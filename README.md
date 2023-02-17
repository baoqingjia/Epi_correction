# Epi_correction
# DLRPG-net (UCRSF-Net) Pytorch
Pytorch implementation of our proposed "Unsupervised Cycle-consistent Restricted Subspace Field map network (UCRSF-Net) "(In the article submitted, we call it DLRPG-net) by Qingjia et al.

This repository is a torch implementation of our proposed DLRPG-net (UCRSF-Net) by Qingjia Bao et al. in PyTorch. See Torch implementation [here](https://github.com/baoqingjia/EPI_correction).There are three folders, including the network model, pulse sequence on PV5, and the Matlab code of Bloch Simulation.

This code is mainly inspired from official [imagenet example](https://github.com/pytorch/examples/tree/master/imagenet) of [FlowNet](http://lmb.informatik.uni-freiburg.de/Publications/2015/DFIB15/)
We learned the idea of building a deep learning model with PyTorch in their code. Then, the network model is rebuilt according to our proposed susceptibility artifact correction method, and almost all the codes are modified. Here, we express our heartfelt thanks for their contributions.

## Prerequisite
these modules can be installed with `pip`

```
torch>=1.2
numpy
h5py
argparse
scipy
os
```

or
```bash
pip install -r requirements.txt
```
