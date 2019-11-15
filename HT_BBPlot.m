function HT_BBPlot(x,y,z,d,h,c,init)
%HT_BBPlot adds bounding boxes to the already ploted 2d data using
%pre-defined surface graphic object.

%   Inputs:
%       x: Discrete x coordinate values.
%       y: Discrete y coordinate values.
%       z: Values of the 2D data. (only the size is used)
%       d: n (number of bounding boxes) by 4 matrix, first two columns are
%       the start and end values of bounding boxes on the x dimension and
%       last two columns are the start and end values of bounding boxes on
%       the y dimension.
%       h: Predefined graphic object of type surface, to use for plotting
%       the bounding boxes.
%       c: 1 by 3 vector, to set the color for bounding boxes.
%       init: Boolean indicating if the surface needs to be cleared first.

% © 2018 Hanif Tiznobake

if init
    set(h,...
        'XData',x,...
        'YData',y,...
        'ZData',100*ones(size(z)),...
        'CData',repmat(zeros(size(z)),1,1,3),...
        'AlphaData',zeros(size(z)));
end
if ~isempty(d)
    idx(1,:)=discretize(d(:,1),x);
    idx(2,:)=discretize(d(:,2),x);
    idx(3,:)=discretize(d(:,3),y);
    idx(4,:)=discretize(d(:,4),y);
    idx(3,isnan(idx(3,:)))=1;
    idx(4,isnan(idx(4,:)))=length(y);
    for i=1:size(idx,2)
        h.AlphaData(idx(3,i):idx(4,i),idx(1,i):idx(2,i))=(0.2+...
             h.AlphaData(idx(3,i):idx(4,i),idx(1,i):idx(2,i)))/2;
        h.AlphaData([idx(3,i):idx(3,i)+1,idx(4,i)-...
            1:idx(4,i)],idx(1,i):idx(2,i))=1;
        h.AlphaData(idx(3,i):idx(4,i),[idx(1,i):idx(1,i)+1,idx(2,i)-...
            1:idx(2,i)])=1;
        for j=1:3
            h.CData(idx(3,i):idx(4,i),idx(1,i):idx(2,i),j)=...
                (c(max(1,rem(i,size(c,1)+1)),j)+...
                h.CData(idx(3,i):idx(4,i),idx(1,i):idx(2,i),j))/2;
        end
    end
end
end
