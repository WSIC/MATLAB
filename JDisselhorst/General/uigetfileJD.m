function [selectedFiles,folder] = uigetfileJD(varargin)

%UIGETFILEJD Standard open file dialog box, able to select many files
%   [FILENAME, PATHNAME] = UIGETFILEJD(STARTFOLDER,FILTERSPEC,TITLE)
%   displays a dialog box for the user to fill in, and returns the filename
%   and path strings. The standard uigetfile has limitations in the number
%   of files that can be selected. All input variables are optional. 
%   STARTFOLDER is the start folder, e.g., 'C:\'
%   FILTERSPEC are the allowed extensions in a cell array. e.g.,
%              {'*.m','*.mat'}
%   TITLE is the figure title, e.g., 'Open file'
%   J.A. Disselhorst 2011


% Initialize
figColor = [.7 .7 .7];
figureTitle = '[JD] Select files';
if nargin==0
    folder = cd;
    ext = {'*.*'};
elseif nargin==1
    folder = varargin{1};
    ext = {'*.*'};
elseif nargin==2
    folder = varargin{1};
    ext = varargin{2};
else
    folder = varargin{1};
    ext = varargin{2};
    figureTitle = varargin{3};
end
if strcmp(folder(end),'\');
    folder = folder(1:end-1);
end
if ~isdir(folder)
    folder = cd;
end
drives = {};
for i=double('A'):double('Z')
    if isdir([char(i) ':'])
        drives(end+1) = {[char(i) ':\']};  %#ok<AGROW>
    end
end
Contents = getFolderContents(folder);
[driveList,Selected] = getDriveList(folder);

% GUI

mainFigure = figure('Resize','off','Position',[400,400,600,350],'menubar','none','Name',figureTitle,'Numbertitle','off','CloseRequestFcn',@closeFigureFcn,'Color',figColor);
driveMenu = uicontrol('Style','popupmenu','String',driveList,'Position',[5 340,560,6],'backgroundcolor','w','Value',Selected,'Callback',@changeDrive);
fileList = uicontrol('Style','listbox','Position',[5 35 590 285],'Min',0,'Max',2,'BackgroundColor','w','String',Contents,'Callback',@selectFile);
uicontrol('Style','pushbutton','Position',[515,5,80,25],'String','Open','Callback',@pressOpenButton,'backgroundColor',figColor)
uicontrol('Style','pushbutton','Position',[430,5,80,25],'String','Cancel','Callback',@pressCancelButton,'backgroundColor',figColor)
upLevelButton = uicontrol('Style','pushbutton','Position',[570,325,25,20],'backgroundColor',figColor,'Callback',@upOneLevel);
IMG = imread(fullfile(matlabroot,'toolbox','matlab','icons','upfolder.gif'));
map = [0,0,0;.7,.7,.7;1,1,0;1,1,1;];
set(upLevelButton,'CData',ind2rgb(IMG,map));
uiwait(mainFigure);

    function Contents = getFolderContents(folder)
        Contents = dir(folder); 
        ContentsFolder = {Contents([Contents.isdir]).name};
        ContentsFolder = ContentsFolder(~cellfun(@(x) any((strcmp(x, {'.','..'}))),ContentsFolder));
        ContentsFolder = cellfun(@(x) sprintf('<html><font color="red"><b>%s</b></font></html>',x),ContentsFolder,'Uni',0);
        ContentsFile = {};
        for i = 1:length(ext)
            Contents = dir(fullfile(folder,char(ext(i))));
            ContentsFile = [ContentsFile {Contents(~[Contents.isdir]).name}];
        end
        Contents = [ContentsFolder unique(ContentsFile)];
    end

    function [driveList,Selected] = getDriveList(currentFolder)
        currentFolder = strrep(regexpi(currentFolder,filesep,'split'),':',':\');
        currentFolder(cellfun(@isempty,currentFolder)) = [];
        for i = 1:length(currentFolder)
            currentFolder{i} = [repmat(' ',1,i-1) currentFolder{i}];
        end
        
        position = find(ismember(drives,upper(currentFolder{1})));
        driveList = [drives(1:position) currentFolder drives(position:end)];
        driveList([position,position+length(currentFolder)+1]) = [];
        Selected = position+length(currentFolder)-1;
    end

    function changeDrive(varargin)
        Selected = get(driveMenu,'Value');
        value = char(driveList(Selected));
        N = sum(value==' ');
        if N
            value = [regexp(folder,'\') length(folder)];
            value = folder(1:value(N+1));
        end
        folder = value;
        refresh(folder)
    end

    function selectFile(varargin)
        selectedFiles = Contents(get(fileList,'Value'));
        selectedFiles = cellfun(@(x) regexprep(x,'<[^>]*>',''),selectedFiles,'Uni',0);
        if strcmpi(get(mainFigure,'SelectionType'),'open')
            handleFileOpen(  char(selectedFiles(1)));
        end
    end

    function handleFileOpen(selectedFiles)
        if isdir(fullfile(folder,selectedFiles))
            switch selectedFiles
                case '.'
                    folder = folder(1:3);
                case '..'
                    N = strfind(folder,'\');
                    if N, folder = folder(1:N(end)-1); else return; end;
                otherwise
                    folder = fullfile(folder,selectedFiles);
            end
            if length(folder)<3, folder = [folder '\']; end
            refresh(folder)
        else
            uiresume(mainFigure);
            delete(mainFigure);
        end
    end
    
    function upOneLevel(varargin)
        N = strfind(folder,'\');
        if N, folder = folder(1:N(end)-1); else return; end;
        if length(folder)<3, folder = [folder '\']; end
        refresh(folder)
    end

    function refresh(folder)
        set([driveMenu fileList],'Enable','off');
        Contents = getFolderContents(folder);
        [driveList,Selected] = getDriveList(folder);
        set(driveMenu,'String',driveList,'Value',Selected,'Enable','on');
        set(fileList,'String',Contents,'Value',1,'Enable','on');
    end

    function pressOpenButton(varargin)
        selectedFiles = Contents(get(fileList,'Value'));
        selectedFiles = cellfun(@(x) regexprep(x,'<[^>]*>',''),selectedFiles,'Uni',0);
        if length(selectedFiles)==1
            handleFileOpen(char(selectedFiles));
        else
            uiresume(mainFigure);
            delete(mainFigure);
        end
    end

    function pressCancelButton(varargin)
        close(mainFigure);
    end
    
    function closeFigureFcn(varargin)
        folder = 0;
        selectedFiles = 0;
        uiresume(mainFigure);
        delete(mainFigure);
    end
end
