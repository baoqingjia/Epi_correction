
SLR_RF.pulname='slr_pulse';
SLR_RF.duration=0.003;
SLR_RF.pts=1000;
SLR_RF.flip=90;
SLR_RF.bandwith=4; %unit kHz
SLR_RF.inripple=0.0001;
SLR_RF.outripple=0.0001;
SLR_RF.filtertype='equiripple';
SLR_RF.pulsetype='excitation';

% SLR_RF.multiband='true';
% SLR_RF.multif=[-1000,0,1000];
% SLR_RF.multiBW=[500,500,500];
% SLR_RF.multiTW=[100,100,100];

% SLR_RF.multiws=1;
% SLR_RF.multiwp=1;


CreateSLR_RF(SLR_RF);



% Para.tof=0;
% Para.p1=0.03;
% Para.flip1=90;
% SLR_RF.pulname='zz_SLR90';
% SLR_RF.duration=Para.p1;
% SLR_RF.pts=400;
% SLR_RF.flip=Para.flip1;
% SLR_RF.bandwith=0.2;
% SLR_RF.inripple=0.0001;
% SLR_RF.outripple=0.0001;
% SLR_RF.filtertype='equiripple';
% SLR_RF.pulsetype='inversion';
% 
% SLR_RF.multiband='true';
% % SLR_RF.multif=-[-231.53,-541.31,-890.75];
% % SLR_RF.multiBW=[510,510,400];
% % SLR_RF.multiTW=[160,160,160];
% % SLR_RF.multif=[-889.89,-545.651,-231.933];
% SLR_RF.multif=[231.933,545.651,889.89];
% SLR_RF.multiBW=[400,400,400];
% SLR_RF.multiTW=[200,200,200];
% 
% % SLR_RF.multif=0;
% SLR_RF.multiBW=400;
% SLR_RF.multiTW=200;


% SLR_RF.multiws=1;
% SLR_RF.multiwp=1;
% 
% 
% CreateSLR_RF(SLR_RF);
% PolychromePulse(SLR_RF.pulname,SLR_RF.duration,0,Para.flip1);




% Para.tof=0;
% Para.p1=0.004;
% Para.flip1=180;
% SLR_RF.pulname='zz_SLR180';
% SLR_RF.duration=Para.p1;
% SLR_RF.pts=1000;
% SLR_RF.flip=Para.flip1;
% SLR_RF.bandwith=0.2;
% SLR_RF.inripple=0.0001;
% SLR_RF.outripple=0.0001;
% SLR_RF.filtertype='equiripple';
% SLR_RF.pulsetype='inversion';
% 
% SLR_RF.multiband='true';
% % SLR_RF.multif=-[-231.53,-541.31,-890.75];
% % SLR_RF.multiBW=[510,510,400];
% % SLR_RF.multiTW=[160,160,160];
% SLR_RF.multif=0;
% SLR_RF.multiBW=1000;
% SLR_RF.multiTW=300;
% 
% SLR_RF.multiws=1;
% SLR_RF.multiwp=1;
% 
% 
% CreateSLR_RF(SLR_RF);
% PolychromePulse(SLR_RF.pulname,SLR_RF.duration,0,Para.flip1);






% clear all
% 
% Para.p2=0.001;
% Para.flip2=180;
% %--------------SLR 180 ----------------------%
% SLR_RF.pulname='zz_SLR180';
% SLR_RF.duration=Para.p2;
% SLR_RF.pts=1000;
% SLR_RF.flip=Para.flip2;
% SLR_RF.bandwith=16;
% SLR_RF.inripple=0.0000000001;
% SLR_RF.outripple=0.0000000001;
% SLR_RF.filtertype='equiripple';
% SLR_RF.pulsetype='refocusing';
% 
% CreateSLR_RF(SLR_RF);
% PolychromePulse(SLR_RF.pulname,SLR_RF.duration,0,Para.flip2);



