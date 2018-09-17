function [csaimage, csaseries, phoenix] = parseSiemensCSAHeader(dicomhdr)
% PARSESIEMENSCSAHEADER Parses the private CSA header in Siemens DICOMs
% usage: [csaimage, csaseries, phoenix] = parseSiemensCSAHeader(dicomhdr)
% input: the dicom header
% output: two csa headers, and the phoenix protocol
%
%
% This function is far from complete, there is a bunch of information
% between the tags (called 'unknown' in the code below). I don't know how
% to process this, and currently it is discarded.
% Two dicomtags are processed 0029x1010 and 0029x1020
%
% additional info:
% http://scion.duhs.duke.edu/vespa/project/wiki/SiemensCsaHeaderParsing
%
% JA Disselhorst 2013, Uni.Tuebingen
% version 2013.04.05

try 
    csaimage  = parsecsa(dicomhdr.(dicomlookup('0029','1010'))'); 
catch
    try
        csaimage  = parsecsa(dicomhdr.(dicomlookup('0029','1110'))');
    catch
        try
            csaimage  = parsecsa(dicomhdr.(dicomlookup('0029','1210'))');
        catch
            csaimage = [];
        end
    end
end
try 
    csaseries = parsecsa(dicomhdr.(dicomlookup('0029','1020'))'); 
catch
    try 
        csaseries = parsecsa(dicomhdr.(dicomlookup('0029','1120'))');
    catch
        try
            csaseries = parsecsa(dicomhdr.(dicomlookup('0029','1220'))');
        catch
            csaseries = []; 
        end
    end
end
try phoenix   = parsephoenix(csaseries); catch ME, phoenix = []; ME, end;
% Other possibilities:
% (0x0029, 0x1010), (0x0029, 0x1210), (0x0029, 0x1110),   *10 is image
% (0x0029, 0x1020), (0x0029, 0x1220), (0x0029, 0x1120)    *20 is series

    function csahdr = parsecsa(csa)
        char(csa(1:4));         % SV10
        csa(5:8);               % 4321
        numElems = typecast(csa(9:12),'uint32');   % the number of elements
        csa(13:16);             % end of a chunk (is 77 or 205)
        pos = 17;  % where we are.
        csahdr = struct;
        unknown = [];   % Between the tags is some unknown stuff...
        for i = 1:numElems
            name = csa(pos:pos+63); pos = pos+64;
            lengthOfName = find(name==0,1,'first')-1; unknown = [unknown char(name(lengthOfName+1:end))];
            name = char(name(1:lengthOfName));
            VM = typecast(csa(pos:pos+3),'uint32'); pos = pos+4;
            VR = char(csa(pos:pos+3)); pos = pos+4;
            syngodt = typecast(csa(pos:pos+3),'uint32'); pos = pos+4;
            numSubElems = typecast(csa(pos:pos+3),'uint32'); pos = pos+4;
            pos = pos+4;% pos+80:pos+83  = end of chunk
            try 
                csahdr.(name) = [];
            catch
                name = matlab.lang.makeValidName(strrep(name,'-','_'));
                csahdr.(name) = [];
            end
            if numSubElems
                n = 1; numeric = 1; nums = zeros(1,numSubElems)/0;
                for j = 1:numSubElems
                    lengthOfData = csa(pos:pos+15); pos = pos+16; % is 16 byte long, 1:4 = 9:12 = 13:16
                    lengthOfData = typecast(lengthOfData(1:4),'uint32');
                    if lengthOfData
                        info = csa(pos:pos+lengthOfData-2); % Minus 2, because the last character seems always to be a zero.
                        pos = pos+lengthOfData; pos = pos + ((ceil(double(lengthOfData)/4)*4)-lengthOfData); % padding.
                        str = strtrim(char(info));
                        csahdr.(name).(sprintf('elem%03.0f',n)) = str;
                        [num, status] = str2num(str); % if all elements are numeric, don't output strings in a struct.
                        if status && numeric, nums(j) = num; end
                        numeric = numeric & status;
                        n = n + 1;
                    end
                end
                if numeric && n>=2
                    csahdr.(name) = nums(1:n-1);
                elseif n==2 % there was only one element (i.e., all but one subelement were empty)
                    csahdr.(name) = csahdr.(name).elem001;
                end
            end
        end
    end

    function phoenix = parsephoenix(csahdr)
        MPP = csahdr.MrPhoenixProtocol;
        
        startpoint = strfind(MPP,'### ASCCONV BEGIN ###')+22;
        endpoint = strfind(MPP,'### ASCCONV END ###')-2;
        if ~isempty(startpoint) && ~isempty(endpoint)
            AscConv = MPP(startpoint:endpoint);
        end
        AscConv = regexpi(AscConv,char(10),'split');
        
        phoenix = struct;
        for ii = 1:length(AscConv)
            line = AscConv{ii};
            line = strtrim(regexpi(line,'=','split'));
            [Name,Value] = line{:};
            Value = strrep(Value,'"','');
            bhb = strfind(Name,'[');
            bhe = strfind(Name,']');
            if ~isempty(bhb) && length(bhb)==length(bhe)
                for jj = 1:length(bhb)
                    num = str2double(Name(bhb(jj)+1:bhe(jj)-1))+1;
                    Name = [Name(1:bhb(jj)), num2str(num), Name(bhe(jj):end)];
                    bhb = strfind(Name,'[');
                    bhe = strfind(Name,']');
                end
            end
            try
                if isnan(str2double(Value))  % It's a string
                    eval( ['phoenix.' strrep(strrep(Name,'[','{'),']',',1}') '=''' Value ''';'] )
                else % It's a number
                    eval( ['phoenix.' strrep(strrep(Name,'[','{'),']',',1}') '=' Value ';'] )
                end
            end
        end
        
        
    end
end