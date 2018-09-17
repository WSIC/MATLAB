function [TMatrix,Vsource,Hsource,Rsource,Vtarget,Htarget,Rtarget] = MakeTransMatrix(Vsource,Hsource,Vtarget,Htarget)

    % Process source
    [rs,cs,ss,ts,ipps,pss] = getInfo(Hsource);
    if ~isempty(ts) && ~all(sign(ss)==sign(ts))       % If the sign of both orientations does not match, the dataset is probably 'upside down'
        Hsource = Hsource(end:-1:1,:);                % Turn headers around
        Vsource = Vsource(:,:,end:-1:1,:);            % turn images around
        [rs,cs,ss,~,ipps,pss] = getInfo(Hsource);
    end
    Rsource = imref3d([size(Vsource,1),size(Vsource,2),size(Vsource,3)],pss(2),pss(1),pss(3)); 
    Tras = [[1 0 0; 0 1 0; 0 0 1; 0 0 0],[ipps;1]];
    Rots = [[[rs,cs,ss],[0;0;0]];[0 0 0 1]];
    tMs = Tras*Rots;

    % Process target
    [rt,ct,st,tt,ippt,pst] = getInfo(Htarget);
    if ~isempty(tt) && ~all(sign(st)==sign(tt))       % If the sign of both orientations does not match, the dataset is probably 'upside down'
        Htarget = Htarget(end:-1:1,:);                % Turn headers around
        Vtarget = Vtarget(:,:,end:-1:1,:);            % turn images around
        [rt,ct,st,~,ippt,pst] = getInfo(Htarget);
    end
    if size(Vtarget,3) == 1
        Vtarget(:,:,2,:) = Vtarget(:,:,1,:);
        warning('Single slice image: to make it 3D, it has been converted to two slices of 1/2 thickness.');
        pst(3) = pst(3)/2;
    end
    Rtarget = imref3d([size(Vtarget,1),size(Vtarget,2),size(Vtarget,3)],pst(2),pst(1),pst(3));
    Trat = [[1 0 0; 0 1 0; 0 0 1; 0 0 0],[ippt;1]];
    Rott = [[[rt,ct,st],[0;0;0]];[0 0 0 1]];
    tMt = Trat*Rott;

    TMatrix = tMs\tMt;
    
    
    function [rdir,cdir,sdir,ippdir,ipp,psize] = getInfo(hdr)
        iop = hdr{1}.ImageOrientationPatient(:);
        rdir=iop(1:3); cdir=iop(4:6); sdir=cross(rdir,cdir);
        if size(hdr,1)>1
            ippdir = (hdr{2,1}.ImagePositionPatient(:) - hdr{1,1}.ImagePositionPatient(:));
            psize = [hdr{1,1}.PixelSpacing(:); sqrt(sum(ippdir.^2))];
            moveSlice = (sqrt(sum(ippdir.^2)) - hdr{1,1}.SliceThickness)/2;
        else
            ippdir = [];
            try 
                if ~isempty(hdr{1,1}.SpacingBetweenSlices)
                    psize = [hdr{1,1}.PixelSpacing(:); hdr{1,1}.SpacingBetweenSlices];
                    moveSlice = (hdr{1,1}.SpacingBetweenSlices - hdr{1,1}.SliceThickness)/2;
                else
                    psize = [hdr{1,1}.PixelSpacing(:); hdr{1,1}.SliceThickness];
                    moveSlice = 0;
                end
            catch
                psize = [hdr{1,1}.PixelSpacing(:); hdr{1,1}.SliceThickness];
                moveSlice = 0;
            end
        end
        ipp = hdr{1,1}.ImagePositionPatient(:);
        ipp = ipp - rdir*psize(1) - cdir*psize(2) - sdir*psize(3) - sdir*moveSlice;
    end
    
  end