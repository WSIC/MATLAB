function [framing,startTimes,midTimes] = header2framing(hdr)
%% HEADER2FRAMING convert an Inveon header to a framing schedule
% [framing,startTimes,midTimes] = header2framing(hdr)
%
% JA Disselhorst. 2014.02.27. 
% Werner Siemens Imaging Center
% University of Tuebingen, Germany

    T = hdr.General.total_frames;
    framing = zeros(1,T);
    startTimes = zeros(1,T);
    for ii = 1:T
        framename = sprintf('frame_%1.0f', ii-1);
        framing(ii)    = hdr.(framename).frame_duration;
        startTimes(ii) = hdr.(framename).frame_start;
    end
    midTimes = framing2MidTimes(framing);
end