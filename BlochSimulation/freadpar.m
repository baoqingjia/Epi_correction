function parvalue=freadpar(fidin,par,initpar)

frewind(fidin);
parflg=0;
ncount=0;
while ~feof(fidin)
    ncount=ncount+1;
    str=fgetl(fidin);
    str=strtrim(str);
    str_check=regexp(str,'\s+','split');
    if length(str_check)>2 && ((strcmpi(str_check{2},par))|| (strcmpi(str_check{2},[par,'='])) || strcmpi(str_check{2},[par,':']));

        if(strcmpi(str_check{2},'maxamp')||strcmpi(str_check{2},'B1rms' )||strcmpi(str_check{2},'nptot')||strcmpi(str_check{2},'stepsize') .....
                ||strcmpi(str_check{2},'B1max'))
            parvalue=str_check{4};
            if ~isnan(str2double(parvalue))
                parvalue=str2double(parvalue);
            end
        else
            parvalue=str_check{3};
            if ~isnan(str2double(parvalue))
                parvalue=str2double(parvalue);
            end
        end
        
        parflg=1;
        break;
    end
    if ncount>=50
        break;
    end
end
if parflg==0
    parvalue=initpar;
end
frewind(fidin);