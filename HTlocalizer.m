function activities = HTlocalizer(detections)
%HT_LOCALIZER Finds location and time of an activity based on acoustic
%detections in N points (N>=3).

%   detections (N by 4 matrix):
%       N: Number of observations
%       4: Latitude, Longitude, Time, Temperature
%   activities (M by 4 matrix):
%       M: Number of potentially valid localizations.
%       4: Latitude, Longitude, Time, Error

% © 2018 Hanif Tiznobake

c = 331.3+0.606*mean(detections(:,4),1);                                    % Speed of sound:  c = 331.3+0.606*theta (taken from https://en.wikipedia.org/wiki/Speed_of_sound at 11/11/2018)
[x,y,~]=geodetic2enu(...
    detections(:,1),detections(:,2),zeros(size(detections,1),1),...
    detections(1,1),detections(1,2),0,referenceEllipsoid('earth'));
t=detections(:,3);
v=nchoosek(1:size(detections,1),3);
sol=double.empty(0,3);
syms x0 y0 t0
for i=1:size(v,1)
    eqns=[(x(v(i,1))-x0)^2+(y(v(i,1))-y0)^2-c^2*(t(v(i,1))-t0)^2,...
          (x(v(i,2))-x0)^2+(y(v(i,2))-y0)^2-c^2*(t(v(i,2))-t0)^2,...
          (x(v(i,3))-x0)^2+(y(v(i,3))-y0)^2-c^2*(t(v(i,3))-t0)^2];
    
    struct=solve(eqns,[x0,y0,t0]);
    a=double([struct.x0,struct.y0,struct.t0]);
    if isreal(a)
        sol=[sol;a];
    end
end
sol = unique(sol(sol(:,3)<min(t) & sol(:,3)~=0,:),'rows');
activities = zeros(size(sol,1),4);
[activities(:,1),activities(:,2),~] = enu2geodetic(...
    sol(:,1),sol(:,2),zeros(size(sol,1),1),...
    detections(1,1),detections(1,2),0,referenceEllipsoid('earth'));
activities(:,3)=sol(:,3);