%% Do a 'manual' dynamic scan.
% 1. Cut the listmode, use CutLMinPieces.m
% 2. Use AutoIt script RECON.au3 to reconstruct all separate listmodes.
% 3. Use this script to put them together as one file.

%% Some variables
N = 30; % number of frames
folder = 'U:\GUIPETReconExe\JonathanD\20140714'; % where is the data? 
HL = 6586.26;
lambda = log(2)/HL;

%% Process the images.
hdrs = cell(1,N);
writeFile = fullfile(folder,'Dynamic.img');
writeID = fopen(writeFile,'w+');
wbh = waitbar(0,'wait...');
for ii = 1:N
    thisFrame = fullfile(folder,sprintf('Frame%03.0f.img',ii));
    readID = fopen(thisFrame,'r');
    fwrite(writeID,fread(readID,Inf));
    fclose(readID);
    hdrs{ii} = headerReader([thisFrame, '.hdr']);
    try waitbar(ii/N,wbh,sprintf('Processing: %1.0f%%',ii/N*100)); end
end
fclose(writeID);
try waitbar(1,wbh,'Writing header...'); end
    
% process header;
HDR = hdrs{1};
HDR.General.file_name = writeFile;
HDR.General.acquisition_mode = 3; % dynamic
HDR.General.total_frames = N;
HDR.General.time_frames = N;
HDR.General.number_of_dimensions = 4;
startTime = HDR.frame_0.frame_duration;
filePointer = HDR.frame_0.data_file_pointer(2);
for ii = 2:N
    HDR.(sprintf('frame_%1.0f',ii-1)).detector_panel = hdrs{ii}.frame_0.detector_panel;
    HDR.(sprintf('frame_%1.0f',ii-1)).event_type =hdrs{ii}.frame_0.event_type;
    HDR.(sprintf('frame_%1.0f',ii-1)).energy_window =hdrs{ii}.frame_0.energy_window;
    HDR.(sprintf('frame_%1.0f',ii-1)).gate =hdrs{ii}.frame_0.gate;
    HDR.(sprintf('frame_%1.0f',ii-1)).bed =hdrs{ii}.frame_0.bed;
    HDR.(sprintf('frame_%1.0f',ii-1)).bed_offset= hdrs{ii}.frame_0.bed_offset;
    HDR.(sprintf('frame_%1.0f',ii-1)).ending_bed_offset = hdrs{ii}.frame_0.ending_bed_offset;
    HDR.(sprintf('frame_%1.0f',ii-1)).vertical_bed_offset = hdrs{ii}.frame_0.vertical_bed_offset;
    HDR.(sprintf('frame_%1.0f',ii-1)).data_file_pointer = hdrs{ii}.frame_0.data_file_pointer+filePointer;
    HDR.(sprintf('frame_%1.0f',ii-1)).frame_start = startTime;
    FD = hdrs{ii}.frame_0.frame_duration;
    HDR.(sprintf('frame_%1.0f',ii-1)).frame_duration = FD;
    
    HDR.(sprintf('frame_%1.0f',ii-1)).scale_factor = hdrs{ii}.frame_0.scale_factor * exp(lambda*startTime);
    HDR.(sprintf('frame_%1.0f',ii-1)).minimum = hdrs{ii}.frame_0.minimum;
    HDR.(sprintf('frame_%1.0f',ii-1)).maximum = hdrs{ii}.frame_0.maximum;
    HDR.(sprintf('frame_%1.0f',ii-1)).deadtime_correction = hdrs{ii}.frame_0.deadtime_correction;
    HDR.(sprintf('frame_%1.0f',ii-1)).decay_correction = hdrs{ii}.frame_0.decay_correction;
    HDR.(sprintf('frame_%1.0f',ii-1)).prompts = hdrs{ii}.frame_0.prompts;
    HDR.(sprintf('frame_%1.0f',ii-1)).prompts_rate = hdrs{ii}.frame_0.prompts_rate;
    HDR.(sprintf('frame_%1.0f',ii-1)).delays = hdrs{ii}.frame_0.delays;
    HDR.(sprintf('frame_%1.0f',ii-1)).trues = hdrs{ii}.frame_0.trues;
    HDR.(sprintf('frame_%1.0f',ii-1)).delays_rate = hdrs{ii}.frame_0.delays_rate;
    HDR.(sprintf('frame_%1.0f',ii-1)).end_of_header = '';
    filePointer = HDR.(sprintf('frame_%1.0f',ii-1)).data_file_pointer(2);
    startTime = startTime + FD;
end
headerWriter(HDR,[writeFile,'.hdr']);
try close(wbh); end