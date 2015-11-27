%% Convert NMR Data for use by QBiC...

% Folder that contains all the measurements:
mainFolder = 'V:\NMR\ERC-09';
saveFolder = 'V:\NMR\#SendToQBiC';
c= mkdir(saveFolder);

% Barcode Format:
bcf = 'Q[A-Z0-9]{9}\>'; % Capital Q followed by 9 alphanumeric capital

% Get all the individual measurements (only folders containing numbers):
meas = dir(mainFolder); meas(~[meas.isdir]) = [];
use = regexp({meas.name},'\d+'); use = cellfun(@(x) isequal(1,x),use);
meas = meas(use);

% Loop over the measurement:
for ii = 1:length(meas)
    Bruker = BrukerNMR(fullfile(mainFolder,meas(ii).name));
    title = Bruker.General.Title;
    titlelong = strjoin(reshape(title,1,[]),' ');

    position = regexp(titlelong,bcf);
    breakloop = 0;
    if isempty(position)
        bars = {''};
        while length(regexp(bars{:},bcf))~=1
            bars = upper(inputdlg(['Title',char(10),strjoin(reshape(title,1,[]),char(10)),char(10),char(10),'Barcode [Qxxxxxxxxx]:'],'No barcode found',1,{'Q'}));
            if isempty(bars)
                warning('DISSELHORST:BarcodeSkipped','File skipped')
                breakloop = 1;
            	break
            end
        end
    elseif length(position)>1
        bars = cell(length(position),1);
        for jj = 1:length(position)
            bars{jj} = titlelong(position(jj):position(jj)+9);
        end
        bars = unique(bars);
        if length(bars)>1
            c = menu(['Title',char(10),strjoin(reshape(title,1,[]),char(10)),char(10),char(10),'Multipe barcodes found, pick one'],bars);
            if ~c
                warning('DISSELHORST:BarcodeSkipped','File skipped')
                breakloop = 1;
            	break
            end
            bars = bars(c);
        end
    else
        bars = {titlelong(position:position+9)};
    end
    if breakloop
        continue
    end

    if exist(fullfile(saveFolder,[bars{:},'.mat']),'file') || ...
       exist(fullfile(saveFolder,[bars{:},'.tar']),'file') || ...
       exist(fullfile(saveFolder,[bars{:},'.csv']),'file') || ...
       exist(fullfile(saveFolder,[bars{:},'.txt']),'file') || ...
       exist(fullfile(saveFolder,[bars{:},'.png']),'file')
            c = questdlg(sprintf('Barcode (%s) already in use, use anyway?',bars{:}),'Barcode has been used','Yes','No','No');
            if ~strcmpi(c,'yes')
                warning('DISSELHORST:BarcodeSkipped','Barcode ''%s'' skipped',bars{:})
            	continue
            end
    end
    fid = fopen(fullfile(saveFolder,[bars{:},'.txt']),'w+');
    fprintf(fid,'Filename: %s\r\nAcquisition: %s\r\nComments: "%s"',fullfile(mainFolder,meas(ii).name),...
        Bruker.General.AcquisitionTime,strjoin(reshape(title,1,[]),'\t'));
    fclose(fid);
    spectrum = Bruker.spectrumBruker;
    spectrum = [Bruker.spectrumAxis; real(spectrum);imag(spectrum)];
    fid = fopen(fullfile(saveFolder,[bars{:},'.csv']),'w+');
    fprintf(fid,'PPM,Real,Imag\r\n'); 
    fprintf(fid,'%2.16f,%i,%i\r\n',spectrum);
    fclose(fid);
    %csvwrite(fullfile(saveFolder,[bars{:},'.csv']),[Bruker.spectrumAxis',spectrum]);
    
    tar(fullfile(saveFolder,[bars{:},'.tar']),fullfile(mainFolder,meas(ii).name));
    %save(fullfile(saveFolder,[bars{:},'.mat']),'Bruker');
    copyfile(fullfile(mainFolder,meas(ii).name,'pdata','1','thumb.png'),fullfile(saveFolder,[bars{:},'.png']));
end; 
