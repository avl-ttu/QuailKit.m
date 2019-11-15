function Object=HT_Feedback(Object)
%HT_Feedback Applies feedback on icons.

%   Inputs:
%       Object: Either the cdata matrix or its parent.
%   Outputs:
%       Object: Updated Object.

% � 2018 Hanif Tiznobake

if isnumeric(Object)
    temp=Object;
else
    temp=Object.CData;
end
c=temp(1,1,:);
temp2=temp;
temp2(~isnan(temp))=NaN;
for i=1:3
    temp3=temp2(:,:,i);
    temp3(isnan(temp(:,:,i)))=c(i);
    temp3(1,:)=c(i);
    temp3(:,1)=c(i);
    temp3(end,:)=c(i);
    temp3(:,end)=c(i);
    temp2(:,:,i)=temp3;
end
if isnumeric(Object)
    Object=temp2;
else
    Object.CData=temp2;
end %gdgfefd