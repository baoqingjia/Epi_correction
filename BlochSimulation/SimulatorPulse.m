%For simulate, we need Phantom,Pulse sequence.
close all; clear; clc;

% load Imag3DGRE_good.mat;
% nii = make_nii(abs(iField));
% fileprefix='niidata.nii'
% save_nii(nii, fileprefix, 0);

gammaHz=4.2574e+3 ; % [Hz/G]
%% define in-plane spin system parameter;
L=[4 4 4]/100; %the readout, phase, slice
N=[128 128*8 1]; %point of spin 
AcqPoint=[128 128 1]; %point of acquire frequency phase slice
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

%% define slice slection parameters
thk=5/1000;
SLR_RF.pulname='slr_pulse';
SLR_RF.duration=0.003;
SLR_RF.pts=1000;
SLR_RF.flip=90;
SLR_RF.bandwith=4; %unit kHz
SLR_RF.inripple=0.0001;
SLR_RF.outripple=0.0001;
SLR_RF.filtertype='equiripple';
SLR_RF.pulsetype='excitation';

%% define chirp pulse
ChirpRFParams.type = 'chirp';
ChirpRFParams.timestep = 40e-6 ;
ChirpRFParams.nsteps = ChripTP/ChirpRFParams.timestep; 
ChirpRFParams.Gmax = ChirpQvalue/ChripTP/L(2); % gradient along y, in Hz/m
ChirpRFParams.nu_rf_0 = 0; % carrier frequency at the center of the sweep
Te=ChirpRFParams.timestep*ChirpRFParams.nsteps;
ChirpRFParams.Gmax = ChirpQvalue/ChripTP/L(2); % gradient along x, in Hz/m
ChirpRFParams.R = ChirpQvalue/ChripTP/ChripTP;
ChirpRFParams.wurstn = 40;
ChirpRFParams.B1max = 3*0.26*sqrt(ChirpRFParams.R);% c
if strcmp(ChirpRFParams.type(end-4:end),'chirp')
    Q = Te^2*ChirpRFParams.R;
    disp(['The quality factor is ' int2str(nearest(Q))]);
end
disp(['Quality factor: ' int2str(nearest(Q))]);



%% define the acquisition parameters
FOV = L(1:2);
ACQParams.timestep = 1/sw;
ACQParams.NPE = AcqPoint(2); %phase encoding
ACQParams.nRO = AcqPoint(1); %readout  
ACQParams.GRO = 1/(FOV(1)*ACQParams.timestep);
ACQParams.GPE = -ChirpRFParams.Gmax;
disp('over');

%% define other pulse sequence parameter  such as crush 
crushduration=2e-3;% unit s
Gcrush=gammaHz*10*100;

%% genetor pulse sequence slice selection

[p1_rf thetalong, philong]=CreateSLR_RF(SLR_RF);
%%%%% use for simulate
nsteps=p1_rf.pts;
timestep=p1_rf.duration/nsteps;
Gmax=p1_rf.bandwidth*1000/thk;

polyn = length(thetalong);
theta = thetalong(polyn/2-nsteps/2+1:polyn/2+nsteps/2);
phi = philong(polyn/2-nsteps/2+1:polyn/2+nsteps/2);

B1 = theta / timestep;
G = 2 * pi * Gmax * ones(1,nsteps);
deltat = timestep * ones(1,nsteps);
RFwaveform.B1 = B1;
RFwaveform.G = G;
RFwaveform.phi = phi;
RFwaveform.deltat = deltat;

% M = softpulse(M,r(:,3),offsets,RFwaveform);
PlotSeqWave.type='pulse';
PlotSeqWave.shape=RFwaveform;
PlotSeqWave.GradDirection='slice';
PlotSeqBlock{1}=PlotSeqWave;

% PlotMag( M,N);

%% slice refocus gradient
% Use a gradient lobe to remove the linear phase
Tpslice = SLR_RF.duration;
% M = gradientlobe(M,r(:,3),offsets,-2*pi*Gmax,Te/2);
Gradwaveform.G=-Gmax;
Gradwaveform.deltat=Tpslice/2;
clear PlotSeqWave;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='slice';
PlotSeqBlock{2}=PlotSeqWave;
% PlotMag( M,N);

%% delay for fully recouse
duration=Ta/2;
% M = delay(M,offsets,duration);
clear PlotSeqWave;
PlotSeqWave.type='delay';
PlotSeqWave.duration=duration;
PlotSeqBlock{3}=PlotSeqWave;
% PlotMag( M,N);

%% gradient for crush
% M = gradientlobe(M,r(:,2),offsets,-2*pi*Gcrush,crushduration);
clear PlotSeqWave;
Gradwaveform.G=Gcrush;
Gradwaveform.deltat=crushduration;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='phase';
PlotSeqBlock{4}=PlotSeqWave;
% PlotMag(M,N);


%% chirp 
% Create the chirp waveform
ChirpRFwaveform = create_rf_waveform(ChirpRFParams);

clear PlotSeqWave;
PlotSeqWave.type='pulse';
PlotSeqWave.shape=ChirpRFwaveform;
PlotSeqWave.GradDirection='phase';
PlotSeqBlock{5}=PlotSeqWave;
% M = softpulse(M,r(:,2),offsets,ChirpRFwaveform);% Calculate the action of the chirp pulse

%% crush gradient

% M = gradientlobe(M,r(:,2),offsets,-2*pi*Gcrush,crushduration);
clear PlotSeqWave;
Gradwaveform.G=Gcrush;
Gradwaveform.deltat=crushduration;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='phase';
PlotSeqBlock{6}=PlotSeqWave;
% PlotMag(M,N);

%% % Prefocusing lobe as echo in the center
% M = gradientlobe(M,r,offsets,...
%     [2*pi*ACQParams.GRO; pi*ChirpRFParams.Gmax*Ta/(ACQParams.nRO/2*ACQParams.timestep)],ACQParams.nRO/2*ACQParams.timestep);
clear PlotSeqWave Gradwaveform;
Gradwaveform.G=[2*pi*ACQParams.GRO; pi*ChirpRFParams.Gmax*Ta/(ACQParams.nRO/2*ACQParams.timestep)];
Gradwaveform.deltat=ACQParams.nRO/2*ACQParams.timestep;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='phase&readout';
PlotSeqBlock{7}=PlotSeqWave;
% PlotMag(M,N);

%% acquire fid
% Create the acquisition trajectory
ACQtrajectory = epi(ACQParams);
% fid = acquisition(M,r,offsets,ACQtrajectory);
clear PlotSeqWave;
PlotSeqWave.type='acquire';
PlotSeqWave.shape=ACQtrajectory;
PlotSeqWave.duration=Ta;
PlotSeqBlock{8}=PlotSeqWave;

PlotPulseSeqence(PlotSeqBlock);

disp('over');

% parameters define
% thk=5/1000;
% bLoadVarianPulse=true;
% FilePath='D:\NewMatlabCode\matlabcode\FuncTool_New\FuncTool\Bloch_simulator_Bao\shapelib';
% pulsepat='sinc';
% PulseLength=2e-3;%unit second
% FilpAngle=90;
% % the last one is frequency carrier
% ExctiteRFwaveform=loadVarianPulse(FilePath,pulsepat,PulseLength,FilpAngle,thk,'excite',0);
% M = softpulse(M,r(:,3),offsets,ExctiteRFwaveform);
% PlotMag( M,N);

% BWe = 5.0e3; % unit Hz
% thk=5/1000; % unit m
% BWe=5000; % unit Hz
% NPulseStep=500;
% sliceSeleRFParams.type='SLR';
% sliceSeleRFParams.timestep = 4e-6 ;
% sliceSeleRFParams.nsteps=round(NPulseStep);
% sliceSeleRFParams.Gmax = BWe/thk; %Hz/m
% sliceSeleRFParams.SLRfiltertype = 'equiripple';
% sliceSeleRFParams.theta = 90;
% sliceSeleRFParams.filtern = sliceSeleRFParams.nsteps;
% sliceSeleRFParams.SLRdesign = 'pulse';
% sliceSeleRFParams.SLRpulsetype = 'excitation';
% duration_lobe = sliceSeleRFParams.nsteps*sliceSeleRFParams.timestep;
% sliceSeleRFParams.tbw = ...
%     sliceSeleRFParams.Gmax*thk*sliceSeleRFParams.nsteps*sliceSeleRFParams.timestep;
% sliceSeleRFParams.inripple = 0.005;
% sliceSeleRFParams.outripple = 0.005;
% ExctiteRFwaveform = create_rf_waveform(sliceSeleRFParams);
% PulseSequenceBlock{1}=ExctiteRFwaveform;
% 
% M = softpulse(M,r(:,3),offsets,ExctiteRFwaveform);
% PlotMag( M,N)
% disp('over');

% PulseSequenceDefine_SPEN;
