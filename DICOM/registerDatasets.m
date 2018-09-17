function [Vsource,Vregister] = registerDatasets(Vsource,Hsource,Vtarget,Htarget,interpmethod,regtype,OutputView)

    if nargin==4
        interpmethod = 'nearest';
        regtype = 'multimodal';
    elseif nargin==5
        regtype = 'multimodal';
    end
    
    [TMatrix,Vsource,Hsource,Rsource,Vtarget,Htarget,Rtarget] = ...
        MakeTransMatrix(Vsource,Hsource,Vtarget,Htarget);
    % try to fix the matrix, otherwise MATLAB thinks its not rigid:
    diffLimit = eps('single');
    TMatrix2 = TMatrix;  % Backup of the TMatrix;
    quat = rotm2quat(TMatrix(1:3,1:3));
    TMatrix(1:3,1:3) = quat2rotm(quat);
    if max(TMatrix2(:)-TMatrix(:))>diffLimit
        warning('Differences (>%1.2e) in the adjusted Rotation Matrix detected!',diffLimit);
        fprintf('Original (calculated from the DICOMS):\n'); disp(TMatrix2(1:3,1:3));
        fprintf('Adjusted:\n'); disp(TMatrix(1:3,1:3)); 
        keep = input('Keep the adjusted matrix? [Y]/N ','s');
        if strcmpi(keep,'n'), TMatrix = TMatrix2; clear TMatrix2; end
    end
    % There is something wrong with MATLAB when registering datasets: 
    % It seems the registration fails immediately when the initial
    % transformation matrix is 90 degrees.
    if any(abs(abs(quat)-0.5)<diffLimit)
        theta = 0.01; % degrees
        Rx = [1 0 0; 0 cosd(theta) -sind(theta); 0 sind(theta) cosd(theta)];
        Ry = [cosd(theta) 0 sind(theta); 0 1 0; -sind(theta) 0 cosd(theta)];
        Rz = [cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1];
        R = [Rz*Ry*Rx, [0;0;0];0 0 0 1];
        TMatrix = TMatrix*R;
        warning('Workaround for potential bug in MATLAB applied (see code)');
    end
    
    
    if nargin<7
        OutputView = Rsource;
    end
    
    [optimizer,metric] = imregconfig(regtype);
    optimizer.MaximumIterations = 2000;
    if strcmpi(regtype,'multimodal')
        metric.UseAllPixels = false;
        metric.NumberOfSpatialSamples = 1000;
    end    
    
    Vregister = zeros(OutputView.ImageSize(1),OutputView.ImageSize(2),OutputView.ImageSize(3),size(Vtarget,4));
    for ii = 1:size(Vtarget,4)
        geomtform = imregtform(Vtarget(:,:,:,ii), Rtarget, Vsource, Rsource, 'rigid', ...
            optimizer, metric,'InitialTransformation',affine3d(TMatrix'),'DisplayOptimization',false);
        Vregister(:,:,:,ii) = imwarp(Vtarget(:,:,:,ii),Rtarget,geomtform,interpmethod,'OutputView',OutputView);
    end
end