%% loadDicomRTstruct Read the contents of a Radiotherapy Structure Set
% Usage: 
% [binaryImage, ROINames, dicomHeader, origImage, origHeader, ...
%           posMatrix] = loadDicomRTstruct(dicomFile, imgDir);
%
% Input: 
%        o dicomFile:   The full path to a dicomfile containing a RTStruct
%        o imgDir:      Folder with associated image DICOM-data [optional]
%                       This should be the volume used to draw the ROI, 
%                       this function does not check for correctness.
%
% Output: 
%        o binaryImage: the binary image (or volume) of the ROI. 
%                       if 'imgDir' is given, the binary image will be the
%                       same size as the original volume, otherwise binary
%                       image will be the size of the ROI.
%        o ROINames:    the names of the ROIs within the structure.
%        o dicomHeader: the complete dicom header of the file
%        o origImage:   the volume that was used to define the region on.
%                       only given when 'imgDir' is given.
%        o origHeader:  the dicom headers of said volume.
%        o posMatrix:   the start and end position of the ROI matrix.
%
% J.A. Disselhorst. [Radboud University Nijmegen Medical Centre - 2011]
%                   [Werner Siemens Imaging Center, Tuebingen   - 2013]
% version 2013.06.12.

function [binaryImage, ROINames, DCInfo, origImage, origHeader, posMatrix] = loadDicomRTstruct(dicomFile,imgDir)
    fprintf('Loading file %s\n',dicomFile);
    DCInfo = dicominfo(dicomFile);
    if ~strcmp(DCInfo.Modality,'RTSTRUCT')
        warning('This is not a DICOM RT structure; Aborting.');
        binaryImage = []; ROINames = []; origImage = []; origHeader = []; posMatrix = [];
        return;
    end
    iD = 0;
    if nargin>=2 && ~isempty(imgDir)
        [IMG,origHeader] = loadDicom(imgDir);
        origImage = IMG(:,:,:,1); origHeader = origHeader(:,1);
        [XXX,YYY,ZZZ] = createPositionMatrix(origHeader);
        iop = origHeader{1}.ImageOrientationPatient;
        if any(iop<0.9999 & iop>0.0001)
            warning('Field of view is tilted, cannot use the image data');
        else
            iD = 1;
        end
        if ~strcmpi(DCInfo.StudyInstanceUID,origHeader{1}.StudyInstanceUID)
            warning('Image data and ROI structure are not from the same study, cannot use the image data!')
            iD = 0;
        end
    else
        origImage = [];
        origHeader = [];
    end
    try
        sizes = DCInfo.Private_007d_1002; %if abs(diff(sizes(1:2)))>0.001, error('in plane pixel sizes do not match'); end
        pixelSize = sizes(1:2); sliceSep = sizes(3);
    catch %#ok<CTCH>
        error('Unknown voxel size.');
        %pixelSize = input('Pixel size (mm): ');
        %sliceSep = input('Slice separation (mm): ');
    end
    numberROIs = length(fieldnames(DCInfo.StructureSetROISequence));
    fprintf('%1.0f different ROIs found.\n',numberROIs);
    ROINames = cell(1,numberROIs);
    ROInoContours = zeros(1,numberROIs);
    ROInoDataPoints = zeros(1,numberROIs);

    minimaC = [Inf Inf Inf];
    maximaC = [-Inf -Inf -Inf];
    fprintf('Determining matrix size...\n');
    for ROINum = 1:numberROIs
        fieldName = sprintf('Item_%1.0f',ROINum);
        ROIName   = getfield(DCInfo.StructureSetROISequence,fieldName,'ROIName');
        ROINames(ROINum) = {ROIName};
        
        contours    = getfield(DCInfo.ROIContourSequence,fieldName,'ContourSequence');
        numContours = length(fieldnames(contours));
        ROInoContours(ROINum) = numContours;
        maxDataPoints = 0;
        for o = 1:numContours
            fieldName2    = sprintf('Item_%1.0f',o);
            contourData   = getfield(DCInfo.ROIContourSequence,fieldName,'ContourSequence',fieldName2,'ContourData');
            minXValue = min(min(min(contourData(1:3:end,:,:))));
            minYValue = min(min(min(contourData(2:3:end,:,:))));
            minZValue = min(min(min(contourData(3:3:end,:,:))));
            maxXValue = max(max(max(contourData(1:3:end,:,:))));
            maxYValue = max(max(max(contourData(2:3:end,:,:))));
            maxZValue = max(max(max(contourData(3:3:end,:,:))));
            minimaC   = min([[minXValue, minYValue, minZValue]; minimaC]);
            maximaC   = max([[maxXValue, maxYValue, maxZValue]; maximaC]);
            numDataPoints = getfield(DCInfo.ROIContourSequence,fieldName,'ContourSequence',fieldName2,'NumberOfContourPoints');
            maxDataPoints = max([numDataPoints maxDataPoints]);
            minXValue = minimaC(1); minYValue = minimaC(2); minZValue = minimaC(3);
            maxXValue = maximaC(1); maxYValue = maximaC(2); maxZValue = maximaC(3);
        end
        ROInoDataPoints(ROINum) = maxDataPoints;
    end
    
    fprintf('Building matrix...\n');
    msize     = double(round([diff([minXValue maxXValue]); diff([minYValue maxYValue])]./pixelSize));
    zsize     = double(round(diff([minZValue maxZValue])./sliceSep)+1);
    binaryImage = false(msize(1),msize(2),zsize,numberROIs);
    for ROINum = 1:numberROIs
        fieldName = sprintf('Item_%1.0f',ROINum);
        numContours = ROInoContours(ROINum);
        maxDataPoints = ROInoDataPoints(ROINum);        
        contourData = zeros(maxDataPoints*3,numContours)./0;
        for o = 1:numContours
            fieldName2           = sprintf('Item_%1.0f',o);
            tempContourData      = getfield(DCInfo.ROIContourSequence,fieldName,'ContourSequence',fieldName2,'ContourData');
            l                    = length(tempContourData);
            contourData(1:l,o)   = tempContourData;
        end

        zValues = unique(contourData(3:3:end,:,:)); zValues = zValues(~isnan(zValues));
        emptyIMG  = false(msize(1),msize(2));
        for j=1:length(zValues)
            slices = find(contourData(3,:)==zValues(j));
            IMG    = emptyIMG;
            for p = 1:length(slices);
                XData = contourData(1:3:end,slices(p));
                XData = XData(~isnan(XData));
                YData = contourData(2:3:end,slices(p));
                YData = YData(~isnan(YData));
                XData = double(round((XData-minXValue)./pixelSize(1))+0.5);
                YData = double(round((YData-minYValue)./pixelSize(2))+0.5);
                BW    = poly2mask(YData,XData,msize(1),msize(2));
                IMG   = xor(IMG,BW);
            end
            binaryImage(:,:,round((zValues(j)-minZValue)/sliceSep)+1, ROINum)=IMG;
        end
    end
    
    if nargout>=6
        posMatrix = [minXValue maxXValue; ...
                     minYValue maxYValue; ...
                     minZValue maxZValue];
%         posMatrix = zeros(msize(1),msize(2),zsize,3);
%         [a,b,c] = meshgrid(minYValue+(pixelSize(2)/2):pixelSize(2):maxYValue-(pixelSize(2)/2),...
%             minXValue+(pixelSize(1)/2):pixelSize(1):maxXValue-(pixelSize(1)/2), ...
%             minZValue:sliceSep:maxZValue);
%         posMatrix(:,:,:,1) = a; posMatrix(:,:,:,2) = b; posMatrix(:,:,:,3) = c;
    end
    
    if iD
        ROIS = false(size(XXX)); ROIS = repmat(ROIS,[1 1 1 numberROIs]);
        for ROINum = 1:numberROIs
            a = (abs(XXX - (minXValue+pixelSize(1)/2))); [~,a] = min(a(:));
            [x(1,1),x(1,2),x(1,3)] = ind2sub(size(XXX),a);
            a = (abs(XXX - (maxXValue-pixelSize(1)/2))); [~,a] = min(a(:));
            [x(2,1),x(2,2),x(2,3)] = ind2sub(size(XXX),a);
            [a,X] = max(max(x)); if a==1, X=0; end

            a = (abs(YYY - (minYValue+pixelSize(2)/2))); [~,a] = min(a(:));
            [y(1,1),y(1,2),y(1,3)] = ind2sub(size(YYY),a);
            a = (abs(YYY - (maxYValue-pixelSize(2)/2))); [~,a] = min(a(:));
            [y(2,1),y(2,2),y(2,3)] = ind2sub(size(YYY),a);
            [a,Y] = max(max(y)); if a==1, Y=0; end

            a = (abs(ZZZ - (minZValue))); [~,a] = min(a(:));
            [z(1,1),z(1,2),z(1,3)] = ind2sub(size(ZZZ),a);
            a = (abs(ZZZ - (maxZValue))); [~,a] = min(a(:));
            [z(2,1),z(2,2),z(2,3)] = ind2sub(size(ZZZ),a);
            [a,Z] = max(max(z)); if a==1, Z=0; end

            shift = [X,Y,Z];
            iets = setdiff([0 1 2 3],shift); if iets, shift(~shift) = iets; end
            binaryTemp = ipermute(binaryImage(:,:,:,ROINum),shift(:));
            pos = zeros(2,3);
            pos(:,shift(1)) = x(:,shift(1));
            pos(:,shift(2)) = y(:,shift(2));
            pos(:,shift(3)) = z(:,shift(3));
            
            xpos = pos(:,1); if xpos(1)~=xpos(2), xpos = [xpos(1):xpos(2),xpos(1):-1:xpos(2)]; else xpos = xpos(1); end
            ypos = pos(:,2); if ypos(1)~=ypos(2), ypos = [ypos(1):ypos(2),ypos(1):-1:ypos(2)]; else ypos = ypos(1); end
            zpos = pos(:,3); if zpos(1)~=zpos(2), zpos = [zpos(1):zpos(2),zpos(1):-1:zpos(2)]; else zpos = zpos(1); end
            ROIS(xpos,ypos,zpos,ROINum) = binaryTemp;
        end
        binaryImage = ROIS;
    end
    
    fprintf('Finished.\n');
end