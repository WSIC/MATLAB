clear all;
close all;
clc;
%% TEST DIMENSIONS
SZ = 1000;
tool = 'L:\JONATHAN\Software\OpenSlide\bin\openslide-write-png';

mkdir(fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\',folder));
for y = 0:ytiles-1
    Y = startY+y*SZ;
    X1 = startX;
    X2 = startX+(xtiles-1)*SZ;
    output1 = fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\',folder,sprintf('AA%03.0f.png',y));
    output2 = fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\',folder,sprintf('BB%03.0f.png',y));
    dos(sprintf('%s %s %1.0f %1.0f 0 %1.0f %1.0f %s',tool,filename,X1,Y,SZ,SZ,output1));
    dos(sprintf('%s %s %1.0f %1.0f 0 %1.0f %1.0f %s',tool,filename,X2,Y,SZ,SZ,output2));
end
fprintf('50%%');
for x = 0:xtiles-1
    X = startX+x*SZ;
    Y1 = startY;
    Y2 = startY+(ytiles-1)*SZ;
    output1 = fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\',folder,sprintf('CC%03.0f.png',x));
    output2 = fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\',folder,sprintf('DD%03.0f.png',x));
    dos(sprintf('%s %s %1.0f %1.0f 0 %1.0f %1.0f %s',tool,filename,X,Y1,SZ,SZ,output1));
    dos(sprintf('%s %s %1.0f %1.0f 0 %1.0f %1.0f %s',tool,filename,X,Y2,SZ,SZ,output2));
end
fprintf('\b\b\b100%%\n');

%% MAKE TILES
SZ = 1000;
CD = {};
CD{1} =  'startX = 36700; xtiles = 38; startY = 165600; ytiles = 26; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_1-JD1-CD31.mrxs'';   folder = ''JD01-CD31''';
CD{2} =  'startX = 33000; xtiles = 32; startY = 115800; ytiles = 22; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_2-JD2-CD31.mrxs'';   folder = ''JD02-CD31''';
CD{3} =  'startX = 18300; xtiles = 39; startY = 53500;  ytiles = 27; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_3-JD3-CD31.mrxs'';   folder = ''JD03-CD31''';
CD{4} =  'startX = 32000; xtiles = 34; startY = 175600; ytiles = 24; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_4-JD4-CD31.mrxs'';   folder = ''JD04-CD31''';
CD{5} =  'startX = 39800; xtiles = 38; startY = 123800; ytiles = 29; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_5-JD5-CD31.mrxs'';   folder = ''JD05-CD31''';
CD{6} =  'startX = 32600; xtiles = 38; startY = 76200;  ytiles = 37; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_6-JD6-CD31.mrxs'';   folder = ''JD06-CD31''';
CD{7} =  'startX = 54100; xtiles = 34; startY = 167000; ytiles = 22; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_7-JD8-CD31.mrxs'';   folder = ''JD08-CD31''';
CD{8} =  'startX = 45200; xtiles = 33; startY = 81700;  ytiles = 47; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_8-JD9-CD31.mrxs'';   folder = ''JD09-CD31''';
CD{9} =  'startX = 24900; xtiles = 42; startY = 152200; ytiles = 34; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_9-JD10-CD31.mrxs'';  folder = ''JD10-CD31''';
CD{10} = 'startX = 35700; xtiles = 18; startY = 89600;  ytiles = 31; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_10-JD11-CD31.mrxs''; folder = ''JD11-CD31''';
CD{11} = 'startX = 14800; xtiles = 54; startY = 148000; ytiles = 61; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_11-JD12-CD31.mrxs''; folder = ''JD12-CD31''';
CD{12} = 'startX = 23240; xtiles = 36; startY = 74930;  ytiles = 21; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_12-JD13-CD31.mrxs''; folder = ''JD13-CD31''';
CD{13} = 'startX = 31300; xtiles = 38; startY = 160600; ytiles = 29; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_13-JD14-CD31.mrxs''; folder = ''JD14-CD31''';
CD{14} = 'startX = 36400; xtiles = 51; startY = 69500;  ytiles = 54; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_14-JD15-CD31.mrxs''; folder = ''JD15-CD31''';

HE = {};
HE{11} = 'startX = 17000; xtiles = 57; startY = 128000; ytiles = 60; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_11-JD12.mrxs''; folder = ''JD12-HE''';
HE{14} = 'startX = 26000; xtiles = 50; startY = 81700;  ytiles = 52; filename = ''C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\12A26_14-JD15.mrxs''; folder = ''JD15-HE''';

for cd = [1,2,3,4,5,6,7,8,9,10,12,13];
    eval(CD{cd});
    tool = 'L:\JONATHAN\Software\OpenSlide\bin\openslide-write-png';
    Nu = 0; totaal = xtiles*ytiles;
    hond = waitbar(0);
    for y = 0:ytiles-1
        Y = startY+y*SZ;
        for x = 0:xtiles-1
            X = startX+x*SZ;
            output = fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\',folder,sprintf('%03.0f-%03.0f.png',y,x));
            dos(sprintf('%s %s %1.0f %1.0f 0 %1.0f %1.0f %s',tool,filename,X,Y,SZ,SZ,output));
            Nu = Nu+1;
            waitbar(Nu/totaal,hond);
        end
    end
end


%% CD31. Clustering. Initialize.
N = 5;
standard1 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD01-CD31\001-025.png');
standard2 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD01-CD31\005-031.png');
standard3 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD01-CD31\010-006.png');
standard4 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD02-CD31\016-024.png');
standard5 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD03-CD31\001-012.png');
standard6 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD03-CD31\005-027.png');
standard7 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD04-CD31\003-009.png');
standard8 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD05-CD31\001-026.png');
standard9 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD15-CD31\003-028.png');
standard = [[standard1,standard2,standard3];[standard4,standard5,standard6];[standard7,standard8,standard9]];
[KM,CC,~,D] = kmeans(double(reshape(standard,[],3)),N);
KM = reshape(KM,size(standard,1),size(standard,2));

%% CD 31. Load standard.
load('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\CD31Standard.mat');
N = size(CC,1);

%% CD31. Analyze all tiles
for cd = [1,2,3,4,5,6,7,8,9,10,11,12,13,14]
    eval(CD{cd});
    CD31 = zeros(ytiles,xtiles,N);
    IM = zeros(ytiles,xtiles,3);
    Nu = 0; totaal = xtiles*ytiles;
    hond = waitbar(0);
    for y = 0:ytiles-1
        for x = 0:xtiles-1
            filename = fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\',folder,sprintf('%03.0f-%03.0f.png',y,x));
            IMG = imread(filename);
            D = pdist2(double(reshape(IMG,[],3)),CC,'Euclidean'); 
            [~,IX] = min(D,[],2);
            Nu = Nu+1;
            for n = 1:N
                CD31(y+1,x+1,n) = sum(IX==n)/SZ^2;
            end
            IM(y+1,x+1,:) = mean(mean(IMG));
            waitbar(Nu/totaal,hond);
        end
    end
    save(fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\',[folder, '.mat']),'CD31','IM')
    imwrite(uint8(IM),fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\',[folder, '.png']),'png')
    imwrite(uint8(round(CD31(:,:,1)*2550)),fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\',[folder, '_vessel.png']),'png')
    imwrite(uint8(round(CD31(:,:,2)*2550)),fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\',[folder, '_backgr.png']),'png')
    imwrite(uint8(round(CD31(:,:,3)*2550)),fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\',[folder, '_nuclei.png']),'png')
    close(hond);
end

%% CD31. Analyze all tiles -> Higher Resolution (subtiles)

for cd = 14%[1,2,3,4,5,6,7,8,9,10,11,12,13,14]
    eval(CD{cd});
    CD31 = zeros(ytiles*2,xtiles*2,N);
    IM = zeros(ytiles*2,xtiles*2,3);
    Nu = 0; totaal = xtiles*ytiles;
    hond = waitbar(0);
    for y = 0:ytiles-1
        for x = 0:xtiles-1
            filename = fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\',folder,sprintf('%03.0f-%03.0f.png',y,x));
            IMG = imread(filename);
            D = pdist2(double(reshape(IMG,[],3)),CC,'Euclidean'); 
            [~,IX] = min(D,[],2);
            Nu = Nu+1;
            
            IX = reshape(IX,1000,1000);
            partIX = IX(1:500,1:500); 
            partIMG = IMG(1:500,1:500,:);
            for n = 1:N
                CD31((y*2)+1,(x*2)+1,n) = sum(partIX(:)==n)/250000;
            end
            IM((y*2)+1,(x*2)+1,:) = mean(mean(partIMG));
            
            partIX = IX(501:1000,1:500);
            partIMG = IMG(501:1000,1:500,:);
            for n = 1:N
                CD31((y*2)+2,(x*2)+1,n) = sum(partIX(:)==n)/250000;
            end
            IM((y*2)+2,(x*2)+1,:) = mean(mean(partIMG));
            
            partIX = IX(1:500,501:1000);
            partIMG = IMG(1:500,501:1000,:);
            for n = 1:N
                CD31((y*2)+1,(x*2)+2,n) = sum(partIX(:)==n)/250000;
            end
            IM((y*2)+1,(x*2)+2,:) = mean(mean(partIMG));
            
            partIX = IX(501:1000,501:1000);
            partIMG = IMG(501:1000,501:1000,:);
            for n = 1:N
                CD31((y*2)+2,(x*2)+2,n) = sum(partIX(:)==n)/250000;
            end
            IM((y*2)+2,(x*2)+2,:) = mean(mean(partIMG));
            
            waitbar(Nu/totaal,hond);
        end
        imshow(CD31(:,:,1),'DisplayRange',[0 0.025],'InitialMagnification','fit'); colormap jet; drawnow; 
    end
    save(fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\',['2x', folder, '.mat']),'CD31','IM')
    imwrite(uint8(IM),fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\',['2x', folder, '.png']),'png')
    imwrite(uint8(round(CD31(:,:,1)*2550)),fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis',['2x', folder, '_vessel.png']),'png')
    imwrite(uint8(round(CD31(:,:,2)*255)),fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis',['2x', folder, '_backgr.png']),'png')
    imwrite(uint8(round(CD31(:,:,3)*255)),fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis',['2x', folder, '_nuclei.png']),'png')
    close(hond);
end

%% Show some images
pos = 1;
E = [0.0005, 0.002 0.003 0.005 0.05];
colors = [1 1 1; .5 .5 1; .1 .1 1; .2 .7 .1; .8 .7 .2; 1 .5 .1; 1 0 0;];
hott = hot(256);
all = [1,2,3,4,5,6,7,8,9,10,11,12,13,14];
Colo = [1,3,5,9,10];
NCI  = [2,4,6,7,8,11,12,13,14];
for cd = [Colo, NaN, NCI]
    if ~isnan(cd)
        eval(CD{cd});
        load(fullfile('L:\JONATHAN\Work\IVIM-ASL\MatlabAnalysis\',['2x', folder, '.mat']));
        jd = CD31(:,:,1);
        jd2 = zeros(size(jd)); jd2(jd>0 & jd<=E(1)) = 1; jd2(jd>E(1) & jd<=E(2)) = 2; jd2(jd>E(2) & jd<=E(3)) = 3; jd2(jd>E(3) & jd<=E(4)) = 4; jd2(jd>E(4) & jd<=E(5)) = 5; jd2(jd>E(5)) = 6;
        jd2 = colors(jd2+1,:); jd2 = reshape(jd2,size(IM,1),size(IM,2),3);
        %jd = jd./max(jd(:)); 
        jd = jd./0.05; jd(jd>1) = 1;
        jd = hott(round(jd*255+1),:);
        jd = reshape(jd,size(IM,1),size(IM,2),3);
        img = [jd2,IM/255; jd, repmat(CD31(:,:,2),[1 1 3])];
        subplot(3,5,pos)
        imshow(img,[])
        iets = get(gca,'Position');
        X = 0.05; iets = iets+[-X -X X X];
        set(gca,'Position', iets)
        title(folder)
    end
    pos = pos+1;
end

colormap(colors)

%% H&E Clustering.
N = 5;
standard1 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD15-HE\001-029.png');
standard2 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD15-HE\020-042.png');
standard3 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD15-HE\018-011.png');
standard4 = imread('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD15-HE\027-006.png');
standard = [[standard1,standard2];[standard3,standard4]]; 
[KM,CC,~,D] = kmeans(double(reshape(standard,[],3)),N);
KM = reshape(KM,size(standard,1),size(standard,2));
something = 1;
%% H&E analysis.
HE = zeros(xtiles,ytiles,N);
IM = zeros(xtiles,ytiles,3);
Nu = 0; totaal = xtiles*ytiles;
hond = waitbar(0);
for y = 0:ytiles-1
    for x = 0:xtiles-1
        filename = fullfile('C:\Users\radissj1\JONATHANDATA\PROJECTS\2012-IVIMASL\Histology\OpenSlide\JD15-HE',sprintf('%03.0f-%03.0f.png',y,x));
        IMG = imread(filename);
        D = pdist2(double(reshape(IMG,[],3)),CC,'Euclidean'); 
        [~,IX] = min(D,[],2);
        Nu = Nu+1;
        for n = 1:N
            HE(x+1,y+1,n) = sum(IX==n);
        end
        IM(x+1,y+1,:) = mean(mean(IMG))./255;
        waitbar(Nu/totaal,hond);
    end
    for i = 1:N, try subplot(2,3,i); end; imshow(HE(:,:,i),[]); end; 
    subplot(236); imshow(IM); colormap jet; drawnow
end
close(hond);


%% Show One Image
imshow(imadjust(IM/256,stretchlim(IM/256),[])); set(gca,'Position',[0 0 1 1])

