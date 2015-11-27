function [ADC,IMG,HDR, bValues] = loadBrukerDataCalcDiffusion(folder)

    % load Dicom:
    [IMG,HDR] = loadDicom(fullfile(folder,'pdata\1\dicom'));

    % load bValues:
    methodData = readBrukerParamFile2(fullfile(folder,'method'));
    bValues = methodData.PVM_DwEffBval; 

    % calc diffusion (ignore direction):
    ADC = calculateDiffusion(IMG(:,:,:,:),bValues);
