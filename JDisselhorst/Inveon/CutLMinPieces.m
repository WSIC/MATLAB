%% Start
clear all; close all; clc; fclose all;
LMfile = 'F:\DATA\FortueneII-MaLTT\Series3\MaLLT_20140825_Control24h_M08\PET\MaLLT_Control24h_Mouse08a.lst';
savedir = 'F:\DATA\FortueneII-MaLTT\Series3\MaLLT_20140825_Control24h_M08\PET\Pieces'; 

frames = [664, 25,90,24,  36,24, 20,217, 283, 904, 7, 600,3, 478 ];
          %x, 3ds,x ,3ds, x, 3ds, x,shim, x,  adc, x, t2, x, t2s
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
    answer = questdlg(sprintf('Listmode duration: %1.2f s, requested framing: %1.2f s. What to do with the extra time (%1.2f s)?',lstdur,sum(frames),timedif),'Difference in duration','New frame','Add to last frame','New frame');
    if strcmpi(answer,'Add to last frame')
        cutpoints(end) = Inf;
    end
elseif timedif<0
    msgbox(sprintf('Listmode duration: %1.2f s, requested framing: %1.2f s. Not all frames will be complete!',lstdur,sum(frames)),'Difference in duration','warn')
end

%% Cut it.
blocksize = 1747627; % around 10MB per block.
pos = 0;
nowcreating = 1;
writeID = fopen(fullfile(savedir,'Frame001.lst'),'w+');

h = waitbar(0);
for xxx = 1:floor(filesize/(blocksize*6))+1;
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
    waitbar((xxx*blocksize*6)/filesize,h,sprintf('%02.0f:%02.0f:%02.0f: %1.2f%% [~%1.0f MB]. ',H,M,S,(xxx*blocksize*6)/filesize*100,xxx*blocksize*6/1024/1024));
    %fprintf('\b\b\b\b\b\b%5.1f%%',(xxx*blocksize*6)/filesize*100)

    pos = pos + length(timerpos);
end
fclose(fid);
fclose(writeID);
        
        
        