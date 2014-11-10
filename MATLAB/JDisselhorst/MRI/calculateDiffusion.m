function results = calculateDiffusion(imageMatrix,headers,mask,method,bValueRange,verbose)
% Calculate diffusion parameters from a DWI-MRI using several methods
%
% Usage:
% results = calculateDiffusion(imageMatrix,bValues,mask,method,bValueRange)
%
% Input:
% * imageMatrix: Matrix containing measurements at different bValues
%                Matrix can have any dimension as long as the last
%                dimension describes the different measurements:
%                [M*N*...*numBvalues]
% * headers:     The DICOM headers containing the bValues, OR ...
%                ... The bValues used for the measurements [s/mm^2]
%                [numBValues*1 or 1*numBValues]
% * mask:        Optional mask matrix. Leave empty if not needed.
%                [M*N*...]
% * method:      One of the following methods [Default: ADClin]
%              - ADC:        Apparent diffusion coefficient (Ref. 1)
%              - ADClin:     ADC, but calculated using linear regression.
%              - IVIM:       Intravoxel Incoherent Motion (Ref. 1)
%              - NGIVIM:     Non-Gaussian IVIM
%                            Lu et al. [2] use bValues 13-1448
%              - Kurtosis:   Kurtosis model
%                            Jensen et al [3] use bValues 0-2500
%              - Stretch:    Stretched exponential
%                            Bennett et al. [4] use bValues 500-6500 
%                            Mazaheri et al. [5] use bValues 0-1200
%              - TwoExp:     Two exponential for high b's
%                            Niendorf et al. [6] use bValues 10-10000
%                            Mulkern et al. [7] use bValues 100-5000
%              - StatModel1: Statistical model  - EXPERIMENTAL!
%                            This function does not converge properly!!
%                            Yablonskiy et al [8] use bValues 150-2250
%              - StatModel2: See above, but does not use the error
%                            function, and is therefore faster and does
%                            converge, is valid when sigma << ADC and
%                            bValues << ADC/sigma^2.  
%              - 2S[Method]: Fix 'D' using a single exponential fit of the
%                            bValues between 200 and 1000. (Ref. 9)
%                            Valid for ADC, IVIM, NGIVIM, Kurtosis, ...
%                                      TwoExp, StatModel
%              - 3S[Method]: Fix 'D' and 'F' like above. 
%                            Valid for IVIM. (Ref. 10)
% * bValueRange: Only use bValues within a certain range [MIN, MAX]
%                Values that will be used: MIN<=bValues<=MAX
% * verbose:     Show information or not. [1: show (default), 0: do not]
%
% Output:
% * results:     A matrix with all relevant parameters + R^2 + AICc
%                [M*N*...*numParameters]
%                AICc is Akaike's "An Information Criterion" corrected for
%                small sample size. Measurement for goodness of fit with a
%                penalty for the number of parameters. A lower value is
%                better. However, it is only informative when several
%                methods are compared using the same data. (Ref. 11 & 12)
%                Note that when no method is provided, ADC linear is used
%                for calculation. In this case, the only output will be
%                ADC, without R^2 or AIC.
%
% References:
%  1) LeBihan et al. Radiology. 1988;168:497–505. 
%  2) Lu et al. J Magn Reson Imaging. 2012;36:1088–96. 
%  3) Jensen et al. Magn Reson Med. 2005;53:1432–40
%  4) Bennett et al. Magn Reson Med. 2003;50:727–34
%  5) Mazaheri et al. J Comput Assist Tomogr. 2012;36:695–703. 
%  6) Niendorf et al. Magn Reson Med. 1996;36:847–57. 
%  7) Mulkern et al. Magn Reson Imaging. 2001;19:659–68
%  8) Yablonskiy et al. Magn Reson Med. 2003;50:664–9. 
%  9) Luciani et al. Radiology. 2008;249:891–9
% 10) Cho et al. Magn Reson Med. 2012;67:1710–20
% 11) Akaike. IEEE Trans Automat Contr. 1974;19:716–23
% 12) Hurvich & Tsai. Biometrika. 1989;76:297–307
% 13) Holz et al. Phys Chem Chem Phys. 2000;2:4740–2
%
% Jonathan A. Disselhorst, Uni. Tuebingen
% Last Version: 3 December 2012.
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');


% Initialize  -------------------------------------------------------------
if nargin == 0
    help(mfilename);
    return
end
if iscell(headers) % It will probably be a cell array of dicom headers.
    N = size(headers,2);
    bValues = zeros(1,N);
    FFT = zeros(N,1);
    for ii = 1:N
        try bValues(ii) = headers{1,ii}.Private_0019_100c;
        catch; error('No b-value in ''0019x100c'''); end
        [~,~,phoenix] = parseSiemensCSAHeader(headers{1,ii});
        for CoilElem = 1:length(phoenix.asCoilSelectMeas{1}.aFFT_SCALE)
            FFT(ii,CoilElem) = phoenix.asCoilSelectMeas{1}.aFFT_SCALE{CoilElem}.flFactor;
        end
    end
    if any(var(FFT))
        info = sprintf('%1.4f, ',mean(FFT,2));
        warning('Irregularities detected in FFT scale factor! See variable ''FFT'' and ''bValues'' in workspace.\nFFT: %s\b\b',info)
        assignin('base','FFT',FFT);
        assignin('base','bValues',bValues);
    end
%     if FFT(1)~=4  % Only required in specific cases. J.Disselhorst;
%         warning('FFT != 4')
%     end
else % It will probably be a list of bValues.
    bValues = headers;
end
if nargin<5 || isempty(bValueRange)
    bValueRange = [min(bValues), max(bValues)];
end
selection = bValues>=bValueRange(1) & bValues<=bValueRange(2);
imageMatrix = imageMatrix(:,:,:,selection);
bValues = bValues(selection);

if nargin<6
    verbose = 1;
end
matrixSize = size(imageMatrix);
if numel(imageMatrix) == numel(bValues)  % Just one voxel is provided
    matrixSize = [1 length(bValues)];    % because dimension could be Nx1 or 1xN
end
T = matrixSize(end);
if T~=length(bValues)                    % Size of the matrix and number of bvalues should match.
    error('CalculateDiffusion:InvalidDimensions','Dimensions of bValues and image data do not match! (Number of bValues: %1.0f; Data: %1.0f)',length(bValues),T);
end
if length(bValues)<2
    error('CalculateDiffusion:InvalidBValues','At least 2 bValues are required!')
end
totalVox    = prod(matrixSize(1:end-1));
imageMatrix = reshape(imageMatrix,[totalVox,T]); % reshape data
bValues     = reshape(bValues,[1,T]);
if nargin<4                                      % calculation methods is not defined -> standard ADC.
    method = 'ADClin';
    fprintf('Switching to default method: Fully linear ADC\n');
end
bValues = bValues/1000;       % We want the output to be micrometer^2/millisecond or 10^-3 mm^2/s; This is not SI, but is quite common in literature.

% Mask --------------------------------------------------------------------
if nargin<3 || isempty(mask)  % Mask is not specified: use every voxel except NaNs
    mask = ~isnan(sum(imageMatrix,2));
else
    if numel(mask)==totalVox
        mask = reshape(mask,[totalVox,1]);
    else
        error('CalculateDiffusion:InvalidDimensions','The number of elements in the mask should be equal to the number of voxels! (Mask: %1.0f; Data: %1.0f)',numel(mask),totalVox);
    end
end

% Method ------------------------------------------------------------------
if strcmpi(method(1:2),'2S') || strcmpi(method(1:2),'3S')           % First estimate Diffusion
    numSteps = str2double(method(1));
    method = method(3:end);
    selection = (bValues<=1 & bValues>=.2);            % Select the bValues between 200 and 1000 s/mm^2
    if sum(selection)<2                                % There should be at least two of those.
        error('CalculateDiffusion:InvalidBValues','At least 2 bValues are required in the range between 200 and 1000 s/mm^2')
    end
    X = [ones(sum(selection),1), bValues(selection)']; % For the linear fit: first column is for the intercept the second for the slope.
elseif strcmpi(method,'ADClin')                        % Linear ADC, using all bvalues. [default]
    X = [ones(length(bValues),1), bValues'];           % For the linear fit: first column is for the intercept the second for the slope.
    selection = 1:length(bValues);                     % This is set for the linear fit, used below.
    if nargin>=4                                       % It is not the default, ADClin has been requested by the user.
        numSteps = Inf;                                % Set to Inf to indicate that only a linear fit should be performed below.
    else
        numSteps = -Inf;
    end
else
    numSteps = 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% BOUNDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% o Self-Diffusion pure water at 37°C: % D = 3.04 µm^2/ms. 
%   Interpolated from: ref. 13
%   IVIM D parameter has 3.0 as upper bound.
%   Pseudodiffusion can be much higher. 
%   Also ADC can be higher as a result of perfusion
% o The images have a maximum image value of 4095. This is also the upper
%   bound for S0. This could be insufficient if, for instance, the
%   measurements start at a high bValue. In that case, adjust the bounds
%   manually.
% o Some parameter have very broad ranges, because physiological ranges are
%   unknown to me.
switch method
    case 'ADClin'                          % Purely linear fit for ADC.
        LB = [0, 0];                       % Lower bound for all parameters
        UB = [5, 4096];                    % Upper bound
        varNames = {'Apparent diffusion coefficient (ADC) [µm^2/ms]', 'Fitted signal intensity at b=0 (S0) [A.U.]'};          % Names of the parameters.
        validBRange = [150 600; 300 1000]; % minimal min(b), minimal max(b); maximal min(b), maximal max(b)
    case 'ADC'
        F = @(p,x) exp(-p(1)*x)*p(2);      % Fit-function
        LB = [0, 0];                       % Lower bound for all parameters
        UB = [5, 4096];                    % Upper bound
        SP = [1, 800];                     % Startpoint for fit
        varNames = {'Apparent diffusion coefficient (ADC) [µm^2/ms]', 'Fitted signal intensity at b=0 (S0) [A.U.]'};          % Names of the parameters.
        validBRange = [150 600; 300 1000]; % minimal min(b), minimal max(b); maximal min(b), maximal max(b)
    case 'IVIM'
        F = @(p,x) ( (1-p(3))*exp(-x*p(1)) + p(3)*exp(-x*(p(2)+p(1))) )*p(4);
        LB = [0, 0,    0,    0 ];
        UB = [3, 1000, 1,    4096];
        SP = [1, 10,   0.05, 800];
        varNames = {'Diffusion coefficient (D) [µm^2/ms]','Pseudodiffusion coefficient (D*) [µm^2/ms]','Perfusion fraction (F)','Fitted signal intensity at b=0 (S0) [A.U.]'};
        validBRange = [0 600; 100 1000];
    case 'NGIVIM'
        F = @(p,x) ( (1-p(3))*exp(-x*p(1) + (1/6)*x.^2*p(1).^2*p(4)) + p(3)*exp(-x*p(2))) * p(5);
        LB = [0, 0,    0,    0, 0];
        UB = [3, 1000, 1,    5, 4096];
        SP = [1, 10,   0.05, 1, 800];
        varNames = {'Diffusion coefficient (D) [µm^2/ms]', 'Pseudodiffusion coefficient (D*) [µm^2/ms]', 'Perfusion fraction (F)', 'Kurtosis (K)', 'Fitted signal intensity at b=0 (S0) [A.U.]'};
        validBRange = [0 600; 100 1500];
    case 'Kurtosis'
        F = @(p,x) exp(-x*p(1) + (1/6)*x.^2*p(1).^2*p(2)) * p(3);
        LB = [0,  0, 0];
        UB = [50, 5, 4096];
        SP = [1,  1, 800];
        varNames = {'Diffusion coefficient (D) [µm^2/ms]', 'Kurtosis (K)', 'Fitted signal intensity at b=0 (S0) [A.U.]'};
        validBRange = [0 600; 500 3000];
    case 'Stretch'
        F = @(p,x) exp( -((x*p(1)).^p(2)) )*p(3);
        LB = [0,  0,   0];    
        UB = [10, 1,   4096]; % See bennett et al.
        SP = [1,  0.7, 800];
        varNames = {'Distributed (or Kohlrausch) diffusion coefficient (DDC) [µm^2/ms]','Streching parameter (alpha)','Fitted signal intensity at b=0 (S0) [A.U.]'};
        validBRange = [0 600; 500 5000];
    case 'TwoExp'
        F = @(p,x) exp(-x*p(1))*(p(4)*p(3)) + exp(-x*p(2))*(p(4)*(1-p(3)));
        LB = [0,  0,   0,   0];
        UB = [50, 50,  1,   4096];
        SP = [1,  0.1, 0.5, 300];
        varNames = {'Diffusion coefficient 1 (Da) [µm^2/ms]','Diffusion coefficient 2 (Db) [µm^2/ms]','Scale factor 1 (A)','Scale factor 2 (B)','A/(A+B)'};
        validBRange = [200 1500; 500 1E4];
    case 'StatModel1'
        F = @(p,x) (((1+erf((p(1)/(p(2)*sqrt(2))) - ((x*p(2))/(sqrt(2)))))/(1+erf(p(1)/(p(2)*sqrt(2))))).*exp(-x*p(1)+0.5*x.^2*p(2).^2))*p(3);
        LB = [0,  0,   0];
        UB = [50, 10,  4096];
        SP = [1,  0.1, 800];
        varNames = {'Apparent diffusion coefficient (ADC) [µm^2/ms]','Sigma','Fitted signal intensity at b=0 (S0) [A.U.]'};
        validBRange = [0 600; 500 3000]; % I don't really know, this seems ok, given yablonskiy's bValues.
        warning('StatModel1: This model does not converge properly! Possibly related to the error function Erf, use StatModel2 instead. See HELP for details!');
    case 'StatModel2'
        F = @(p,x) exp(-x*p(1)+0.5*x.^2*p(2).^2)*p(3);
        LB = [0,  0,   0];
        UB = [50, 10,  4096];
        SP = [1,  0.1, 800];
        varNames = {'Apparent diffusion coefficient (ADC) [µm^2/ms]','Sigma','Fitted signal intensity at b=0 (S0) [A.U.]'};
        validBRange = [0 600; 500 3000]; % I don't really know, this seems ok, given yablonskiy's bValues.
    otherwise
        error('CalculateDiffusion:InvalidMethod','''%s'' is not a valid method!',method);
end
% Test if the bValues are within the expected range for this method -------
thisBRange = [min(bValues) max(bValues)]*1000;
if any(~[thisBRange>=validBRange(1,:), thisBRange<=validBRange(2,:)])
    warning('CalculateDiffusion:bValuesOutOfRange','(Some) bValues are out of the expected range for the %s model. See HELP for details.',method);
end

% Fit parameters ----------------------------------------------------------
options             = optimset('lsqcurvefit');
options.Display     = 'off';
options.FunValCheck = 'on';
options.UseParallel = 'Always';
options.TolFun      = 1E-8;
options.TolX        = 1E-8;
options.MaxFunEvals = 5000;
options.MaxIter     = 5000;
options.Algorithm   = 'trust-region-reflective';
%options.Algorithm   = 'levenberg-marquardt'; warning('Levenberg-Marquardt selected!');

% Test for clipping / saturation ------------------------------------------
numClip = sum(imageMatrix(repmat(mask,[1 T])) >= 4095);
if numClip
    warning('CalculateDiffusion:Clipping','A value of 4095 has been found %1.0f times.',numClip);
end

% Calculate all voxels ----------------------------------------------------
nParam = length(LB)+2; % This is used for the results, number of parameters + r^2 + AICc.
K = length(LB)+1;      % This is used for the AICc. Number of parameters + 1.
if numSteps==-Inf
    nParam = 2;
end
results = zeros(totalVox,nParam);
mask = find(mask);
total = length(mask);
if verbose, fprintf('Calculating: ......');
    wbh = waitbar(0,'Calculating: .....','Name',sprintf('Calculating using %s model',method));
    wbp = ceil(total/1000);  % Parameter to update the waitbar only every 0.1%
end
for a = 1:total
    voxelValues = imageMatrix(mask(a),:);
    N = length(bValues);
    if numSteps % first do a linear fit if numSteps > 0
        A = X\log(voxelValues(selection))';    % Linear fit Y = A(2)X+A(1)
        D = -A(2); Intercept = exp(A(1));      % Diffusion is -A(2), A(1) can be used for the perfusion fraction f. 
        D = min([UB(1), max([LB(1), D])]);     % Force D to be within bounds.
    end
    if strcmpi(options.Algorithm,'levenberg-marquardt')
        LB = []; UB = [];
    end
    if numSteps == Inf % Only linear fit for ADC!
        resnorm = sum( (voxelValues(selection)' - exp(A(2)*X(:,2) + A(1)) ).^2  );
        Rsquared = 1 - resnorm/sum((voxelValues-mean(voxelValues)).^2);  % Calculate R squared: 1 - [residual sum of squares] / [total sum of squares]
        AICc = N*log(resnorm/N)+2*K+((2*K*(K+1))/(N-K-1)); % Akaike's "An Information Criterion" corrected for small samples size
        results(mask(a),:) = [D, Intercept, Rsquared, AICc];
    elseif numSteps == -Inf % Only linear, but nothing else (only ADC and S0);
        results(mask(a),1:2) = [D, Intercept];
    elseif numSteps == 3  % Use D and Intercept from above
        try [fitResult,resnorm] = lsqcurvefit(@(p, x) F([D, p(1), max([0 (p(2)-Intercept)/p(2)]), p(2)],x),SP([2,4:end]),bValues,voxelValues,LB([2,4:end]),UB([2,4:end]),options); % Do the non linear fit (function is adjusted to use the linear fitted D parameter, and the intercept value as well.)
        catch, fitResult = zeros(1,length(SP))/0; resnorm = Inf; end%#ok<CTCH> % Make it NaNs and Inf, if the curve fitting fails.
        Rsquared = 1 - resnorm/sum((voxelValues-mean(voxelValues)).^2);  % Calculate R squared: 1 - [residual sum of squares] / [total sum of squares]
        AICc = N*log(resnorm/N)+2*K+((2*K*(K+1))/(N-K-1)); % Akaike's "An Information Criterion" corrected for small samples size
        results(mask(a),:) = [D, fitResult(1), max([0 (fitResult(2)-Intercept)/fitResult(2)]), fitResult(2), Rsquared, AICc];
    elseif numSteps == 2 % Use only D from above
        try [fitResult,resnorm] = lsqcurvefit(@(p, x) F([D p],x),SP(2:end),bValues,voxelValues,LB(2:end),UB(2:end),options); % Do the non linear fit (function is adjusted to use the linear fitted D parameter.)
        catch, fitResult = zeros(1,length(SP))/0; resnorm = Inf; end%#ok<CTCH> % Make it NaNs and Inf, if the curve fitting fails.
        Rsquared = 1 - resnorm/sum((voxelValues-mean(voxelValues)).^2);  % Calculate R squared.
        AICc = N*log(resnorm/N)+2*K+((2*K*(K+1))/(N-K-1)); % Akaike's "An Information Criterion" corrected for small samples size
        results(mask(a),:) = [D, fitResult, Rsquared, AICc];
    else % Everything is fitted using NLLS.
        try [fitResult,resnorm] = lsqcurvefit(F,SP,bValues,voxelValues,LB,UB,options);
        catch, fitResult = zeros(1,length(SP))/0; resnorm = Inf; end%#ok<CTCH> % Make it NaNs and Inf, if the curve fitting fails.
        Rsquared = 1 - resnorm/sum((voxelValues-mean(voxelValues)).^2); % calculate R squared.
        AICc = N*log(resnorm/N)+2*K+((2*K*(K+1))/(N-K-1)); % Akaike's "An Information Criterion" corrected for small samples size
        results(mask(a),:) = [fitResult, Rsquared, AICc];
    end
    if verbose    
        if ~mod(a,wbp)  % Only show progress every 0.1%
            fprintf('\b\b\b\b\b\b%5.1f%%',a/total*100);
            try waitbar(a/total,wbh,sprintf('%2.1f%%',a/total*100)); end % Update the waitbar, unless it has been closed...
        end
    end
end
if verbose
    try delete(wbh); end; drawnow; fprintf('\b\b\b\b\b\b\b\b\b\bon completed.\n') % Get rid of the line 'Calculating ...%'
end

if strcmp(method,'TwoExp') % Some tricks are required to get the correct output for TwoExp
    temp = results(:,1)<results(:,2);                % For the two exponential model the fast exponential should be 'A', and the slow exponential 'B'
    results2 = results;                              % Copy the results.
    results(temp,1) = results2(temp,2);              % Switch A & B if this condition is not met.
    results(temp,2) = results2(temp,1);              % "   "
    results2(temp,3) = 1-results2(temp,3);           % Also switch the factor, i.e., F -> (1-F) & (1-F) -> F
    results(:,3) = results2(:,3).*results2(:,4);     % A = F*S0
    results(:,4) = (1-results2(:,3)).*results2(:,4); % B = (1-F)*S0
    results(:,7) = results(:,6);                     % Akaike should the last item.
    results(:,6) = results(:,5);                     % Before last is r^2
    results(:,5) = results2(:,3);                    % The factor equals A/(A+B)
    nParam = 7;                                      % One parameter was added.
end

if nargin<4 % No method, default to linear adc, only output the adc.
    results = reshape(results(:,1),matrixSize(1:end-1));
    fprintf('ADC units: 10^-9 m^2/s (µm^2/ms)\n');
elseif verbose
    results = reshape(results,[matrixSize(1:end-1), nParam]);
    dimension = sprintf('%1.0f*',[matrixSize(1:end-1), nParam]);
    fprintf('\nResults are in a %s matrix, with dimension %1.0f being:\n', dimension(1:end-1),ndims(results));
    varNames = [varNames, {'R^2', 'Akaike''s "An Information Criterion" corrected for small sample size (AICc) [A.U.]'}];
    for a = 1:nParam, fprintf(' %1.0f) %s\n',a,varNames{a}); end
end


end
