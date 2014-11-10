%% PROCESSDICOMDIR Sorts folder with dicom-files in subfolders.
% WARNING: each series will be copied to its own folder, 
% this is based on the series name and instance uid.
% BE CAREFULL, FILES MAY GET MIXED UP!
% JA Disselhorst 2012. Uni.Tuebingen.

function status = processDicomDir(dataFolder,targetFolder)
    status = 0;
    h = waitbar(0,'Initializing....');fprintf('\n....'); 
    files = dir(fullfile(dataFolder,'*.IMA'));

    curDir = cd;
    cd([matlabroot strrep('_toolbox_images_iptformats_private','_',filesep)]);  % path to a faster, more basic dicom parser -> new matlab
    [g1, e1] = dicomlookup('SeriesInstanceUID'); UIDs = {};
    [g2, e2] = dicomlookup('SeriesDescription'); names = {};
    [g3, e3] = dicomlookup('SeriesNumber');
    [g4, e4] = dicomlookup('StudyInstanceUID');
    
    
    

    for i = 1:length(files)
        a = dicomparse(fullfile(dataFolder,files(i).name),files(i).bytes, 'L', false, dicomdict('get_current'));
        idx = ([a.Group] == g1) & ([a.Element] == e1);
        UID = char(a(idx).Data);
        idx = ([a.Group] == g2) & ([a.Element] == e2);
        name = deblank(char(a(idx).Data));
        idx = ([a.Group] == g3) & ([a.Element] == e3);
        serie = str2double(deblank(char(a(idx).Data)));
        if ~any(strcmpi(UID,UIDs)) % new UID found
            UIDs(1,end+1) = {UID};
            n = 1; name = sprintf('%02.0f_%s',serie,name);
            names(1,end+1) = {name};
            [~,~,~] = mkdir(targetFolder,name);
        else  % not new.
            name = char(names(strcmpi(UID,UIDs)));
        end
        copyfile(fullfile(dataFolder,files(i).name),fullfile(targetFolder,name,files(i).name));
        waitbar(i/length(files),h,'copying.....'); fprintf('\b\b\b\b%3.0f%%',i/length(files)*100);
    end
    close(h); fprintf('\b\b\b\b');
    cd(curDir);
    status = 1;