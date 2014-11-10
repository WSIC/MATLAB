%% Configuration files for the Inveon.
% J.A. Disselhorst (2008-2009)
% Radboud University Nijmegen Medical Centre
% University of Twente
% 
% Run the function for help (in GUI)
function GUI_Config_Template

    clear all; close all; clc;
    fprintf('GUI_Config_Template v1.0 - JA Disselhorst\nCreate Configuration files for the Inveon\n');
    DirLoaded = 0;
    ConfigLoaded = 0;
    aantalVars = 0;
    listFiles = 0;
    configExt = 0;
    exten = {'*.scn','*.lst'};
    current_directory = cd;
    randoms = 'bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ1234567890';
    fig = figure('Position',[5,50,1200,800]);
    lijst = uicontrol('Style','listbox','Units','normalized', 'Value',1,'String','...','min',1,'max',1,...
        'Position',[0 .02 .5 .98],'Enable','off');
    progress = axes('Color','black','Units','normalized', ...
        'Position',[0 0 .5 .02]);
    axis([0 1 0 1]);
    init = uipanel('Title','Initialize','Position',[.5 .75 .5 .25]);
    config = uipanel('Title','Config','Position',[.5 0 .5 .75]);
    % Edits --------------------------------------------------------------
    startdir = uicontrol('Parent',init,'Style','edit','Units','normalized','String',cd,...
         'Position',[.11 .88 .68 .12],'HorizontalAlignment','left','Backgroundcolor','white');
    configbestand = uicontrol('Parent',init,'Style','edit', 'String','','Units','normalized',...
         'Position',[.11 .76 .78 .12],'HorizontalAlignment','left','Backgroundcolor','white');
    extensie = uicontrol('Parent',init,'Style','popupmenu','Units','normalized','String',exten,...
         'Position',[.79 .88 .1 .12],'Backgroundcolor','white');
    outputedit = uicontrol('Parent',init,'Style','edit','Units','normalized','String',cd,...
         'Position',[.11 .64 .78 .12],'HorizontalAlignment','left','Backgroundcolor','white');
    outputnameedit = uicontrol('Parent',init,'Style','edit','Units','normalized','String','[FILENAME]_[DATE][RANDOM]', ...
         'Position',[.11 .52 .78 .12],'HorizontalAlignment','left','Backgroundcolor','white');
    % Buttons ------------------------------------------------------------
    dirchange = uicontrol('Parent',init,'Style','pushbutton','Units','normalized','String','...','Callback',{@dirchange_Callback},...
         'Position',[.89,.88,.05,.12]);
    configchange = uicontrol('Parent',init,'Style','pushbutton','Units','normalized','String','...','Callback',{@configchange_Callback},...
         'Position',[.89,.76,.05,.12]);
    outputchange = uicontrol('Parent',init,'Style','pushbutton','Units','normalized','String','...','Callback',{@outputchange_Callback},...
         'Position',[.89,.64,.05,.12]);
    dirload = uicontrol('Parent',init,'Style','pushbutton','Units','normalized','String','Go','Callback',{@dirload_Callback},...
         'Position',[.94,.88,.05,.12]);
    configload = uicontrol('Parent',init,'Style','pushbutton','Units','normalized','String','Go','Callback',{@configload_Callback},...
         'Position',[.94,.76,.05,.12]);
     
    StartButton = uicontrol('Parent',init,'Style','pushbutton','Units','normalized','String','Start','Callback',{@StartButton_Callback},...
         'Position',[.9,.02,.1,.36]);
     
    % Text ---------------------------------------------------------------
    uicontrol('Parent',init, 'Style','text','Units','normalized','String','Dir: ',...
        'Position', [.01 .86 .1 .12], 'HorizontalAlignment','right');
    uicontrol('Parent',init, 'Style','text','Units','normalized','String','template: ',...
        'Position', [.01 .74 .1 .12], 'HorizontalAlignment','right');
    uicontrol('Parent',init, 'Style','text','Units','normalized','String','output dir: ',...
        'Position', [.01 .62 .1 .12], 'HorizontalAlignment','right');
    uicontrol('Parent',init, 'Style','text','Units','normalized','String','out name: ',...
        'Position', [.01 .50 .1 .12], 'HorizontalAlignment','right');
    uicontrol('Parent',init, 'Style','text','Units','normalized','String','[PATH], [FILENAME] and [EXTENSION] are the path, filename and extension of the input file and can be used in all fields. [RANDOM] and [DATE] insert 8 random characters and the current date+time respectively. Attenuation and Normalization filenames can be changed either by right clicking or normal editing. [ATTENFILEINFOLDER] will search for an attanuation file (*.atn) in the folder of the sinogram, its output INCLUDES the path! Add additional variables with [+] button. Delete a variable by clearing its name.', ...
        'Position', [.01 .02 .85 .45], 'HorizontalAlignment','left');
    % - - -- - - - - - - - - 
 % init names.
 addvar = 0;
 vars.name1 = 0;
 vars.value1 = 0;
 % //end.
    
    function outputchange_Callback(source,eventdata)
        % Change the output directory
        startpath = get(outputedit,'String');
        directory_name      = uigetdir(startpath,'Choose data-directory');
        if directory_name~=0
            set(outputedit,'String',directory_name);
        end
    end  
    
    function dirchange_Callback(source,eventdata)
        % Change the input directory
        startpath = get(startdir,'String');
        directory_name      = uigetdir(startpath,'Choose data-directory');
        if directory_name~=0
            set(startdir,'String',directory_name);
        end
    end

    function configchange_Callback(source,eventdata)
        % change the config file to load.
        startbestand = get(configbestand,'String');
        [configfile_name, configfile_path] = uigetfile({'*.uPetRecon','Reconstruction Configs';'*.uPetHist','Histogram Configs';'*.*','All files'},'Choose template configuration file',startbestand);
        config_name = fullfile(configfile_path, configfile_name);
        if config_name~=0
            set(configbestand,'String',config_name);
            % autoload if succesful. 
            configload_Callback(1,2);
        end
    end

    function dirload_Callback(source,eventdata)
        % Load the directory, look for either *.scn or *.lst files.
        startpath = get(startdir,'String');
        ext = char(exten(get(extensie,'Value')));
        fprintf('searching for "%s" in directory "%s".... ',ext,startpath);
        % Uses MS-DOS, so only Windows. Probably error otherwise.
        [status, results]   = dos(['dir "' startpath '\' ext '" /s /b']);
        
        nummers             = [0, findstr(results,char(10))];
        aantalBestanden     = length(nummers)-1;
        listFiles = cell(aantalBestanden,1);
        for n = 1:aantalBestanden
            listFiles(n,:) = {results(nummers(n)+1:nummers(n+1)-1)};
        end
        set(lijst,'String',listFiles);
        set(lijst,'max',aantalBestanden);
        set(lijst,'Enable','on');
        fprintf('finished. %1.0f files found\n',aantalBestanden);
        DirLoaded = 1;
    end

    function configload_Callback(source,eventdata)
        delete(get(config,'Children'));
        % load config file
        % change output directories etc.
        configFile = get(configbestand,'String');
        [configPath, configName, configExt] = fileparts(configFile);
        fprintf('loading "%s".... ',configFile);
        bestand = fopen(configFile);
        % Row length max 256, can be changed, but should be sufficient. Ignore comments
        a = textscan(bestand, '%s %256[ 1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/\\:.,-_+`!@#$%^&*()]',...
            'CommentStyle','#','ReturnOnError',0,'MultipleDelimsAsOne',0,'CollectOutput',1);
        a=a{1,1};
        fclose(bestand);

        for jd=1:size(a,1)
            % Create the var name and value input boxes. Items connected to
            % the input turn green, norm and attn file inputs turn orange.
            varname = cell2mat(a(jd,1));
            varvalue = cell2mat(a(jd,2));
            functie = '';
            if strcmp(varname ,'scan_filename')==1
                color = [.8 1 .8];
                varvalue = '[PATH][FILENAME][EXTENSION]';
                set(lijst,'BackgroundColor',[.8 1 .8]);
            elseif strcmp(varname, 'listmode_filename')==1
                color = [.8 1 .8];
                varvalue = '[PATH][FILENAME][EXTENSION]';
                set(lijst,'BackgroundColor',[.8 1 .8]);   
            elseif strcmp(varname,'image_filename')==1
                color = [.8 1 .8];
                varvalue = '[PATH][FILENAME].img';
                set(lijst,'BackgroundColor',[.8 1 .8]);
            elseif strcmp(varname,'!final_image_filename')==1
                color = [.8 1 .8];
                varvalue = '[PATH][FILENAME].img';
                set(lijst,'BackgroundColor',[.8 1 .8]);
            elseif strcmp(varname, 'output_filename')==1
                color = [.8 1 .8];
                varvalue = '[PATH][FILENAME].scn';
                set(lijst,'BackgroundColor',[.8 1 .8]);
            elseif strcmp(varname, 'scatter_filename')==1
                color = [.8 1 .8];
                varvalue = '[PATH][FILENAME]_Scatter.scn';
                set(lijst,'BackgroundColor',[.8 1 .8]);
                
            elseif strcmp(varname, 'norm_filename')==1
                color = [1 .9 .8];
                functie = {@NormFile};
            elseif strcmp(varname, 'attn_filename')==1
                color = [1 .9 .8];
                functie = {@AttnFile};
                
            else
                color = 'white';
            end
            eval(['vars.name' num2str(jd) '=uicontrol(''Parent'',config,''Style'',''edit'',''Units'',''normalized'',''BackgroundColor'',''white'',''Position'', [.01 .99-jd*.025 .28 .024], ''HorizontalAlignment'',''left'',''String'',varname);']);
            eval(['vars.value' num2str(jd) '=uicontrol(''Parent'',config,''Style'',''edit'',''Units'',''normalized'',''BackgroundColor'',color,''Position'', [.3 .99-jd*.025 .69 .024], ''HorizontalAlignment'',''left'',''String'',varvalue,''ButtonDownFcn'',functie);']);
        end
        addvar = uicontrol('Parent',config,'Style','pushbutton','Units','normalized','String','+','Callback',{@AddVar_Callback},...
                'Position',[.97,.96-jd*.025,.024,.024]);
        
        ConfigLoaded = 1;
        aantalVars = jd;
        fprintf('finished\n');
    end

    function AddVar_Callback(source,eventdata)
        % Add an additional variable.
        aantalVars = aantalVars + 1;
        jd = aantalVars;
        eval(['vars.name' num2str(jd) '=uicontrol(''Parent'',config,''Style'',''edit'',''Units'',''normalized'',''BackgroundColor'',''white'',''Position'', [.01 .99-jd*.025 .28 .024], ''HorizontalAlignment'',''left'',''String'','''');']);
        eval(['vars.value' num2str(jd) '=uicontrol(''Parent'',config,''Style'',''edit'',''Units'',''normalized'',''BackgroundColor'',''white'',''Position'', [.3 .99-jd*.025 .69 .024], ''HorizontalAlignment'',''left'',''String'','''');']);
        positie = get(addvar,'Position');
        set(addvar,'Position',positie-[0 .025 0 0]);
    end

    function NormFile(source,eventdata)
        % Change the normalization file name with GUI.
        pad = get(source,'String');
        [FileName,PathName,FilterIndex] = uigetfile({'*.nrm';'norm. files (*.nrm)';'*.*';'all files (*.*)'},...
            'Select normalization file',pad);
        if PathName~=0
            pad = fullfile(PathName, FileName);
            set(source,'String',pad);
        end
    end
        
    function AttnFile(source,eventdata)
        % Change the attenuation file name with GUI.
        pad = get(source,'String');
        [FileName,PathName,FilterIndex] = uigetfile({'*.atn';'atten. files (*.atn)';'*.*';'all files (*.*)'},...
            'Select attenuation file',pad);
        if PathName~=0
            pad = fullfile(PathName, FileName);
            set(source,'String',pad);
        end
    end
    
     function StartButton_Callback(source,eventdata)
         % Run the script, write the file. 
         if (ConfigLoaded == 1)&&(DirLoaded==1)
             fprintf('Creating Configuration Files..... ');
             set(get(config,'Children'),'Enable','off');
             set(lijst,'Enable','off','BackgroundColor',[.7 .7 .7]);
             set(get(init,'Children'),'Enable','off');
             
             Selection = get(lijst,'Value');
             outputDir = get(outputedit,'String');
             outputName1 = get(outputnameedit,'String');
             
             Selection = listFiles(Selection);
             
             aantalBestanden = length(Selection);
             for bestandjes = 1:aantalBestanden
                 currentFile = char(Selection(bestandjes));
                 [currentPath, currentName, currentExt] = fileparts(currentFile);
                 
                 outputName = strrep(outputName1,'[FILENAME]',currentName);
                 outputName = strrep(outputName,'[EXTENSION]',currentExt);
                 outputName = strrep(outputName,'[RANDOM]',randoms(round(rand(1,8).*49+1)));
                 outputName = strrep(outputName,'[DATE]',datestr(now, 'yyyymmddHHMMSS'));
 
                 % Header. All commented so probably optional.
                 configFile = fopen(fullfile(outputDir, [outputName configExt]) , 'w+t');
                 fprintf(configFile, '#Inveon PET Configuration Settings\n#Protocol Version: 0x0001\n#Created by: J.A. Disselhorst\n#Created on: %s by: Matlab\n\n', ...
                            datestr(now, 'mm/dd/yyyy HH:MM:SS AM'));
                 for jd = 1:aantalVars
                     % write real data.
                     varname = eval(['get(vars.name' num2str(jd) ',''String'');']);
                     varvalue = eval(['get(vars.value' num2str(jd) ',''String'');']);
                     varvalue = strrep(varvalue,'[PATH]',[currentPath '\']);
                     varvalue = strrep(varvalue,'[FILENAME]',currentName);
                     varvalue = strrep(varvalue,'[EXTENSION]',currentExt);
                     
                     if regexp(varvalue,'[ATTENFILEINFOLDER]')
                         files = dir(fullfile(currentPath,'*.atn'));
                         if isempty(files)
                             [FileN,PathN] = uigetfile({'*.atn';'atten. files (*.atn)';'*.*';'all files (*.*)'},'Select attenuation file',currentPath);
                             attenFile = fullfile(FileN,PathN);
                         elseif length(files)>1
                             choice = menu('multiple atten found, select 1',{files.name});
                             if ~choise
                                 error('No file selected, aborting!');
                             else
                                 attenFile = fullfile(currentPath,files(choice).name);
                             end
                         else
                             attenFile = fullfile(currentPath,files.name);
                         end
                         varvalue = strrep(varvalue,'[ATTENFILEINFOLDER]',attenFile);
                     end
                     varvalue = strrep(varvalue,'[RANDOM]',randoms(round(rand(1,8).*49+1)));
                     varvalue = strrep(varvalue,'[DATE]',datestr(now, 'yyyymmddHHMMSS'));
                     if ~isempty(varname)
                        % delete empty variables.
                        fprintf(configFile, '%s\t\t %s\n',varname,varvalue);
                     end
                     % / / / / 
                 end
                 fclose(configFile);
                 patchy = patch([0 (bestandjes)/aantalBestanden (bestandjes)/aantalBestanden 0],[0 0 1 1],[1 0 0]);
                set(fig,'Name',sprintf('%1.0f%%',floor((bestandjes)/aantalBestanden*100)));
                drawnow;
             end
             % ///.
             
             fprintf('finished. Output in "%s"\n',outputDir);
             set(get(config,'Children'),'Enable','on');
             set(lijst,'Enable','on','BackgroundColor',[.8 1 .8]);
             set(get(init,'Children'),'Enable','on');
             set(patchy,'FaceColor',[0 .7 0]);
             
         end
     end

uiwait(fig)
fprintf('Exit\n');
end