function [bmask, amask] = createFunctionalMRIMask(aimg,bimg,ahdr,bhdr,amask)
    
    if nargin<4
        error('At least four inputs are required!');
    elseif nargin==4
        bA = alignDicoms(aimg,bimg,ahdr,bhdr,'nearest');
        [sx,sy,sz] = size(bA);
        [x,~,X] = unique(mean(mean(bA,2),3),'stable'); x = length(x);
        [y,~,Y] = unique(mean(mean(bA,1),3),'stable'); y = length(y);
        [z,~,Z] = unique(mean(mean(bA,1),2),'stable'); z = length(z);
        [~,direction] = min([x,y,z]);
        fig = figure;
        switch direction
            case 1
                temp1 = zeros(x-1,sy,sz);
                mask1 = temp1==1;
                amask = true(size(aimg));
                for ii = 2:x
                    temp1(ii-1,:,:) = mean(aimg(X==ii,:,:),1);
                    imshow(squeeze(temp1(ii-1,:,:)),[]); title('Draw ROI and press Enter');
                    ROI = imfreehand;
                    pause
                    tempmask = ROI.createMask;
                    mask1(ii-1,:,:) = tempmask;
                    amask(X==ii,:,:) = repmat(reshape(tempmask,[1 sy sz]),[sum(X==ii),1 1]);
                end
            case 2
                temp1 = zeros(sx,y-1,sz);
                mask1 = temp1==1;
                amask = true(size(aimg));
                for ii = 2:y
                    temp1(:,ii-1,:) = mean(aimg(:,Y==ii,:),2);
                    imshow(squeeze(temp1(:,ii-1,:)),[]); title('Draw ROI and press Enter');
                    ROI = imfreehand;
                    pause
                    tempmask = ROI.createMask;
                    mask1(:,ii-1,:) = tempmask;
                    amask(:,Y==ii,:) = repmat(reshape(tempmask,[sx,1,sz]),[1,sum(Y==ii),1]);
                end
            case 3
                temp1 = zeros(sx,sy,z-1);
                mask1 = temp1==1;
                amask = true(size(aimg));
                for ii = 2:z
                    temp1(:,:,ii-1) = mean(aimg(:,:,Z==ii),3);
                    imshow(squeeze(temp1(:,:,ii-1)),[]); title('Draw ROI and press Enter');
                    ROI = imfreehand;
                    pause
                    tempmask = ROI.createMask;
                    mask1(:,:,ii-1) = tempmask;
                    amask(:,:,Z==ii) = repmat(tempmask,[1,1,sum(Z==ii)]);
                end
        end
        bmask = alignDicoms(bimg,amask,bhdr,ahdr,'nearest')==1;
        close(fig)
    else
        bmask = alignDicoms(bimg,amask,bhdr,ahdr,'nearest')==1;
    end

end