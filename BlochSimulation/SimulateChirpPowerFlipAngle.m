%For simulate, we need Phantom,Pulse sequence.
% define in-plane spin system parameter;
close all; clear; clc;
load Imag3DGRE_good.mat;
gammaHz=4.2574e+3 ; % [Hz/G]
Nseg=1;

L=[4 4 4]/100; %the readout, phase, slice
N=[1 1 1000]; %point of spin 
AcqPoint=[1 1 200]; %point of acquire frequency phase slice

SpinContrast=round(abs(iField));
SpinContrast=SpinContrast/max(SpinContrast(:));
figure(1);imshow3Dfull(SpinContrast)

% nii = make_nii(abs(iField));
% fileprefix='niidata_before.nii'
% save_nii(nii, fileprefix, 0);

[y x z]=...
   ndgrid(linspace(1,size(SpinContrast,1),N(1)),...
          linspace(1,size(SpinContrast,2),N(2)),...
          linspace(1,size(SpinContrast,3),N(3)));
SpinContrastResize=interp3(SpinContrast,x,y,z);

figure(2);imshow3Dfull(SpinContrastResize(:,1:8:end,:))
% nii1 = make_nii(abs(SpinContrastResize));
% fileprefix='niidata_after.nii'
% save_nii(nii, fileprefix, 0);



%% define chirp pulse
ChirpQvalue=120;  % Qvalue of the chirp 
ChripTP=1/1000; % unit ms
ChirpRFParams.type = 'chirp';
ChirpRFParams.timestep = 4e-6 ;
ChirpRFParams.nsteps = ChripTP/ChirpRFParams.timestep; 
ChirpRFParams.Gmax =0.88*ChirpQvalue/ChripTP/L(3); % gradient along y, in Hz/m
ChirpRFParams.nu_rf_0 = 0; % carrier frequency at the center of the sweep
Te=ChirpRFParams.timestep*ChirpRFParams.nsteps;
ChirpRFParams.R = ChirpQvalue/ChripTP/ChripTP;
ChirpRFParams.wurstn = 100;

if strcmp(ChirpRFParams.type(end-4:end),'chirp')
    Q = Te^2*ChirpRFParams.R;
    disp(['The quality factor is ' int2str(ceil(Q))]);
end
disp(['Quality factor: ' int2str(ceil(Q))]);

%% 
spectrum=0;
% Optionally add some inhomogeneities
imap.a1 = [0e3 0e3 0e3]; % in Hz/cm
imap.a2 = [0e6 0e6 0e3]; % in Hz/(cm^2)
imap.ar = 00; % in Hz
[M r offsets] = spin_system3D(L,N,spectrum);
offsets = inhomogeneise3D(offsets,r,N,imap);
% M(:,3)=M(:,3).*SpinContrastResize(:);
TestM=M;
TestMz=reshape(TestM(:,3),N);
TestMx=reshape(TestM(:,1),N);
TestMy=reshape(TestM(:,2),N);

FlipAngle=linspace(0,360,180)/90 *pi;
FinalAllFlipMz=zeros(length(FlipAngle),N(3));
FinalAllFlipMxy=zeros(length(FlipAngle),N(3));
for iFlip=1:length(FlipAngle)
    ChirpRFParams.B1max = FlipAngle(iFlip)/(ChirpRFParams.timestep*ChirpRFParams.nsteps);% 3*0.26*sqrt(ChirpRFParams.R)
    ChirpRFwaveform = create_rf_waveform(ChirpRFParams);
    MAfterPulse = softpulse(M,r(:,3),offsets,ChirpRFwaveform);
    TestM1=MAfterPulse;
    TestMz=reshape(TestM1(:,3),N);
    TestMx=reshape(TestM1(:,1),N);
    TestMy=reshape(TestM1(:,2),N);
%     figure;plot(squeeze(TestMz))
%     figure;plot(squeeze(squeeze(sqrt(TestMx.^2+TestMy.^2))));
    ComplexM=TestMx+1i*TestMy;
    FinalAllFlipMz(iFlip,:)= squeeze(TestMz);
    FinalAllFlipMxy(iFlip,:)=squeeze(ComplexM);
%     figure;plot(phase(squeeze(((ComplexM)))))
    disp(iFlip);
end

zz=sum(FinalAllFlipMz,2);
xy=sum(abs(FinalAllFlipMxy),2);
figure;plot(FlipAngle,zz/max(zz));hold on; plot(FlipAngle,xy/max(xy));hold off;
figure;subplot(1,2,1);imagesc(FinalAllFlipMz);subplot(1,2,2);imagesc(abs(FinalAllFlipMxy));
figure;subplot(1,2,1);contour(FinalAllFlipMz);subplot(1,2,2);contour(abs(FinalAllFlipMxy));
