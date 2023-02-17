import torch
import torch.nn as nn
import torchvision.models as models
from .util import conv, conv1


__all__ = [
    'ucrsf_net'
]

backbone = 'resnet50'


class DecoderBlock(nn.Module):
    def __init__(self, in_channels, mid_channels, out_channels, upsample_mode='pixelshuffle', BN_enable=True):
        super().__init__()
        self.in_channels = in_channels
        self.mid_channels = mid_channels
        self.out_channels = out_channels
        self.upsample_mode = upsample_mode
        self.BN_enable = BN_enable
        self.conv = nn.Conv2d(in_channels=in_channels, out_channels=mid_channels, kernel_size=3, stride=1, padding=1, bias=False)

        if self.BN_enable:
            self.norm1 = nn.BatchNorm2d(mid_channels)
        self.relu1 = nn.ReLU(inplace=False)
        self.relu2 = nn.ReLU(inplace=False)

        if self.upsample_mode == 'deconv':
            self.upsample = nn.ConvTranspose2d(in_channels=mid_channels, out_channels=out_channels, kernel_size=3, stride=2, padding=1, output_padding=1, bias=False)
        elif self.upsample_mode == 'pixelshuffle':
            self.upsample = nn.PixelShuffle(upscale_factor=2)
        if self.BN_enable:
            self.norm2 = nn.BatchNorm2d(out_channels)

    def forward(self, x):
        x = self.conv(x)
        if self.BN_enable:
            x = self.norm1(x)
        x = self.relu1(x)
        x = self.upsample(x)
        if self.BN_enable:
            x = self.norm2(x)
        x = self.relu2(x)
        return x


class UCRSF_Net(nn.Module):
    def __init__(self, BN_enable=True, resnet_pretrain=False):
        super().__init__()
        self.BN_enable = BN_enable
        if backbone == 'resnet34':
            resnet = models.resnet34(pretrained=resnet_pretrain)
            filters = [64, 64, 128, 256, 512]
        elif backbone == 'resnet50':
            resnet = models.resnet50(pretrained=resnet_pretrain)
            filters = [64, 256, 512, 1024, 2048]
        self.firstconv = nn.Conv2d(in_channels=2, out_channels=64, kernel_size=7, stride=2, padding=3, bias=False)
        self.firstbn = resnet.bn1
        self.firstrelu = resnet.relu
        self.firstmaxpool = resnet.maxpool
        self.encoder1 = resnet.layer1
        self.encoder2 = resnet.layer2
        self.center = DecoderBlock(in_channels=filters[2], mid_channels=filters[2]*4, out_channels=filters[2], BN_enable=self.BN_enable)
        self.decoder1 = DecoderBlock(in_channels=filters[2]+filters[1], mid_channels=filters[1]*4, out_channels=filters[1], BN_enable=self.BN_enable)
        self.decoder2 = DecoderBlock(in_channels=filters[1]+filters[0], mid_channels=filters[0]*4, out_channels=filters[0], BN_enable=self.BN_enable)

        if self.BN_enable:
            self.final = nn.Sequential(
                nn.Conv2d(in_channels=filters[0], out_channels=32, kernel_size=3, padding=1),
                nn.BatchNorm2d(32),
                nn.Conv2d(in_channels=32, out_channels=1, kernel_size=1)
                )
        else:
            self.final = nn.Sequential(
                nn.Conv2d(in_channels=filters[0], out_channels=32, kernel_size=3, padding=1),
                nn.Conv2d(in_channels=32, out_channels=1, kernel_size=1),
                )

        self.mconv = conv1(True, 1, 1)
        self.spline_conv1_1 = nn.Conv2d(filters[2], 2, kernel_size=3, stride=2, padding=0)
        self.spline_conv1_2 = nn.Conv2d(filters[2], 2, kernel_size=2, stride=2, padding=0)
        self.spline_conv2_1 = nn.Conv2d(filters[2] + filters[1], 2, kernel_size=4, stride=2, padding=0)
        self.spline_conv2_2 = nn.Conv2d(filters[2] + filters[1], 2, kernel_size=1, stride=2, padding=0)
        self.spline_conv3_1 = nn.Conv2d(filters[1] + filters[0], 2, kernel_size=4, stride=2, padding=0)
        self.spline_conv3_2 = nn.Conv2d(filters[1] + filters[0], 2, kernel_size=5, stride=2, padding=0)

    def forward(self, x):
        x = self.firstconv(x)
        x = self.firstbn(x)
        x = self.firstrelu(x)
        x_ = self.firstmaxpool(x)
        e1 = self.encoder1(x_)
        e2 = self.encoder2(e1)
        spline_1_1 = self.spline_conv1_1(e2)
        spline_1_2 = self.spline_conv1_2(e2)
        center = self.center(e2)
        spline_2_1 = self.spline_conv2_1(torch.cat([center, e1], dim=1))
        spline_2_2 = self.spline_conv2_2(torch.cat([center, e1], dim=1))
        d2 = self.decoder1(torch.cat([center, e1], dim=1))
        spline_3_1 = self.spline_conv3_1(torch.cat([d2, x], dim=1))
        spline_3_2 = self.spline_conv3_2(torch.cat([d2, x], dim=1))
        spline_all = [spline_1_1[:, :, :3, :3], spline_1_2[:, :, :4, :4], spline_2_1[:, :, :5, :5], spline_2_2[:, :, :6, :6], spline_3_1[:, :, :8, :8], spline_3_2[:, :, :10, :10]]
        return spline_all

    def weight_parameters(self):
        return [param for name, param in self.named_parameters() if 'weight' in name]

    def bias_parameters(self):
        return [param for name, param in self.named_parameters() if 'bias' in name]


def ucrsf_net(data=None):
    model = UCRSF_Net(BN_enable=True, resnet_pretrain=False)
    if data is not None:
        model.load_state_dict(data['state_dict'])
    return model
