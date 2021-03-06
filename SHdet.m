function varargout = SHdet(S,F,t,template,scale,threshold,doublepass)
% Input Parameters
% Spectrogram
% Template
% Thresh: Corresponding threshold for different templates
% Mode: Single (Single Envelope), Double (Double Envelope)
% h: Graphic handles (Line,Line,Scatter,Scatter)

% Output:
% Contains number of calls (Number of rows)
% Each row contains start Time, End Time, Start freq. and End freq.
tem=importdata(['template_',char(string(template)),'.mat']);
[r,c]=size(tem);
% Template Matching
Upper = find(F==1000);
Downward = find(F==3000);
M = normxcorr2(tem,S(Upper:Downward,:));
M = M(r:size(M,1)-r+1,c:end);
dist = scale * 2;
dist=round(dist*numel(tem));
%     Calls = [];
%     CallsIDX = [];
if doublepass
    SecondDistance = round(dist/3);
    [Locs,Width] = TwoEnvelope(M,dist,SecondDistance,threshold,true,size(tem,2));
    [StartF,StartT] = ind2sub(size(M),Locs);
    StartF = StartF + 1000;
    EndT = StartT + Width - 1;
    EndF = StartF + size(tem,1)+1000;
    EndT = round(EndT);
    callsIDX = [(StartT)',(EndT)',(StartF)',(EndF)'];
    Calls = [t(StartT)',t(EndT)',F(StartF)',F(EndF)'];
else
    [Locs,Width,up] = SingleEnvelope(M,dist,threshold,true);
    Width = Width./(2*numel(tem));
    Width = size(tem,2).*Width;
    %         Width = size(Template,2);
    [StartF,StartT] = ind2sub(size(M),Locs);
    EndT = StartT + Width - 1;
    EndF = StartF + size(tem,1)-1;
    EndT = round(EndT);
    EndT(EndT>size(M,2)) = size(M,2);
    callsIDX = [(StartT),(EndT),(StartF),(EndF)];
    Calls = [t(StartT),t(EndT),F(StartF)'+1000,F(EndF)'+1000];
end
Calls=array2table(Calls,'VariableNames',{'start_t','end_t','low_f','high_f'});
Calls.detection_template=repmat(template,size(Calls,1),1);
Calls.detection_scale=repmat(scale,size(Calls,1),1);
Calls.detection_threshold=repmat(threshold,size(Calls,1),1);
varargout{1}=Calls;
varargout{2}=callsIDX;
varargout{3}=M;
end

function [locs,width,up] = SingleEnvelope(M,Distance,Thresh,UseDistance)
[up,~]=envelope(M(:),Distance,'peak');  % First envelope
if UseDistance==true
    [locs,width] = FindLocsUnderEnvelope(up,M,Thresh,0.5*Distance);
else
    [locs,width] = FindLocsUnderEnvelope(up,M,Thresh,0);
end
end

function [locs,width] = FindLocsUnderEnvelope(up,M,Thresh,Distance)
up(1) = 0;
up(end) = 0;
idx = find(up>=Thresh);
LeftLimit = idx(up(idx-1)<Thresh);
RightLimit = idx(up(idx+1)<Thresh);
locs = zeros(size(LeftLimit));
width = zeros(size(LeftLimit));

for i=1:numel(LeftLimit)
    Tempidx = LeftLimit(i):RightLimit(i);
    if numel(Tempidx)<Distance
        continue;
    end
    Temp = M(Tempidx);
    [Max,Templocs] = max(Temp);
    if Max<Thresh
        continue;
    end
    locs(i) = Templocs + LeftLimit(i) - 1;
    width(i) = numel(Tempidx);
end
locs(locs==0)=[];
width(width==0) = [];
end

function [locsE,WidthE] = TwoEnvelope(M,FirstDistance,SecondDistance,Thresh,UseDistance)

[up,~]=envelope(M(:),FirstDistance,'peak');  % First envelope
% Find the signal under the signal
[~,locs,Width,~] = findpeaks(up,1:numel(M));

% Avoid preallocation
Xidx = cell(size(locs));
MSub = cell(size(locs));
UpSub = cell(size(locs));
WidthE = cell(size(locs));
locsE = cell(size(locs));

for i=1:numel(locs)
    idx = int64(locs(i)-Width(i)/2:locs(i)+Width(i)/2);
    if numel(find(idx<=0))~=0
        idx = idx(idx>0);
    end
    if numel(find(idx>numel(M)))~=0
        idx = idx(idx<=numel(M));
    end
    if UseDistance==true
        if numel(find(up(idx)>Thresh))<FirstDistance
            Xidx{i} = int64([]);
            locsE{i} = int64([]);
            continue;
        end
        Xidx{i} = idx;
        MSub{i} = M(idx);
        [Temp,~] = envelope(M(idx),SecondDistance,'peak'); % Second Envelop
        UpSub{i} = Temp;
        locsTemp = int64(FindLocsUnderEnvelope(Temp,M(idx),Thresh,SecondDistance));
        locsE{i} = locsTemp+idx(1)-1;
        if numel(locsE{i}~=0)
            WidthE{i} = repmat(Width(i),size(locsE{i}));
        end
    else
        Xidx{i} = idx;
        MSub{i} = M(idx);
        [Temp,~] = envelope(M(idx),SecondDistance,'peak'); % Second Envelop
        UpSub{i} = Temp;
        locsTemp = int64(FindLocsUnderEnvelope(Temp,M(idx),Thresh,0));
        locsE{i} = locsTemp+idx(1)-1;
        if numel(locsE{i}~=0)
            WidthE{i} = repmat(Width(i),size(locsE{i}));
        end
    end
end
locsE = cell2mat(locsE);
WidthE = cell2mat(WidthE);
end
