function info = quickerDicomParse(files)
    
    N = length(files);
    curDir = cd;
    cd([matlabroot strrep('_toolbox_images_iptformats_private','_',filesep)]);  % path to a faster, more basic dicom parser -> new matlab
    [g1, e1] = dicomlookup('SeriesInstanceUID'); 
    [g2, e2] = dicomlookup('SeriesDescription'); 
    [g3, e3] = dicomlookup('StudyInstanceUID');
    [g4, e4] = dicomlookup('PatientName');
    [g5, e5] = dicomlookup('SeriesNumber');
    [g6, e6] = dicomlookup('PatientID');
    info = struct('StudyInstanceUID',cell(N,1),...
                  'SeriesInstanceUID',cell(N,1),...        
                  'SeriesNumber',cell(N,1),...
                  'SeriesDescription',cell(N,1),...
                  'PatientName',cell(N,1),...
                  'PatientID',cell(N,1));
    
    for ii = 1:N
        a = dicomparse(files(ii).name,files(ii).bytes, 'L', false, dicomdict('get_current'));
        idx = ([a.Group] == g1) & ([a.Element] == e1);
        info(ii).SeriesInstanceUID = char(a(idx).Data);
        idx = ([a.Group] == g2) & ([a.Element] == e2);
        info(ii).SeriesDescription = deblank(char(a(idx).Data));
        idx = ([a.Group] == g3) & ([a.Element] == e3);
        info(ii).StudyInstanceUID = deblank(char(a(idx).Data));
        idx = ([a.Group] == g4) & ([a.Element] == e4);
        info(ii).PatientName = deblank(char(a(idx).Data));
        idx = ([a.Group] == g5) & ([a.Element] == e5);
        info(ii).SeriesNumber = str2double(deblank(char(a(idx).Data)));
        idx = ([a.Group] == g6) & ([a.Element] == e6);
        info(ii).PatientID = deblank(char(a(idx).Data));
    end
    cd(curDir);

end