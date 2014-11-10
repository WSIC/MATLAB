%% Inveon File Slice
clc
fprintf('Select header file: ...\n');
PathName = getenv('JDisselhorstFolder');
[FileName,PathName,FilterIndex] = uigetfile({'*.hdr','Header files (*.hdr)'},'Select Header file',PathName);
headerFile = fullfile(PathName,FileName);
dF = 4;
if FilterIndex
    setenv('JDisselhorstFolder',PathName);
    imageHeader = headerReader(headerFile);
    imageMatrix = buildMatrix(headerFile(1:end-4),imageHeader,dF,[1 1 1 imageHeader.General.total_frames; Inf Inf Inf Inf]);
    clc
    x = size(imageMatrix,1);
    y = size(imageMatrix,2);
    z = size(imageMatrix,3);
    mask = false(x,y,z);
    mask(ceil(x/3):floor(x/3*2),ceil(y/3):floor(y/3*2),ceil(z/3):floor(z/3*2)) = true;
    close all
    oV = overlayVolume(imageMatrix,mask,'alpha',0.1,'AspectRatio',[imageHeader.General.pixel_size_x imageHeader.General.pixel_size_y imageHeader.General.pixel_size_z]);
    ov.ROIEnabled = 2;
    oV.editROI(oV);
    hd = helpdlg({'Edit the ROI and press OK when done'},'Instructions');
    uiwait(hd);
    mask = oV.overVol; [x,y,z] = ind2sub(size(mask),find(mask));
    subSection = [ [(min(x)-1)*dF+1; max(x)*dF] ,...
                   [(min(y)-1)*dF+1; max(y)*dF] ,...
                   [(min(z)-1)*dF+1; max(z)*dF] ];
    close all
    [FileName,PathName,FilterIndex] = uiputfile({'*.hdr','Header files (*.hdr)'},'Save file as...',[headerFile(1:end-8), '_ROI.img.hdr']);
    if FilterIndex
        saveHeaderFile = fullfile(PathName,FileName);
        matrixSize = buildMatrix(headerFile(1:end-4),imageHeader,1,subSection,saveHeaderFile(1:end-4));
        imageHeader.General.x_dimension = matrixSize(1);
        imageHeader.General.y_dimension = matrixSize(2);
        imageHeader.General.z_dimension = matrixSize(3);
        imageHeader.General.total_frames = matrixSize(4);
        imageHeader.General.subject_identifier = [imageHeader.General.subject_identifier '-ROI'];
        imageHeader.General.file_name = saveHeaderFile(1:end-4);
        headerWriter(imageHeader,saveHeaderFile)
    else
        fprintf('No file has been saved.\n')
    end
end