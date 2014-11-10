function [M,X,Y,Z,VOI,VNames] = pixeldump2matrix(fileName)
% PIXELDUMP2MATRIX loads a pixeldump (from IRW or PMOD) and builds a matrix
% Usage: 
%         [M,X,Y,Z,VOI,VNames] = pixeldump2matrix(fileName)
%
% Input:
%         o fileName: name of a comma separated values file containing
%                     the pixel dump. Can either be from IRW or PMOD. 
%                     Pixel dumps from PMOD should include the header!
% Ouput:
%         o M:        A matrix containing the value of each pixel.
%         o X:        The x-positions of each pixel. 
%         o Y:        The y-positions of each pixel.
%         o Z:        The z-positions of each pixel.
%         o VOI:      The VOI number the pixel belongs to.
%         o VNames:   The names of the VOIs.
%
% JA Disselhorst; 
% version 20130913
% Uses code from 'gnovice' on stackoverflow: 
%     http://stackoverflow.com/a/4801735
%
    if nargin<1
        error('Please provide the filename for the pixeldump');
    end
fprintf('Loading file...');
fid = fopen(fileName,'r');                  %# Open the file
lineArray = cell(1,1); 
lineIndex = 1;                              %# Index of cell to place the next line in
nextLine = fgetl(fid);                      %# Read the first line from the file
while ~isequal(nextLine,-1)                 %# Loop while not at the end of the file
    if ~isempty(nextLine)
        lineArray{lineIndex,1} = nextLine;  %# Add the line to the cell array
        lineIndex = lineIndex+1;            %# Increment the line index
    end
    nextLine = fgetl(fid);                  %# Read the next line from the file
end
fclose(fid);                                %# Close the file

%% Check for IRW or PMOD
str = lineArray{1};
if regexp(str,'PIXEL DUMP')
    app = 'PMOD';
    delimiter = '\t';
elseif regexp(str,'Subject ID')
    app = 'IRW';
    delimiter = ',';
else
    error('Unknown Pixeldump, currently not supported. Please use IRW or PMOD, and for PMOD: be sure to include the header info');
end

%% Convert data to cells
for iLine = 1:lineIndex-1                           %# Loop over lines
    lineData = textscan(lineArray{iLine},'%s','Delimiter',delimiter);   %# Read strings
    lineData = lineData{1};                         %# Remove cell encapsulation
    if strcmp(lineArray{iLine}(end),delimiter)      %# Account for when the line
    	lineData{end+1} = '';                       %#   ends with a delimiter
    end
    lineArray(iLine,1:numel(lineData)) = lineData;  %# Overwrite line data
end
%% Load the correct columns. 
switch app
    case 'PMOD'
        VOIs = find(cellfun(@(x) ~isempty(x),(regexp(lineArray(2,:),'VoiName'))));
        if isempty(VOIs), error('Cannot find VOI names'); end
        VOIs = lineArray(4:end,VOIs);
        ID = find(strcmpi(lineArray(2,:),'Time'));
        T = str2double(lineArray(4:end,ID));
        X = str2double(lineArray(4:end,ID+1)); 
        Y = str2double(lineArray(4:end,ID+2)); 
        Z = str2double(lineArray(4:end,ID+3)); 
        V = str2double(lineArray(4:end,ID+4)); 
    case 'IRW'
        X = str2double(lineArray(4:end,1)); 
        Y = str2double(lineArray(4:end,2)); 
        Z = str2double(lineArray(4:end,3)); 
        V = str2double(lineArray(4:end,4));
        T = zeros(size(X));
        VOIs = cell(size(X));
        
        VOINP = find(cellfun(@(x) ~isempty(x),(regexp(lineArray(4:end,1),'ROI Name: '))));
        VoiB = VOINP+1; VOINP(end+1) = lineIndex;
        VoiE = VOINP(2:end)-1; VOINP(end) = [];
        for ii=1:length(VOINP)
            VOIs(VoiB(ii):VoiE(ii),1) = {lineArray{VOINP(ii)+3,1}(11:end)};
        end
        kill = cellfun(@(x) isempty(x),VOIs);
        X(kill) = []; Y(kill) = []; Z(kill) = [];
        T(kill) = []; VOIs(kill) = []; V(kill) = [];
end

%% Make the Matrix
    xsz = [min(X), max(X)]; X = X-min(X); % Get the range of pixel positions
    ysz = [min(Y), max(Y)]; Y = Y-min(Y); 
    zsz = [min(Z), max(Z)]; Z = Z-min(Z);
       
    F = 1E6; % Small errors are allowed.
    X = round(F*X)/F; Y = round(F*Y)/F; Z = round(F*Z)/F;
    
    xst = min(diff(unique(X))); if isempty(xst), xst = 1; end % Get the pixel size 
    yst = min(diff(unique(Y))); if isempty(yst), yst = 1; end % This routine can fail, but 
    zst = min(diff(unique(Z))); if isempty(zst), zst = 1; end % will work in most cases.

    X = X/xst+1; Y = Y/yst+1; Z = Z/zst+1; % Increase with the pixelsize.
    roe = max([max(abs(round(X)-X)), max(abs(round(Y)-Y)), max(abs(round(Z)-Z))]);
    if roe>=0.1
        error('Rounding-off errors in pixel positions larger than 10%!')
    elseif roe>0.001
        warning('Rounding-off errors in pixel positions larger than 0.1%! ')
    end
    X = round(X); Y = round(Y); Z = round(Z);
    [VNames,~,VOIs] = unique(VOIs);
    
    M = zeros(max(X),max(Y),max(Z))./0; % Allocate the Matrix.
    VOI = M;
    I = sub2ind(size(M),X,Y,Z);         % For indexing.
    M(I) = V;                           % Fill the matrix with the values.
    VOI(I) = VOIs;                      % Fill with the VOI index.
    [X,Y,Z] = meshgrid(ysz(1):yst:ysz(2), xsz(1):xst:xsz(2), zsz(1):zst:zsz(2));

    if length(unique(T))>1
        warning('Dynamic sequences currently not supported');
    end
    fprintf(' Done.\n');
end