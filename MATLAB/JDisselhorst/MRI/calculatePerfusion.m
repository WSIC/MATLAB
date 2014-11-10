function [perfusionMap,perfusionMap_filtered,perfusionMap_prefiltered] = calculatePerfusion(ASLmeas,ASLm0,ignore)
% CALCULATEPERFUSION Is used for ASL scans. It is not very optimized!
% Temporary function, do not use this for any real research.
% USAGE:
% [perfusionMap,perfusionMap_filtered,perfusionMap_prefiltered] ...
%              = calculatePerfusion(ASLmeas,ASLm0,ignore)
%
% INPUT:
% o ASLmeas: the measurement images 
%            [Tagged, non-tagged, tagged, non-tagged, ..., etc.]
%            It is probably 60 of them.
% o ASLm0:   the m0 images
% o ignore:  the images that should be ignored, e.g., [1,2,5,7,40]
%
% OUTPUT:
% o perfusionMap: The perfusion map in mL/100g/min
% o perfusionMap_filtered
% o perfusionMap_prefiltered
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

    if nargin<3
        ignore = [];
    end
    lambda = 1.0;     % lambda is the blood-tissue water partition coefficient, which is assumed to have a constant value of 80 ml/100 g in humans
    T1 = 2.0;         % maybe a T1-map should be acquired
    TI = 1.8;         % A dicom tag exists (InversionTime / 0018x0082), but it not present in these files.... 
    time_scale = 60;  % Per minute
    spat_scale = 100; % Per 100 grams. ?  -> results mL/100g/min
    h = fspecial('gaussian', [5 5], 0.5); % for the filter

    imageMatrix_A = ASLmeas(:,:,:,setdiff(1:2:end,ignore));
    imageMatrix_B = ASLmeas(:,:,:,setdiff(2:2:end,ignore));
    imageMatrix_m0 = mean(ASLm0,4);
    
    difference = mean(imageMatrix_A,4)-mean(imageMatrix_B,4);
    perfusionMap = lambda * time_scale * spat_scale * exp(TI/T1) * difference./(2*TI*imageMatrix_m0);
    
    try
        perfusionMap_filtered = imfilter(perfusionMap, h, 'replicate');
        imageMatrix_m0_filtered = imfilter(imageMatrix_m0, h,'replicate');
        differenceFiltered = mean(smooth3(squeeze(imageMatrix_A),'gaussian',[5 5 5], 0.5),3) - mean(smooth3(squeeze(imageMatrix_B),'gaussian',[5 5 5], 0.5),3);
        perfusionMap_prefiltered = lambda * time_scale * spat_scale * exp(TI/T1) * differenceFiltered./(2*TI*imageMatrix_m0_filtered);
    catch
        perfusionMap_filtered = [];
        perfusionMap_prefiltered = [];
    end
    
    perfusionMap(perfusionMap<0) = 0;
    
end