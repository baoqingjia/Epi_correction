
path='D:\vnmrJ_PulseCode';
filename='SPEN180_per1';
type='GRD';


[SpenPrephase,SpenPrephaseInfo,SpenPrephaseStrength]=loadvarianfile(path,filename,type);

SumGradPre=sum(SpenPrephase(:,1)*SpenPrephaseInfo.strength*SpenPrephaseInfo.resolution)/max(SpenPrephase(:,1));
disp(['SumGradPre==' num2str(SumGradPre*1000)]);
figure;plot(SpenPrephase(:,1)/32767*SpenPrephaseInfo.strength);

filename1='SPEN180_pe';
type='GRD';

[Spen,SpenInfo,SpenStrengh]=loadvarianfile(path,filename1,type);
figure;plot(Spen(:,1)/32767*SpenInfo.strength);
SumGradSpen=sum(Spen(:,1)*SpenInfo.strength*SpenInfo.resolution)/max(Spen(:,1));
disp(['SumGradSpen SPEN Phase without com ==' num2str(SumGradSpen*1000)]);
disp(['SumGradSpen SPEN Phase with com ==' num2str(SumGradSpen*32/31*1000)]);


filename2='SPEN180_per_oneblip1';
type='GRD';
[SpenOneBlip,SpenInfoBlip,SpenStrenghBlip]=loadvarianfile(path,filename2,type);
figure;plot(SpenOneBlip(:,1)/32767*SpenInfoBlip.strength);
SumGradSpenOneBlip=sum(SpenOneBlip(:,1)*SpenInfoBlip.strength*SpenInfoBlip.resolution)/max(SpenOneBlip(:,1));
disp(['Ideal one blip ==' num2str(SumGradSpen/31*1000)]);
disp(['SumGradSpenOneBlip ==' num2str(SumGradSpenOneBlip*1000)]);
