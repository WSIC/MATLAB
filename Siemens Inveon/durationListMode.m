function varargout = durationListMode(filename)
%DURATIONLISTMODE determines the duration of Inveon LM file 
%
% USAGE: 
%       duration = durationListMode(filename)
%
% INPUT:
%       o filename:    The filename of the listmode (optional)
%
% OUTPUT:
%       o duration:    Duration of the listmode in seconds.
%       o filesize:    The file size in bytes.
%       o firstmark:   The fist time mark in the listmode.
%       o lastmark:    The last time mark in the listmode.
%
% J.A. Disselhorst, 2018
% Werner Siemens Imaging Center, Tuebingen (DE)
% version 2018.09.17
%         180917: more output
%         180807: detect wraparound
%         170524: ask for file with nargin==0
%         140731: created a function from the script, added help
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 

    warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');
    
    % Choose the file
    if nargin==0
        try 
            directory = getenv('JDisselhorstFolder');
        catch
            directory = cd;
        end
        [filename,directory] = uigetfile('*.lst','Select listmode file',directory);
        filename = fullfile(directory,filename);
    else
        directory = fileparts(filename);
    end
    
    % Open the file and find the first time mark
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
    
    % Go to the end of file and go backward to find the last time mark
    found = 0;
    fseek(fid,0,'eof'); filesize = ftell(fid);
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
    
    % Wraparound:
    RealLastTimeMark = LastTimeMark;
    if FirstTimeMark>LastTimeMark
        warning('The last time mark is smaller than the first, most likely due to integer overflow (wraparound). Adding a single 32bit offset (approximately 238.5 hours).')
        asterisk = sprintf(' (Originally %u)',LastTimeMark);
        LastTimeMark = LastTimeMark + 2^32;
    else
        asterisk = '';
    end
    
    % Final calculations and report. 
    duration = (LastTimeMark-FirstTimeMark)/5000; % Time marks are inserted every 200 microseconds.
    fprintf('First time mark: %1.0f\n',FirstTimeMark);
    fprintf('Last time mark:  %1.0f%s\n',LastTimeMark,asterisk);
    [h,m,s] = sec2hms(duration);
    fprintf('Total time:      %02.0f:%02.0f:%06.3f\n',h,m,s);
    if nargout>0
        varargout{1} = duration;
        varargout{2} = filesize;
        varargout{3} = FirstTimeMark;
        varargout{4} = RealLastTimeMark;
    end
    setenv('JDisselhorstFolder',directory);
end