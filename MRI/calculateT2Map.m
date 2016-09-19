function [T2Map, Bs, Ds] = calculateT2Map(imageMatrix,headers,varargin)
    %% Calculate an T2 or T2* Map from a series of images
    % calculateT2Map(imageMatrix,headers,optionalParameter,parameterSetting)
    % imageMatrix: voxel values [x,y,z,EchoTime]
    % headers:     The headers for the dataset (cells)
    %              As an alternative, the TE's for each image can be given.
    % optional parameters:
    % 'smooth' can be 1 (on) or 0 (off) performs boxcar smoothing on
    %           imageMatrix. Default is off
    % 'robust' based on the cook's distance, outliers can be identified or
    %           removed. parameterSetting can be [N], this will remove at
    %           maximum N outliers per voxel in t-dimension, or [N T],
    %           which will remove N outliers above cook threshold T.
    %           Default is no outlier identification nor filtering. 
    % 
    % Output: [T2Map, Intercept-Map, Cook-Matrix]
    %
    % JA Disselhorst 2014.
    % Werner Siemens Imaging Center, Uni. Tuebingen
    % Version 2014.05.09
    %
    % Disclaimer:
    % THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
    % KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

    if nargin<2
        help 
    end
    if iscell(headers) % It will probably be a cell array of dicom headers.
        N = size(headers,2);
        TE = zeros(N,1);
        for ii = 1:N
            TE(ii) = headers{1,ii}.EchoTime;
        end
        if strcmpi(headers{1}.ScanningSequence,'SE')
            warning('In a SE_MC sequence (default for T2 Mapping at the WSIC), please remove the first echo! It will NOT be done by this program! [The first echo is a pure primary echo, the subsequent echos are a combination of primary and stimulated echos]');
        end
    else % Probably a list of TE's
        TE = headers(:);
    end
    if ndims(imageMatrix)~=4
        error('Matrix should be X*Y*Z*t [4D]');
    end
    [x,y,z,t] = size(imageMatrix);
    fprintf('...')
    % Defaults:
    smooth = 0;
    robust = 0; if nargout==3, robust = 1; numOutlier2Remove=0; end;
    if nargin>2  % additional options are given.
        for argNum = 1:2:nargin-2
            switch lower(char(varargin(argNum)))
                case 'smooth'
                    smooth = cell2mat(varargin(argNum+1));
                case 'robust'
                    robust = cell2mat(varargin(argNum+1));
                    numOutlier2Remove = robust(1);
                    if length(robust)==1
                        robust(2) = 4/t;
                        if numOutlier2Remove>0, fprintf('\b\b\bUsing default cutoff value of %1.4f. ...',4/t); end
                    end
                    outlierCutoff = robust(2);
                    robust = 1;
                    if numOutlier2Remove > t
                        error('The number of outliers that can be removed cannot be larger then number of TE''s (%1.0f)!',t)
                    end
            end
        end
    end

    if smooth
        fprintf('\b\b\bSmoothing data. ...')
        if sum(isnan(imageMatrix(:)))
            warning('NaN''s detected!'); fprintf('   ')
        end
        for i = 1:t
            imageMatrix(:,:,:,i) = smooth3(imageMatrix(:,:,:,i),'box',5);
        end
    end

    logMatrix = log(imageMatrix); 
    logMatrix = reshape(logMatrix,[x*y*z,t]);
    logMatrix(isinf(logMatrix)) = 0;
    
    fprintf('\b\b\bCalculating map....');
    % y = a*x + b
    As = zeros(x*y*z,1); % preallocation for the fitted a
    Bs = As;             % preallocation for the fitted b
    Ds = zeros(x*y*z,t); % preallocation for cook distance
    
    X = [ones(t,1) TE];
 
    N = (x*y*z);
    for i = 1:N
        Y = logMatrix(i,:)';
        A = X\Y;  % Do the normal fit.
        As(i) = A(2);
        Bs(i) = A(1);
        
        if robust
            Ye = X*A; %expected response value
            e = Y-Ye; %residual term
            SSRes = e'*e;  %residual sum of squares
            v2 = t-2; %residual degrees of freedom
            MSRes = SSRes/v2; %residual mean square
            Rse = sqrt(MSRes); %standard error term
            H = X/(X'*X)*X'; %hat matrix
            hii = diag(H); %leverage of the i-th observation
            ri = e./(Rse*sqrt(1-hii)); %Studentized residual
            Ds(i,:) = diag((ri.^2/2)*(hii./(1-hii))'); %Cook's distance
        end
    end
    
    if robust && (numOutlier2Remove>0)  % remove outliers
        fprintf('\b\b\b\nRemoving maximum %1.0f outliers per voxel....',numOutlier2Remove)
        [Values, IX] = sort(Ds,2);
        IX(Values<outlierCutoff) = NaN;
        removePointsMatrix = IX(:, (end-numOutlier2Remove+1):end);
        Ds = zeros(size(Ds));
        for i = 1:N
            removePoint = removePointsMatrix(i,:);
            Y2 = logMatrix(i,:)';
            X2 = X;
            Y2(removePoint(~isnan(removePoint))) = [];
            X2(removePoint(~isnan(removePoint)),:) = [];
            A = X2\Y2;  % Do the normal fit.
            As(i) = A(2);
            Bs(i) = A(1);
            Ds(i,removePoint(~isnan(removePoint))) = 1;
        end
    end

    As = reshape(As,[x,y,z]);
    Bs = reshape(Bs,[x,y,z]);
    Ds = reshape(Ds,[x,y,z,t]);
    T2Map = -1./As;
    T2Map(T2Map<0) = 0;    
    fprintf('\b\b\b\b: Done.\n');
end