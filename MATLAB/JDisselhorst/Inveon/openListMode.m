%% Open List Mode File
% result = openListMode(infile, output);
% infile: full path to *.lst
% output: [1/0]. 1 will produce a 25600x25600 matrix with coincidence
%         events. 0 will produce nothing, but show a lot [default].
%           2 will only show singles
%           3 will only show coincidences.
% result: the output-matrix, if output = 1;
%
% This function is far from complete, probably erroneous. 
%
% J.A. Disselhorst '09
% University of Twente, Enschede
% Radboud University Medical Center, Nijmegen

function result = openListMode(infile, output)
global result

h = waitbar(0,'Progress');
if nargin==0
    error('no input file');
elseif nargin<2
    output = 0;
end

fiID = fopen(infile,'r');
fseek(fiID,0,'eof'); totalsize=ftell(fiID)/6; fseek(fiID,0,'bof');

if output == 1
    
    fprintf('Creating lookup table ... ....');
    Lookup = zeros(320,320,2);
    for A = 1:320         % Crystal 1
        for B = 1:320     % Crystal 2
            a = A-1; b = B-1;
            c = (160-b+a)/2;
            
            LOR = a-c+160;
            LOR = rem(LOR,160)+1;
            Lookup(A,B,1) = LOR;
            
            LOR2 = LOR+160;
            dif(1,1) = LOR-a;
            dif(2,1) = LOR-b;
            dif(3,1) = a-LOR2;
            dif(4,1) = b-LOR2;
            [temp,IX] = sort(abs(dif));
            bin = dif(IX(1),1);
            Lookup(A,B,2) = -2*bin+67;
        end
        fprintf('\b\b\b\b%3.0f%%',A/3.2);
    end
    temp = Lookup(:,:,2);
    temp(temp>128) = 129;    %because temp(temp>128) = NaN;
    Lookup(:,:,2) = temp;
    Lookup(Lookup<1) = 129;  %because Lookup(Lookup<1) = NaN;
    Lookup = round(Lookup);
    fprintf('\b\b\b\b\b\b\b\b\b. done.\n');
    %------------------------------------------------
    
    %result = zeros(25600,25600);
    result = zeros(161,129,159); 
    count = 0;
    for i = 1:totalsize
        waitbar(i/totalsize,h,sprintf('%3.5f%%: %1.0f',i/totalsize*100,count));
        numbers = fread(fiID, 1, 'ubit48');
        numbers = dec2bin(numbers,48);
        gray = numbers(1:4);
        type = numbers(5:8);
        switch bin2dec(type)
            case {0,1,2,3,4,5,6,7}
               % PromptDelay = numbers(6);
               % TimeDifference = bin2dec(numbers(7:10));
                CL2 = bin2dec(numbers(32:48));    % 0:25699
                CL1 = bin2dec(numbers(13:29));
                
                ring1 = floor(CL1/320);            % 0:79
                posring1 = mod(CL1,320);           % 0:319
                ring2 = floor(CL2/320);            % 0:79
                posring2 = mod(CL2,320);           % 0:319
                
                if ring1 == ring2
                    result(Lookup(posring1+1,posring2+1,1), Lookup(posring1+1,posring2+1,2), (ring1+1)*2-1) = ...
                        result(Lookup(posring1+1,posring2+1,1), Lookup(posring1+1,posring2+1,2), (ring1+1)*2-1)+1;
                    count = count + 1;
                elseif abs(diff([ring1 ring2])) < 20  %% Span...
                    result(Lookup(posring1+1,posring2+1,1), Lookup(posring1+1,posring2+1,2), floor(mean([ring1+1,ring2+1]))*2 ) = ...
                        result(Lookup(posring1+1,posring2+1,1), Lookup(posring1+1,posring2+1,2), floor(mean([ring1+1,ring2+1]))*2 )+1;
                    count = count + 1;
                end
        end
    end
    
elseif output == 0     % SHOW everything.
    counterStrings = {'Time Mark','EPM CFD Singles Count','EPM Stored Singles Count', ...
        'EPM Valid Singles Count','EPM RIO Singles Count','EPM Delays Count', ...
        'EPM RIO Delays Count','EPM Prompts Count','EPM RIO Prompts Count', ...
        'ERS RIO Prompts Count','ERS RIO Delays Count','ERS RIO Singles Count'};
    for i = 1:totalsize
        waitbar(i/totalsize,h);
        numbers = fread(fiID, 1, 'ubit48');
        [returnType, returnData] = processPack(numbers);
        fprintf(returnData);
    end

elseif output == 2   % SHOW singles
    counterStrings = {'Time Mark','EPM CFD Singles Count','EPM Stored Singles Count', ...
        'EPM Valid Singles Count','EPM RIO Singles Count','EPM Delays Count', ...
        'EPM RIO Delays Count','EPM Prompts Count','EPM RIO Prompts Count', ...
        'ERS RIO Prompts Count','ERS RIO Delays Count','ERS RIO Singles Count'};
    for i = 1:totalsize
        waitbar(i/totalsize,h);
        numbers = fread(fiID, 1, 'ubit48');
        [returnType, returnData] = processPack(numbers);
        if returnType == 8
            fprintf(returnData);
        end
    end
elseif output == 3   % SHOW coincidences
    counterStrings = {'Time Mark','EPM CFD Singles Count','EPM Stored Singles Count', ...
        'EPM Valid Singles Count','EPM RIO Singles Count','EPM Delays Count', ...
        'EPM RIO Delays Count','EPM Prompts Count','EPM RIO Prompts Count', ...
        'ERS RIO Prompts Count','ERS RIO Delays Count','ERS RIO Singles Count'};
    for i = 1:totalsize
        waitbar(i/totalsize,h);
        numbers = fread(fiID, 1, 'ubit48');
        [returnType, returnData] = processPack(numbers);
        if returnType < 8
            fprintf(returnData);
        end
    end
end

fclose(fiID);



%%

function [returnType, returnData] = processPack(packageData)
        numbers = dec2bin(packageData,48);
        gray = numbers(1:4);
        type = numbers(5:8);
        returnType = bin2dec(type);
        switch returnType
            case 8
                EE2 = bin2dec(numbers(30:31));
                EE1 = bin2dec(numbers(11:12));
                CL2 = bin2dec(numbers(32:48));
                CL1 = bin2dec(numbers(13:29));
                returnData = sprintf('%s. Single Event. Energy: %1.0f, Crystal: %1.0f | Energy: %1.0f, Crystal: %1.0f\n', ...
                    gray, EE1, CL1, EE2, CL2);
            case 9
                returnData = sprintf('%s. Undefined\n',gray);
            case 10
                CountType = bin2dec(numbers(9:12));
                if CountType == 0
                    TimeMark = bin2dec(numbers(17:48));
                    returnData = sprintf('%s. Counter Tag. Time Mark: %1.0f\n',gray, TimeMark);
                elseif CountType >= 1 && CountType <= 8
                    EPMSlot = bin2dec(numbers(13:20));
                    EPMDetector = bin2dec(numbers(21:22));
                    Count = bin2dec(numbers(25:48));
                    returnData = sprintf('%s. Counter Tag. Block Single Counter: Subtype: %s, Slot: %1.0f, Detector: %1.0f, Count: %1.0f\n',gray, char(counterStrings(CountType+1)), EPMSlot, EPMDetector, Count);
                elseif CountType >= 12 && CountType <= 14
                    Channel = bin2dec(numbers(13:16));
                    Count = bin2dec(numbers(25:48));
                    returnData = sprintf('%s. Counter Tag. Channel Prompt/Delay/Single Count: Subtype: %X, Channel: %1.0f, Count: %1.0f\n',gray, CountType, Channel, Count);
                else
                    returnData = sprintf('%s. Counter Tag. Unknown\n',gray);
                end
            case 11
                returnData = sprintf('%s. Undefined\n',gray);
            case 12
                SubType = bin2dec(numbers(9:12));
                Forward = numbers(13);
                switch SubType
                    case 0  %Motion Axis Event
                        Axis = bin2dec(numbers(14:16));
                        AxisEvent = bin2dec(numbers(17:20));
                        Information = bin2dec(numbers(25:48));
                        switch AxisEvent
                            case 0
                                returnData = sprintf('%s. IOS Board Tag. Forward: %s. Motion Axis Event. Axis: %1.0f. Periodic Axis Position, current position: %1.0f\n',gray, Forward, Axis, Information);
                            case 1
                                returnData = sprintf('%s. IOS Board Tag. Forward: %s. Motion Axis Event. Axis: %1.0f. Motion Destination, End Position or Number of Revs: %1.0f\n',gray, Forward, Axis, Information);
                            case 2
                                returnData = sprintf('%s. IOS Board Tag. Forward: %s. Motion Axis Event. Axis: %1.0f. Start Motion, Number of Passes: %1.0f\n',gray, Forward, Axis, Information);
                            otherwise
                                returnData = sprintf('%s. IOS Board Tag. Forward: %s. Unknown Motion Axis Event\n',gray, Forward);
                        end
                    case 1  %Trigger Event
                        Trigger = bin2dec(numbers(44:48));
                        Edge = numbers(43);
                        State = numbers(42);
                        Gated = numbers(41);
                        Average = numbers(17:40);
                        returnData = sprintf('%s. IOS Board Tag. Forward: %s. Trigger Event. Trigger: %1.0f, Edge: %1.0f, State: %1.0f, Gated: %1.0f, Average: %1.0f\n',gray, Forward, Trigger, Edge, State, Gated, Average);
                    case 2  %Index Event
                        Edge = numbers(17);
                        PointSource = bin2dec(numbers(14:16));
                        Position = bin2dec(numbers(25:48));
                        returnData = sprintf('%s. IOS Board Tag. Forward: %s. Index Event. Edge: %1.0f, PointSource: %1.0f, Position: %1.0f\n',gray, Forward,Edge, PointSource, Position);
                    case 3  %Relay Event
                        State = bin2dec(numbers(43:48));
                        Relay = bin2dec(numbers(35:40));
                        returnData = sprintf('%s. IOS Board Tag. Forward: %s. Relay Event. State: %1.0f, Relay: %1.0f\n',gray, Forward,State,Relay);
                    case 4  %Temp Sensor Tag
                        FanGroup = bin2dec(numbers(14:16));
                        T3 = bin2dec(numbers(17:24));
                        T2 = bin2dec(numbers(25:32));
                        T1 = bin2dec(numbers(33:40));
                        T0 = bin2dec(numbers(41:48));
                        returnData = sprintf('%s. IOS Board Tag. Forward: %s. Temp Sensor. FanGroup: %1.0f, T0: %1.0f, T1: %1.0f, T2: %1.0f, T3: %1.0f\n',gray, Forward, FanGroup, T0, T1, T2, T3);
                    case 5  %Fan Speed Tag
                        FanGroup = bin2dec(numbers(14:16));
                        F3 = bin2dec(numbers(17:24));
                        F2 = bin2dec(numbers(25:32));
                        F1 = bin2dec(numbers(33:40));
                        F0 = bin2dec(numbers(41:48));
                        returnData = sprintf('%s. IOS Board Tag. Forward: %s. Fan Speed. FanGroup: %1.0f, F0: %1.0f, F1: %1.0f, F2: %1.0f, F3: %1.0f\n',gray, Forward, FanGroup, F0, F1, F2, F3);
                    otherwise  %Parity Error
                        returnData = sprintf('%s. IOS Board Tag. Forward: %s. Parity Error!\n',gray, Forward);
                end
            case 13
                returnData = sprintf('%s. Undefined\n',gray);
            case 14
                returnData = sprintf('%s. Extended Packet\n',gray);
            case 15
                returnData = sprintf('%s. Microcontroller Tag\n',gray);
            otherwise
                PromptDelay = numbers(6);
                TimeDifference = bin2dec(numbers(7:10));
                EE2 = bin2dec(numbers(30:31));
                EE1 = bin2dec(numbers(11:12));
                CL2 = bin2dec(numbers(32:48));
                CL1 = bin2dec(numbers(13:29));
                returnData = sprintf('%s. Coincidence Event. Energy: %1.0f, Crystal: %1.0f | Energy: %1.0f, Crystal: %1.0f | TimeDiff: %1.0f, Prompt/Delay: %s\n',gray,EE1, CL1, EE2, CL2, TimeDifference, PromptDelay);
        end
   end
end