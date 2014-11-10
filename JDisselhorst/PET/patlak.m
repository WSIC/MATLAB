%PATLAK Patlak analysis
%   patlak(APTAC, TTAC, midTimes, startFrame, endFrame, showCurve [1/0])
% JA Disselhorst.

function [slope, intercept,xaxis,yaxis] = patlak(APTAC,TTAC,midTimes,startFrame,endFrame,showCurve)

warning('This script has not been validated!!!!!');

if nargin<5
    error('Not enough input parameters!!')
elseif nargin==5
    showCurve = 1;
end
APTAC = APTAC(:); TTAC = TTAC(:); midTimes = midTimes(:);
if sum(midTimes)>1000
    %probably in seconds
    midTimes = midTimes./60;
end
N = length(APTAC);
if (length(TTAC)~=N) || (length(midTimes)~=N)
    error('curves are not equal in length!');
end

intAPTAC = zeros(N,1);
for i = 1:N
    intAPTAC(i) = trapz([0; midTimes(1:i)],[0; APTAC(1:i)]);
end

xaxis = intAPTAC./APTAC;
yaxis = TTAC./APTAC;

[X,IX] = sort(xaxis(startFrame:endFrame));
Y = yaxis(startFrame:endFrame); Y = Y(IX);
[p,S] = polyfit(X,Y,1);


if showCurve
    plot(xaxis,yaxis,'ro'); hold on;
    X = [min(X) max(X)];
    plot(X,X.*p(1)+p(2),'k'); 
    X = [0 X(1)];
    plot(X,X.*p(1)+p(2),'k:'); 
    hold off
    title(sprintf('Slope: %1.5f, Intercept: %1.5f',p(1),p(2)));
    drawnow
end

slope = p(1);
intercept = p(2);
