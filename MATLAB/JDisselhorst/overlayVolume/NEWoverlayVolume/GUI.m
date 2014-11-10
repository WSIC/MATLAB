
%%
function GUI(varargin)
if nargin<1, error('At least 1 input argument required!'); end
vs = []; % variables
hs = []; % handles
createFigure;
setMenuVariables;
ds = []; % data
parseInput(varargin);
createMenu;

    function setMenuVariables()
        % menus
        vs.iconPath = fullfile(fileparts(mfilename('fullpath')),'Icons');
        parents = {hs.ctrlMenu;hs.ctrlMenu;hs.ctrlMenu;hs.ctrlMenu; ...
                   hs.backMenu;hs.backMenu;hs.backMenu;hs.backMenu; ...
                   hs.overMenu;hs.overMenu;hs.overMenu;hs.overMenu; ...
                   hs.overMenu};
        names = {'layout1';'layout2';'layout3';'layout4'; ...
                 'bbback'; 'bback';  'fback';  'ffback'; ...
                 'bbover'; 'bover';  'fover';  'ffover'; ...
                 'test'};  % Used to control toggle behavior
        strings = {'';'';'';''; '';'';'';'';  '';'';'';''; {'a','b','c','d'}};
        icons = {'view1.png';'view2.png';'view3.png';'view4.png'; ...
                 'bb.png';   'b.png';    'f.png';    'ff.png'; ...
                 'bb.png';   'b.png';    'f.png';    'ff.png'; ...
                 ''};
        pos   = {10,10; 50,10; 90,10; 130,10;...
                 10,10; 50,10; 90,10; 130,10;...
                 10,10; 50,10; 90,10; 130,10;...
                 10,50};
        style = {'togglebutton'; 'togglebutton'; 'togglebutton'; 'togglebutton';...
                 'pushbutton'; 'pushbutton'; 'pushbutton'; 'pushbutton';...
                 'pushbutton'; 'pushbutton'; 'pushbutton'; 'pushbutton';...
                 'popupmenu'};
        enabled = {'on'; 'on'; 'on'; 'on';...
                   'on'; 'on'; 'on'; 'on';...
                   'on'; 'on'; 'on'; 'on';...
                   'on'};
        value   = {1;0;0;0;  0;0;0;1;  0;0;0;1;  1};
        func  = {{@changeLayout,1}; {@changeLayout,2}; {@changeLayout,3}; {@changeLayout,4}; ...
                 {@frameChange,1,-Inf}; {@frameChange,1,-1}; {@frameChange,1,1}; {@frameChange,1,Inf}; ...
                 {@frameChange,2,-Inf}; {@frameChange,2,-1}; {@frameChange,2,1}; {@frameChange,2,Inf}; ...
                 {}};
        vs.buttons = cell2struct([parents,names,strings,icons, pos,style,enabled,func,value],{'Parent','Name','String','Icon','X','Y','Style','Enabled','Function','Value'},2);
       
    end
    function createFigure()
        vs.menuWidth    = 180;
        vs.figPos       = [100,100,1200,500];
        vs.figTitle     = 'Test; J.A. Disselhorst (2014)';
        vs.menuColor    = [.7, .7, .7];
        vs.imageColor   = 'k';
        vs.borderColors = [0.3, 0.3, 0.3; 0.8, 0.0 0.0]; % Not selected / selected
        vs.activeLayout = 1; 
        vs.activeView   = [true, false, false];

        % Do not change variable below:
        vs.subImgPos        = [0,   0,   1/3, 1;   1/3, 0,   1/3, 1;   2/3, 0,   1/3, 1  ];
        vs.subImgPos(:,:,2) = [0,   0,   2/3, 1;   2/3, 0,   1/3, 1/2; 2/3, 1/2, 1/3, 1/2];
        vs.subImgPos(:,:,3) = [2/3, 1/2, 1/3, 1/2; 0,   0,   2/3, 1;   2/3, 0,   1/3, 1/2];
        vs.subImgPos(:,:,4) = [2/3, 1/2, 1/3, 1/2; 2/3, 0,   1/3, 1/2; 0,   0,   2/3, 1  ];
        vs.axDir = [[2,1,2]; [3,3,1]]; % Direction of the axes.
        
        hs.fig = figure('Position',vs.figPos,'MenuBar','figure','Name',vs.figTitle,'NumberTitle','off', ...
            'ResizeFcn',@resizeFigure,'WindowButtonDownFcn',@clickInFigure, ...
            'WindowScrollWheelFcn',@figureScroll,...
            'NextPlot','new','Interruptible','off', 'BusyAction','cancel'); 
        hs.menuPanel = uipanel('Parent',hs.fig,'BackgroundColor',vs.menuColor,'Units','pixels','Position',[0 0 10 10],'BorderType','none');
        hs.ctrlMenu  = uipanel('Parent',hs.menuPanel,'BackgroundColor',vs.menuColor,'Units','normalized','Position',[0 0 1 1/3],'BorderType','none');
        hs.backMenu  = uipanel('Parent',hs.menuPanel,'Title','Background','BackgroundColor',vs.menuColor,'Units','normalized','Position',[0 2/3 1 1/3],'BorderType','beveledin');
        hs.overMenu  = uipanel('Parent',hs.menuPanel,'Title','Overlay','BackgroundColor',vs.menuColor,'Units','normalized','Position',[0 1/3 1 1/3],'BorderType','beveledin');
        hs.imgPanel  = uipanel('Parent',hs.fig,'BackgroundColor',vs.menuColor,'Units','pixels','Position',[0 0 10 10],'BorderType','none');
        for ii = 1:3
            hs.subImgPanel(ii) = uipanel('Parent',hs.imgPanel,'BorderType','line','HighlightColor',vs.borderColors(vs.activeView(ii)+1,:),'BackgroundColor',vs.imageColor,'Units','normalized','Position',vs.subImgPos(ii,:,vs.activeLayout));
            hs.subImgAxes(ii)  = axes('Parent',hs.subImgPanel(ii),'Position',[0 0 1 1]); 
            hs.subImgImage(ii) = image(1:3,1:3,ones([3,3,3],'uint8')*50,'CDataMapping','scaled','Parent',hs.subImgAxes(ii));
            set(hs.subImgAxes(ii),'DataAspectRatio',[1 1 1]); % This has to be done *after* the image has been initialized.
            hold(hs.subImgAxes(ii),'on');
            hs.subImgPointer(ii) = plot(hs.subImgAxes(ii),1,1,'g-');
            hold(hs.subImgAxes(ii),'off');
            axis off
        end
        set(hs.fig,'NextPlot','new');
        hs.infoAxes = axes('Parent',hs.imgPanel,'Position',[0 0 1 1],'visible','off','HitTest','off','HandleVisibility','off');
        hs.infoText = text('Parent',hs.infoAxes,'HandleVisibility','off','HitTest','off','Position',[0,1],'VerticalAlignment','Top','Color','w');
        setCursor('cross')
    end
    
    function createMenu()   % <- Fix this!
        for ii = 1:length(vs.buttons)
            if ~isempty(vs.buttons(ii).Icon)
                icon = imread(fullfile(vs.iconPath,vs.buttons(ii).Icon));
            else
                icon = zeros(16,40);
            end
            vs.buttons(ii).Handle = uicontrol('Parent',vs.buttons(ii).Parent,'Style',vs.buttons(ii).Style,...
                'Position',[vs.buttons(ii).X, vs.buttons(ii).Y, size(icon,2)+4, size(icon,1)+4], ...
                'Enable',vs.buttons(ii).Enabled,'Callback',vs.buttons(ii).Function, ...
                'Value', vs.buttons(ii).Value,'Tag',vs.buttons(ii).Name,'cdata',icon,'String',vs.buttons(ii).String);
        end
    end

    function frameChange(varargin)
        vs.currentFrame(varargin{3}) = vs.currentFrame(varargin{3})+varargin{4};
        vs.currentFrame = min([vs.numFrames; max([[1 1]; vs.currentFrame])]);
        updateImages;
    end
    function parseInput(input)  % <- fix this.
        % currently there is no input checking
        ds.backVol = input{1};
        vs.volumeSize = [size(ds.backVol), 1]; vs.volumeSize = vs.volumeSize(1:3); % The size of the volume (the 1 is added for 2D cases).
        vs.currentPoint = round(vs.volumeSize/2);
        try ds.overVol = input{2};             % Overlay volume
        catch, ds.overVol = []; set(hs.overMenu,'Visible','off'); end
        vs.numFrames = [size(ds.backVol,4), size(ds.overVol,4)];
        
        vs.currentFrame = [size(ds.backVol,4), size(ds.overVol,4)];
        vs.aspectRatio  = [1 1 1];             % data aspect ratio.
        vs.backMap      = gray(256);             % Color map for the background 
        vs.backRange    = getRange(ds.backVol);             % background image range [min, max]
        vs.overMap      = jet(256);             % Color map for the overlay
        vs.overRange    = getRange(ds.overVol);             % Overlay image range [min, max]
        vs.maskRange    = vs.overRange;             % Overlay will only be shown for values in the maskRange [lower, upper]
        vs.alpha        = 0.5;             % Transparency value [0<=alpha<=1]
        
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
            disp('Click in menu');
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
                    vs.currentPoint = CP;
                    updateImages(find(~type)); % Update the images of the other figures.
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
    function mouseMove(~,~,type)
        % MOUSEMOVE is used to change the contrast and brightness
        % This function is only triggered when the user clicks and
        % holds the right of middle mouse button.
        newMouse = get(hs.fig,'CurrentPoint');
        switch type
            case 'back'
                mouseMove = newMouse - vs.mousePoint;
                Value = vs.backRange;
                Value = Value + mouseMove*0.01*diff(Value);
                if Value(1)<Value(2)                            % The first should be smaller than the second
                    vs.backRange = Value;                       % Set the values.
                    updateImages;                               % Update the images.
                    %showColorBar(obj,'UpdateIfExist');          % Update the colorbar if it exists.
                end
            case 'over'
                if ~isempty(vs.overRange)
                    mouseMove = newMouse - vs.mousePoint;
                    Value = vs.overRange;
                    Value = Value + mouseMove*0.01*diff(Value);
                    if Value(1)<Value(2)                            % The first should be smaller than the second
                        vs.overRange = Value;                       % Set the values.
                        updateImages;                               % Update the images.
                        %showColorBar(obj,'UpdateIfExist');          % Update the colorbar if it exists.
                    end
                end
        end
        vs.mousePoint = newMouse;
    end

    function mouseUp(varargin)
        setCursor('cross')
        set(hs.fig, 'WindowButtonUpFcn','','WindowButtonMotionFcn','');
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
    function [type, position] = determineClickPosition(currentPoint)
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
            end
        end
    end

    function resizeFigure(figureHandle,varargin)
        position = get(figureHandle,'Position');
        set(hs.menuPanel,'Position',[1 1 vs.menuWidth position(4)]);
        set(hs.imgPanel,'Position',[vs.menuWidth+1, 1, position(3)-vs.menuWidth, position(4)]);
        vs.imgPanelPos = [position(3)-vs.menuWidth, position(4)];

        % Get the size of all subimages [1: y,z. 2: x,z. 3: y,x]:
        a = vs.volumeSize([2,3;1,3;2,1]);
        % Get the size of displays, obtain ratios
        showratio = vs.subImgPos(:,3:4,vs.activeLayout).*repmat(vs.imgPanelPos,[3,1]);
        showratio = showratio(:,1)./showratio(:,2);
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
            try
                IMG = provideImage(views(ii));
                set(hs.subImgImage(views(ii)),'CData',IMG); 
            end
        end
        for ii = 1:3
            x = vs.currentPoint(vs.axDir(1,ii));
            y = vs.currentPoint(vs.axDir(2,ii));
            set(hs.subImgPointer(ii),'XData',[-1000,1000,NaN,x,x],'YData',[y,y,NaN,-1000,1000])
        end
        set(hs.infoText,'String',sprintf(' %1.0f / %1.0f / %1.0f',vs.currentPoint(1),vs.currentPoint(2),vs.currentPoint(3)))
        %updateMarkers(obj,sync);
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
            set(hs.subImgPointer(ii),'XData',[-1000,1000,NaN,x,x],'YData',[y,y,NaN,-1000,1000])
            assignin('base','hs',hs);
        end
    end
    function refreshButtons()
        for ii = 1:length(vs.buttons)
            set(vs.buttons(ii).Handle, 'Value',vs.buttons(ii).Value,'Enable',vs.buttons(ii).Enabled);
        end
    end

    function changeLayout(varargin)
        vs.activeLayout = varargin{3};
        for ii = 1:3
            set(hs.subImgPanel(ii),'Position',vs.subImgPos(ii,:,vs.activeLayout));
        end
        for ii = 1:4
            vs.buttons(strcmp({vs.buttons.Name},sprintf('layout%1.0f',ii))).Value = (ii == varargin{3});
        end
        assignin('base','vs',vs);
        refreshButtons;
        resizeFigure(hs.fig);
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
                 case 'pen'
                     pointer = [0 0 0 0 0 0 0 0 0 0 0 2 1 2 0 0;0 0 0 0 0 0 0 0 0 0 2 1 1 1 2 0;0 0 0 0 0 0 0 0 0 2 2 1 1 1 1 2;0 0 0 0 0 0 0 0 2 1 1 2 1 1 1 1;0 0 0 0 0 0 0 2 1 1 1 1 2 1 1 2;0 0 0 0 0 0 2 1 1 1 1 1 1 2 2 0;0 0 0 0 0 2 1 1 1 1 1 1 1 2 0 0;0 0 0 0 2 1 1 1 1 1 1 1 2 0 0 0;0 0 0 2 1 1 1 1 1 1 1 2 0 0 0 0;0 0 2 1 1 1 1 1 1 1 2 0 0 0 0 0;0 2 1 1 1 1 1 1 1 2 0 0 0 0 0 0;2 2 1 1 1 1 1 1 2 0 0 0 0 0 0 0;2 1 2 1 1 1 1 2 0 0 0 0 0 0 0 0;2 1 1 2 1 1 2 0 0 0 0 0 0 0 0 0;2 1 1 1 2 2 0 0 0 0 0 0 0 0 0 0;2 2 2 2 2 0 0 0 0 0 0 0 0 0 0 0;];
                     spot = [16 1];
                 case 'cross'
                    pointer = [0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;2 2 2 2 2 2 2 0 2 2 2 2 2 2 2 0;1 1 1 1 1 1 0 0 0 1 1 1 1 1 1 0;2 2 2 2 2 2 2 0 2 2 2 2 2 2 2 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 2 1 2 0 0 0 0 0 0 0;0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;];
                    spot = [7,7];
            end
            pointer(~pointer) = NaN;
            set(hs.fig,'Pointer','custom','PointerShapeCData',pointer,'PointerShapeHotSpot',spot)
        end

end