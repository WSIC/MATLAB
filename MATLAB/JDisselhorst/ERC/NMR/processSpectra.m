function [ax1,sp1] = processSpectra(ax1,sp1,varargin)
% PROCESSSPECTRA processes NMR spectra
% 
% Usage: [ax1,sp1] = processSpectra(ax,sp,select,range,thresh,binsize,align)
% 
% Inputs:
%         o ax:      the axes of the spectra to process (NxM)
%         o sp:      the spectra to process (NxM)
%         o select:  only process these spectra, e.g., [1, 3, 5:7]
%                    optional argument, leave empty to use all
%         o range:   select only a certain ppm-range, e.g., [0,6]
%                    optional, leave empty to use the entire spectrum
%         o thresh:  threshold for probabilistic quotient normalization,
%                    see below. Optional argument, leave empty to skip the
%                    normalization. A good value seems to be 3. 
%         o binsize: downsample the spectra with this binsize in ppm.
%                    optional argument, leave empty to skip downsampling.
%                    Note: the final binsize will depend on the original
%                    sampling, as only entire bins will be combined. 
%         o align:   align the spectra to the first big peak 
%                    optional, 1 or 0. 
%
% Output:
%         o ax1:     the processed axes
%         o sp1:     the processed spectra
%
% J.A. DISSELHORST - WERNER SIEMENS IMAGING CENTER
% 2014.06.12
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
% EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

p = inputParser;
addRequired(p,'ax1');
addRequired(p,'sp1');
addOptional(p,'select',[],@(x) isempty(x) || isnumeric(x));
addOptional(p,'range',[],@(x) isempty(x) || (isnumeric(x) && numel(x)==2));
addOptional(p,'PQNthresh',[],@(x) isempty(x) || isscalar(x));
addOptional(p,'resampbin',[],@(x) isempty(x) || isscalar(x));
addOptional(p,'align',0);
parse(p,ax1,sp1,varargin{:});
select    = p.Results.select;
range     = p.Results.range;
PQNthresh = p.Results.PQNthresh;
resampbin = p.Results.resampbin;
align     = p.Results.align;

if ~isempty(select)
    sp1 = sp1(select,:);
    ax1 = ax1(select,:);
end
M = size(sp1,1);

if align
    validrange = [0.5, 0.9]; % peak should be between these ppms
    gem = real(mean(sp1,2));
    results = zeros(M,2);
    for ii = 1:M
        spectrum = real(sp1(ii,:));
        spectrum = smooth(spectrum,30);
        pks = peakfinder(spectrum, gem(ii)*5);
        if ~isempty(pks)
            ppos = ax1(ii,pks);
            ppos(ppos>validrange(2) | ppos<validrange(1)) = Inf;
            [C,I] = min(ppos);
            if ~isinf(C)
                results(ii,:) = [pks(I),C];
            end
        end
    end
    medianpeak = median(results(:,2));
    for ii = 1:M
        if results(ii,1)==0
            continue
        end
        [~,I] = min(abs(ax1(ii,:)-medianpeak)); % index where the peak should be
        shift = (results(ii,1)-I);
        spectrum = sp1(ii,:);
        if shift<0
            spectrum = [zeros(1,abs(shift)), spectrum(1:end+shift)];
        elseif shift>0
            spectrum = [spectrum(shift+1:end), zeros(1,shift)];
        end
        sp1(ii,:) = spectrum;
    end
end

if ~isempty(range)
    startpos = range(1);   % ppm
    endpos   = range(2);   % ppm

    temp = abs(ax1-endpos); %temp(temp<0) = Inf;
    [a,xend] = find(temp==repmat(min(temp,[],2),[1,size(temp,2)]));
    [~,ix] = sort(a); xend = xend(ix);
    temp = abs(ax1-startpos); %temp(temp<0) = Inf;
    [a,xstart] = find(temp==repmat(min(temp,[],2),[1,size(temp,2)]));
    [~,ix] = sort(a); xstart = xstart(ix);
    nsample = unique(xstart-xend+1); xstart = min([xstart,xend],[],2);
    if length(nsample)~=1
        warning('DISSELHORST:WrongAxes','Differences in number of samplepoints in the given given range (%1.0f-%1.0f ppm)!',startpos,endpos)
        nsample = max(nsample);
    end
    if length(unique(ax1(sub2ind(size(ax1),1:M,xstart'))))~=1
        warning('DISSELHORST:WrongAxes','Differences in startposition between the spectra!')
    end

    temp = zeros(M,nsample); temp2 = temp;
    for ii = 1:M
        temp(ii,:) = sp1(ii,xstart(ii):xstart(ii)+nsample-1);
        temp2(ii,:)  = ax1(ii,xstart(ii):xstart(ii)+nsample-1);
    end
    sp1 = temp;
    ax1 = temp2;
end

if ~isempty(PQNthresh)
    %% Probabilistic quotient normalization
    % Dieterle, Ross, Schlotterbeck, and Senn. Anal Chem (2006);78:4281-4290
    % http://pubs.acs.org/doi/full/10.1021/ac051632c
    spectra2 = real(sp1);                 % only use the real part
    saxisref = unique(ax1,'rows');          % reference axis;
    if size(saxisref,1)>1                      % apparently there are different axes
        Q = questdlg('Continue?','Differences in axes!','Yes','No','No');
        if ~strcmpi(Q,'Yes')
            error('DISSELHORST:WrongAxes','Differences in axes!')
        else
            saxisref = mean(saxisref);
        end
    end
    binsize = abs(mean(diff(saxisref)));

    for ii = 1:M                               % Integral normalization
        temp = spectra2(ii,:);
        temp = temp/(trapz(temp)*binsize)*100;
        spectra2(ii,:) = temp;
    end

    reference = median(spectra2);              % The reference spectrum

    figure; hold on;
    plot(saxisref,reference,'g'); 
    temp = max(spectra2);
    plot(saxisref,temp,'g:')
    temp = reference; temp(reference<PQNthresh) = NaN;
    plot(saxisref,temp,'r','LineWidth',2); 
    plot(saxisref,temp*0-PQNthresh,'r')
    hold off;
    title(sprintf('PQNthresh: %g. Correct?',PQNthresh));
    legend({'Median','Maximum','Selected'})
    axis([-Inf Inf -PQNthresh*5 Inf]);
    for ii = 1:M
        temp = spectra2(ii,:);
        temp2 = temp./reference;                % quotients
        temp2(reference<PQNthresh) = [];        % remove everything below the treshold.
        spectra2(ii,:) = temp/median(temp2);    % divide by the median quotient.
    end
    sp1 = spectra2;
end

if ~isempty(resampbin)
    bs = unique(diff(ax1,1,2),'rows');
    if size(bs,1)>1
        Q = questdlg('Continue?','Binsize not the same on all axes!','Yes','No','No');
        if ~strcmpi(Q,'Yes')
            error('DISSELHORST:WrongAxes','Differences in axes!')
        else
            bs = mean(bs);
        end
    end
    bs  = unique(bs);
    if length(bs)>1
        if max(diff(bs))<1E-12
            bs = mean(bs);
        else
            error('DISSELHORST:WrongAxes','Binsize varies with %1.0g',max(diff(bs)));
        end
    end

    nsample = size(ax1,2);
    binsamples = abs(round(resampbin/bs));
    nsample = floor(nsample/binsamples)*binsamples;

    spectra2 = zeros(M,nsample/binsamples);
    saxis2 = spectra2;
    for ii = 1:M
        temp = sp1(ii,1:nsample);
        temp = sum(reshape(temp,binsamples,[]));
        spectra2(ii,:) = temp;
        temp = ax1(ii,1:nsample);
        temp = mean(reshape(temp,binsamples,[]));
        saxis2(ii,:) = temp;
    end
    sp1 = spectra2; ax1 = saxis2;
end