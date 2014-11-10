%% midTimes2framing: Convert frame mid times in a dynamic PET 
% to the framing schedule that has been used.
% J.A. Disselhorst 2011. Radboud University Nijmegen Medical Centre
% Input: Array of frameMidTimes,
% Output: Array of frame lengths

function framing = midTimes2Framing(frameMidTimes)
    clc
    framing = frameMidTimes*2;  % Then at least the first element is correct.
    for i = 2:length(framing);  % calculate subsequent frame lengths
        framing(i) = (frameMidTimes(i)-sum(framing(1:i-1)))*2;
    end
    if any(framing<=0)  % If any of the frame lengths <0, the time sequence was invalid.
        fprintf('Invalid time sequence!\n')
        return
    end

    % Some output text: ---------
    if framing(1) < 1  % framing probably in minutes
        FRAMING = round(framing*60);
    else               % probably already in seconds
        FRAMING = round(framing);
    end
        cur = FRAMING(1);
    n = 1;
    fprintf('Framing schedule of %1.0f sec\n',sum(FRAMING))
    for i = 2:length(framing);
        if FRAMING(i)==cur
            n = n + 1;
        else
            fprintf('%1.0f x %1.0f, ',n,cur)
            cur = FRAMING(i);
            n = 1;
        end
    end
    fprintf('%1.0f x %1.0f sec\n',n,cur);
    % -----------------------------
end