function [IMG, HDR] = loadDicom(varargin)
% LOADDICOM loads all the DICOMs in a folder
% [IMG, HDR] = loadDicom(directory);
% Load dicom images to a [X,Y,Z,T] matrix in Matlab.
% Looks only for *.DCM and *.IMA.
%
% Input can be:
%  - empty (program will ask to select a folder, or files)
%  - directory (program will load all dicoms in folder)
%  - a cell-array with filenames including full path
%
% Output: 
%  - IMG: the image matrix [x,y,z,t]
%  - HDR: the DICOM-headers [z,t]
%
% Version 2014.05.02
% JA Disselhorst
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');


if nargin==0
    try 
        directory = getenv('JDisselhorstFolder');
    catch
        directory = cd;
    end
    
    if exist('uipickfiles','file') % uipickfiles from the fileexchange is available -> use it.
        selected = uipickfiles('FilterSpec',directory,'Type',{'*.ima','DICOM (*.ima)';'*.dcm','DICOM (*.dcm)';'*','All files (*.*)'},'Output','struct');
        if isstruct(selected)
            files = {};
            for N = 1:length(selected)
                if selected(N).isdir;
                    thisfiles = getFilesFromDir(selected(N).name);
                    files = [files; thisfiles];
                else
                    files = [files; selected(N).name];
                end
            end
        else
            files = [];
        end
    else
        directory = uigetdir(directory);
        if ~directory
            error('No folder selected!');
        end
        setenv('JDisselhorstFolder',directory);
        files = getFilesFromDir(directory);
    end
else
    if iscell(varargin{1})
        files = varargin{1};
    else
        files = getFilesFromDir(varargin{1});
    end
end

if isempty(files)
    warning('No files or folders selected.');
    IMG = []; HDR = [];
    return
end
drawnow
N = length(files);
fprintf('Loading files:     0%%');
temp = dicominfo(files{1});
Rows = temp.Rows; Cols = temp.Columns;
IMG = zeros(Rows,Cols,N);
HDR = cell(1,N);

for currentFile = 1:N
    fileName = files{currentFile};
    try
        hdr = dicominfo(fileName);
        img = double(dicomread(hdr)); [R,C,S] = size(img);
    catch ME
        error('Loading %s failed (''%s'').\n',fileName,ME.message);
    end
    try % Some dicoms have rescaling values.
       Intercept = double(hdr.RescaleIntercept);
       Slope = double(hdr.RescaleSlope);
       img = img.*Slope + Intercept;
    end
    if S>1
        error('Multi-frame DICOM files are currently not supported...');
    elseif R~=Rows || C ~= Cols
        error('Not all files have the same image dimensions...');
    end
    IMG(:,:,currentFile) = img;
    HDR{1,currentFile} = hdr;
    fprintf('\b\b\b\b\b%4.1f%%',currentFile/N*100);
end
fprintf('\n');

[IMG,HDR] = sortImages(IMG,HDR);

end

function files = getFilesFromDir(directory)
    temp = dir(fullfile(directory,'*.IMA'));
    if length(temp)<2
        temp = dir(fullfile(directory,'*.DCM'));
           % if length(files)<2
           %     files = dir(fullfile(directory,'*'));
                if length(temp)<2
                    fprintf('No files found in %s! Is the extension .DCM or .IMA?\n',directory);
                    files = [];
                    return
                end
           % end
    end
    temp([temp.isdir]) = [];
    if ~isempty(temp) && isstruct(temp)
        files = cell(length(temp),1);
        for ii = 1:length(temp)
            files{ii} = fullfile(directory,temp(ii).name);
        end
    end
end

function [IMG,HDR] = sortImages(IMG,HDR)
    % Determine how the images are arranged;
    N = length(HDR);
    IPP = zeros(N,3);
    Time = zeros(N,1);
    Instance = zeros(N,1);
    Series = zeros(N,1);
    Acq = zeros(N,1);
    for ii = 1:N
        IPP(ii,:) = HDR{ii}.ImagePositionPatient;
        try 
            D = HDR{ii}.AcquisitionDate;
            T = HDR{ii}.AcquisitionTime; T = sprintf('%010.3f',str2double(T)); % Change the time into HHMMSS.FFF
            Time(ii) = datenum([D,'-',T],'yyyymmdd-HHMMSS.FFF');
        catch
            Time(ii) = NaN;
        end
        try Instance(ii) = HDR{ii}.InstanceNumber; catch, Instance(ii) = 0; end
        try Series(ii) = HDR{ii}.SeriesNumber; catch, Series(ii) = 0; end
        try Acq(ii) = HDR{ii}.AcquisitionNumber; catch, Acq(ii) = 0; end
    end

    [IPPuni,IPPpos,IPPind] = unique(IPP, 'rows');
    if length(IPPpos) == numel(HDR) % There are no frames
        HDR = HDR(IPPpos); HDR = reshape(HDR,[],1);
        IMG = IMG(:,:,IPPpos);
    else                            % There are frames in this data.
        z = size(IPPuni,1); x = size(IMG); y = x(2); x = x(1);
        [uniqueInstances,~,instanceIndex] = unique(ceil(Instance/z));
        T = length(uniqueInstances);
        if T==1 || T*z~=N % Cannot sort the images based on instance number
            [uniqueSeries,~,seriesIndex] = unique(Series); % Try it based on the series number, e.g., for a set of diffusion weighted images.
            T = length(uniqueSeries);
            if T==1 || T*z~=N % Cannot sort based on the series number
                error('Cannot sort based on instance and series number, sorting based on time is not yet implemented. Or some other problems could have occured, e.g., inprobable variations in slice location (ImagePositionPatient)');
            elseif T>1
                IMG2 = zeros(x,y,z,T);
                HDR2 = cell(z,T);
                for ii = 1:N
                    IMG2(:,:,IPPind(ii),seriesIndex(ii)) = IMG(:,:,ii);
                    HDR2(IPPind(ii),seriesIndex(ii)) = HDR(ii);
                end
                HDR = HDR2;
                IMG = IMG2;
            end
%         elseif regexpi(HDR{1}.Manufacturer,'Bruker')
%             warning('Caution: This is Bruker Paravision Dicom. Sorting may very well be incorrect!');
%             TheIndex = Instance-(IPPind-1)*T;
%             IMG2 = zeros(x,y,z,T);
%             HDR2 = cell(z,T);
%             for ii = 1:N
%                 IMG2(:,:,IPPind(ii),TheIndex(ii)) = IMG(:,:,ii);
%                 HDR2(IPPind(ii),TheIndex(ii)) = HDR(ii);
%             end
%             HDR = HDR2;
%             IMG = IMG2;
        elseif T>1
            IMG2 = zeros(x,y,z,T);
            HDR2 = cell(z,T);
            for ii = 1:N
                IMG2(:,:,IPPind(ii),instanceIndex(ii)) = IMG(:,:,ii);
                HDR2(IPPind(ii),instanceIndex(ii)) = HDR(ii);
            end
            HDR = HDR2;
            IMG = IMG2;
        end
    end    
end

