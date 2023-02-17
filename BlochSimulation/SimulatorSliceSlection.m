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

%% define slice slection parameters
sliceNum=1;
sliceGap=0;
sliceCenter=0;
thk=20/1000;
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

SliceIndex=[-round(sliceNum/2)+1:1:-round(sliceNum/2)+sliceNum];
slicePosition = sliceCenter+(thk+sliceGap)*SliceIndex;
pulsetime = timestep*((1:nsteps)-0.5);
for iSliceIndex=1:sliceNum
    RFwaveform{iSliceIndex}.B1 = B1;
    RFwaveform{iSliceIndex}.G = G;
    RFwaveform{iSliceIndex}.phi = phi+2*pi*Gmax*slicePosition(iSliceIndex)*pulsetime;
    RFwaveform{iSliceIndex}.deltat = deltat;
end

for iSliceIndex=1:sliceNum
    
    [M r offsets] = spin_system3D(L,N,spectrum);
    M = softpulse(M,r(:,3),offsets,RFwaveform{iSliceIndex});
    PlotSeqWave.type='pulse';
    PlotSeqWave.shape=RFwaveform;
    PlotSeqWave.GradDirection='slice';
    PlotSeqBlock{1}=PlotSeqWave;
    PlotMag(M,N);
    
    %% slice refocus gradient
    % Use a gradient lobe to remove the linear phase
    Tpslice = SLR_RF.duration;
    M = gradientlobe(M,r(:,3),offsets,-2*pi*Gmax,Tpslice/2);
    Gradwaveform.G=-Gmax;
    Gradwaveform.deltat=Tpslice/2;
    clear PlotSeqWave;
    PlotSeqWave.type='gradient';
    PlotSeqWave.shape=Gradwaveform;
    PlotSeqWave.GradDirection='slice';
    PlotSeqBlock{2}=PlotSeqWave;
    PlotMag(M,N);
end

