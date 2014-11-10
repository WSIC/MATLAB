function varargout = voxels2mesh(volume,varargin)
% VOXELS2MESH converts volume data to faces and vertices.
%
% Usage:
%   [faces,vertices,colors] = VOXELS2MESH(volume,pixelsize,origin,optimize)
%   [FV]                    = VOXELS2MESH(volume,pixelsize,origin,optimize)
%   Calling VOXELS2MESH without output arguments will display the mesh
%
% Input:
%   o volume:    Volume [X*Y*Z matrix] 
%   o pixelsize: Size of the pixels in all dimensions [x,y,z] or, for
%                isotropic voxels as [size]. Optional, default: [1]
%   o origin:    The center of this voxel is the origin (0,0,0) of the
%                volume. The origin can lay within, or outside the volume.
%                The origin does not have to be positioned in the center of
%                voxel. Given as [x,y,z]. 
%                Optional, the default is the center of the volume.
%   o optimize:  Attempts to reduce the number of faces. Optional
%                0: no optimization [default]
%                1: standard optimization (changes the orientation)
%                2: additional optimization (removes holes inside volume)
%                3: only removes the holes
%
% Output:
%   o faces:     the faces of the objects
%   o vertices:  the vertices of the objects
%   o colors:    VertexFaceCData (can be used for patch)
%   o FV:        Structure containing the above output
% 
% Example:
%   <a href="matlab:volume = randn(5,5,5)>1;">volume = randn(5,5,5)>1; </a>
%   <a href="matlab:voxels2mesh(volume);">voxels2mesh(volume);</a>
%
% Author:  J.A. Disselhorst
%          Werner Siemens Imaging Center
%          Eberhard Karls University Tuebingen
%          Tuebingen, Germany
% Version: 2014-07-24
%
% Acknowledgement:
% Based on the greedy meshing algorithm by Mikola Lysenko (www.0fps.net)
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
% EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');


    %% Input parsing ------------------------------------------------------
    if nargin==0
        help voxels2mesh
        return
    end
    p = inputParser;
    addRequired(p,'volume',@(x)((isnumeric(x) || islogical(x)) && ndims(x)==3));
    addOptional(p,'pixelsize',1,@(x)(isnumeric(x) && (numel(x)==3 || numel(x)==1)));
    addOptional(p,'origin',size(volume)/2+0.5,@(x)(isnumeric(x) && numel(x) == 3));
    addOptional(p,'optimize',0,@(x)(numel(x)==1 && (isnumeric(x) || islogical(x))));
    parse(p,volume,varargin{:});
    pixelsize = p.Results.pixelsize;
    if numel(pixelsize)==1, pixelsize = repmat(pixelsize,1,3); end
    origin = p.Results.origin;
    optimize = p.Results.optimize;

    %% Create the mesh ---------------------------------------------------
    fprintf('Creating mesh...');
    if optimize % Optimization
        [faces,vertices,colors] = optimizeMesh(volume,optimize);
    else
        [faces,vertices,colors] = createMesh(volume,[0,0,0]);
    end
    fprintf('\b\b\b: finished.\n');
    
    % Include the origin and the pixelsize:
    vertices = vertices- repmat(origin(:)',[size(vertices,1),1])+0.5;
    vertices = vertices.*repmat(pixelsize(:)',[size(vertices,1),1]);
    
    if nargout==0  
        axs = [([0, 0, 0] - origin(:)' + 0.5).*pixelsize(:)'; ...
               (size(volume) - origin(:)' + 0.5).*pixelsize(:)'];
        displayResults(vertices,faces,colors,axs);
        clear faces vertices colors % Suppress output
    elseif nargout==1
        FV.faces = faces; 
        FV.vertices = vertices;
        FV.facevertexcdata = colors;
        varargout{1} = FV;
    else
        varargout{1} = faces;
        varargout{2} = vertices;
        varargout{3} = colors;
    end

end
function displayResults(vertices,faces,colors,axs)
% DISPLAYRESULTS displays the mesh
    patch('Vertices',vertices,'Faces',faces,'FaceVertexCData',colors,...
        'EdgeColor','none','FaceColor','flat','FaceAlpha',1,'FaceLighting','flat');
    view(3)
    axis equal;
    axis(axs(:))
end

function [faces,vertices,colors,wbh] = createMesh(volume,direction,varargin)
    % CREATEMESH makes the mesh from the volume
    % Input:  - the pixeldata
    %         - the direction how the faces are oriented
    % Output: - the faces
    %         - the vertices
    %         - colors of the faces
    
    % First increase the size of the volume with one. Otherwise the
    % trailing edge of the last voxel will not be drawn. Then increase the
    % size of the volume again, this is to create a mask using 'diff'.
    volume   = padarray(volume,[1 1 1],0,'post');
    dims     = size(volume);
    volume   = padarray(volume,[1 1 1],0);
    % Initialization of variables, and the different color options.
    Nv = [10000,10000]; % Prealocate the vertices with Nv(1) items, current size = Nv(2)
    Nf = [10000,10000]; % Prealocate the faces and colors with Nf(1), current size = Nf(2)
    vertices = zeros(Nv(1),3);
    faces    = zeros(Nf(1),3);
    colors   = zeros(Nf(1),3);
    cOpts    = [1,0,0;0,1,0;0,0,1;0,1,1;1,0,1;1,1,0];
    nVert  = 0;
    nFace  = 0;
    % Progress bar
    if nargin==4
        wbh = varargin{1};
        try waitbar(0,wbh,sprintf('Optimization step %1.0f/8...',varargin{2})); end;
    else
        wbh = waitbar(0,'Creating mesh, please wait...'); 
    end
    % Loop through all three dimensions of the volume and draw faces for
    % each of them. In which direction the faces will be created depends on
    % the variable 'direction', i.e., leftright/updown vs updown/leftright.
    for q = 1:3
        if direction(q)
            r = mod(q,3)+1;
            s = mod(q+1,3)+1;
        else
            r = mod(q+1,3)+1;
            s = mod(q,3)+1;
        end
        curPoint = [0,0,0]; % This holds the position of the current point.
        % Reorder the volume based on q, r, and s above. Calculate the
        % derivative to create the mask, and remove the additional padding
        % that has been added before.
        tempVol = permute(volume,[q,r,s]);
        tempVol = diff(tempVol); 
        tempVol = tempVol(1:end,2:end-1,2:end-1);
        % Loop through all the slices in direction q.
        for Q = 1:dims(q)
            curPoint(q) = Q; 
            mask = squeeze(tempVol(Q,:,:));
            for S = 1:dims(s) 
                for R = 1:dims(r) 
                    if mask(R,S) % When this voxel is on...
                        % Compute the width of the face on this plane. The
                        % width increases as long as the end is not
                        % reached. Break the loop when we reach it to set
                        % the width. Do the same for the height.
                        for width=1:dims(r)
                            if R+width>dims(r) || mask(R,S)~=mask(R+width,S)
                                break
                            end
                        end
                        for height = 1:dims(s)
                            if S+height>dims(s) || ~all(mask(R:R+width-1,S+height)==mask(R,S))
                                break
                            end
                        end
                        % Set the starting position and width/height of the
                        % face, and create the vertices.
                        curPoint(r) = R;
                        curPoint(s) = S;
                        dr = [0,0,0]; dr(r) = width;
                        ds = [0,0,0]; ds(s) = height;
                        temp = [[curPoint(1),             curPoint(2),             curPoint(3)]; ...
                                [curPoint(1)+dr(1),       curPoint(2)+dr(2),       curPoint(3)+dr(3)]; ...
                                [curPoint(1)+dr(1)+ds(1), curPoint(2)+dr(2)+ds(2), curPoint(3)+dr(3)+ds(3)]; ...
                                [curPoint(1)+ds(1),       curPoint(2)+ds(2),       curPoint(3)+ds(3)]]-1;
                        vertices(nVert+1:nVert+4,1:3) = temp;
                        % Create the faces and set the colors, also take
                        % the normals into account. Finally, remove the
                        % voxels that now have been processed.
                        if mask(R,S) < 0
                            faces(nFace+1:nFace+2,1:3) = nVert+[3,2,1;4,3,1];
                            colors(nFace+1:nFace+2,1:3) = repmat(cOpts(q,:).*(Q/dims(q)*0.8),[2,1]);
                        else
                            faces(nFace+1:nFace+2,1:3) = nVert+[1,2,3;1,3,4];
                            colors(nFace+1:nFace+2,1:3) = repmat(cOpts(q+3,:).*(1-(Q/dims(q)*0.8)),[2,1]);
                        end
                        nVert = nVert + 4; 
                        nFace = nFace + 2;
                        mask(R:R+width-1,S:S+height-1) = false; 
                        if nFace>=Nf(2) % When the faces and colors matrix are too small, expand.
                            faces(nFace+1:nFace+Nf(1),:) = 0;
                            colors(nFace+1:nFace+Nf(1),:) = 0;
                            Nf(2) = nFace+Nf(1);
                        end
                        if nVert>=Nv(2)
                            vertices(nVert+1:nVert+Nv(1),:) = 0;
                            Nv(2) = nVert+Nv(1);
                        end
                    end
                end
            end
            try waitbar(Q/dims(q)/3+(q-1)/3,wbh); end;
        end
    end
    % Clean up the vertices (remove doubles), and reset the face indices.
    vertices(nVert+1:end,:) = [];
    faces(nFace+1:end,:) = [];
    colors(nFace+1:end,:) = [];
    [vertices,~,ic] = unique(vertices,'rows');
    faces = ic(faces);
    if nargin == 2 || (nargin == 4 && varargin{2} == 8)
        try close(wbh); end;
    end
end

function [faces,vertices,colors] = optimizeMesh(volume,optimize)
    % OPTIMIZEMESH attempts to reduces the number of faces.
    % The 'optimize' parameter can take a value of 1, 2 or 3. A 2 or 3 will
    % first remove holes in the volume that cannot be reached from the
    % outside.
    % In the next step (only with optimize < 3), the orientation in which
    % faces are generated will be alternated to (further) reduce the number
    % of faces. For some very specific volume configurations this could
    % reduce the number of faces considerably, but usually does not help
    % much. Obviously both optimizations require additional CPU time. 

    if optimize>=2
        volume = imfill(volume,6,'holes');
    end
    if optimize<=2
        [faces,vertices,colors,wbh] = createMesh(volume,[0,0,0],'doNotCloseWaitBar');
        direction = [0,0,1;0,1,0;1,0,0;0,1,1;1,0,1;1,1,0;1,1,1];
        nFace = length(faces);
        for n = 1:7
            [faces2,vertices2,colors2,wbh] = createMesh(volume,direction(n,:),wbh,n+1);
            nFace2 = length(faces2);
            if nFace2<nFace
                faces = faces2;
                vertices = vertices2;
                colors = colors2;
                nFace = nFace2;
            end
        end
    else
        [faces,vertices,colors] = createMesh(volume,[0,0,0]);
    end
end

