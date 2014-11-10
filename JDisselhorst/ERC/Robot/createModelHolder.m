function volume = createModelHolder(type,writeFile)
% CREATEMODELHOLDER creates a voxelized model of holders from ERC project
% These holders have been designed by Fraunhofer IPA to work with the
% milling robot. 
%
% Usage: volume = createModelHolder(type,writeFile)
%
% Input (all input is optional):
%   o type:         Which holder? Can be 'mouse' [default] or 'rat'
%                   [currently only mouse is supported] 
%   o writeFile:    Should the model be written to a Inveon CT image file?
%                   false [default], or true
%
% Output:
%   o volume:       The voxelized model [X*Y*Z boolean]
%
%
% J.A. Disselhorst 2014.
% Werner Siemens Imaging Center, Uni. Tuebingen
% Version 2014.07.24
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
    warning('THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

    if nargin<1
        type = 'mouse';
    end
    if nargin<2
        writeFile = 0;
    end
    switch lower(type)
        case 'mouse'
            fprintf('Creating mouse holder model...');
            % Total volume: 160x70x35 mm, voxelsize: 0.1 mm
            volume = false(1600,700,350);

            % Bottom:
            % 5 mm thick. 
            % Circles of 6.6 mm diameter. 27 mm in y, and 69 and 71 mm in x.
            % Corners are cut off at 2 mm
            [y,x] = meshgrid(-349.5:349.5,-799.5:799.5);
            pattern = sqrt((x-690).^2 + (y-270).^2)<=33;
            pattern = pattern | (sqrt((x-710).^2 + (y-270).^2)<=33);
            pattern(x>=690 & x<=710 & y>=237 & y<=303) = true;
            pattern = pattern | fliplr(pattern);
            pattern = pattern | flipud(pattern);
            for ii = 1:19
                pattern([1:ii, 1601-ii:end],20-ii) = true;
                pattern([1:ii, 1601-ii:end],681+ii) = true;
            end
            volume(:,:,1:50) = repmat(~pattern,[1,1,50]);


            % Pattern in the bottom:
            % circle in the center (6 mm diameter)
            % two circles at 25 and 55 mm from the center
            pattern = pattern | (sqrt(x.^2+y.^2)<=30);
            pattern = pattern | (sqrt((x+250).^2 + y.^2)<=20);
            pattern = pattern | (sqrt((x+550).^2 + y.^2)<=20);
            pattern(abs(y)<=20 & x<=-250 & x>=-550) = true;
            volume(:,:,1:20) = repmat(~pattern,[1,1,20]);

            % Sides:
            % 4 mm wide, with rounded edged of radius is 3 mm
            volume(176:1425,:,51:end) = true;
            pattern = (sqrt((abs(x)-555).^2 + (abs(y)-280).^2)<=30);
            pattern(246:1355,41:660) = true;
            pattern(216:1385,71:630) = true;
            cutout = repmat(pattern,[1 1 350]);
            cutout(:,:,1:50) = false;
            x = repmat(x,[1 1 30]);
            y = repmat(y,[1 1 30]);
            z = repmat(reshape(-29.5:-0.5,[1 1 30]),[1600,700,1]);
            pattern = sqrt((abs(x)-555).^2 + (abs(y)-280).^2 + z.^2)<=30;
            pattern( (sqrt((abs(x)-555).^2 + z.^2)<=30) & abs(y)<=280) = true;
            pattern( (sqrt((abs(y)-280).^2 + z.^2)<=30) & abs(x)<=555) = true;
            pattern( abs(x)<=555 & abs(y)<=280 ) = true;
            cutout(:,:,51:80) = pattern;
            volume(cutout) = false;

            % Rods in x direction
            [z,y] = meshgrid(0.5:349.5,-349.5:349.5);
            pattern = (sqrt((z-120).^2 + (y+330).^2)<=6);
            pattern = pattern | (sqrt((z-280).^2 + (y+330).^2)<=6);
            pattern = pattern | flipud(pattern);
            pattern = repmat(reshape(pattern,[1,700,350]),[1600,1,1]);
            pattern(476:1125,:,:) = false;
            volume(pattern) = false;

            % Rods in y direction
            [z,x] = meshgrid(0.5:349.5,1599.5:-1:0.5);
            pattern = (sqrt((z-25).^2 + (x-255).^2)<=6);
            pattern = pattern | (sqrt((z-25).^2 + (x-405).^2)<=6);
            pattern = pattern | (sqrt((z-25).^2 + (x-555).^2)<=6);
            pattern = pattern | (sqrt((z-25).^2 + (x-705).^2)<=6);
            pattern = pattern | (sqrt((z-25).^2 + (x-905).^2)<=6);
            pattern = pattern | (sqrt((z-25).^2 + (x-1005).^2)<=6);
            pattern = repmat(reshape(pattern,[1600,1,350]),[1,700,1]);
            pattern(:,1:400,:) = false;
            volume(pattern) = false;
        case 'rat'
            error('Rat holder is not defined yet!');
            %fprintf('Creating rat holder model...');
        otherwise
            error('Unknown model ''%s''!',lower(type));
    end

    % flip z and make it scanner like.
    volume(:,:,1:end) = volume(:,:,end:-1:1);
    volume = permute(volume,[2,3,1]);
    fprintf('\b\b\b: finished.\n');
    if writeFile
        createImageFile;
    end
    
    function createImageFile
        [fileName,pathName] = uiputfile({'*.img'},'Save model as','FraunhoferModel.ct.img');
        fprintf('Writing volume to ''%s'' as Inveon CT image file...',fileName);
        fileName2 = fullfile(pathName,fileName);
        fID = fopen(fileName2,'w+');
        volume = padarray(volume,[0 100 0],0,'pre');
        fwrite(fID,uint8(volume),'uint8');
        fclose(fID);
        headerInfo = headerReader('defaultCT.img.hdr');
        headerInfo.General.file_name = fileName2;
        headerInfo.General.x_dimension = size(volume,1); 
        headerInfo.General.y_dimension = size(volume,2);
        headerInfo.General.z_dimension = size(volume,3);
        headerInfo.General.pixel_size_x = 0.1;
        headerInfo.General.pixel_size_y = 0.1;
        headerInfo.General.pixel_size_z = 0.1;
        headerInfo.General.study_identifier = dicomuid;
        headerInfo.General.subject_orientation = 4;
        headerInfo.General.data_type = 1; % 8 bit data.
        headerWriter(headerInfo,[fileName2,'.hdr']);
        fprintf('\b\b\b: finished with Inveon File.\n');
        writeDicom(pathName,fileName);
    end

    function writeDicom(pathName,fileName)
        pathName = fullfile(pathName,'DICOM');
        mkdir(pathName);
        fprintf('Writing volume as DICOM in ''%s'': ....',pathName);
        mfolder = fileparts(mfilename('fullpath')); 
        HDR = dicominfo(fullfile(mfolder,'data','TemplateCTDicom.dcm'));
        [X,Y,Z] = size(volume);
        HDR.Width = X;   HDR.Height = Y;
        HDR.Columns = X; HDR.Rows = Y;
        HDR.NumberOfSeriesRelatedInstances = Z;
        HDR.ImageOrientationPatient = [1;0;0;0;1;0];
        HDR.PatientPosition = 'HFP';
        HDR.RescaleIntercept = 0; HDR.RescaleSlope = 1;
        HDR.BitDepth = 8;
        HDR.HighBit  = 7;
        for jj = 1:Z
            tempimg = flipud(uint8(volume(:,:,jj)'));
            temphdr = HDR;
            temphdr.AcquisitionNumber = Z-jj+1;
            temphdr.InstanceNumber = Z-jj+1;
            temphdr.ImagePositionPatient = [-X/10/2+0.05; 0.05; ((jj-1)-(Z/2))/10+0.05];
            dicomwrite(tempimg,fullfile(pathName,sprintf('%s_%05.0f.dcm',fileName(1:end-4),jj)),temphdr);
            fprintf('\b\b\b\b%3.0f%%',jj/Z*100);
        end
        fprintf('\b\b\b\bDone.\n');
    end

end
