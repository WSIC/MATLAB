function varargout = showSpectra(varargin)
% SHOWSPECTRA Shows NMR spectra
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
% showSpectra(X,Y,color,names): provide the labels for each of the curves.
% Should be 1xM or Mx1 cell array of strings.
%
% H = showSpectra(...): provides the handle to the figure.
% 
% showSpectra(H,...): plot in a showSpectra-figure created earlier. 
%
%
% J.A. Disselhorst
% Werner Siemens Imaging Center, http://www.preclinicalimaging.org/
% University of Tuebingen, Germany.
% Version: 2014.10.16
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 

if nargin<1
    help showSpectra;
    return;
end
if numel(varargin{1})==1 && ishandle(varargin{1}) && strcmp(get(varargin{1},'Name'),'showSpectra')
    fig = varargin{1};
    if nargin==1
        error('DISSELHORST:Input','At least one spectrum is required!');
    elseif nargin==2
        y = real(varargin{2}); x = []; c = []; n = [];
    elseif nargin==3
        x = varargin{2};
        y = real(varargin{3}); c = []; n = [];
    elseif nargin==4
        x = varargin{2};
        y = real(varargin{3});
        c = varargin{4}; n = [];
    elseif nargin>4
        x = varargin{2};
        y = real(varargin{3});
        c = varargin{4}; 
        n = varargin{5};
    end
    info = get(fig,'UserData');
else
    if nargin==1
        y = real(varargin{1}); x = []; c = []; n = [];
    elseif nargin==2
        x = varargin{1};
        y = real(varargin{2}); c = []; n = [];
    elseif nargin==3
        x = varargin{1};
        y = real(varargin{2});
        c = varargin{3}; n = [];
    elseif nargin>3
        x = varargin{1};
        y = real(varargin{2});
        c = varargin{3}; 
        n = varargin{4};
    end
    fig = figure('Color','w','Name','showSpectra','NextPlot','new');
    axs = axes('Parent',fig,'Position',[0 .05 1 .95],'XDir','reverse');
    txs = axes('Parent',fig,'Position',[0 .05 1 .95],'Visible','off','HitTest','off');
    info = struct('x',[],'y',[],'c',[],'n',[],'offset',1,'scale',1,'axs',axs,'txs',txs,'color',[0 0 0],'label',1);
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

if isempty(n)
    n = repmat({''},Ns,1);
elseif size(n,1)~=Ns || ~iscell(n)
    if Ns==1 && ischar(n)
        n= {n};
    else warning('DISSELHORST:Input','Invalid label input, should be a 1x%1.0f or %1.0fx1 cell array',Ns,Ns);
        n = repmat({''},Ns,1);
    end
end

info.x = [info.x; num2cell(x,2)];
info.y = [info.y; num2cell(y,2)];
info.c = [info.c; c];
info.n = [info.n; n];
info.Ns = size(info.y,1);
info.lims = [min(cellfun(@min,info.x)), max(cellfun(@max,info.x)), min(cellfun(@min,info.y)), max(cellfun(@max,info.y))];
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
        cla(UD.axs); cla(UD.txs);
        hold(UD.axs,'on');
        UD.hnd = zeros(1,UD.Ns);
        UD.txt = zeros(1,UD.Ns);
        
        hcmenu = uicontextmenu;
        uimenu(hcmenu,'Label','Delete','Callback',{@deleteCurve,0});
        uimenu(hcmenu,'Label','Remove all others','Callback',{@deleteCurve,1});
        uimenu(hcmenu,'Label','Save this curve','Callback',{@saveCurves,0});
        uimenu(hcmenu,'Label','Change color','Callback',@changeColor);
        uimenu(hcmenu,'Label','Change label','Callback',@changeLabel);
        vsb = {'off','on'};
        for ii = 1:UD.Ns
            UD.hnd(ii) = plot(UD.axs,UD.x{ii},UD.scale*UD.y{ii}+(ii)*UD.offs(UD.offset),'Color', UD.c(ii,:));
            set(UD.hnd(ii),'uicontextmenu',hcmenu,'Tag','SP');
            textstring = UD.n{ii}; if isempty(textstring), textstring = num2str(ii); end
            UD.txt(ii) = text(0,(ii)*UD.offs(UD.offset),[' ' textstring],'Parent',UD.txs,...
                'VerticalAlignment','bottom','FontSize',8,'Visible',vsb{UD.label+1},...
                'Color', UD.c(ii,:),'Interpreter','none','HitTest','off');
        end
        hold(UD.axs,'off');
        set(fig,'UserData',UD);
        axis(UD.axs,UD.lims);
        axis(UD.txs,[0 1 UD.lims(3) UD.lims(4)]);
        linkaxes([UD.axs,UD.txs],'y');
        hcmenu = uicontextmenu;
        uimenu(hcmenu,'Label','Save all curves','Callback',{@saveCurves,1});
        uimenu(hcmenu,'Label','Add vertical line','Callback',@addVerticalLine);
        uimenu(hcmenu,'Label','Align peaks','Callback',{@alignPeaks,1});
        uimenu(hcmenu,'Label','Create image','Callback',@createImage);
        if UD.color(1)
            uimenu(hcmenu,'Label','Change to light view','Callback',@changeViewMode,'Tag','Theme');
        else
            uimenu(hcmenu,'Label','Change to dark view','Callback',@changeViewMode,'Tag','Theme');
        end
        if UD.label
            uimenu(hcmenu,'Label','Turn labels off','Callback',@toggleLabels,'Tag','ToggleLabels');
        else
            uimenu(hcmenu,'Label','Turn labels on','Callback',@toggleLabels,'Tag','ToggleLabels');
        end
        set(UD.axs,'uicontextmenu',hcmenu,'FontSize',15,'XMinorTick','on');
    end
    function clickFig(varargin)
        h = get(fig,'CurrentObject');
        type = get(h,'Type');
        if strcmp(get(gcf,'SelectionType'),'normal')
            if strcmp(type,'line'), 
                posvar = get(gca,'CurrentPoint'); 
                set(fig,'WindowButtonUpFcn',{@mouseUp,h},'WindowButtonMotionFcn',{@moveMouse,h,posvar,type});
            else
                posvar = get(fig,'CurrentPoint');
                set(fig,'WindowButtonUpFcn',{@mouseUp,0},'WindowButtonMotionFcn',{@moveMouse,h,posvar,type});
            end
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
                        set(h,'XData',UD.x{this}+move,'YData',UD.scale*(UD.y{this}*SC)+(this)*UD.offs(UD.offset));
                    case 'VL'
                        set(h,'XData',[nu(1,1), nu(1,1)]);
                    case 'AC'
                        ref = get(h,'XData');
                        hl = findobj(UD.axs,'Tag','AL');
                        cur = get(hl,'XData');
                        set(hl,'XData', [nu(1,1), nu(1,1)] - (ref-cur))
                        hr = findobj(UD.axs,'Tag','AR');
                        cur = get(hr,'XData');
                        set(hr,'XData', [nu(1,1), nu(1,1)] - (ref-cur))
                        set(h,'XData',[nu(1,1), nu(1,1)]);
                    case {'AL','AR'}
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
            UD.y{this} = (get(varargin{3},'YData')-(this)*UD.offs(UD.offset))/UD.scale;
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

    function deleteCurve(~,~,type)
        UD = get(fig,'UserData');
        switch type
            case 0
                ID = find(UD.hnd==gco);
            case 1
                ID = find(UD.hnd~=gco);
            case 2
                delete(gco);
                return
            case 3
                delete(findobj(UD.axs,'Tag','AC'));
                delete(findobj(UD.axs,'Tag','AL'));
                delete(findobj(UD.axs,'Tag','AR'));
                return
        end
        if ~isempty(ID)
            if UD.Ns>1
                UD.x(ID) = [];
                UD.y(ID) = [];
                UD.c(ID,:) = [];
                delete([UD.hnd(ID),UD.txt(ID)]);
                UD.hnd(ID) = [];
                UD.txt(ID) = [];
                UD.Ns = UD.Ns-length(ID);
                set(fig,'UserData',UD);
                updateCurves;
            end
        end
    end
    function changeColor(varargin)
        UD = get(fig,'UserData');
        cl = uisetcolor(gco);
        UD.c(UD.hnd==gco,:) = cl;
        set(UD.txt(UD.hnd==gco),'Color',cl);
        set(fig,'UserData',UD);
    end
    function changeLabel(varargin)
        UD = get(fig,'UserData');
        IX = UD.hnd==gco;
        answer = inputdlg('New label:','Change label',1,UD.n(IX));
        if ~isempty(answer)
            UD.n(IX) = answer;
            set(fig,'UserData',UD);
            set(UD.txt(IX),'String',[' ', char(answer)])
        end
    end
    function updateCurves
        UD = get(fig,'UserData');
        for jj = 1:UD.Ns
            set(UD.hnd(jj),'YData',UD.scale*UD.y{jj}+(jj)*UD.offs(UD.offset));
            set(UD.txt(jj),'Position',[0,(jj)*UD.offs(UD.offset)]);
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
        h = plot(UD.axs,[nu(1,1), nu(1,1)],[-1E9 1E9],'Color',UD.color);
        hcmenu = uicontextmenu;
        uimenu(hcmenu,'Label','Delete','Callback',{@deleteCurve,2});
        set(h,'Tag','VL','uicontextmenu',hcmenu)
        uistack(h,'bottom')
        hold(UD.axs,'off');
    end
    function createImage(varargin)
        q = inputdlg({'From:','To:','Number of points:'},'Create Image',1,{'0','6','100'});
        if isempty(q)
            return
        end
        N = str2double(q{3}); 
        e = str2double(q{1});
        b = str2double(q{2}); 
        lims = e:(b-e)/N:b;
        
        UD = get(fig,'UserData');
        img = zeros(UD.Ns,N);
        for ii = 1:UD.Ns
            for jj = 1:N
                x = UD.x{ii};
                y = UD.y{ii};
                img(ii,jj) = mean(y(x>=lims(jj) & x<lims(jj+1)));
            end
        end

        figure; imagesc(lims(1:end-1)+diff(lims)/2,1:29,real(log(img)))
        xlabel('ppm'); ylabel('sample number')
    end
    function changeViewMode(varargin)
        UD = get(fig,'UserData');
        UD.color = 1-UD.color;
        set(fig,'color',1-UD.color);
        set(UD.axs,'color',1-UD.color,'XColor',UD.color,'YColor',UD.color);
        set(setdiff(findall(UD.axs,'Type','line'),UD.hnd),'Color',UD.color);
        set(fig,'UserData',UD);
        if UD.color(1)
            set(varargin{1},'Label','Change to light view');
        else
            set(varargin{1},'Label','Change to dark view');
        end
    end
    function toggleLabels(varargin)
        UD = get(fig,'UserData');
        UD.label = 1-UD.label;
        if UD.label
            set(varargin{1},'Label','Turn labels off');
            set(UD.txt,'Visible','on');
        else
            set(varargin{1},'Label','Turn labels on');
            set(UD.txt,'Visible','off');
        end
        set(fig,'UserData',UD);        
    end
    function alignPeaks(~,~,type)
        switch type
            case 1
                UD = get(fig,'UserData');
                nu = get(UD.axs,'CurrentPoint');
                nu = nu(1,1);
                hold(UD.axs,'on');
                hc = plot(UD.axs,[nu, nu],[-1E9 1E9],'Color',UD.color);
                hl = plot(UD.axs,[nu, nu]+0.04,[-1E9 1E9],'Color',UD.color,'LineStyle',':');
                hr = plot(UD.axs,[nu, nu]-0.04,[-1E9 1E9],'Color',UD.color,'LineStyle',':');
                hcmenu = uicontextmenu;
                uimenu(hcmenu,'Label','Cancel','Callback',{@deleteCurve,3});
                uimenu(hcmenu,'Label','Align','Callback',{@alignPeaks,2});
                set(hc,'Tag','AC','uicontextmenu',hcmenu);
                set(hl,'Tag','AL','uicontextmenu',hcmenu)
                set(hr,'Tag','AR','uicontextmenu',hcmenu)
                hold(UD.axs,'off');
                hcmenu = get(UD.axs,'uicontextmenu');
                set(findobj(hcmenu,'Label','Align peaks'),'Callback',{@alignPeaks,2});
            case 2
                UD = get(fig,'UserData');
                ac = get(findobj(UD.axs,'Tag','AC'),'XData');
                range = sort([get(findobj(UD.axs,'Tag','AL'),'XData'), ...
                              get(findobj(UD.axs,'Tag','AR'),'XData')]);
                for ii = 1:UD.Ns
                    X = UD.x{ii}; Y = UD.y{ii};
                    Y = Y(X>=range(1) & X<=range(end));
                    X = X(X>=range(1) & X<=range(end));
                    N = length(X);
                    [~,IX] = max(Y);
                    if ~isempty(IX)
                        if IX>1 && IX<N
                            p = polyfit(X(IX-1:IX+1),Y(IX-1:IX+1),2);      
                            IX = -p(2)/(2*p(1));          
                        else
                            IX = X(IX);
                        end
                        UD.x{ii} = UD.x{ii} - (IX-ac(1));
                        set(UD.hnd(ii),'XData',UD.x{ii});
                    else
                        warning('Something went wrong during peak alignment!')
                    end
                end
                hcmenu = get(UD.axs,'uicontextmenu');
                set(findobj(hcmenu,'Label','Align peaks'),'Callback',{@alignPeaks,1});
                deleteCurve(1,2,3);
        end
    end
end