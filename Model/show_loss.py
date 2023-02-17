import numpy as np
import matplotlib.pyplot as plt
import pylab as pl

dir='./model'

loss = np.load('/%s/lossall_train2.npy'%(dir))
loss_t1 = np.load('/%s/lossall_train_t1_mse.npy'%(dir))
loss_mse_cup_cdown_xmask = np.load('/%s/lossall_train_mse_cup_cdown_xmask.npy'%(dir))
loss_mse_cup_cdown = np.load('/%s/lossall_train_mse_cup_cdown.npy'%(dir), allow_pickle=True)
loss_cir = np.load('/%s/lossall_train_cir.npy'%(dir), allow_pickle=True)

x = np.arange(201)
x1 = np.arange(201)
x2 = np.arange(201)
x3 = np.arange(201)
x4 = np.arange(201)

print(loss[200])
print(loss_mse_cup_cdown[200])
print(loss_cir[200])
print(loss_mse_cup_cdown_xmask[200])

plt.figure()
pl.plot(x, loss, 'g-', label=u'lossall')
p2 = pl.plot(x1, loss_t1, 'r-', label=u'loss_t1')
pl.legend()
p3 = pl.plot(x2, loss_mse_cup_cdown_xmask, 'b-', label=u'loss_mse_cup_cdown_xmask')
pl.legend()
p4 = pl.plot(x3, loss_mse_cup_cdown, 'y-', label=u'loss_mse_cup_cdown')
pl.legend()
p5 = pl.plot(x4, loss_cir, 'c-', label=u'loss_cir')
pl.legend()
pl.xlabel(u'iters')
pl.ylabel(u'loss')
plt.title('Compare different loss for models in training')
plt.show()
