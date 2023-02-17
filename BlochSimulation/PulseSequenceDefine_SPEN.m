%%
BWe = 5.0e3; % unit Hz
thk=20/1000; % unit m
BWe=5000; % unit Hz
NPulseStep=500;
sliceSeleRFParams.type='SLR';
sliceSeleRFParams.timestep = 4e-6 ;
sliceSeleRFParams.nsteps=round(NPulseStep);
sliceSeleRFParams.Gmax = BWe/thk; %Hz/m
sliceSeleRFParams.SLRfiltertype = 'equiripple';
sliceSeleRFParams.theta = 85;
sliceSeleRFParams.filtern = sliceSeleRFParams.nsteps;
sliceSeleRFParams.SLRdesign = 'pulse';
sliceSeleRFParams.SLRpulsetype = 'excitation';
duration_lobe = sliceSeleRFParams.nsteps*sliceSeleRFParams.timestep;
sliceSeleRFParams.tbw = ...
    sliceSeleRFParams.Gmax*thk*sliceSeleRFParams.nsteps*sliceSeleRFParams.timestep;
sliceSeleRFParams.inripple = 0.005;
sliceSeleRFParams.outripple = 0.005;
ExctiteRFwaveform = create_rf_waveform(sliceSeleRFParams);

PulseSequenceBlock{1}=ExctiteRFwaveform;

M = softpulse(M,r,offsets,ExctiteRFwaveform);

%% 
RFParams.type = 'chirp';
RFParams.timestep = 40e-6 ;
RFParams.nsteps = ChripTP/RFParams.timestep; 
RFParams.Gmax = ChirpRvalue/ChripTP/L(2); % gradient along y, in Hz/m
RFParams.nu_rf_0 = 0; % carrier frequency at the center of the sweep
Te=RFParams.timestep*RFParams.nsteps;
RFParams.Gmax = ChirpRvalue/ChripTP/L(2); % gradient along x, in Hz/m
RFParams.R = ChirpRvalue/ChripTP/ChripTP;
RFParams.wurstn = 40;
RFParams.B1max = 3*0.26*sqrt(RFParams.R);% c