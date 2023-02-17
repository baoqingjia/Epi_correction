function [ output_args ] = PlotMag( M,N,varargin)
%PLOTMAG Summary of this function goes here
%   Detailed explanation goes here

reshapeMx=reshape(M(:,1),N);
reshapeMy=reshape(M(:,2),N);
reshapeMz=reshape(M(:,3),N);

Mxy=reshapeMx+1i*reshapeMy;
Mz=abs(reshapeMz);
absMxy=abs(Mxy);
PhaseMxy=angle(Mxy);

if(numel(varargin)==0)
    xShowRegion=1:N(1);
    yShowRegion=1:N(2);
    zShowRegion=1:N(3);
    ShowPlane=1;
end
if(numel(varargin)== 1)
    L=varargin{1};
    xShowRegion=linspace(-L(1)/2,L(1)/2,N(1));
    yShowRegion=linspace(-L(2)/2,L(2)/2,N(2));
    zShowRegion=linspace(-L(3)/2,L(3)/2,N(3));
    ShowPlane=1;
end
if(numel(varargin)== 2)
    L=varargin{1};
    xShowRegion=linspace(-L(1)/2,L(1)/2,N(1));
    yShowRegion=linspace(-L(2)/2,L(2)/2,N(2));
    zShowRegion=linspace(-L(3)/2,L(3)/2,N(3));
    ShowPlane=varargin{2};
end

if(numel(varargin)== 3)
    L=varargin{1};

    ShowPlane=varargin{2};
    EffectRegion=varargin{3};
    
    xShowRegion=EffectRegion.x*L(1)/N(1)-L(1)/2;
    yShowRegion=EffectRegion.y*L(2)/N(2)-L(2)/2;
    zShowRegion=EffectRegion.z*L(3)/N(3)-L(3)/2;
    tempMxy=reshapeMx+1i*reshapeMy;
    Mxy=tempMxy(EffectRegion.x,EffectRegion.y,EffectRegion.z);
    tmepMz=abs(reshapeMz);
    Mz=tmepMz(EffectRegion.x,EffectRegion.y,EffectRegion.z);
    absMxy=abs(Mxy);
    tempxxx=angle(Mxy);
    PhaseMxy=angle(Mxy)-mean(tempxxx(:));
    disp(abs(sum(Mxy(1,1,:))));
    disp(sum(abs(Mxy(1,1,:))));
end



figure(111);
switch ShowPlane
    case 1
        subplot(3,2,1)
        imagesc(zShowRegion,yShowRegion,(squeeze(Mz(1,:,:))));colorbar;
        subplot(3,2,2)
        plot(zShowRegion,squeeze(abs(Mz(1,1,:))));
        subplot(3,2,3)
        imagesc(zShowRegion,yShowRegion,(squeeze(abs(Mxy(1,:,:)))));colorbar;
        subplot(3,2,4)
        plot(zShowRegion,(squeeze(abs(Mxy(1,1,:)))));
        subplot(3,2,5)
        imagesc(zShowRegion,yShowRegion,(squeeze(PhaseMxy(1,:,:))));colorbar;
        subplot(3,2,6)
        plot(zShowRegion,(squeeze(PhaseMxy(1,1,:))));
    case 2
        subplot(3,2,1)
        imagesc(xShowRegion,yShowRegion,(squeeze(Mz(:,:,1))));colorbar;
        subplot(3,2,2)
        plot(yShowRegion,squeeze(abs(Mz(1,:,1))));
        subplot(3,2,3)
        imagesc(xShowRegion,yShowRegion,(squeeze(abs(Mxy(:,:,1)))));colorbar;
        subplot(3,2,4)
        plot(yShowRegion,(squeeze(abs(Mxy(end/2,:,1)))));
        subplot(3,2,5)
        imagesc(xShowRegion,yShowRegion,(squeeze(angle(Mxy(:,:,1)))));colorbar;
        subplot(3,2,6)
        plot(yShowRegion,unwrap(squeeze(angle(Mxy(end/2,:,1)))));
     case 3
        subplot(3,2,1)
        imagesc(xShowRegion,yShowRegion,(squeeze(Mz(:,1,:))));colorbar;
        subplot(3,2,2)
        plot(yShowRegion,squeeze(abs(Mz(1,:,1))));
        subplot(3,2,3)
        imagesc(xShowRegion,yShowRegion,(squeeze(abs(Mxy(:,1,:)))));colorbar;
        subplot(3,2,4)
        plot(yShowRegion,(squeeze(abs(Mxy(1,:,1)))));
        subplot(3,2,5)
        imagesc(xShowRegion,yShowRegion,(squeeze(angle(Mxy(:,1,:)))));colorbar;
        subplot(3,2,6)
        plot(yShowRegion,unwrap(squeeze(angle(Mxy(1,:,1)))));
        
    otherwise
        error('the plane is not right');

end

