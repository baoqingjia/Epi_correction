%For simulate, we need Phantom,Pulse sequence.
close all; clear; clc;

% load Imag3DGRE_good.mat;
% nii = make_nii(abs(iField));
% fileprefix='niidata.nii'
% save_nii(nii, fileprefix, 0);

gammaHz=4.2574e+3 ; % [Hz/G]
%% define in-plane spin system parameter;
L=[4 4 4]/100; %the readout, phase, slice
N=[1 128 128*8]; %point of spin 
AcqPoint=[1 128 128]; %point of acquire frequency phase slice
ChirpQvalue=120;  % Qvalue of the chirp 
sw=250000; % unit Hz
Ta = AcqPoint(1)*AcqPoint(2)/sw;
ChripTP=Ta/2; % unit second

spectrum=0;
% Optionally add some inhomogeneities
imap.a1 = [0e3 0e3 0e3]; % in Hz/cm
imap.a2 = [0e6 0e6 0e3]; % in Hz/(cm^2)
imap.ar = 00; % in Hz
% Define the phantom
phantomtype = 'circle';
phantomscale = [1 1 1];
[M r offsets] = spin_system3D(L,N,spectrum);
% Take inhomogeneity into account
offsets = inhomogeneise3D(offsets,r,N,imap);

% parameters define
thk=5/1000;
bLoadVarianPulse=true;
FilePath='D:\NewMatlabCode\matlabcode\FuncTool_New\FuncTool\Bloch_simulator_Bao\shapelib';
pulsepat='SPENchirp180';
PulseLength=4e-3;%unit second
FilpAngle=90;
B1max=1000;
% the last two is frequency carrier and B1max this is for chirp
ExctiteRFwaveform=loadVarianPulse(FilePath,pulsepat,PulseLength,FilpAngle,thk,'excite',0,B1max);
% for normal pulse 
% ExctiteRFwaveform=loadVarianPulse(FilePath,pulsepat,PulseLength,FilpAngle,thk,'excite',0);



M = softpulse(M,r(:,3),offsets,ExctiteRFwaveform);
PlotMag( M,N);

M = gradientlobe(M,r(:,3),offsets,-max(ExctiteRFwaveform.G),PulseLength/2);
PlotMag( M,N);

EffectPoint=round(thk/L(3)*N(3));
EffectRegion=N(3)/2-round(EffectPoint/2):N(3)/2-round(EffectPoint/2)+EffectPoint+2;
EffectRegion3D.x=1:N(1);
EffectRegion3D.y=1:N(2);
EffectRegion3D.z=EffectRegion;
PlotMag(M,N,L,1,EffectRegion3D);

% PulseSequenceDefine_SPEN;
