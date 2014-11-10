function varargout = phaseCorrect(ax,spectrum)
% PHASECORRECT graphical user interphase to phase correct a spectrum
%
% Usage: spectrum = phaseCorrect(spectrum)
%        spectrum = phaseCorrect(ax,spectrum)
%
% Input: 
%        o ax:          ppm values for the spectrum [optional]
%        o spectrum:    the actual spectrum (complex double)
% Output:
%        o spectrum:    the processed spectrum
%  
% Note:  This function is experimental, it may not perform well. 
%
% J.A. DISSELHORST
% Werner Siemens Imaging Center
% v20140319
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
% EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 

if nargin==1
    spectrum = ax;
    ax = length(spectrum):-1:1;
end
spectrum = spectrum(:); 
I = imag(spectrum);
R = real(spectrum);

points = [0, 0; 0.4, 0];
factor = [4*pi,.00005];
addfct = [0,0];
offset = 0;
offfct = max(abs(spectrum))/1E5;

fig = figure('Color','w');
ax1 = axes('Parent',fig,'Position',[0 .05 1 .95],'XDir','reverse');
ax2 = axes('Parent',fig,'Position',[0 0 1 1],'Visible','off');
str = ['\alpha: ',sprintf('%1.6g',0), char(10), '\beta: ',sprintf('%1.6g',0)];
txt = text('Parent',ax2,'Position',[-.49 .49],'VerticalAlignment','top','String',str);
str = ['Help: Zeroth- and first-order phase correction',char(10), ...
       'with red lines below and mousewheel.',char(10), ...
       'Baseline shift with up and down arrow. Pressing', char(10),...
       'shift and/or ctrl simultaneously shifts faster'];
hlp = text('Parent',ax2,'Position',[0.49 .49],'VerticalAlignment','top','HorizontalAlignment','right','String',str);
str = ['Zeroth order',char(10),'\downarrow'];
hlp(2) = text('Parent',ax2,'Position',[points(1,1),points(1,2)+.01],'VerticalAlignment','bottom','HorizontalAlignment','center','String',str);
str = ['First order',char(10),'\downarrow'];
hlp(3) = text('Parent',ax2,'Position',[points(2,1),points(2,2)+.01],'VerticalAlignment','bottom','HorizontalAlignment','center','String',str);

set(fig,'WindowButtonDownFcn',@clickFig,'WindowScrollWheelFcn',@mouseWheel,...
    'NextPlot', 'new','CloseRequestFcn',{@closeWindow,nargout}, ...
    'WindowKeyPressFcn',@keyPress);

hold(ax1,'on');
hnd = plot(ax1,ax,R);
plot(ax1,[min(ax) max(ax)],[0 0],'k');
hold(ax1,'off');
axis(ax1,[min(ax) max(ax) -max(R(:))/20 max(R(:))]);
hold(ax2,'on');
p1 = plot(ax2,points(1,1),points(1,2),'ro');
p2 = plot(ax2,points(2,1),points(2,2),'ro');
slope = diff(points(:,2))./diff(points(:,1));
inter = points(1,2) - points(1,1)*slope;
l1 = plot(ax2,[-0.5, 0.5],[points(1,2), points(1,2)],'r');
l2 = plot(ax2,[-0.5, 0.5],[-0.5, 0.5].*slope+inter,'r');
set([p1,p2,l1,l2],'HitTest','off');
hold(ax2,'off');
axis(ax2,[-0.5 0.5 -0.5 0.5]);

import java.awt.Robot;
mouse = Robot;
setAllowAxesZoom(zoom(fig),ax2,false)
set(fig,'NextPlot','new');
if nargout
    uiwait(fig);
    warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');
    varargout{1} = spectrum;
end

    function clickFig(varargin)
        posvar = get(ax2,'CurrentPoint');
        switch get(fig,'SelectionType')
            case 'normal'
                if sqrt(sum((posvar(1,1:2)-points(2,:)).^2))<.01
                    set(fig,'WindowButtonUpFcn',@mouseUp,'WindowButtonMotionFcn',{@moveMouse,2})
                elseif sqrt(sum((posvar(1,1:2)-points(1,:)).^2))<.01
                    set(fig,'WindowButtonUpFcn',@mouseUp,'WindowButtonMotionFcn',{@moveMouse,1})
                elseif abs(posvar(1,2)-points(1,2))<.01
                    set(fig,'WindowButtonUpFcn',@mouseUp,'WindowButtonMotionFcn',{@moveMouse,3})
                end
            case 'open'
                if posvar(1,1)<-0.3 && posvar(1,2)>0.4
                    options.Interpreter='tex';
                    answer = inputdlg({'\alpha:','\beta:'},'Extra',1,{num2str(addfct(1)),num2str(addfct(2))},options);
                    if ~isempty(answer)
                        addfct(1) = str2double(answer{1});
                        addfct(2) = str2double(answer{2});
                        updateCurves
                    end
                end
        end
    end
    function moveMouse(varargin)
        posvar = get(ax2,'CurrentPoint');
        if varargin{3}<3
            A = posvar(1,1:2);
            A = max([min([A;0.5,0.5]);-0.5,-0.5]);
            points(varargin{3},:) = A;
        else
            if posvar(1,2)<=0.5 && posvar(1,2)>=-0.5
                points(2,2) = points(2,2) - (points(1,2)-posvar(1,2));
                points(1,2) = posvar(1,2);
                if points(2,2) > 0.5 || points(2,2)<-0.5
                    A = 0.5-(points(2,2)<points(1,2));
                    slope = diff(points(:,2))./diff(points(:,1));
                    inter = points(1,2) - points(1,1)*slope;
                    points(2,2) = A;
                    points(2,1) = (A-inter)/slope;
                end
            end
        end
        updateCurves
    end
    function mouseUp(varargin)
        set(fig,'WindowButtonUpFcn','','WindowButtonMotionFcn','')
    end
    function mouseWheel(varargin)
        mousepos = get(0,'PointerLocation');
        A = get(fig,'Position'); A = A(4);
        temp = varargin{2};
        if temp.VerticalScrollCount<0
            if points(1,2)+0.005<=0.5
                points(1,2) = points(1,2)+0.005;
                points(2,2) = points(2,2)+0.005;
                mouse.mouseMove(mousepos(1)-1,1080-mousepos(2)-round(A*0.005))
            end
        else
            if points(1,2)-0.005>=-0.5
                points(1,2) = points(1,2)-0.005;
                points(2,2) = points(2,2)-0.005;
                mouse.mouseMove(mousepos(1)-1,1080-mousepos(2)+round(A*0.005))
            end
        end
        if points(2,2) > 0.5 || points(2,2)<-0.5
            A = 0.5-(points(2,2)<points(1,2));
            slope = diff(points(:,2))./diff(points(:,1));
            inter = points(1,2) - points(1,1)*slope;
            points(2,2) = A;
            points(2,1) = (A-inter)/slope;
        end
        updateCurves;
    end
    function keyPress(varargin)
        details = varargin{2};
        A = strcmpi({'uparrow','downarrow'},details.Key);
        if any(A)
            if A(1)
                N = offfct;
            elseif A(2)
                N = -offfct;
            end
            if any(strcmpi(details.Modifier,'shift'))
                N = N*20;
            end
            if any(strcmpi(details.Modifier,'control'))
                N = N*5;
            end
            offset = offset+N;
            updateCurves;
        end
        
    end
    function updateCurves
        delete(hlp(ishandle(hlp)));
        set(p1,'XData',points(1,1),'YData',points(1,2));
        set(p2,'XData',points(2,1),'YData',points(2,2));
        slope = diff(points(:,2))./diff(points(:,1));
        inter = points(1,2) - points(1,1)*slope;
        set(l1,'YData',[points(1,2), points(1,2)]);
        set(l2,'YData',[-0.5, 0.5].*slope+inter);
        
        a = points(1,2)*factor(1)+addfct(1);
        b = slope*factor(2)+addfct(2);
        A = R.*(cos(a+b*(1:length(R)))') + I.*(sin(a+b*(1:length(R)))')+offset;
       % D = R.*(sin(a+b*(1:length(R)))') - I.*(cos(a+b*(1:length(R)))');
        set(hnd,'YData',A);
        str = ['\alpha: ',sprintf('%1.6g',a), char(10), '\beta: ',sprintf('%1.6g',b)];
        set(txt,'String',str);
    end
    function closeWindow(varargin)
        slope = diff(points(:,2))./diff(points(:,1));
        inter = points(1,2) - points(1,1)*slope;
        a = points(1,2)*factor(1)+addfct(1);
        b = slope*factor(2)+addfct(2);
        A = R.*(cos(a+b*(1:length(R)))') + I.*(sin(a+b*(1:length(R)))')+offset;
        D = R.*(sin(a+b*(1:length(R)))') - I.*(cos(a+b*(1:length(R)))')+offset;
        spectrum = complex(A,D);
        if (a~=0 || b~=0) && ~varargin{3}
            answer = questdlg('Spectrum has changed, save changes?','Save changes?','Yes','No','Yes');
            if ~strcmpi(answer,'no')
                warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');
                assignin('base','ans',spectrum);
            end
        end
        delete(fig);
    end

end