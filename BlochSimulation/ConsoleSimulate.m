function [ M ,fid] = ConsoleSimulate( M,r,offsets, PlotSeqBlock,N,L,varargin )
%CONSOLESIMULATE Summary of this function goes here
%   Detailed explanation goes here

if(numel(varargin)==0)
 PhaseCoherent=ones(1,length(PlotSeqBlock));
   
end
if(numel(varargin)==1)
  PhaseCoherent=varargin{1};
end

for iBlockIndex=1:length(PlotSeqBlock)
    OnePlotBlock=PlotSeqBlock{iBlockIndex};
    if(length(OnePlotBlock)>1) %for multislice
        OnePlotBlock=OnePlotBlock{1};
    end
    offsets=offsets*PhaseCoherent(iBlockIndex);
    switch OnePlotBlock.type
        case 'gradient'
            Gradwaveform=OnePlotBlock.shape;
            Gmax=Gradwaveform.G;
            delta=Gradwaveform.deltat;
            GradDirection = OnePlotBlock.GradDirection;
            switch GradDirection
                case 'readout'
                    M = gradientlobe(M,r(:,1),offsets,Gmax,delta);
                case 'phase'
                    M = gradientlobe(M,r(:,2),offsets,Gmax,delta);
                case 'slice'
                    M = gradientlobe(M,r(:,3),offsets,Gmax,delta);
                case 'phase&readout'
                    M = gradientlobe(M,r,offsets,Gmax,delta);

                otherwise         
                    error(' error wrong direction!');
            end
        case  'pulse'
            RFwaveform=OnePlotBlock.shape;
            GradDirection=OnePlotBlock.GradDirection;
            
            switch GradDirection
                case 'readout'
                    M = softpulse(M,r(:,1),offsets,RFwaveform);
                case 'phase'
                    M = softpulse(M,r(:,2),offsets,RFwaveform);
                case 'slice'
                    M = softpulse(M,r(:,3),offsets,RFwaveform);
                otherwise
                    error(' error wrong direction!');
            end
        case  'delay'
           duration= OnePlotBlock.duration;
           M = delay(M,offsets,duration);
        case  'acquire'
            ACQtrajectory = OnePlotBlock.shape;
            fid = acquisition(M,r,offsets,ACQtrajectory);
        otherwise
            error('now we only suport three kinds display');
    end
%     PlotMag(M,N,L,2);
end


end

