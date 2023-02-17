import torch
import torch.nn as nn
from torch.nn.init import kaiming_normal_, constant_
from .util import conv, predict_map, deconv, crop_like

__all__ = [
    'flownets', 'flownets_bn'
]


class FlowNetS(nn.Module):
    expansion = 1

    def __init__(self, batchNorm = True):
        super(FlowNetS, self).__init__()
        self.batchNorm = batchNorm
        self.conv0 = conv(self.batchNorm, 2, 16, kernel_size=5)
        self.conv0_1 = conv(self.batchNorm, 16, 16, kernel_size=5)
        self.conv1 = conv(self.batchNorm, 16, 32, kernel_size=5, stride=2)
        self.conv1_1 = conv(self.batchNorm, 32, 32)
        self.conv2 = conv(self.batchNorm, 32, 64, stride=2)
        self.conv2_1 = conv(self.batchNorm, 64, 64)
        self.conv3 = conv(self.batchNorm, 64, 128, stride=2)
        self.conv3_1 = conv(self.batchNorm, 128, 128)
        self.conv4 = conv(self.batchNorm, 128, 256, stride=2)
        self.conv5 = conv(self.batchNorm, 32, 32)
        self.deconv5 = deconv(256, 128)
        self.deconv4 = deconv(256, 32)
        self.deconv3 = deconv(96, 32)
        self.deconv2 = deconv(64, 16)
        self.predict_map2 = predict_map(96)
        self.predict_map1 = predict_map(64)
        self.predict_map0 = predict_map(32)
        self.upsampled_map2_to_1 = nn.ConvTranspose2d(1, 1, 4, 2, 1, bias=False)
        self.upsampled_map1_to_0 = nn.ConvTranspose2d(1, 1, 4, 2, 1, bias=False)

        for m in self.modules():
            if isinstance(m, nn.Conv2d) or isinstance(m, nn.ConvTranspose2d):
                kaiming_normal_(m.weight, 0.1)
                if m.bias is not None:
                    constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm2d):
                constant_(m.weight, 0.1)
                constant_(m.bias, 0)

    def forward(self, x):
        out_conv0 = self.conv0_1(self.conv0(x))
        out_conv1 = self.conv1_1(self.conv1(out_conv0))
        out_conv2 = self.conv2_1(self.conv2(out_conv1))
        out_conv3 = self.conv3_1(self.conv3(out_conv2))
        out_conv4 = self.deconv5(self.conv4(out_conv3))
        concat4 = torch.cat((out_conv4, out_conv3), 1)
        out_deconv3 = self.deconv4(concat4)
        concat3 = torch.cat((out_deconv3, out_conv2), 1)
        map2 = self.predict_map2(concat3)
        out_deconv2 = crop_like(self.deconv3(concat3), out_conv1)
        concat2 = torch.cat((out_deconv2, out_conv1), 1)
        map1 = self.predict_map1(concat2)
        out_deconv1 = crop_like(self.deconv2(concat2), out_conv0)
        concat1 = torch.cat((out_deconv1, out_conv0), 1)
        out_conv = self.conv5(concat1)
        map0 = self.predict_map0(out_conv)

        if self.training:
            return map0, map1, map2
        else:
            return map0

    def weight_parameters(self):
        return [param for name, param in self.named_parameters() if 'weight' in name]

    def bias_parameters(self):
        return [param for name, param in self.named_parameters() if 'bias' in name]


def flownets(data=None):
    model = FlowNetS(batchNorm=False)
    if data is not None:
        model.load_state_dict(data['state_dict'])
    return model


def flownets_bn(data=None):
    model = FlowNetS(batchNorm=True)
    if data is not None:
        model.load_state_dict(data['state_dict'])
    return model
