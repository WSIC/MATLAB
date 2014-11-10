classdef CTSlicer < handle
    %CTSlicer function opens up inveon CT files in downsampled form and
    %allows user to interactively draw ROIs to decrease file size
    %   Detailed explanation goes here
    %
    % Mathew Divine, May 2013
    
    properties 
        dSFactor            = [];
        pathName            = ''
        imgFileName         = ''
        imgDirectory        = ''
        headerFileName      = ''
        imageHeader         = []
        dSImage             = []
        haveVol             = 0;
        oV                  = [];
        roiLis              = {};
        niiWrite            = 0;
        inveonWrite         = 1;    
        
    end
    properties (SetAccess = private, Hidden = true)
        %-------figure handles------%
        f               = []
        lb              = []
        pbExport        = []
        pbCancel        = []
        tbox            = []
    end
    methods
        function obj = CTSlicer(varargin)
            dialogTitle = 'Choose .hdr file.';
            [INIpath, INIname] = fileparts(mfilename('fullpath'));
            if exist(fullfile(INIpath,[INIname, '.config']),'file')
                INI = headerReader(fullfile(INIpath,[INIname, '.config']));
                startFolder = INI.General.startfolder;
            else
                startFolder = cd;
            end
            filterSpec = fullfile(startFolder,'*.hdr');
            
            if numel(varargin) == 0
                [fileName, obj.pathName,~] = uigetfile(filterSpec, dialogTitle);
                obj.headerFileName = fullfile(obj.pathName, fileName);
                ind = regexp(obj.headerFileName,'.hdr');
                obj.imgFileName = obj.headerFileName(1:ind-1);
            elseif numel(varargin) ==1 && ischar(varargin{1})
                obj.headerFileName = varargin{1};
                ind = regexp(obj.headerFileName,'.hdr');
                obj.imgFileName = obj.headerFileName(1:ind-1);
            elseif (numel(varargin) == 1 && ~ischar(varargin{1}))
                [fileName, obj.pathName] = uigetfile(filterSpec, dialogTitle);
                obj.headerFileName = fullfile(obj.pathName,fileName);
                ind = regexp(obj.headerFileName,'.hdr');
                obj.imgFileName = obj.headerFileName(1:ind-1);
                obj.haveVol = 1;
            else
                errordlg('Too many input arguments')
            end
            if ~fileName
                error('No file selected');
            end
            INI = struct;
            INI.General.startFolder = obj.pathName;
            headerWriter(INI,fullfile(INIpath,[INIname '.config']));
            obj.imageHeader = headerReader(obj.headerFileName);
            obj.determineDownFactor(obj);
          
            if obj.haveVol == 0
                vol = obj.importCTWithDownSample(obj);
            else
                vol = varargin{1};
            end
            obj.oV = overlayVolume(vol);
            %             SpecialEventDataClass(obj);
            obj.roiLis = addlistener(obj.oV,'savedROIs','PostSet',@(src,evnt)CTSlicer.updateROIList(src,evnt,obj));
            obj.makeROIList();
        end
        function obj = makeROIList(obj)
            obj.f = figure('Position',[200 200 180 400],'MenuBar','none','ToolBar','none',...
                'Resize','off','NumberTitle','off');
            obj.lb =  uicontrol('Style','listbox','Position',[5 100 170 260],...
                'Min',0,'Max',2);
            obj.pbExport    =  uicontrol('Style','PushButton','Position',[5 50 170 35],...
                'String','Export');
            set(obj.pbExport,'Callback',@(hO,evnt)exportButtonCallBack(hO,evnt,obj))
            obj.pbCancel    =  uicontrol('Style','PushButton','Position',[5 10  170 35],...
                'String','Cancel');
            obj.tbox        =  uicontrol('Style','Text','Position',[5 365 170 30 ],...
                'String','Exportable ROI List','FontSize',14,'BackgroundColor',[0.8 0.8 0.8]);
        end
        function exportButtonCallBack(~,~,obj)
            if isempty(obj.oV.savedROIs)
                errordlg('Must create ROI before exporting');
            else
                fNames = fieldnames(obj.oV.savedROIs);
                roiList = obj.oV.savedROIs;
                for fn = 1:length(fNames)
                    cROIpos = roiList.(fNames{fn}).('pos');
                    %                obj = calculateInverseDSCoordinates(cROIpos, obj);
                    obj.writeROIImage(cROIpos,fNames{fn},obj);
                end
            end
        end
    end
    
    methods (Static)
        function updateROIList(~,~,obj)
            set(obj.lb,'String',fieldnames(obj.oV.savedROIs))
        end
        function determineDownFactor(obj)
            
            
            X = obj.imageHeader.General.x_dimension;
            Y = obj.imageHeader.General.y_dimension;
            Z = obj.imageHeader.General.z_dimension;
            datasize = [1 2 4 4 4 2 4];
            datasize = datasize(obj.imageHeader.General.data_type);
            sz = X*Y*Z*datasize;        % matrix size in bytes. [2 is uint16]
            dF = round(sz / (1024*1024*512)); % sz / 0.5 GB in bytes
            if dF<1
                dF = 1;
            end
            obj.dSFactor = dF;
        end
        function vol = importCTWithDownSample(obj)
            datatype = {'int8', 'int16', 'int32', 'float32', 'float32', 'in16', 'int32'};
            datasize = [1 2 4 4 4 2 4];
            datatype = datatype{obj.imageHeader.General.data_type};
            datasize = datasize(obj.imageHeader.General.data_type);
            ds = obj.dSFactor;
            X = obj.imageHeader.General.x_dimension;
            Y = obj.imageHeader.General.y_dimension;
            Z = obj.imageHeader.General.z_dimension;
            vol = zeros(length(ds:ds:X),length(ds:ds:Y),length(ds:ds:Z)); % allocate memory
            fid_r = fopen(obj.imgFileName);
            % waitbar preparation
            hw = waitbar(0,'Please wait......Loading image in progress');
            for zz = ds:ds:Z
                slice = fread(fid_r,[X,Y],datatype);
                if isempty(slice)
                    continue
                else
                slice_ds = slice(ds:ds:end,ds:ds:end);
                fseek(fid_r,(X*Y*(ds-1)*datasize),'cof');
                vol(:,:,zz/ds) = slice_ds;
                
                end
                waitbar(zz/Z,hw)
            end
            fclose(fid_r);
            close(hw);
        end
        function writeROIImage(pos,roiName, obj)
            % coordinates are from the downsampled image and start at the
            % top left hand side of the volume and include the length of a
            % rectangluar voi i.e. [x y z xl yl zl]
            x =1; y=2; z=3; xl=4; yl=5; zl=6;
            iX1 = obj.dSFactor*pos(x);
            iY1 = obj.dSFactor*pos(y);
            iZ1 = obj.dSFactor*pos(z);
            iX2 = obj.dSFactor*pos(xl)+iX1;
            iY2 = obj.dSFactor*pos(yl)+iY1;
            iZ2 = obj.dSFactor*pos(zl)+iZ1;
           
            X = obj.imageHeader.General.x_dimension;
            Y = obj.imageHeader.General.y_dimension;
            Z = obj.imageHeader.General.z_dimension;
            % ---------------------------------
            datatype = {'int8', 'int16', 'int32', 'float32', 'float32', 'in16', 'int32'};
            datasize = [1 2 4 4 4 2 4];
            datatype = datatype{obj.imageHeader.General.data_type};
            datasize = datasize(obj.imageHeader.General.data_type);
            
            vol = zeros(length(iX1:iX2),length(iY1:iY2),length(iZ1:iZ2));
            fid_r = fopen(obj.imgFileName);
            fseek(fid_r,iZ1*X*Y*datasize,'bof'); 
            N = 1;
            hw = waitbar(0,'Please wait......Loading ROI volume');
            for zz = iZ1:iZ2
               slice = fread(fid_r,[X,Y],datatype); 
               vol(:,:,N) = slice(iX1:iX2,iY1:iY2);
               waitbar(N/length(iZ1:iZ2),hw);
               N = N + 1;
            end            
            % --------------------------------
            hw = waitbar(.99,hw,'Please wait......Saving ROI volume');
            if obj.niiWrite
                nii = make_nii(vol, [], [], 4, []);
                save_nii(nii, [obj.imgFileName '_' roiName], [])
            elseif obj.inveonWrite 
                obj.imageHeader.General.x_dimension = size(vol,1);
                obj.imageHeader.General.y_dimension = size(vol,2);
                obj.imageHeader.General.z_dimension = size(vol,3);
                obj.imageHeader.General.subject_identifier = [obj.imageHeader.General.subject_identifier '-' roiName];
                obj.imageHeader.General.file_name = [obj.imgFileName '_' roiName '.img.hdr'];
                headerWriter(obj.imageHeader,[obj.imgFileName '_' roiName '.img.hdr'])
                fid = fopen([obj.imgFileName '_' roiName '.img'],'w+');
                fwrite(fid,vol,datatype);
                fclose(fid);
            end
            fclose(fid_r);
            close(hw)
        end

    end
end

