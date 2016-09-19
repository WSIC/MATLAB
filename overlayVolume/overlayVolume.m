function overlayVolume(varargin)
%OVERLAYVOLUME displays a 3D volume in slices with optional overlay.
%
% Usage: 
% - OVERLAYVOLUME(V1, V2):     Displays a 3D datasets V1, and an overlay
%                              dataset V2, with default display settings.
%                              4D datasets are also supported.   
% - OVERLAYVOLUME(V1):         Displays one 3D dataset VOL1
% - OVERLAYVOLUME(...,'p',V);  Displays 3D datasets with addional user
%                              specified display settings. Settings should
%                              be provided as parameter name - value pairs.
%
% Optional parameters:
% - backRange:   display range of background data as [lower, upper]
%                default: [lowest value in data, highest value]
% - backMap:     colormap of the background as Nx3 matrix
%                default: gray(256)
% - overRange:   display range of overlay data as [lower, upper]
%                default: [lowest value in data, highest value]
% - overMap:     colormap of the overlay as Nx3 matrix
%                default: jet(256)
% - alpha:       transparency of the overlay as scalar between 0 and 1
%                default: 0.5
% - maskRange:   range of values in the overlay that will be displayed as
%                [LO, HI]. That is, all values lower than LO, and all
%                values higher than HI will not be shown. 
%                default: []
% - aspectRatio: aspect ratio of the three dimensions as [x,y,z]
%                default: [1 1 1]
% - title:       Adds a name to the windows [char array]
%
% 
% Examples:
% load('mri'); VOL1 = double(squeeze(D)); % load matlab sample data
% VOL2 = (VOL1>20).*rand(size(VOL1));     % create a random overlay
% OVERLAYVOLUME(VOL1,VOL2,'alpha',0.2);   % show volumes, alpha=0.2
% OVERLAYVOLUME(VOL1,VOL2,'backMap',bone(256),'overMap',hot(64));
% OVERLAYVOLUME(VOL1,'aspectRatio',[1 1 5]);
% 
% Acknowledgement:
% - "ct3"        by "tripp",      FileExchange ID: #32173
% - "OverlayImg" by "Jochen Rau", FileExchange ID: #26790
%
% J.A. Disselhorst
% Werner Siemens Imaging Center, http://www.preclinicalimaging.org/
% University of Tuebingen, Germany.
% Version: 2.16.9.12 (2016.09.12)
% Changelog: 
% 2016.09.12: supports saving of ROIs to workspace.
% 2016.06.22: supports integer input.
%
% TODO:
% - ROI LOAD
% - BETTER INPUT PARSING
%   - CHECK IF THE BACKGROUND AND OVERLAY ARE THE SAME SIZE
%   - CHANGE GUI ACCORDING TO COLORMAP INPUTS
%   - ACCEPT COLORMAP NAMES AS COLORMAP
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 

if nargin<1, error('At least 1 input argument required!'); end
vs = []; % variables
hs = []; % handles
ds = []; % data
createFigure;
parseInput(varargin);
setMenuVariables;
createMenu;
resizeFigure;

    
    function createFigure()
        vs.figTitle     = 'overlayVolume v2.16.9.12; J.A. Disselhorst (2014-2016)'; % Default Name;
        vs.figPos       = [100,100,1366,768];            % Position of the figure.
        vs.menuColor    = [0.8, 0.5, 0.3];               % Color of the menu
        vs.buttonColor  = [100 150 190]/255;             % Color of the buttons
        vs.crossColor   = [0.8,0.5,0.3];                 % Color of the crosshairs
        vs.imageColor   = 'k';                           % Background color around images
        vs.borderColors = [0.3, 0.3, 0.3; 1.0, 0.0 0.0]; % Not selected / selected
        vs.activeLayout = 1;                             % The default layout
        vs.activeView   = [true, false, false];          % The view that is active.

        % Do not change variables below:
        vs.menuWidth        = 180;
        vs.subImgPos        = [0,   0,   1/3, 1;   1/3, 0,   1/3, 1;   2/3, 0,   1/3, 1  ];
        vs.subImgPos(:,:,2) = [0,   0,   2/3, 1;   2/3, 0,   1/3, 1/2; 2/3, 1/2, 1/3, 1/2];
        vs.subImgPos(:,:,3) = [2/3, 1/2, 1/3, 1/2; 0,   0,   2/3, 1;   2/3, 0,   1/3, 1/2];
        vs.subImgPos(:,:,4) = [2/3, 1/2, 1/3, 1/2; 2/3, 0,   1/3, 1/2; 0,   0,   2/3, 1  ];
        vs.axDir            = [[2,1,2]; [3,3,1]]; % Direction of the axes.
        vs.ROImode          = 0; % ROI mode: 0: off, 1: add, -1: remove;
        vs.ROIpoints        = zeros(0,2);
        vs.showROI          = 0;
        
        hs.fig = figure('Position',vs.figPos,'MenuBar','figure','NumberTitle','off', ...
            'WindowButtonDownFcn',@clickInFigure, ...
            'WindowScrollWheelFcn',@figureScroll,...
            'NextPlot','new','Interruptible','off', 'BusyAction','cancel'); 
        hs.menuPanel = uipanel('Parent',hs.fig,'BackgroundColor',vs.menuColor,'Units','pixels','Position',[0 0 10 10],'BorderType','none');
        hs.ctrlMenu  = uipanel('Parent',hs.menuPanel,'Title','','TitlePosition','centerbottom','BackgroundColor',vs.menuColor,'HighlightColor','k','Units','normalized','Position',[0 0 1 1/3],'BorderType','line');
        hs.backMenu  = uipanel('Parent',hs.menuPanel,'Title','Background','TitlePosition','centerbottom','BackgroundColor',vs.menuColor,'HighlightColor','k','Units','normalized','Position',[0 1/3 1 1/3],'BorderType','line');
        hs.overMenu  = uipanel('Parent',hs.menuPanel,'Title','Overlay','TitlePosition','centerbottom','BackgroundColor',vs.menuColor,'HighlightColor','k','Units','normalized','Position',[0 2/3 1 1/3],'BorderType','line');
        hs.imgPanel  = uipanel('Parent',hs.fig,'BackgroundColor',vs.menuColor,'Units','pixels','Position',[0 0 10 10],'BorderType','none');
        for ii = 1:3
            hs.subImgPanel(ii) = uipanel('Parent',hs.imgPanel,'BorderType','line','HighlightColor',vs.borderColors(vs.activeView(ii)+1,:),'BackgroundColor',vs.imageColor,'Units','normalized','Position',vs.subImgPos(ii,:,vs.activeLayout),'BorderWidth',2);
            hs.subImgAxes(ii)  = axes('Parent',hs.subImgPanel(ii),'Position',[0 0 1 1]);  %#ok<LAXES>
            hs.subImgImage(ii) = image(1:3,1:3,ones([3,3,3],'uint8')*50,'CDataMapping','scaled','Parent',hs.subImgAxes(ii));
            set(hs.subImgAxes(ii),'DataAspectRatio',[1 1 1]); % This has to be done *after* the image has been initialized.
            hold(hs.subImgAxes(ii),'on');
            hs.subImgPointer(ii) = plot(hs.subImgAxes(ii),1,1,'g-');
            hs.subImgROIcurve(ii) = plot(hs.subImgAxes(ii),NaN,NaN,'g');
            hold(hs.subImgAxes(ii),'off');
            axis off
        end
        set(hs.fig,'NextPlot','new');
        setCursor('cross')
    end
    function initImages
        % INITIMAGES Initializes the images and indicator lines
        updateImages;
        for ii = 1:3
            set(hs.subImgImage(ii),'XData',1:vs.volumeSize(vs.axDir(1,ii)),'YData',1:vs.volumeSize(vs.axDir(2,ii)));
        	set(hs.subImgAxes(ii),'XLim',[0.5 vs.volumeSize(vs.axDir(1,ii))+0.5],'YLim',[0.5 vs.volumeSize(vs.axDir(2,ii))+0.5],...
                'DataAspectRatio',[vs.aspectRatio(vs.axDir(1,ii)) vs.aspectRatio(vs.axDir(2,ii)) 1]);
            x = vs.currentPoint(vs.axDir(1,ii));
            y = vs.currentPoint(vs.axDir(2,ii));
            set(hs.subImgPointer(ii),'XData',[-10000,10000,NaN,x,x],'YData',[y,y,NaN,-10000,10000],'Color',vs.crossColor)
        end
    end

    function setMenuVariables()
        cmaps = {'autumn','bone','colorcube','cool','copper','flag','gray','hot','hsv','jet','lines','pink','prism','spring','summer','white','winter'};
        
        vs.iconPath = fullfile(fileparts(mfilename('fullpath')),'Icons');
        vs.buttons = struct('Parent',{},'ID',{},'String',{},'Icon',{},'Position',{},'Style',{},'Enabled',{},'Value',{},'Function',{},'Color',{});
        
        addMenuItem(hs.ctrlMenu,'layout1','','view1.png',[10,10],'togglebutton','on',1,@changeLayout,{1},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'layout2','','view2.png',[50,10],'togglebutton','on',0,@changeLayout,{2},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'layout3','','view3.png',[90,10],'togglebutton','on',0,@changeLayout,{3},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'layout4','','view4.png',[130,10],'togglebutton','on',0,@changeLayout,{4},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'cross','','cross.png',[10,50],'togglebutton','on',1,@changeCrosshairs,{},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'aspect','','aspect.png',[50,50],'pushbutton','on',0,@changeAspectRatio,{},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'saveimg','','photo.png',[90,50],'pushbutton','on',1,@saveImages,{},vs.buttonColor);
        addMenuItem(hs.backMenu,'bbback', '','bb.png',[10,10],'pushbutton','on',0,@changeFrame,{1,-Inf},vs.buttonColor);
        addMenuItem(hs.backMenu,'bback',  '','b.png',[50,10],'pushbutton','on',0,@changeFrame,{1,-1},vs.buttonColor);
        addMenuItem(hs.backMenu,'fback',  '','f.png',[90,10],'pushbutton','on',0,@changeFrame,{1,1},vs.buttonColor);
        addMenuItem(hs.backMenu,'ffback', '','ff.png',[130,10],'pushbutton','on',1,@changeFrame,{1,Inf},vs.buttonColor);
        addMenuItem(hs.overMenu,'bbover', '','bb.png',[10,10],'pushbutton','on',0,@changeFrame,{2,-Inf},vs.buttonColor);
        addMenuItem(hs.overMenu,'bover',  '','b.png',[50,10],'pushbutton','on',0,@changeFrame,{2,-1},vs.buttonColor);
        addMenuItem(hs.overMenu,'fover',  '','f.png',[90,10],'pushbutton','on',0,@changeFrame,{2,1},vs.buttonColor);
        addMenuItem(hs.overMenu,'ffover', '','ff.png',[130,10],'pushbutton','on',1,@changeFrame,{2,Inf},vs.buttonColor);
        addMenuItem(hs.backMenu,'lbcmap', 'Colormap: ',[],[10,40,72,16],'text','on',0,[],{},vs.menuColor);
        addMenuItem(hs.overMenu,'locmap', 'Colormap: ',[],[10,40,72,16],'text','on',0,[],{},vs.menuColor);
        addMenuItem(hs.backMenu,'bcmap',  cmaps,[],[66,40,100,20],'popupmenu','on',7,@changeColormap,{1},'w');
        addMenuItem(hs.overMenu,'ocmap',  cmaps,[],[66,40,100,20],'popupmenu','on',10,@changeColormap,{0},'w');
        addMenuItem(hs.backMenu,'lbrange','Range: ',[],[10,65,35,16],'text','on',0,[],{},vs.menuColor);
        addMenuItem(hs.backMenu,'brangeb',sprintf('%g',vs.backRange(1)),[],[50,65,55,20],'edit','on',0,@changeRange,{1,1},'w');
        addMenuItem(hs.backMenu,'brangee',sprintf('%g',vs.backRange(2)),[],[110,65,55,20],'edit','on',0,@changeRange,{1,2},'w');
        addMenuItem(hs.overMenu,'lbrange','Range: ',[],[10,65,35,16],'text','on',0,[],{},vs.menuColor);
        addMenuItem(hs.overMenu,'orangeb',sprintf('%g',vs.overRange(1)),[],[50,65,55,20],'edit','on',0,@changeRange,{2,1},'w');
        addMenuItem(hs.overMenu,'orangee',sprintf('%g',vs.overRange(2)),[],[110,65,55,20],'edit','on',0,@changeRange,{2,2},'w');
        addMenuItem(hs.overMenu,'lmask','Mask: ',[],[10,90,35,16],'text','on',0,[],{},vs.menuColor);
        addMenuItem(hs.overMenu,'maskb',sprintf('%g',vs.maskRange(1)),[],[50,90,55,20],'edit','on',0,@changeRange,{3,1},'w');
        addMenuItem(hs.overMenu,'maske',sprintf('%g',vs.maskRange(2)),[],[110,90,55,20],'edit','on',0,@changeRange,{3,2},'w');
        addMenuItem(hs.overMenu,'lalpha', 'Alpha: ',[],[10,115,35,16],'text','on',0,[],{},vs.menuColor);
        addMenuItem(hs.overMenu,'alpha',  '',[],[50,115,115,20],'slider','on',0.5,@changeAlpha,{},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'ROIadd','','pencil.png',[10,100],'togglebutton','on',0,@roiEdit,{1},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'ROIrem','','eraser.png',[50,100],'togglebutton','on',0,@roiEdit,{0},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'lrois','Current ROI: ',[],[90,122,76,16],'text','on',0,[],{},vs.menuColor);
        addMenuItem(hs.ctrlMenu,'ROIlist',{'<NEW>'},[],[90,102,76,20],'popupmenu','on',1,@roiSelect,{},'w');
        addMenuItem(hs.ctrlMenu,'ROIplot','','plot.png',[10,140],'pushbutton','on',1,@plotROIs,{},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'ROIsave','','save.png',[50,140],'pushbutton','on',1,@saveROIs,{},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'ROIload','','load.png',[90,140],'pushbutton','off',1,@loadROIs,{},vs.buttonColor);
        addMenuItem(hs.ctrlMenu,'ROItrash','','trash.png',[130,140],'pushbutton','on',1,@trashROIs,{},vs.buttonColor);
        
    end
    function addMenuItem(Parent,ID,String,Icon,Position,Style,Enabled,Value,Function,Args,Color)
        N = numel(vs.buttons)+1;
        vs.buttons(N).Parent = Parent;
        vs.buttons(N).ID = ID;
        vs.buttons(N).String = String;
        vs.buttons(N).Icon = Icon;
        vs.buttons(N).Position = Position;
        vs.buttons(N).Style = Style;
        vs.buttons(N).Enabled = Enabled;
        vs.buttons(N).Value = Value;
        vs.buttons(N).Color = Color;
        if ~isempty(Function)
            vs.buttons(N).Function = [{Function},{N},Args];
        else
            vs.buttons(N).Function = [];
        end
    end
    function createMenu()
        for ii = 1:length(vs.buttons)
            if ~isempty(vs.buttons(ii).Icon)
                icon = imread(fullfile(vs.iconPath,vs.buttons(ii).Icon));
                pos = [vs.buttons(ii).Position, size(icon,2)+4, size(icon,1)+4];
            else
                icon = [];
                pos = vs.buttons(ii).Position;
            end
            hs.buttons(ii) = uicontrol('Parent',vs.buttons(ii).Parent,'Style',vs.buttons(ii).Style,...
                'Position',pos, 'Enable',vs.buttons(ii).Enabled,'Callback',vs.buttons(ii).Function, ...
                'Value', vs.buttons(ii).Value,'Tag',vs.buttons(ii).ID,'cdata',icon,'String',vs.buttons(ii).String, ...
                'BackgroundColor', vs.buttons(ii).Color, 'HorizontalAlignment','left');
        end
        if vs.numFrames(1)==1
            set(findobj(hs.buttons, '-regexp','Tag','back'),'Enable','off');
        end
        if vs.numFrames(2)==1
            set(findobj(hs.buttons, '-regexp','Tag','over'),'Enable','off');
        end
    end

    function changeLayout(varargin)
        vs.activeLayout = varargin{4};
        for ii = 1:3
            set(hs.subImgPanel(ii),'Position',vs.subImgPos(ii,:,vs.activeLayout));
        end
        for ii = 1:4
            vs.buttons(strcmp({vs.buttons.ID},sprintf('layout%1.0f',ii))).Value = (ii == varargin{4});
        end
        refreshButtons;
        resizeFigure;
    end
    function changeCrosshairs(varargin)
        if get(varargin{1},'Value')
            set(hs.subImgPointer,'LineStyle','-');
            vs.buttons(varargin{3}).Value = 1;
        else
            set(hs.subImgPointer,'LineStyle','none');
            vs.buttons(varargin{3}).Value = 0;
        end
    end
    function changeFrame(varargin)
        vs.currentFrame(varargin{4}) = vs.currentFrame(varargin{4})+varargin{5};
        vs.currentFrame = min([vs.numFrames; max([[1 1]; vs.currentFrame])]);
        updateImages;
    end
    function changeColormap(varargin)
        selected = get(varargin{1},'value');
        vs.buttons(varargin{3}).Value = selected;
        if varargin{4} % backmap
            vs.backMap = eval([vs.buttons(varargin{3}).String{selected} '(256)']);
        else           % overmap
            vs.overMap = eval([vs.buttons(varargin{3}).String{selected} '(256)']);
        end
        updateImages;
    end
    function changeRange(varargin)
        value = str2double(get(varargin{1},'String'));
        ranges = {'backRange','overRange','maskRange'};
        range = vs.(ranges{varargin{4}});
        if ~isnan(value)
            if varargin{5}==2
                if value>range(1)
                    range(2) = value;
                end
            else
                if value<range(2)
                    range(1) = value;
                end
            end
            vs.(ranges{varargin{4}}) = range;
            updateImages;
        end
        set(varargin{1},'String',sprintf('%g',range(varargin{5})));
    end
    function changeAlpha(varargin)
        alpha = get(varargin{1},'Value');
        vs.buttons(varargin{3}).Value = alpha;
        vs.alpha = alpha;
        updateImages;
    end
    function changeAspectRatio(varargin)
        Default = vs.aspectRatio;
        Default = arrayfun(@num2str, Default/min(Default),'UniformOutput',false);
        answer = inputdlg({'X:','Y:','Z:'},'Image aspect ratio',1,Default);
        if ~isempty(answer)
            answer = str2double(answer); 
            answer = answer/min(answer); 
            vs.aspectRatio = answer;
            for ii = 1:3
                set(hs.subImgAxes(ii),'position',[0 0 1 1],'DataAspectRatio',...
                    [vs.aspectRatio(vs.axDir(1,ii)) vs.aspectRatio(vs.axDir(2,ii)) 1]);
            end
            resizeFigure;
        end
    end

    function parseInput(input)
        if length(input)>1 && ischar(input{2})
            input = [input(1),{[]},input(2:end)];
        end
        
        p = inputParser;
        p.addRequired('backVol',@(x)ndims(x)>=2);
        p.addOptional('overVol',[],@(x)ndims(x)>=2);
        p.addParamValue('backRange',[],@(x)length(x)==2&x(1)<x(2));
        p.addParamValue('overRange',[],@(x)length(x)==2&x(1)<x(2));
        p.addParamValue('backMap',gray(256),@(x)isnumeric(x)&ismatrix(x)&size(x,2)==3)
        p.addParamValue('overMap',jet(256),@(x)isnumeric(x)&ismatrix(x)&size(x,2)==3)
        p.addParamValue('maskRange',[-Inf Inf],@(x)length(x)==2&x(1)<x(2));
        p.addParamValue('alpha',0.5,@(x)x>=0&x<=1);
        p.addParamValue('aspectRatio',[1 1 1],@(x)length(x)==3);
        p.addParamValue('title',vs.figTitle,@ischar);
        p.parse(input{:});
        vs.backRange   = p.Results.backRange;
        vs.overRange   = p.Results.overRange;
        vs.maskRange   = p.Results.maskRange;
        vs.alpha       = p.Results.alpha;
        vs.backMap     = p.Results.backMap;
        vs.overMap     = p.Results.overMap;
        vs.aspectRatio = p.Results.aspectRatio;
        vs.figTitle    = p.Results.title;
        
        ds.backVol = p.Results.backVol; if isinteger(ds.backVol), ds.backVol = double(ds.backVol); end
        ds.overVol = p.Results.overVol; if isinteger(ds.overVol), ds.overVol = double(ds.overVol); end
        if isempty(vs.backRange), vs.backRange = getRange(ds.backVol); end
        if isempty(vs.overRange), vs.overRange = getRange(ds.overVol); end
        
        vs.volumeSize = [size(ds.backVol), 1];  % The size of the volume (the 1 is added for 2D cases).
        vs.volumeSize = vs.volumeSize(1:3); 
        vs.currentPoint = round(vs.volumeSize/2);
        if isempty(ds.overVol), set(hs.overMenu,'Visible','off'); end
        vs.numFrames = [size(ds.backVol,4), size(ds.overVol,4)];
        vs.currentFrame = [size(ds.backVol,4), size(ds.overVol,4)];
        set(hs.fig,'Name',vs.figTitle,'ResizeFcn',@resizeFigure);
        
        initImages; % Set the correct axis etc.
    end 
    function range = getRange(volume)
        % GETRANGE provides the display range for a volume
        % The function will provide the minimum and maximum value in
        % the volume, NaNs and Infs will be ignored.
        volume(~isfinite(volume)) = [];
        if ~isempty(volume)
            range = [min(volume(:)), max(volume(:))];
            %range = prctile(volume(:), [0.05, 99.95]);       % Set the range to exclude the first and last 0.05%, the possible outliers. -> Slow and uses a lot of memory
            if diff(range)==0 % When the numbers are equal
                range = range+[-1, 1]; % Subtract and add one.
            end
        else
            range = [-1E9 1E9];
        end
    end

    function clickInFigure(varargin)
        ST = get(hs.fig,'SelectionType');  % Get the type of mouse click
        currentPoint = get(hs.fig,'CurrentPoint');
        [type,position] = determineClickPosition(currentPoint);
        if ~any(type) % click in the menu
            %disp('Click in menu');
        else % Click on the images
            if strcmp(ST,'normal')
                if any(vs.activeView~=type) % Not the active panel was clicked.
                    vs.activeView = type;
                    for i = 1:3
                        set(hs.subImgPanel(i),'HighlightColor',vs.borderColors(vs.activeView(i)+1,:));
                    end
                else % The active panel was clicked
                    CP = vs.currentPoint;
                    VS = vs.volumeSize;
                    if type(1)
                        CP(3) = max([1 min([VS(3), round(position(2))])]);
                        CP(2) = max([1 min([VS(2), round(position(1))])]);
                    elseif type(2)
                        CP(3) = max([1 min([VS(3), round(position(2))])]);
                        CP(1) = max([1 min([VS(1), round(position(1))])]);
                    else
                        CP(1) = max([1 min([VS(1), round(position(2))])]);
                        CP(2) = max([1 min([VS(2), round(position(1))])]);
                    end
                    if vs.ROImode
                        vs.ROIpoints = [position(1),position(2)];
                        set(hs.subImgROIcurve(type),'XData',vs.ROIpoints(:,1),'YData',vs.ROIpoints(:,2));
                        set(hs.fig,'NextPlot','new','WindowButtonUpFcn',{@mouseUp,type}, ...
                                   'WindowButtonMotionFcn',{@mouseMove,'roi',type}, ...
                                   'WindowScrollWheelFcn','');
                    else
                        vs.currentPoint = CP;
                        updateImages(find(~type)); % Update the images of the other figures.
                    end
                end
            elseif strcmp(ST,'extend') % Shift-click, or double mouse button, or mousewheel click
                vs.mousePoint = get(hs.fig,'CurrentPoint');
                setCursor('contrast');
                set(hs.fig, 'WindowButtonUpFcn',@mouseUp,...
                    'WindowButtonMotionFcn',{@mouseMove,'over'});
            elseif strcmp(ST,'alt') % Right click
                vs.mousePoint = get(hs.fig,'CurrentPoint');
                setCursor('contrast');
                set(hs.fig, 'WindowButtonUpFcn',@mouseUp,...
                    'WindowButtonMotionFcn',{@mouseMove,'back'});
            end
        end
    end
    function [type, position] = determineClickPosition(currentPoint,type)
        if nargin<2
            if currentPoint(1)<=vs.menuWidth; % click in the menu
                type = false;
                position = currentPoint;
            else
                type = currentPoint-[vs.menuWidth, 0];
                type = repmat(type./vs.imgPanelPos,[3,1]);
                type = vs.subImgPos(:,1:2,vs.activeLayout)-type;
                type(type>0) = Inf;
                type = sum(type.^2,2);
                type = (type==min(type))';
                if sum(type)==1
                    axesClick = get(hs.subImgAxes(type),'CurrentPoint');
                    position = [axesClick(1,1), axesClick(2,2)];
                else
                    type = false;
                    position = currentPoint;
                end
            end
        else
            axesClick = get(hs.subImgAxes(type),'CurrentPoint');
            position = [axesClick(1,1), axesClick(2,2)];
        end
    end
    function mouseMove(varargin)
        % MOUSEMOVE is used to change the contrast and brightness
        % This function is only triggered when the user clicks and
        % holds the right of middle mouse button.
        newMouse = get(hs.fig,'CurrentPoint');
        switch varargin{3}
            case 'back'
                mouseMove = newMouse - vs.mousePoint;
                Value = vs.backRange;
                Value = Value + mouseMove*0.01*diff(Value);
                if Value(1)<Value(2)                            % The first should be smaller than the second
                    vs.backRange = Value;                       % Set the values.
                    updateImages;                               % Update the images.
                    set(findobj('Tag','brangeb'),'String',sprintf('%g',Value(1)));
                    set(findobj('Tag','brangee'),'String',sprintf('%g',Value(2)));
                end
            case 'over'
                if ~isempty(vs.overRange)
                    mouseMove = newMouse - vs.mousePoint;
                    Value = vs.overRange;
                    Value = Value + mouseMove*0.01*diff(Value);
                    if Value(1)<Value(2)                            % The first should be smaller than the second
                        vs.overRange = Value;                       % Set the values.
                        updateImages;                               % Update the images.
                        set(findobj('Tag','orangeb'),'String',sprintf('%g',Value(1)));
                        set(findobj('Tag','orangee'),'String',sprintf('%g',Value(2)));
                    end
                end
            case 'roi'
                [~, position] = determineClickPosition(newMouse,varargin{4});
                vs.ROIpoints = [vs.ROIpoints; [position(1),position(2)]];
                set(hs.subImgROIcurve(varargin{4}),'XData',vs.ROIpoints(:,1),'YData',vs.ROIpoints(:,2));
        end
        vs.mousePoint = newMouse;
    end
    function mouseUp(varargin)
        if vs.ROImode
            X = vs.axDir(1,varargin{3});
            Y = vs.axDir(2,varargin{3});
            if X<Y
                mask = poly2mask(vs.ROIpoints(:,2),vs.ROIpoints(:,1),vs.volumeSize(X),vs.volumeSize(Y));
            else
                mask = poly2mask(vs.ROIpoints(:,1),vs.ROIpoints(:,2),vs.volumeSize(Y),vs.volumeSize(X));
            end
            set(hs.subImgROIcurve,'XData',NaN,'YData',NaN);
            n =  get(findobj(hs.buttons,'Tag','ROIlist'),'Value');
            MSK = false(vs.volumeSize);
            sz = {1:vs.volumeSize(1),1:vs.volumeSize(2),1:vs.volumeSize(3)};
            sz{varargin{3}} = vs.currentPoint(varargin{3});
            MSK(sz{1},sz{2},sz{3}) = mask;
            if vs.ROImode>0
                ds.ROIVol(:,:,:,vs.showROI) = ds.ROIVol(:,:,:,vs.showROI) | MSK;
            else
                ds.ROIVol(:,:,:,vs.showROI) = ds.ROIVol(:,:,:,vs.showROI) & ~MSK;
            end
            updateImages;
        else
            setCursor('cross');
        end
        set(hs.fig, 'WindowButtonUpFcn','','WindowButtonMotionFcn','','WindowScrollWheelFcn',@figureScroll);
    end
    function figureScroll(~,evnt)
        % FIGURESCROLL triggers when the mousewheel is used in a figure
        % The function checks in which figure the scrolling was done,
        % keeps the position within the bounds of the volume and if
        % necessary (the position has changed) updates the images.
        CP = vs.currentPoint; % The current point
        VS = vs.volumeSize;
        if vs.activeView(1)
            temp = CP(1);
            CP(1) = CP(1)+evnt.VerticalScrollCount; % Add the scroll count (this number can also be negative)
            CP(1) = min([VS(1), max([1, CP(1)])]); % The new position should be in correct range (>0 and <image size).
            vs.currentPoint = CP;
            if temp~=CP(1)  % When the position has changed
                updateImages(1);  % Update the images.
            end
        elseif vs.activeView(2)
            temp = CP(2);
            CP(2) = CP(2)+evnt.VerticalScrollCount;
            CP(2) = min([VS(2), max([1, CP(2)])]);
            vs.currentPoint = CP;
            if temp~=CP(2)
                updateImages(2);
            end
        else
            temp = CP(3);
            CP(3) = CP(3)+evnt.VerticalScrollCount;
            CP(3) = min([VS(3), max([1, CP(3)])]);
            vs.currentPoint = CP;
            if temp~=CP(3)
                updateImages(3);
            end
        end
    end
    function setCursor(cursor)
        % SETCURSOR sets custom cursors indicating the current function
        switch cursor
            case 'contrast'
                pointer = [0 0 0 0 0 2 2 2 1 1 1 0 0 0 0 0;0 0 0 2 2 1 1 1 2 2 2 1 1 0 0 0;0 0 2 1 1 1 1 1 2 2 2 2 2 1 0 0;0 2 1 1 1 1 1 1 2 2 2 2 2 2 1 0;0 2 1 1 1 1 1 1 2 2 2 2 2 2 1 0;2 1 1 1 1 1 1 1 2 2 2 2 2 2 2 1;2 1 1 1 1 1 1 1 2 2 2 2 2 2 2 1;2 1 1 1 1 1 1 1 2 2 2 2 2 2 2 1;2 1 1 1 1 1 1 1 2 2 2 2 2 2 2 1;2 1 1 1 1 1 1 1 2 2 2 2 2 2 2 1;2 1 1 1 1 1 1 1 2 2 2 2 2 2 2 1;0 2 1 1 1 1 1 1 2 2 2 2 2 2 1 0;0 2 1 1 1 1 1 1 2 2 2 2 2 2 1 0;0 0 2 1 1 1 1 1 2 2 2 2 2 1 0 0;0 0 0 2 2 1 1 1 2 2 2 1 1 0 0 0;0 0 0 0 0 2 2 2 1 1 1 0 0 0 0 0;];
                spot = [8,8];
            case 'rotate'
                pointer = [0 0 0 0 1 1 1 1 1 1 1 1 0 1 1 1;0 0 0 1 1 2 2 2 2 2 2 1 1 1 2 1;0 0 1 1 2 2 2 2 2 2 2 2 1 2 2 1;0 0 1 2 2 1 1 1 1 1 2 2 2 2 2 1;0 0 1 2 1 1 0 0 0 1 1 2 2 2 2 1;0 0 1 1 1 0 0 0 1 1 2 2 2 2 2 1;0 0 0 0 0 0 0 0 1 2 2 2 2 2 2 1;0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1;1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0;1 2 2 2 2 2 2 1 0 0 0 0 0 0 0 0;1 2 2 2 2 2 1 1 0 0 0 1 1 1 0 0;1 2 2 2 2 1 1 0 0 0 1 1 2 1 0 0;1 2 2 2 2 2 1 1 1 1 1 2 2 1 0 0;1 2 2 1 2 2 2 2 2 2 2 2 1 1 0 0;1 2 1 1 1 2 2 2 2 2 2 1 1 0 0 0;1 1 1 0 1 1 1 1 1 1 1 1 0 0 0 0;];
                spot = [8,8];
            case 'roi'
                pointer = [1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0;1 2 2 2 1 0 0 0 0 0 0 0 0 0 0 0;1 2 2 1 0 0 0 0 0 0 0 0 0 0 0 0;1 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0;1 1 0 0 1 2 1 2 1 2 1 2 1 2 1 2;1 0 0 0 2 1 2 1 2 1 2 1 2 1 2 1;0 0 0 0 1 2 0 0 0 0 0 0 0 0 1 2;0 0 0 0 2 1 0 0 0 0 0 0 0 0 2 1;0 0 0 0 1 2 0 0 0 0 0 0 0 0 1 2;0 0 0 0 2 1 0 0 0 0 0 0 0 0 2 1;0 0 0 0 1 2 0 0 0 0 0 0 0 0 1 2;0 0 0 0 2 1 0 0 0 0 0 0 0 0 2 1;0 0 0 0 1 2 0 0 0 0 0 0 0 0 1 2;0 0 0 0 2 1 0 0 0 0 0 0 0 0 2 1;0 0 0 0 1 2 1 2 1 2 1 2 1 2 1 2;0 0 0 0 2 1 2 1 2 1 2 1 2 1 2 1;];
                spot = [1,1];
            case 'pencil'
                pointer = [0 0 0 0 0 0 0 0 0 0 0 2 1 2 0 0;0 0 0 0 0 0 0 0 0 0 2 1 1 1 2 0;0 0 0 0 0 0 0 0 0 2 2 1 1 1 1 2;0 0 0 0 0 0 0 0 2 1 1 2 1 1 1 1;0 0 0 0 0 0 0 2 1 1 1 1 2 1 1 2;0 0 0 0 0 0 2 1 1 1 1 1 1 2 2 0;0 0 0 0 0 2 1 1 1 1 1 1 1 2 0 0;0 0 0 0 2 1 1 1 1 1 1 1 2 0 0 0;0 0 0 2 1 1 1 1 1 1 1 2 0 0 0 0;0 0 2 1 1 1 1 1 1 1 2 0 0 0 0 0;0 2 1 1 1 1 1 1 1 2 0 0 0 0 0 0;2 2 1 1 1 1 1 1 2 0 0 0 0 0 0 0;2 1 2 1 1 1 1 2 0 0 0 0 0 0 0 0;2 1 1 2 1 1 2 0 0 0 0 0 0 0 0 0;2 1 1 1 2 2 0 0 0 0 0 0 0 0 0 0;2 2 2 2 2 0 0 0 0 0 0 0 0 0 0 0;];
                spot = [16 1];
            case 'eraser'
                pointer = [0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0;0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0;0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0;0,0,0,0,0,0,2,2,2,2,2,2,2,2,0,0;0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,0;0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2;0,0,0,2,2,1,2,2,2,2,2,2,2,2,2,2;0,0,2,2,1,1,1,2,2,2,2,2,2,2,2,0;0,2,2,1,1,1,1,1,2,2,2,2,2,2,0,0;2,2,1,1,1,1,1,1,1,2,2,2,2,0,0,0;0,2,2,1,1,1,1,1,1,1,2,2,0,0,0,0;0,0,2,2,1,1,1,1,1,2,2,0,0,0,0,0;0,0,0,2,2,1,1,1,2,2,0,0,0,0,0,0;0,0,0,0,2,2,1,2,2,0,0,0,0,0,0,0;2,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0;2,2,0,0,0,0,2,0,0,0,0,0,0,0,0,0];
                spot = [16 1];
            case 'cross'
                pointer = [0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;2 2 2 2 2 2 2 0 2 2 2 2 2 2 2 0;1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 0;2 2 2 2 2 2 2 0 2 2 2 2 2 2 2 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;];
                spot = [7,7];
        end
        pointer(~pointer) = NaN;
        set(hs.fig,'Pointer','custom','PointerShapeCData',pointer,'PointerShapeHotSpot',spot)
    end

    function resizeFigure(varargin)
        position = get(hs.fig,'Position');
        set(hs.menuPanel,'Position',[1 1 vs.menuWidth position(4)]);
        set(hs.imgPanel,'Position',[vs.menuWidth+1, 1, position(3)-vs.menuWidth, position(4)]);
        vs.imgPanelPos = [position(3)-vs.menuWidth, position(4)];

        % Get the size of all subimages [1: y,z. 2: x,z. 3: y,x]:
        a = vs.volumeSize([2,3;1,3;2,1]);
        b = vs.aspectRatio([2,3;1,3;2,1]);
        % Get the size of displays, obtain ratios
        showratio = vs.subImgPos(:,3:4,vs.activeLayout).*repmat(vs.imgPanelPos,[3,1]);
        showratio = (showratio(:,1).*b(:,1))./(showratio(:,2).*b(:,2));
        % Determine the axes limits:
        X = (max([a(:,2).*showratio, a(:,1)],[],2)-a(:,1))/2;
        Y = (max([a(:,1)./showratio, a(:,2)],[],2)-a(:,2))/2;

        for ii = 1:3
            XLim = [0.5 vs.volumeSize(vs.axDir(1,ii))+0.5]+[-X(ii) X(ii)];
            YLim = [0.5 vs.volumeSize(vs.axDir(2,ii))+0.5]+[-Y(ii) Y(ii)];
            %%%%%% Check for zoom level [UNDOCUMENTED MATLAB]:
            info = getappdata(hs.subImgAxes(ii),'matlab_graphics_resetplotview');
            if ~isempty(info)
                zX = get(hs.subImgAxes(ii),'XLim');
                zY = get(hs.subImgAxes(ii),'YLim');
                if ~isequal(zX, info.XLim) || ~isequal(zY, info.YLim)
                    % Zoomed axes: set zoomed axes and adapt zoom info
                    Cx = (zX(1)+zX(2))/2;
                    Cy = (zY(1)+zY(2))/2;
                    magn = diff(info.XLim)./(zX(2)-zX(1));
                    W = (XLim(2)-XLim(1))/2/magn;
                    H = (YLim(2)-YLim(1))/2/magn; 
                    set(hs.subImgAxes(ii),'XLim',[Cx-W,Cx+W],'YLim',[Cy-H,Cy+H]);
                    info.XLim = XLim; info.YLim = YLim;
                    setappdata(hs.subImgAxes(ii),'matlab_graphics_resetplotview',info);
                else
                    % No zoom: Set axes and remove zoom information.
                    set(hs.subImgAxes(ii),'XLim',XLim,'YLim',YLim);
                    setappdata(hs.subImgAxes(ii),'matlab_graphics_resetplotview',[]);
                end
            else
                % No zoom level information to change:
                set(hs.subImgAxes(ii),'XLim',XLim,'YLim',YLim);
            end
        end
    end
    function updateImages(views)
    % UPDATEIMAGES updates the images.
    % The function can be called for one specific window, without
    % the second argument it will update all open windows.
    % First the new images are set, then the markers are updated,
    % and if a ROI is present it will be updated as well.
        if nargin<1
            views = 1:3;
        end
        for ii = 1:length(views)
            %try
                IMG = provideImage(views(ii));
                set(hs.subImgImage(views(ii)),'CData',IMG); 
            %end
        end
        for ii = 1:3
            x = vs.currentPoint(vs.axDir(1,ii));
            y = vs.currentPoint(vs.axDir(2,ii));
            set(hs.subImgPointer(ii),'XData',[-10000,10000,NaN,x,x],'YData',[y,y,NaN,-10000,10000])
        end
        if vs.numFrames(1)>1, frameStr = sprintf(' (%u)',vs.currentFrame(1)); else frameStr = ''; end
        set(hs.backMenu,'Title',sprintf('Background: %g%s',ds.backVol(vs.currentPoint(1),vs.currentPoint(2),vs.currentPoint(3),vs.currentFrame(1)),frameStr));
        if ~isempty(ds.overVol)
           if vs.numFrames(2)>1, frameStr = sprintf(' (%u)',vs.currentFrame(2)); else frameStr = ''; end
           set(hs.overMenu,'Title',sprintf('Overlay: %g%s',ds.overVol(vs.currentPoint(1),vs.currentPoint(2),vs.currentPoint(3),vs.currentFrame(2)),frameStr));
        end
        set(hs.ctrlMenu,'Title',sprintf('Position (%u, %u, %u)',vs.currentPoint(1),vs.currentPoint(2),vs.currentPoint(3)));
    end
    function IMG = provideImage(view)
            % PROVIDEIMAGE creates an image from the volumes to display
            % All settings such as the colormap, the colorrange, the alpha
            % value etc, are being processed here to produce the correct
            % image. The function will be called for each figure
            % individually. 
            CP = vs.currentPoint; 
            CF = vs.currentFrame;
            % Get the image for the background:
            if view==1
                IMG1 = permute(ds.backVol(CP(1),:,:,CF(1)),[3 2 1]);
            elseif view==2
                IMG1 = permute(ds.backVol(:,CP(2),:,CF(1)),[3 1 2]);
            else
                IMG1 = ds.backVol(:,:,CP(3),CF(1));
            end
            IMG1 = IMG1-vs.backRange(1); % Subtract the lower display limit.
            IMG1 = IMG1./(vs.backRange(2)-vs.backRange(1)); % Also use the upper display limit.
            IMG1(IMG1<0) = 0; % Everything below the lower limit is set to the lower limit.
            IMG1(IMG1>1) = 1; % Everything above the upper limit is set to the upper limit.
            IMG1 = round(IMG1*(size(vs.backMap,1)-1))+1;  % Multiply by the size of the colormap, and make it integers to get a color index.
            IMG1(isnan(IMG1)) = 1; % remove NaNs -> these will be shown as the lower limit.
            IMG1 = reshape(vs.backMap(IMG1,:),[size(IMG1,1),size(IMG1,2),3]); % Get the correct color from the colormap using the index calculated above
            
            % If present, create the overlay image including mask
            if ~isempty(ds.overVol);
                if view==1
                    IMG2 = permute(ds.overVol(CP(1),:,:,CF(2)),[3 2 1]);
                elseif view==2
                    IMG2 = permute(ds.overVol(:,CP(2),:,CF(2)),[3 1 2]);
                else
                    IMG2 = ds.overVol(:,:,CP(3),CF(2));
                end
                % If a maskrange is available, use it. First the mask is
                % set to one (show all), then everything outside the mask
                % range will be set to zero (not shown)
                if ~isempty(vs.maskRange)
                    mask = ones(size(IMG2));
                    mask(IMG2<vs.maskRange(1) | IMG2>vs.maskRange(2)) = 0;
                else
                    mask = ones(size(IMG2));
                end
                IMG2=IMG2-vs.overRange(1);
                IMG2=IMG2./(vs.overRange(2)-vs.overRange(1));
                IMG2(IMG2<0) = 0;
                IMG2(IMG2>1) = 1;
                IMG2 = round(IMG2*(size(vs.overMap,1)-1))+1;
                mask(isnan(IMG2)) = 0;
                IMG2(isnan(IMG2)) = 1;
                IMG2 = reshape(vs.overMap(IMG2,:),[size(IMG2,1),size(IMG2,2),3]);
                mask = repmat(mask,[1 1 3]); % repeat mask for R, G and B.
                %IMG = IMG1*(1-obj.alpha) + mask.*IMG2*obj.alpha; % Combine background and overlay, using alpha and mask.
                IMG = IMG1.* ((mask .* -vs.alpha) + 1) + mask.*IMG2*vs.alpha; % Combine background and overlay, using alpha and mask.
            else
                IMG = IMG1;
            end
            if vs.showROI
                if view==1
                    IMG3 = permute(ds.ROIVol(CP(1),:,:,vs.showROI),[3 2 1]);
                elseif view==2
                    IMG3 = permute(ds.ROIVol(:,CP(2),:,vs.showROI),[3 1 2]);
                else
                    IMG3 = ds.ROIVol(:,:,CP(3),vs.showROI);
                end
                IMG3 = repmat(IMG3,[1 1 3]);
                IMG3(:,:,2:3) = repmat(bwperim(IMG3(:,:,1)),[1 1 2]);
                IMG(IMG3) = 1;
            end
    end
    function refreshButtons()
        for ii = 1:length(vs.buttons)
            set(hs.buttons(ii), 'Value',vs.buttons(ii).Value,'Enable',vs.buttons(ii).Enabled);
        end
    end
    
    function saveImages(varargin)
        filterSpec = {'*.png','PNG image';'*.bmp','Windows bitmap';'*.jpg','JPEG image'};
        [fileName, filePath, filterIndex] = uiputfile(filterSpec,'Save images as');
        if filterIndex
            views = {'_Axial','_Coronal','_Sagittal'};
            [~,fileName,ext] = fileparts(fileName);
            for ii = 1:3
                img = get(hs.subImgImage(ii),'CData');
                thisFileName = fullfile(filePath,[fileName, views{ii}, ext]);
                num = 1;
                while exist(thisFileName,'file');
                    thisFileName = fullfile(filePath,[fileName, views{ii},sprintf('%u',num), ext]);
                    num = num+1;
                end
                imwrite(img,thisFileName);
            end
        end
    end

    function roiEdit(varargin)
        hs.ROIHandle = [];
        if get(varargin{1},'Value')
            hroilist = findobj(hs.buttons,'Tag','ROIlist');
            curROI = get(hroilist,'Value');
            allROI = get(hroilist,'String');
            n = length(allROI);
            if varargin{4} % add
                set(findobj(hs.buttons,'Tag','ROIrem'),'Value',0);
                if curROI == 1 % Create new ROI
                    num = cell2mat(cellfun(@(x) sscanf(x,'ROI %i'),allROI(2:end),'UniformOutput',false));
                    num = setdiff(1:max(num)+1,num); num = [min(num) 1];
                    set(hroilist,'String',[allROI;{sprintf('ROI %01i',num(1))}],'Value',n+1);
                    vs.showROI = n;
                    v = vs.volumeSize;
                    ds.ROIVol(1:v(1),1:v(2),1:v(3),n) = false;
                end
                setCursor('pencil');
                vs.ROImode = 1;
            else % remove
                set(findobj(hs.buttons,'Tag','ROIadd'),'Value',0);
                if curROI == 1 % Create new ROI
                    set(varargin{1},'Value',0);
                else
                    setCursor('eraser');
                end
                vs.ROImode = -1;
            end
        else
            vs.ROImode = 0;
            setCursor('cross');
        end
    end
    function roiSelect(varargin)
        set(findobj(hs.buttons,'Tag','ROIadd','-or','Tag','ROIrem'),'Value',0);
        set(hs.fig, 'WindowButtonUpFcn','','WindowButtonMotionFcn','','WindowScrollWheelFcn',@figureScroll);
        set(hs.subImgROIcurve,'XData',NaN,'YData',NaN);
        vs.ROImode = 0;
        vs.showROI = get(varargin{1},'Value')-1;
        setCursor('cross');
        updateImages;
    end
    function plotROIs(varargin)
        vs.ROImode = 0;
        set(findobj(hs.buttons,'Tag','ROIadd','-or','Tag','ROIrem'),'Value',0);
        setCursor('cross');
        hroilist = findobj(hs.buttons,'Tag','ROIlist');
        allROI = get(hroilist,'String');
        n = length(allROI)-1;
        colors = hsv2rgb([(0:1/n:1-1/n)',randi([40 100],[n,1])/100,randi([40 100],[n,1])/100]);
        if n
            figure(999); cla; 
            set(gcf,'color','w','NumberTitle','off','Name','overlayVolume Plot');
            hold on;
            lg = zeros(n,4);
            for ii = 1:n
                mask = ds.ROIVol(:,:,:,ii);
                if isempty(ds.overVol)
                    data = reshape(ds.backVol(repmat(mask,[1 1 1 vs.numFrames(1)])),[],vs.numFrames(1));
                else
                    data = reshape(ds.overVol(repmat(mask,[1 1 1 vs.numFrames(2)])),[],vs.numFrames(2));
                end
                m = mean(data);
                s = std(data);
                c = colors(ii,:);
                lg(ii,1) = patch([1:length(m),length(m):-1:1],[m-s,m(end:-1:1)+s(end:-1:1)],'w','FaceColor',c,'EdgeColor','none','FaceAlpha',0.2);
                lg(ii,2) = plot([1:length(m),NaN,1:length(m)],[m-s,NaN,m+s],'Color',c);
                lg(ii,3) = plot(1:length(m),m,'Color',c,...
                    'LineWidth',2,'DisplayName',allROI{ii+1});
                lg(ii,4) = plot(1:length(m),m,'ko','Marker','o','MarkerFaceColor',c,...
                    'MarkerEdgeColor','k','LineStyle','none','MarkerSize',8); drawnow;
            end
           set(gca,'Children',lg(end:-1:1)); 
           hold off; legend(lg(:,3),allROI(2:end));
           axis([0 length(m)+1 -Inf Inf])
           set(gca,'LineWidth',2,'FontSize',14,'FontName','Arial'); box on;
        end
    end
    function saveROIs(varargin)
        hroilist = findobj(hs.buttons,'Tag','ROIlist');
        allROI = get(hroilist,'String');
        n = length(allROI)-1;
        answer = 'No';
        if n>0
            for ii = 1:n
                thisROI = ds.ROIVol(:,:,:,ii);
                thisName = checkName(allROI{ii+1},'export');
                W = evalin('base','whos'); %Check if the variable already exists
                if ismember(thisName,{W(:).name}) && ~strcmp(answer,'All');
                    answer = questdlg(sprintf('The ROI (''%s'') already exists, overwrite?',thisName),'Overwrite?','Yes','No','All','Yes');
                    if any(strcmp(answer,{'Yes','All'}))
                        assignin('base',thisName,thisROI);
                    else
                        continue
                    end
                else
                    assignin('base',thisName,thisROI);
                end
            end
        end
    end
    function loadROIs(varargin)
    end
    function name = checkName(name,what)
        % Will be used to check the name of ROIs, variables, etc.
        switch what
            case 'import'
                
            case 'export'
                name = strrep(name,' ','_');
        end
    end
    function trashROIs(varargin)
        hroilist = findobj(hs.buttons,'Tag','ROIlist');
        curROI = get(hroilist,'Value');
        allROI = get(hroilist,'String');
        if curROI>1
            vs.ROImode = 0;
            set(findobj(hs.buttons,'Tag','ROIadd','-or','Tag','ROIrem'),'Value',0);
            allROI(curROI) = [];
            set(hroilist,'Value',curROI-1,'String',allROI);
            ds.ROIVol(:,:,:,curROI-1) = [];
            vs.showROI = curROI-2;
            updateImages;
        end
    end
end