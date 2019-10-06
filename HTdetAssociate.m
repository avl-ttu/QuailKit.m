function validPairs=HTdetAssociate(detections)
%HTdetAssociate groups observations of multiple acoustic events together
%based on the possibility of them coming from the same source. 

%   detections (N by 4 matrix):
%       N: Number of observations
%       4: Latitude, Longitude, Time, Temperature
%   validPairs (M by 2 matrix):
%       M: Number of valid pairs
%       2: detection index 1, detection index 2

% © 2019 Hanif Tiznobake

validPairs=[];
for ii=1:size(detections,1)
    for jj=ii+1:size(detections,1)
        if isAssociated(...
                detections(ii,1),detections(jj,1),...
                detections(ii,2),detections(jj,2),...
                detections(ii,3),detections(jj,3),...
                mean(detections([ii,jj],4)))
            validPairs=[validPairs;ii,jj];
        end
    end
end

end

function associated=isAssociated(lat1,lat2,long1,long2,time1,time2,temp)
delayDistance=abs(time1-time2) *(331.3 + 0.606 * temp) / 1000;
actualDistance = 2.0 * 6371000 * asin(sqrt(sind(0.5*(lat2-lat1))^2 + ...
    cosd(lat1) * cosd(lat2) * sind(0.5*(long2-long1))^2));
associated = delayDistance<=actualDistance;
end