function [filedata,RFInfo,varargout]=loadvarianfile(path,filename,type)

switch type
    case 'RF'
        fulfilename=[path,filesep,filename,'.RF'];
        Fstruct=init_rf(filename);
    case 'GRD'
        fulfilename=[path,filesep,filename];
        if(strcmp(fulfilename(end-3:end),'.GRD'))
            fulfilename=fulfilename;
        else
            fulfilename=[path,filesep,filename,'.GRD'];
        end

        Fstruct=init_grad(filename);
    case 'DEC'
        fulfilename=[path,filesep,filename,'.DEC'];
        Fstruct=init_dec(filename);
end

fid = fopen(fulfilename,'r'); 
if fid==-1
    error('Error opening the aglient file');
end

Fstructmember=fieldnames(Fstruct);
for k=1:length(Fstructmember)
    membervalue=Fstruct.(Fstructmember{k});
    if isstruct(membervalue)
        Fstructsubmember=fieldnames(Fstruct.(Fstructmember{k}));
        for m=1:length(Fstructsubmember)
            submembervalue=Fstruct.(Fstructmember{k}).(Fstructsubmember{m});
            parvalue=freadpar(fid,Fstructsubmember{m},submembervalue);
            
            Fstruct.(Fstructmember{k}).(Fstructsubmember{m})=parvalue;
        end
        RFInfo=Fstruct.(Fstructmember{k});
    elseif isnumeric(membervalue) || ischar(membervalue)
        parvalue=freadpar(fid,Fstructmember{k},membervalue);
        Fstruct.(Fstructmember{k})=parvalue;
    end      
end
fdata=freaddata(fid);
fclose(fid);
filedata=fdata;

switch type
    case 'RF'
        Fstruct.B1=fdata(:,2).*exp(1i*2*pi*fdata(:,1)/360);
        Fstruct.B1=(Fstruct.B1/max(abs(Fstruct.B1))).';
        Fstruct.pts=length(Fstruct.B1);
    case 'GRD'
        Fstruct.ampdata=fdata(:,1).';
        Fstruct.amplength=fdata(:,2).';
        Fstruct.duration=Fstruct.head.resolution*Fstruct.head.points;
    case 'DEC'
        Fstruct.ampdata=fdata(:,2).';
        Fstruct.phase=fdata(:,1).';
end
varargout{1}=Fstruct;