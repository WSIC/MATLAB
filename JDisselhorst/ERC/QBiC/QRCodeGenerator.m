function [QR,FV] = QRCodeGenerator(str,quality)
% QRCODEGENERATOR Creates a QR-Code
% Input:
%        o String to be converted to a QR code
%        o Optional quality parameter (error correction): 1-4
%          1: Low       (7%)
%          2: Medium   (15%) [default]
%          3: Quartile (25%)
%          4: High     (30%)
%
% Output:
%        o QR code (binary image)
%        o a structure containing vertices and faces.
%
% Example:
% [qr,fv] = QRCodeGenerator(['MATLAB ' version],4);
% imshow(qr);
% patch(fv,'FaceColor','r','EdgeColor','none');
%
% J.A. Disselhorst
% Werner Siemens Imaging Center
% 2014.6.4
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
% EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

if nargin<1
    error('At least one argument required');
elseif nargin==1
    quality = 2;
end

% Convert the string to hex;
str = dec2hex(uint8(str),3); str(:,1) = '%';
str = reshape(str',1,[]);

% Read the image from Zebra Crossing:
sz = '300x300';
eclevels = 'LMQH';
URL = ['http://zxing.org/w/chart?cht=qr&chs=', sz, '&chld=', eclevels(quality), '&choe=ISO-8859-1&chl=' str];
QR = imread(URL);

% Downscale 
x = mean(double(QR));   sx = find(diff(x),1,'first')+1; dx = min(diff(find(diff(x)))); nx = find(diff(x),1,'last');
y = mean(double(QR),2); sy = find(diff(y),1,'first')+1; dy = min(diff(find(diff(y)))); ny = find(diff(y),1,'last');
QR = QR(sx:dx:nx,sx:dx:nx);

% Create faces and vertices
[x,y] = find(~QR); N = length(x);
x = repmat(x,[1,4])+repmat([-1,1,1,-1]/2,[N,1]);
y = repmat(y,[1,4])+repmat([-1,-1,1,1]/2,[N,1]);
faces = reshape(1:4*N,N,4);
verts = [y(:),x(:)]; [verts, ~, ic] = unique(verts,'rows');
faces = ic(faces);
FV.faces = faces;
FV.vertices = verts;

