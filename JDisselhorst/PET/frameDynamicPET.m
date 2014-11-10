function [bloodMeasured, tissueMeasured, frameMidTimes, frameStartTimes, frameEndTimes] = frameDynamicPET(TTAC, APTAC, framing, res)
    frameMidTimes   = cumsum(framing)-(framing./2);
    frameStartTimes = cumsum(framing)-framing;
    frameEndTimes   = cumsum(framing);
    frameStartPlace = round((cumsum(framing)-framing)./(res) +1);
    frameEndPlace   = round(cumsum(framing)./(res) +1);
    tissueMeasured  = framing;
    bloodMeasured   = framing;
    
    warning('There will be a small error in the calculation. To be solved. Probably related to ongoing decay between two sample points')

    for i = 1:length(framing)
        %tissueMeasured(i) = mean(TTAC(frameStartPlace(i):frameEndPlace(i)));
        %tissueMeasured(i) = (sum(TTAC(frameStartPlace(i):frameEndPlace(i))*res))./framing(i);
        tissueMeasured(i) =  trapz(TTAC(frameStartPlace(i):frameEndPlace(i)))*res/(framing(i));
        
        %bloodMeasured(i)  = mean(APTAC(frameStartPlace(i):frameEndPlace(i)));
        %bloodMeasured(i) = (sum(APTAC(frameStartPlace(i):frameEndPlace(i))*res))./framing(i);
        bloodMeasured(i) = trapz(APTAC(frameStartPlace(i):frameEndPlace(i)))*res/(framing(i));
    end

end