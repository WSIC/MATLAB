% ROTATEMATRIX is a GUI to rotate a 3D matrix and shows 3 orthogonal slices
% Requires the function rotate3DMatrix
%
% Usage: ROTATEMATRIXGUI(inputMatrix,colorm,startRot,interp);
% inputMatrix : The 3D matrix [REQUIRED]
% colorm      : The (name of the) colormap [OPTIONAL, Default: jet]
%                 e.g., 'jet' or n*3 matrix 
% startRot    : Matrix to define the start rotation and location [OPTIONAL]
%                 [angle angle angle slice slice slice] 
% interp      : Interpolation method. [OPTIONAL, Default: linear]
%                 Can be 'cubic', 'linear' or 'nearest'. 
% 
% EXAMPLES:
% rotateMatrixGUI(rand(10,10,10),'jet',[0 0 0 2 4 7])
% 

function rotateMatrixGUI(inputMatrix, varargin)
    
    try
        [x,y,z] = size(inputMatrix);
        inputMatrix = double(inputMatrix);
        imageRange = min(inputMatrix(:));
        imageRange(2) = max(inputMatrix(:));
        if any(isnan(imageRange))
            imageRange = [0 1];
        end
        displayRange = imageRange;
    catch %#ok<CTCH>
        x = 2; y = 2; z = 2;
    end
    
    % Check the input: ----------------------------------------------
    iP = inputParser; 
    checkMatrix = @(q) ndims(q)==3;
    addRequired(iP,'inputMatrix',checkMatrix);
    defaultColormap = 'jet';
    checkColormap = @(q) iptcheckmap(colormap(q), 'rotateMatrix', 'colorm', 2);
    addOptional(iP,'colorm',defaultColormap,checkColormap);
    defaultRotation = [0 0 0 round(z/2) round(y/2) round(x/2)];
    checkRotation = @(q) all(q <= [360 360 360 z y x]) & all(q >= [0 0 0 1 1 1]);
    addOptional(iP,'startRot',defaultRotation,checkRotation);
    defaultInterp = 'linear';
    validInterp = {'linear','cubic','nearest'};
    checkInterp = @(q) any(validatestring(q,validInterp));
    addOptional(iP,'interp',defaultInterp,checkInterp);
    mainFigure = figure;
    parse(iP,inputMatrix,varargin{:});
    colorm = iP.Results.colorm;
    if isstr(colorm)
        colorm = eval([colorm '(256)']);
    end
    interp = iP.Results.interp;
    inputMatrix = iP.Results.inputMatrix;
    startRot = iP.Results.startRot;
    %-----------------------------------------------------------------
    
    outputMatrix = inputMatrix;
    sliceX = startRot(6); RotAroundZ = startRot(3);
    sliceY = startRot(5); RotAroundY = startRot(2);
    sliceZ = startRot(4); RotAroundX = startRot(1);

    % Create figure with axes: ------------------------------------------
    set(mainFigure,'Position',[40 40 1200 500],'MenuBar','none', 'NumberTitle','Off','Name','Rotate 3D');
    panelAxes = uipanel('Position',[0 0 1 .9]);
    panelControls = uipanel('Position',[0 .9 1 .1]);
    axesa1 = axes('Units','normalized','Position',[0 0 .3 1],'Parent',panelAxes);
    axesa2 = axes('Units','normalized','Position',[.35 0 .3 1],'Parent',panelAxes);
    axesa3 = axes('Units','normalized','Position',[.7 0 .3 1],'Parent',panelAxes);    
    % Manage the mouse pointer:
    iptPointerManager(mainFigure);
    enterFcn = @(figureHandle, currentPoint) set(figureHandle, 'Pointer', 'Fullcross');
    iptSetPointerBehavior(axesa1, enterFcn);
    iptSetPointerBehavior(axesa2, enterFcn);
    iptSetPointerBehavior(axesa3, enterFcn);
    
    % Controls for rotation: --------------------------------------------
    sa1 = uicontrol('Style','slider','Units','normalized','Position',[0.01 0.05 0.2 0.3], 'Value',RotAroundZ,'min',0,'max',360,'Callback',@changeRotation,'Parent',panelControls, 'SliderStep',[1 10]/360);
    sa2 = uicontrol('Style','slider','Units','normalized','Position',[0.01 0.37 0.2 0.3], 'Value',RotAroundY,'min',0,'max',360,'Callback',@changeRotation,'Parent',panelControls, 'SliderStep',[1 10]/360);
    sa3 = uicontrol('Style','slider','Units','normalized','Position',[0.01 0.69 0.2 0.3], 'Value',RotAroundX,'min',0,'max',360,'Callback',@changeRotation,'Parent',panelControls, 'SliderStep',[1 10]/360);
    ea1 = uicontrol('Style','text','String',sprintf('%1.2f',RotAroundZ),'Units','normalized','Position',[0.22 0.05 0.1 0.3],'Parent',panelControls,'HorizontalAlign','Left');
    ea2 = uicontrol('Style','text','String',sprintf('%1.2f',RotAroundY),'Units','normalized','Position',[0.22 0.37 0.1 0.3],'Parent',panelControls,'HorizontalAlign','Left');
    ea3 = uicontrol('Style','text','String',sprintf('%1.2f',RotAroundX),'Units','normalized','Position',[0.22 0.69 0.1 0.3],'Parent',panelControls,'HorizontalAlign','Left');
    interpolation = uicontrol('Style','popup','String',validInterp,'Value',find(strcmpi(interp,validInterp)),'Units','normalized','Position',[0.27 0.2 0.1 0.3],'Parent',panelControls,'Callback',@changeInterp);
    uicontrol('Style','pushbutton','String','Rotation','Units','normalized', 'Position',[0.27 0.55 0.05 0.4],'Parent',panelControls,'Callback',@ManualRotationChange);
    uicontrol('Style','pushbutton','String','Position','Units','normalized', 'Position',[0.32 0.55 0.05 0.4],'Parent',panelControls,'Callback',@ManualPositionChange,'enable','off');
    
    % Controls for slice selection: -------------------------------------
    sb1 = uicontrol('Style','slider','Units','normalized','Position',[0.41 0.05 0.2 0.3], 'Value',sliceX,'min',1,'max',x,'Callback',@changeSlice,'Parent',panelControls, 'SliderStep',[1 5]./x);
    sb2 = uicontrol('Style','slider','Units','normalized','Position',[0.41 0.37 0.2 0.3], 'Value',sliceY,'min',1,'max',y,'Callback',@changeSlice,'Parent',panelControls, 'SliderStep',[1 5]./y);
    sb3 = uicontrol('Style','slider','Units','normalized','Position',[0.41 0.69 0.2 0.3], 'Value',sliceZ,'min',1,'max',z,'Callback',@changeSlice,'Parent',panelControls, 'SliderStep',[1 5]./z);
    eb1 = uicontrol('Style','text','String',num2str(sliceX),'Units','normalized', 'Position',[0.62 0.05 0.1 0.3],'Parent',panelControls,'HorizontalAlign','Left');
    eb2 = uicontrol('Style','text','String',num2str(sliceY),'Units','normalized', 'Position',[0.62 0.37 0.1 0.3],'Parent',panelControls,'HorizontalAlign','Left');
    eb3 = uicontrol('Style','text','String',num2str(sliceZ),'Units','normalized', 'Position',[0.62 0.69 0.1 0.3],'Parent',panelControls,'HorizontalAlign','Left');
    
    % Buttons: ----------------------------------------------------------
    uicontrol('Style','pushbutton','String','Save images','Units','normalized', 'Position',[0.7 0.05 0.10 0.4],'Parent',panelControls,'Callback',@saveImages);
    showMIP = uicontrol('Style','togglebutton','Max',1,'String','MIP','Units','normalized', 'Position',[0.70 0.5 0.05 0.4],'Parent',panelControls,'Callback',@toggleProjection);
    showAIP = uicontrol('Style','togglebutton','Max',2,'String','AIP','Units','normalized', 'Position',[0.75 0.5 0.05 0.4],'Parent',panelControls,'Callback',@toggleProjection);
    
    axes('Units','normalized','Position',[.85 .9 .1 .1],'Parent',panelControls,'DataAspectRatioMode','manual');
    image([1:length(colormap(colorm))]);
    axis off
    minRange = uicontrol('Style','edit','String',sprintf('%1.6f',displayRange(1)),'Units','normalized', 'Position',[0.85 0.50 0.05 0.4],'Parent',panelControls,'Callback',@changeRange);
    maxRange = uicontrol('Style','edit','String',sprintf('%1.6f',displayRange(2)),'Units','normalized', 'Position',[0.90 0.50 0.05 0.4],'Parent',panelControls,'Callback',@changeRange);
    subOne = uicontrol('Style','pushbutton','String','-','Units','normalized','Position',[0.95 0.50 0.016 0.4],'Parent',panelControls,'Callback',@changeRange);
    addOne = uicontrol('Style','pushbutton','String','+','Units','normalized','Position',[0.966 0.50 0.016 0.4],'Parent',panelControls,'Callback',@changeRange);
    defaultRange = uicontrol('Style','pushbutton','Max',3,'String','Default','Units','normalized', 'Position',[0.85 0.05 0.08 0.4],'Parent',panelControls,'Callback',@changeRange);
    showOnlyCheck = uicontrol('Style','checkbox','Units','normalized','Position',[0.935 0.05 0.02 0.4],'Parent',panelControls,'Callback',@changeRange);
    showOnly = 0;
        
    % Misc: -------------------------------------------------------------
    IP = 0;   % Show an intensity projection? 0 = no.
    changeRotation;   % First view.
    
    
    function ManualRotationChange(varargin)
        RotAroundZ = get(sa1,'Value');
        RotAroundY = get(sa2,'Value');
        RotAroundX = get(sa3,'Value');
        answer = inputdlg({'Around x','Around y','Around z'},'Change angles',1,{num2str(RotAroundX),num2str(RotAroundY),num2str(RotAroundZ)});
        if ~isempty(answer)
            drawnow
            X = str2double(answer{1}); Y = str2double(answer{2}); Z = str2double(answer{3});
            X = max([0, min([X, 360])]); Y = max([0, min([Y, 360])]); Z = max([0, min([Z, 360])]);
            set(sa1,'Value',Z); set(sa2,'Value',Y); set(sa3,'Value',X);
            changeRotation;
        end
    end

    function changeRotation(varargin)
        RotAroundZ = get(sa1,'Value');
        RotAroundY = get(sa2,'Value');
        RotAroundX = get(sa3,'Value');
        outputMatrix = rotate3DMatrix(inputMatrix,[RotAroundZ,RotAroundY,RotAroundX],interp);
        if showOnly
            outputMatrix((outputMatrix<=displayRange(1)) | (outputMatrix>displayRange(2))) = 0;
        end
        [x,y,z] = size(outputMatrix);
        sliceX = min([sliceX x]); sliceY = min([sliceY y]); sliceZ = min([sliceZ z]);
        set(sb1,'max',x,'Value',sliceX); set(sb2,'max',y,'Value',sliceY); set(sb3,'max',z,'Value',sliceZ);
        set(eb1,'String',num2str(sliceX)); set(eb2,'String',num2str(sliceY)); set(eb3,'String',num2str(sliceZ));
        set(ea1,'String',sprintf('%1.2f',RotAroundZ)); 
        set(ea2,'String',sprintf('%1.2f',RotAroundY));
        set(ea3,'String',sprintf('%1.2f',RotAroundX));
        showImages;
    end
    
    function changeSlice(varargin)
        sliceX = round(get(sb1,'Value')); set(sb1,'Value',sliceX);
        sliceY = round(get(sb2,'Value')); set(sb2,'Value',sliceY);
        sliceZ = round(get(sb3,'Value')); set(sb3,'Value',sliceZ);
        set(eb1,'String',num2str(sliceX)); 
        set(eb2,'String',num2str(sliceY));
        set(eb3,'String',num2str(sliceZ));
        showImages;
        assignin('base','results',outputMatrix);
    end

    function showImages(varargin)
        imshow(squeeze(outputMatrix(:,:,sliceZ)),'DisplayRange',displayRange,'Parent',axesa1)
        imshow(squeeze(outputMatrix(:,sliceY,:)),'DisplayRange',displayRange,'Parent',axesa2)
        switch IP
            case 1 % Maximum intensity projection
                imshow(squeeze(max(outputMatrix)),'DisplayRange',displayRange,'Parent',axesa3)
            case 2 % Average intensity projection
                imshow(squeeze(mean(outputMatrix)),'DisplayRange',displayRange,'Parent',axesa3)
            otherwise % Just show the slice.
                imshow(squeeze(outputMatrix(sliceX,:,:)),'DisplayRange',displayRange,'Parent',axesa3)
        end
        colormap(colorm)
    end

    function saveImages(varargin)
        IMG = mat2gray(squeeze(outputMatrix(:,:,sliceZ)),[displayRange(1) displayRange(2)]);
        IMG = ceil(IMG*size(colormap(colorm),1));
        imwrite(IMG,colormap(colorm),'IMG_view1.png','png')
        IMG = mat2gray(squeeze(outputMatrix(:,sliceY,:)),[displayRange(1) displayRange(2)]);
        IMG = ceil(IMG*size(colormap(colorm),1));
        imwrite(IMG,colormap(colorm),'IMG_view2.png','png')
        IMG = mat2gray(squeeze(outputMatrix(sliceX,:,:)),[displayRange(1) displayRange(2)]);
        IMG = ceil(IMG*size(colormap(colorm),1));
        imwrite(IMG,colormap(colorm),'IMG_view3.png','png')
        fprintf('Images saved in: %s\\\nAs IMG_view[1-3].png\n',cd);
    end

    function toggleProjection(varargin)
        IP = get(varargin{1},'Value');
        set([showMIP,showAIP],'Value',0);
        set(varargin{1},'Value',IP);
        changeRotation;   % Show it.
    end

    function changeRange(varargin)
        if varargin{1} == defaultRange
            displayRange = imageRange;
        elseif varargin{1} == showOnlyCheck
            showOnly = get(showOnlyCheck,'Value');
        elseif varargin{1} == subOne
            displayRange = displayRange-1;
        elseif varargin{1} == addOne
            displayRange = displayRange+1;
        else
            a = str2double(get(minRange,'String'));
            b = str2double(get(maxRange,'String'));
            if ~any([isnan([a b]), isinf([a b]), (a >= b)])
                displayRange = [a b];
            end
        end
        set(minRange,'String',sprintf('%1.6f',displayRange(1)));
        set(maxRange,'String',sprintf('%1.6f',displayRange(2)));
        changeRotation;
    end

    function changeInterp(varargin)
        interp = char(validInterp(get(interpolation,'Value')));
        changeRotation;
    end
end