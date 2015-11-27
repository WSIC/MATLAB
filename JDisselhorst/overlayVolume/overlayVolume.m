classdef overlayVolume < handle
    %OVERLAYVOLUME displays a 3D volume in slices with optional overlay.
    %
    % Usage: 
    % - OVERLAYVOLUME(VOL1, VOL2); displays a 3D datasets VOL1, and an
    %   overlay dataset VOL2, with default display settings. 4D datasets
    %   are also supported, and will display an additional scrollbar.
    % - OVERLAYVOLUME(VOL1); displays one 3D dataset VOL1
    % - OVERLAYVOLUME(VOL1,VOL2,optionalparameters); displays 3D datasets
    %   VOL1 and VOL2 with addional user specified display settings.
    %   Settings should be provided as parameter name - value pairs.
    % - After initialization, many settings can be changed using the
    %   context menus or the setPROPERTY functions, see below.
    % - showColorBar shows the colorbars, see example below.
    % - dockWindows will the dock the three orthogonal views in one window.
    %
    % Optional parameters:
    % - backRange:   display range of background data as [lower, upper]
    %                default: [lowest value in data, highest value]
    % - backMap:     colormap of the background as Nx3 matrix
    %                default: gray(256)
    % - overRange:   display range of overlay data as [lower, upper]
    %                default: [lowest value in data, highest value]
    % - overMap:     colormap of the overlay as Nx3 matrix
    %                default: hot(256)
    % - alpha:       transparency of the overlay as scalar between 0 and 1
    %                default: 0.4
    % - maskRange:   range of values in the overlay that will be
    %                displayed as [LO, HI]. I.e., all values lower than LO,
    %                and all values higher than HI will not be shown.
    %                default: []
    % - aspectRatio: aspect ratio of the three dimensions as [x,y,z]
    %                default: [1 1 1]
    % - colorbar:    show the colorbar window [1: on, 0: off]
    % - dockWindows: dock individual views in one window [1: yes, 0: no]
    % - title:       Adds a name to the windows [char array]
    % - sync:        Synchronize the position of several overlayVolumes
    %                [1: synchronize, 0: do not synchronize (default)]
    %
    % Available setPROPERTY functions:
    % - setBackVolume:  set the background volume, should be the same size.
    % - setBackRange:   set the background display range.
    % - setBackMap:     set the background colormap
    % - setOverVolume:  set the overlay volume
    % - setOverRange:   set the overlay display range
    % - setOverMap:     set the overlay colormap
    % - setAlpha:       set the overlay transparency
    % - setMaskRange:   set the overlay mask range
    % - setAspectRatio: set the aspect ratio of the volumes
    % 
    % Examples:
    % load('mri'); VOL1 = double(squeeze(D)); % load matlab sample data
    % VOL2 = (VOL1>20).*rand(size(VOL1));     % create a random overlay
    % OVERLAYVOLUME(VOL1,VOL2,'alpha',0.2);   % show volumes, alpha=0.2
    % OVERLAYVOLUME(VOL1,VOL2,'backMap',bone(256),'overMap',hot(64));
    % OVERLAYVOLUME(VOL1,[],'aspectRatio',[1 1 5]);
    % OVERLAYVOLUME(VOL1,[],'dockWindows',1)
    % OV = OVERLAYVOLUME(VOL1,VOL2);          % start with default settings
    % OV.showColorBar;                        % show the colorbars.
    % OV.dockWindows;
    % OV.setOverMap(jet(256));                % set the overlay color map
    % OV.setAspectRatio([1 1 5]);             % set the aspect ratio
    % OV.setOverVolume([]);                   % remove the overlay volume
    % 
    % Acknowledgement:
    % - "ct3"        by "tripp",      FileExchange ID: #32173
    % - "OverlayImg" by "Jochen Rau", FileExchange ID: #26790
    %
    % J.A. Disselhorst
    % Werner Siemens Imaging Center, http://www.preclinicalimaging.org/
    % University of Tuebingen, Germany.
    % 2014.03.03
    %
    %
    % TODO:
    % - Colorbar: In the colorbarfigure, the colorbar itself should not be
    %   updated all the time, only when the current colormap will be
    %   changed. Same holds for the lines, etc. 
    % - Rotation does not work for 2D images.
    % - Rotation with left/right arrow does not keep focus on right window.
    % - With the roi is resized or moved, the mouse click should not update
    %   the current position.
    %
    % Disclaimer:
    % THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
    % KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
    
    properties
        aspectRatio  = [];             % data aspect ratio.
        backVol      = [];             % Background volume
        backMap      = [];             % Color map for the background 
        backRange    = [];             % background image range [min, max]
        overVol      = [];             % Overlay volume
        overMap      = [];             % Color map for the overlay
        overRange    = [];             % Overlay image range [min, max]
        maskRange    = [];             % Overlay will only be shown for values in the maskRange [lower, upper]
        alpha        = [];             % Transparency value [0<=alpha<=1]
        title        = 'overlayVol';   % Window name.
        currentPoint = [];             % current point shown
    end 
    properties (SetAccess = private, Hidden = true)
        %------Volume properties-------%
        volumeSize   = [];             % size of the volume
        numFrames    = [1 1];          % number of frames for background and overlay
        %currentPoint = [];             % current point shown
        currentFrame = [1 1];          % The current frame
        mousePoint   = [];             % The position of the last mouse click.
        sync         = [];             % synchronize with other overlayvolume figures. 
        %-----------Handles------------%
        figsHandles  = [];             % handles to the figures.
        imgsHandles  = [];             % handles to the images
        lineHandles  = [];             % handles to the lines
        cursHandles  = [];             % handles to the cursor tool tips.
        colorBarFig  = [];             % handle to the optional colorbar figure.
        frameFig     = [];             % handle to the frame selection figure.
        %-----Rotation properties------%
        backOriginal = [];             % Used during rotation, keeps the original background data.
        overOriginal = [];             % Used during rotation, keeps the original overlay data.
        rotation     = [];             % The angles of rotation
        %--------ROI Properties--------%
        ROIEnabled   = 0;              % is it active or not
        ROIPoints    = [];             % the temporay points, during drawing.
        ROIHandle    = [];             % the handle to the temporary points.
        ROIStyle     = [];             % the style of ROI: freehand, square, circle, ...
        ROIType      = [];             % the type of drawing, adding (1) or removing (0)
        ROIEditH     = [];             % the handles to the edit boxes

    end
    properties (SetObservable, GetObservable)
        savedROIs                      % This will hold information about saved Regions-of-interest
    end
    methods(Static)
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
        function makeMenus(figHandles,obj)
            % MAKEMENUS creates menus in the menubar and context menus
            % First the context menu is created, then the menu in the
            % menubar for each of the three figures. In the end, a custom
            % rotation function is defined.
            for curFig = figHandles
                figure(curFig);
                cMaps = {'Gray','Jet','HSV','Hot','Cool','Spring','Summer','Autumn','Winter','Bone','Copper','Pink','Lines','Colorcube','Flag','Prism','Invert'};
                cmenu = uicontextmenu;
                fmenu = uimenu(curFig,'label','overlayVolume');
                for MENU = [cmenu,fmenu]
                    backMenu = uimenu(MENU, 'label','Background');
                    uimenu(backMenu, 'label','Set range','Callback',{@overlayVolume.menuAction,obj,'backRange'});
                    backMapMenu = uimenu(backMenu, 'label','Colormap');
                    for ii=1:length(cMaps)
                        uimenu(backMapMenu,'label',cMaps{ii},'Callback',{@overlayVolume.menuAction,obj,'backMap',cMaps{ii}});
                    end

                    overMenu = uimenu(MENU, 'label','Overlay');
                    uimenu(overMenu, 'label','Set range','Callback',{@overlayVolume.menuAction,obj,'overRange'});
                    overMapMenu = uimenu(overMenu, 'label','Colormap');
                    for ii=1:length(cMaps)
                        uimenu(overMapMenu,'label',cMaps{ii},'Callback',{@overlayVolume.menuAction,obj,'overMap',cMaps{ii}});
                    end
                    uimenu(overMenu,'label','Set alpha','Callback',{@overlayVolume.menuAction,obj,'alpha'});
                    uimenu(overMenu,'label','Set mask range','Callback',{@overlayVolume.menuAction,obj,'maskRange'});

                    uimenu(MENU,'label','Set aspect ratio','Callback',{@overlayVolume.menuAction,obj,'aspectRatio'});
                    uimenu(MENU,'label','Show colorbar','Callback',{@overlayVolume.menuAction,obj,'colorBar'},'Separator','on');
                    uimenu(MENU,'label','Show framebar','Callback',{@overlayVolume.menuAction,obj,'frameBar'});
                    uimenu(MENU,'label','Synchronize','Callback',{@overlayVolume.menuAction,obj,'sync'});
                    drawroi = uimenu(MENU,'label','Draw ROI','Separator','on');
                    uimenu(drawroi,'label','Freehand ROI','Callback',{@overlayVolume.menuAction,obj,'ROI','Freehand'},'Tag','ROImenu');
                    uimenu(drawroi,'label','Square ROI','Callback',{@overlayVolume.menuAction,obj,'ROI','Square'},'Tag','ROImenu');
                    uimenu(drawroi,'label','Circle ROI','Callback',{@overlayVolume.menuAction,obj,'ROI','Circle'},'Tag','ROImenu');
                    uimenu(MENU,'label','Edit ROI','Callback',{@overlayVolume.menuAction,obj,'ROI','Edit'},'Tag','ROImenu');
                    uimenu(MENU,'label','Add ROI frame','Callback',{@overlayVolume.menuAction,obj,'ROI','Add'});
                    uimenu(MENU,'label','Delete ROI frame','Callback',{@overlayVolume.menuAction,obj,'ROI','Del'});
                    uimenu(MENU,'label','Save ROIs','Callback',{@overlayVolume.menuAction,obj,'ROI','Save'});
                    uimenu(MENU,'label','Show curve','Callback',{@overlayVolume.menuAction,obj,'ROI','Curve'});
                    uimenu(MENU,'Separator','on','label','Show Projection (radon) [warning: slow!]','Callback',{@overlayVolume.menuAction,obj,'projection'});
                    uimenu(MENU,'label','Export this image','Callback',{@overlayVolume.menuAction,obj,'exportImage'});
                end
                set(curFig,'uicontextmenu',cmenu);
                h = rotate3d(curFig);
                set(h,'ActionPreCallback',{@overlayVolume.rotationStart,h});
                set(h,'ActionPostCallback',{@overlayVolume.rotationEnd,obj});
                set(curFig,'WindowKeyPressFcn',{@overlayVolume.keyPress,obj});
            end
        end
        function menuAction(varargin)
            % MENUACTION is called whenever a menuitem is selected.
            % The different menuitems respond differently, some require
            % additional user input, others change the colormap or execute
            % a function.
            obj = varargin{3};
            switch varargin{4}
                case 'backMap'
                    if strcmpi(varargin{5},'invert')
                        obj.setBackMap(obj.backMap(end:-1:1,:));
                    else
                        eval(sprintf('obj.setBackMap(%s(256));',lower(varargin{5})));
                    end
                case 'overMap'
                    if strcmpi(varargin{5},'invert')
                        obj.setOverMap(obj.overMap(end:-1:1,:));
                    else
                        eval(sprintf('obj.setOverMap(%s(256));',lower(varargin{5})));
                    end
                case 'aspectRatio'
                    Default = obj.aspectRatio;
                    Default = arrayfun(@num2str, Default/min(Default),'UniformOutput',false);
                    answer = inputdlg({'X:','Y:','Z:'},'Image aspect ratio',1,Default);
                    if ~isempty(answer)
                        answer = str2double(answer); 
                        answer = answer/min(answer); 
                        setAspectRatio(obj,answer); 
                    end
                case 'backRange'
                    Default = arrayfun(@num2str, obj.backRange,'UniformOutput',false);
                    answer = inputdlg({'Lower bound:','Upper bound:'},'Background display range',1,Default);
                    setBackRange(obj,str2double(answer)');
                case 'overRange'
                    Default = arrayfun(@num2str, obj.overRange,'UniformOutput',false);
                    try answer = inputdlg({'Lower bound:','Upper bound:'},'Overlay display range',1,Default);
                    setOverRange(obj,str2double(answer)'); end
                case 'maskRange'
                    Default = arrayfun(@num2str, obj.maskRange,'UniformOutput',false);
                    if isempty(Default), Default = {'0','1'}; end;
                    answer = inputdlg({'Lower bound:','Upper bound:'},'Overlay mask range',1,Default);
                    setMaskRange(obj,str2double(answer)');
                case 'alpha'
                    Default = {num2str(obj.alpha)};
                    try answer = inputdlg('Alpha:','Transparency',1,Default);
                    setAlpha(obj,str2double(answer)); end
                case 'colorBar'
                    showColorBar(obj);
                case 'frameBar'
                    showFrameFig(obj);
                case 'toggleROI'
                    toggleROI(obj);
                case 'saveROI'
                    saveROI(obj);
                case 'deleteROI'
                    deleteROI(obj);
                case 'ROI'
                    figs = obj.figsHandles; figs = figs(ishandle(figs));
                    set(findall(figs,'tag','ROImenu'),'Checked','off')
                    obj.ROIEnabled = ~(obj.ROIEnabled & strcmpi(varargin{5},obj.ROIStyle));
                    if obj.ROIEnabled
                        obj.ROIStyle = varargin{5};
                        % Is there already an overlay?
                        if isempty(obj.ROIType) && ~isempty(obj.overVol)
                            if islogical(obj.overVol)
                                button = questdlg('An overlay volume already exists','Overlay exists','Use','Add','Cancel','Cancel');
                            else
                                button = questdlg('An overlay volume already exists','Overlay exists','Overwrite','Cancel','Cancel');
                            end
                            if strcmpi(button,'Overwrite')
                                obj.overVol = false(obj.volumeSize);
                                obj.overRange = [0, 1.2];
                                obj.overMap = jet(256);
                                obj.maskRange = [0.5 1.5];
                                varargin{5} = 'new';
                                obj.numFrames(2) = 1;
                                obj.currentFrame(2) = 1;
                            elseif strcmpi(button,'Add')
                                obj.overVol(:,:,:,end+1) = false(obj.volumeSize); N = size(obj.overVol,4);
                                obj.numFrames(2) = N;
                                obj.currentFrame(2) = N;
                                varargin{5} = 'new';
                            elseif strcmpi(button,'Cancel')
                                obj.ROIEnabled = 0;
                                return;
                            end % 'Use' needs no special action.
                        end
                        if isempty(obj.overVol)
                            obj.overVol = false(obj.volumeSize);
                            obj.overRange = [0, 1.2];
                            obj.overMap = jet(256);
                            obj.maskRange = [0.5 1.5];
                        end
                        overlayVolume.setCursor(figs,'pen');
                        set(findall(figs,'label',sprintf('%s ROI',varargin{5})),'Checked','on')
                        delete(obj.ROIEditH);
                        obj.ROIEditH = [];
                        if strcmpi(varargin{5},'Edit')
                            obj.ROIEnabled = 2;
                            overlayVolume.editROI(obj);
                        elseif strcmpi(varargin{5},'Add')
                            obj.overVol(:,:,:,end+1) = false(obj.volumeSize); N = size(obj.overVol,4);
                            obj.numFrames(2) = N;
                            obj.currentFrame(2) = N;
                            showFrameFig(obj);
                            updateImages(obj);
                            obj.ROIEnabled = false;
                            overlayVolume.setCursor(figs,'cross');
                        elseif strcmpi(varargin{5},'Del')
                            if obj.numFrames(2)>1
                                obj.overVol(:,:,:,obj.currentFrame(2)) = []; N = size(obj.overVol,4);
                                obj.numFrames(2) = N;
                                obj.currentFrame(2) = min([N, obj.currentFrame(2)]);
                                showFrameFig(obj);
                            else
                                obj.overVol = false(obj.volumeSize);
                            end
                            obj.ROIEnabled = false;
                            overlayVolume.setCursor(figs,'cross');
                            updateImages(obj);
                        elseif strcmpi(varargin{5},'new')
                            obj.ROIEnabled = 0;
                            showFrameFig(obj);
                            updateImages(obj);
                            overlayVolume.setCursor(figs,'cross');
                        elseif strcmpi(varargin{5},'save')
                            if islogical(obj.overVol)
                                varName = inputdlg('Variable name','Choose name',1,{'ROI'});
                                if ~isempty(varName)
                                    assignin('base',varName{1},obj.overVol);
                                end
                            end
                        elseif strcmpi(varargin{5},'curve')
                            obj.ROIEnabled = 0;
                            overlayVolume.setCursor(figs,'cross');
                            updateImages(obj);
                            if obj.numFrames(1)>1 && islogical(obj.overVol)
                                figure('NumberTitle', 'off'); cla; hold on;
                                colors = hsv(obj.numFrames(2));
                                N = obj.numFrames(1);
                                plotHandles = zeros(1,obj.numFrames(2));
                                for ii = 1:obj.numFrames(2)
                                    mask = obj.overVol(:,:,:,ii);
                                    mask = repmat(mask,[1 1 1 N]);
                                    curve = obj.backVol(mask);
                                    curve = reshape(curve,[],N);
                                    if size(curve,1)>1
                                        test = isfinite(curve);
                                        badPoints = sum(~test(:));
                                        if badPoints
                                            means = zeros(1,N); stds = means;
                                            for jj = 1:N
                                                means(jj) = mean(curve(test(:,jj),jj));
                                                stds(jj) = std(curve(test(:,jj),jj));
                                            end
                                            fprintf('Non finite numbers have been removed (%1.0f)\n',badPoints);
                                        else
                                            means = mean(curve);
                                            stds = std(curve);
                                        end
                                        if size(curve,1)>1
                                            xs = [1:N; 1:N; nan(1,N); (1:N)-0.1; (1:N)+0.1; nan(1,N); (1:N)-0.1; (1:N)+0.1; nan(1,N)];
                                            stds = [means+stds; means-stds; nan(1,N); ...
                                                    means+stds; means+stds; nan(1,N); ...
                                                    means-stds; means-stds; nan(1,N)];
                                            plot(xs(:),stds(:),'Color',colors(ii,:),'LineStyle','-');
                                            plotHandles(ii) = plot(1:N,means,'Color',colors(ii,:),'Marker','o','LineWidth',2,'MarkerEdgeColor','none','MarkerFaceColor',colors(ii,:));
                                        end
                                    elseif size(curve,1)==1
                                        plotHandles(ii) = plot(1:N,curve,'Color',colors(ii,:),'Marker','o','LineWidth',2,'MarkerEdgeColor','none','MarkerFaceColor',colors(ii,:));
                                    else
                                        plotHandles(ii) = plot(NaN,NaN,'Marker','s','Color','k','LineStyle','none');
                                    end
                                end
                                grid on;
                                set(gca,'FontSize',14,'FontName','Helvetica','FontWeight','bold', ...
                                        'Box','on','LineWidth',2,'Position',[0.05 0.05 0.90 0.90],'YMinorTick','off','XMinorTick','off');
                                set(gcf,'renderer','zbuffer','Color','w')
                                try set(gca,'LooseInset',get(gca,'TightInset')); end % Undocumented MATLAB
                                axis([0 N+1 obj.backRange(1) obj.backRange(2)])
                                hold off
                                legend(plotHandles,arrayfun(@(x) sprintf('ROI %1.0f',x), 1:obj.numFrames(2), 'unif', 0))
                            end
                        end
                        obj.ROIType = 1;
                    else
                        delete(obj.ROIEditH);
                        obj.ROIEditH = [];
                        overlayVolume.setCursor(figs,'cross');
                    end
                case 'projection'
                    overlayVolume.projection(obj,find(obj.figsHandles==gcbf));
                case 'exportImage'
                    im = get(obj.imgsHandles(obj.figsHandles==gcbf),'CData');
                    [FileName,PathName] = uiputfile({'*.png','PNG image';'*.jpg','JPEG image';'*.bmp','BMP image'},'Save image','image');
                    if FileName
                        imwrite(im,fullfile(PathName,FileName));
                    end
                case 'sync'
                    figs = obj.figsHandles; figs = figs(ishandle(figs));
                    if obj.sync
                        obj.sync = 0;
                        set(findall(figs,'label','Synchronize'),'Checked','off')
                        set(obj.figsHandles(ishandle(obj.figsHandles)),'Tag','OverlayVolume');
                    else
                        obj.sync = 1;
                        set(findall(figs,'label','Synchronize'),'Checked','on')
                        set(obj.figsHandles(ishandle(obj.figsHandles)),'Tag','OverlayVolumeSync');
                    end
            end
        end
        function editROI(obj)
            BWN = bwconncomp(obj.overVol(:,:,:,obj.currentFrame(2)));
            N = BWN.NumObjects;
            if N
                for ii = 1:N
                    pixels = BWN.PixelIdxList{ii}; if length(pixels)==1, pixels = [pixels;pixels]; end
                    [X,Y,Z] = ind2sub(obj.volumeSize,pixels);
                    x = [min(X(:))-0.5 max(X(:))+0.5]; x(3:4) = [NaN mean(x)];
                    y = [min(Y(:))-0.5 max(Y(:))+0.5]; y(3:4) = [NaN mean(y)];
                    z = [min(Z(:))-0.5 max(Z(:))+0.5]; z(3:4) = [NaN mean(z)];
                    roiHandle = overlayVolume.ROIEditBox(obj,x,y,z);
                    set(roiHandle(ishandle(roiHandle)),'UserData',[X,Y,Z]);
                    obj.ROIEditH(1:3,end+1) = roiHandle;
                end
            else
                overlayVolume.menuAction([],[],obj,'ROI','Edit');
            end
        end
        function roiHandles = ROIEditBox(obj,X,Y,Z)
            handles = obj.figsHandles;
            handles = handles(ishandle(handles));
            roiHandles = zeros(1,3)/0;
            color = 'r';
            for ii = 1:length(handles)
                axs = findobj(handles(ii),'Type','axes');
                hold(axs,'on')
                if handles(ii) == obj.figsHandles(1)
                    roiHandles(1) = plot(axs,Y([1,2,2,1,1,3,4]),Z([1,1,2,2,1,3,4]),'Marker','s','linestyle','-','Color',color,'MarkerFaceColor','w');
                    set(roiHandles(1),'ButtonDownFcn',{@overlayVolume.ROIClick,obj})
                elseif handles(ii) == obj.figsHandles(2)
                    roiHandles(2) = plot(axs,X([1,2,2,1,1,3,4]),Z([1,1,2,2,1,3,4]),'Marker','s','linestyle','-','Color',color,'MarkerFaceColor','w');
                    set(roiHandles(2),'ButtonDownFcn',{@overlayVolume.ROIClick,obj})
                else
                    roiHandles(3) = plot(axs,Y([1,2,2,1,1,3,4]),X([1,1,2,2,1,3,4]),'Marker','s','linestyle','-','Color',color,'MarkerFaceColor','w');
                    set(roiHandles(3),'ButtonDownFcn',{@overlayVolume.ROIClick,obj})
                end
                hold off
                set(handles(ii),'NextPlot','new');
            end
        end
        function ROIClick(roiHandle,~,obj)
            X = get(roiHandle,'XData')';
            Y = get(roiHandle,'YData')';
            LN = [X,Y];
            axs = get(roiHandle,'Parent');
            fig = get(axs,'Parent');
            CP = obj.currentPoint; 
            ROI = get(roiHandle,'UserData');
            if fig==obj.figsHandles(1)
                mini = min(ROI(:,[3,2]),[],1)-1;
                A = ROI(ROI(:,1)==CP(1),3); B = ROI(ROI(:,1)==CP(1),2);
                IMG = zeros(max(ROI(:,[3,2]))-mini);            
            elseif fig==obj.figsHandles(2)
                mini = min(ROI(:,[3,1]),[],1)-1;
                A = ROI(ROI(:,2)==CP(2),3); B = ROI(ROI(:,2)==CP(2),1);
                IMG = zeros(max(ROI(:,[3,1]))-mini);
            else
                mini = min(ROI(:,[1,2]),[],1)-1;
                A = ROI(ROI(:,3)==CP(3),1); B = ROI(ROI(:,3)==CP(3),2);
                IMG = zeros(max(ROI(:,[1,2]))-mini);
            end
            if ~isempty(A) && ~isempty(B)
                IMG(sub2ind(size(IMG),A-mini(1),B-mini(2)))=1;
                [x1,y1] = ind2sub(size(IMG),find(IMG));
                x1 = [min(x1)-0.5, max(x1)+0.5];
                y1 = [min(y1)-0.5, max(y1)+0.5];
                x1 = [x1(1), x1(2), x1(2), x1(1), x1(1)];
                y1 = [y1(1), y1(1), y1(2), y1(2), y1(1)];
                hold(axs,'on')
                patchHandle = patch(y1'+mini(2),x1'+mini(1),'','FaceColor',get(roiHandle,'Color'),...
                    'EdgeColor','none','FaceAlpha',0.3,'Parent',axs,'HitTest','off',...
                    'UserData',{(y1'-0.5)/size(IMG,2),(x1'-0.5)/size(IMG,1)});
                hold off
            else
                patchHandle = patch([NaN NaN],[NaN NaN],'','Parent',axs,'UserData','');
            end
            CP = get(axs,'CurrentPoint');
            CP = CP(1,1:2);
            dist = (LN-repmat(CP,length(X),1)).^2;
            dist2 = sqrt(sum(dist,2));
            dist2 = dist2./max(dist2(:));
            mini = min(dist2);
            point = find(dist2==mini,1,'first');
            if mini>0.05
                point = {'T','B','R','L'};
                dist = [mean(dist([3,4],2)), mean(dist([1,2],2)), mean(dist([2,3],1)), mean(dist([1,4],1))];
                point = point{dist==min(dist)};
            end
            set(fig,'WindowButtonUpFcn',{@overlayVolume.ROIUp,roiHandle,patchHandle,obj},...
                'WindowButtonMotionFcn',{@overlayVolume.ROIMove,roiHandle,patchHandle,axs,point},...
                'WindowScrollWheelFcn','','NextPlot', 'new')
        end
        function ROIMove(~,~,roiHandle,patchHandle,axs,point)
            X = get(roiHandle,'XData');
            Y = get(roiHandle,'YData');
            CP = get(axs,'CurrentPoint'); CP = CP(1,1:2);
            
            switch point
                case 1, X([1,4,5]) = CP(1); Y([1,2,5]) = CP(2);
                case 2, X([2,3]) = CP(1); Y([1,2,5]) = CP(2);
                case 3, X([2,3]) = CP(1); Y([3,4]) = CP(2);
                case 4, X([1,4,5]) = CP(1); Y([3,4]) = CP(2);
                case 7
                    X(1:5) = X(1:5) + CP(1)-mean(X(1:4));
                    Y(1:5) = Y(1:5) + CP(2)-mean(Y(1:4));
                case 'L', X([1,4,5]) = CP(1);
                case 'R', X([2,3]) = CP(1);
                case 'T', Y([3,4]) = CP(2);
                case 'B', Y([1,2,5]) = CP(2);
            end
            X(7) = mean(X(1:4)); Y(7) = mean(Y(1:4));
            set(roiHandle,'XData',X,'YData', Y);
            P1 = X([1,3]); P2 = Y([1,3]);
            YX = get(patchHandle,'UserData');
            if ~isempty(YX)
                XData = (YX{1}*(P1(2)-P1(1)))+P1(1);
                YData = (YX{2}*(P2(2)-P2(1)))+P2(1);
                set(patchHandle,'XData',XData,'YData',YData);
            end
        end
        function ROIUp(fig,~,roiHandle,patchHandle,obj)
            % Currently, only translation and resize are possible, rotation
            % is not yet implemented.
            set(fig,'WindowButtonUpFcn','','WindowButtonMotionFcn','',...
                'WindowScrollWheelFcn',{@overlayVolume.figureScroll,obj});
            ROI = get(roiHandle,'UserData'); 
            p = min(ROI)-0.5;
            p(2,1:3) = max(ROI)+0.5;
            B = get(roiHandle,'XData'); B = B([1,3]);
            A = get(roiHandle,'YData'); A = A([1,3]);
            after = [A;B]';
            newROI = false(obj.volumeSize);
            if fig == obj.figsHandles(1) % Z / Y
                before = [p(:,3),p(:,2)];
                T = zeros(3,3); T([1,5,9]) = 1;
                T([1,5]) = diff(after)./diff(before);
                T([3,6]) = after(1,:) - before(1,:).*T([1,5]);
                TF = maketform('affine',T);
                for X = p(1,1)+0.5:p(2,1)-0.5
                    IMG = false(obj.volumeSize(2),obj.volumeSize(3));
                    IMG(sub2ind([obj.volumeSize(2),obj.volumeSize(3)], ROI(ROI(:,1)==X,2), ROI(ROI(:,1)==X,3) )) = true;
                    IMG = imtransform(IMG,TF,'nearest','XData',[1 obj.volumeSize(3)], 'YData',[1 obj.volumeSize(2)]);
                    newROI(X,:,:) = IMG;
                end
            elseif fig == obj.figsHandles(2) % Z / X
                before = [p(:,3),p(:,1)];
                T = zeros(3,3); T([1,5,9]) = 1;
                T([1,5]) = diff(after)./diff(before);
                T([3,6]) = after(1,:) - before(1,:).*T([1,5]);
                TF = maketform('affine',T);
                for Y = p(1,2)+0.5:p(2,2)-0.5
                    IMG = false(obj.volumeSize(1),obj.volumeSize(3));
                    IMG(sub2ind([obj.volumeSize(1),obj.volumeSize(3)], ROI(ROI(:,2)==Y,1), ROI(ROI(:,2)==Y,3) )) = true;
                    IMG = imtransform(IMG,TF,'nearest','XData',[1 obj.volumeSize(3)], 'YData',[1 obj.volumeSize(1)]);
                    newROI(:,Y,:) = IMG;
                end
            else % X / Y
                after = after(:,[2,1]);
                before = [p(:,2),p(:,1)];
                T = zeros(3,3); T([1,5,9]) = 1;
                T([1,5]) = diff(after)./diff(before);
                T([3,6]) = after(1,:) - before(1,:).*T([1,5]);
                TF = maketform('affine',T);
                for Z = p(1,3)+0.5:p(2,3)-0.5
                    IMG = false(obj.volumeSize(1),obj.volumeSize(2));
                    IMG(sub2ind([obj.volumeSize(1),obj.volumeSize(2)], ROI(ROI(:,3)==Z,1), ROI(ROI(:,3)==Z,2) )) = true;
                    IMG = imtransform(IMG,TF,'nearest','XData',[1 obj.volumeSize(2)], 'YData',[1 obj.volumeSize(1)]);
                    newROI(:,:,Z) = IMG;
                end
            end
            obj.overVol(sub2ind([obj.volumeSize, obj.numFrames(2)],ROI(:,1),ROI(:,2),ROI(:,3),repmat(obj.currentFrame(2),size(ROI,1),1))) = false;
            obj.overVol(:,:,:,obj.currentFrame(2)) = (obj.overVol(:,:,:,obj.currentFrame(2)) | newROI);
            delete(patchHandle);
            delete(obj.ROIEditH(ishandle(obj.ROIEditH))); obj.ROIEditH = [];
            overlayVolume.editROI(obj)
            updateImages(obj);
        end
        function figureScroll(fig,evnt,obj)
            % FIGURESCROLL triggers when the mousewheel is used in a figure
            % The function checks in which figure the scrolling was done,
            % keeps the position within the bounds of the volume and if
            % necessary (the position has changed) updates the images.
            CP = obj.currentPoint; % The current point
            VS = obj.volumeSize;
            if fig==obj.figsHandles(1)
                temp = CP(1);
                CP(1) = CP(1)+evnt.VerticalScrollCount; % Add the scroll count (this number can also be negative)
                CP(1) = min([VS(1), max([1, CP(1)])]); % The new position should be in correct range (>0 and <image size).
                obj.currentPoint = CP;
                if temp~=CP(1)  % When the position has changed
                    updateImages(obj,fig);  % Update the images.
                end
            elseif fig==obj.figsHandles(2)
                temp = CP(2);
                CP(2) = CP(2)+evnt.VerticalScrollCount;
                CP(2) = min([VS(2), max([1, CP(2)])]);
                obj.currentPoint = CP;
                if temp~=CP(2)
                    updateImages(obj,fig);
                end
            else
                temp = CP(3);
                CP(3) = CP(3)+evnt.VerticalScrollCount;
                CP(3) = min([VS(3), max([1, CP(3)])]);
                obj.currentPoint = CP;
                if temp~=CP(3)
                    updateImages(obj,fig);
                end
            end
        end
        function imageClick(img,~,obj)
            % imageClick triggers when the user clicks in a windows.
            % The function checks which mouse button was clicked, left
            % mousebutton changes the position of the current view, right
            % mouse and scrollwheel click change the brightness and
            % contrast of the background and overlay, respectively.
            fig = obj.figsHandles(obj.imgsHandles==img);
            axs = get(img,'Parent');
            ST = get(fig,'SelectionType');  % Get the type of mouse click
            if obj.ROIEnabled == 1
                CP = get(axs,'CurrentPoint');
                obj.ROIPoints = CP(1,1:2);
                if strcmpi(ST,'normal')
                    obj.ROIType = 1; color = 'g';
                else
                    obj.ROIType = 0; color = 'r';
                end
                hold on;
                if ishandle(obj.ROIHandle), delete(obj.ROIHandle); end
                obj.ROIHandle = plot(CP(1,1),CP(1,2),color);
                hold off;
                set(fig, 'NextPlot','new','WindowButtonUpFcn',{@overlayVolume.mouseUp,obj},'WindowButtonMotionFcn',{@overlayVolume.mouseMove,obj,'ROI'});
            else
                if strcmpi(ST,'normal')
                    CP = obj.currentPoint;
                    VS = obj.volumeSize;
                    p = get(axs,'CurrentPoint'); % Get the currentpoint in the correct image.
                    if fig==obj.figsHandles(1)
                        CP(3) = max([1 min([VS(3), round(p(1,2))])]);
                        CP(2) = max([1 min([VS(2), round(p(1,1))])]);
                    elseif fig==obj.figsHandles(2)
                        CP(3) = max([1 min([VS(3), round(p(1,2))])]);
                        CP(1) = max([1 min([VS(1), round(p(1,1))])]);
                    else
                        CP(1) = max([1 min([VS(1), round(p(1,2))])]);
                        CP(2) = max([1 min([VS(2), round(p(1,1))])]);
                    end
                    obj.currentPoint = CP; % update the position in the class.
                    updateImages(obj,setdiff(obj.figsHandles,fig)); % Update the images of the other figures.
                elseif strcmpi(ST,'extend') % Shift-click, or double mouse button, or mousewheel click
                    obj.mousePoint = get(fig,'CurrentPoint');
                    overlayVolume.setCursor(fig,'contrast');
                    set(fig, 'WindowButtonUpFcn',{@overlayVolume.mouseUp,obj},'WindowButtonMotionFcn',{@overlayVolume.mouseMove,obj,'over'});
                elseif strcmpi(ST,'alt') % Right click
                    obj.mousePoint = get(fig,'CurrentPoint');
                    set(fig, 'WindowButtonUpFcn',{@overlayVolume.mouseUp,obj},...
                        'WindowButtonMotionFcn',{@overlayVolume.mouseMove,obj,'back'});
                    overlayVolume.setCursor(fig,'contrast')
                end
            end
        end
        function mouseMove(fig,~,obj,type)
            % MOUSEMOVE is used to change the contrast and brightness
            % This function is only triggered when the user clicks and
            % holds the right of middle mouse button.
            newMouse = get(fig,'CurrentPoint');
            switch type
                case 'back'
                    mouseMove = newMouse - obj.mousePoint;
                    Value = obj.backRange; 
                    Value = Value + mouseMove*0.01*diff(Value);
                    if Value(1)<Value(2)                            % The first should be smaller than the second
                        obj.backRange = Value;                      % Set the values.
                        updateImages(obj);                          % Update the images.
                        showColorBar(obj,'UpdateIfExist');          % Update the colorbar if it exists.
                    end
                case 'over'
                    mouseMove = newMouse - obj.mousePoint;
                    if ~isempty(obj.overRange)
                        Value = obj.overRange; 
                        Value = Value + mouseMove*0.01*diff(Value);
                        if Value(1)<Value(2)                            % The first should be smaller than the second
                            obj.overRange = Value;                      % Set the values.
                            updateImages(obj);                          % Update the images.
                            showColorBar(obj,'UpdateIfExist');          % Update the colorbar if it exists.
                        end
                    end
                case 'ROI'
                    CP = get(findall(fig,'tag','IMG'),'CurrentPoint');
                    switch obj.ROIStyle
                        case 'Freehand'
                            obj.ROIPoints = [obj.ROIPoints; CP(1,1:2)];
                            XData = [obj.ROIPoints(:,1);obj.ROIPoints(1,1)];
                            YData = [obj.ROIPoints(:,2);obj.ROIPoints(1,2)];
                        case 'Square'
                            obj.ROIPoints = [obj.ROIPoints(1,:); CP(1,1:2)];
                            XData = obj.ROIPoints([1 2 2 1 1],1);
                            YData = obj.ROIPoints([1 1 2 2 1],2);
                        case 'Circle'
                            obj.ROIPoints = [obj.ROIPoints(1,:); CP(1,1:2)];
                            theta = 0:pi/50:2*pi;
                            C = mean(obj.ROIPoints);
                            D = diff(obj.ROIPoints)/2;
                            XData = C(1) + (D(1) * cos(theta));
                            YData = C(2) + (D(2) * sin(theta));
                    end
                    set(obj.ROIHandle,'XData',XData,'YData',YData);
            end
            obj.mousePoint = newMouse;
        end
        function mouseUp(fig,~,obj)
            % MOUSEUP resets mouse click behavior and cursor in the figure
            % This function is called after brightness and contrast have
            % been changed using the mouse, or a ROI has been drawn
            if obj.ROIEnabled == 1
                delete(obj.ROIHandle);
                try
                    MSK = false(obj.volumeSize);
                    RP = obj.ROIPoints;
                    switch obj.ROIStyle
                        case 'Square'
                            RP = [RP([1 2 2 1],1), RP([1 1 2 2],2)];
                        case 'Circle'
                            theta = 0:pi/50:2*pi;
                            C = mean(RP);
                            D = diff(RP)/2;
                            RP = [C(1) + (D(1) * cos(theta)); C(2) + (D(2) * sin(theta))]';
                    end
                    if fig==obj.figsHandles(1)
                        mask = poly2mask(RP(:,2),RP(:,1),obj.volumeSize(2),obj.volumeSize(3));
                        MSK(obj.currentPoint(1),:,:) = mask;
                    elseif fig==obj.figsHandles(2)
                        mask = poly2mask(RP(:,2),RP(:,1),obj.volumeSize(1),obj.volumeSize(3));
                        MSK(:,obj.currentPoint(2),:) = mask;
                    else
                        mask = poly2mask(RP(:,1),RP(:,2),obj.volumeSize(1),obj.volumeSize(2));
                        MSK(:,:,obj.currentPoint(3)) = mask;
                    end
                    if obj.ROIType
                        obj.overVol(:,:,:,obj.currentFrame(2)) = MSK | obj.overVol(:,:,:,obj.currentFrame(2));
                    else
                        obj.overVol(:,:,:,obj.currentFrame(2)) = ~MSK & obj.overVol(:,:,:,obj.currentFrame(2));
                    end
                end
                updateImages(obj);
            else
                overlayVolume.setCursor(fig,'cross')
            end
            set(fig, 'WindowButtonUpFcn','','WindowButtonMotionFcn','');
        end
        function closeRequest(fig,~,obj)
            % CLOSEREQUEST is used to clean up just before a fig is closed 
            ind2Close = obj.figsHandles == fig; % collect indices of figure/ROI Handles to close i.e. they appear in the same order
            delete(fig);  % close the figure;
            obj.figsHandles(ind2Close) = NaN; % delete the handle. This is necessary in case multiple instances of the class are open.
        end
        function IMG = provideImage(fig,obj)
            % PROVIDEIMAGE creates an image from the volumes to display
            % All settings such as the colormap, the colorrange, the alpha
            % value etc, are being processed here to produce the correct
            % image. The function will be called for each figure
            % individually. 
            CP = obj.currentPoint; 
            CF = obj.currentFrame;
            % Get the image for the background:
            if fig==obj.figsHandles(1)
                IMG1 = permute(obj.backVol(CP(1),:,:,CF(1)),[3 2 1]);
            elseif fig==obj.figsHandles(2)
                IMG1 = permute(obj.backVol(:,CP(2),:,CF(1)),[3 1 2]);
            else
                IMG1 = obj.backVol(:,:,CP(3),CF(1));
            end
            IMG1 = IMG1-obj.backRange(1); % Subtract the lower display limit.
            IMG1 = IMG1./(obj.backRange(2)-obj.backRange(1)); % Also use the upper display limit.
            IMG1(IMG1<0) = 0; % Everything below the lower limit is set to the lower limit.
            IMG1(IMG1>1) = 1; % Everything above the upper limit is set to the upper limit.
            IMG1 = round(IMG1*(size(obj.backMap,1)-1))+1;  % Multiply by the size of the colormap, and make it integers to get a color index.
            IMG1(isnan(IMG1)) = 1; % remove NaNs -> these will be shown as the lower limit.
            IMG1 = reshape(obj.backMap(IMG1,:),[size(IMG1,1),size(IMG1,2),3]); % Get the correct color from the colormap using the index calculated above
            
            % If present, create the overlay image including mask
            if ~isempty(obj.overVol);
                if fig==obj.figsHandles(1)
                    IMG2 = permute(obj.overVol(CP(1),:,:,CF(2)),[3 2 1]);
                elseif fig==obj.figsHandles(2)
                    IMG2 = permute(obj.overVol(:,CP(2),:,CF(2)),[3 1 2]);
                else
                    IMG2 = obj.overVol(:,:,CP(3),CF(2));
                end
                % If a maskrange is available, use it. First the mask is
                % set to one (show all), then everything outside the mask
                % range will be set to zero (not shown)
                if ~isempty(obj.maskRange)
                    mask = ones(size(IMG2));
                    mask(IMG2<obj.maskRange(1) | IMG2>obj.maskRange(2)) = 0;
                else
                    mask = ones(size(IMG2));
                end
                IMG2=IMG2-obj.overRange(1);
                IMG2=IMG2./(obj.overRange(2)-obj.overRange(1));
                IMG2(IMG2<0) = 0;
                IMG2(IMG2>1) = 1;
                IMG2 = round(IMG2*(size(obj.overMap,1)-1))+1;
                mask(isnan(IMG2)) = 0;
                IMG2(isnan(IMG2)) = 1;
                IMG2 = reshape(obj.overMap(IMG2,:),[size(IMG2,1),size(IMG2,2),3]);
                mask = repmat(mask,[1 1 3]); % repeat mask for R, G and B.
                %IMG = IMG1*(1-obj.alpha) + mask.*IMG2*obj.alpha; % Combine background and overlay, using alpha and mask.
                IMG = IMG1.* ((mask .* -obj.alpha) + 1) + mask.*IMG2*obj.alpha; % Combine background and overlay, using alpha and mask.
            else
                IMG = IMG1;
            end
        end
        function params = parseInputs(input,obj)
            % PARSEINPUTS parses the inputs given by the user.
            % Some basic input checking is performed, and defaults are
            % provided for parameters unspecified by the user.
            % It uses Matlabs input parser, see "help inputparser"
            p = inputParser;  
            p.addParamValue('backRange',overlayVolume.getRange(obj.backVol),@(x)length(x)==2&x(1)<x(2));
            p.addParamValue('overRange',overlayVolume.getRange(obj.overVol),@(x)length(x)==2&x(1)<x(2));
            p.addParamValue('backMap',gray(256),@(x)ismatrix(x)&size(x,2)==3)
            p.addParamValue('overMap',hot(256),@(x)ismatrix(x)&size(x,2)==3)
            p.addParamValue('maskRange',[-Inf Inf],@(x)length(x)==2&x(1)<x(2));
            p.addParamValue('alpha',0.4,@(x)x>=0&x<=1);
            p.addParamValue('aspectRatio',[1 1 1],@(x)length(x)==3);
            p.addParamValue('colorBar',0,@isscalar);
            p.addParamValue('dockWindows',0,@isscalar);
            p.addParamValue('title','Overlay Volume',@ischar);
            p.addParamValue('sync',0,@isscalar);
            p.parse(input{:});
            obj.backRange   = p.Results.backRange;
            obj.overRange   = p.Results.overRange;
            obj.maskRange   = p.Results.maskRange;
            obj.alpha       = p.Results.alpha;
            obj.backMap     = p.Results.backMap;
            obj.overMap     = p.Results.overMap;
            obj.aspectRatio = p.Results.aspectRatio;
            obj.title       = p.Results.title;
            obj.sync        = p.Results.sync;
            if p.Results.colorBar, showColorBar(obj); end
            params = p.Results;
        end
        function sliderMove(varargin)
            % SLIDERMOVE is executed when a different frame is selected.
            % The function can only be called when the frame window is
            % open. When the user changes the position of the sliders the
            % correct frame is displayed.
            obj = varargin{3}; N = varargin{4};
            position = round(get(varargin{1},'Value'));
            set(varargin{1},'Value',position);
            cF = obj.currentFrame;
            if cF(N)~=position
                nF = obj.numFrames;
                obj.currentFrame(N) = position;
                cF(N) = position;
                updateImages(obj);
                set(obj.frameFig,'Name',sprintf('B: %1.0f/%1.0f | O: %1.0f/%1.0f',cF(1),nF(1),cF(2),nF(2)));
            end
            if obj.ROIEnabled==2
            	figs = obj.figsHandles; figs = figs(ishandle(figs));
                set(findall(figs,'tag','ROImenu'),'Checked','off')
                overlayVolume.setCursor(figs,'cross');
                delete(obj.ROIEditH);
                obj.ROIEditH = [];
                obj.ROIEnabled = 0;
            end
        end
        function rotationStart(fig,~,h)
            % ROTATIONSTART is executed when the user starts rotating.
            overlayVolume.setCursor(fig,'rotate')
            set(h,'RotateStyle','box'); % Only rotate a bounding box, not the image.
        end
        function rotationEnd(fig,axs,obj)
            % ROTATIONEND is used when the user is done rotating.
            % This function will do the actual rotation and updates the
            % images. When the user double clicks in rotation mode, the
            % original view is reset.
            % Note that aspect ratios do not change with the rotation, and
            % the volumesize will not change. 
            new = get(axs.Axes,'View'); % Get the requested rotation
            set(axs.Axes,'View',[0 90]); % Keep the original view.
            if isempty(obj.backOriginal)
                obj.backOriginal = obj.backVol;
                obj.overOriginal = obj.overVol;
                obj.rotation = [0 0 0];
            end
            rotate = obj.rotation;
            if fig == obj.figsHandles(1)
                rotate = rotate + [-new(1),90-new(2),0];
            elseif fig == obj.figsHandles(2)
                rotate = rotate + [90-new(2),new(1),0];
            else 
            	rotate = rotate + [0,90-new(2),new(1)];
            end
            if ~strcmpi(get(fig,'SelectionType'),'open');
                obj.rotation = rotate;
                obj.backVol = rotate3DMatrix(obj.backOriginal,rotate,'nearest');
                if ~isempty(obj.overVol)
                    obj.overVol = rotate3DMatrix(obj.overOriginal,rotate,'nearest');
                end
            else
                obj.rotation = [0 0 0];
                obj.backVol = obj.backOriginal; 
                if ~isempty(obj.overVol)
                    obj.overVol = obj.overOriginal; 
                end
            end
            updateImages(obj)
            overlayVolume.setCursor(fig,'cross')
        end
        function matrix = rotate90degrees(matrix,dim,cw)
            % ROTATE90DEGREES will rotate the volume 90 degrees.
            % This function is called after the user presses the left or
            % right arrows, see KEYPRESS below. It supports the three
            % different views and clock- or counterclockwise rotation.
            switch dim
                case 1
                    if cw
                        matrix = permute(matrix,[1,3,2,4]);
                        matrix = matrix(:,end:-1:1,:,:);
                    else
                        matrix = permute(matrix(:,end:-1:1,:,:),[1,3,2,4]);
                    end
                case 2
                    if cw
                        matrix = permute(matrix,[3,2,1,4]);
                        matrix = matrix(end:-1:1,:,:,:);
                    else
                        matrix = permute(matrix(end:-1:1,:,:,:),[3,2,1,4]);
                    end
                case 3
                    if cw
                        matrix = permute(matrix,[2,1,3,4]);
                        matrix = matrix(end:-1:1,:,:,:);
                    else
                        matrix = permute(matrix(end:-1:1,:,:,:),[2,1,3,4]);
                    end
            end
        end
        function setCursor(fig,cursor)
            % SETCURSOR sets custom cursors indicating the current function
            for handle = fig
                if ishandle(handle)
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
                    set(handle,'Pointer','custom','PointerShapeCData',pointer,'PointerShapeHotSpot',spot)
                end
            end
        end
        function keyPress(fig,click,obj)
            % KEYPRESS process keypresses in any of the windows.
            % Currently only left and right arrow have a reaction, rotation
            % in counterclockwise, respectively clockwise direction.
            dim = find(fig == obj.figsHandles);
            aspect = obj.aspectRatio; aRSwitch = [1,3,2;3,2,1;2,1,3];
            switch click.Key
                case 'leftarrow'
                    obj.backVol = overlayVolume.rotate90degrees(obj.backVol,dim,0);
                    obj.overVol = overlayVolume.rotate90degrees(obj.overVol,dim,0);
                    temp = [size(obj.backVol),1];
                    obj.volumeSize = temp(1:3);
                    obj.currentPoint = min([obj.currentPoint; temp(1:3)]);
                    obj.aspectRatio = aspect(aRSwitch(dim,:));
                    overlayVolume.initImages(obj,dim)
                    updateImages(obj)
                case 'rightarrow'
                    obj.backVol = overlayVolume.rotate90degrees(obj.backVol,dim,1);
                    obj.overVol = overlayVolume.rotate90degrees(obj.overVol,dim,1);
                    temp = [size(obj.backVol),1];
                    obj.volumeSize = temp(1:3);
                    obj.currentPoint = min([obj.currentPoint; temp(1:3)]);
                    obj.aspectRatio = aspect(aRSwitch(dim,:));
                    overlayVolume.initImages(obj,dim)
                    updateImages(obj)
            end
        end
        function initImages(obj,fig)
            % INITIMAGES Initializes the images and indicator lines
            if nargin==1, fig = []; end;
            vS = obj.volumeSize;
            A = [3,3,1]; B = [2,1,2];
            for ii = 1:3
                if ishandle(obj.figsHandles(ii))
                    figure(obj.figsHandles(ii));
                    obj.imgsHandles(ii) = imshow(zeros(vS(A(ii)),vS(B(ii))));
                    set(obj.imgsHandles(ii),'ButtonDownFcn',{@overlayVolume.imageClick,obj});
                    hold on % Hold, to initialize lines
                    obj.lineHandles(ii) = plot(0,1,'Color',[0.8,0.8,0.8]);  % The correct coordinates are not necessary at this stage.
                    set(obj.lineHandles(ii),'HitTest','off')
                    hold off
                    % Image should be full size, The correct data aspect
                    % ratio, and can be identified by the tag 'IMG' 
                    set(gca,'position',[0 0 1 1],'DataAspectRatio',[obj.aspectRatio(A(ii)) obj.aspectRatio(B(ii)) 1],'Tag', 'IMG');
                    set(obj.figsHandles(ii),'NextPlot','new');
                    if isempty(fig), fig = obj.figsHandles(ii); end
                end
            end
            figure(fig);
        end
        function projection(obj,fig)
            angle = 9;
            theta = 0:angle:360-angle;
            order = [2 3 1; 1 3 2; 2 1 3];
            image = permute(obj.backVol(:,:,:,obj.currentFrame(1)),order(fig,:));
            Rb = overlayVolume.makeMIP(image,theta,'nearest');
            if ~isempty(obj.overVol)
                image = permute(obj.overVol,order(fig,:));
                Ro = overlayVolume.makeMIP(image,theta,'nearest');
            else
                Ro = [];
            end
            overlayVolume(Rb,Ro,'backMap',obj.backMap,'backRange',obj.backRange,'overMap',obj.overMap,'overRange',obj.overRange,'maskRange',obj.maskRange,'alpha',obj.alpha);
            
        end
        
        function R = makeMIP(vol,angles,interp)
            F = min(vol(:));
            SZ = size(vol); diag = sqrt(SZ(1)^2+SZ(2)^2);
            vol = padarray(vol,[ceil((diag-SZ(1))/2) ceil((diag-SZ(2))/2) 0],F);
            cntr = (size(vol) +1)/2;
            RS = makeresampler(interp, 'fill');
            TDIMS = [1 2 3];
            TSIZE = size(vol);
            R = zeros(TSIZE(2),TSIZE(3),length(angles));
            N = 0;
            for ii = angles
                N = N+1;
                Trot = [cosd(ii),-sind(ii),0,0;sind(ii),cosd(ii),0,0;0,0,1,0;0,0,0,1];
                T1 = [1,0,0,0;0,1,0,0;0,0,1,0;-cntr,1];
                T2 = [1,0,0,0;0,1,0,0;0,0,1,0;cntr,1];
                T = T1*Trot*T2;
                tform = maketform('affine', T);
                rotated = squeeze(max(tformarray(vol, tform, RS, TDIMS, TDIMS, TSIZE, [], F),[],1));
                R(:,:,N) = rotated;
            end
        end
    end
    methods
    	function obj = overlayVolume(backVol,overVol,varargin)
            if nargin==1, overVol = []; end
            if isscalar(backVol) || ndims(backVol)>4 % Volume should be 2D - 4D
                error('Images should be 2- to 4-Dimensional');
            elseif ndims(backVol)==4 || ndims(overVol)==4 % 4D case, determine number of frames.
                obj.currentFrame = [size(backVol,4), size(overVol,4)];
                obj.numFrames = obj.currentFrame;
            end

            vS = [size(backVol), 1]; vS = vS(1:3); % The size of the volume (the 1 is added for 2D cases).
            obj.currentPoint = round(vS/2); % Current point is in the center of the volume.
            if ~isempty(overVol)
                overSize = [size(overVol), 1];
                if ~all(vS == overSize(1:3))
                    error('Overlay must be the same size');
                end
            end
            if ~isreal(backVol) || ~isreal(overVol)
                warning('The data should not be complex. Only showing the real part.')
                backVol = real(backVol);
                overVol = real(overVol);
            end
            obj.volumeSize = vS;
            obj.backVol = double(backVol);
            obj.overVol = overVol;
            if islogical(overVol) && ~any(ismember({'overRange', 'overMap', 'maskRange'},varargin(1:2:end)))
                varargin = [varargin, 'overRange',[0, 1.2], 'overMap', jet(256), 'maskRange', [0.5 1.5]];
            end
            
            % Parse the optional additional input parameters.
            params = overlayVolume.parseInputs(varargin,obj);
            
            % Create the figures and get the cursor handles for datatip
            obj.figsHandles(1) = figure('Tag','OverlayVolume','UserData',obj);
            obj.cursHandles=datacursormode(obj.figsHandles(1));
            obj.figsHandles(2) = figure('Tag','OverlayVolume','UserData',obj);
            obj.cursHandles(2)=datacursormode(obj.figsHandles(2));
            obj.figsHandles(3) = figure('Tag','OverlayVolume','UserData',obj);
            obj.cursHandles(3)=datacursormode(obj.figsHandles(3));
            
            % Initialize the images and lines, set context menus, change
            % some properties of the windows, add some functions to the
            % figures, set the data cursor mode to a custom function
            overlayVolume.initImages(obj)
            overlayVolume.makeMenus(obj.figsHandles,obj);     
            set(obj.figsHandles, 'WindowScrollWheelFcn',{@overlayVolume.figureScroll,obj},...
                'NumberTitle','off','NextPlot','new',... 
                'CloseRequestFcn',{@overlayVolume.closeRequest,obj}, ...
                'Interruptible','off', 'BusyAction','cancel','Color',[.8 .85 .9]);                         
            set(obj.cursHandles, 'UpdateFcn', @obj.dataTip); 
            updateImages(obj,[],0); 
            if any(obj.numFrames>1)
                showFrameFig(obj);
            end
            % Close windows if there is a singleton dimension.
            if any(vS==1)
                close(obj.figsHandles(intersect(find(vS~=1),[1 2 3])))
            end
            if params.dockWindows, try dockWindows(obj); end; end % When the user wants the windows docked, try to do so.
            overlayVolume.setCursor(obj.figsHandles,'cross') % Set the default cursor.
            if obj.sync, obj.sync = 0; obj.menuAction([],[],obj,'sync'); end
        end
        function tiptext = dataTip(obj, ~, event)
            % DATATIP shows something meaningful in the datacursor.
            % The current position is shown, together with the pixel value
            % of the background and, if available, the overlay.
            CP = obj.currentPoint;
            Pos = event.Position;
            fig = get(event.Target,'Parent');
            while ~strcmp('figure', get(fig,'type'))
                fig = get(fig,'Parent');
            end  
            if fig==obj.figsHandles(1)
                X=CP(1); Y=Pos(1); Z=Pos(2);
            elseif fig==obj.figsHandles(2)
                X=Pos(1); Y=CP(2); Z=Pos(2);
            else 
                X=Pos(2); Y=Pos(1); Z=CP(3); 
            end
            back = obj.backVol(X,Y,Z,obj.currentFrame(1));                          
            tiptext = sprintf('X: %1.0f, Y: %1.0f, Z: = %1.0f\nBackground: %2.2f',X,Y,Z,back);
            if ~isempty(obj.overVol)
                over = obj.overVol(X,Y,Z,obj.currentFrame(2));
                tiptext = sprintf('%s\nOverlay: %2.2f',tiptext,over);
            end  
        end
        function updateImages(obj,figs,sync)
            % UPDATEIMAGES updates the images.
            % The function can be called for one specific window, without
            % the second argument it will update all open windows.
            % First the new images are set, then the markers are updated,
            % and if a ROI is present it will be updated as well.
            if nargin==1 || isempty(figs)
                figs = obj.figsHandles;
            end
            if nargin<3
                sync = 1;
            end
            for loop = 1:length(figs)
                if ishandle(figs(loop))
                    try
                        IMG=overlayVolume.provideImage(figs(loop),obj);
                        set(obj.imgsHandles(figs(loop) == obj.figsHandles),'CData',IMG); 
                    end
                end
            end
            updateMarkers(obj,sync);
        end
        function updateMarkers(obj,sync)
            % UPDATEMARKERS sets line markers showing the current position
            % In addition, the title of the figure is updated to show the
            % position.
            CP = obj.currentPoint;
            vS = obj.volumeSize;
            LL = vS/15; LL2 = LL-0.5; % Length of the helper lines depends on the size of the volume.
            Name = [obj.currentPoint;obj.volumeSize];
            Name = sprintf('%s [X: %1.0f/%1.0f, Y: %1.0f/%1.0f, Z: %1.0f/%1.0f]',obj.title,Name(:));
            
            if obj.sync && sync
                others = get(findobj('Type','figure','Tag','OverlayVolumeSync'),'UserData');
                others = setdiff(unique([others{:}]),obj);
                if ~isempty(others)
                    for currentObj = 1:length(others)
                        others(currentObj).currentPoint = min([obj.currentPoint;others(currentObj).volumeSize]);
                        others(currentObj).updateImages([],0);
                    end
                end
            end
            
            if ishandle(obj.figsHandles(1))
                set(obj.lineHandles(1),'XData',[0.5 0.5+LL(2) NaN vS(2)-LL2(2) vS(2)+0.5 NaN CP(2) CP(2) NaN CP(2) CP(2)]);
                set(obj.lineHandles(1),'YData',[CP(3) CP(3) NaN CP(3) CP(3) NaN 0.5 0.5+LL(3) NaN vS(3)-LL2(3) vS(3)+0.5]);
                set(obj.figsHandles(1),'Name',Name);
            end
            if ishandle(obj.figsHandles(2))
                set(obj.lineHandles(2),'XData',[0.5 0.5+LL(1) NaN vS(1)-LL2(1) vS(1)+0.5 NaN CP(1) CP(1) NaN CP(1) CP(1)]);
                set(obj.lineHandles(2),'YData',[CP(3) CP(3) NaN CP(3) CP(3) NaN 0.5 0.5+LL(3) NaN vS(3)-LL2(3) vS(3)+0.5]);
                set(obj.figsHandles(2),'Name',Name);
            end
            if ishandle(obj.figsHandles(3))
                set(obj.lineHandles(3),'XData',[0.5 0.5+LL(2) NaN vS(2)-LL2(2) vS(2)+0.5 NaN CP(2) CP(2) NaN CP(2) CP(2)]);
                set(obj.lineHandles(3),'YData',[CP(1) CP(1) NaN CP(1) CP(1) NaN 0.5 0.5+LL(1) NaN vS(1)-LL2(1) vS(1)+0.5]);
                set(obj.figsHandles(3),'Name',Name); 
            end
        end
                
        function setBackVolume(obj, Value)
            % SETBACKVOLUME can be used to change the background volume.
            % The size of the volume should match the previous one.
            if ~isequal(size(Value), size(obj.backVol))
                warning('Background image should have the same dimensions!');
            end;
            obj.backVol = Value;
            updateImages(obj);
        end
        function setOverVolume(obj, Value)
            % SETOVERVOLUME  can be used to change the overlay volume.
            % The size of the volume should match the background, or could
            % be empty.
            if ~isempty(Value)
                if ~isequal(size(Value), size(obj.backVol))
                    warning('Overlay image should have the same dimensions as the background!');
                end
            end
            obj.overVol = Value;
            if isempty(obj.overRange)
                obj.overRange = overlayVolume.getRange(Value(:,:,:,end));
            end
            updateImages(obj);
            showColorBar(obj,'UpdateIfExist');
        end
        function setBackMap(obj, Value)
            % SETBACKMAP can be used to change the background colormap 
            % A quick error check is performed before.
            try iptcheckmap(Value) 
                obj.backMap = Value;
                updateImages(obj);
                showColorBar(obj,'UpdateIfExist'); 
            catch %#ok<CTCH>  We do not need the error message.
                warning('Colormap should be X*3');
            end
        end
        function setOverMap(obj, Value)
            % SETOVERMAP can be used to change the overlay colormap 
            % A quick error check is performed before.
            try iptcheckmap(Value)
                obj.overMap = Value;
                updateImages(obj);
                showColorBar(obj,'UpdateIfExist');
            catch %#ok<CTCH>  We do not need the error message.
                warning('Colormap should be X*3');
            end
        end
        function setBackRange(obj, Value)
            % SETBACKRANGE sets the background color range
            if length(Value) == 2 
                if Value(1)<Value(2)
                    obj.backRange = Value;
                    updateImages(obj);
                    showColorBar(obj,'UpdateIfExist'); 
                end
            end
        end
        function setOverRange(obj, Value)
            % SETOVERRANGE sets the overlay color range
            if length(Value) == 2
                if Value(1)<Value(2)
                    obj.overRange = Value;
                    updateImages(obj);
                    showColorBar(obj,'UpdateIfExist');
                end
            end
        end
        function setRange(obj,hObject,~,over,pos)
            % SETRANGE sets the range of the images using the colorbar
            value = str2double(get(hObject,'String'));
            if over
                range = obj.overRange;
            else
                range = obj.backRange;
            end
            range(pos) = value; 
            if range(1)<range(2)
                if over 
                    setOverRange(obj,range);
                else
                    setBackRange(obj,range);
                end
            else
                showColorBar(obj,'UpdateIfExist');
            end
        end
        function setMaskRange(obj, Value)
            % SETMASKRANGE sets the range that is visible in the overlay
            if length(Value) == 2
                if Value(1)<Value(2)
                    obj.maskRange = Value;
                end
            elseif isempty(Value)
                obj.maskRange = [];
            end
            updateImages(obj);
        end
        function setAlpha(obj, Value)
            % SETALPHA sets the transparency of the overlay
            if length(Value)==1
                if Value>=0 && Value<=1
                    obj.alpha = Value;
                    updateImages(obj);
                end
            end
        end
        function setAspectRatio(obj, Value)
            % SETASPECTRATIO sets the aspect ratio of the images.
            % The aspect should be one number, or three. 
            if length(Value)==1, Value = repmat(Value,[1 3]); end
            if length(Value)==3
                obj.aspectRatio = Value;
                if ishandle(obj.figsHandles(1))
                    set(findall(obj.figsHandles(1),'type','axes'),'position',[0 0 1 1],'DataAspectRatio',[Value(3) Value(2) 1]);
                end   
                if ishandle(obj.figsHandles(1))
                    set(findall(obj.figsHandles(2),'type','axes'),'position',[0 0 1 1],'DataAspectRatio',[Value(3) Value(1) 1]);
                end
                if ishandle(obj.figsHandles(1))
                    set(findall(obj.figsHandles(3),'type','axes'),'position',[0 0 1 1],'DataAspectRatio',[Value(1) Value(2) 1]);
                end
            else
                warning('Aspected ratio''s should be provided as a 1x3 or 1x1 array!')
            end
        end
        
        function showFrameFig(obj)
            % SHOWFRAMEFIG shows a separate figure for 4D volume
            nF = obj.numFrames; 
            if any(nF>1)
                cF = obj.currentFrame;
                visibles = {'off','on'};
                if ~isempty(obj.frameFig) &&  ishandle(obj.frameFig) 
                    figure(obj.frameFig)
                    set(obj.frameFig,'Name',sprintf('B: %1.0f/%1.0f | O: %1.0f/%1.0f',cF(1),nF(1),cF(2),nF(2)));
                    h = findobj(obj.frameFig,'Tag','back');
                    set(h,'Value',cF(1),'Max',max([nF(1),2]),'SliderStep',[1 5]/max([nF(1),2])+1E-5,'Visible',visibles{(nF(1)>1)+1})
                    h = findobj(obj.frameFig,'Tag','over');
                    set(h,'Value',cF(2),'Max',max([nF(2),2]),'SliderStep',[1 5]/max([nF(2),2])+1E-5,'Visible',visibles{(nF(2)>1)+1})
                else
                    obj.frameFig = figure('NumberTitle','off','Menubar','none',...
                        'Color',[.8 .8 .8],'NextPlot','new',...
                        'Name',sprintf('B: %1.0f/%1.0f | O: %1.0f/%1.0f',cF(1),nF(1),cF(2),nF(2)));        % ... make one
                    position = get(obj.frameFig,'Position'); position(3:4) = [275,50];
                    set(obj.frameFig,'Position',position);
                    uicontrol('Style','text','Units','normalized','Position',[0 0.65 0.2 0.25],'String','Back:','BackgroundColor',[.8 .8 .8])
                    uicontrol('Style','text','Units','normalized','Position',[0 0.15 0.2 0.25],'String','Over:','BackgroundColor',[.8 .8 .8])
                    uicontrol('Tag','back','Style','slider','Units','normalized','Position',[0.2 0.5 0.8 0.5],'Value',cF(1),'Min',1,'Max',max([nF(1),2]),'SliderStep',[1 5]/max([nF(1),2])+1E-5,'Callback',{@overlayVolume.sliderMove,obj,1},'Visible',visibles{(nF(1)>1)+1}); 
                    uicontrol('Tag','over','Style','slider','Units','normalized','Position',[0.2 0.0 0.8 0.5],'Value',cF(2),'Min',1,'Max',max([nF(2),2]),'SliderStep',[1 5]/max([nF(2),2])+1E-5,'Callback',{@overlayVolume.sliderMove,obj,2},'Visible',visibles{(nF(2)>1)+1}); 
                end
            end
        end
        function showColorBar(obj,varargin)
            % SHOWCOLORBAR shows an additional figure with the colorbars.
            % The colorranges can be changed from this figure.
            X = 1/256;
            if isempty(obj.overVol)
                N = 25;  % The full width of the bar is for the background volume.
                over = []; % No overlay bar.
                line = []; % And no line to separate the two.
                fgsz = [1800,100,162,394];
                uiw = 0.59;
                axsz = [0.6 0.01 0.39 0.98];
            else 
                N = 12; % this is the width of each bar.
                over = ceil((1:-X:X)*size(obj.overMap,1))'; % Make a 256 pixel high image.
                over = repmat(over,[1,N]);  % Repeat for the width of the bar.
                over = reshape(obj.overMap(over,:),256,N,3); % Make it the correct color (overlay)
                line = zeros(256,1,3); 
                fgsz = [1800,100,213,394];
                uiw = 0.38;
                axsz = [0.4 0.01 0.2 0.98];
            end

            back = ceil((1:-X:X)*size(obj.backMap,1))';
            back = repmat(back,[1,N]);
            back = reshape(obj.backMap(back,:),256,N,3);
            linelr = zeros(256,1,3); linebt = zeros(1,27,3); % The lines left/right and bottom/top
            colors = [linelr,back,line,over,linelr];  % The colorbar + vertical lines.
            colors = [linebt;colors;linebt];  % Add horizontal lines.

            bcolor = [.8 .85 .9]; % The background color of the window
            if ~isempty(obj.colorBarFig) && ishandle(obj.colorBarFig)
                pos = get(obj.colorBarFig,'Position');
                pos(3) = fgsz(3);
                set(obj.colorBarFig,'Position',pos)
            else
                if nargin~=1 % Check if this function call was from the user (nargin==1) or from a setPROPERTY function (nargin==2) 
                    return % If it was from the setPROPERTY and there is no window, don't make one.
                end
                obj.colorBarFig = figure('Menubar','none','Position',fgsz,'Resize','off','Color', bcolor);
            end
            clf(obj.colorBarFig);
            axs = axes('Parent',obj.colorBarFig,'Position',axsz);
            imshow(colors,'XData', [0 27], 'YData', [0 258],'Parent',axs); 
            hold(axs,'on');
            plot([1 27 NaN 1 27 NaN 1 27],[129.5 129.5 NaN 64.25 64.25 NaN 192.75 192.75],'k','Parent',axs);
            hold(axs,'off');

            % the GUI elements for the background
            backValues = regexpi(sprintf('%.6g ,',interp1([0 100],obj.backRange,[0,25,50,75,100])),',','split');
            uicontrol('Style','Edit','Units','normalized','Position',[0,0.01,uiw,0.05],'String',backValues{1},'BackgroundColor','White','HorizontalAlignment','right','callback',{@obj.setRange,0,1},'Parent',obj.colorBarFig)
            uicontrol('Style','Edit','Units','normalized','Position',[0,0.94,uiw,0.05],'String',backValues{5},'BackgroundColor','White','HorizontalAlignment','right','callback',{@obj.setRange,0,2},'Parent',obj.colorBarFig)
            uicontrol('Style','Text','Units','normalized','Position',[0,0.48,uiw,0.04],'String',backValues{3},'HorizontalAlignment','right','BackgroundColor',bcolor,'Parent',obj.colorBarFig)
            uicontrol('Style','Text','Units','normalized','Position',[0,0.235,uiw,0.04],'String',backValues{2},'HorizontalAlignment','right','BackgroundColor',bcolor,'Parent',obj.colorBarFig)
            uicontrol('Style','Text','Units','normalized','Position',[0,0.725,uiw,0.04],'String',backValues{4},'HorizontalAlignment','right','BackgroundColor',bcolor,'Parent',obj.colorBarFig)
            if N==12
                % the GUI elements for the overlay.
                overValues = regexpi(sprintf(' %.6g,',interp1([0 100],obj.overRange,[0,25,50,75,100])),',','split');
                uicontrol('Style','Edit','Units','normalized','Position',[0.62,0.01,uiw,0.05],'String',overValues{1},'BackgroundColor','White','HorizontalAlignment','left','callback',{@obj.setRange,1,1},'Parent',obj.colorBarFig)
                uicontrol('Style','Edit','Units','normalized','Position',[0.62,0.94,uiw,0.05],'String',overValues{5},'BackgroundColor','White','HorizontalAlignment','left','callback',{@obj.setRange,1,2},'Parent',obj.colorBarFig)
                uicontrol('Style','Text','Units','normalized','Position',[0.62,0.48,uiw,0.04],'String',overValues{3},'HorizontalAlignment','left','BackgroundColor',bcolor,'Parent',obj.colorBarFig)
                uicontrol('Style','Text','Units','normalized','Position',[0.62,0.235,uiw,0.04],'String',overValues{2},'HorizontalAlignment','left','BackgroundColor',bcolor,'Parent',obj.colorBarFig)
                uicontrol('Style','Text','Units','normalized','Position',[0.62,0.725,uiw,0.04],'String',overValues{4},'HorizontalAlignment','left','BackgroundColor',bcolor,'Parent',obj.colorBarFig)
            end
            set(obj.colorBarFig,'NextPlot','new');
        end
        function dockWindows(obj)
            % DOCKWINDOWS dock the three orthogonal view in one window.
            set(obj.figsHandles,'WindowStyle','docked');
            desktop=com.mathworks.mde.desk.MLDesktop.getInstance;
            pause(0.1); % Somehow, some pause is required before the next line is executed. Otherwise, the parent window will remain docked.
            desktop.setGroupDocked('Figures',false);
            desktop.setDocumentArrangement('Figures',2,java.awt.Dimension(length(obj.figsHandles),1));
        end
    end
end