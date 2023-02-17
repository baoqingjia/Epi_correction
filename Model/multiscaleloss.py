import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import math
import os
from torch.autograd import Variable


device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


class LCC(nn.Module):
    def __init__(self, win=[3, 3], eps=1e-5):
        super(LCC, self).__init__()
        self.win = win
        self.eps = eps

    def forward(self, I, J):
        I2 = I.pow(2)
        J2 = J.pow(2)
        IJ = I * J
        filters = Variable(torch.ones(1, 1, self.win[0], self.win[1]))
        if I.is_cuda:
            filters = filters.cuda()
        padding = (self.win[0] // 2, self.win[1] // 2)
        I_sum = F.conv2d(I, filters, stride=1, padding=padding)
        J_sum = F.conv2d(J, filters, stride=1, padding=padding)
        I2_sum = F.conv2d(I2, filters, stride=1, padding=padding)
        J2_sum = F.conv2d(J2, filters, stride=1, padding=padding)
        IJ_sum = F.conv2d(IJ, filters, stride=1, padding=padding)
        win_size = self.win[0] * self.win[1]
        u_I = I_sum / win_size
        u_J = J_sum / win_size
        cross = IJ_sum - u_J * I_sum - u_I * J_sum + u_I * u_J * win_size
        I_var = I2_sum - 2 * u_I * I_sum + u_I * u_I * win_size
        J_var = J2_sum - 2 * u_J * J_sum + u_J * u_J * win_size
        cc = cross * cross / (I_var * J_var + self.eps)
        lcc = -1.0 * torch.mean(cc) + 1
        return lcc


def EPICE(EPIupC, EPIdownC):
    mse = ((EPIupC - EPIdownC) ** 2).mean()
    return mse


def getval(j, u, deta, unCEPI):
    h, w = unCEPI.size()
    if u < 0:
        u = 0
    if u > h-1:
        u = h - 1
    um = u-1 if u-1 > 0 else 0
    up = u+1 if u+1 <= h-1 else h-1
    upp = u+2 if u+2 <= h-1 else h-1
    cub = (-1/2*unCEPI[j, um]+3/2*unCEPI[j, u]-3/2*unCEPI[j, up]+1/2*unCEPI[j, upp])*math.pow(deta, 3)
    quad = (unCEPI[j, um]-5/2*unCEPI[j, u]+2*unCEPI[j, up]-1/2*unCEPI[j, upp])*math.pow(deta, 2)
    lin = (-1/2*unCEPI[j, um]+1/2*unCEPI[j, up])*deta
    z0 = unCEPI[j, u]
    val = quad+lin+z0
    return val


def getvalNew(u, j, deta, unCEPI):
    h, w = unCEPI.size()
    u = u.clamp(0, h-1).type(torch.long)
    up = (u+1).clamp(0, h-1)
    val = (1-deta)*unCEPI[u, j]+deta*unCEPI[up, j]
    return val


def CorrectEPI(fieldmap, unCorrectedEPI):
    c, h, w = fieldmap.size()
    EPIUPC = np.zeros([h, w])
    EPIUPC = torch.tensor(EPIUPC)
    EPIDOWNC = np.zeros([h, w])
    EPIDOWNC = torch.tensor(EPIDOWNC)
    for i in range(h):
        for j in range(w):
            u = math.floor(j+fieldmap[0, i, j])
            d = math.floor(j-fieldmap[0, i, j])
            detay = j+fieldmap[0, i, j]-u
            detad = j-fieldmap[0, i, j]-d
            EPIUPC[i, j] = getval(i, u, detay, unCorrectedEPI[0])
            EPIDOWNC[i, j] = getval(i, d, detad, unCorrectedEPI[1])
    return EPIUPC, EPIDOWNC


def TraCorrectEPINew(fieldmap, unCorrectedEPI):
    c, h, w = fieldmap.size()
    EPIUPC = np.zeros([h, w])
    EPIUPC = torch.tensor(EPIUPC)
    EPIDOWNC = np.zeros([h, w])
    EPIDOWNC = torch.tensor(EPIDOWNC)
    y = np.arange(0, h)
    y = torch.tensor(y).type(torch.long)
    y = y.to(device)
    upEPI = unCorrectedEPI[0]
    downEPI = unCorrectedEPI[1]
    map = fieldmap[0, :, :]
    A = map[1:, :]
    B = map[0:1, :]
    C = map[0:h - 1, :]
    D = map[h - 1:, :]
    mdown = torch.cat((A, B), 0)
    mup = torch.cat((D, C), 0)
    map1 = fieldmap[1, :, :]
    A1 = map1[1:, :]
    B1 = map1[0:1, :]
    C1 = map1[0:h - 1, :]
    D1 = map1[h - 1:, :]
    mdown1 = torch.cat((A1, B1), 0)
    mup1 = torch.cat((D1, C1), 0)
    J1 = 1 + (mup - mdown) / 2
    J2 = 1 - (mup1 - mdown1) / 2

    for i in range(w):
        ypf = y + fieldmap[0, :, i]
        ymf1 = y - fieldmap[1, :, i]
        u = ypf.floor()
        d1 = ymf1.floor()
        detay = ypf - u
        detad1 = ymf1 - d1
        EPIUPC[:, i] = getvalNew(u, i, detay, upEPI)
        EPIDOWNC[:, i] = getvalNew(d1, i, detad1, downEPI)
    upEPI = torch.mul(upEPI, J1)
    downEPI = torch.mul(downEPI, J2)
    return EPIUPC, EPIDOWNC


def CorrectEPINew(fieldmap, weight1, weight2, unCorrectedEPI):
    c, h, w = fieldmap.size()
    EPIUPC = np.zeros([h, w])
    EPIUPC = torch.tensor(EPIUPC)
    EPIDOWNC = np.zeros([h, w])
    EPIDOWNC = torch.tensor(EPIDOWNC)
    EPIUPCw = np.zeros([h, w])
    EPIUPCw = torch.tensor(EPIUPCw)
    EPIDOWNCw = np.zeros([h, w])
    EPIDOWNCw = torch.tensor(EPIDOWNCw)
    y = np.arange(0, h)
    y = torch.tensor(y).type(torch.long)
    y = y.to(device)
    upEPI = unCorrectedEPI[0]
    downEPI = unCorrectedEPI[1]

    for i in range(w):
        ypf = y + fieldmap[0, :, i]
        ymf1 = y - fieldmap[1, :, i]
        u = ypf.floor()
        d1 = ymf1.floor()
        detay = ypf - u
        detad1 = ymf1 - d1
        EPIUPC[:, i] = getvalNew(u, i, detay, upEPI)
        EPIDOWNC[:, i] = getvalNew(d1, i, detad1, downEPI)
    EPIUPC = EPIUPC.to(device)
    EPIDOWNC = EPIDOWNC.to(device)
    EPIUPCw = torch.mul(EPIUPC, torch.squeeze(weight1))
    EPIDOWNCw = torch.mul(EPIDOWNC, torch.squeeze(weight2))
    return EPIUPCw, EPIDOWNCw, EPIUPC, EPIDOWNC


def circleCor(cor, fieldmap):
    c, h, w = fieldmap.size()
    cirunEPIUP = np.zeros([h, w])
    cirunEPIDOWN = np.zeros([h, w])
    cirunEPIUP = torch.tensor(cirunEPIUP)
    cirunEPIDOWN = torch.tensor(cirunEPIDOWN)
    y = np.arange(0, h)
    y = torch.tensor(y).type(torch.long)
    y = y.to(device)
    for i in range(w):
        ypf = y - fieldmap[0, :, i]
        ymf = y + fieldmap[1, :, i]
        u = ypf.floor()
        d = ymf.floor()
        detay = ypf - u
        detad = ymf - d
        cirunEPIUP[:, i] = getvalNew(u, i, detay, cor)
        cirunEPIDOWN[:, i] = getvalNew(d, i, detad, cor)
    return cirunEPIUP, cirunEPIDOWN


def getGrid(map, flag):
    b, _, h, w = map.size()
    grid = torch.zeros([b, h, w, 2])
    grid[:, :, :, 1] = flag*map[:, 0, :, :]
    return grid


def sparse_max_pool(input, size):
    positive = (input > 0).float()
    negative = (input < 0).float()
    output = F.adaptive_max_pool2d(input * positive, size) - F.adaptive_max_pool2d(-input * negative, size)
    return output


def multiscaleEPI(network_output, multisEPI, bsize, weights=None, sparse=False):
    def one_scale(output, target, sparse):
        b, _, h, w = output.size()
    if type(network_output) not in [tuple, list]:
        network_output = [network_output]
    if weights is None:
        weights = [0.02, 0.08, 0.32]  # as in original article
    assert(len(weights) == len(network_output))

    loss = 0
    for output, EPI, weight in zip(network_output,multisEPI, weights):
        b, c, h, w = output.size()
        EPI = EPI.to(device)
        grid0 = getGrid(output, -1)
        grid1 = getGrid(output, 1)
        grid0 = grid0.to(device)
        grid1 = grid1.to(device)
        aaa = EPI[:, 0, :, :]
        EPICup = F.grid_sample(EPI[:, 0, :, :].unsqueeze(1), grid0, padding_mode="reflection", align_corners=False)
        EPICDown = F.grid_sample(EPI[:, 1, :, :].unsqueeze(1), grid1, padding_mode="reflection", align_corners=False)
        for i in range(bsize):
            loss += weight*EPICE(torch.squeeze(EPICup[i], 1), torch.squeeze(EPICDown[i], 1))
    loss = loss/bsize
    return loss


class TVLoss(nn.Module):
    def __init__(self, TVLoss_weight=1):
        super(TVLoss, self).__init__()
        self.TVLoss_weight = TVLoss_weight

    def forward(self, x):
        h_x = x.size()[2]
        w_x = x.size()[3]
        count_h = self._tensor_size(x[:, :, 1:, :])
        count_w = self._tensor_size(x[:, :, :, 1:])
        h_tv = torch.pow((x[:, :, 1:, :]-x[:, :, :h_x-1, :]), 2).sum()
        w_tv = torch.pow((x[:, :, :, 1:]-x[:, :, :, :w_x-1]), 2).sum()
        return self.TVLoss_weight*2*(h_tv/count_h+w_tv/count_w)

    def _tensor_size(self, t):
        return t.size()[1]*t.size()[2]*t.size()[3]


def LossTV(map):
    c, w, h = map.size()
    map = torch.squeeze(map)
    losstv = 0
    lossvalley = 0
    loss = 0
    y = np.arange(0, h)
    y = torch.tensor(y).type(torch.long)
    y = y.to(device)
    yp = (y + 1).clamp(0, h - 1)
    fmax = torch.max(map)
    for i in range(w):
        losstv += torch.abs(map[i, yp]-map[i, y]).sum()+torch.abs(map[yp, i]-map[y, i]).sum()
    return losstv


def multiscaleEPINew(network_output, multisEPI, bsize, weightall, weights=None, sparse=False):
    if type(network_output) not in [tuple, list]:
        network_output = [network_output]
    if weights is None:
        weights = [0.02, 0.08, 0.32]
    assert(len(weights) == len(network_output))
    loss = 0
    addition = TVLoss()
    for output, input, weight1 in zip(network_output, multisEPI, weightall):
        b, c, h, w=output.size()
        input = input.to(device)
        for i in range(bsize):
            EPIC = CorrectEPINew(output[i], weight1[i], 2-weight1[i], input[i])
            loss += EPICE(EPIC[0], EPIC[1]).to(device)
        loss += addition(output[:, 0:1, :, :]).to(device)
        loss += addition(output[:, 1:2, :, :]).to(device)
    loss = loss/bsize
    return loss


def testloss(network_output, input, bsize):
    loss = 0
    input = input.to(device)
    for i in range(bsize):
        loss += EPICE(input[:, 0, :, :]-input[:, 1, :, :], network_output[:, 0, :, :])
    loss = loss / bsize
    return loss


def EPIloss(network_output, input, weight1, bsize, epoch):
    loss = 0
    input = input.to(device)
    addition = TVLoss()
    lcc = LCC()
    for i in range(bsize):
        EPIC = TraCorrectEPINew(network_output[i], input[i])
        cor = (EPIC[0] + EPIC[1]) / 2
        cor = cor.to(device)
        cirunEPIUP, cirunEPIDOWN = circleCor(cor, network_output[i])
        cirunEPIUP = cirunEPIUP.to(device)
        cirunEPIDOWN = cirunEPIDOWN.to(device)
        loss += EPICE(EPIC[0], EPIC[1]).to(device)
        loss += 5*EPICE(cirunEPIUP, input[i][0])
        loss += 5*EPICE(cirunEPIDOWN, input[i][1])
    loss += addition(network_output[:, 0:1, :, :]).to(device)
    loss += addition(network_output[:, 1:2, :, :]).to(device)
    loss = loss/bsize
    return loss
