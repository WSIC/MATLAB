%% This script does not actually work (yet).
%% Tumor
clear all;
[aimg, ahdr] = loadDicom('L:\DATA\2012-IVIMASL\Mouse15\Anatomy_in-vivo');
[bimg, bhdr] = loadDicom('L:\DATA\2012-IVIMASL\Mouse15\Haste');
bimg = bimg(:,:,:,1); bhdr = bhdr(:,1);
%% Brain
clear all
[aimg, ahdr] = loadDicom('L:\DATA\2013-StrokeRienso\Mouse12\Anatomy');
[bimg, bhdr] = loadDicom('L:\DATA\2013-StrokeRienso\Mouse12\Haste');
bimg = bimg(:,:,:,1); bhdr = bhdr(:,1);

%% Create the position matrix for a dicomvolume using their headers.
[X,Y,Z] = createPositionMatrix(ahdr);
distanceFromCenter = sqrt(X.^2 + Y.^2 + Z.^2);

%% Shim...
% See also: http://www.nmr.mgh.harvard.edu/~greve/dicom-unpack
%
HDRs = bhdr;
PatientPosition = HDRs{1}.PatientPosition;
if ~strcmpi(PatientPosition,'HFS')
    error('Scan not HFS (Head-First, Supine), but %s...',PatientPosition)
    % HFS:
    % X: increases from subject left to right, Sag
    % Y: increases from anterior to posterior, Cor
    % Z: increases from inferior to superior,  Tra
end
[~,~,Phoenix] = parseSiemensCSAHeader(HDRs{1});
ShimCenter = Phoenix.sAdjData.sAdjVolume.sPosition;
ShimCenter = [ShimCenter.dSag, ShimCenter.dCor, ShimCenter.dTra];
ShimSize = Phoenix.sAdjData.sAdjVolume.dThickness;
temp = Phoenix.sAdjData.sAdjVolume.sNormal;
try ShimRot(1) = temp.dSag; catch, ShimRot(1) = 0; end %#ok<CTCH>
try ShimRot(2) = temp.dCor; catch, ShimRot(2) = 0; end %#ok<CTCH>
try ShimRot(3) = temp.dTra; catch, ShimRot(3) = 0; end %#ok<CTCH>

PED = HDRs{1}.InPlanePhaseEncodingDirection;  % Either 'ROW' or 'COL
if strcmpi(PED,'COL')
    ShimSize = [Phoenix.sAdjData.sAdjVolume.dPhaseFOV,Phoenix.sAdjData.sAdjVolume.dReadoutFOV,ShimSize];
elseif strcmpi(PED,'ROW')
    ShimSize = [Phoenix.sAdjData.sAdjVolume.dReadoutFOV,Phoenix.sAdjData.sAdjVolume.dPhaseFOV,ShimSize];
end

ShimSize
ShimRot
ShimCenter
%% Create a 1 voxel 'dicom'
SHIMVOL = 1;
% vector from center to 
SHIMHDR = struct(...
    'ImageOrientationPatient',[1 0 0 0 0 1],...
    'ImagePositionPatient',   ShimCenter,...
    'SliceThickness',         ShimSize(3),...
    'PixelSpacing',           ShimSize(1:2)',...
    'FrameOfReferenceUID',    HDRs{1}.FrameOfReferenceUID);

SHIMALIGNED = alignDicoms(aimg,SHIMVOL,ahdr,SHIMHDR,'Nearest');
overlayVolume(aimg,SHIMALIGNED);






%%
 O = [1 2 3]; % order
% O = [1 3 2]; % order -
% O = [2 1 3]; % order
% O = [2 3 1]; % order
% O = [3 2 1]; % order
% O = [3 1 2]; % order


ShimArea = sqrt((X-ShimCenter(O(1))).^2 + (Y-ShimCenter(O(2))).^2 + (Z-ShimCenter(O(3))).^2);
[~,IX] = min(ShimArea(:)); %ShimArea = zeros(size(ShimArea)); 

%ShimArea( X>=(ShimCenter(O(1))-ShimSize(O(1))/2) & X<=(ShimCenter(O(1))+ShimSize(O(1))/2) & ...
%          Y>=(ShimCenter(O(2))-ShimSize(O(2))/2) & Y<=(ShimCenter(O(2))+ShimSize(O(2))/2) & ...
%          Z>=(ShimCenter(O(3))-ShimSize(O(3))/2) & Z<=(ShimCenter(O(3))+ShimSize(O(3))/2) ) = 1;
      
ShimArea(IX) = 1;

%overlayVolume(alignDicoms(aimg,bimg,ahdr,bhdr,'nearest'),ShimArea,'backRange',[0 300])
temp = alignDicoms(aimg,bimg,ahdr,bhdr,'nearest');
temp = double(temp>0)*0.5 + 1; 
close all
overlayVolume(aimg.*temp,ShimArea,'overMap',[1 0 0; repmat([0 0 0; .8 .3 0],5,1)])






%%
% Let op, dit is allemaal onder de aanname dat de slices NIET schuin zijn.
[~,~,Phoenix] = parseSiemensCSAHeader(bhdr{1});
ShimCenter = Phoenix.sAdjData.sAdjVolume.sPosition;
ShimCenter = [ShimCenter.dSag, ShimCenter.dCor, ShimCenter.dTra];  % Does the order depend on the head first/feet first, supine / prone, etc?
ShimSize = Phoenix.sAdjData.sAdjVolume.dThickness;
ShimRot = Phoenix.sAdjData.sAdjVolume.sNormal;

FOVCenter = Phoenix.sSliceArray.asSlice{1}.sPosition;
FOVCenter = [FOVCenter.dSag, FOVCenter.dCor, FOVCenter.dTra];  % Does the order depend on the head first/feet first, supine / prone, etc?
FOVCenter2 = Phoenix.sSliceArray.asSlice{end}.sPosition;
FOVCenter2 = [FOVCenter2.dSag, FOVCenter2.dCor, FOVCenter2.dTra];  % Does the order depend on the head first/feet first, supine / prone, etc?
N = length(Phoenix.sSliceArray.asSlice);
FOVSize = abs(FOVCenter2(3) - FOVCenter(3)) + Phoenix.sSliceArray.asSlice{1}.dThickness;

FOVRot = Phoenix.sSliceArray.asSlice{1}.sNormal;

firstPix = bhdr{1}.ImagePositionPatient';
PED = bhdr{1}.InPlanePhaseEncodingDirection;  % Either 'ROW' or 'COL
if strcmpi(PED,'COL')
    ShimSize = [Phoenix.sAdjData.sAdjVolume.dPhaseFOV,Phoenix.sAdjData.sAdjVolume.dReadoutFOV,ShimSize];
    FOVSize  = [Phoenix.sSliceArray.asSlice{1}.dPhaseFOV, Phoenix.sSliceArray.asSlice{1}.dReadoutFOV, FOVSize];
    firstPix(1:2) = firstPix([2,1]);
elseif strcmpi(PED,'ROW')
    ShimSize = [Phoenix.sAdjData.sAdjVolume.dReadoutFOV,Phoenix.sAdjData.sAdjVolume.dPhaseFOV,ShimSize];
    FOVSize  = [Phoenix.sSliceArray.asSlice{1}.dReadoutFOV, Phoenix.sSliceArray.asSlice{1}.dPhaseFOV, FOVSize];
end

% position matrix:
pixelSize = FOVSize./size(bimg); pixelSize(3) = abs(FOVCenter2(3) - FOVCenter(3)) / (N-1);
FOVCenter = mean([FOVCenter; FOVCenter2]);
lastPix = bhdr{end}.ImagePositionPatient';
direction = ((FOVCenter - firstPix)>0)*2-1;  % 1 increase from firstPix to lastPix, -1 is decrease;
lastPix(1:2) = firstPix(1:2)+FOVSize(1:2).*direction(1:2)-pixelSize(1:2);
FOV = double([bhdr{1}.Rows; bhdr{1}.Columns]).*bhdr{1}.PixelSpacing;
FOV(3) = abs(firstPix(3)-lastPix(3))+bhdr{1}.SliceThickness;
fprintf('FOV size according to dicom:   %1.4f x %1.4f x %1.4f mm\n',FOV)
fprintf('FOV size according to phoenix: %1.4f x %1.4f x %1.4f mm\n',FOVSize)
[X,Y,Z] = meshgrid(firstPix(2):pixelSize(2):lastPix(2), ...
                   firstPix(1):pixelSize(1):lastPix(1), ...
                   firstPix(3):pixelSize(3):lastPix(3));
ShimArea = zeros(size(bimg));
a = [ShimCenter-ShimSize/2; ShimCenter+ShimSize/2;]; 
ShimArea(X>=a(1,1) & X<=a(2,1) & Y>=a(1,2) & Y<=a(2,2) & Z>=a(1,3) & Z<=a(2,3)) = 1;
ShimArea = reshape(ShimArea,size(bimg));


% shim area in the anatomy:
[~,~,Phoenix] = parseSiemensCSAHeader(ahdr{1});
FOVCenter = Phoenix.sSliceArray.asSlice{1}.sPosition;
FOVCenter = [FOVCenter.dSag, FOVCenter.dCor, FOVCenter.dTra];  % Does the order depend on the head first/feet first, supine / prone, etc?
FOVSize = Phoenix.sSliceArray.asSlice{1}.dThickness;

FOVRot = Phoenix.sSliceArray.asSlice{1}.sNormal;
firstPix = ahdr{1}.ImagePositionPatient';
PED = ahdr{1}.InPlanePhaseEncodingDirection;  % Either 'ROW' or 'COL
if strcmpi(PED,'COL')
    FOVSize  = [Phoenix.sSliceArray.asSlice{1}.dPhaseFOV, Phoenix.sSliceArray.asSlice{1}.dReadoutFOV, FOVSize];
    firstPix(1:2) = firstPix([2,1]);
elseif strcmpi(PED,'ROW')
    FOVSize  = [Phoenix.sSliceArray.asSlice{1}.dReadoutFOV, Phoenix.sSliceArray.asSlice{1}.dPhaseFOV, FOVSize];
end

pixelSize = FOVSize./size(aimg); pixelSize(3) = ahdr{1}.SliceThickness;
lastPix = ahdr{end}.ImagePositionPatient';
direction = ((FOVCenter - firstPix)>0)*2-1;  % 1 increase from firstPix to lastPix, -1 is decrease;
lastPix(1:2) = firstPix(1:2)+FOVSize(1:2).*direction(1:2)-pixelSize(1:2);
FOV = double([ahdr{1}.Rows; ahdr{1}.Columns]).*ahdr{1}.PixelSpacing;
FOV(3) = abs(firstPix(3)-lastPix(3))+ahdr{1}.SliceThickness;
fprintf('FOV size according to dicom:   %1.4f x %1.4f x %1.4f mm\n',FOV)
fprintf('FOV size according to phoenix: %1.4f x %1.4f x %1.4f mm\n',FOVSize)
[X,Y,Z] = meshgrid(firstPix(2):pixelSize(2):lastPix(2), ...
                   firstPix(1):pixelSize(1):lastPix(1), ...
                   firstPix(3):pixelSize(3):lastPix(3));

