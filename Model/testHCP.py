import torch
import torch.nn as nn
import torch.nn.functional as F
import scipy.io as sio
import numpy as np
import os
from time import time
import cv2
import torch.backends.cudnn as cudnn
import argparse
import models
from torch.utils.data import Dataset
from multiscaleloss import EPICE, LCC, TraCorrectEPINew, circleCor
import h5py
import nibabel as nib
from util import AverageMeter
from spline import Bsplinebao, SDS_BSpline_Basis
import matplotlib.pyplot as plt


model_names = sorted(name for name in models.__dict__ if name.islower() and not name.startswith("__"))

parser = argparse.ArgumentParser(description='PyTorch FlowNet Training on EPI datasets', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--data', metavar='DIR', help='path to dataset')
group = parser.add_mutually_exclusive_group()
group.add_argument('-s', '--split-file', default=None, type=str, help='test-val split file')
group.add_argument('--split-value', default=0.8, type=float, help='test-val split proportion between 0 (only test) and 1 (only train), will be overwritten if a split file is set')
parser.add_argument('--arch', '-a', metavar='ARCH', default='ucrsf_net', choices=model_names, help='model architecture, overwritten if pretrained is specified: ' + ' | '.join(model_names))
parser.add_argument('--solver', default='adam', choices=['adam', 'sgd'], help='solver algorithms')
parser.add_argument('-j', '--workers', default=8, type=int, metavar='N', help='number of data loading workers')
parser.add_argument('--epochs', default=313, type=int, metavar='N', help='number of total epochs to run')
parser.add_argument('--start-epoch', default=0, type=int, metavar='N', help='manual epoch number (useful on restarts)')
parser.add_argument('--epoch-size', default=24, type=int, metavar='N', help='manual epoch size (will match dataset size if set to 0)')
parser.add_argument('-b', '--batch-size', default=8, type=int, metavar='N', help='mini-batch size')
parser.add_argument('--lr', '--learning-rate', default=0.001, type=float, metavar='LR', help='initial learning rate')
parser.add_argument('--momentum', default=0.9, type=float, metavar='M', help='momentum for sgd, alpha parameter for adam')
parser.add_argument('--beta', default=0.999, type=float, metavar='M', help='beta parameter for adam')
parser.add_argument('--weight-decay', '--wd', default=4e-4, type=float, metavar='W', help='weight decay')
parser.add_argument('--bias-decay', default=0, type=float, metavar='B', help='bias decay')
parser.add_argument('--multiscale-weights', '-w', default=[0.02, 0.08, 0.32], type=float, nargs=5, help='training weight for each scale, from highest resolution (flow2) to lowest (flow6)', metavar=('W2', 'W3', 'W4', 'W5', 'W6'))
parser.add_argument('--sparse', action='store_true', help='look for NaNs in target flow when computing EPE, avoid if flow is garantied to be dense, automatically seleted when choosing a KITTIdataset')
parser.add_argument('--model_dir', type=str, default='model', help='trained or pre-trained model directory')
parser.add_argument('-e', '--evaluate', dest='evaluate', action='store_true', help='evaluate model on validation set')
parser.add_argument('--pretrained', dest='pretrained', default=None, help='path to pre-trained model')
parser.add_argument('--div-flow', default=20, help='value by which flow will be divided. Original value is 20 but 1 with batchNorm gives good results')

n_iter = 0
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

basisAll = []


class RandomDataset(Dataset):
    def __init__(self, data, length):
        self.data = data
        self.len = length

    def __getitem__(self, index):
        return torch.Tensor(self.data[index, :]).float()

    def __len__(self):
        return self.len


def getCor(up, down):
    temp = torch.mul(up, down)
    cor = torch.div(2*temp, up+down)
    return cor


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

    test_set = h5py.File('/home/user/data1/weida/data/hcp_dwi/test/nor/connectome_test_100610_pair_nor.mat')['output'].value
    test_set = torch.tensor(test_set)
    test_set = test_set.permute(3, 2, 1, 0)
    test_set = test_set.numpy()
    pd = ((0, 0), (0, 0), (0, 0), (0, 8))
    test_set = np.pad(test_set, pd, 'constant')

    ImagX = test_set.shape[2]
    ImagY = test_set.shape[3]
    ImagSize = np.array([ImagX, ImagY])
    current_support = np.array([0.0, 0.0])
    full_res = np.array([ImagX, ImagY])
    for iLever in range(8):
        if (iLever == 0):
            current_support = np.array([ImagX, ImagY])
        else:
            current_support = np.round(3 * current_support / 4)
        B, hx = Bsplinebao(current_support, ImagSize, 'linear')
        basis = SDS_BSpline_Basis(B, hx, full_res)
        basisAll.append(basis)

    if args.pretrained:
        network_data = torch.load(args.pretrained)
        args.arch = network_data['arch']
        print("=> using pre-trained model '{}'".format(args.arch))
    else:
        network_data = None
        print("=> creating model '{}'".format(args.arch))

    model = models.__dict__[args.arch](network_data).to(device)
    model.eval()

    assert (args.solver in ['adam', 'sgd'])
    print('=> setting {} solver'.format(args.solver))
    param_groups = [{'params': model.bias_parameters(), 'weight_decay': args.bias_decay},
                    {'params': model.weight_parameters(), 'weight_decay': args.weight_decay}]

    if args.solver == 'adam':
        optimizer = torch.optim.Adam(param_groups, args.lr, betas=(args.momentum, args.beta))
    elif args.solver == 'sgd':
        optimizer = torch.optim.SGD(param_groups, args.lr, momentum=args.momentum)

    model_dir = "%s/%s/param" % (save_path, args.model_dir)
    pre_model_dir = model_dir
    model.load_state_dict(torch.load('%s/net_params_%d.pkl' % (pre_model_dir, 300)))

    ImgNum=test_set.shape[0]

    dir1 = '/hcp_T1_circle_100610_resunet-304_TWOMAP'
    if not os.path.exists(save_path + dir1+"/map"):
        os.makedirs(save_path + dir1+"/map")
    if not os.path.exists(save_path + dir1+"/Correct"):
        os.makedirs(save_path + dir1+"/Correct")
    if not os.path.exists(save_path + dir1+"/EPICup"):
        os.makedirs(save_path + dir1+"/EPICup")
    if not os.path.exists(save_path + dir1+"/EPICDown"):
        os.makedirs(save_path + dir1+"/EPICDown")
    if not os.path.exists(save_path + dir1+"/UP"):
        os.makedirs(save_path + dir1+"/UP")
    if not os.path.exists(save_path + dir1+"/DOWN"):
        os.makedirs(save_path + dir1+"/DOWN")
    if not os.path.exists(save_path + dir1+"/temp"):
        os.makedirs(save_path + dir1+"/temp")

    with torch.no_grad():
        sb = ImgNum//111
        shape = (144, 168, 111, sb)
        mapall = np.zeros([2, 144, 168, 111, sb])
        Correctall = np.zeros(shape)
        EPICupall = np.zeros(shape)
        EPICDownall = np.zeros(shape)
        UPall = np.zeros(shape)
        DOWNall = np.zeros(shape)
        weightupall = np.zeros(shape)
        weightdownall = np.zeros(shape)
        densityupall = np.zeros(shape)
        densitydownall = np.zeros(shape)
        prelosses = AverageMeter()
        losses = AverageMeter()
        start = time()
        for img_no in range(ImgNum):
            Img_output = test_set[img_no]
            UNEPIUP = Img_output[0]
            UNEPIDOWN = Img_output[1]
            input = torch.from_numpy(Img_output)
            input1 = input.to(device)
            input=input.unsqueeze(0)
            input = input.type(torch.FloatTensor)
            input = input.to(device)
            network_output = model(input[:, 0:2, :, :])
            output = torch.zeros([2, 144, 176])
            output = output.to(device)
            current_support = torch.tensor([144, 176])
            for k in range(6):
                for j in range(2):
                    if k > 0:
                        current_support = np.round(3 * current_support / 4)
                    tmp = torch.squeeze(network_output[k][0][j])
                    aa = torch.from_numpy(basisAll[k][1].T).float()
                    bb = torch.from_numpy(basisAll[k][0].T).float()
                    aa = aa.to(device)
                    bb = bb.to(device)
                    tmp = torch.sqrt(1 / current_support[1]) * torch.mm(aa, tmp)
                    tmp = torch.sqrt(1 / current_support[0]) * torch.mm(bb, tmp.T)
                    output[j] = output[j] + tmp
            output = output.to(device)
            EPICup, EPICDown = TraCorrectEPINew(output, input[0])
            cor = getCor(EPICup, EPICDown)
            cor = cor.to(device)
            shape1 = (144, 176)

            losspre = EPICE(UNEPIUP, UNEPIDOWN)
            loss = EPICE(EPICup, EPICDown)
            prelosses.update(losspre.item(), 1)
            losses.update(loss.item(), 1)

            EPICup = EPICup.cpu().data.numpy().reshape(shape1)
            EPICDown = EPICDown.cpu().data.numpy().reshape(shape1)
            Prediction_map = output.cpu().data.numpy().reshape([2, 144, 176])

            print('[{0}/{1}] pre loss is {2},Proposed loss is {3}'
                  .format(img_no, ImgNum, prelosses,
                          losses))
            b = img_no // 111
            c = img_no % 111

            mapall[:, :, :, c, b] = Prediction_map[:, :, 0:168]
            Correctall[:, :, c, b] = (EPICup[:, 0:168] + EPICDown[:, 0:168]) / 2
            EPICupall[:, :, c, b] = EPICup[:, 0:168]
            EPICDownall[:, :, c, b] = EPICDown[:, 0:168]
            UPall[:, :, c, b] = UNEPIUP[:, 0:168]
            DOWNall[:, :, c, b] = UNEPIDOWN[:, 0:168]

        end = time()
        print('Run time is{0}'.format((end - start)))

        mapall = nib.Nifti1Image(mapall, np.eye(4))
        mapall.set_data_dtype(np.float)
        nib.save(mapall, save_path + dir1 + "/map/mapall.nii.gz")
        Correctall = nib.Nifti1Image(Correctall, np.eye(4))
        Correctall.set_data_dtype(np.float)
        nib.save(Correctall, save_path + dir1 + "/Correct/Correctall.nii.gz")
        EPICupall = nib.Nifti1Image(EPICupall, np.eye(4))
        EPICupall.set_data_dtype(np.float)
        nib.save(EPICupall, save_path + dir1 + "/EPICup/EPICupall.nii.gz")
        EPICDownall = nib.Nifti1Image(EPICDownall, np.eye(4))
        EPICDownall.set_data_dtype(np.float)
        nib.save(EPICDownall, save_path + dir1 + "/EPICDown/EPICDownall.nii.gz")
        UPall = nib.Nifti1Image(UPall, np.eye(4))
        UPall.set_data_dtype(np.float)
        nib.save(UPall, save_path + dir1 + "/UP/UPall.nii.gz")
        DOWNall = nib.Nifti1Image(DOWNall, np.eye(4))
        DOWNall.set_data_dtype(np.float)
        nib.save(DOWNall, save_path + dir1 + "/DOWN/DOWNall.nii.gz")


if __name__ == '__main__':
    main()






