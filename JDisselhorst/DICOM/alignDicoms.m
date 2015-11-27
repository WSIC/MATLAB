function [alignedTarget, transMatrix] = alignDicoms(sourceImg, targetImg, sourceHdr, targetHdr, interp, fill)
% ALIGNDICOMS Aligns dicom datasets, gives image and transformation matrix.
%
% WARNING: This code has not been tested extensively.
% Use the results cautiously!
%
% Note: Matlab does not seem to interpolate correctly when matrices are
% reduced in size. E.g., [1 3 8] magnified by (1/3) returns 3 instead of 4.
% Even when interpolation is set to cubic or linear.
%
% Input:
%  o sourceImg: source dataset (This is the reference)
%  o targetImg: target dataset (This one will be transformed)
%  o sourceHdr: dicom headers of the source images.
%               it can be a cell array with all headers or only the header
%               of the first slice. A cell array is better.
%  o targetHdr: dicom headers of the target images. 
%               it can be a cell array with all headers or only the header
%               of the first slice. A cell array is better.
%  o interp:    type of interpolation ('cubic','nearest','linear')
%               [optional. default: cubic]
%               Note: different types of interpolation can be performed in
%               different directions (e.g., in plane cubic, between plane
%               nearest, use: "{'cubic', 'cubic', 'nearest'}")
%  o fill:      the fill value. [optional. default: 0];
%
% Output:
%  o alignedTarget: the target dataset aligned to the source
%                   (the data will also have the same dimensions)
%  o transMatrix:   the transformation matrix that has been used.
%
% See also TFORMARRAY, MAKERESAMPLER,
% 
% Jonathan A. Disselhorst, Werner Siemens Imaging Center
% Version 2013.01.11
% Includes code by Alper Yaman, Matlab file exchange ID: <a href = "http://www.mathworks.com/matlabcentral/fileexchange/24277-transform-matrix-between-two-dicom-image-coordinates">#24277</a>. 
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');


%% Test the input parameters.
    if nargin<4                                 % Both datasets should be complete
        help alignDicoms
        error('Not enough input arguments!');   % Error.
    elseif nargin==4                            
        interp = 'cubic';   
        fill = 0;
    elseif nargin==5    
        fill = 0;
    end

    sourceDim = ndims(sourceImg);               % Number of dimension of the source
    targetDim = ndims(targetImg);               % Number of dimension of the target
    sourceIs2D = 0;
    if sourceDim == 2                           % special case: 2D source.
        sourceImg = repmat(sourceImg,[1,1,2]);  % Make it 3D temporarily
        sourceDim = 3; sourceIs2D = 1;
    elseif sourceDim > 3                        % The source is >3D:
        sourceImg = sourceImg(:,:,:,1);         % Use only the first 3 dimensions.
        sourceDim = 3;
    end
    if targetDim > 4                            % The target is >4D:
        error('Unsupported dimensions of the target!'); 
    elseif targetDim == 4                       % The target is 4D
        fprintf('The target has 4 dimensions. Assuming X*Y*Z*T. \n');
        numFrames = size(targetImg,4);          % The number of frames.
    else
        numFrames = 1;                          % Default: one frame.
    end
    if iscell(sourceHdr)                                        % If the header is given for every slice of the dataset, it should be a cell array
        L = size(sourceHdr,1);                                  % The number of headers.
        if L~=size(sourceImg,3)                                 % Should match the number of slices.
            error('Number of headers should match the number of slices');
        elseif L==1                                             % There is only one slice
            sourceHdr = sourceHdr{1};                           % it should not be a cell.
        else
            iop = sourceHdr{1}.ImageOrientationPatient;
            r=iop(1:3); c=iop(4:6); s=cross(r,c);               % Orientation according to the orientation tag,
            t = (sourceHdr{2}.ImagePositionPatient - ...        % Orientation according to the image position ...
                 sourceHdr{1}.ImagePositionPatient);            % ... of two adjacent slices.
            if ~all(sign(s)==sign(t))                           % If the sign of both orientations does not match, the dataset is probably 'upside down'
                sourceHdr = sourceHdr(end:-1:1);                % Turn headers around
                sourceImg = sourceImg(:,:,end:-1:1);            % turn images around
            end
            sourceHdr = sourceHdr{1};                           % Use the header of the first slide.
            sourceHdr.SpacingBetweenSlices = sqrt(sum(t.^2));   % SliceThickness is sometimes incorrect, so use the distance between slice one and two.
            try if abs(sourceHdr.SliceThickness - sourceHdr.SpacingBetweenSlices)>0.001
                warning('Source image: Slice Thickness and Spacing Between Slices do not match (%1.4f vs. %1.4f mm). Consider aligning slice by slice.',sourceHdr.SliceThickness,sourceHdr.SpacingBetweenSlices)
            end; end
        end
    end
    if iscell(targetHdr)                                        % If the header is given for every slice of the dataset, it should be a cell array
        L = size(targetHdr,1);                                  % The number of headers.
        if L~=size(targetImg,3)                                 % Should match the number of slices.
            error('Number of headers should match the number of slices');
        elseif L==1                                             % There is only one slice
            targetHdr = targetHdr{1};                           % it should not be a cell.
        else
            iop = targetHdr{1}.ImageOrientationPatient;
            r=iop(1:3); c=iop(4:6); s=cross(r,c);               % Orientation according to the orientation tag,
            t = (targetHdr{2}.ImagePositionPatient - ...        % Orientation according to the image position ...
                 targetHdr{1}.ImagePositionPatient);            % ... of two adjacent slices.
            if ~all(sign(s)==sign(t))                           % If the sign of both orientations does not match, the dataset is probably 'upside down'
                targetHdr = targetHdr(end:-1:1);                % Turn headers around
                targetImg = targetImg(:,:,end:-1:1);            % turn images around
            end
            targetHdr = targetHdr{1};                           % Use the header of the first slide.
            targetHdr.SpacingBetweenSlices = sqrt(sum(t.^2));   % SliceThickness is sometimes incorrect, so use the distance between slice one and two.
            try if abs(targetHdr.SliceThickness - targetHdr.SpacingBetweenSlices)>0.001
                warning('Target image: Slice Thickness and Spacing Between Slices do not match (%1.4f vs. %1.4f mm). Consider aligning slice by slice.',targetHdr.SliceThickness,targetHdr.SpacingBetweenSlices)
            end; end
        end
    end

%% Do these two datasets share the frame of reference?
    if ~strcmp(sourceHdr.FrameOfReferenceUID,targetHdr.FrameOfReferenceUID)
        fprintf('The two datasets do not have the same frame of reference!\n');
        FORcheck = input('Continue anyway? Y/[N] ','s');
        if isempty(FORcheck) || strcmpi(FORcheck,'n')
            alignedTarget = []; transMatrix = [];
            return
        end
    end

%% Initialize the transformation
    transMatrix   = GetTransformMatrix(targetHdr, sourceHdr, ...    % \
                                       targetDim, sourceDim);       %  - Obtain a transformation matrix
    T             = maketform('affine',transMatrix');               % Create a multidimensional spatial transformation structure
    R             = makeresampler(interp,'fill');                   % Create a resampler
    TDIMS_A       = 1:sourceDim;                                    % Use the dimensions of the source
    TDIMS_B       = 1:sourceDim;                                    % Also use the source
    TSIZE_B       = size(sourceImg);                                % Use the size of the source for the output image
    TMAP_B        = [];                                             % Point locations in output space; not defined.
    F             = fill;                                           % Fill empty outputspace
    alignedTarget = zeros([size(sourceImg), numFrames]);            % Preallocate output image

%% Perform the transformation(s)
    for frameNum  = 1:numFrames                                     % Loop over the frames of the target.
        alignedTarget(:,:,:,frameNum) = ...                         % \
             tformarray(targetImg(:,:,:,frameNum), T, R,...         %  } Apply the transformation
                        TDIMS_A, TDIMS_B, TSIZE_B, TMAP_B, F);      % /
    end
    if sourceIs2D                                                   % The special case with 2D source
        alignedTarget = alignedTarget(:,:,1,:);                     % Undo temporary increase to 3D.
    end
end

function M = GetTransformMatrix(info1, info2, ND1, ND2)
    M1 = TransMatrix(info1,ND1);    % Transformation matrix for the target to the origin.
    M2 = TransMatrix(info2,ND2);    % Transformation matrix for the source to the origin.
    M = M2\M1;                      % Transformation matrix for the target to the source.
end

function M = TransMatrix(info,ND)
    ipp = info.ImagePositionPatient;          % The position of (the center of) the first voxel
    iop = info.ImageOrientationPatient;       % The orientation of the image [row direction cos, column direction cos]
    ST  = info.SliceThickness;                % Use the slice thickness
    if ND==3                                  % Unless this is a 3D dataset
        try                                   % try to use 
            ST = info.SpacingBetweenSlices;   % spacing between slices 
        end                                   % (it does not always exist)
    end
    ps=[info.PixelSpacing; ST];               % The size of the voxel in three directions.

    r=iop(1:3);                               % Direction of the row
    c=iop(4:6);                               % ... the column
    s=cross(r,c);                             % ... and slice.

    ipp = ipp - r*ps(1) - c*ps(2) - s*ps(3);  % This is important when pixeldimensions are not equal.

    Tipp = [1,     0,     0,     ipp(1); ...  % Transformation
            0,     1,     0,     ipp(2); ...
            0,     0,     1,     ipp(3); ...
            0,     0,     0,     1];
    R    = [r(1),  c(1),  s(1),  0; ...       % Rotation
            r(2),  c(2),  s(2),  0; ...
            r(3),  c(3),  s(3),  0; ...
            0,     0,     0,     1];
    S    = [ps(1), 0,     0,     0; ...       % Scaling
            0,     ps(2), 0,     0; ...
            0,     0,     ps(3), 0; ...
            0,     0,     0,     1];
    T0   = [0,     1,     0,     0; ...       % Standard location. For some reason ...
            1,     0,     0,     0; ...       % ... the x and y should be flipped.
            0,     0,     1,     0; ...       % see also http://nipy.sourceforge.net/nibabel/dicom/dicom_orientation.html
            0,     0,     0,     1];
    M = Tipp * R * S * T0;                    % Combination of the above -> final transformation matrix.
end