% This is a script to load HASTE files and output an ADC-map as DICOM.
%
% 1. All haste files should be in one folder!
folder = cd;
% 2. Set the folder:
folder = uigetdir(folder,'Select folder with HASTE-dicoms. All files should be in this folder (not subfolders)!');
if ~folder, error('Please select a folder!'); end

% 3. Load the haste images:
[imageMatrix,header] = loadDicom(folder);

% 4. Calculate the ADC:
results = calculateDiffusion(imageMatrix,HDR); clc;

% 5. Make the units micrometer^2/s.
ADC = int16(results*1000); 

% 6. Save the results to a dicom. 
pause(.01); % This pause is necessary because of some weird matlab behavior... 
finished = 0; 
while ~finished
startover = 0;
[fileName,pathName] = uiputfile({'*.dcm;*.ima','DICOM files (*.dcm,*.ima)'},'Select output folder and filename',fullfile(folder,'output.dcm'));
overwrite = 0;
if pathName
    ext = fileName(end-2:end);
    fileName = fileName(1:end-4);
    DcmID = dicomuid;
    for N = 1:size(header,1)
        if startover 
            continue
        end
        HDR = header{N,1};
        HDR.SeriesInstanceUID = DcmID;
        HDR.ImageType='DERIVED\PRIMARY\M\ND\ADC';
        HDR.ProtocolName='ADC';
        outFile = fullfile(pathName,sprintf('%s_%03.0f.%s',fileName,N,ext));
        if exist(outFile,'file') && ~overwrite
            choice = questdlg(sprintf('%s already exists. Overwrite?',outFile),'File exists','Yes','All','No','No');
            switch choice
                case 'No'
                    startover = 1;  % Start over by selecting a new file name.
                    continue
                case 'All'          % All existing files should be overwritten
                    overwrite = 1;
            end
        end
        dicomwrite(ADC(:,:,N),outFile,HDR);
    end
    if ~startover
        finished = 1;
    end
end
end
fprintf('DONE!\n');


