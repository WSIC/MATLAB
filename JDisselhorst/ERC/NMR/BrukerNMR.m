function Bruker = BrukerNMR(mainFolder)
% BRUKERNMR opens bruker NMR data
% Usage: Bruker = BrukerNMR(mainFolder)
%
% Input: 
%         o  mainFolder:     the rootfolder of the dataset.
%
% Output:
%         o  Bruker:         structure containing all the information
%
% Notes:
%         1. The output structure contains two spectra, one created and
%            processed by the Bruker software ('spectrumBruker'). The other
%            ('spectrumJD') is created in the this function using the raw
%            FID data. The latter is highly experimental, is uncorrected
%            (i.e., no baseline correction, no phase correction, etc). This
%            spectrum should not be used for anything important!
%         2. Currenty only 1D spectra have been tested. It should work with
%            higher dimensional spectra, but there is absolutely no
%            guarantee, since it has not been tested. Use at your own risk.
% 
% J.A. DISSELHORST
% Werner Siemens Imaging Center
% v20140319
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
% EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

Bruker = struct;

%% Get the title and other general information
fileID = fopen(fullfile(mainFolder,'pdata','1','title'));
temp = textscan(fileID,'%s','WhiteSpace','\n');
Bruker.General.Title = temp{:};
fclose(fileID);
Bruker.General.Directory = mainFolder;

%% Read param files
Bruker.acqus   = readBrukerParamFile(fullfile(mainFolder,'acqus'));
Bruker.procs   = readBrukerParamFile(fullfile(mainFolder,'pdata','1','procs'));
try Bruker.acqu    = readBrukerParamFile(fullfile(mainFolder,'acqu')); end
try Bruker.acqu2   = readBrukerParamFile(fullfile(mainFolder,'acqu2')); end
try Bruker.acqu2s  = readBrukerParamFile(fullfile(mainFolder,'acqu2s')); end
try Bruker.acqu3   = readBrukerParamFile(fullfile(mainFolder,'acqu3')); end
try Bruker.acqu3s  = readBrukerParamFile(fullfile(mainFolder,'acqu3s')); end
try Bruker.scon2   = readBrukerParamFile(fullfile(mainFolder,'scon2')); end
try Bruker.specpar = readBrukerParamFile(fullfile(mainFolder,'specpar')); end
try Bruker.proc    = readBrukerParamFile(fullfile(mainFolder,'pdata','1','proc')); end
try Bruker.proc2   = readBrukerParamFile(fullfile(mainFolder,'pdata','1','proc2')); end
try Bruker.proc2s  = readBrukerParamFile(fullfile(mainFolder,'pdata','1','proc2s')); end
Bruker.General.AcquisitionTime = datestr((Bruker.acqus.DATE/24/60/60)+datenum(1970,1,1));

%% LOAD FID  -> 1D
try 
    if Bruker.acqus.BYTORDA==0, endian = 'l'; else endian = 'b'; end
    fileID = fopen(fullfile(mainFolder,'fid'),'r',endian);
    FID = fread(fileID,'int32');
    fclose(fileID);
    Bruker.FID = FID(1:2:end) + FID(2:2:end)*sqrt(-1);  % Separate real and imaginary. 
end

%% LOAD SER   -> 2D
try
    if Bruker.acqus.BYTORDA==0, endian = 'l'; else endian = 'b'; end
    fileID = fopen(fullfile(mainFolder,'ser'),'r',endian);
    SER = fread(fileID,'int32');
    warning('2D FID support not implemented properly!');
    fclose(fileID);
    TD = Bruker.acqus.TD; 
    SER = reshape(SER,TD,[]); % Make it 2D
    SER = SER(1:2:end,:) + SER(2:2:end,:)*sqrt(-1);
    Bruker.SER = SER;
end

%% PERFORM FOURIER TRANSFORM AND INVERT
% First multiply with a weighting function:
try 
    if Bruker.acqus.DIGTYP==12
        AQ = Bruker.acqus.TD / (2*Bruker.acqus.SW*Bruker.acqus.SFO1); % Aquisition time.
        LB = Bruker.procs.LB;  % Exponent
        TD = length(Bruker.FID);  % Number of points in FID.
        expWindow = exp(LB.*((1:TD)/TD*AQ*1000))';
    else
        warning('unknown digitizer, no exponential window applied!');
        expWindow = 1;
    end
    % There is a 'bug' in the FID of Bruker, see for example:
    % http://nmr-analysis.blogspot.com.au/2008/02/why-arent-bruker-fids-time-corrected.html
    % This relates to a time delay in the FID-data, before the real FID starts.
    % This time delay is apparently hardware specific. 
    td = 70; %number of points to remove from the signal.
    try td = round(Bruker.acqus.GRPDLY)+1; end
    %warning('Time delay: %1.0f point',td);

    % Perform FFT
    spectrumJD = fftshift(fft(Bruker.FID((1+td):end).*expWindow((1+td):end),Bruker.procs.FTSIZE));
    Bruker.spectrumJD = reshape(spectrumJD(end:-1:1),1,[]);
end
%% LOAD PROCESSED SPECTRA
try % 1D spectrum
    if Bruker.procs.BYTORDP==0, endian = 'l'; else endian = 'b'; end
    fileID = fopen(fullfile(mainFolder,'pdata','1','1r'),'r',endian);
    realpart = fread(fileID,'int32');
    fclose(fileID);
    fileID = fopen(fullfile(mainFolder,'pdata','1','1i'),'r',endian);
    imagpart = fread(fileID,'int32');
    fclose(fileID);
    Bruker.spectrumBruker = reshape(complex(realpart,imagpart),1,[]);
catch
    try % 2D spectra
        fileID = fopen(fullfile(mainFolder,'pdata','1','1r'),'r',endian);
        realpart = fread(fileID,'int32');
    fclose(fileID);
    end
end
  

%% CREATE THE AXES
try
    Left = Bruker.procs.OFFSET;
    Step = -Bruker.acqus.SW/Bruker.procs.FTSIZE;
    Right = Bruker.procs.OFFSET - Bruker.acqus.SW - Step;
    Bruker.spectrumAxis = (Left:Step:Right);
end
end