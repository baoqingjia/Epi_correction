import argparse
import os
import time
import scipy.io as sio
import torch
import torch.nn.functional as F
import torch.nn.parallel
import torch.optim
import torch.utils.data
import models
import h5py
from util import flow2rgb, AverageMeter, save_checkpoint
from torch.utils.data import Dataset
import numpy as np
from multiscaleloss import EPICE, CorrectEPINew, LCC, EPIloss
import matplotlib.pyplot as plt


model_names = sorted(name for name in models.__dict__
                     if name.islower() and not name.startswith("__"))


parser = argparse.ArgumentParser(description='PyTorch Resnet_Unet Training on EPI datasets',
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--data', metavar='DIR',
                    help='path to dataset')
group = parser.add_mutually_exclusive_group()
group.add_argument('-s', '--split-file', default=None, type=str,
                   help='test-val split file')
group.add_argument('--split-value', default=0.8, type=float,
                   help='test-val split proportion between 0 (only test) and 1 (only train), '
                        'will be overwritten if a split file is set')
parser.add_argument('--arch', '-a', metavar='ARCH', default='ucrsf_net',
                    choices=model_names,
                    help='model architecture, overwritten if pretrained is specified: ' +
                         ' | '.join(model_names))
parser.add_argument('--solver', default='adam', choices=['adam', 'sgd', 'adadelta'],
                    help='solver algorithms')
parser.add_argument('-j', '--workers', default=8, type=int, metavar='N',
                    help='number of data loading workers')
parser.add_argument('--epochs', default=319, type=int, metavar='N',
                    help='number of total epochs to run')
parser.add_argument('--start-epoch', default=0, type=int, metavar='N',
                    help='manual epoch number (useful on restarts)')
parser.add_argument('--epoch-size', default=24, type=int, metavar='N',
                    help='manual epoch size (will match dataset size if set to 0)')
parser.add_argument('-b', '--batch-size', default=8, type=int,
                    metavar='N', help='mini-batch size')
parser.add_argument('--lr', '--learning-rate', default=0.001, type=float,
                    metavar='LR', help='initial learning rate')
parser.add_argument('--momentum', default=0.9, type=float, metavar='M',
                    help='momentum for sgd, alpha parameter for adam')
parser.add_argument('--beta', default=0.999, type=float, metavar='M',
                    help='beta parameter for adam')
parser.add_argument('--weight-decay', '--wd', default=4e-4, type=float,
                    metavar='W', help='weight decay')
parser.add_argument('--bias-decay', default=0, type=float,
                    metavar='B', help='bias decay')
parser.add_argument('--multiscale-weights', '-w', default=[1,1,1], type=float, nargs=5,
                    help='training weight for each scale, from highest resolution (flow2) to lowest (flow6)',
                    metavar=('W2', 'W3', 'W4', 'W5', 'W6'))
parser.add_argument('--sparse', action='store_true',
                    help='look for NaNs in target flow when computing EPE, avoid if flow is garantied to be dense,'
                         'automatically seleted when choosing a KITTIdataset')
parser.add_argument('--model_dir', type=str, default='model', help='trained or pre-trained model directory')
parser.add_argument('-e', '--evaluate', dest='evaluate', action='store_true',
                    help='evaluate model on validation set')
parser.add_argument('--pretrained', dest='pretrained', default=None,
                    help='path to pre-trained model')
parser.add_argument('--div-flow', default=20,
                    help='value by which flow will be divided. Original value is 20 but 1 with batchNorm gives good results')
parser.add_argument('--milestones', default=[50,100,150,200], metavar='N', nargs='*',
                    help='epochs at which learning rate is divided by 2')

n_iter = 0
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


class RandomDataset(Dataset):
    def __init__(self, data, length):
        self.data = data
        self.len = length

    def __getitem__(self, index):
        return torch.Tensor(self.data[index, :]).float()

    def __len__(self):
        return self.len


def main():
    global args
    args = parser.parse_args()
    save_path = './{}-{}-{}epochs{}-b{}-lr{}'.format(
        args.arch,
        args.solver,
        args.epochs,
        ',epochSize' + str(args.epoch_size) if args.epoch_size > 0 else '',
        args.batch_size,
        args.lr)
    save_path = save_path.replace('\\', '/')
    print('=> will save everything to {}'.format(save_path))
    if not os.path.exists(save_path):
        os.makedirs(save_path)

    train_set = h5py.File(
        '/home/user/data1/weida/data/simulate_mice/true_map_simulate/processed/train/mice_simult_train_std.mat')[
        'output'].value
    train_set = torch.tensor(train_set)
    train_set = train_set.permute(3, 2, 1, 0)
    train_set = train_set.numpy()

    vali_set = h5py.File(
        '/home/user/data1/weida/data/simulate_mice/true_map_simulate/processed/validate/mice_simult_validate_std.mat')[
        'output'].value
    vali_set = torch.tensor(vali_set)
    vali_set = vali_set.permute(3, 2, 1, 0)
    vali_set = vali_set.numpy()

    nrtrain = 614
    nrvali = 54

    train_loader = torch.utils.data.DataLoader(
        RandomDataset(train_set, nrtrain), batch_size=args.batch_size,
        num_workers=args.workers, pin_memory=True, shuffle=True)
    vali_loader = torch.utils.data.DataLoader(
        RandomDataset(vali_set, nrvali), batch_size=args.batch_size,
        num_workers=args.workers, pin_memory=True, shuffle=False)

    if args.pretrained:
        network_data = torch.load(args.pretrained)
        args.arch = network_data['arch']
        print("=> using pre-trained model '{}'".format(args.arch))
    else:
        network_data = None
        print("=> creating model '{}'".format(args.arch))

    model = models.__dict__[args.arch](network_data).to(device)

    assert (args.solver in ['adam', 'sgd' ,'adadelta'])
    print('=> setting {} solver'.format(args.solver))
    param_groups = [{'params': model.bias_parameters(), 'weight_decay': args.bias_decay},
                    {'params': model.weight_parameters(), 'weight_decay': args.weight_decay}]

    if args.solver == 'adam':
        optimizer = torch.optim.Adam(param_groups, args.lr, betas=(args.momentum, args.beta))
    elif args.solver == 'sgd':
        optimizer = torch.optim.SGD(param_groups, args.lr, momentum=args.momentum)
    elif args.solver == 'adadelta':
        optimizer = torch.optim.Adadelta(param_groups, args.lr, rho=0.9, eps=1e-06, weight_decay=0)
    scheduler = torch.optim.lr_scheduler.MultiStepLR(optimizer, milestones=args.milestones, gamma=0.5)
    model_dir = "./%s/%s/param" % (save_path, args.model_dir)
    loss_dir = "./%s/%s" % (save_path, args.model_dir)

    if not os.path.exists(model_dir):
        os.makedirs(model_dir)
    if args.start_epoch > 0:
        pre_model_dir = model_dir
        model.load_state_dict(torch.load('./%s/net_params_%d.pkl' % (pre_model_dir, args.start_epoch)))
    lossall = []

    for epoch in range(args.start_epoch, args.epochs):
        loss = train(train_loader, model, optimizer, epoch)
        valilosse = evaluate(vali_loader, model)
        lossall.append(valilosse)
        scheduler.step()
        if epoch % 100 == 0:
            torch.save(model.state_dict(), "./%s/net_params_%d.pkl" % (model_dir, epoch))  # save only the parameters
        if epoch == 300:
            loss0 = np.array(lossall)
            np.save("./%s/lossall" % (loss_dir), loss0)


def train(train_loader, model, optimizer, epoch):
    global n_iter, args
    batch_time = AverageMeter()
    data_time = AverageMeter()
    losses = AverageMeter()
    epoch_size = len(train_loader) if args.epoch_size == 0 else min(len(train_loader), args.epoch_size)
    model.train()
    end = time.time()

    for i, (input) in enumerate(train_loader):
        data_time.update(time.time() - end)
        input = input.to(device)
        output, weight1 = model(input)

        loss = EPIloss(output, input, weight1, args.batch_size, epoch)
        losses.update(loss.item(), 1)

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        batch_time.update(time.time() - end)
        end = time.time()

        print('Epoch: [{0}][{1}/{2}]\t Time {3}\t Data {4}\t Loss {5}'.format(epoch, i, epoch_size, batch_time, data_time, losses))
        n_iter += 1
        if i >= epoch_size:
            break
    return loss


def evaluate(vali_loader, model):
    model.eval()
    epoch_loss = 0
    with torch.no_grad():
        for j, (input) in enumerate(vali_loader):
            loss = 0
            input = input.to(device)
            output, weight1 = model(input)
            llen = np.shape(input)[0]
            for i in range(llen):
                EPIC = CorrectEPINew(output[i], weight1[i], 2-weight1[i], input[i])
                loss += EPICE(EPIC[0], EPIC[1]).to(device)
            loss = loss / llen
            epoch_loss += loss.item()
    res = int(epoch_loss) / len(vali_loader)
    return res


if __name__ == '__main__':
    main()
