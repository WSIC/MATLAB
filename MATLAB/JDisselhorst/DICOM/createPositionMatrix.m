function [XXX,YYY,ZZZ] = createPositionMatrix(HDR)
% CREATEPOSITIONMATRIX Creates coordinate matrices of a dicom volume
%
% Usage:   
%         [X,Y,Z] = createPositionMatrix(HDRs)
%
% Input:  
%         * HDRs: a cell array of headers of the volume
%
% Output: 
%         * X: X positions of the volume
%         * Y: Y positions of the volume
%         * Z: Z positions of the volume
%
% JA Disselhorst, Uni. Tuebingen
% Version 20130404
%
% See also: 
% http://nipy.sourceforge.net/nibabel/dicom/dicom_orientation.html

    F = HDR{1}.ImageOrientationPatient;        % Orientation of the slices
    F = [F(4), F(1); F(5), F(2); F(6), F(3)];  % Put in a different order
    N = length(HDR);                           % The number of slices
    S1 = HDR{1}.ImagePositionPatient;          % Position of the first pixel of the first slice
    %S2 = HDR{2}.ImagePositionPatient;
    SN = HDR{end}.ImagePositionPatient;        % Position of the first pixel of the last slice
    dc = HDR{1}.PixelSpacing;                  % Pixel spacing.
    dr = dc(2);                                % For the IOPs
    dc = dr(1);                                % For the columns
    %ds = sqrt(sum((S2-S1).^2));      
    r = double(HDR{1}.Rows)-1;                 % The number of the last pixel in the IOP
    c = double(HDR{2}.Columns)-1;              % The number of the last pixel in the column
    s = length(HDR)-1;                         % The number of the last slice

    A = [F(1,1)*dr, F(1,2)*dc, (S1(1)-SN(1))/(1-N), S1(1);  % Affine transform matrix.
         F(2,1)*dr, F(2,2)*dc, (S1(2)-SN(2))/(1-N), S1(2);
         F(3,1)*dr, F(3,2)*dc, (S1(3)-SN(3))/(1-N), S1(3);
         0,0,0,1];

    [X,Y,Z] = meshgrid([0,c],[0,r],[0,s]);     % The 8 corner points (pixel number) of the volume
    Px = zeros(2,2,2);                         % Initialize their x position
    Py = Px; Pz = Px;                          % Initialize their y and z position
    for ii = 1:8                               % Loop through all 8
        p = A*[Y(ii);X(ii);Z(ii);1];           % Calculate their position
        Px(ii) = p(1);                         % X
        Py(ii) = p(2);                         % Y
        Pz(ii) = p(3);                         % Z
    end
    [XX,YY,ZZ] = meshgrid(0:c,0:r,0:s);        % The pixel numbers of all pixels
    XXX = interp3(X,Y,Z,Px,XX,YY,ZZ);          % Interpolate all the x positions.
    YYY = interp3(X,Y,Z,Py,XX,YY,ZZ);          % Interpolate all the y positions.
    ZZZ = interp3(X,Y,Z,Pz,XX,YY,ZZ);          % Interpolate all the z positions.
    
    IOP = HDR{1}.ImageOrientationPatient;
    IOP(7:9) = cross(IOP(1:3),IOP(4:6));
    IOPabs = abs(IOP);
    % ROW, COL, SLI
    
    O = 'XXX';
    for i = 1:3:7;
        if IOPabs(i)>0.0001 && IOPabs(i)>IOPabs(i+1) && IOPabs(i)>IOPabs(i+2)
            if IOP(i)<0, O((i+2)/3) = 'R'; else O((i+2)/3) = 'L'; end
        elseif IOPabs(i+1)>0.0001 && IOPabs(i+1)>IOPabs(i) && IOPabs(i+1)>IOPabs(i+2)
            if IOP(i+1)<0, O((i+2)/3) = 'A'; else O((i+2)/3) = 'P'; end
        elseif IOPabs(i+2)>0.0001 && IOPabs(i+2)>IOPabs(i) && IOPabs(i+2)>IOPabs(i+1)
            if IOP(i+2)<0, O((i+2)/3) = 'F'; else O((i+2)/3) = 'H'; end
        else error('Image orientation is unclear!');
        end
    end
    fprintf('Direction x: %s, Direction y: %s, Direction z: %s\n',O(1),O(2),O(3)); 