function writeIRWTransformationMatrix(TRF,filename,source_uid,target_uid)

if nargin < 1 || isempty(TRF)
    TRF = eye(4); 
    fprintf('Writing default (identity matrix).\n');
end
if any(size(TRF)~=[4,4])
    fprintf('Invalid tranformation matrix, 4x4 required!\n');
    return;
end
if nargin < 2 || isempty(filename)
    fprintf('Select output file: ...\n');
    [FileName,PathName,FilterIndex] = uiputfile({'*.trf','Transformation matrices (*.trf)'},'Select output file');
    filename = fullfile(PathName,FileName);
    if ~FilterIndex
        fprintf('Aborted\n');
        return
    end
end
if nargin<4
    fprintf('No UIDs provided, creating new ones\n');
    source_uid = dicomuid;
    target_uid = dicomuid;
end


data = sprintf('SOURCE_UID=%s;\nTARGET_UID=%s;\nTARGET_TRANSFORM_MATRIX=\n',source_uid,target_uid);
TRF = TRF';
for ii = 1:16
    newstr = sprintf('%1.17g,',TRF(ii));
    if isempty(regexp(newstr,'\.'))
        newstr = [newstr(1:end-1),'.0,'];
    end
    data = [data,newstr];
    if ~rem(ii,4)
        data = [data,char(10)];
    end
end
data(end-1:end) = [];
[y,m,d] = datevec(now);
data = [data,sprintf('\n;\nDATETIME=%1.0f,%1.0f,%1.0f;\n',d,m,y)];
fid = fopen(filename,'w+');
fprintf(fid,data);
fclose(fid);
