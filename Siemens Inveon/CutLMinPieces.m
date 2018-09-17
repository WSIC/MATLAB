%% Start
clear all; close all; clc; fclose all;
LMfile = '\\mb-petinsert1\ListMode\Normalizations\20180814_NormAfterSetup_18h.lst';
savedir = '\\mb-petinsert1\ListMode\Normalizations\3E9Counts'; 

frames = [26642];


%% allocate and initialization
tic; clc
fid = fopen(LMfile,'r','l');
found = 0;
while ~found
    numbers = fread(fid, 1, 'ubit48');
    numbers = dec2bin(numbers,48);
    gray = numbers(1:4);
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
    gray = numbers(1:4);
    type = numbers(5:8);
    if bin2dec(type)==10
        if ~bin2dec(numbers(9:12))
            found = 1;
            LastTimeMark = bin2dec(numbers(17:48));
        end
    end
    fseek(fid,-12,0);
end
fseek(fid,0,'eof'); filesize = ftell(fid); frewind(fid);
lstdur = (LastTimeMark-FirstTimeMark)/5000; % duration of listmode in seconds
fprintf('First Time Mark: %1.0f\n',FirstTimeMark);
fprintf('Last Time Mark:  %1.0f\n',LastTimeMark);
fprintf('Listmode duration: %1.3f sec\n',lstdur)

cutpoints = cumsum(frames)*5000;


%% Some Checks
if ~exist(savedir)
    mkdir(savedir);
end
abc = dir(savedir);
if length(abc)>2
    answer = questdlg('Save directory is not empty. Overwrite existing content?','Not empty','Yes','No','No');
    if ~strcmpi(answer,'yes')
        error('Save directory not empty');
    end
end
timedif = lstdur - sum(frames);
if timedif>0
    answer = questdlg(sprintf('Listmode duration: %1.2f s, requested framing: %1.2f s. What to do with the extra time (%1.2f s)?',lstdur,sum(frames),timedif),'Difference in duration','New frame','Drop','Add to last frame','New frame');
    if strcmpi(answer,'Add to last frame')
        cutpoints(end) = LastTimeMark-FirstTimeMark;
        frames(end) = frames(end)+timedif;
        useEverything = 1;
    elseif strcmpi(answer,'New frame')
        frames(end+1) = timedif;
        useEverything = 1;
    else
        useEverything = 0;
    end
elseif timedif<0
    msgbox(sprintf('Listmode duration: %1.2f s, requested framing: %1.2f s. Not all frames will be complete!',lstdur,sum(frames)),'Difference in duration','warn')
end


%% Make an estimate of the timepoints in the file
% take a sample of 1200 bytes (500 packages) every ~25 MB:
rsize = 500; % num packages to read
skip = round(25*1024*1024/6)*6-(rsize*6); % skip in bytes
N = floor(filesize/skip);
filepos = zeros(1,N+2)/0; filepos(1) = 0; filepos(end) = filesize;
times = zeros(1,N+2)/0; times(1) = FirstTimeMark; times(end) = LastTimeMark;
fprintf('Estimating cutpoints... 000%%');
for ii = 1:N
    fseek(fid,skip,'cof');
    numbers = fread(fid,[12,rsize],'ubit4');
    types = numbers(11,:);
    count = numbers(10,:);
    timerpos = find(types==10 & ~count);
    if ~isempty(timerpos)
        filepos(ii+1) = (ii-1)*(skip+rsize*6) + skip + (timerpos(1)-1)*6;
        times(ii+1) = bin2dec(reshape(dec2bin(numbers(8:-1:1,timerpos(1)),4)',1,32));
    end
    fprintf('\b\b\b\b%03.0f%%',ii/N*100);
end
fprintf('\n')
estimatedfilecuts = round(interp1(times,filepos,cutpoints+FirstTimeMark)/6)*6;
frewind(fid);

%% Get the real cutpositions:
estpacks = 5000; % how many packs to read to find the proper cut points
realfilecuts = zeros(1,length(frames));
if estimatedfilecuts(end)>filesize-estpacks*6
    estimatedfilecuts(end) = filesize-estpacks*6;
end
if useEverything, realfilecuts(end) = filesize; end;
for ii = 1:length(frames)-useEverything % if the whole file is used, we don't need to search for the last cut.
    found = 0; offset = 0;
    tries = 0;
    while ~found
        tries = tries+1; if tries > 1000, error('cannot find the right cutting point... '); end
        status = fseek(fid,estimatedfilecuts(ii)-round(estpacks/2)*6 + offset*estpacks*6,'bof');
        if status
            warning('something isn''t right...');
            continue
        end
        numbers = fread(fid,[12,estpacks],'ubit4');
        types = numbers(11,:);
        count = numbers(10,:);
        timerpos = find(types==10 & ~count);
        if ~isempty(timerpos)
            theseTimes = zeros(1,length(timerpos));
            for jj = 1:length(timerpos)
                theseTimes(jj) = bin2dec(reshape(dec2bin(numbers(8:-1:1,timerpos(jj)),4)',1,32));
            end
            timediffs = (theseTimes-FirstTimeMark-cutpoints(ii));
            [v,ix] = min(abs(timediffs));
            if v == 0 % we found the package
                found = 1;
                realfilecuts(ii) = estimatedfilecuts(ii)-round(estpacks/2)*6 + offset*estpacks*6 + (timerpos(ix)-1)*6;
            elseif timediffs(ix)>0 % we need to go back
                offset = offset-1;
            else % we need to go forward
                offset = offset+1;
            end
        else
            error('No time marks found, ''estpacks'' is set too low, please increase!');
        end
    end
end
plot(filepos,(times-FirstTimeMark)/5000); ylabel('Time [s]'); xlabel('Fileposition [bytes]');
hold on;
plot(estimatedfilecuts,cutpoints/5000,'r.')
plot(realfilecuts,cutpoints/5000,'r-+')
hold off

%% Cut it. The new version.
if ~all(round(realfilecuts/6) == realfilecuts/6)
    error('Some cuts are not in 6 byte intervals. Cannot proceed.');
end
blocksize = 1747627*6; % around 10MB per block is copied.
fseek(fid,0,'bof');
wbh = waitbar(0);
for ii = 1:length(frames)
    fid2 = fopen(fullfile(savedir,sprintf('Frame%03.0f.lst',ii)),'w+');
    complete = 0;
    while ~complete
        position = ftell(fid);
        if position+blocksize<realfilecuts(ii)
            data = fread(fid,blocksize);
            fwrite(fid2,data);
        else
            data = fread(fid,realfilecuts(ii)-position+6); % still include the timemark in the block
            fwrite(fid2,data);
            complete = 1;
        end
        try, waitbar(position/filesize,wbh,sprintf('Frame %u/%u. (%1.0f/%1.0f MB)',ii,length(frames),position/1024/1024,filesize/1024/1024)); end 
    end
    fclose(fid2);
    fseek(fid,-6,'cof'); % also include the time mark in the next.
end
fclose(fid);


%% Cut it. The old version.
%{
blocksize = 1747627; % around 10MB per block.
pos = 0;
nowcreating = 1;
writeID = fopen(fullfile(savedir,'Frame001.lst'),'w+');

h = waitbar(0);
for xxx = 1:floor(filesize/(blocksize*6))+1
    numbers = fread(fid,[12,blocksize],'ubit4');  % Open a block of six-byte packages.
    types = numbers(11,:);
    count = numbers(10,:);
    timerpos = find(types==10 & ~count);
    
    timemarks = (1:length(timerpos)) + pos;
    inters = intersect(timemarks,cutpoints);
    start = 1;
    if ~isempty(inters)
        for ii = 1:length(inters)
            knip = timerpos(cutpoints(nowcreating)-pos);
            fwrite(writeID,numbers(:,start:knip),'ubit4');
            start = knip + 1;
            fclose(writeID);
            nowcreating = nowcreating+1;
            writeID = fopen(fullfile(savedir,sprintf('Frame%03.0f.lst',nowcreating)),'w+');
        end
    end
    fwrite(writeID,numbers(:,start:end),'ubit4');

    [H,M,S] = sec2hms(toc);
    [H2,M2,S2] = sec2hms((timemarks(end)-FirstTimeMark)/5000);
    waitbar((xxx*blocksize*6)/filesize,h,sprintf('Elapsed time %02.0f:%02.0f:%02.0f: %1.2f%% [~%1.0f MB] @%02u:%02u:02u.',H,M,S,(xxx*blocksize*6)/filesize*100,xxx*blocksize*6/1024/1024),H2,M2,S2);
    %fprintf('\b\b\b\b\b\b%5.1f%%',(xxx*blocksize*6)/filesize*100)

    pos = pos + length(timerpos);
end
fclose(fid);
fclose(writeID);

%}
        
        