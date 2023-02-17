%For simulate, we need Phantom,Pulse sequence.
% define in-plane spin system parameter;
close all; clear; clc;
load Imag3DGRE_good.mat;
gammaHz=4.2574e+3 ; % [Hz/G]
Nseg=5;

L=[4 4 4]/100; %the readout, phase, slice
N=size(iField); %point of spin 
AcqPoint=[200 200 4]; %point of acquire frequency phase slice

SpinContrast=round(abs(iField));
SpinContrast=SpinContrast/max(SpinContrast(:));
figure(1);imshow3Dfull(SpinContrast)

nii = make_nii(abs(iField));
fileprefix='niidata_before.nii'
save_nii(nii, fileprefix, 0);

[y x z]=...
   ndgrid(linspace(1,size(SpinContrast,1),N(1)),...
          linspace(1,size(SpinContrast,2),N(2)),...
          linspace(1,size(SpinContrast,3),N(3)));
SpinContrastResize=interp3(SpinContrast,x,y,z);

figure(2);imshow3Dfull(SpinContrastResize(:,1:8:end,:))
nii1 = make_nii(abs(SpinContrastResize));
fileprefix='niidata_after.nii'
save_nii(nii, fileprefix, 0);


%%
ChirpQvalue=120;  % Qvalue of the chirp 
sw=500000; % unit Hz
Ta = AcqPoint(1)*AcqPoint(2)/sw/Nseg;
ChripTP=Ta/2; % unit second

spectrum=0;
% Optionally add some inhomogeneities
imap.a1 = [0e3 0e3 0e3]; % in Hz/cm
imap.a2 = [0e6 0e6 0e3]; % in Hz/(cm^2)
imap.ar = 00; % in Hz
% Define the phantom
phantomtype = 'circle';
phantomscale = [1 1 1];



%% define slice slection parameters 
sliceNum=AcqPoint(3);
sliceCenter=0;
sliceGap=0;
thk=1/1000; %unit m
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
    disp(['The quality factor is ' int2str(ceil(Q))]);
end
disp(['Quality factor: ' int2str(ceil(Q))]);



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
GSlicemax=Gmax;

polyn = length(thetalong);
theta = thetalong(polyn/2-nsteps/2+1:polyn/2+nsteps/2);
phi = philong(polyn/2-nsteps/2+1:polyn/2+nsteps/2);

B1 = theta / timestep;
G = 2 * pi * Gmax * ones(1,nsteps);
deltat = timestep * ones(1,nsteps);

% multislice experiment
SliceIndex=[-round(sliceNum/2):1:-round(sliceNum/2)+sliceNum-1];
slicePosition = sliceCenter+(thk+sliceGap)*SliceIndex;
pulsetime = timestep*((1:nsteps)-0.5);
for iSliceIndex=1:sliceNum
    RFwaveform{iSliceIndex}.B1 = B1;
    RFwaveform{iSliceIndex}.G = G;
    RFwaveform{iSliceIndex}.phi = phi+2*pi*Gmax*slicePosition(iSliceIndex)*pulsetime;
    RFwaveform{iSliceIndex}.deltat = deltat;
    PlotSeqWave.type='pulse';
    PlotSeqWave.shape=RFwaveform{iSliceIndex};
    PlotSeqWave.GradDirection='slice';
    PlotSeqBlock{1}{iSliceIndex}=PlotSeqWave;
end

% slice refocus gradient Use a gradient lobe to remove the linear phase
Tpslice = SLR_RF.duration;
Gradwaveform.G=-Gmax;
Gradwaveform.deltat=Tpslice/2;
clear PlotSeqWave;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='slice';
PlotSeqBlock{2}=PlotSeqWave;

%% delay for fully recouse
duration=Ta/2;
clear PlotSeqWave;
PlotSeqWave.type='delay';
PlotSeqWave.duration=duration;
PlotSeqBlock{3}=PlotSeqWave;

%% gradient for crush
clear PlotSeqWave;
Gradwaveform.G=Gcrush;
Gradwaveform.deltat=crushduration;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='phase';
PlotSeqBlock{4}=PlotSeqWave;

% Create the chirp waveform
ChirpRFwaveform = create_rf_waveform(ChirpRFParams);
clear PlotSeqWave;
PlotSeqWave.type='pulse';
PlotSeqWave.shape=ChirpRFwaveform;
PlotSeqWave.GradDirection='phase';
PlotSeqBlock{5}=PlotSeqWave;

% crush gradient
clear PlotSeqWave;
Gradwaveform.G=Gcrush;
Gradwaveform.deltat=crushduration;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='phase';
PlotSeqBlock{6}=PlotSeqWave;

% Prefocusing lobe as echo in the center
clear PlotSeqWave Gradwaveform;
Gradwaveform.G=[2*pi*ACQParams.GRO; pi*ChirpRFParams.Gmax*Ta/(ACQParams.nRO/2*ACQParams.timestep)]/2/pi;
Gradwaveform.deltat=ACQParams.nRO/2*ACQParams.timestep;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='phase&readout';
PlotSeqBlock{7}=PlotSeqWave;

% Create the acquisition trajectory
ACQtrajectory = epi(ACQParams);
clear PlotSeqWave;
PlotSeqWave.type='acquire';
PlotSeqWave.shape=ACQtrajectory;
PlotSeqWave.duration=Ta;
PlotSeqWave.FreqNum=AcqPoint(1);
PlotSeqWave.PhaseNum=AcqPoint(2);
PlotSeqBlock{8}=PlotSeqWave;
disp('over');

%% plot pulse sequence
PlotPulseSeqence( PlotSeqBlock )

%% 
[M r offsets] = spin_system3D(L,N,spectrum);
offsets = inhomogeneise3D(offsets,r,N,imap);
M(:,3)=M(:,3).*SpinContrast(:);
TestM=M;
TestMz=reshape(TestM(:,3),N);
TestMx=reshape(TestM(:,1),N);
TestMy=reshape(TestM(:,2),N);

LXYPlane=L(1:2);
NXYPlane=N(1:2);
% Spen direction need more points
NXYPlane(2)=NXYPlane(2)*8;
[M_xy_Initial r_xy offsets_xy] = spin_system3D(LXYPlane,NXYPlane,spectrum);


for iSlice=20
    lSlice=L(3); % slice direction Fov
    NSlice=N(3)*10;
    [MSlice rSlice offsetslice] = spin_system3D(lSlice,NSlice,spectrum);
    imapSlice.a1 = imap.a1(3); % in Hz/cm
    imapSlice.a2 = imap.a2(3); % in Hz/(cm^2)
    imapSlice.ar = 00; % in Hz
    offsetSlice = inhomogeneise3D(offsetslice,rSlice,NSlice,imapSlice);
    MSlice = softpulse(MSlice,rSlice(:,1),offsetSlice,RFwaveform{iSlice});
    PlotMag(MSlice,[1 1 NSlice]);
    
    Tpslice = SLR_RF.duration;
    MSlice = gradientlobe(MSlice,rSlice(:,1),offsetSlice,-2*pi*GSlicemax,Tpslice/2);
    PlotMag(MSlice,[1 1 NSlice]);
    
    MxySlice=MSlice(:,1)+1i*MSlice(:,2);
    tempdata=sum(reshape(MxySlice,[round(length(MxySlice)/N(3)),N(3)]));
    
    tempdata=abs(tempdata);
    
    SpinContrastSliceSelc=zeros(size(SpinContrast));
    for iX=1:N(1)
        for iY=1:N(2)
            SpinContrastSliceSelc(iX,iY,:)=squeeze(TestMz(iX,iY,:)).*tempdata';
        end
    end
    SpinContrastAfterSlice=sum(SpinContrastSliceSelc,3);
   
    SpinContrastAfterSlice=imresize(SpinContrastAfterSlice,NXYPlane);
    M_xy_OneSlice=M_xy_Initial;
    M_xy_OneSlice(:,3)=M_xy_Initial(:,3).*SpinContrastAfterSlice(:);
    M_xy_OneSlice(:,2)=M_xy_OneSlice(:,3);
    M_xy_OneSlice(:,3)=0;
    PlotMag(M_xy_OneSlice,[NXYPlane 1],[LXYPlane L(3)] ,2);
    [ MFinal_xy FID] = ConsoleSimulate( M_xy_OneSlice,r_xy,offsets_xy, [PlotSeqBlock(5) PlotSeqBlock(7) PlotSeqBlock(8)],[NXYPlane 1],[LXYPlane L(3)]); % the first block is slice relate
    fidsquare = transpose(reshape(FID,ACQParams.nRO,ACQParams.NPE));
    for k = 1:ACQParams.NPE
        if abs(floor(k/2) - k/2 + 0.5) < eps
            fidsquare(k,1:end) = fidsquare(k,end:-1:1);
        end
    end
    figure
    imagesc(abs(fidsquare));
    
    ftfidsquare = fftshift(fft(fidsquare,[],2),2);
    figure
    imagesc(abs(ftfidsquare));

    disp('over')
end
%% 

