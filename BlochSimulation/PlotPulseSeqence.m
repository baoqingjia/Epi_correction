function [ output_args ] = PlotPulseSeqence( PlotSeqBlock )
%PLOTPULSESEQENCE Summary of this function goes here
%   Detailed explanation goes here
%%
%calculate the total time;
TotalTime=0;
DelayTime=zeros(1,length(PlotSeqBlock));
PulseTime=zeros(1,length(PlotSeqBlock));
GradientTime=zeros(1,length(PlotSeqBlock));
VerticalGxScale=zeros(1,length(PlotSeqBlock));
VerticalGyScale=zeros(1,length(PlotSeqBlock));
VerticalGzScale=zeros(1,length(PlotSeqBlock));
VerticalRFScale=zeros(1,length(PlotSeqBlock));
for iBlockIndex=1:length(PlotSeqBlock)
    OnePlotBlock=PlotSeqBlock{iBlockIndex};
    if(length(OnePlotBlock)>1) %for multislice
        OnePlotBlock=OnePlotBlock{1};
    end
    
    switch OnePlotBlock.type
        case 'gradient'
            Gradwaveform=OnePlotBlock.shape;
            TotalTime=TotalTime+sum(Gradwaveform.deltat);
            GradientTime(iBlockIndex)= sum(Gradwaveform.deltat);
            switch OnePlotBlock.GradDirection
                case 'readout'
                    VerticalGxScale(iBlockIndex)=max(abs(Gradwaveform.G));
                case 'phase'
                    VerticalGyScale(iBlockIndex)=max(abs(Gradwaveform.G));
                case 'slice'
                    VerticalGzScale(iBlockIndex)=max(abs(Gradwaveform.G));
                case 'phase&readout'
                    TempGrad=Gradwaveform.G;
                    VerticalGxScale(iBlockIndex)=max(abs(TempGrad(1,:)));
                    VerticalGyScale(iBlockIndex)=max(abs(TempGrad(2,:)));
                    
                case 'phase&readout&slice'
                    TempGrad=Gradwaveform.G;
                    VerticalGxScale(iBlockIndex)=max(abs(TempGrad(1,:)));
                    VerticalGyScale(iBlockIndex)=max(abs(TempGrad(2,:)));
                    VerticalGzScale(iBlockIndex)=max(abs(TempGrad(3,:)));
                otherwise
                    error('the gradient is in wrong direction');
            end
        case  'pulse'
            Pulsewaveform=OnePlotBlock.shape;
            TotalTime=TotalTime+sum(Pulsewaveform.deltat);
            PulseTime(iBlockIndex)= sum(Pulsewaveform.deltat);
            RealGradwaveform=OnePlotBlock.shape.G;
            RealRFwaveform=abs(OnePlotBlock.shape.B1);
            VerticalRFScale(iBlockIndex)= max(abs(RealRFwaveform));
            if( size(RealGradwaveform,1) > 1 )
                error('Now we do not support this');
            end
            
            switch OnePlotBlock.GradDirection
                case 'read'
                    VerticalGxScale(iBlockIndex)=max(abs(RealGradwaveform));
                case 'phase'
                    VerticalGyScale(iBlockIndex)=max(abs(RealGradwaveform));
                case 'slice'
                    VerticalGzScale(iBlockIndex)=max(abs(RealGradwaveform));
                case 'phase&readout'
                    TempGrad=RealGradwaveform;
                    VerticalGxScale(iBlockIndex) = max(abs(TempGrad(1,:)));
                    VerticalGyScale(iBlockIndex) = max(abs(TempGrad(2,:)));
                otherwise
                    error('the gradient is in wrong direction');
            end
            
        case  'delay'
            Delay=OnePlotBlock.duration;
            TotalTime=TotalTime+sum(Delay);
            DelayTime(iBlockIndex)= sum(Delay);
        case  'acquire'
            ACQtrajectory=OnePlotBlock.shape;
            TotalTime=TotalTime+OnePlotBlock.duration;
            GradientTime(iBlockIndex)= OnePlotBlock.duration;
            Gradwave=ACQtrajectory.G;
            GradX=Gradwave(1,:);
            GradY=Gradwave(2,:);
            VerticalGxScale(iBlockIndex) = max(abs(GradX));
            VerticalGyScale(iBlockIndex) = max(abs(GradY));
        otherwise
            error('now we only suport three kinds display');
    end
end

%% resize the show size
MaxScale=3;
GradientTimeRatio=GradientTime/min(GradientTime(find(GradientTime>0)));
PulseTimeRatio=PulseTime/min(PulseTime(find(PulseTime>0)));
if(min(DelayTime(find(DelayTime>0)))>0)
DelayTimeRatio=DelayTime/min(DelayTime(find(DelayTime>0)));
else
    DelayTimeRatio=DelayTime;
end
[x GradientBigIndex]=find(GradientTimeRatio>MaxScale);
[x PulseTimeBigIndex]=find(PulseTimeRatio>MaxScale);
[x DelayTimeBigIndex]=find(DelayTimeRatio>MaxScale);
GradientTimeRatio(GradientBigIndex)=MaxScale;
PulseTimeRatio(PulseTimeBigIndex)=MaxScale;
DelayTimeRatio(DelayTimeBigIndex)=MaxScale;

TotalDelaytime=sum(DelayTime);
TotalPulseTime=sum(PulseTime);
TotalGradientTime=sum(GradientTime);

ShowPulseRatio = min(PulseTime(find(PulseTime>0)));
ShowGradRatio = min(GradientTime(find(GradientTime>0)));
ShowDelayRatio = min(DelayTime(find(DelayTime>0)));

temp=[GradientTime PulseTime DelayTime];
tmepMin=min(temp(find(temp>0)));
Scale=round(1/tmepMin);
GradientTimeRatio=GradientTimeRatio.*GradientTime*Scale;
PulseTimeRatio=PulseTimeRatio.*PulseTime*Scale;
DelayTimeRatio=DelayTimeRatio.*DelayTime*Scale;


VerticalGxScale=VerticalGxScale/max(VerticalGxScale);
VerticalGyScale=VerticalGyScale/max(VerticalGyScale);
if(max(VerticalGzScale)>0)
    VerticalGzScale=VerticalGzScale/max(VerticalGzScale);
end
VerticalRFScale=VerticalRFScale/max(VerticalRFScale);

VerticalScale.Gx=VerticalGxScale;
VerticalScale.Gy=VerticalGyScale;
VerticalScale.Gz=VerticalGzScale;
VerticalScale.RF=VerticalRFScale;
%%

RFchannel=[];
Gxchannel=[];
Gychannel=[];
Gzchannel=[];
for iBlockIndex=1:length(PlotSeqBlock)
    OnePlotBlock=PlotSeqBlock{iBlockIndex};
    if(length(OnePlotBlock)>1) %for multislice
        OnePlotBlock=OnePlotBlock{1};
    end
    switch OnePlotBlock.type
        case 'gradient'
            ShowPointNum = round(GradientTimeRatio(iBlockIndex)*100);
            [RFchannel Gxchannel Gychannel Gzchannel]=ProcessGrad(RFchannel,Gxchannel,....
                Gychannel, Gzchannel,OnePlotBlock, ShowPointNum,VerticalScale,iBlockIndex);
        case  'pulse'
            ShowPointNum = round(PulseTimeRatio(iBlockIndex)*100);
            [RFchannel Gxchannel Gychannel Gzchannel]=ProcessPulse(RFchannel,Gxchannel,....
                Gychannel, Gzchannel,OnePlotBlock, ShowPointNum,VerticalScale,iBlockIndex);
            
        case  'delay'
            ShowPointNum = round(DelayTimeRatio(iBlockIndex)*100);
            temp=zeros(1,ShowPointNum);
            RFchannel=[RFchannel,temp];
            Gxchannel=[Gxchannel temp];
            Gychannel=[Gychannel temp];
            Gzchannel=[Gzchannel temp];
            
            
        case  'acquire'
            ShowPointNum = round(GradientTimeRatio(iBlockIndex)*100);
            [RFchannel Gxchannel Gychannel Gzchannel]=ProcessAcq(RFchannel,Gxchannel,....
                Gychannel, Gzchannel,OnePlotBlock, ShowPointNum,VerticalScale,iBlockIndex);
        otherwise
            error('now we only suport three kinds display');
    end
end

%%
N=length(RFchannel);

figure('Name','Pulse sequence')
plot(zeros(1,N),'linewidth',1,'Linestyle','--');
hold on
plot(ones(1,N)*2.5,'linewidth',1,'Linestyle','--');
hold on
plot(ones(1,N)*5,'linewidth',1,'Linestyle','--');
hold on
plot(ones(1,N)*7.5,'linewidth',1,'Linestyle','--');

Gzchannel=Gzchannel/(max(Gzchannel)-min(Gzchannel))*1.5;
Gxchannel=Gxchannel/(max(Gxchannel)-min(Gxchannel))*1.5;
Gychannel=Gychannel/(max(Gychannel)-min(Gychannel))*1.5;
RFchannel=RFchannel/(max(RFchannel)-min(RFchannel))*1.5;

hold on
plot(Gzchannel,'linewidth',2);
hold on
plot(Gychannel+2.5,'linewidth',2);
hold on
plot(Gxchannel+5,'linewidth',2);
hold on
plot(RFchannel*2+7.5,'linewidth',2,'color','red');
ylim([-2 13]);

hold off


end
%% %%%%%%%%%%%%%%%%%%%%%%%%%
function [RFchannel Gxchannel Gychannel Gzchannel]=ProcessGrad(RFchannel,Gxchannel, Gychannel, Gzchannel,OnePlotBlock, ShowPointNum,VerticalScale,iBlockIndex)

VerticalGxScale=VerticalScale.Gx;
VerticalGyScale=VerticalScale.Gy;
VerticalGzScale=VerticalScale.Gz;
VerticalRFScale=VerticalScale.RF;

GxScale=VerticalGxScale(iBlockIndex);
GyScale=VerticalGyScale(iBlockIndex);
GzScale=VerticalGzScale(iBlockIndex);

if(OnePlotBlock.type~='gradient')
    error('type wrong');
end
temp=zeros(1,ShowPointNum);
RFchannel=[RFchannel,temp];
RealGradwaveform=OnePlotBlock.shape.G;
if(size(RealGradwaveform,1) == 1 )
    if(length(RealGradwaveform) > 1 )
        ShowGrad=interp1(1:length(RealGradwaveform),RealGradwaveform,linspace(1,length(RealGradwaveform),ShowPointNum));
    else
        ShowGrad=RealGradwaveform*ones(1,ShowPointNum);
    end
end
if(size(RealGradwaveform,1) == 2 )
    if(size(RealGradwaveform,2) > 1 )
        ShowGradX=interp1(1:length(RealGradwaveform(1,:)),RealGradwaveform(1,:),linspace(1,length(RealGradwaveform(1,:)),ShowPointNum));
    else
        ShowGradX=RealGradwaveform(1,:)*ones(1,ShowPointNum);
    end
    if(size(RealGradwaveform,2) > 1 )
        ShowGradY=interp1(1:length(RealGradwaveform(2,:)),RealGradwaveform(2,:),linspace(1,length(RealGradwaveform(2,:)),ShowPointNum));
    else
        ShowGradY=RealGradwaveform(2,:)*ones(1,ShowPointNum);
    end
end

if(size(RealGradwaveform,1) == 3 )
    if(size(RealGradwaveform,2) > 1 )
        ShowGradX=interp1(1:length(RealGradwaveform(1,:)),RealGradwaveform(1,:),linspace(1,length(RealGradwaveform(1,:)),ShowPointNum));
    else
        ShowGradX=RealGradwaveform(1,:)*ones(1,ShowPointNum);
    end
    if(size(RealGradwaveform,2) > 1 )
        ShowGradY=interp1(1:length(RealGradwaveform(2,:)),RealGradwaveform(2,:),linspace(1,length(RealGradwaveform(2,:)),ShowPointNum));
    else
        ShowGradY=RealGradwaveform(2,:)*ones(1,ShowPointNum);
    end
    
    if(size(RealGradwaveform,2) > 1 )
        ShowGradZ=interp1(1:length(RealGradwaveform(3,:)),RealGradwaveform(3,:),linspace(1,length(RealGradwaveform(3,:)),ShowPointNum));
    else
        ShowGradZ=RealGradwaveform(3,:)*ones(1,ShowPointNum);
    end
end

switch OnePlotBlock.GradDirection
    case 'readout'
        Gxchannel=[Gxchannel GxScale*ShowGrad];
        Gychannel=[Gychannel temp];
        Gzchannel=[Gzchannel temp];
    case 'phase'
        Gxchannel=[Gxchannel temp];
        Gychannel=[Gychannel GyScale*ShowGrad];
        Gzchannel=[Gzchannel temp];
    case 'slice'
        Gxchannel=[Gxchannel temp];
        Gychannel=[Gychannel temp];
        Gzchannel=[Gzchannel GzScale*ShowGrad];
    case 'phase&readout'
        Gxchannel=[Gxchannel GxScale*ShowGradX];
        Gychannel=[Gychannel GyScale*ShowGradY];
        Gzchannel=[Gzchannel temp];
    case 'phase&readout&slice'
        Gxchannel=[Gxchannel GxScale*ShowGradX];
        Gychannel=[Gychannel GyScale*ShowGradY];
        Gzchannel=[Gzchannel GzScale*ShowGradZ];
    otherwise
        error('the gradient is in wrong direction');
end
end


function [RFchannel Gxchannel Gychannel Gzchannel]=ProcessPulse(RFchannel,Gxchannel, Gychannel, Gzchannel,OnePlotBlock, ShowPointNum,VerticalScale,iBlockIndex)
if(OnePlotBlock.type~='pulse')
    error('type wrong');
end
VerticalGxScale=VerticalScale.Gx;
VerticalGyScale=VerticalScale.Gy;
VerticalGzScale=VerticalScale.Gz;
VerticalRFScale=VerticalScale.RF;

GxScale=VerticalGxScale(iBlockIndex);
GyScale=VerticalGyScale(iBlockIndex);
GzScale=VerticalGzScale(iBlockIndex);


temp=zeros(1,ShowPointNum);
RealGradwaveform=OnePlotBlock.shape.G;
RealRFwaveform=abs(OnePlotBlock.shape.B1);
if( size(RealGradwaveform,1) > 1 )
    error('Now we do not support this');
end
if(length(RealGradwaveform) > 1 )
    ShowGrad=interp1(1:length(RealGradwaveform),RealGradwaveform,linspace(1,length(RealGradwaveform),ShowPointNum));
else
    ShowGrad=RealGradwaveform*ones(1,ShowPointNum);
end

if(length(RealRFwaveform) > 1 )
    ShowB1=interp1(1:length(RealRFwaveform),RealRFwaveform,linspace(1,length(RealRFwaveform),ShowPointNum));
else
    ShowB1=RealRFwaveform*ones(1,ShowPointNum);
end
RFchannel=[RFchannel,ShowB1];
switch OnePlotBlock.GradDirection
    case 'readout'
        Gxchannel=[Gxchannel GxScale*ShowGrad];
        Gychannel=[Gychannel temp];
        Gzchannel=[Gzchannel temp];
    case 'phase'
        Gxchannel=[Gxchannel temp];
        Gychannel=[Gychannel GyScale*ShowGrad];
        Gzchannel=[Gzchannel temp];
    case 'slice'
        Gxchannel=[Gxchannel temp];
        Gychannel=[Gychannel temp];
        Gzchannel=[Gzchannel GzScale*ShowGrad];
    otherwise
        error('the gradient is in wrong direction');
end
end

function [RFchannel Gxchannel Gychannel Gzchannel]=ProcessAcq(RFchannel,Gxchannel, Gychannel, Gzchannel,OnePlotBlock, ShowPointNum,VerticalScale,iBlockIndex)
if(OnePlotBlock.type~='acquire')
    error('type wrong');
end

VerticalGxScale=VerticalScale.Gx;
VerticalGyScale=VerticalScale.Gy;
VerticalGzScale=VerticalScale.Gz;
VerticalRFScale=VerticalScale.RF;

GxScale=VerticalGxScale(iBlockIndex);
GyScale=VerticalGyScale(iBlockIndex);
GzScale=VerticalGzScale(iBlockIndex);

temp=zeros(1,ShowPointNum);
RFchannel=[RFchannel,temp];
ACQtrajectory=OnePlotBlock.shape;
Gradwave=ACQtrajectory.G;
deltat=ACQtrajectory.deltat;
GradX=Gradwave(1,:);
tempData=deltat(1,:);
GradY=Gradwave(2,:)/(max(deltat(1,:))/min(tempData(find(tempData>0))));

if(~isfield(OnePlotBlock,'FreqNum') || ~isfield(OnePlotBlock,'PhaseNum'))
    if(length(GradX) > 1 )
        ShowGradX=interp1(1:length(GradX),GradX,linspace(1,length(GradX),ShowPointNum));
    else
        ShowGradX=GradX*ones(1,ShowPointNum);
    end
    if(length(GradY) > 1 )
        ShowGradY=interp1(1:length(GradY),GradY,linspace(1,length(GradY),ShowPointNum));
    else
        ShowGradX=GradY*ones(1,ShowPointNum);
    end
    Gxchannel=[Gxchannel ShowGradX];
    Gychannel=[Gychannel ShowGradY];
    Gzchannel=[Gzchannel temp];
else
    FinalShowTempX=[];FinalShowTempY=[];
    for iPhaseIndex=1:OnePlotBlock.PhaseNum
        beginRO = (iPhaseIndex-1)*(OnePlotBlock.FreqNum)+1;
        endRO = iPhaseIndex*(OnePlotBlock.FreqNum)-1;
        tempX=Gradwave(1,beginRO:endRO);
        tempY=Gradwave(2,beginRO:endRO);
        if(length(tempX) > 1 )
            ShowTempX=interp1(1:length(tempX),tempX,linspace(1,length(tempX),round(ShowPointNum/OnePlotBlock.PhaseNum*1.0)));
        else
            ShowTempX=tempX*ones(1,round(ShowPointNum/OnePlotBlock.PhaseNum*1.0));
        end
        if(length(tempY) > 1 )
            ShowTempY=interp1(1:length(tempY),tempY,linspace(1,length(tempY),round(ShowPointNum/OnePlotBlock.PhaseNum*1.0)));
        else
            ShowTempY=tempX*ones(1,round(ShowPointNum/OnePlotBlock.PhaseNum*1.0));
        end
        FinalShowTempX=[FinalShowTempX ShowTempX Gradwave(1,endRO+1)];
        FinalShowTempY=[FinalShowTempY ShowTempY Gradwave(2,endRO+1)*(max(deltat(1,:))/min(tempData(find(tempData>0))))];
    end
    Gxchannel=[Gxchannel GxScale*FinalShowTempX];
    Gychannel=[Gychannel GyScale*FinalShowTempY];
    temp=zeros(1,length(FinalShowTempY));
    Gzchannel=[Gzchannel temp];
end






end

