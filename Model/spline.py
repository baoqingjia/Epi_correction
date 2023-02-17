import numpy as np
import math
import matplotlib.pyplot as plt


anum = 0.0001


def Bsplinebao(current_support, ImagSize, basistype):
    Dimmesion = np.shape(current_support)
    B = np.empty(Dimmesion, dtype=object)
    hx = np.zeros(Dimmesion)
    for aa in range(Dimmesion[0]):
        if current_support[aa] == 1:
            B[aa] = 1
            hx[aa] = 0
        else:
            if basistype == 'linear':
                hx[aa] = (np.round(1/2*(current_support[aa] - 1+anum)))
            else:
                hx[aa] = (np.round(1/4*(current_support[aa] - 1+anum)))
        hx = np.array(hx, dtype=int)
        t1 = np.linspace(0, 1, hx[aa]+1)
        t2 = np.linspace(1, 2, hx[aa] + 1)
        t2 = t2[1:]
        tmp_B = np.zeros(Dimmesion)
        if basistype == 'linear':
            x1 = np.flipud(t1[: -1])
            tmp_B = np.hstack((t1, x1))
        elif basistype == 'cubic':
            x1 = 2 / 3 - np.multiply((1 - np.divide(abs(t1), 2)), np.power(t1,2))
            x2 = np.power(1 / 6 * (2 - abs(t2)), 3)
            x = np.hstack((x1, x2))
            tmp_B = np.hstack((np.flipud(x[1:]), x))
        B[aa] = tmp_B
    return B, hx


def SDS_BSpline_Basis(B, hx, full_res):
    basis = []
    tmp_basis = []
    full_res = np.array(full_res, dtype=int)
    lens = np.size(B)
    for bb in range(np.size(B)):
        if all(B[bb] == 1):
            basis[bb] = np.ones((1, full_res[bb]))
        else:
            extent = 3 * hx[bb] - 1 + full_res[bb]
            num_vecs = math.floor((((extent - 1) - 1) / hx[bb]) + 1)
            last_starting = (num_vecs - 1) * hx[bb] + 1
            support_size = np.size(B[bb])
            tmp_basis = np.zeros((num_vecs, last_starting + support_size - 1))
            for aa in range(num_vecs):
                tmp_basis[aa, aa * hx[bb]: aa * hx[bb] + support_size] = B[bb]
            tmp_basis = tmp_basis[:, 3 * hx[bb]: 3 * hx[bb] + full_res[bb]]
            indx = []
            for aa in range(tmp_basis.shape[0]):
                if np.sum(np.abs(tmp_basis[aa, :])) == 0:
                    indx = np.hstack((indx, aa))
            indx = np.array(indx, dtype=int)
            if np.size(indx) > 0:
               tmp_basis = np.delete(tmp_basis, indx, axis=0)
            basis.append(tmp_basis)
    return basis
