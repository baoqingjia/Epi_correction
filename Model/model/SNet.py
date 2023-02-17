import torch
import torch.nn as nn
from torch.nn.init import kaiming_normal_, constant_
from .util import conv, predict_map, deconv, crop_like

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

__all__ = [
    'snet', 'snet_bn'
]


def init_weight(m):
    if type(m) == nn.Conv2d:
        constant_(m.weight, 1)


class UNet(nn.Module):
    expansion = 1

    def __init__(self, batchNorm=True):
        super(UNet, self).__init__()
        self.batchNorm = batchNorm
        self.conv1 = conv(self.batchNorm, 1, 8, stride=2)
        self.deconv1 = deconv(8, 1)

        for m in self.modules():
            if isinstance(m, nn.Conv2d) or isinstance(m, nn.ConvTranspose2d):
                kaiming_normal_(m.weight, 0.1)
                if m.bias is not None:
                    constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm2d):
                constant_(m.weight, 0.1)
                constant_(m.bias, 0)

    def forward(self, x):
        out_conv1 = self.conv1(x)
        out_deconv1 = self.deconv1(out_conv1)
        return out_deconv1


class SNet(nn.Module):
    expansion = 1

    def __init__(self, batchNorm=True):
        super(SNet, self).__init__()
        self.batchNorm = batchNorm
        self.conv1 = conv(self.batchNorm, 2, 16, stride=2)
        self.conv2 = conv(self.batchNorm, 16, 32, stride=2)
        self.conv3 = conv(self.batchNorm, 32, 32, stride=2)
        self.conv4 = conv(self.batchNorm, 32, 32, stride=2)
        self.deconv4 = deconv(32, 32)
        self.deconv3 = deconv(64, 32)
        self.deconv2 = deconv(64, 32)
        self.deconv1 = deconv(48, 32)
        self.conv5 = conv(self.batchNorm, 32, 8)
        self.conv6 = conv(self.batchNorm, 8, 8)
        self.conv7 = conv(self.batchNorm, 8, 1)
        self.conv8 = conv(self.batchNorm, 32, 1)
        self.conv9 = nn.Conv2d(1, 1, kernel_size=3, stride=1, padding=2//2, bias=False)

        for m in self.modules():
            if isinstance(m, nn.Conv2d) or isinstance(m, nn.ConvTranspose2d):
                kaiming_normal_(m.weight, 0.1)
                if m.bias is not None:
                    constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm2d):
                constant_(m.weight, 0.1)
                constant_(m.bias, 0)
        self.conv9.apply(init_weight)

    def forward(self, x):
        out_conv1 = self.conv1(x)
        out_conv2 = self.conv2(out_conv1)
        out_conv3 = self.conv3(out_conv2)
        out_conv4 = self.conv4(out_conv3)
        out_deconv4 = self.deconv4(out_conv4)
        concat4 = torch.cat((out_deconv4, out_conv3), 1)
        out_deconv3 = self.deconv3(concat4)
        concat3 = torch.cat((out_deconv3, out_conv2), 1)
        out_deconv2 = self.deconv2(concat3)
        concat2 = torch.cat((out_deconv2, out_conv1), 1)
        out_deconv1 = self.deconv1(concat2)
        disp = self.conv8(out_deconv1)
        return disp

    def weight_parameters(self):
        return [param for name, param in self.named_parameters() if 'weight' in name]

    def bias_parameters(self):
        return [param for name, param in self.named_parameters() if 'bias' in name]


def snet(data=None):
    model = SNet(batchNorm=False)
    if data is not None:
        model.load_state_dict(data['state_dict'])
    return model


def snet_bn(data=None):
    model = SNet(batchNorm=True)
    if data is not None:
        model.load_state_dict(data['state_dict'])
    return model
