clc;
close all
clear;
testFit=true;
ShotNum=5;

HOSTNAME = '132.77.74.32';
USERNAME = 'Qingjia';
PASSWORD = 'baoqingjia123';
remotePath='/home/Qingjia/vnmrsys/shapelib/';
localPath='D:\NewMatlabCode\matlabcode\High_Resolution_SPEN\TempDataFromFtp';
% figure;
for i=1:ShotNum
    if(ShotNum>1)
%         if(mod(i,2)==1)
            RemoteGradFile{+1}=['epirsl1' '.GRD'];
            RemoteGradFile{+2}=['epirro1'  '.GRD'];
            RemoteGradFile{+3}=['epirpe' num2str(i) '1' '.GRD'];
%         else
%             RemoteGradFile{+1}=['epirslShift1'  '.GRD'];
%             RemoteGradFile{+2}=['epirroShift1'  '.GRD'];
%             RemoteGradFile{+3}=['epirpeShift' num2str(i) '1' '.GRD'];
%         end
    else
        if(mod(i,2)==1)
            RemoteGradFile{+1}=['epirsl' num2str(i) '.GRD'];
            RemoteGradFile{+2}=['epirro' num2str(i) '.GRD'];
            RemoteGradFile{+3}=['epirpe' num2str(i) num2str(i) '.GRD'];
        else
%             RemoteGradFile{+1}=['epirslShift' num2str(i) '.GRD'];
%             RemoteGradFile{+2}=['epirroShift' num2str(i) '.GRD'];
%             RemoteGradFile{+3}=['epirpeShift' num2str(i) num2str(i) '.GRD'];
        end
    end

    ssh2_conn = scp_simple_get(HOSTNAME,USERNAME,PASSWORD,RemoteGradFile,localPath,remotePath);
    ssh2_conn = ssh2_close(ssh2_conn);
    
    type='GRD';
    [GradShape,GradInfo,SpenStrengh]=loadvarianfile(localPath,RemoteGradFile{1},type);
    GradSize=size(GradShape);
    
    FinalGradShape=zeros(GradSize(1)+100,2);
    iGrad=1;
    for ii=1:size(RemoteGradFile,2)
        TestFileName=RemoteGradFile{ii};
%         if(mod(i,2)==1)
            if(strcmp(TestFileName(1:6),'epirpe')||strcmp(TestFileName(1:6),'epirro'))
                [GradShape,GradInfo,SpenStrengh]=loadvarianfile(localPath,RemoteGradFile{ii},type);
                FinalGradShape(1:GradInfo.points,iGrad)=GradShape(:,1);
                iGrad=iGrad+1;
            end
%         else
%             if(strcmp(TestFileName(1:11),'epirpeShift')||strcmp(TestFileName(1:11),'epirroShift'))
%                 [GradShape,GradInfo,SpenStrengh]=loadvarianfile(localPath,RemoteGradFile{ii},type);
%                 FinalGradShape(1:GradInfo.points,iGrad)=GradShape(:,1);
%                 iGrad=iGrad+1;
%             end
%         end
    end
    figure;
    plot(FinalGradShape);
    
    disp(sum(FinalGradShape(1:246,2)))
    disp(sum(FinalGradShape(246:end,2)))
    disp(sum(FinalGradShape(246:end,2))+sum(FinalGradShape(1:246,2)*2))
    
%     hold on;
    disp('over');
end
hold off

% for i=1:ShotNum
%     RemoteGradFile{3*(i-1)+1}=['epirsl' num2str(i) '.GRD'];
% %     RemoteGradFile{6*(i-1)+2}=['epirslShift' num2str(i) '.GRD'];
%     RemoteGradFile{3*(i-1)+2}=['epirro' num2str(i) '.GRD'];
% %     RemoteGradFile{6*(i-1)+4}=['epirroShift' num2str(i) '.GRD'];
%     RemoteGradFile{3*(i-1)+3}=['epirpe' num2str(i) num2str(i) '.GRD'];
% %     RemoteGradFile{6*(i-1)+6}=['epirpeShift' num2str(i) num2str(i) '.GRD'];
% end






PhaseFactor=-2;