function data = readBrukerParamFile(fileName)
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
    processAgain = {};
    for ii = 1:length(temp)  
        line = temp{ii,1};
        valueType = 'normal';
        if regexp(line,'^##\$*(.+)=\ \(\d\.\.\d+\)(.+)')         % It is a tag with an array as value and already a value
            error('Not defined!')
        elseif regexp(line,'^##\$*(.+)=\ \(\d\.\.\d+\)')         % It is a tag with an array as value
            results = regexp(line,'^##\$*(.+)=\ \((\d+)\.\.(\d+)\)','tokens');
            tagName = results{1}{1};
            arrayRange = [str2double(results{1}{2})+1, str2double(results{1}{3})];
            tagValue = cell(1,arrayRange(2));
            tagType = 'multi';
            processAgain{end+1} = tagName;
        elseif regexp(line,'^##\$*(.+)=\ (.+)')                  % It is a tag with a single value.
            results = regexp(line,'^##\$*(.+)=\ (.+)','tokens'); 
            tagName = results{1}{1};
            tagValue = results{1}{2};
            tagType = 'single';
        elseif regexp(line,'^##\$*(.+)=')                        % It is a tag without a value
            results = regexp(line,'^##\$*(.+)=','tokens');
            tagName = results{1}{1};
            tagValue = [];
            tagType = 'single';
        elseif regexp(line,'^\$\$(.*)')                          % It is comments or something                      
            results = regexp(line,'^\$\$(.*)','tokens');
            valueType = 'comment';
        elseif regexp(line,'^([^\$#].*)');                       % It is just a value or array
            results = regexp(line,'\s','split');
            valueType = 'values';
        else
            error('DISSELHORST:NoClue','Unknown string formatting')
        end
        switch valueType
            case 'normal'
                data.(tagName) = tagValue;
                if ~isnan(str2double(tagValue))
                    data.(tagName) = str2double(tagValue);
                end
            case 'comment'
                try data.Comments = [data.Comments, char(10), results{1}{1}];
                catch, data.Comments = results{1}{1};
                end
            case 'values'
                switch tagType
                    case 'single'
                        data.(tagName) = [data.(tagName), ' ',results{1}];
                    case 'multi'
                        N = length(results);
                        tempValue = data.(tagName);
                        tempValue(arrayRange(1):arrayRange(1)+N-1) = results;
                        data.(tagName) = tempValue;
                        arrayRange(1) = arrayRange(1)+N;
                end
        end
    end
    if ~isempty(processAgain)
        for ii = 1:length(processAgain)
            tempValue = data.(processAgain{ii});
            tempValue = str2double(tempValue);
            if ~any(isnan(tempValue))
                data.(processAgain{ii}) = tempValue;
            end
        end
    end
end