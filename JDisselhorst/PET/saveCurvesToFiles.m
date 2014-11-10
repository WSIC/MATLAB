%% J.A. Disselhorst, 2010
% Radboud University Nijmegen Medical Centre
% Nijmegen, The Netherlands
% j.disselhorst@nucmed.umcn.nl

function saveCurvesToFiles(fileName,TTAC,APTAC,framing,frameMidTimes,td)
    if nargin<6
        td = 0;
    end
    dlmwrite([fileName '_blood.csv'],[frameMidTimes(:)-td,APTAC(:)],'newline','pc');
    dlmwrite([fileName '_tissue.csv'],[frameMidTimes(:),TTAC(:)],'newline','pc');
    dlmwrite([fileName '_durations.csv'],framing(:),'newline','pc');
end