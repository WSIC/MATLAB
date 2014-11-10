%% NDPI
% init
clear all;
close all; 
clc

%% Open one NDP image
filename = 'C:\Users\radissj1\Desktop\Matlab_1\FO-03-06_HE_01_2011-12-02_112303.ndpi';
IMGs = openNDP(filename,1.25,0);

%% Open a folder of NDPs
folder = 'C:\Users\radissj1\Desktop\Matlab_1\';
zoomLevel = 1.25;
files = dir(fullfile(folder,'*.ndpi'));
IMGs = cell(0,1);
sizes = zeros(0,2);
for ii = 1:length(files);
    filename = files(ii).name;
    [temp,temp2] = openNDP(fullfile(folder,filename),zoomLevel,1);
    if iscell(temp)
        IMGs(end+1:end+size(temp,1)) = temp;
        sizes(end+1:end+size(temp,1),:) = temp2;
    else
        IMGs(end+1) = {temp};
        sizes(end+1,:) = temp2;
    end
end

%% Show an image:
N = 1;
IMG = IMGs{N,1};
sz  = sizes(N,:)/1E6;
[x,y,~] = size(IMG);
gamma = 0.7;
IMG = imadjust(IMG,stretchlim(IMG),[],gamma);
image((1:x)/x*sz(2), (y:-1:1)/y*sz(1),IMG);
set(gca,'YDir','normal')
axis equal
set(gca,'Units','pixels');
clear gamma N

%% Show without axes with imtool
imtool(IMG)

%% Make masks for all images.
points = struct('x',{},'y',{});
for N = 1:length(IMGs)
    try
        IMG = IMGs{N,1};
        [XX,YY,~] = size(IMG);
        sz  = sizes(N,:)/1E6;
        mask = ~im2bw(IMG,graythresh(IMG));
        mask = bwmorph(mask,'majority',50);
        mask = imfill(mask,'holes');
        [L, num] = bwlabeln(mask);
        for ii = 1:num
            if sum(L(:)==ii)<1E4
                mask(L==ii) = false;
            end
        end
        mask = bwperim(mask);
        
        image((1:XX)/XX*sz(1), (YY:-1:1)/YY*sz(2),IMG);
        set(gca,'YDir','normal')
        hold on;
        [x,y] = ind2sub(size(mask),find(mask));
        x = XX-x+1;
        y = y/YY*sz(1);
        x = x/XX*sz(2);
        points(M,N).x = x;
        points(M,N).y = y;
        plot(y,x,'g.'); pause(.1); drawnow;
        hold off;
    catch
        % It seems that this images does not exist
    end
end

%%
counter = 0;
for N = 1:7
    for M = 1:2
        plot3(points(M,N).x,points(M,N).y,repmat(counter,[1,length(points(M,N).x)]),'r.'); hold on
        counter = counter+1; 
    end
end
hold off
%% matching
IMG1 = images{3};
IMG2 = images{4};
[poinst1, points2] = cpselect(IMG1,IMG2,'Wait',true);
transf = cp2tform(poinst1,points2,'projective');
IMG1_registered = imtransform(IMG1, transf, 'XData',[1 size(IMG2,2)], 'YData',[1 size(IMG2,1)]);
%%
imshow(IMG1_registered+IMG2,[])
