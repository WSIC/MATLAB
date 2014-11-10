path = 'C:\Users\radissj1\JONATHANDATA\2012-IVIMASL-HISTOLOGY\NanoZoomer\';
fileNames = {'IVIMASL_CD31_JD01-02-03.ndpi', ...
    'IVIMASL_CD31_JD04-05-06.ndpi', ...
    'IVIMASL_CD31_JD08-09.ndpi', ...
    'IVIMASL_CD31_JD10-11.ndpi', ...
    'IVIMASL_CD31_JD12-13.ndpi', ...
    'IVIMASL_CD31_JD14-15.ndpi', ...
    'IVIMASL_CD31_JD16-17.ndpi', ...
    'IVIMASL_CD31_JD18-19-20.ndpi'};

if not(libisloaded('NDPRead'))
    fprintf('Loading library:...');
    loadlibrary('NDPRead.dll','NDPRead.h')
    fprintf('\b\b\b done.\n');
else
    calllib('NDPRead','CleanUp');
end

%% Create Training Data?
% First create a training data set, then analyze it (see below). Than run
tileSize = 250; %tile size in px
createTraining = 0;
analyzeTraining = 0;
tilesPerTumor = 2;
numClus = 5;
trainingPath = 'C:\Users\radissj1\JONATHANDATA\2012-IVIMASL-HISTOLOGY\NanoZoomer\TrainingData';
resultsPath = 'C:\Users\radissj1\JONATHANDATA\2012-IVIMASL-HISTOLOGY\NanoZoomer\Results';
cform = makecform('srgb2lab');
%%  This works in L*a*b* color space, and uses 'a' and 'b' for clustering.
if ~analyzeTraining
    load(fullfile(resultsPath,'centroids.mat'));
    multiWaitbar( 'CloseAll' );
    multiWaitbar( 'Overall', 'Busy', 'Color', [1 0 0] );
    multiWaitbar( 'Current slide', 'Busy', 'Color', [0 0.5 0] );
    multiWaitbar( 'Current ROI', 'Busy', 'Color', [0 0 1] );

    
    for ii = 1:8
        %%
        tic
        NDP = fullfile(path,fileNames{ii});

        noChannels = double(calllib('NDPRead','GetNoChannels',NDP));
        channelOrder = calllib('NDPRead','GetChannelOrder',NDP);   % 0: Error, 1: BGR [default], 2: RGB, 3: Greyscale
        sourceLens = double(calllib('NDPRead','GetSourceLens',NDP));
        [~,~, fullPixelWidth, fullPixelHeight] = calllib('NDPRead','GetSourcePixelSize',NDP,1,1);
        fullPixelWidth = double(fullPixelWidth); fullPixelHeight = double(fullPixelHeight);
        fullImageWidth = double(calllib('NDPRead','GetImageWidth',NDP));
        fullImageHeight = double(calllib('NDPRead','GetImageHeight',NDP));
        fullRes = [fullImageWidth/fullPixelWidth, fullImageHeight/fullPixelHeight]; % nm/pixel for the full thing at 1x zoom
        Z = 0;

        CSV = [NDP,'.csv'];
        fid = fopen(CSV);
        data = regexpi(char(fread(fid)'),'[,\n]','split');
        data(cellfun(@isempty,data)) = [];
        fclose(fid);
        N = (length(data))/5;
        data = reshape(data,5,[])'; % Reshape to matrix
        data = sortrows(data);      % Sort ROIs alphabetically
        for jj = 1:size(data,1)
            currentName = data{jj,1};
            center = str2double(data(jj,[2,3]));  % Center of the ROI in nm.
            reqSize = str2double(data(jj,[4,5])); % Full size of the ROI in nm.
            pxSize = reqSize./fullRes;            % Size of the ROI in px at source zoom.
            numTiles = ceil(pxSize/tileSize);     % Number of tiles;
            nmPerTile = tileSize*fullRes;
            centerX = center(1)-((numTiles(1)-1)/2*nmPerTile(1))+(0:numTiles(1)-1)*nmPerTile(1);
            centerY = center(2)-((numTiles(2)-1)/2*nmPerTile(2))+(0:numTiles(2)-1)*nmPerTile(2);
            calllib('NDPRead','SetCameraResolution',tileSize, tileSize);
            multiWaitbar( 'Current ROI', 'Value', 0 );
            if createTraining
                XX = randperm(numTiles(1));
                YY = randperm(numTiles(2));
                numSelected = 0; this = 1;
                while numSelected<2
                    [~,~,~,~,~,bufferSize] = calllib('NDPRead','GetImageData',NDP,centerX(XX(this)),centerY(YY(this)),0,sourceLens,0,0,0,0);
                    [~,~,physWidth,physHeight,buffer,~] = calllib('NDPRead','GetImageData',NDP,centerX(XX(this)),centerY(YY(this)),Z,sourceLens,0,0,zeros(1,bufferSize,'uint8'),bufferSize);
                    physWidth = double(physWidth); physHeight = double(physHeight);
                    dimensions = [physWidth,physHeight];
                    IMG = buildImageSeperate(buffer,tileSize,tileSize,noChannels,channelOrder);
                    imshow(IMG,[]);
                    choice = menu('Good tile?', 'no', 'yes')-1;
                    if choice
                        numSelected = numSelected+1;
                        filename = sprintf('%s_%s_tile%1.0f_%03.0f-%03.0f.png',fileNames{ii},currentName,numSelected,XX(this),YY(this));
                        imwrite(IMG,fullfile(trainingPath,filename),'png')
                    end
                    this = this+1;
                end
            else
                HistImage = zeros(numTiles(1),numTiles(2),3);
                ClusterImage = zeros(numTiles(1),numTiles(2),numClus);
                iii = 0; N = numTiles(1)*numTiles(2);
                for XX = 1:numTiles(1)
                    for YY = 1:numTiles(2)
                        iii = iii + 1;
                        [~,~,~,~,~,bufferSize] = calllib('NDPRead','GetImageData',NDP,centerX(XX),centerY(YY),0,sourceLens,0,0,0,0);
                        [~,~,physWidth,physHeight,buffer,~] = calllib('NDPRead','GetImageData',NDP,centerX(XX),centerY(YY),Z,sourceLens,0,0,zeros(1,bufferSize,'uint8'),bufferSize);
                        physWidth = double(physWidth); physHeight = double(physHeight);
                        dimensions = [physWidth,physHeight];
                        IMG = buildImageSeperate(buffer,tileSize,tileSize,noChannels,channelOrder);
                        IMGdata = reshape(IMG,[],3);
                        IMGdata = double(applycform(IMGdata,cform));
                        D = pdist2(IMGdata(:,2:3),Centroids,'Euclidean'); 
                        [~,IX] = min(D,[],2);
                        for n = 1:numClus
                            ClusterImage(XX,YY,n) = sum(IX==n)/tileSize^2;
                        end
                        %imshow(IMG,[]); drawnow;
                        HistImage(XX,YY,:) = mean(mean(IMG));
                        
                        multiWaitbar( 'Current ROI','Value',iii/N);
                    end
                end
            end
            save(fullfile(resultsPath,[currentName,'.MAT']),'HistImage','ClusterImage')
            multiWaitbar( 'Current slide','Value',jj/size(data,1));
        end
        multiWaitbar( 'Overall', 'Value', ii/8 );
    end
else  % Analyze Training
    data = zeros(0,3,'uint8');
    files = dir(fullfile(trainingPath,'*.png'));
    N = length(files);
    for ii = 1:N
        IMG = imread(fullfile(trainingPath,files(ii).name));
        data(end+1:end+(tileSize^2),:) = reshape(IMG,[],3);
    end
    data2 = double(applycform(data,cform));
    fprintf('Clustering ....');
    [IDX,Centroids] = kmeans(data2(:,2:3),numClus,'replicates',6);
    fprintf('Done\n');
    %% Show it.
    figure
    num = 3;
    subplot(121); imshow(reshape(data([1:(tileSize^2)]+(num-1)*(tileSize^2),:),tileSize,tileSize,3));
    subplot(122); imshow(reshape(IDX([1:(tileSize^2)]+(num-1)*(tileSize^2)),tileSize,tileSize),[]); colormap jet
    %% Histogram of one cluster RGB
    figure('Name','Histograms for all clusters (RGB)'); 
    for cluster = 1:numClus
        subplot(ceil(numClus/ceil(sqrt(numClus))),ceil(sqrt(numClus)),cluster);
        hist(reshape(data(repmat(IDX,1,3)==cluster),[],3),0:255);
        h = findobj(gca,'Type','patch');
        set(h(3),'FaceColor',[1 0 0],'EdgeColor',[1 0 0])
        set(h(2),'FaceColor',[0 0.5 0],'EdgeColor',[0 0.5 0])
        set(h(1),'FaceColor',[0 0 1],'EdgeColor',[0 0 1])
        axis([0 255 0 Inf])
    end
    %% Save centroids.
    save(fullfile(resultsPath,'centroids.mat'),'Centroids');
end
%%
