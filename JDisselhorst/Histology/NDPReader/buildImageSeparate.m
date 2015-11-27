function IMG = buildImageSeparate(rawdata,width,height,channels,channelOrder)
        % BUILDIMAGE creates an image from the raw data from the NDPi file
        % This function is built into NDPReader
        IMG = uint8(zeros(height,width,channels));
        linesize = ceil((width*channels)/4)*4;
        for X = 1:height
            position = (X-1)*linesize+1;
            currentline = rawdata(position:position+linesize-1);
            currentline = currentline(1:width*3);
            currentline = reshape(currentline,3,width);
            currentline = permute(currentline,[2,1]);
            if channelOrder==1
                IMG(X,:,3:-1:1) = currentline;
            elseif channelOrder==2
                IMG(X,:,1:3) = currentline;
            elseif channelOrder==3
                IMG(X,:,1) = currentline;
            else
                error('Number of channels undefined!')
            end
        end
        IMG = IMG(end:-1:1,:,:);
    end