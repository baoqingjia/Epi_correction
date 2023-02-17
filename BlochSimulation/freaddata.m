function varargout=freaddata(fidin)

ncount=0;
frewind(fidin);
while ~feof(fidin)
    str=fgetl(fidin);
    str=strtrim(str);
    str_check=regexp(str,'\s+','split');
    str_check=str2double(str_check);
    if ~any(isempty(str_check)) && ~any(isnan(str_check))
        ncount=ncount+1;
        varargout{1}(ncount,:) = str_check;
    end
end
frewind(fidin);
