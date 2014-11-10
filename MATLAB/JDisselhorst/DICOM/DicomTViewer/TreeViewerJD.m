%% TREEVIEWER. Visualize the contents of DICOM structures.
%
%
% version 2014.05.02
%
% J.A. Disselhorst. 2009-2014
% Radboud University Nijmegen Medical Centre, Nijmegen (NL)
% University of Twente, Enschede (NL)
% Werner Siemens Imaging Center, Tuebingen (DE)
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 


function TreeViewerJD(Q)
mPath = mfilename('fullpath'); % The path of this m file.
mPath = mPath(1:end-length(mfilename));
%narginchk(0, 2);  % Check for the number of input arguments.
%nargoutchk(0,0);  % Check for the number of output arguments.

% Turn of those annoying warning about migrating functions of this tree.
warning off MATLAB:uitreenode:MigratingFunction  % number 1
warning off MATLAB:uitree:MigratingFunction      % and number 2

    if nargin ~=1
        Q = struct; Q(1).PatientID = '0'; Q(1).PatientName = 'none';
        Q(1).StudyInstanceUID = '0'; Q(1).StudyDescription = 'none';
        Q(1).SeriesInstanceUID = '0'; Q(1).SeriesDescription = 'none';
        Q(1).Filename = ''; Q(1).Modality = 'OT';  
    end
    % (Q = dicominformation thing)
    
    foldericon = fullfile(mPath,'data','folder.gif'); 
    pageicon   = fullfile(mPath,'data','page.gif');
    CTicon     = fullfile(mPath,'data','CT.gif');
    PTicon     = fullfile(mPath,'data','PT.gif');
    MRicon     = fullfile(mPath,'data','MR.gif');
    NMicon     = fullfile(mPath,'data','NM.gif');
    RTicon     = fullfile(mPath,'data','RT.gif');

    root = uitreenode([0 0 0 0], 'DICOM', foldericon, false);  % value, string to show, icon, 
    dimensions = [0, 0, 1000, 800];  % uitree does not support 'Units'-'Normalized', therefore absolute dims.
    fg = figure('Name','DICOM. J.A. Disselhorst','NumberTitle','off','Position',dimensions+[40 40 0 0],'MenuBar','none','Resize','off');
    
    mf = uimenu('Label','File');
    uimenu(mf,'Label','Open Directory','Accelerator','O','Callback',@openDirectory);
    me = uimenu(mf,'Label','Extension');
    uimenu(me,'Label','Dicom (*.ima)','Callback',{@extChange, 1});
    uimenu(me,'Label','Dicom (*.dcm)','Callback',{@extChange, 2}); 
    uimenu(me,'Label','Dicom (*.dcm, *.ima)','Checked','on','Callback',{@extChange, 3});  ext = {'*.dcm','*.ima'};
    uimenu(me,'Label','Dicom (*)','Callback',{@extChange, 4});
    ms = uimenu('Label','Selected');
    uimenu(ms,'Label','Copy to ...','Callback',@copyFiles);
    uimenu(ms,'Label','Save to Workspace','Callback',@save2Workspace);
    uimenu(ms,'Label','Save DICOMDIR to Workspace','Callback',@saveQ2Workspace);
    uimenu(ms,'Label','Display','Callback',{@selectedFunction,'disp'});
    uimenu(ms,'Label','Calculate T1','Callback',{@selectedFunction,'t1'});
    uimenu(ms,'Label','Calculate T2','Callback',{@selectedFunction,'t2'});
    uimenu(ms,'Label','Calculate ADC','Callback',{@selectedFunction,'adc'});
    %uimenu(ms,'label','Display Header','Callback',{@selectedFunction,4});
    mh = uimenu('Label','Help');
    uimenu(mh,'Label','About','Callback',@ShowAbout);
    t = uitree(fg,'Root', root, 'ExpandFcn', @expandFunction,'Position',[0 0 .4 1].*dimensions);
    e = uicontrol(fg,'Style','listbox','Units','normalized','Position',[.4,0,.6,1], ...
        'BackgroundColor','white','Min',0,'Max',2,'HorizontalAlign','Left', ...
        'CallBack',@listBoxClick);
    set(t, 'NodeSelectedCallback', @selectFunction,'MultipleSelectionEnabled',1);
    startDir = cd;
    try
        t.getTree.expandRow(0);
    end
 
    function ShowAbout(varargin)   % Show the about dialog
    aboutText = {'','J.A. Disselhorst, 2009-2014','J.Disselhorst@gmail.com', ...
        '', 'THIS SOFTWARE IS PROVIDED "AS IS"','USE AT YOUR OWN RISK!'};
    af = figure('Name','About','NumberTitle','off','Position',[300,500,300,160],'MenuBar','none','Resize','off');
    uicontrol('Parent',af,'Style','text','Units','normalized','Position',[.01 .01 .98 .98], ...
        'String',aboutText,'FontSize',10);
    end
    
    function nodes = expandFunction(~, value)   % Expand the tree after clicking
        switch value(1)
            case 0   % EXPAND PATIENTS
                [AV,~,AP] = unique({Q.PatientID});
                for i=1:length(AV)
                    nodes(i) = uitreenode([1 i 0 0], [char(Q(find(AP==i,1,'first')).PatientName), ...
                       ' (', strtrim(char(Q(find(AP==i,1,'first')).PatientID)), ')', ...
                       ' [', num2str(length(unique({Q(AP==i).StudyInstanceUID}))), ']'], foldericon, 0);
                end
            case 1   % EXPAND STUDIES
                [~,~,AP] = unique({Q.PatientID});
                AL=AP==value(2);
                R = {Q.StudyInstanceUID}; R(~AL)= {' '};
                [BV,~,BP] = unique(R); n=0; if strcmpi(char(BV(1)),' '),n=1; end
                for i=1+n:length(BV)  % give each node a good description.
                    nodes(i-n) = uitreenode([2 value(2) i-n 0], [strtrim(char(Q( find(BP==i,1,'first') ).StudyDescription)), ...
                        ' [', num2str(length(unique({Q(BP==i).SeriesInstanceUID}))), ']'], foldericon, 0);
                end
            case 2   % EXPAND SERIES
                [~,~,AP] = unique({Q.PatientID});
                AL=AP==value(2);
                R = {Q.StudyInstanceUID}; R(~AL)= {' '};
                [BV,~,BP] = unique(R); n=0; if strcmpi(char(BV(1)),' '),n=1; end
                BL = (BP==value(3)+n)&AL;
                S = {Q.SeriesInstanceUID}; S(~BL)={' '};
                [CV,~,CP] = unique(S); m=0; if strcmpi(char(CV(1)),' '),m=1; end
                for i = 1+m:length(CV)
                    Modality = char(Q(find(CP==i,1,'first')).Modality);   % What is the modality? Choose proper icon.
                    if strcmpi(Modality,'CT')
                        itemicon = CTicon;
                    elseif strcmpi(Modality,'PT')
                        itemicon = PTicon;
                    elseif strcmpi(Modality,'NM')
                        itemicon = NMicon;
                    elseif strcmpi(Modality,'MR')
                        itemicon = MRicon;
                    elseif strcmpi(Modality,'RTSTRUCT');
                        itemicon = RTicon;
                    else
                        itemicon = pageicon;
                    end
                    % give the node a good description:
                    nodes(i-m) = uitreenode([3 value(2) value(3) i-m], ...
                        [strtrim(char(Q(find(CP==i,1,'first')).SeriesDescription)), ' [', num2str(length(find(CP==i))), ']'], itemicon, 1);
                end
        end
    end

    function selectFunction(tree, varargin)   % what happens when a node is clicked.
        nodes = tree.SelectedNodes;   % What is the selected node?
        if isempty(nodes)        % nothing selected
            return               % nothing to do.
        end
        list = false;
        for i = 1:length(nodes)  % loop all selected nodes.
            node = nodes(i);
            p = node.getPath;
            p = p(end).getValue;
            if p(1)>=3           % only when a Series was clicked do something.
                [~,~,AP] = unique({Q.PatientID});
                AL=AP==p(2);
                R = {Q.StudyInstanceUID}; R(~AL)= {' '};
                [BV,~,BP] = unique(R); n=0; if strcmpi(char(BV(1)),' '),n=1; end
                BL = (BP==p(3)+n)&AL;
                S = {Q.SeriesInstanceUID}; S(~BL)={' '};
                [CV,~,CP] = unique(S); m=0; if strcmpi(char(CV(1)),' '),m=1; end
                CL = (CP==p(4)+m)&BL;
                list = list|CL;  % Add the files to the list.
            end
        end
        set(e,'Value',1:sum(list));       % Fill the list
        set(e,'String',{Q(list).Filename})  % Show the filenames.

    end

    function listBoxClick(hObject, varargin)  % Click one of the filenames.
        clickType = get(fg,'SelectionType');
        if strcmp(clickType,'open')
            try
                selected = get(hObject,'Value'); 
                files = get(hObject,'String');
                filenames = files(selected);
                intel = dicominfo(char(filenames(1)));        % dicom information
                h = findobj('Name','DICOM Information');     % Is a image viewing window open?
                if h                                    % yes, use it.
                    figure(h(1)); clf
                else                                    % no, create it.
                    h = figure('Name','DICOM Information','MenuBar','none','NumberTitle','off'); 
                end
                
                try
                    image = dicomread(intel);
                    subplot(121); imshow(image,[]);
                end
                list = uicontrol(h,'Style','listbox','Units','normalized','Position',[0.5,0,0.5,1], ...
                    'BackgroundColor','white','Min',0,'Max',2,'HorizontalAlign','Left',...
                    'FontName','Courier');
                intelName = char(fieldnames(intel));
                intel = struct2cell(intel);            % Make a cell from the dicominformation structure           

                for i = 1:size(intelName,1);
                    try
                        info = cell2mat(intel(i));
                        intel(i) = {[intelName(i,:),' : ', num2str(info(:)')]};   % show each item
                    catch   %#ok<*CTCH> % Doesn't work
                        try   % could be a substruct?
                            intel(i) = {[intelName(i,:),' : ', num2str(cell2mat(struct2cell(info(:))'))]};
                        catch ME  % Don't know what problem is. Show error line:
                            intel(i) = {[intelName(i,:),' : Parse error: ', ME.message]};
                        end
                    end
                end
                set(list,'String',intel);
            end
        end
    end

    function openDirectory(varargin)  % Open a directory to process dicom contents.
        startDir = uigetdir(startDir,'Select the input directory');   % GUI to select folder.
        if startDir    % something has been chosen.
            wb = waitbar(0,'Finding dicoms'); drawnow; 
            allFiles = subdir(startDir, ext);   % Search for files.
            if ~isempty(allFiles)       % files have been found
                Q = struct; % base variable, all important dicom information is stored here.
                medName = 'iptformats'; % for older matlabs: 'medformats'
                privateFolder = fullfile(matlabroot,'toolbox','images',medName,'private');
                dcmParse = getPrivateFcn(privateFolder,'dicomparse');

                dcmTags = {'PatientID','PatientName','StudyInstanceUID','StudyDescription',...
                    'SeriesInstanceUID','SeriesDescription','Modality'};
                dcmGroups = zeros(1,length(dcmTags)); dcmElems = dcmGroups;
                for ii = 1:length(dcmTags)
                    [dcmGroups(ii), dcmElems(ii)] = dicomlookup(dcmTags{ii});
                end
                fprintf('%1.0f files found.\n',length(allFiles));
                for i = 1:length(allFiles)  % loop through all files.
                    waitbar(i/length(allFiles),wb,sprintf('Reading dicoms: %1.0f%%',i/length(allFiles)*100))
                    try  % parse the dicom files
                        dcmInfo = dcmParse(allFiles(i).name,allFiles(i).bytes, 'L', false, dicomdict('get_current'));
                        for ii = 1:length(dcmTags) % Read the required dcmTags
                            idx = ([dcmInfo.Group] == dcmGroups(ii)) & ([dcmInfo.Element] == dcmElems(ii));
                            Q = setfield(Q,{i},dcmTags{ii},char(dcmInfo(idx).Data));
                        end
                    catch  % When something goes wrong, show all information as 'Error'
                        Q(i).PatientID = 'Error';
                        Q(i).PatientName = 'Error';
                        Q(i).StudyInstanceUID = 'Error';
                        Q(i).StudyDescription = 'Error';
                        Q(i).SeriesInstanceUID = 'Error';
                        Q(i).SeriesDescription = 'Error';
                        Q(i).Modality = 'Error';
                    end
                    try
                        Q(i).Filename = allFiles(i).name;
                    catch
                        Q(i).Filename = 'error';
                    end
                end
                try delete(wb); end    % remove waitbar.
                % Build the tree, with some settings:
                root = uitreenode([0 0 0 0], startDir, foldericon, false);  % value, string to show, icon, 
                t = uitree(fg,'Root', root, 'ExpandFcn', @expandFunction,'Position',[0 0 .4 1].*dimensions);
                set(t, 'NodeSelectedCallback', @selectFunction,'MultipleSelectionEnabled',1);
                set(e,'Value',1);
                set(e,'String','')
                try
                    t.getTree.expandRow(0);
                end
            else  % nothing has been found
                delete(wb); % close the waitbar.
                msgbox('No dicoms found. (check extension?)','0 Results','warn');
            end
        else  % nothing has been chosen or other error.
            fprintf('ERROR. Incorrect path\n');
            startDir = cd;
        end
    end

    function extChange(hObject, ~, type)  % change the extension to search for
        set(get(get(hObject,'parent'),'children'),'Checked','off');
        set(hObject,'Checked','on');
        switch type
            case 1 
                ext = {'*.ima'};
            case 2 
                ext = {'*.dcm'};
            case 3 
                ext = {'*.ima','*.dcm'};
            case 4
                ext = {'*'};
        end
    end

    function selectedFunction(~, ~, type)  % File-Selected-... has been clicked.
        selected = get(e,'Value');    % Get the files selected.
        values = get(e,'String');
        if isempty(values)
            warning('Nothing selected!');
            return;
        end
        values=values(selected);
        try
            [IMG,HDR] = loadDicom(values);
            switch type
                case 'disp' % display.
                    overlayVolume(IMG);
                case 'adc'
                    ADC = calculateDiffusion(IMG,HDR,[],'ADClin');
                    overlayVolume(ADC);
                case 't2'
                    T2 = calculateT2Map(IMG,HDR);
                    overlayVolume(T2);
                case 't1'
                    T1 = calculateT1Map(IMG,HDR);
                    overlayVolume(T1);
            end
        catch mE
            mE.message
        end
    end

    function copyFiles(varargin)
        selected = get(e,'Value');    % Get the files selected.
        values = get(e,'String');
        if isempty(values)
            warning('Nothing selected!');
            return;
        end
        values=values(selected); numFiles = length(values);
        startDir = uigetdir([],'Select the output directory.');
        if startDir
            wb = waitbar(0,'Copying files...');
            for i = 1:numFiles
                copyfile(char(values(i)),startDir);
                waitbar(i/numFiles,wb);
            end
            delete(wb)
        else
            fprintf('ERROR. Incorrect path\n');
        end
    end

    function save2Workspace(varargin)   % save to workspace
        selected = get(e,'Value');    % Get the files selected.
        fileNames = get(e,'String');
        if isempty(fileNames)
            warning('Nothing selected!');
            return;
        end
        fileNames=fileNames(selected); 
        
        tempinfo = dicominfo(char(fileNames(1)));
        if strcmpi(tempinfo.Modality,'RTSTRUCT');
            [DCInfo, binaryImage, ROINames] = readDicomRTstruct(char(fileNames(1)),0);
            assignin('base','DCInfo',DCInfo);
            assignin('base','binaryImage',binaryImage);
            assignin('base','ROINames',ROINames);
            msgbox('The ROI data and dicominformation have been saved to workspace as ''binaryImage'', ''ROINames'' and ''DCInfo''.','Saved to workspace','help')
        else
            [imageMatrix, information] = loadDicom(fileNames);
            assignin('base','imageMatrix',imageMatrix);
            assignin('base','information',information);
            msgbox('The image matrix and dicominformation have been saved to workspace as ''imageMatrix'' and ''information''.','Saved to workspace','help')
        end
    end

    function saveQ2Workspace(varargin)
        nodes = t.SelectedNodes;     % What is the selected node?
        if isempty(nodes), return; end  % Nothing selected, nothing to do.
        list = false;
        for i = 1:length(nodes)
            node = nodes(i);
            p = node.getPath;
            p = p(end).getValue;
            if p(1)>=3   % series
                [~,~,AP] = unique({Q.PatientID});
                AL=AP==p(2);
                R = {Q.StudyInstanceUID}; R(~AL)= {' '};
                [BV,~,BP] = unique(R); n=0; if strcmpi(char(BV(1)),' '),n=1; end
                BL = (BP==p(3)+n)&AL;
                S = {Q.SeriesInstanceUID}; S(~BL)={' '};
                [CV,~,CP] = unique(S); m=0; if strcmpi(char(CV(1)),' '),m=1; end
                CL = (CP==p(4)+m)&BL;
                list = list|CL;  % Add to the list.
            elseif p(1)==2  % study
                [~,~,AP] = unique({Q.PatientID});
                AL=AP==p(2);
                R = {Q.StudyInstanceUID}; R(~AL)= {' '};
                [BV,~,BP] = unique(R); n=0; if strcmpi(char(BV(1)),' '),n=1; end
                BL = (BP==p(3)+n)&AL;
                list = list|BL;  % Add to the list.
            elseif p(1)== 1 % patient
                [~,~,AP] = unique({Q.PatientID});
                AL=AP==p(2);
                list = list|AL;  % Add to the list
            else % Everything.
                list = true(1,length(Q));
            end
            assignin('base','DICOMDIR',Q(list));
        end
    end

end

function Files = subdir(folder,filter)
    % Based on subdir.
    % Copyright 2006 Kelly Kearney
    pathstr = genpath(folder);
    seplocs = strfind(pathstr, pathsep);
    loc1 = [1 seplocs(1:end-1)+1];
    loc2 = seplocs(1:end)-1;
    pathfolders = arrayfun(@(a,b) pathstr(a:b), loc1, loc2, 'UniformOutput', false);
    Files = [];
    for ifolder = 1:length(pathfolders)
        for iext = 1:length(filter)
            NewFiles = dir(fullfile(pathfolders{ifolder}, filter{iext}));
            if ~isempty(NewFiles)
                fullnames = cellfun(@(a) fullfile(pathfolders{ifolder}, a), {NewFiles.name}, 'UniformOutput', false); 
                [NewFiles.name] = deal(fullnames{:});
                Files = [Files; NewFiles];
            end
        end
    end
    if ~isempty(Files)
        Files([Files.isdir]) = [];
    end
end

function privateFcn = getPrivateFcn(privateDir,fcnName)
    oldDir = cd(privateDir);         %# Change to the private directory
    privateFcn = str2func(fcnName);  %# Get a function handle
    cd(oldDir);                      %# Change back to the original directory
end