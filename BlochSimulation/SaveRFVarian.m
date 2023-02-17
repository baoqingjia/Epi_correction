function [ output_args ] = SaveRFVarian( ExctiteRFwaveform, FileName,RFParams )
%SAVERFVARIAN Summary of this function goes here
%   Detailed explanation goes here
fulfilename=FileName;
fid = fopen(fulfilename,'w'); 

SincFileName='D:\NewMatlabCode\matlabcode\FuncTool_New\FuncTool\Bloch_simulator_Bao\shapelib\sinc.RF';
Sincfid = fopen(SincFileName,'r'); 

% write head 
  
while  ~feof(Sincfid)
 tline=fgetl(Sincfid);
 flag=0;
 for ix=1:size(tline,2)
     if(tline(ix) == '#')
        flag=1;
        break;
     end
 end
 if(flag == 1)
     if(~isempty(strfind(tline,'# STEPS')) )
        fprintf(fid,'%s  \n',['# STEPS    ' num2str(RFParams.nsteps)]);
     elseif (~isempty(strfind(tline,'# TYPE')) )
         fprintf(fid,'%s  \n',['# TYPE    ' 'SLR']);
     elseif (~isempty(strfind(tline,'# EXCITEWIDTH')) )
          fprintf(fid,'%s  \n',['# EXCITEWIDTH    '  num2str(RFParams.tbw)]);
     elseif (~isempty(strfind(tline,'# INTEGRAL')) )
         INTEGRAL = sum(ExctiteRFwaveform.B1.*exp(1i*ExctiteRFwaveform.phi))/max(abs(ExctiteRFwaveform.B1))/size(ExctiteRFwaveform.B1,2);
         fprintf(fid,'%s  \n',['# INTEGRAL    '  num2str(abs(INTEGRAL))]);
     else
         fprintf(fid,'%s\n',tline);
     end
 end 
end
amp=ExctiteRFwaveform.B1;
rfdata=[ExctiteRFwaveform.phi*180/pi;amp/max(amp)*1022;ones(1,RFParams.nsteps);ones(1,RFParams.nsteps)];
fprintf(fid,'%3.3f    %3.3f    %1.1f    %0.0f \n',rfdata);
fclose(fid);


end

