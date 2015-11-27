%% imageQualityAnalysis, analyze a NEMA image quality phantom.
%
%   USAGE: 
%       imageQualityAnalysis(imageMatrix,xyDimension,zDimension,output, ...
%             LeftRight,xPosition,yPosition,zPosition,Rotation,scatRot, ...
%             timeFrame,outputMode)
%           Input arguments are optional.
%           imageMatrix:    image data (x,y,z,t); Doubles
%           xyDimension:    pixelsize xy
%           zDimension:     pixelsize z
%           output:         output filename for the results
%           LeftRight:      0/1, how the phantom is positioned
%           x/yPosition:    Position 
%           zPosition:       '  '
%           Rotation:       Rotation of the phantom
%           scatRot:        Additional rotation of the scatter volumes
%           timeFrame:      Time frame
%           outputMode:     save results immediately (1) or not (0)
%
% J.A. Disselhorst, 2009-2015. 
% Jonathan.Disselhorst@med.uni-tuebingen.de
% Radboud University Nijmegen Medical Centre
%       - Department of Nuclear Medicine. 
% Eberhard Karls University Tuebingen
%       - Werner Siemens Imaging Center
%
% Update 2015.11.20. Added size restrictions.


function imageQualityAnalysis(imageMatrix,xyDimension,zDimension,output,LeftRight,xPosition,yPosition,zPosition,Rotation,scatRot,timeFrame,NEMAStyle,outputMode)
if nargin==0
    imageMatrix = zeros(128,128,128);
    output = 'output.xlsx';
    LeftRight = 0;      % Left to right (1) or Right to left (0)
    xPosition = 0;      % Start position of the phantom in millimeter, x;
    yPosition = 0;      % Start position of the phantom in millimeter, y;
    zPosition = 0;      % Start position of the phantom in millimeter, z;
    Rotation = 0;       % Rotation in degree;
    scatRot = 0;
    xyDimension = 1;    % Pixel size x and y (mm)
    zDimension = 1;     % Pixel size z (mm)
    timeFrame = 1;
    NEMAstyle = 1;
    fprintf('Using Default input parameters\n');
    outputMode = 0;
elseif nargin==1
    output = 'output.xlsx';
    LeftRight = 0;      % Left to right (1) or Right to left (0)
    xPosition = 0;      % Start position of the phantom in millimeter, x;
    yPosition = 0;      % Start position of the phantom in millimeter, y;
    zPosition = 0;      % Start position of the phantom in millimeter, z;
    Rotation = 0;       % Rotation in degree;
    scatRot = 0;
    xyDimension = 1;    % Pixel size x and y (mm)
    zDimension = 1;     % Pixel size z (mm)
    timeFrame = 1;
    NEMAstyle = 1;
    fprintf('Using Default input parameters\n');
    outputMode = 0;
elseif nargin==3
    output = 'output.xlsx';
    LeftRight = 0;      % Left to right (1) or Right to left (0)
    xPosition = 0;      % Start position of the phantom in millimeter, x;
    yPosition = 0;      % Start position of the phantom in millimeter, y;
    zPosition = 0;      % Start position of the phantom in millimeter, z;
    Rotation = 0;       % Rotation in degree;
    scatRot = 0;
    timeFrame = 1;
    NEMAstyle = 1;
    fprintf('Using Default input parameters\n');
    outputMode = 0;
elseif nargin==4
    LeftRight = 0;      % Left to right (1) or Right to left (0)
    xPosition = 0;      % Start position of the phantom in millimeter, x;
    yPosition = 0;      % Start position of the phantom in millimeter, y;
    zPosition = 0;      % Start position of the phantom in millimeter, z;
    Rotation = 0;       % Rotation in degree;
    scatRot = 0;
    timeFrame = 1;
    NEMAstyle = 1;
    fprintf('Using Default input parameters\n');
    outputMode = 0;
elseif nargin==12
    outputMode = 0;
else
    error('invalid number of input arguments');
end
fprintf('JA Disselhorst\nVersion 2.1 (November 2015).\n');
xDIM = size(imageMatrix,1);
yDIM = size(imageMatrix,2);
zDIM = size(imageMatrix,3);

        % Definitions of NEMA Phantom
        Diameter = 30;      % diameter of the phantom (mm)
        Length = 50;        % length of the phantom (mm)
        regions = [8,25.5,41.75; 18,35.5,49.25];  % in millimeter
        NemaAngles = (0:4).*72; 
        NemaAngles2 = [0 180] + 16.5; 
        largeDiameter = 22.5;

SORVolume = [];
uniformVolume = [];
rodVolume = [];      
xCenter = [];
yCenter = [];
colors = [0 1 0; 0.8 0.6 0.1; 0 1 1];

%%
figure('Name','Image Quality','NumberTitle','off','Position',[100, 100, 1050,700],'MenuBar','none');
settings = uipanel('Title','Settings','Position',[0 .85 1 .15]);
images = uipanel('Title','Images','Position',[0 0 1 .85]);
% Edits --------------------------------------------------------------
xPosEdit = uicontrol('Parent',settings,'Style','edit','Units','normalized','String',num2str(xPosition),...
     'Position',[.1 2/3 .2 1/3],'HorizontalAlignment','left','Backgroundcolor','white','Callback',@analyze);
uicontrol('Parent',settings, 'Style','text','Units','normalized','String','X Position: ',...
        'Position', [0.05 2/3 .05 .25], 'HorizontalAlignment','right'); 
 
yPosEdit = uicontrol('Parent',settings,'Style','edit','Units','normalized','String',num2str(yPosition),...
     'Position',[.1 1/3 .2 1/3],'HorizontalAlignment','left','Backgroundcolor','white','Callback',@analyze);
uicontrol('Parent',settings, 'Style','text','Units','normalized','String','Y Position: ',...
        'Position', [0.05 1/3 .05 .25], 'HorizontalAlignment','right');
    
zPosEdit = uicontrol('Parent',settings,'Style','edit','Units','normalized','String',num2str(zPosition),...
     'Position',[.1 0 .2 1/3],'HorizontalAlignment','left','Backgroundcolor','white','Callback',@analyze);
uicontrol('Parent',settings, 'Style','text','Units','normalized','String','Z Position: ',...
        'Position', [0.05 0 .05 .25], 'HorizontalAlignment','right'); 
 
    
rotEdit = uicontrol('Parent',settings,'Style','edit','Units','normalized','String',num2str(Rotation),...
     'Position',[.4 2/3 .2 1/3],'HorizontalAlignment','left','Backgroundcolor','white','Callback',@analyze);
uicontrol('Parent',settings, 'Style','text','Units','normalized','String','Rotation: ',...
        'Position', [.3 2/3 .1 .25], 'HorizontalAlignment','right'); 
    
scatRotEdit = uicontrol('Parent',settings,'Style','edit','Units','normalized','String',num2str(scatRot),...
     'Position',[.4 1/3 .2 1/3],'HorizontalAlignment','left','Backgroundcolor','white','Callback',@analyze);
uicontrol('Parent',settings, 'Style','text','Units','normalized','String','Extra SOR rotation: ',...
        'Position', [.3 1/3 .1 .25], 'HorizontalAlignment','right'); 

timeEdit = uicontrol('Parent',settings,'Style','edit','Units','normalized','String',num2str(timeFrame),...
     'Position',[.4 0 .2 1/3],'HorizontalAlignment','left','Backgroundcolor','white','Callback',@analyze);
uicontrol('Parent',settings, 'Style','text','Units','normalized','String','Time Frame: ',...
        'Position', [.3 0 .1 .25], 'HorizontalAlignment','right');     
    
leftRightCheck = uicontrol('Parent',settings,'Style','checkBox','Units','normalized','String','Left-Right',...
     'Position',[.62 1/3 .2 1/3],'HorizontalAlignment','left','Callback',@analyze,'Value',LeftRight);

uicontrol('Parent',settings,'Style','pushbutton','Units','normalized','String','Save (Ctrl+S)', ...
    'Position',[.62 0 .1 1/3],'CallBack',@save);
uicontrol('Parent',settings,'Style','pushbutton','Units','normalized','String','Open Images', ...
    'Position',[.73 0 .1 1/3],'CallBack',@openimg);
NEMAstyle = uicontrol('Parent',settings,'Style','popupmenu','Units','normalized','String','Max. NEMA size|Min. NEMA size|Closest to NEMA', ...
    'Position',[.62 2/3 .1 1/3],'Callback',@analyze,'Value',NEMAstyle);

% MENU
filemenu = uimenu('Label','Image Quality Analysis');
    uimenu(filemenu,'Label','Open File','Callback',@openFile);
    uimenu(filemenu,'Label','Save Results','Callback',@save,'Accelerator','S');
    uimenu(filemenu,'Label','Save Results As','Callback',@saveAs);
    uimenu(filemenu,'Label','Quit','Callback','close','Separator','on','Accelerator','Q');

% Images
firstAxes = axes('Parent',images,'Units','normalized','Position',[0 0 1/3 .6]);
secondAxes = axes('Parent',images,'Units','normalized','Position',[1/3 0 1/3 .6]);
thirdAxes = axes('Parent',images,'Units','normalized','Position',[2/3 0 1/3 .6]);
top1Axes = axes('Parent',images,'Units','normalized','Position',[0 .6 .7 .4]);
infoField = uicontrol('Style','edit','Parent',images,'Units','normalized','Position',[.7 .6 .3 .4], ...
    'Min',0,'Max',2,'HorizontalAlignment','left','Backgroundcolor','white');
 %axes('Parent',images,'Units','normalized','Position',[.5 .6 .5 .4]);
Results = analyze;
if outputMode == 1
    writeExcel(Results);
    close
end

    function openFile(varargin)
        [FileName,PathName,FilterIndex] = uigetfile({'*.img.hdr','Image header files (*.img.hdr)'; ...
            '*.dcm','dicom files (*.dcm)';'*.nii','Nifti files (*.nii)'; '*.*','All files (*.*)'},'Select file');
        if FileName & FilterIndex==1
            % Inveon
            headerFile = fullfile(PathName,FileName);
            imageHeader = headerReader(headerFile);
            imageMatrix = buildMatrix(headerFile(1:end-4),imageHeader);
            xyDimension = imageHeader.General.pixel_size_x;
            zDimension  = imageHeader.General.pixel_size_z;
            if timeFrame > imageHeader.General.total_frames
                timeFrame = 1;
            end
            output = [headerFile '.xlsx'];
        elseif FileName & FilterIndex==2
            % Dicom
            [imageMatrix,hdr] = loadDicom(PathName);
            xyDimension = hdr{1}.PixelSpacing;  xyDimension = xyDimension(1);    % pixel size x, y
            zDimension  = hdr{1}.SliceThickness;    % Pixel Size z
            if timeFrame>size(imageMatrix,4)
                    timeFrame = 1;
            end
            output = [fullfile(PathName,FileName) '.xlsx'];
        elseif FileName & FilterIndex==3
            % Nifti
            niftiFile = fullfile(PathName,FileName);
            [imageHeader, filetype, fileprefix, machine] = load_nii_hdr(niftiFile);
            [imageMatrix,imageHeader] = load_nii_img(imageHeader,filetype,fileprefix,machine,[],[],[],[],0);
            imageMatrix = permute(double(imageMatrix),[2 1 3 4]);
            xyDimension = imageHeader.dime.pixdim(2);
            zDimension = imageHeader.dime.pixdim(4);
            if timeFrame>size(imageMatrix,4)
                    timeFrame = 1;
            end
            output = [niftiFile '.xlsx'];
        elseif FileName
            % Unknown. 
            try  %dicom?
                [imageMatrix,hdr] = loadDicom(PathName);
                xyDimension = hdr{1}.PixelSpacing;  xyDimension = xyDimension(1);    % pixel size x, y
                zDimension  = hdr{1}.SliceThickness;    % Pixel Size z
                if timeFrame>size(imageMatrix,4)
                    timeFrame = 1;
                end
                output = [fullfile(PathName,FileName) '.xlsx'];
            catch 
                try % inveon?
                    headerFile = fullfile(PathName,FileName);
                    imageHeader = headerReader(headerFile);
                    imageMatrix = buildMatrix(headerFile(1:end-4),imageHeader,0);
                    xyDimension = imageHeader.General.pixel_size_x;
                    zDimension  = imageHeader.General.pixel_size_z;
                    if timeFrame > imageHeader.General.total_frames
                        timeFrame = 1;
                    end
                    output = [headerFile '.xlsx'];
                catch
                    try
                        % Nifti
                        niftiFile = fullfile(PathName,FileName);
                        [imageHeader, filetype, fileprefix, machine] = load_nii_hdr(niftiFile);
                        [imageMatrix,imageHeader] = load_nii_img(imageHeader,filetype,fileprefix,machine,[],[],[],[],0);
                        imageMatrix = permute(double(imageMatrix),[2 1 3 4]);
                        xyDimension = imageHeader.dime.pixdim(2);
                        zDimension = imageHeader.dime.pixdim(4);
                        if timeFrame>size(imageMatrix,4)
                                timeFrame = 1;
                        end
                        output = [niftiFile '.xlsx'];
                    catch
                        fprintf('Unknown file format\n');
                    end
                end
            end
        end
        xDIM = size(imageMatrix,1);
        yDIM = size(imageMatrix,2);
        zDIM = size(imageMatrix,3);

        Results = analyze;
    end
    
    function save(varargin)
        Results = analyze;
        writeExcel(Results);
    end
    
    function openimg(varargin)
        x1 = floor((xCenter-Diameter/2)./xyDimension);
        x2 = ceil((xCenter+Diameter/2)./xyDimension);
        y1 = floor((yCenter-Diameter/2)./xyDimension);
        y2 = ceil((yCenter+Diameter/2)./xyDimension);
        figure; montage(permute(rodVolume(y1:y2,x1:x2,:),[1 2 4 3]),'DisplayRange',[]);
        figure; montage(permute(uniformVolume(y1:y2,x1:x2,:),[1 2 4 3]),'DisplayRange',[]);
        figure; montage(permute(SORVolume(y1:y2,x1:x2,:),[1 2 4 3]),'DisplayRange',[]);
    end

    function saveAs(varargin)
        [FileName,PathName,FilterIndex] = uiputfile({'*.xlsx';'*.xls';'*.*'},'Save output as',output);
        if FileName
            output = fullfile(PathName,FileName);
            Results = analyze;
            writeExcel(Results);
        end
    end

    function Results = analyze(varargin)
        set(get(settings,'Children'),'Enable','off');
        xPosition = str2double(get(xPosEdit,'String'));
        yPosition = str2double(get(yPosEdit,'String'));
        xCenter = (xDIM*xyDimension/2)+xPosition;
        yCenter = (yDIM*xyDimension/2)+yPosition;
        zPosition = str2double(get(zPosEdit,'String'));
        Rotation = str2double(get(rotEdit,'String'));
        SORRotation = str2double(get(scatRotEdit,'String'));
        timeFrame = round(str2double(get(timeEdit,'String')));
        if timeFrame>size(imageMatrix,4), timeFrame = size(imageMatrix,4); elseif timeFrame<1, timeFrame = 1; end
        set(timeEdit,'String',num2str(timeFrame)); 
        LeftRight = get(leftRightCheck,'Value');
        if LeftRight == 1;
            imageMatrix = flipdim(imageMatrix,3);
            imageMatrix = flipdim(imageMatrix,2);
            set(leftRightCheck,'Value',0)
        end
        angles = NemaAngles + Rotation;
        angles2 = NemaAngles2 + Rotation + SORRotation;
        select = get(NEMAstyle, 'Value'); % 1: smaller, 2: larger, 3: closest
        
        % 2015---------------------------------------------
        regctrs = mean(regions+zPosition);
        regsize = diff(regions+zPosition);
        sz = regsize/zDimension;
        sz = [floor(sz); ceil(sz)];
        [~,ix] = min(abs(sz*zDimension-repmat(regsize,[2,1])));
        sz(3,:) = [sz(ix(1),1), sz(ix(2),2), sz(ix(3),3)];
        odd = rem(sz,2);

        slices = zeros(2,3);
        for ii = 1:3
            ctrreal = regctrs(ii)/zDimension;
            ctr = round(ctrreal);
            num = sz(select,ii);
            if odd(select,ii) % odd number of slices
                slices(:,ii) = [ctr-((num-1)/2); ctr+((num-1)/2)];
            else % even number of slices
                if ctrreal<ctr
                    slices(:,ii) = [ctr-(num/2); ctr+((num/2)-1)];
                else
                    slices(:,ii) = [ctr-((num/2)-1); ctr+(num/2)];
                end
            end
        end 
        %--------------------------------------------------------
        
        % Make the images:
        SORVolume = squeeze(imageMatrix(:,:,slices(1,3):slices(2,3),timeFrame));
        SORImage  = mean(SORVolume,3);
        uniformVolume = squeeze(imageMatrix(:,:,slices(1,2):slices(2,2),timeFrame));
        uniformImage  = mean(uniformVolume,3);
        rodVolume = squeeze(imageMatrix(:,:,slices(1,1):slices(2,1),timeFrame));
        rodImage = mean(rodVolume,3);
        
        
        % Top graph --------------------------------------------------
        axes(top1Axes)
        imshow(squeeze(mean(imageMatrix(:,:,:,timeFrame))),'DisplayRange',[],'InitialMagnification','fit');
        %axis([zPosition./zDimension (zPosition+Length)./zDimension yPosition./xyDimension (yPosition+Diameter)./xyDimension])
        axis([0 Inf (xCenter-Diameter/2)./xyDimension (xCenter+Diameter/2)./xyDimension])
        hold on;
        for ii = 1:3
            plot([slices(1,ii)-0.5, slices(1,ii)-0.5],[(xCenter-Diameter/2)./xyDimension (xCenter+Diameter/2)./xyDimension],'Color',colors(ii,:));
            plot([slices(2,ii)+0.5, slices(2,ii)+0.5],[(xCenter-Diameter/2)./xyDimension (xCenter+Diameter/2)./xyDimension],'Color',colors(ii,:));
        end
        plot((zPosition-.5)./zDimension, xCenter/xyDimension, 'y+')
        hold off
        % RODS --------------------------------------------------------
        axes(firstAxes); 
        imshow(rodImage,'DisplayRange',[],'InitialMagnification','fit');
        axis([(xCenter-Diameter/2)./xyDimension (xCenter+Diameter/2)./xyDimension (yCenter-Diameter/2)./xyDimension (yCenter+Diameter/2)./xyDimension])
        hold on
        numslices = size(rodVolume,3); slicedist = numslices*zDimension;
        labeltext = sprintf(' RC: %1.0f slices / %1.2f mm',numslices,slicedist);
        text((xCenter-Diameter/2)/xyDimension,(yCenter-Diameter/2)/xyDimension,labeltext,'Color',colors(1,:),'VerticalAlignment','top');
        RC1mm  = circle([(7*sind(angles(1))+xCenter)/xyDimension (7*cosd(angles(1))+yCenter)/xyDimension], 2/xyDimension, 20, colors(1,:));
        RC2mm  = circle([(7*sind(angles(2))+xCenter)/xyDimension (7*cosd(angles(2))+yCenter)/xyDimension], 2.5/xyDimension, 20, colors(1,:));
        RC3mm  = circle([(7*sind(angles(3))+xCenter)/xyDimension (7*cosd(angles(3))+yCenter)/xyDimension], 3/xyDimension, 20, colors(1,:));
        RC4mm  = circle([(7*sind(angles(4))+xCenter)/xyDimension (7*cosd(angles(4))+yCenter)/xyDimension], 3.5/xyDimension, 20, colors(1,:));
        RC5mm  = circle([(7*sind(angles(5))+xCenter)/xyDimension (7*cosd(angles(5))+yCenter)/xyDimension], 4/xyDimension, 20, colors(1,:));
        hold off
        % SOR ---------------------------------------------------------
        axes(thirdAxes);
        imshow(SORImage,'DisplayRange',[],'InitialMagnification','fit');
        axis([(xCenter-Diameter/2)./xyDimension (xCenter+Diameter/2)./xyDimension (yCenter-Diameter/2)./xyDimension (yCenter+Diameter/2)./xyDimension])
        hold on
        numslices = size(SORVolume,3); slicedist = numslices*zDimension;
        labeltext = sprintf(' SOR: %1.0f slices / %1.2f mm',numslices,slicedist);
        text((xCenter-Diameter/2)/xyDimension,(yCenter-Diameter/2)/xyDimension,labeltext,'Color',colors(3,:),'VerticalAlignment','top');
        SORwat = (circle([(7.5*sind(angles2(1))+xCenter)/xyDimension (7.5*cosd(angles2(1))+yCenter)/xyDimension], 2/xyDimension, 15, colors(3,:)));
        text((7.5*sind(angles2(1))+xCenter+2.5)/xyDimension, (7.5*cosd(angles2(1))+yCenter)/xyDimension, 'Water','Color',colors(3,:));
        SORair = (circle([(7.5*sind(angles2(2))+xCenter)/xyDimension (7.5*cosd(angles2(2))+yCenter)/xyDimension], 2/xyDimension, 15, colors(3,:)));
        text((7.5*sind(angles2(2))+xCenter+2.5)/xyDimension, (7.5*cosd(angles2(2))+yCenter)/xyDimension, 'Air','Color',colors(3,:));
        hold off
        % UNIF ----------------------------------------------------------
        axes(secondAxes);  
        imshow(uniformImage,'DisplayRange',[],'InitialMagnification','fit');
        axis([(xCenter-Diameter/2)./xyDimension (xCenter+Diameter/2)./xyDimension (yCenter-Diameter/2)./xyDimension (yCenter+Diameter/2)./xyDimension])
        hold on
        numslices = size(uniformVolume,3); slicedist = numslices*zDimension;
        labeltext = sprintf(' Uniform: %1.0f slices / %1.2f mm',numslices,slicedist);
        text((xCenter-Diameter/2)/xyDimension,(yCenter-Diameter/2)/xyDimension,labeltext,'Color',colors(2,:),'VerticalAlignment','top');
        Unif   = (circle([(xCenter)./xyDimension yCenter./xyDimension], largeDiameter/xyDimension/2, 30, colors(2,:)));
        hold off
        % --------------------------------------------------------------
        
        % Uniformity -------------------------
        imageMask = poly2mask(Unif(1,:),Unif(2,:),xDIM,yDIM);
        volumeMask = repmat(imageMask,[1 1 size(uniformVolume,3)]);
        uniformMean = mean(uniformVolume(volumeMask));
        uniformMax  = max(uniformVolume(volumeMask));
        uniformMin  = min(uniformVolume(volumeMask));
        uniformSTD  = std(uniformVolume(volumeMask));
        Results.Uniformity_Mean = uniformMean;
        Results.Uniformity_Max = uniformMax;
        Results.Uniformity_Min = uniformMin;
        Results.Uniformity_PercentSTD = uniformSTD/uniformMean*100;
        
        % RC ------------------------------
        axes(firstAxes); hold on;
        imageMask = poly2mask(RC1mm(1,:),RC1mm(2,:),xDIM, yDIM);
        volumeMask = repmat(imageMask,[1 1 size(rodVolume,3)]);
        temp = imageMask.*rodImage; [max1,i] = max(temp(:)); [x1,y1,z] = ind2sub(size(rodVolume),i);
        temp = rodVolume.*volumeMask; profile = squeeze(temp(x1,y1,:)); 
        rod1Mean = mean(profile); rod1STD = std(profile); max1 = max(profile);
        plot(y1,x1,'ro');

        imageMask = poly2mask(RC2mm(1,:),RC2mm(2,:),xDIM, yDIM);
        volumeMask = repmat(imageMask,[1 1 size(rodVolume,3)]);
        temp = imageMask.*rodImage; [max2,i] = max(temp(:)); [x2,y2,z] = ind2sub(size(rodVolume),i);
        temp = rodVolume.*volumeMask; profile = squeeze(temp(x2,y2,:)); 
        rod2Mean = mean(profile); rod2STD = std(profile); max2 = max(profile);
        plot(y2,x2,'ro');

        imageMask = poly2mask(RC3mm(1,:),RC3mm(2,:),xDIM, yDIM);
        volumeMask = repmat(imageMask,[1 1 size(rodVolume,3)]);
        temp = imageMask.*rodImage; [max3,i] = max(temp(:)); [x3,y3,z] = ind2sub(size(rodVolume),i);
        temp = rodVolume.*volumeMask; profile = squeeze(temp(x3,y3,:)); 
        rod3Mean = mean(profile); rod3STD = std(profile); max3 = max(profile);
        plot(y3,x3,'ro');

        imageMask = poly2mask(RC4mm(1,:),RC4mm(2,:),xDIM, yDIM);
        volumeMask = repmat(imageMask,[1 1 size(rodVolume,3)]);
        temp = imageMask.*rodImage; [max4,i] = max(temp(:)); [x4,y4,z] = ind2sub(size(rodVolume),i);
        temp = rodVolume.*volumeMask; profile = squeeze(temp(x4,y4,:)); 
        rod4Mean = mean(profile); rod4STD = std(profile); max4 = max(profile);
        plot(y4,x4,'ro');
        
        imageMask = poly2mask(RC5mm(1,:),RC5mm(2,:),xDIM, yDIM);
        volumeMask = repmat(imageMask,[1 1 size(rodVolume,3)]);
        temp = imageMask.*rodImage; [max5,i] = max(temp(:)); [x5,y5,z] = ind2sub(size(rodVolume),i);
        temp = rodVolume.*volumeMask; profile = squeeze(temp(x5,y5,:)); 
        rod5Mean = mean(profile); rod5STD = std(profile); max5 = max(profile);
        plot(y5,x5,'ro');
        hold off
        
        background = uniformSTD/uniformMean;

        Results.Rod1_Mean = rod1Mean;
        Results.Rod1_Max = max1;
        Results.Rod1_RC = rod1Mean/uniformMean;
        Results.Rod1_PercentSTD = 100*sqrt((rod1STD/rod1Mean)^2 + background^2);
        Results.Rod1_x = x1; Results.Rod1_y = y1;
        Results.Rod2_Mean = rod2Mean;
        Results.Rod2_Max = max2;
        Results.Rod2_RC = rod2Mean/uniformMean;
        Results.Rod2_PercentSTD = 100*sqrt((rod2STD/rod2Mean)^2 + background^2);
        Results.Rod2_x = x2; Results.Rod2_y = y2;
        Results.Rod3_Mean = rod3Mean;
        Results.Rod3_Max = max3;
        Results.Rod3_RC = rod3Mean/uniformMean;
        Results.Rod3_PercentSTD = 100*sqrt((rod3STD/rod3Mean)^2 + background^2);
        Results.Rod3_x = x3; Results.Rod3_y = y3;
        Results.Rod4_Mean = rod4Mean;
        Results.Rod4_Max = max4;
        Results.Rod4_RC = rod4Mean/uniformMean;
        Results.Rod4_PercentSTD = 100*sqrt((rod4STD/rod4Mean)^2 + background^2);
        Results.Rod4_x = x4; Results.Rod4_y = y4;
        Results.Rod5_Mean = rod5Mean;
        Results.Rod5_Max = max5;
        Results.Rod5_RC = rod5Mean/uniformMean;
        Results.Rod5_PercentSTD = 100*sqrt((rod5STD/rod5Mean)^2 + background^2);
        Results.Rod5_x = x5; Results.Rod5_y = y5;
        
        % SOR ------------------------------
        imageMask = poly2mask(SORwat(1,:),SORwat(2,:),xDIM,yDIM);
        Water = repmat(imageMask,[1 1 size(SORVolume,3)]);
        waterMean = mean(SORVolume(Water));
        waterSTD = std(SORVolume(Water));
        waterSD = 100*(waterSTD/waterMean);
      
        imageMask = poly2mask(SORair(1,:),SORair(2,:),xDIM,yDIM);
        Air = repmat(imageMask,[1 1 size(SORVolume,3)]);
        airMean = mean(SORVolume(Air));
        airSTD = std(SORVolume(Air));
        airSD = 100*(airSTD/airMean);
        
        Results.Water_SOR = waterMean/uniformMean;
        Results.Water_PercentSTD = waterSD;
        Results.Air_SOR = airMean/uniformMean;
        Results.Air_PercentSTD = airSD;
        
        Results.matrixSize = size(imageMatrix,1);
        Results.pixelSizeXY = xyDimension;
        Results.pixelSizeZ = zDimension;
        Results.xPosition = xPosition;
        Results.yPosition = yPosition;
        Results.zPosition = zPosition;
        Results.Rotation = Rotation;
        Results.ExtraSORRotation = SORRotation;
        Results.timeFrame = timeFrame;
        nemastyles = {'At least NEMA dimensions','At most NEMA dimenions','Closest to NEMA dimensions'};
        Results.sizeStyle = nemastyles{select};        
        
        set(infoField,'String',sprintf('%%STD: %1.3f\nRC1mm: %1.3f\nRC2mm: %1.3f\nRC3mm: %1.3f\nRC4mm: %1.3f\nRC5mm: %1.3f\nSOR water: %1.3f\nSOR air: %1.3f\n', ...
            Results.Uniformity_PercentSTD, Results.Rod1_RC, Results.Rod2_RC, Results.Rod3_RC, Results.Rod4_RC, Results.Rod5_RC, ...
            Results.Water_SOR, Results.Air_SOR));
        set(get(settings,'Children'),'Enable','on');
    end

    function writeExcel(Results)
        xlswrite(output,[{'JA DISSELHORST','NEMA IQ Analysis';'','';'Parameter','Value'};[fieldnames(Results),struct2cell(Results)]]);
        set(get(settings,'Children'),'Enable','on');
    end

    function H=circle(center,radius,NOP,style)
    %----------------------------------------------------
    % H=CIRCLE(CENTER,RADIUS,NOP,STYLE)
    % This routine draws a circle with center defined as
    % a vector CENTER, radius as a scaler RADIS. NOP is 
    % the number of points on the circle. As to STYLE,
    % use it the same way as you use the rountine PLOT.
    % Since the handle of the object is returned, you
    % use routine SET to get the best result.
    %   Usage Examples,
    %   circle([1,3],3,1000,'r'); 
    %   circle([2,4],2,1000,[1 0 0]);
    %
    %   Zhenhai Wang <zhenhai@ieee.org>
    %   Version 1.00
    %   December, 2002
    % Edit: JA Disselhorst '09
    %------------------------------------------------------

        THETA=linspace(0,2*pi,NOP);
        RHO=ones(1,NOP)*radius;
        [X,Y] = pol2cart(THETA,RHO);
        X=X+center(1);
        Y=Y+center(2);
        H = [X;Y];
        plot(X,Y,'Color',style);
        axis square;

    end


end



 
 