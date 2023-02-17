close all; clear; clc;
gammaHz=4.2574e+3 ; % [Hz/G]
L=[10]/100; %the readout, phase, slice
N=[128*32]; %point of spin 
spectrum=0;
% Optionally add some inhomogeneities
imap.a1 = [0e3]; % in Hz/cm
imap.a2 = [0e3]; % in Hz/(cm^2)
imap.ar = 00; % in Hz
% Define the phantom
phantomtype = 'circle';
phantomscale = [1 1 1];
[M r offsets] = spin_system3D(L,N,spectrum);
% Take inhomogeneity into account
offsets = inhomogeneise3D(offsets,r,N,imap);

ShowLIndex=linspace(-L/2,L/2,N);

MBFraction=[1];
FractionPhase=[0];
FractionNum=length(MBFraction);
MBNum=FractionNum;
WholeThk=10/1000; %unit  mm

BWe = 3000; % unit Hz
thk=WholeThk/sum(MBFraction)*MBFraction; % unit m

TempGrad=BWe./thk;
sliceSeleRFParams.Gmax=max(TempGrad);
MBSliceCenter=zeros(1,length(MBFraction));
MBSliceCenter(1)=MBFraction(1)/2/sum(MBFraction)*WholeThk-WholeThk/2;
for iMBIndex=2:FractionNum
    MBSliceCenter(iMBIndex)=-WholeThk/2+sum(MBFraction(1:iMBIndex-1))/sum(MBFraction)*WholeThk+MBFraction(iMBIndex)/2/sum(MBFraction)*WholeThk;
end

for iMBIndex =1:length(MBFraction)
    
    BWePerMB=sliceSeleRFParams.Gmax*thk(iMBIndex);

    NPulseStep=1024;
    sliceSeleRFParams.type='SLR';
    sliceSeleRFParams.timestep = 4e-6 ;
    sliceSeleRFParams.nsteps=round(NPulseStep);
    
    sliceSeleRFParams.SLRfiltertype = 'equiripple';
    sliceSeleRFParams.theta = 90;
    sliceSeleRFParams.filtern = sliceSeleRFParams.nsteps;
    sliceSeleRFParams.SLRdesign = 'pulse';
    sliceSeleRFParams.SLRpulsetype = 'excitation';
    duration_lobe = sliceSeleRFParams.nsteps*sliceSeleRFParams.timestep;
    sliceSeleRFParams.tbw = ...
        sliceSeleRFParams.Gmax*thk(iMBIndex)*sliceSeleRFParams.nsteps*sliceSeleRFParams.timestep;
    sliceSeleRFParams.inripple = 0.0001;
    sliceSeleRFParams.outripple = 0.0001;
    ExctiteRFwaveform = create_rf_waveform(sliceSeleRFParams);
    
    FileName=['SLR_BWe' num2str(BWePerMB)  'Hz_' num2str(sliceSeleRFParams.Gmax/gammaHz/100) 'Gau' '_' 'theta_' .....
    num2str(sliceSeleRFParams.theta) '_length' num2str(duration_lobe*1000) 'ms' '.RF' ];
    SaveRFVarian( ExctiteRFwaveform,FileName,sliceSeleRFParams )
    
    
    FreqForPerMBSlice=zeros(1,MBNum);
    pulsetime = sliceSeleRFParams.timestep*((1:sliceSeleRFParams.nsteps)-0.5);
    
    FreqForPerMBSlice=2*pi*sliceSeleRFParams.Gmax*MBSliceCenter(iMBIndex);
    
    tempRFwaveform{iMBIndex}.B1 = ExctiteRFwaveform.B1;
    tempRFwaveform{iMBIndex}.G = ExctiteRFwaveform.G;
    tempRFwaveform{iMBIndex}.phi = ExctiteRFwaveform.phi+FreqForPerMBSlice*pulsetime;
    tempRFwaveform{iMBIndex}.deltat = ExctiteRFwaveform.deltat;
end
temp=0;
for iMBIndex=1:MBNum
    temp = temp+tempRFwaveform{iMBIndex}.B1.*exp(1i*tempRFwaveform{iMBIndex}.phi).*exp(1i*FractionPhase(iMBIndex));
end
SingleRFwaveform.B1=abs(temp);
SingleRFwaveform.G = ExctiteRFwaveform.G;
SingleRFwaveform.phi=angle(temp);
SingleRFwaveform.deltat=ExctiteRFwaveform.deltat;


M = softpulse(M,r(:,1),offsets,SingleRFwaveform);

reshapeMx=reshape(M(:,1),[N 1]);
reshapeMy=reshape(M(:,2),[N 1]);
reshapeMz=reshape(M(:,3),[N 1]);
Mxy=reshapeMx+1i*reshapeMy;
absMxy=abs(Mxy);
PhaseMxy=unwrap(angle(Mxy));
figure(2);
subplot(3,1,1)
plot(ShowLIndex,reshapeMz);
subplot(3,1,2)
plot(ShowLIndex,absMxy);
subplot(3,1,3)
plot(ShowLIndex,PhaseMxy);

figure(20);
subplot(3,1,1)
plot(ShowLIndex,reshapeMz);
subplot(3,1,2)
plot(ShowLIndex,reshapeMx);
subplot(3,1,3)
plot(ShowLIndex,reshapeMy);

EffectPoint=round(WholeThk/L*N);
EffectRegion=N/2-round(EffectPoint/2):N/2-round(EffectPoint/2)+EffectPoint+2;
ShowEffecLIndex=linspace(-WholeThk/2,WholeThk/2,length(EffectRegion));

figure(3);
subplot(3,1,1)
plot(ShowEffecLIndex,reshapeMz(EffectRegion));
subplot(3,1,2)
plot(ShowEffecLIndex,absMxy(EffectRegion));
subplot(3,1,3)
plot(ShowEffecLIndex,PhaseMxy(EffectRegion));

Tpslice = sliceSeleRFParams.timestep *NPulseStep ;
% M = gradientlobe(M,r(:,3),offsets,-2*pi*Gmax,Te/2);
Gmax = sliceSeleRFParams.Gmax ;
M = gradientlobe(M,r(:,1),offsets,-2*pi*Gmax,Tpslice/2);

reshapeMx=reshape(M(:,1),[N 1]);
reshapeMy=reshape(M(:,2),[N 1]);
reshapeMz=reshape(M(:,3),[N 1]);
Mxy=reshapeMx+1i*reshapeMy;
absMxy=abs(Mxy);
PhaseMxy=unwrap(angle(Mxy));

figure(21);
subplot(3,1,1)
plot(ShowLIndex,reshapeMz);
subplot(3,1,2)
plot(ShowLIndex,absMxy);
subplot(3,1,3)
plot(ShowLIndex,PhaseMxy);


figure(4);
subplot(3,1,1)
plot(ShowEffecLIndex,reshapeMz(EffectRegion));
subplot(3,1,2)
plot(ShowEffecLIndex,absMxy(EffectRegion));
subplot(3,1,3)
plot(ShowEffecLIndex,PhaseMxy(EffectRegion));


figure(40);
subplot(3,1,1)
plot(ShowEffecLIndex,reshapeMz(EffectRegion));
subplot(3,1,2)
plot(ShowEffecLIndex,reshapeMx(EffectRegion));
subplot(3,1,3)
plot(ShowEffecLIndex,reshapeMy(EffectRegion));


disp('over');