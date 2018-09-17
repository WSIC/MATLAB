function [CR,T] = listModeCountRate(file,timeres,starttime,duration)
% LISTMODECOUNTRATE obtains the coincidence count rate in an Inveon lst.
%
% USAGE:
% [CR, T] = listModeCountRate(file,timeres,starttime,duration)
%
% INPUT:
%  o file [string]    : filename
%  o timeres [float]  : time resolution [optional, default: 0.5]
%  o starttime [float]: start after this many second [optional, default: 0]
%  o duration [float] : read this many seconds [optional, default: to end]
%
% OUTPUT:
%  o CR [floatarray]  : the coincidence countrate at every time point
%                       Note: countrate in counts/timeres
%  o T [floatarray]   : time in seconds
%
% NOTE: Currently, this function cannot handle listmode files with an overflow
%       in the timemarks. (The timemarks are inserted every 5000 msec, and are
%       written in 32 bits. After 2^32 timemarks they start again at 0. In
%       those cases, the function may fail, or provide incorrect
%       results.
%
% JA DISSELHORST 2014-2018
% WERNER SIEMENS IMAGING CENTER
% Version 2018.09.17
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');


%% Definitions:
dataSize = 20;       % Data to read per iteration in MB.
if nargin<2  || isempty(timeres)
    timeres = 0.5;       % Required time resolution for the coinc counts (seconds)
end
if nargin<3  || isempty(starttime)
    starttime = 0;
end
if nargin<4  || isempty(duration)
    duration = Inf;
end

% Initialize (size etc)
[lstdur,filesize,FirstTimeMark] = durationListMode(file); % duration of the listmode in sec.
if starttime>lstdur
    error('Starttime (%1.1f s) beyond complete duration of listmode (%1.1f s)',starttime,lstdur)
elseif starttime<0
    starttime = 0;
end
if timeres < 1/100
    error('Please use a time resolution higher than 1/100 s');
end

% Some user setting have to be corrected
blocksize = round(dataSize*1024*1024/6);     % convert to number of packets to read.
timemarkres = max([1, round(timeres*5000)]); % Convert time resolution to timemark resolution, should be integer.
timeres = timemarkres/5000;                  % Correct time resolution for potential round-off errors above.
CR = zeros(1,ceil(lstdur/timeres))/0;        % countrate
T = CR; % time

h = waitbar(0,'Starting....'); % Init waitbar.
fid = fopen(file,'r','l');
if starttime>0 || (starttime+duration)<lstdur
    timepointsInLST = -ones(1,ceil(filesize/(blocksize*6)))*Inf;
    for xxx = 2:floor(filesize/(blocksize*6))+1
        fseek(fid,(blocksize*6)*(xxx-1),'bof'); % move forward.
        found = 0;
        while ~found % Find the closest timemark from here
            numbers = fread(fid, 12, 'ubit4');
            if numbers(11)==10 && ~numbers(10)
                timepointsInLST(xxx) = sum(bitshift(numbers(1:8),[0;4;8;12;16;20;24;28]))-FirstTimeMark;
                found = 1;
            end
        end
        if (timepointsInLST(xxx)/5000) >= (starttime+duration)
            break; % We don't need to continue if we already reached the requested duration.
        end
    end
    startpackage = (timepointsInLST/5000)-starttime;
    startpackage(startpackage>0) = -Inf;
    [~,startpackage] = max(startpackage);
    fseek(fid,(blocksize*6)*(startpackage-1),'bof');

    endpackage = (timepointsInLST/5000)-(starttime+duration);
    endpackage(endpackage<0) = Inf;
    [~,IX] = min(endpackage(end:-1:1));   %
    endpackage = length(endpackage)-IX+1; %
else
    startpackage = 1;
    endpackage = floor(filesize/(blocksize*6))+1;
    frewind(fid);
end

tic;
% Read data.
pos = 1;
lastblockcoinc = 0; % The coincidences left from last datablock;
for xxx = startpackage:endpackage
    try %#ok<TRYNC>
        numbers = fread(fid,[12,blocksize],'ubit4');  % Open a block of six-byte packages x the number of packages
        types = numbers(11,:);
        count = numbers(10,:);
        timerpos = find(types==10 & ~count);
        coincpos = (types<=7);

        timeMarks = sum(bitshift(numbers(1:8,timerpos),repmat([0;4;8;12;16;20;24;28],[1,length(timerpos)])))-FirstTimeMark;
        splitPos = timerpos(~rem(timeMarks,timemarkres));
        nT = length(splitPos);

        currentcoinccounts = zeros(1,length(splitPos));
        currentcoinccounts(1) = lastblockcoinc + sum(coincpos(1:splitPos(1)));  % the end of the previous block + the beginning of this block
        for ii = 1:length(splitPos)-1
            currentcoinccounts(ii+1) = sum(coincpos(splitPos(ii):splitPos(ii+1)));
        end
        lastblockcoinc = sum(coincpos(splitPos(end):end));  % The coincidences left in this block, will be used in the next block.

        CR(pos:pos+nT-1) = currentcoinccounts;
        T(pos:pos+nT-1) = timeMarks(~rem(timeMarks,timemarkres))/5000;
        pos = pos+nT;
        [H,M,S] = sec2hms(toc);
        waitbar((xxx-startpackage+1)/(endpackage-startpackage+1),h,sprintf('%02.0f:%02.0f:%02.0f: %1.2f%% [~%1.0f MB, %1.0f/%1.0fs]. ',H,M,S,(xxx-startpackage+1)/(endpackage-startpackage+1)*100,xxx*blocksize*6/1024/1024,timeMarks(end)/5000,lstdur));
        drawnow;
    end
end
fclose(fid);

% Clean up the data: remove unused (NaN) and cut to specifications.
CR(pos:end) = [];
T(pos:end) = [];
CR(T<starttime) = [];
T(T<starttime) = [];
CR(T>starttime+duration) = [];
T(T>starttime+duration) = [];

try delete(h); end %#ok<TRYNC>

end

function [hour, minute, second] = sec2hms(sec)
%SEC2HMS  Convert seconds to hours, minutes and seconds.
%
%   [HOUR, MINUTE, SECOND] = SEC2HMS(SEC) converts the number of seconds in
%   SEC into hours, minutes and seconds.

%   Author:      Peter J. Acklam
%   Time-stamp:  2002-03-03 12:50:09 +0100
%   E-mail:      pjacklam@online.no
%   URL:         http://home.online.no/~pjacklam

   hour   = fix(sec/3600);      % get number of hours
   sec    = sec - 3600*hour;    % remove the hours
   minute = fix(sec/60);        % get number of minutes
   sec    = sec - 60*minute;    % remove the minutes
   second = sec;
end
