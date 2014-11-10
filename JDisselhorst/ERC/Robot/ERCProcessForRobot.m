function [modelFV,holderFV] = ERCProcessForRobot(dicomFile,method)

%% Initialize
close all; clc
[mfolder,mname] = fileparts(mfilename('fullpath')); % Path of the function.
if exist(fullfile(mfolder,'data',[mname, '.config']),'file') && exist('headerReader.m','file');
    INI = headerReader(fullfile(mfolder,'data',[mname, '.config']));
    openFileName = INI.General.openfilename;
    openPathName = INI.General.openpathname;
    saveFileName = INI.General.savefilename;
    savePathName = INI.General.savepathname;
    referenceUID = INI.General.referenceuid;
else
    openFileName = '*.dcm';
    openPathName = cd;
    saveFileName = sprintf('CNC_%s_%08.0f.stl',datestr(now,'yymmdd'),rand*1E8);
    savePathName = cd;
    referenceUID = '1.2.826.0.1.3417726.3.19410.20140924172437555';
end

if nargin<1 % No inputs
    dicomFile = 0;
else % dicomfile given
    [openPathName,openFileName,ext] = fileparts(dicomFile);
    openFileName = [openFileName,ext];
end
if nargin<2 % No method provided.
    method = 0;
end

%% Load the RTSTRUCT-DICOM
if ~dicomFile
    [openFileName,openPathName] = uigetfile({'*.dcm';'*.ima';'*'},'Pick a DICOM RTSTRUCT with the regions-of-interest',fullfile(openPathName,openFileName));
    if ~openFileName
        fprintf('aborted.\n');
    end
end
dicomFile = fullfile(openPathName,openFileName); 
[binaryImages, ROINames, dicomHeader,~,~,positions] = readDicomRTstruct(dicomFile);
[z,y,x] = meshgrid((round((positions(2,1)+0.05)*100):10:round((positions(2,2)-0.05)*100))/100, ...
                   (round((positions(1,1)+0.05)*100):10:round((positions(1,2)-0.05)*100))/100, ...
                   (round(positions(3,1)*100):10:round(positions(3,2)*100))/100);
N = size(binaryImages,4);
c = zeros(N,3); % the center of each object.
for ii = 1:N
    IM = binaryImages(:,:,:,ii);
    c(ii,:) = [mean(x(IM)), mean(y(IM)), mean(z(IM))];
end

% Check if the ROI was made in the expected series:
if ~strcmp(referenceUID,dicomHeader.SeriesInstanceUID)
    warning('Dicom Series Instance UID: %s\nExpected UID:              %s\n',dicomHeader.SeriesInstanceUID,referenceUID)
%     response = questdlg(sprintf('DICOM series instance unique identifier different then expected! Continue?'),...
%         'Different DICOM UID','Yes','No','No');
%     if ~strcmp(response,'Yes')
%         fprintf('aborted.\n');
%         return
%     else
%         response = questdlg(sprintf('Set new DICOM series instance unique identifier as default?'),...
%         'Set new DICOM UID default','Yes','No','No');
%         if strcmp(response,'Yes')
%             referenceUID = dicomHeader.SeriesInstanceUID;
%         end
%     end
end

%% Choose the method
if ~method
    method = questdlg('Choose your method for processing:','Choose method','Cylinders','Voxels','Cylinders');
    if isempty(method)
        error('aborted');
    end
end

%% Method I: Create cylinders
if strcmpi(method,'Cylinders')
    n = 30;
    H = 3.2; 
    rt = 1;
    rb = 4;
    
    nC = size(c,1);
    bl = min(c(:,3))-H/2-0.1;
    faces = zeros(n*8*nC,3);
    vertices = zeros(n*10*nC,3);
    for ii = 1:nC
        [F,V] = createCylinderWithBase(H,c(ii,:)-[0 0 H/2],bl,rt,rb,n);
        vertices((ii-1)*n*10+1:ii*n*10,:) = V;
        faces((ii-1)*n*8+1:ii*n*8,:) = F+(ii-1)*n*10;
    end
    [vertices,~,ic] = unique(vertices,'rows');
    faces = ic(faces);
    
    % base plate:
    nV = size(vertices,1);
    vertices(nV+1:nV+4,:) = [-58.5,-31, bl; -58.5,31, bl; 58.5,31,bl; 58.5,-31,bl];
    nF = size(faces,1);
    faces(nF+1:nF+2,:) = [nV+1,nV+3,nV+2; nV+1,nV+4,nV+3];

    % Create FV structure:
    modelFV = struct;
    modelFV.vertices = vertices;
    modelFV.faces = faces;
end

%% Method I: Create cylinders
if strcmpi(method,'Cylinders2')
    % Base cylinder:
    r = 1;    % Radius in mm
    h = 1;    % Height in mm
    n = 32;   % Number of points
    [x,y,z] = cylinder(r,n); z = z*h-h/2;
    baseVertices = [[0;0;x(:)],[0;0;y(:)],[z(1);z(end);z(:)]]; 
    baseFaces = zeros(4*n,3);
    for ii = 1:n
        baseFaces(ii*4-3,:) = [(ii+1)*2+1,  ii*2+1,    1];
        baseFaces(ii*4-2,:) = [ ii*2+1,    (ii+1)*2+1, ii*2+2]; 
        baseFaces(ii*4-1,:) = [(ii+1)*2+1, (ii+1)*2+2, ii*2+2]; %%
        baseFaces(ii*4,:)   = [ 2,          ii*2+2,   (ii+1)*2+2];
    end

    % Create the actual cylinders
    R = 1; H = 3.2;
    nC = size(c,1);
    faces = zeros(n*4*nC,3); vertices = zeros(nC*(n*2+4),3);
    for ii = 1:nC
        faces(((ii-1)*4*n+1):((ii)*4*n),:) = baseFaces+(ii-1)*(n*2+4);
        temp = baseVertices;
        temp(:,1:2) = temp(:,1:2)*R; 
        temp(:,3) = temp(:,3)*H;
        vertices(((ii-1)*(n*2+4)+1):((ii)*(n*2+4)),:) = temp+repmat(c(ii,:),n*2+4,1);
    end

    % Create the support structures (if necessary)
    cc = c;
    lowest = min(cc(:,3));
    if any(diff(cc(:,3)))  % cylinders on different heights?
        
        IX = find(cc(:,3)==lowest); % Find (all) the lowest cylinders
        cc(IX,:) = []; % remove them, they don't need support
        nC = size(cc,1);
        nF = size(faces,1); nV = size(vertices,1); 
        faces(nF+1:nF+n*4*nC,3) = 0; vertices(nV+1:nV+nC*(n*2+4),3) = 0;
        for ii = 1:nC
            thisH = cc(ii,3) - lowest;
            thisC = cc(ii,:); thisC(3) = thisC(3)-H/2-thisH/2;
            R = 4; 
            faces((nF+(ii-1)*4*n+1):(nF+(ii)*4*n),:) = nV+baseFaces+(ii-1)*(n*2+4);
            temp = baseVertices;
            temp(:,1:2) = temp(:,1:2)*R; 
            temp(:,3) = temp(:,3)*thisH;
            vertices((nV+(ii-1)*(n*2+4)+1):(nV+(ii)*(n*2+4)),:) = temp+repmat(thisC,n*2+4,1);
        end
    end
    % base plate:
    lowest = lowest-H/2;
    nV = size(vertices,1);
    vertices(nV+1:nV+4,:) = [-58.5,-31, lowest; -58.5,31, lowest; 58.5,31,lowest; 58.5,-31,lowest];
    nF = size(faces,1);
    faces(nF+1:nF+2,:) = [nV+1,nV+3,nV+2; nV+1,nV+4,nV+3];

    % Create FV structure:
    modelFV = struct;
    modelFV.vertices = vertices;
    modelFV.faces = faces;
end

%% Method II: Use Voxels
if strcmpi(method,'Voxels')
    regions = any(binaryImages,4);
    modelFV = voxels2mesh(regions,[0.1,0.1,0.1],'optimize',2);
    numVert = size(modelFV.vertices,1);
    modelFV.vertices = modelFV.vertices+repmat(mean(positions,2)',[numVert,1]);
    modelFV.vertices = modelFV.vertices(:,[3,1,2]);
end

imgs = displayModel;

%% Write STL.
fprintf('Series description: %s\n',dicomHeader.SeriesDescription);
[saveFileName,savePathName] = uiputfile({'*.STL';},'Save as...',fullfile(savePathName,dicomHeader.SeriesDescription));
if saveFileName
    fTitle = sprintf('JDisselhorst. WSIC. %s',dicomHeader.SeriesDescription);
    if length(fTitle)>80, fTitle = fTitle(1:80); end
    saveFileName(end-3:end) = [];
    stlwrite(fullfile(savePathName,[saveFileName, '.stl']),modelFV,'Title',fTitle,'FaceColor',[31,15,0]);
    %stlwrite(fullfile(savePathName,[saveFileName, '_holder.stl']),holderFV,'Title',title,'FaceColor',[0,15,31]);
    imwrite(imgs,fullfile(savePathName,[saveFileName, '.png']));
    figure(gcf);
else
    fprintf('Saving canceled...\n');
    savePathName = INI.General.savepathname;
    saveFileName = INI.General.savefilename;
    figure(gcf);
end

%% Write config.
if exist('headerWriter.m','file');
    INI.General.openfilename = openFileName;
    INI.General.openpathname = openPathName;
    INI.General.savefilename = saveFileName;
    INI.General.savepathname = savePathName;
    INI.General.referenceuid = referenceUID;
    headerWriter(INI,fullfile(mfolder,'data',[mname, '.config']),false);
end

    function [faces,verts] = createCylinderWithBase(H,cpos,bl,rt,rb,n)
    %     H = 3.2;  % height;
    %     cpos = [0,0,0];   % position of base of cylinder;
    %     bl = -4;  % bottom level
    %     rt = 1;   % top radius
    %     rb = 5;   % bottom radius
    %     n  = 50;   % number of segments
        angles = 0:360/n:360;

        XX = cosd(angles);
        YY = sind(angles);
        faces = zeros(8*n,3);
        verts = zeros(10*n,3);
        for kk = 1:n
            verts((kk-1)*10+1:kk*10,:) = [0,0,cpos(3)+H; ...
                 XX(kk)*rt,YY(kk)*rt,cpos(3)+H; XX(kk+1)*rt,YY(kk+1)*rt,cpos(3)+H; ...
                 XX(kk)*rt,YY(kk)*rt,cpos(3); XX(kk+1)*rt,YY(kk+1)*rt,cpos(3); ...
                 XX(kk)*rb,YY(kk)*rb,cpos(3); XX(kk+1)*rb,YY(kk+1)*rb,cpos(3); ...
                 XX(kk)*rb,YY(kk)*rb,bl; XX(kk+1)*rb,YY(kk+1)*rb,bl; ...
                 0,0,bl];
            faces((kk-1)*8+1:kk*8,:) = [1,2,3; 2,5,3; 2,4,5; 4,6,5; 5,6,7; 6,8,9; 6,9,7; 8,10,9] + (kk-1)*10;
        end
        verts(:,1) = verts(:,1)+cpos(1);
        verts(:,2) = verts(:,2)+cpos(2);
    end

    function imgs = displayModel
        %% Display
        h1 = subplot(223);
        h2 = subplot(2,2,[2,4]);
        a = cross(modelFV.vertices(modelFV.faces(:,1),:)-modelFV.vertices(modelFV.faces(:,3),:),modelFV.vertices(modelFV.faces(:,2),:)-modelFV.vertices(modelFV.faces(:,3),:));
        b = sqrt(sum(a' .^2))';
        CD = a./repmat(b,[1,3]); 
        CD = (CD+1)/3;
        patch(modelFV,'EdgeColor','none','FaceColor','flat','FaceVertexCData',CD);
        view(3); axis equal;

        % Load the mouse holder mesh:
        holderFV = stlread(fullfile(mfolder,'data','HolderMouse.STL'));
        holderFV.faces = holderFV.faces(:,[1,3,2]); % normals are flipped...
        holderFV.vertices(:,1) = holderFV.vertices(:,1)-35;  % Center the model.
        holderFV.vertices(:,3) = -holderFV.vertices(:,3)+80;
        holderFV.vertices = holderFV.vertices(:,[3,1,2]);
        a = cross(holderFV.vertices(holderFV.faces(:,1),:)-holderFV.vertices(holderFV.faces(:,3),:),holderFV.vertices(holderFV.faces(:,2),:)-holderFV.vertices(holderFV.faces(:,3),:));
        b = sqrt(sum(a' .^2))';
        CD = a./repmat(b,[1,3]); 
        CD = (CD+1)/2; 
        CD = repmat(CD(:,1)/2+CD(:,2)/4+CD(:,3)/9,[1,3]);
        patch(holderFV,'FaceColor','flat','FaceAlpha',1,'EdgeColor','none','FaceVertexCData',CD);


        % Plot lines
        displayLines(holderFV,h1,h2,[0 .7 0]);
        displayLines(modelFV,h1,h2,[.8 .1 0]);

        % Labels:
        h3 = subplot(221);
        axis(h3,'off')
        textlabels = cell(1,N+1);
        for jj = 1:N
            text(c(jj,1),c(jj,2),0,['  ',num2str(jj)],'Parent',h1)
            textlabels{jj} = sprintf('%1.0f) %s: [%1.2f,%1.2f,%1.2f]',jj,strrep(strrep(ROINames{jj},'_',' '),'^',' '),c(jj,1),c(jj,2),c(jj,3));
        end
        bl = min(modelFV.vertices);
        textlabels{jj+1} = sprintf('Bottom level: %1.2f | %1.2f',bl(3),bl(3)-35);
        text(0,0,textlabels,'VerticalAlignment','bottom');

        title(h1,strrep(strrep(dicomHeader.SeriesDescription,'_',' '),'^',' '));
        set(gcf,'Renderer','zbuffer','color','w','Toolbar','figure'); % Because OpenGL renderer seems to place text labels incorrectly sometimes
        axis([h1,h2],'equal');
        xlabel(h1,'X'); xlabel(h2,'X');
        ylabel(h1,'Y'); ylabel(h2,'Y');
        zlabel(h2,'Z');
        axis(h1,[-85, 85, -40, 40])
        axis(h2,[-85, 85, -40, 40, -5 40])
        view(h2,50,60);
        camproj(h2,'perspective');
        set(gcf,'Position',[5,13,1800,1000])
        imgs = export_fig(gcf,'-nocrop');

    end

    function V = displayLines(model,axs1,axs2,color)
        [V,~,ic] = unique(model.vertices,'rows');
        F = ic(model.faces);
        n = size(F,1);
        Fx = repmat(reshape(F,[n,1,3]),[1,n,1]); 
        Fy = permute(Fx,[2,1,3]);
        ix = repmat(tril(true(n,n)),[1,1,3]);
        Fx(~ix) = 0; Fy(~ix) = 0;
        Fs = sort([reshape(Fx,[],3),reshape(Fy,[],3)],2); 
        Ft = (sum(~diff(Fs,1,2),2)==2);
        Fs(~Ft,:) = []; Fs = Fs';
        Ft = padarray(~diff(Fs),[1,0],0,'pre') | padarray(~diff(Fs),[1,0],0,'post');
        shared = reshape(Fs(Ft),4,[]); shared = shared([1,3],:)';
        extra =  reshape(Fs(~Ft),2,[])';
        N1 = cross(V(shared(:,1),:)-V(extra(:,1),:),V(shared(:,2),:)-V(extra(:,1),:));
        N1 = N1./repmat(sqrt(sum(N1' .^2))',[1,3]);
        N2 = cross(V(shared(:,2),:)-V(extra(:,2),:),V(shared(:,1),:)-V(extra(:,2),:));
        N2 = N2./repmat(sqrt(sum(N2' .^2))',[1,3]);
        angle = abs(atan2d(sqrt(sum(cross(N1,N2).^2,2)),dot(N1,N2,2)));
        shared(angle<40,:) = [];
        shared(:,3) = size(V,1)+1;
        V(end+1,:) = NaN;
        hold(axs1,'on'); hold(axs2,'on')
        plot3(V(shared',1),V(shared',2),V(shared',3),'LineWidth',2,'Color',[.3 0 0],'Parent',axs2)
        plot3(V(shared',1),V(shared',2),0*V(shared',3),'LineWidth',1,'Color',color,'Parent',axs1);
        hold(axs1,'off'); hold(axs2,'off')
    end

end