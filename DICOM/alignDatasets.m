function [Valigned,TMatrix,Vsource,Hsource,Rsource,Vtarget,Htarget,Rtarget] = alignDatasets(Vsource,Hsource,Vtarget,Htarget,interpmethod, OutputView)
    if nargin<5
        interpmethod = 'nearest';
    end
    
    [TMatrix,Vsource,Hsource,Rsource,Vtarget,Htarget,Rtarget] = ...
        MakeTransMatrix(Vsource,Hsource,Vtarget,Htarget);
       
    if nargin<6
        OutputView = Rsource;
    end

    Valigned = zeros(OutputView.ImageSize(1),OutputView.ImageSize(2),OutputView.ImageSize(3),size(Vtarget,4));
    for ii = 1:size(Vtarget,4)
        Valigned(:,:,:,ii) = imwarp(Vtarget(:,:,:,ii),Rtarget,affine3d(TMatrix'),interpmethod,'OutputView',OutputView);
    end

end