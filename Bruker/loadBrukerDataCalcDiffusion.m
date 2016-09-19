function varargout = loadBrukerDataCalcDiffusion(folder, savedicom)
% LOADBRUKERDATACALCDIFFUSION: load biospec-data, calculate ADC, save DCM
% This function will take a folder with diffusion weighted data from the
% Bruker Biospec MRI and calculates an ADC. The ADC can be saved as DICOM.
% The original data has to be present as DICOM.
%
% Usage:  
%          [ADC, IMG, HDR, BV] = loadBrukerDataCalcDiffusion(FOLDER, SAVE)
% 
% Inputs: 
%         o FOLDER: the full path to the data [string]. 
%           This is an optional parameter. Leave empty to get a UIGETDIR
%           Folder should point to the expno with the diffusion weighted
%           data, i.e., without pdata/1/... The 1st procno is taken. 
%         o SAVE: should the final ADC be saved as dicom? [boolean]
%           Optional. Defaults: FALSE if nargout>0, TRUE otherwise.
%           ADC is saved as 16 bit ints, values are multiplied with 1000
%           to reduce round-off errors.  
%
% Outputs:
%         o ADC: The ADC volume [(x,y,z) doubles].
%         o IMG: The original data [(x,y,z,bv) doubles].
%         o HDR: The original DICOM headers [(z,bv) cell].
%         o BV:  The b-Values used for the calculation [(bv,1) double].
%
% Examples:
%         o loadBrukerDataCalcDiffusion; % ask for inputdata, save dicom
%         o adc = loadBrukerDataCalcDiffusion('C:\mri\9',1);
%
% See also LOADDICOM READBRUKERPARAMFILE CALCULATEDIFFUSION SAVEDICOM
%
% Jonathan A. Disselhorst, Werner Siemens Imaging Center
% Version 2016.02.01
%
% :::::::::::::::::::::::::::::: Disclaimer ::::::::::::::::::::::::::::::
% :   THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY   :
% : KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK :
% ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    
    % Check input and output:
    if nargin<1 || isempty(folder)
        folder = uigetdir([],'Pick the series folder, i.e., without pdata\1\dicom. (It uses the first procno)');
    end
    if nargin<2 && nargout>0
        savedicom = 0;
    elseif nargin<2 && nargout == 0
        savedicom = 1;
    end

    % load Dicom:
    [IMG,header] = loadDicom(fullfile(folder,'pdata\1\dicom'));

    % load bValues:
    methodData = readBrukerParamFile(fullfile(folder,'method'));
    bValues = methodData.PVM_DwEffBval; 

    % calc diffusion (ignore/average direction):
    ADC = calculateDiffusion(IMG(:,:,:,:),bValues);
    ADC2 = int16(ADC*1000); 
    
    % Save Dicom??
    if savedicom
        extraHDR.ImageType='DERIVED\PRIMARY\M\ND\ADC';
        extraHDR.ProtocolName='ADC';
        extraHDR.SeriesDescription = 'ADC';
        saveDicom(ADC2, header(:,1), [], fullfile(folder,'output.dcm'), extraHDR);
    end
    
    % Handle the output.
    if nargout
        varargout{1} = ADC;
        varargout{2} = IMG;
        varargout{3} = header;
        varargout{4} = bValues;
    end
