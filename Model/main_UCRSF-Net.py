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
from multiscaleloss import EPICE, LCC, EPIloss, TraCorrectEPINew, circleCor, TVLoss
from spline import Bsplinebao, SDS_BSpline_Basis

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
parser.add_argument('--lr', '--learning-rate', default=0.0001, type=float,
                    metavar='LR', help='initial learning rate')
parser.add_argument('--momentum', default=0.9, type=float, metavar='M',
                    help='momentum for sgd, alpha parameter for adam')
parser.add_argument('--beta', default=0.999, type=float, metavar='M',
                    help='beta parameter for adam')
parser.add_argument('--weight-decay', '--wd', default=4e-4, type=float,
                    metavar='W', help='weight decay')
parser.add_argument('--bias-decay', default=0, type=float,
                    metavar='B', help='bias decay')
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

# 添加基础GPU状态检查
print("CUDA Available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("Active GPU Index:", torch.cuda.current_device())
    print("Device Name:", torch.cuda.get_device_name(device))

#randomize the input data
class RandomDataset(Dataset):
    def __init__(self, data, length):
        self.data = data
        self.len = length

    def __getitem__(self, index):
        return torch.Tensor(self.data[index, :]).float()

    def __len__(self):
        return self.len

basisAll=[]

def main():
    global args
    args = parser.parse_args()
    save_path = './wh/EPI_PLUS/UCRSF-Net_1/add_T1_trian_result/{}-{}-{}epochs{}-b{}-lr{}'.format(
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

##添加的基线处理部分的数据输入



    # train_set = h5py.File(
    #     '/home/user/data1/weida/data/hcp_dwi/train/connectome_train_T1_std.mat')[
    #     'output'].value
    with h5py.File('/home/data1/mrLab/wh/EPI_PLUS/UCRSF-Net_1/mice_simult_train_std.mat', "r") as f:
        for key in f.keys():
            print(f[key], key, f[key].name)
            train_set = f[key][:] 
            #train_set = f[key].value
    train_set = torch.tensor(train_set)
    train_set = train_set.permute(3, 2, 1, 0)
    train_set = train_set.numpy()
    #

    # vali_set = h5py.File(
    #     '/home/user/data1/weida/data/simulate_mice/simulate_map_2_gene_mice_x2/proposed/validate/mice_simult_data3_x2_validate_std.mat')[
    #     'output'].value
    # vali_set = torch.tensor(vali_set)
    # vali_set = vali_set.permute(3, 2, 1, 0)
    # vali_set = vali_set.numpy()

    nrtrain = 614
   #nrtrain = 2997
    # nrvali = 54


    pd = ((0, 0), (0, 0), (0, 0), (0, 8))
    train_set = np.pad(train_set, pd, 'constant')
#其中 “np.pad” 是 NumPy 库中的函数，用于对数组进行填充操作。“train_set” 是要进行填充的数组，“pd” 可能是一个表示填充宽度的参数，“'constant'” 表示使用常量值（通常为零）进行填充。

    # create base for BPM module多尺度B样条基函数构建过程中的边界扩展​​ 
    ImagX = train_set.shape[2]#返回形状信息
    ImagY = train_set.shape[3]

    ImagSize = np.array([ImagX, ImagY])#（96，104）
    current_support = np.array([0.0, 0.0])#初始化值支撑域变量
    full_res = np.array([ImagX, ImagY])
    for iLever in range(8):
        if (iLever == 0):
            current_support = np.array([ImagX, ImagY])
        else:
            current_support = np.round(3 * current_support / 4 + 0.0001)# 逐步缩小支撑区
        # print(current_support)
        B, hx = Bsplinebao(current_support, ImagSize, 'linear') # 生成B样条基

        basis = SDS_BSpline_Basis(B, hx, full_res)# 构建基函数
        basisAll.append(basis)#将所有的basis合在一起
        # print(basis)


    train_loader = torch.utils.data.DataLoader(
        RandomDataset(train_set, nrtrain), batch_size=args.batch_size,
        num_workers=args.workers, pin_memory=True, shuffle=True)#works是用于加载数据的子进程数量
    # vali_loader = torch.utils.data.DataLoader(
    #     RandomDataset(vali_set, nrvali), batch_size=args.batch_size,
    #     num_workers=args.workers, pin_memory=True, shuffle=False)


    # create model
    if args.pretrained:
        network_data = torch.load(args.pretrained)
        args.arch = network_data['arch']
        print("=> using pre-trained model '{}'".format(args.arch))
    else:
        network_data = None
        print("=> creating model '{}'".format(args.arch))

    model = models.__dict__[args.arch](network_data).to(device)

    assert (args.solver in ['adam', 'sgd', 'adadelta'])
    print('=> setting {} solver'.format(args.solver))
    param_groups = [{'params': model.bias_parameters(), 'weight_decay': args.bias_decay},
                    {'params': model.weight_parameters(), 'weight_decay': args.weight_decay}]

    # if device.type == "cuda":
    #     model = torch.nn.DataParallel(model).cuda()
    #     cudnn.benchmark = True

    if args.solver == 'adam':
        optimizer = torch.optim.Adam(param_groups, args.lr,
                                     betas=(args.momentum, args.beta))
    elif args.solver == 'sgd':
        optimizer = torch.optim.SGD(param_groups, args.lr,
                                    momentum=args.momentum)
    elif args.solver == 'adadelta':
        optimizer = torch.optim.Adadelta(param_groups, args.lr, rho=0.9, eps=1e-06, weight_decay=0)

    # if args.evaluate:
    #     best_EPE = validate(val_loader, model, 0, output_writers)
    #     return

    scheduler = torch.optim.lr_scheduler.MultiStepLR(optimizer, milestones=args.milestones, gamma=0.5)

    model_dir = "%s/%s/param" % (save_path, args.model_dir)
    loss_dir = "%s/%s" % (save_path, args.model_dir)
    temp_dir = "%s/%s/temp" % (save_path, args.model_dir)

    if not os.path.exists(model_dir):
        os.makedirs(model_dir)

    if not os.path.exists(temp_dir):
        os.makedirs(temp_dir)

    if args.start_epoch > 0:
        pre_model_dir = model_dir
        model.load_state_dict(torch.load('./%s/net_params_%d.pkl' % (pre_model_dir, args.start_epoch)))


    lossall = []
    lossall_train = []
    lossall_t1 = []
    lossall_mse_cup_cdown = []
    lossall_cir = []


    # 定义总参数量、可训练参数量及非可训练参数量变量
    Total_params = 0
    Trainable_params = 0
    NonTrainable_params = 0

    # 遍历model.parameters()返回的全局参数列表
    for param in model.parameters():
        mulValue = np.prod(param.size())  # 使用numpy prod接口计算参数数组所有元素之积
        Total_params += mulValue  # 总参数量
        if param.requires_grad:
            Trainable_params += mulValue  # 可训练参数量
        else:
            NonTrainable_params += mulValue  # 非可训练参数量

    print(f'Total params: {Total_params}')
    print(f'Trainable params: {Trainable_params}')
    print(f'Non-trainable params: {NonTrainable_params}')

    for epoch in range(args.start_epoch, args.epochs):
        # train for one epoch
        # loss, pic = train(train_loader, model, optimizer, epoch)
        loss= train(train_loader, model, optimizer, epoch)
        lossall_train.append(loss[0])
        lossall_t1.append(loss[1])
        lossall_mse_cup_cdown.append(loss[2])
        lossall_cir.append(loss[3])
        scheduler.step()


        if epoch % 100 == 0:
            torch.save(model.state_dict(), "./%s/net_params_%d.pkl" % (model_dir, epoch))  # save only the parameters

        if epoch % 300 == 0:
            loss0 = np.array(lossall)
            loss1 = np.array(lossall_train)#总损失
            loss2 = np.array(lossall_t1)
            loss4 = np.array(lossall_mse_cup_cdown)
            loss5 = np.array(lossall_cir)

            np.save("./%s/lossall_validate2.npy" % (loss_dir), loss0)
            np.save("./%s/lossall_train2.npy" % (loss_dir), loss1)#总损失
            np.save("./%s/lossall_train_t1_mse.npy" % (loss_dir), loss2)
            np.save("./%s/lossall_train_mse_cup_cdown.npy" % (loss_dir), loss4)
            np.save("./%s/lossall_train_cir.npy" % (loss_dir), loss5)


def train(train_loader, model, optimizer, epoch):
    global n_iter, args
    batch_time = AverageMeter()
    data_time = AverageMeter()
    losses = AverageMeter()
    losses_mset1 = AverageMeter()
    loss_cup_cdown = AverageMeter()
    loss_cir = AverageMeter()

    # epoch_size = len(train_loader)
    epoch_size = len(train_loader) if args.epoch_size == 0 else min(len(train_loader), args.epoch_size)

    # switch to train mode
    model.train()

    end = time.time()

    for i, (input) in enumerate(train_loader):
        # measure data loading time
        data_time.update(time.time() - end)

        input = input.to(device)

        # compute output
        output = model(input[:, 0:2, :, :])
#，表示取所有的第一个维度，第二个维度的前两个元素，以及第三、第四个维度的所有元素）进行处理，并将结果赋值给变量 “output”。

        #EPIloss is the loss function
        lossall = EPIloss(output, input, basisAll, args.batch_size, epoch)

        loss = lossall[0]#总损失
        lmset1 = lossall[1]#EPI校正后与参考图之间损失
        lcup_cdown = lossall[2]#几何校正损失
        lcir = lossall[3]#循环损失

        losses.update(loss.item(), output[0].size(0))
        losses_mset1.update(lmset1.item(), output[0].size(0))
        loss_cup_cdown.update(lcup_cdown.item(), output[0].size(0))
        loss_cir.update(lcir.item(), output[0].size(0))

        # compute gradient and do optimization step计算梯度并执行优化步骤
        optimizer.zero_grad()

        loss.backward()

        optimizer.step()

        # measure elapsed time
        batch_time.update(time.time() - end)
        end = time.time()

        print('Epoch: [{0}][{1}/{2}]\t Time {3}\t Data {4}\t Loss {5}'
              .format(epoch, i, epoch_size, batch_time,
                      data_time, losses))
        n_iter += 1
        if i >= epoch_size:
            break

    loss_avg_all = [losses.avg, losses_mset1.avg, loss_cup_cdown.avg, loss_cir.avg]

    return loss_avg_all

def evaluate(vali_loader, model):
    model.eval()
    epoch_loss = AverageMeter()
    addition = TVLoss()
    with torch.no_grad():
        for j, (input) in enumerate(vali_loader):
            loss=0
            input = input.to(device)

            output, weight1 = model(input)
            llen = np.shape(input)[0]
            for i in range(llen):
                EPIC = TraCorrectEPINew(output[i], input[i])
                cor = (EPIC[0] + EPIC[1]) / 2
                cor = cor.to(device)
                cirunEPIUP, cirunEPIDOWN = circleCor(cor, output[i])

                cirunEPIUP = cirunEPIUP.to(device)
                cirunEPIDOWN = cirunEPIDOWN.to(device)

                loss += EPICE(EPIC[0], EPIC[1]).to(device)
                # loss += 10 * EPICE(EPIC[2], EPIC[3]).to(device)
                loss += EPICE(cirunEPIUP, input[i][0])
                loss += EPICE(cirunEPIDOWN, input[i][1])
            loss += addition(output).to(device)
            loss = loss / llen
            epoch_loss.update(loss.item(), output.size(0))
    return epoch_loss.avg


if __name__ == '__main__':
    main()
