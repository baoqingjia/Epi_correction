%For simulate, we need Phantom,Pulse sequence.
close all; clear; clc;

load Imag3DGRE_good.mat;

SpinContrast=squeeze(abs(iField(64,:,:)));

gammaHz=4.2574e+3 ; % [Hz/G]
%% define in-plane spin system parameter;
L=[4 4 4]/100; %the readout, phase, slice
N=[128 128*8 1]; %point of spin 
SpinContrast=squeeze(abs(iField(:,:,80)));
SpinContrast=imresize(SpinContrast,N(1:2));
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
phantomscale = [1 1 1];
[M r offsets] = spin_system3D(L,N,spectrum);
M(:,3)=M(:,3).*SpinContrast(:);

%after excitation 
M(:,2)=M(:,3);
M(:,3)=0;
M_inital=M;

% Take inhomogeneity into account
offsets = inhomogeneise3D(offsets,r,N,imap);


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



%% chirp 
% Create the chirp waveform
ChirpRFwaveform = create_rf_waveform(ChirpRFParams);
clear PlotSeqWave;
PlotSeqWave.type='pulse';
PlotSeqWave.shape=ChirpRFwaveform;
PlotSeqWave.GradDirection='phase';
PlotSeqBlock{1}=PlotSeqWave;
M = softpulse(M,r(:,2),offsets,ChirpRFwaveform);% Calculate the action of the chirp pulse
PlotMag( M,N,L,2);

reshapeMx=reshape(M(:,1),N);
reshapeMy=reshape(M(:,2),N);
reshapeMz=reshape(M(:,3),N);
Mxy=reshapeMx+1i*reshapeMy;
Lcm=L(2)*100;
yRegion=linspace(-Lcm/2,Lcm/2,N(2));
yacq= -Lcm/2:Lcm/AcqPoint(2): -Lcm/2+(AcqPoint(2)-1)*Lcm/AcqPoint(2);

Gy=ChirpQvalue/Te/(Lcm)/gammaHz;
a_rad2cmsqr = -2*pi * gammaHz * Gy * ChripTP / (Lcm)  ;

[Y, TempYacq]=ndgrid(yRegion,yacq);
SPIN_desity=reshape(M_inital(:,2),[N(1),N(2)]);

% PhaseTheory=SPIN_desity*exp(-1i*a_rad2cmsqr*((Y-TempYacq).^2-TempYacq.^2));
yyyy=a_rad2cmsqr*(yRegion).*yRegion;

xxxx=phase(Mxy(1,:));
xxxx=xxxx-(max(xxxx)-max(yyyy));
figure;plot(yyyy);hold on;plot(xxxx)


% Mtc = M(:,1)+1i*M(:,2);
% Mtc=reshape((Mtc),N(1),N(2));
% figure
% subplot(131)
% imagesc(abs(Mtc));
% subplot(132)
% imagesc(angle(Mtc));
% subplot(133)
% imagesc(reshape(abs(M(:,3)),N(1),N(2)));

%% % Prefocusing lobe as echo in the center
M = gradientlobe(M,r,offsets,...
    [2*pi*ACQParams.GRO; pi*ChirpRFParams.Gmax*Ta/(ACQParams.nRO/2*ACQParams.timestep)],ACQParams.nRO/2*ACQParams.timestep);
PlotMag(M,N,L,2);
clear PlotSeqWave Gradwaveform;
Gradwaveform.G=[2*pi*ACQParams.GRO; pi*ChirpRFParams.Gmax*Ta/(ACQParams.nRO/2*ACQParams.timestep)]/2/pi;
Gradwaveform.deltat=ACQParams.nRO/2*ACQParams.timestep;
PlotSeqWave.type='gradient';
PlotSeqWave.shape=Gradwaveform;
PlotSeqWave.GradDirection='phase&readout';
PlotSeqBlock{2}=PlotSeqWave;



%% acquire fid
% Create the acquisition trajectory
ACQtrajectory = epi(ACQParams);
fid = acquisition(M,r,offsets,ACQtrajectory);
clear PlotSeqWave;
PlotSeqWave.type='acquire';
PlotSeqWave.shape=ACQtrajectory;
PlotSeqWave.duration=Ta;
PlotSeqWave.FreqNum=AcqPoint(1);
PlotSeqWave.PhaseNum=AcqPoint(2);
PlotSeqBlock{3}=PlotSeqWave;


% [ M_New ,fid_new] = ConsoleSimulate( M_inital,r,offsets, PlotSeqBlock,N,L );
% fid=fid_new;
fidsquare = transpose(reshape(fid,ACQParams.nRO,ACQParams.NPE));
for k = 1:ACQParams.NPE
    if abs(floor(k/2) - k/2 + 0.5) < eps
      fidsquare(k,1:end) = fidsquare(k,end:-1:1);
    end  
end
figure    
imagesc(abs(fidsquare));

% Fourier transform along one dimension
ftfidsquare = fftshift(fft(fidsquare,[],2),2);
figure
imagesc(abs(ftfidsquare));
%contour(abs(ftfidsquare));

srftfidsquare = zeros(size(ftfidsquare));

% super-resolution
SRParams.Ge = ChirpRFParams.Gmax;
SRParams.R = ChirpRFParams.R;
SRParams.duration = Te;
SRParams.Ga = -ACQParams.GPE;
SRParams.timestep = ACQParams.timestep*ACQParams.nRO;
SRParams.Lsr = L(2);
SRParams.killlobesfactor = 10;
A = sr(size(fid,1),SRParams);
for k = 1:ACQParams.nRO   
    srftfidsquare(:,k) = A*(ftfidsquare(:,k));
end
figure    
imagesc(abs(flipud(srftfidsquare)));

% Fourier transform along both dimensions
ft2fidsquare = fftshift(fftshift(fft2(padarray(fidsquare,[0 0])),1),2);
figure    
imagesc(abs(ft2fidsquare));

% end

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
