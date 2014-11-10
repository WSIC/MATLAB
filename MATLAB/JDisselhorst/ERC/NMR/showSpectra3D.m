function varargout = showSpectra3D(varargin)
% SHOWSPECTRA3D Shows NMR spectra in 3D (experimental)
% 
% showSpectra(X,Y): plots the spectra Y versus axis X; Both can be 1xN,
% Nx1, or MxN, with N the samples, and M the different spectra. The
% imaginary part of the spectra is ignored.
%
% showSpectra(Y): plots the spectra Y against their index.
% 
% showSpectra(X,Y,color): also indicate the color of the lines. Can be a
% string (e.g., 'k' or 'green'), or a 1x3 or 3x1 matrix of RGB values to
% plot all spectra in the same color. Or a matrix Mx3 to plot each spectrum
% in an individual color.
%
% H = showSpectra(...): provides the handle to the figure.
% 
% showSpectra(H,...): plot in an a showSpectra-figure created earlier. 
%
%
% J.A. Disselhorst
% Werner Siemens Imaging Center, http://www.preclinicalimaging.org/
% University of Tuebingen, Germany.
% 2014.06.06
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

if nargin<1
    help showSpectra;
    return;
end
if numel(varargin{1})==1 && ishandle(varargin{1}) && strcmp(get(varargin{1},'Name'),'showSpectra')
    fig = varargin{1};
    if nargin==1
        error('DISSELHORST:Input','At least one spectrum is required!');
    elseif nargin==2
        y = real(varargin{2}); x = []; c = [];
    elseif nargin==3
        x = varargin{2};
        y = real(varargin{3}); c = [];
    elseif nargin>3
        x = varargin{2};
        y = real(varargin{3});
        c = varargin{4};
    end
    info = get(fig,'UserData');
else
    if nargin==1
        y = real(varargin{1}); x = []; c = [];
    elseif nargin==2
        x = varargin{1};
        y = real(varargin{2}); c = [];
    elseif nargin>2
        x = varargin{1};
        y = real(varargin{2});
        c = varargin{3};
    end
    fig = figure('Color','w','Name','showSpectra');
    axs = axes('Parent',fig,'Position',[0 .05 1 .95],'XDir','reverse');

    info = struct('x',[],'y',[],'c',[],'offset',1,'scale',1,'axs',axs);
end

[Ns,Np] = size(y);
if Np == 1 || Ns == 1 % Only one spectrum
    Np = Ns*Np; Ns = 1; 
    y = y(:)';
end
if isempty(x)
    x = repmat(-1:-1:-Np,[Ns,1]);
elseif numel(x) == Np
    x = repmat(x(:)',[Ns,1]);
elseif any(size(x)~=[Ns,Np])
    error('DISSELHORST:Input', 'Horizontal axis does not match these spectra, provide a 1x%1.0f or %1.0fx%1.0f matrix',Np,Ns,Np);
end
if isempty(c)
    c = rand([Ns,3]);
elseif ischar(c)
    [~,c] = intersect({'red','green','blue','cyan','magenta','yellow','black','white','r','g','b','c','m','y','k','w'},c);
    if isempty(c), c = 7; else c = c-8*(c>8); end
    cs = [1,0,0;0,1,0;0,0,1;0,1,1;1,0,1;1,1,0;0,0,0;1,1,1];
    c = repmat(cs(c,:),[Ns,1]);
elseif numel(c) == 3
    c = repmat(c(:)',[Ns,1]);
elseif any(size(c)~=[Ns,3])
    error('DISSELHORST:Input', 'Colors do not match these spectra, provide a string, or a 1x3 or %1.0fx3 matrix',Ns);
end

info.x = [info.x; num2cell(x,2)];
info.y = [info.y; num2cell(y,2)];
info.c = [info.c; c];
info.Ns = size(info.y,1);
info.lims = [min(cellfun(@min,info.x)), max(cellfun(@max,info.x)), 0, 100, min(cellfun(@min,info.y)), max(cellfun(@max,info.y))];
info.offs = linspace(0,info.lims(4)^(1/3),100).^3;

set(fig,'WindowButtonDownFcn',@clickFig,...
        'WindowScrollWheelFcn',@mouseWheel, ...
        'NextPlot', 'new', 'UserData', info);
initializeCurves;
if nargout
    varargout{1} = fig;
end

    function initializeCurves(varargin)
        UD = get(fig,'UserData');
        cla(UD.axs);
        hold(UD.axs,'on');
        UD.hnd = zeros(1,UD.Ns);
        
        hcmenu = uicontextmenu;
        uimenu(hcmenu,'Label','Delete','Callback',@deleteCurve);
        uimenu(hcmenu,'Label','Change color','Callback',@changeColor);
        uimenu(hcmenu,'Label','Save this curve','Callback',{@saveCurves,0});

        for ii = 1:UD.Ns
            UD.hnd(ii) = plot3(UD.x{ii},ones(1,length(UD.x{ii})).*(ii)*UD.offs(UD.offset),UD.scale*UD.y{ii},'Color', UD.c(ii,:));
            set(UD.hnd(ii),'uicontextmenu',hcmenu,'Tag','SP')
        end
        hold(UD.axs,'off');
        set(fig,'UserData',UD);
        axis(UD.axs,UD.lims);
        hcmenu = uicontextmenu;
        uimenu(hcmenu,'Label','Save all curves','Callback',{@saveCurves,1});
        uimenu(hcmenu,'Label','Add vertical line','Callback',@addVerticalLine);
        set(UD.axs,'uicontextmenu',hcmenu);
    end
    function clickFig(varargin)
        h = get(fig,'CurrentObject');
        type = get(h,'Type');
        if strcmp(type,'line'), 
            posvar = get(gca,'CurrentPoint'); 
            set(fig,'WindowButtonUpFcn',{@mouseUp,h},'WindowButtonMotionFcn',{@moveMouse,h,posvar,type});
        else
            posvar = get(fig,'CurrentPoint');
            set(fig,'WindowButtonUpFcn',{@mouseUp,0},'WindowButtonMotionFcn',{@moveMouse,h,posvar,type});
        end
    end
    function moveMouse(varargin)
        UD = get(fig,'UserData');
        h = varargin{3};
        posvar = varargin{4};
        switch varargin{5};
            case 'line'
                nu = get(UD.axs,'CurrentPoint');
                switch get(h,'Tag')
                    case 'SP'
                        move = nu(1)-posvar(1);
                        this = find(UD.hnd==h);
                        SC = (nu(1,2)-(this)*UD.offs(UD.offset))/(posvar(1,2)-(this)*UD.offs(UD.offset));
                        set(h,'XData',UD.x{this}+move,'YData',ones(1,length(UD.x{this}))*(this)*UD.offs(UD.offset),'ZData',UD.scale*(UD.y{this}*SC));
                    case 'VL' 
                        set(h,'XData',[nu(1,1), nu(1,1)]);
                end
                
            case 'axes'
                nu = get(fig,'CurrentPoint');
                move = nu(2)-posvar(2);
                if move<0
                    UD.offset = UD.offset-1;
                else
                    UD.offset = UD.offset+1;
                end
                UD.offset = max([1 min([UD.offset 100])]);
                set(fig,'UserData',UD,'WindowButtonMotionFcn',{@moveMouse,h,nu,'axes'});
                updateCurves
        end
    end
    function mouseUp(varargin)
        set(fig,'WindowButtonUpFcn','','WindowButtonMotionFcn','')
        if varargin{3} && strcmp(get(varargin{3},'Tag'),'SP')
            UD = get(fig,'UserData');
            this = find(UD.hnd==varargin{3});
            UD.x{this} = get(varargin{3},'XData');
            UD.y{this} = (get(varargin{3},'ZData')-(this)*UD.offs(UD.offset))/UD.scale;
            set(fig,'UserData',UD)
        end
    end
    function mouseWheel(varargin)
        UD = get(fig,'UserData');
        temp = varargin{2};
        if temp.VerticalScrollCount>0
            UD.scale = UD.scale * 0.95;
        else
            UD.scale = UD.scale * 1.05;
        end
        set(fig,'UserData',UD);
        updateCurves;
    end

    function deleteCurve(varargin)
        UD = get(fig,'UserData');
        ID = find(UD.hnd==gco);
        if ~isempty(ID)
            if UD.Ns>1
                UD.x(ID) = [];
                UD.y(ID) = [];
                UD.c(ID,:) = [];
                delete(UD.hnd(ID));
                UD.hnd(ID) = [];
                UD.Ns = UD.Ns-1;
                set(fig,'UserData',UD);
                updateCurves;
            end
        else
            delete(gco);
        end
    end
    function changeColor(varargin)
        UD = get(fig,'UserData');
        cl = uisetcolor(gco);
        UD.c(UD.hnd==gco,:) = cl;
        set(fig,'UserData',UD);
    end
    function updateCurves
        UD = get(fig,'UserData');
        for jj = 1:UD.Ns
            set(UD.hnd(jj),'YData',ones(1,length(UD.x{jj}))*(jj)*UD.offs(UD.offset), 'ZData',UD.scale*UD.y{jj});
        end
    end
    function saveCurves(varargin)
        UD = get(fig,'UserData');
        if varargin{3}
            this = true(UD.Ns,1);
        else
            this = UD.hnd==gco;
        end
        x = UD.x(this);
        y = UD.y(this);
        assignin('base','AXS',x);
        assignin('base','SPC',y);
    end
    function addVerticalLine(varargin)
        UD = get(fig,'UserData');
        nu = get(UD.axs,'CurrentPoint');
        hold(UD.axs,'on');
        h = plot(UD.axs,[nu(1,1), nu(1,1)],[-1E9 1E9],'k');
        hcmenu = uicontextmenu;
        uimenu(hcmenu,'Label','Delete','Callback',@deleteCurve);
        set(h,'Tag','VL','uicontextmenu',hcmenu)
        hold(UD.axs,'off');
    end
end