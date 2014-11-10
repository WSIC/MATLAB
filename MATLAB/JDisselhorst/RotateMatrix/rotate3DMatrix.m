function rotatedMat = rotate3DMatrix(inputMat, degrees, interp)
% ROTATE3DMATRIX Rotates a 3-Dimensional matrix. 
% Usage: 
%         rotatedMat = rotate3DMatrix(inputMat, degrees, interp)
% Input:
%         o inputMat:   Input matrix [x,y,z]
%         o degrees:    Rotationangle in all directions [x,y,z]
%         o interp:     Interpolation method.
% 
% Output:
%         o rotatedMat: The rotated matrix.
%
% Mathew Divine. 2012

if nargin<3
    interp = 'linear';
end

if numel(degrees) == 3
    rads = degrees.*pi./180;
    thetaX = rads(1);
    thetaY = rads(2);
    thetaZ = rads(3);
    
else
    disp('Error:need a 3x1 matrix')
end
% setup rotation matrices around specified axes
    Tx = [ 1     0            0       0
           0 cos(thetaX) -sin(thetaX) 0 
           0 sin(thetaX)  cos(thetaX) 0
           0     0            0       1];
       
    Ty = [ cos(thetaY)  0  sin(thetaY) 0      
                 0      1     0        0
           -sin(thetaY) 0 cos(thetaY)  0
           0            0     0        1];  
    
    Tz = [ cos(thetaZ) -sin(thetaZ) 0  0      
           sin(thetaZ)  cos(thetaZ) 0  0
           0                  0     1  0
           0                  0     0  1];
       
% set up translational matrices to and from the center point of the 3d
% object

inputMatCenter = (size(inputMat) +1)/2;
T1 = [1 0 0 0
      0 1 0 0
      0 0 1 0
    -inputMatCenter 1];
T2 = [1 0 0 0
      0 1 0 0
      0 0 1 0
    inputMatCenter 1];

T = T1 * Tx * Ty * Tz * T2; 

tform = maketform('affine', T);
tformfwd(inputMatCenter, tform);

%% tformarray
% function specifies type of interpolation and how to handle boundaries
R = makeresampler(interp, 'fill');
% each spatial transfromation corresponds to the same input array dimension
% other types are "advanced" at this moment 
TDIMS_A = [1 2 3];
% specifies how the dimensions of the output array correspond to 
% the dimensions of the spatial transformation. 
TDIMS_B = [1 2 3];
% size of output array
TSIZE_B = size(inputMat);
% TMAP_B is unused when you have a tform struct. Just specify it to be empty. 
TMAP_B = [];
% values outside of the boundarty
F = 0;
% transform
rotatedMat = tformarray(inputMat, tform, R, TDIMS_A, TDIMS_B, TSIZE_B, TMAP_B, F);

end