%% Initialize:
reqPix = [200,200]; % How big are the tiles to process?
K = 8; % How many clusters (kmeans)

%% Load the training data:
folder = 'V:\histology\JonathanD\MaLTT\Ther_Contr_24u72h\CD31_Training';
files = dir(fullfile(folder,'*.jpg'));
training = zeros(6000,6000,3,'uint8');
for ii = 1:36
    img = imread(fullfile(folder,files(ii).name));
    x = rem(ii-1,6);
    y = floor((ii-1)/6);
    training((x*1000)+1:(x*1000)+1000,(y*1000)+1:(y*1000)+1000,:) = img(1:1000,1:1000,:);
end

%% Do the kmeans:
[KM,CC,~,D] = kmeans(double(reshape(training,[],3)),K,'MaxIter',500,'emptyaction','drop','Display','Iter');
KM = reshape(KM,size(training,1),size(training,2));


%% Select one image.
% NDPi = struct('filename','','finished',0);
% [filename,pathname] = uigetfile({'*.ndpi', 'Hamamatsu NDP images (*.ndpi)'; '*.*', 'All files (*.*'}, 'Select Hamamatsu NDP file','V:\histology\JonathanD\MaLTT\Ther_Contr_24u72h');
% filename = fullfile(pathname,filename);

%% Loop over all.
folder = 'V:\histology\JonathanD\MaLTT\Ther_Contr_24u72h';
files = dir(fullfile(folder,'*CD31*.ndpi'));
for abc = 1:length(files)
    filename = fullfile(folder,files(abc).name);

%% Start with the image.
NDPi.filename = filename;
if not(libisloaded('NDPRead'))
    fprintf('Loading library:...');
    loadlibrary('NDPRead.dll','NDPRead.h')
    fprintf('\b\b\b done.\n');
else
    calllib('NDPRead','CleanUp');
end
NDPi.noChannels = double(calllib('NDPRead','GetNoChannels',filename));
NDPi.channelOrder = calllib('NDPRead','GetChannelOrder',filename);   % 0: Error, 1: BGR [default], 2: RGB, 3: Greyscale
NDPi.sourceLens = double(calllib('NDPRead','GetSourceLens',filename));
[~,~, fullPixelWidth, fullPixelHeight] = calllib('NDPRead','GetSourcePixelSize',filename,1,1);
NDPi.fullPixelWidth = double(fullPixelWidth);
NDPi.fullPixelHeight = double(fullPixelHeight);
NDPi.fullImageWidth = double(calllib('NDPRead','GetImageWidth',filename));
NDPi.fullImageHeight = double(calllib('NDPRead','GetImageHeight',filename));
NDPi.fullRes = [NDPi.fullImageWidth/NDPi.fullPixelWidth, NDPi.fullImageHeight/NDPi.fullPixelHeight]*NDPi.sourceLens; % nm/pixel for the full thing at 1x zoom
[~,~,minFocalDepth,maxFocalDepth,focalDistance] = calllib('NDPRead','GetZRange',filename,1,1,1);
if minFocalDepth~=maxFocalDepth
    focalDepths = minFocalDepth:focalDistance:maxFocalDepth;
    focalMenu = cell(1,length(focalDepths));
    for ii = 1:length(focalDepths)
        focalMenu{ii} = num2str(focalDepths(ii));
    end
    NDPi.Z = focalDepths(menu('Focal depth:',focalMenu));
else
    NDPi.Z = 0;
end
% YR = getpixelposition(NDPi.thisAxs); XR = floor(YR(3)); YR = floor(YR(4));
XR = 3000; YR = 2000;
calllib('NDPRead','SetCameraResolution',XR, YR);
[~,~,~,~,~,~,~,bufferSize] = calllib('NDPRead','GetMap',NDPi.filename,1,1,1,1,1,1,1,1);
[~,~,physPosX,physPosY,physWidth,physHeight,buffer,~,pixelWidth,pixelHeight] = calllib('NDPRead','GetMap',NDPi.filename,1,1,1,1,zeros(bufferSize,1,'uint8'),bufferSize,1,1);
NDPi.pixelWidth = double(pixelWidth); NDPi.pixelHeight = double(pixelHeight);
NDPi.physPosX = double(physPosX); NDPi.physPosY = double(physPosY);
NDPi.physWidth = double(physWidth); NDPi.physHeight = double(physHeight);
IMG = buildImageSeparate(buffer,NDPi.pixelWidth,NDPi.pixelHeight,NDPi.noChannels,NDPi.channelOrder);
% imshow(IMG,'Border','tight','InitialMagnification',100);
NDPi.finished = 1; drawnow;

zoomLevel = NDPi.sourceLens;
pixSize = [NDPi.fullImageWidth/NDPi.fullPixelWidth, NDPi.fullImageHeight/NDPi.fullPixelHeight];
tileSize = pixSize.*reqPix;
center = [NDPi.physPosX, NDPi.physPosY];
numTiles = floor([NDPi.fullPixelWidth,NDPi.fullPixelHeight]./reqPix);


%% Process the tiles
total = numTiles(1)*numTiles(2); current = 0; fprintf('000%%');
results = zeros(numTiles(2),numTiles(1),K+3);
for ii = 1:numTiles(1)  %-(numTiles(1)/2)+0.5:(numTiles(1)/2)-0.5
    for jj = 1:numTiles(2) %-(numTiles(2)/2)+0.5:(numTiles(2)/2)-0.5
        thisCenter = center+[ii-numTiles(1)/2-0.5,jj-numTiles(2)/2-0.5].*tileSize;
        calllib('NDPRead','SetCameraResolution',reqPix(1), reqPix(2));
        [~,~,~,~,~,bufferSize] = calllib('NDPRead','GetImageData',NDPi.filename,thisCenter(1),thisCenter(2),0,zoomLevel,0,0,0,0);
        [~,~,physWidth,physHeight,buffer,~] = calllib('NDPRead','GetImageData',NDPi.filename,thisCenter(1),thisCenter(2),NDPi.Z,zoomLevel,0,0,zeros(1,bufferSize,'uint8'),bufferSize);
        physWidth = double(physWidth); physHeight = double(physHeight);
        IMG = buildImageSeparate(buffer,reqPix(1),reqPix(2),NDPi.noChannels,NDPi.channelOrder);
        
        %%%%%%%%%%%%%%%% Process the tile %%%%%%%%%%%%%%%%%%%%%%%%%%
        D = pdist2(double(reshape(IMG,[],3)),CC,'Euclidean'); 
        [~,IX] = min(D,[],2);
        for n = 1:K
            results(jj,ii,n) = sum(IX==n)/(reqPix(1)*reqPix(2));
        end
        results(jj,ii,n+1:n+3) = mean(mean(IMG));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        current = current+1; fprintf('\b\b\b\b%3.0f%%',current/total*100);
    end
end; fprintf('\n');

%% End loop
eval(sprintf('Data%03.0f = results(:,:,1:8);',abc));
eval(sprintf('Data%03.0fName = files(abc).name;',abc));
eval(sprintf('Data%03.0fImage = uint8(results(:,:,9:11));',abc));
end
save('V:\histology\JonathanD\MaLTT\Ther_Contr_24u72h\MatlabResults.mat','Data*','training','KM');

