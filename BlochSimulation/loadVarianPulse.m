function RFwaveform=loadVarianPulse(PulseFilePath,pulsepat,PulseLength,FilpAngle,thk,PulseType,varargin);
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[RFStruct RFInfo]=loadvarianfile(PulseFilePath,pulsepat,'RF');

switch PulseType
    case 'excite'
        Bandwidth=RFInfo.EXCITEWIDTH/PulseLength;
    case 'inverse'
        Bandwidth=RFInfo.INVERTWIDTH/PulseLength;
    otherwise
        error('not support RF type');
end

if(numel(varargin)==0)
    nu_rf_0=0;
end
if(numel(varargin)>=1)
    nu_rf_0=varargin{1};
end

if(size(RFStruct,2)==4)
ZerosGateIndex=find(RFStruct(:,4)==0);
RFStruct(ZerosGateIndex,:)=[];
end

NPulseStep=length(RFStruct(:,1));
timestep = PulseLength/NPulseStep ;
nsteps=round(NPulseStep);
Gmax = Bandwidth/thk; %Hz/m

time = timestep*((1:nsteps)-0.5);
omega_rf_0 = 2 * pi * nu_rf_0; % carrier freq
phi_1 = omega_rf_0 * time;
Gmax = 2 * pi * Gmax;

% calculate B1max to get desire FilpAngle
FilpAngle=FilpAngle*pi/180;

if(RFInfo.integral<0)
    
else
    B1Max=FilpAngle/PulseLength/RFInfo.integral;
end

if(numel(varargin)==2)
    B1Max=varargin{2};
end
% B1Max=2 * pi * B1Max; 
tempB1=RFStruct(:,2)';
B1=tempB1/max(tempB1(:));
B1=B1;
B1=B1*B1Max;
phi=RFStruct(:,1)';
phi=phi/180*pi;

deltat(1,1:nsteps) = timestep;
G(1,1:nsteps) = Gmax;

RFwaveform.B1 = B1;
RFwaveform.G = G;
RFwaveform.phi = phi_1+phi;
RFwaveform.deltat = deltat;

end

