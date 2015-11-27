function data = readBrukerParamFile2(fileName)
% READBRUKERPARAMFILE reads the parameter files from Bruker NMR experiments
%
% Usage:    data = readBrukerParamFile(fileName)
%
% Input:
%         o fileName: the filename / fullpath+filename of the param file
%                     for example: 'acqu', 'procs'
%
% Output: 
%         o data:     structure containing the information from the file
% 
% J.A. DISSELHORST
% Werner Siemens Imaging Center
% v20140728
%
% Disclaimer:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
% EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK 
warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

    fileID = fopen(fileName);
    temp = textscan(fileID,'%s','WhiteSpace','\n');
    fclose(fileID);
    temp = temp{:};
    data = struct;
    for ii = 1:length(temp)  
        line = temp{ii,1};
        if regexp(line,'^##[^=]') % Some tag.
            results = regexp(line,'=','split');
            tagType = 'Normal';
        elseif regexp(line,'^\$\$')  % some comment
            results = line;
            tagType = 'Comment';
        else
            tagType = 'Skip';
        end
        
       switch tagType
            case 'Normal'
                currentTag = results{1};
                if length(results)==1
                    currentValue = '';
                else
                    currentValue = results{2};
                    abc = 1;
                    if ii<length(temp)
                        nextline = temp{ii+abc,1};
                        while isempty(regexp(nextline,'(^##[^=])|(^\$\$)'))
                            currentValue = [currentValue, nextline];
                            if ii+abc<length(temp)
                                abc = abc+1;
                                nextline = temp{ii+abc,1};
                            else
                                break
                            end
                        end
                    end
                end
                currentValue = processValue(currentValue);
                data.(currentTag(regexp(currentTag,'[^#\$]','once'):end)) = currentValue;
            case 'Comment'
%                 try data.Comments = [data.Comments, char(10), results{1}{1}];
%                 catch, data.Comments = results{1}{1};
%                 end

        end
    end
end


function currentValue = processValue(currentValue)
    if regexp(currentValue,'[^\d\s,\.eE-]+') % contains non-numeric values;
        if regexp(currentValue,'(?<=^\s*\()[\d\s,]+(?=\).+?)') % the string starts with an arraysize definition followed by at least one char.
            arraySize = regexp(currentValue,'(?<=^\s*\()[\d\s,]+(?=\).+?)','match');
            if regexp(currentValue,'(?<=^\([\d\s,]+\)).*[^\d\s,\.eE-]+.*') 
                % This is a bunch of strings, not handled yet.
                try
                    temp = regexp(currentValue,'(?<=^\([\d\s,]+\)).*[^\d\s,\.eE]+.*','match');
                    currentValue = strtrim(char(temp));
                    currentValue = regexp(currentValue,'(?<=<)[^<>]+(?=>)','match');
                end
            else % what follows are only numbers whitespace, dots and commas
                try
                    temp = regexp(currentValue,'(?<=^\([\d\s,]+\))[\d\s,\.eE-]+','match');
                    temp = str2num(char(temp));
                    currentValue = reshape(temp,[str2num(char(arraySize)),1]);
                end
            end
        end
    else %only numbers
        try
            currentValue = str2num(currentValue);
        end
    end
end