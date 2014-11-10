%% DeleteFrames
% Delete a number of frames from an Inveon file.
% Programs asks for input header file and frames to delete. 
% Frame numbering starts at 1. New data and header will be written with the
% same name with '_CopyJD' added. 
%
% J.A. Disselhorst 2009 Radboud University Nijmegen Medical Centre

fprintf('Select header file: ...\n');
[FileName,PathName,FilterIndex] = uigetfile({'*.hdr','Header files (*.hdr)'},'Select Header file');
headerFile = fullfile(PathName,FileName); dataFile = headerFile(1:end-4);
outFile = [dataFile(1:end-4) '_CopyJD' dataFile(end-3:end)];
outHeader = [outFile '.hdr'];
if FilterIndex
    clear headerInfo2
    clc;
    fprintf('%s\n',dataFile);
    answer = input('Frames to delete (first frame == 1): ');
    headerInfo = headerReader(headerFile);
    totalFrames = headerInfo.General.total_frames;
    if sum(answer>totalFrames)
        fprintf('Incorrect value. Total frames %1.0f.\n',totalFrames);
    end
    dataID = fopen(dataFile);
    outID = fopen(outFile,'w');
    fseek(dataID,0,'eof'); fileSize = ftell(dataID); fseek(dataID,0,'bof');
    frameSize = fileSize/totalFrames;
    
    for i = 1:totalFrames
        fseek(dataID,(i-1)*frameSize,'bof');
        if ~sum(answer==i)  % Frame to keep
            fwrite(outID, fread(dataID,frameSize));
        end
    end
    fclose(dataID); fclose(outID);
    fprintf('File written. (%s)\n',outFile);
    
    if totalFrames==headerInfo.General.time_frames
        fNames = fieldnames(headerInfo);
        if length(fNames) == totalFrames + 1;
            killFields = [0, (ismember([1:totalFrames],answer))];
            headerInfo2.General = headerInfo.General;
            keepers = find([0 1-killFields(2:end)]);
            for i = 1:totalFrames-length(answer)
                eval(sprintf('headerInfo2.frame_%1.0f = headerInfo.%s;',i-1,char(fNames(keepers(i)))));
            end
            headerInfo2.General.total_frames = totalFrames-length(answer);
            headerInfo2.General.time_frames = totalFrames-length(answer);
            headerWriter(headerInfo2, outHeader)
        end
    else
        fprintf('Header file not modified! (%s)\n',headerFile);
    end
end
    