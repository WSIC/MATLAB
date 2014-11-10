function duration = durationInveonListMode(filename)
%DURATIONINVEONLISTMODE determines the duration of Inveon LM file 
%
% USAGE: 
%       duration = durationInveonListMode(filename)
%
% INPUT:
%       o filename:    The filename of the listmode 
%
% OUTPUT:
%       o duration:    Duration of the listmode in seconds.
%
% version 2014.07.31
% Last update: created a function from the script, added help
%
% J.A. Disselhorst, 2014
% Werner Siemens Imaging Center, Tuebingen (DE)
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 

warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

    fid = fopen(filename);
    found = 0;
    while ~found
        numbers = fread(fid, 1, 'ubit48');
        numbers = dec2bin(numbers,48);
        type = numbers(5:8);
        if bin2dec(type)==10
            if ~bin2dec(numbers(9:12))
                found = 1;
                FirstTimeMark = bin2dec(numbers(17:48));
            end
        end
    end

    found = 0;
    fseek(fid,-6,'eof');
    while ~found
        numbers = fread(fid, 1, 'ubit48');
        numbers = dec2bin(numbers,48);
        type = numbers(5:8);
        if bin2dec(type)==10
            if ~bin2dec(numbers(9:12))
                found = 1;
                LastTimeMark = bin2dec(numbers(17:48));
            end
        end
        fseek(fid,-12,0);
    end
    fclose(fid);
    duration = (LastTimeMark-FirstTimeMark)/5000;
    fprintf('First time mark: %1.0f\n',FirstTimeMark);
    fprintf('Last time mark:  %1.0f\n',LastTimeMark);
    [h,m,s] = sec2hms(duration);
    fprintf('Total time:      %02.0f:%02.0f:%06.3f\n',h,m,s);
end