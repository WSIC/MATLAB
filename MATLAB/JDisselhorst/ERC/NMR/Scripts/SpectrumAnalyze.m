%% Get spectra, 
%clc; clear all; close all
% mainFolder = 'F:\DATA\NMR\AndreasSchmid'; % mainFolder = 'E:\NMR\AndreasSchmid';
%mainFolder = 'F:\DATA\NMR\ERC\Narcosis\Measurement_MODIFIED_JD';
%mainFolder = 'F:\DATA\NMR\ERC\MetaboLiver\MeasurementOriginal';
%mainFolder = 'F:\DATA\NMR\ERC\MetaboLiverII\Jonathan';
%mainFolder = 'F:\DATA\NMR\ERC\MetaboLiverII\Mathew';
%mainFolder = 'F:\DATA\NMR\ERC\MetaboLiverII\Valerie';
%mainFolder = 'F:\DATA\NMR\ERC\MetaboLiverII\Marcel';
%mainFolder = 'F:\DATA\NMR\ERC\MetaboLiverII\Combined';
%mainFolder = 'F:\DATA\NMR\ERC\MarcelTumors\NOESY';
%mainFolder = 'V:\NMR\ERC09';
mainFolder = 'V:\NMR\ERC10';


meas = dir(mainFolder); meas(~[meas.isdir]) = [];
if isempty(meas)
    fprintf('No spectra found in %s, or non existing location!\n',mainFolder);
    return;
end
use = regexp({meas.name},'\d+'); use = cellfun(@(x) isequal(1,x),use);
meas = meas(use);

% Loop over the measurement:
Bruker = BrukerNMR(fullfile(mainFolder,meas(1).name));
spectra = reshape(Bruker.spectrumBruker,1,[]);
spectra = repmat(spectra,length(meas),1);
saxis   = reshape(Bruker.spectrumAxis,1,[]);
saxis   = repmat(saxis,length(meas),1);

if length(meas)>1
spectra(2:end,:) = 0;
saxis(2:end,:)   = 0;
titles = cell(length(meas),1);
times = zeros(length(meas),1);
for ii = 1:length(meas)
    Bruker = BrukerNMR(fullfile(mainFolder,meas(ii).name));
    spectra(ii,:) = Bruker.spectrumBruker;
    saxis(ii,:) = Bruker.spectrumAxis;
    fprintf('%1.0f / %1.0f \n',ii,length(meas));
    times(ii) = datenum(Bruker.General.AcquisitionTime);
    titles{ii} = strjoin(reshape(Bruker.General.Title,1,[]),' ');
       
end
end
N = size(spectra,1);
meas = cellfun(@str2double,{meas.name})';

clear use ii Bruker

%% standard:
offset = 0;
colors = rand(N,3);
cc = ones(N,1);
info = [meas,meas,ones(N,1),ones(N,1)*-1,ones(N,1)*-1,cc-1];
%% ERC-9
offset = 0.28;
mousenum = cell2mat(cellfun(@(x) str2double(x(7:10)),titles,'UniformOutput',false));
colors = [1 0 0; 0 0 1];
cc = (mousenum<=9537) + 1;
info = [meas,mousenum,ones(10,1),ones(10,1)*-1,ones(10,1)*-1,cc-1];
F2 = {'018P','002P'};

%% ERC-10 [sample#,mouse#,tissue,FDG,weight,type]
info = csvread('V:\NMR\ERC10\ERC-10.csv',1,0);
[~,IX] = setdiff(info(:,1),meas);
info(IX,:) = [];
if any(info(:,1) ~= meas), error('exception'); end
cc = info(:,3)*2+info(:,6)+1;
colors = [1,0,0;.8,0,.7;0,0,1;0,.8,0];
offset = 0.28;
F2 = {'Control','Cetux'};

%% Do some processing
%select = 7:24;   % which spectra to use
select = [];
select = find(meas>200);

range = [0 6];  % which range (in ppm)

PQNthresh = 4;  % the threshold for probabilistic quotient normalization (leave empty ([]) to skip
%PQNthresh = [];  % the threshold for probabilistic quotient normalization (leave empty ([]) to skip

% Rebinning. [downsample 2: 0.000611, downsample 4: 0.001222]
resampbin = 0.001222; % rebinning to this ppm binsize (leave empty to skip resampling)
%resampbin = [];

align = 0;
%align = 1;

%[ax1,sp1] = processSpectra(saxis,spectra,select,range,PQNthresh,resampbin,align);
[ax1,sp1] = processSpectra(saxis,spectra,select,range,PQNthresh,resampbin,align);

% offset
ax1 = ax1+offset; 

h = showSpectra(ax1,sp1);

%%
%showSpectra(ax1,sp1,colors(info(select,1)+1,:));
close all;
SampleNames = cellfun(@(x,y) sprintf('S%1.0f_M%1.0f',x,y),num2cell(meas),num2cell(info(:,2)),'UniformOutput',0);
h = showSpectra(ax1,sp1,colors(cc,:),SampleNames);

%% WRITE CSV:
a = cellfun(@(x) sprintf('Bin %1.3f',x),num2cell(median(ax1)),'UniformOutput',0);
b = num2cell(sp1);

% Sample names, two factors
SampleNames = [{'AnimalID'}; cellfun(@(x,y) sprintf('S%1.0f_M%1.0f',x,y),num2cell(meas),num2cell(info(:,2)),'UniformOutput',0)];
F1 = {'Liver','Tumor'}; 
f1 = [{'Tissue'}; F1(info(:,3)+1)']; f2 = [{'Group'}; F2(info(:,6)+1)'];

total = [SampleNames,f2,[a;b]];
cell2csv('C:\Users\radissj1\Desktop\file.csv',total);
%% Calculate relative change over multiple measurements.
x = mean(saxis3); y = median(spectra3); y = y/sum(y);
pp = peakfinder(y,0.001,0.005);
plot(x,y); hold on; 
plot(x(pp),y(pp),'ro');
slopes = zeros(3,length(pp));
for ii = 1:length(pp)
    [p,S] = polyfit((1:M)',spectra3(:,pp(ii)),1);
    yfit = polyval(p,(1:M)');
    yresid = spectra3(:,pp(ii)) - yfit;
    SSresid = sum(yresid.^2);
    SStotal = (M-1)*var(spectra3(:,pp(ii)));
    rsq = 1-SSresid/SStotal;
    
    slopes(:,ii) = [p(1), p(2), p(1)/p(2)];
    text(x(pp(ii)),y(pp(ii))+.001,sprintf('%+1.0f%% \n%1.2f',slopes(3,ii)*100,rsq),...
        'Color',[1-(slopes(3,ii)>0), 0, 0],'HorizontalAlignment','Center','VerticalAlignment', 'Bottom')
end
hold off
set(gca,'XDir','reverse')
xlabel('Chemical shift \delta [ppm]');
ylabel('Abundance [A.U.]')
axis([startpos endpos -max(y)/10 max(y)*1.1]);
set(gcf,'Color', 'w');
