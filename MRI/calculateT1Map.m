function [T1, M0] = calculateT1Map(imageMatrix,headers,varargin)
    %% Calculate an T1 Map from a series of images with different FA/TR/TI
    % CALCULATET1MAP(imageMatrix,headers,optionalParameter,parameterSetting)
    % Calculation of T1 is based on different flip angles or different TRs,
    % or different TIs. TE should be constant. Also important: TE<<T2*
    %
    % Input:
    % o imageMatrix: voxel values [x,y,z,FA or TR or TI variation]
    % o headers:     The headers for the dataset (cells)
    % 
    % optional parameters:
    % o 'smooth' can be 1 (on) or 0 (off) performs boxcar smoothing on
    %            imageMatrix. Default is off. Only works for 3D, not 2D.
    %
    % Output: 
    % o T1:         Map the T1 relaxation time.
    % o M0:         Map of M-zero
    %
    % References:
    % o Wang et al. Optimizing the Precision in T1 Relaxation
    %   Estimation Using Limited Flip Angles. Mang Reson Med. 1987
    % o http://www.paul-tofts-phd.org.uk/talks/ismrm2009_rt.pdf
    %
    % Example:
    % [img,hdr] = loadDicom;
    % [T1,M0] = calculateT1Map(img,hdr);
    %
    % JA Disselhorst 2013-2015.
    % Werner Siemens Imaging Center, Uni. Tuebingen
    % Version 2015.11.05
    %
    % Disclaimer:
    % THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
    % KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
    warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');
    
    if iscell(headers) % It will probably be a cell array of dicom headers.
        N = size(headers,2);
        FA = zeros(N,1); TR = FA; TI = FA;
        for ii = 1:N
            FA(ii) = headers{1,ii}.FlipAngle;
            TR(ii) = headers{1,ii}.RepetitionTime;
            try TI(ii) = headers{1,ii}.InversionTime; catch, TI(ii)=Inf; end
        end
        NFA = length(unique(FA));
        NTR = length(unique(TR));
        NTI = length(unique(TI));
        if sum([NFA>1, NTR>1, NTI>1])>1
            error('Variations detected in more than one of the following parameters FA, TR, TI! (Only one allowed)')
        elseif NFA>1
            TR = TR(1); Type = 'FA';
        elseif NTR>1
            Type = 'TR';
        elseif NTI>1
            TR = TR(1); Type = 'TI';
        else
            error('No variation in any of the following parameters FA, TR, TI! (One required!)');
        end
    else 
        error('Please provide the headers as cell array');
    end
    if ndims(imageMatrix)~=4
        error('Matrix should be X*Y*Z*t [4D]');
    end
    [x,y,z,t] = size(imageMatrix);
    
    fprintf('...')
    % Defaults:
    smooth = 0;
    if nargin>2  % additional options are given.
        for argNum = 1:2:nargin-2
            switch lower(char(varargin(argNum)))
                case 'smooth'
                    smooth = cell2mat(varargin(argNum+1));
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
    
    % Test for clipping / saturation ------------------------------------------
    numClip = sum(imageMatrix(:) >= 4095);
    if numClip
        warning('CalculateDiffusion:Clipping','A value of 4095 has been found %1.0f times.',numClip);
    end
    
    fprintf('\b\b\bCalculating map....');
    switch Type
        case 'FA'
            FAMatrix = repmat(reshape(FA,1,t),[x*y*z,1]);
            XMatrix = reshape(imageMatrix,[x*y*z,t])./tand(FAMatrix);
            YMatrix = reshape(imageMatrix,[x*y*z,t])./sind(FAMatrix);
            % y = a*x + b
            As = zeros(x*y*z,1)./0; % preallocation for the fitted a
            Bs = As;                % preallocation for the fitted b
            ONE = ones(t,1);
            N = (x*y*z);
            for i = 1:N
                yy = YMatrix(i,:)';
                xx = [ONE,XMatrix(i,:)'];
                if all(xx>0)
                    A = xx\yy;  % Do the normal fit.
                    As(i) = A(1);
                    Bs(i) = A(2);
                end
            end

            As = reshape(As,[x,y,z]);
            Bs = reshape(Bs,[x,y,z]);
            T1 = real(-TR/log(Bs));
            T1(T1<0) = 0; T1(T1>10000) = 10000;
            M0 = As./(1-exp(-TR./T1));
        case 'TR' % This has to be done with a non-linear fit...:
            threshold = 50;
            warning('Treshold of 50 was used. See code, line 98');
            F = @(p,x) (1-exp(-x/p(1))) * p(2);    % Fit-function
            LB = [0, 0];                           % Lower bound for all parameters
            UB = [10000, 4096];                    % Upper bound
            SP = [1500, 800];                      % Startpoint for fit
            options             = optimset('lsqcurvefit');
            options.Display     = 'off';
            options.FunValCheck = 'on';
            options.UseParallel = 'Always';
            options.TolFun      = 1E-8;
            options.TolX        = 1E-8;
            options.MaxFunEvals = 5000;
            options.MaxIter     = 5000;
            options.Algorithm   = 'trust-region-reflective';
            T1 = zeros(x*y*z,1);
            M0 = T1;
            N = (x*y*z);
            imageMatrix = reshape(imageMatrix,[x*y*z,t]);
            mask = mean(imageMatrix,2)>threshold;
            wbh = waitbar(0,'Please wait...');
            list = find(mask);
            for ii = 1:length(list)
                i = list(ii);
                voxelValue = imageMatrix(i,:)';
                fitResult = lsqcurvefit(F,SP,TR,voxelValue,LB,UB,options);
                T1(i) = fitResult(1);
                M0(i) = fitResult(2);
                try waitbar(i/N,wbh); end
            end
            T1 = reshape(T1,[x,y,z]);
            M0 = reshape(M0,[x,y,z]);
            try close(wbh); end
        case 'TI'
            threshold = 50;
            warning('Treshold of 50 was used. See code, line 133');
            F = @(p,x) abs((1-2*exp(-x/p(1)) - exp(-TR/p(1)))) * p(2);    % Fit-function
            LB = [0, 0];                           % Lower bound for all parameters
            UB = [10000, 4096];                    % Upper bound
            SP = [1000, 1000];                     % Startpoint for fit
            options             = optimset('lsqcurvefit');
            options.Display     = 'off';
            options.FunValCheck = 'on';
            options.UseParallel = 'Always';
            options.TolFun      = 1E-9;
            options.TolX        = 1E-9;
            options.MaxFunEvals = 5000;
            options.MaxIter     = 5000;
            options.Algorithm   = 'trust-region-reflective';
            T1 = zeros(x*y*z,1);
            M0 = T1;
            N = (x*y*z);
            imageMatrix = reshape(imageMatrix,[x*y*z,t]);
            mask = mean(imageMatrix,2)>threshold;
            wbh = waitbar(0,'Please wait...');
            list = find(mask);
            for ii = 1:length(list)
                i = list(ii);
                voxelValue = imageMatrix(i,:)';
                fitResult = lsqcurvefit(F,SP,TI,voxelValue,LB,UB,options);
                T1(i) = fitResult(1);
                M0(i) = fitResult(2);
                try waitbar(i/N,wbh); end
            end
            T1 = reshape(T1,[x,y,z]);
            M0 = reshape(M0,[x,y,z]);
            try close(wbh); end
    end
    fprintf('\b\b\b\b: Done.\n');
end