"""Small NumPy equivalents for the frame pipeline when SciPy is unavailable."""
import numpy as np


class Rotation:
    @classmethod
    def from_quat(cls, q):
        result = cls()
        result.q = np.asarray(q) / np.linalg.norm(q, axis=-1, keepdims=True)
        return result

    def as_matrix(self):
        x, y, z, w = np.moveaxis(self.q, -1, 0)
        return np.stack([
            1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w),
            2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w),
            2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)
        ], axis=-1).reshape(self.q.shape[:-1]+(3,3))


class CubicSpline:
    """Interpolating cubic with the same default not-a-knot end conditions."""
    def __init__(self, x, y):
        self.x, self.y = np.asarray(x), np.asarray(y)
        h = np.diff(x)
        n = len(x)
        a = np.zeros((n,n)); rhs = np.zeros_like(y)
        for i in range(1,n-1):
            a[i,i-1:i+2] = [h[i-1],2*(h[i-1]+h[i]),h[i]]
            rhs[i] = 6*((y[i+1]-y[i])/h[i]-(y[i]-y[i-1])/h[i-1])
        a[0,:3] = [-h[1],h[0]+h[1],-h[0]]
        a[-1,-3:] = [-h[-1],h[-2]+h[-1],-h[-2]]
        self.second = np.linalg.solve(a,rhs)

    def __call__(self, t):
        i = np.clip(np.searchsorted(self.x,t)-1,0,len(self.x)-2)
        h = self.x[i+1]-self.x[i]
        a = ((self.x[i+1]-t)/h)[:,None]
        b = ((t-self.x[i])/h)[:,None]
        return a*self.y[i]+b*self.y[i+1]+((a**3-a)*self.second[i]+(b**3-b)*self.second[i+1])*h[:,None]**2/6


def sample(image, uv):
    h,w = image.shape[:2]
    xy = np.clip(uv*[w,h]-.5,[0,0],[w-1.00001,h-1.00001])
    ij = np.floor(xy).astype(int)
    x,y = ij.T
    fx,fy = (xy-ij).T
    return ((image[y,x]*(1-fx[:,None])+image[y,x+1]*fx[:,None])*(1-fy[:,None])+
            (image[y+1,x]*(1-fx[:,None])+image[y+1,x+1]*fx[:,None])*fy[:,None])
