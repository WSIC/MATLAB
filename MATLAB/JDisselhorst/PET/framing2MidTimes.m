%% framing2MidTimes: Convert framing to mid times from a dynamic pet 
%
% J.A. Disselhorst 2011. Radboud University Nijmegen Medical Centre
% Input: Array of frame lengths,
% Output: Array of frameMidTimes

function frameMidTimes = framing2MidTimes(framing)
    frameMidTimes = framing/2+cumsum([0 framing(1:end-1)]);  % Then at least the first element is correct.
end