function [Calls,CallsIDX,M] = SH_FindCalls(S,t,F,Template,Thresh,Distance,DoublePass,h)
    % Input Parameters
    % Spectrogram
    % Template
    % Thresh: Corresponding threshold for different templates
    % Mode: Single (Single Envelope), Double (Double Envelope)
    % h: Graphic handles (Line,Line,Scatter,Scatter)
    
    % Output:
    % Contains number of calls (Number of rows)
    % Each row contains start Time, End Time, Start freq. and End freq.
    % M: Correlation Signal
    
    [r,c]=size(Template);
    % Only process the freq between 1000 and 3000
    Upper = find(F==1000);
    Downward = find(F==3000);
    S = S(Upper:Downward,:);
    
    M = normxcorr2(Template,S); % Template Matching
    M = M(r:size(M,1)-r+1,c:end);
    
    Distance = Distance * 2;
    Distance=round(Distance*numel(Template));   % Distance for Envelope Detection

    if DoublePass
        SecondDistance = round(Distance/3);
        [Locs,Width] = TwoEnvelope(M,Distance,SecondDistance,Thresh,true,size(Template,2));
        [StartF,StartT] = ind2sub(size(M),Locs);
        StartF = StartF + 1000;
        EndT = StartT + Width - 1;
        EndF = StartF + size(Template,1)+1000;
        EndT = round(EndT);
        CallsIDX = [(StartT)',(EndT)',(StartF)',(EndF)'];
        Calls = [t(StartT)',t(EndT)',F(StartF)',F(EndF)'];
    else
        [Locs,Width,up] = SingleEnvelope(M,Distance,Thresh,true);
        Width = Width./(2*numel(Template));
        Width = size(Template,2).*Width;
        %         Width = size(Template,2);
        [StartF,StartT] = ind2sub(size(M),Locs);
        EndT = StartT + Width - 1;
        EndF = StartF + size(Template,1)-1;
        EndT = round(EndT);
        EndT(EndT>size(M,2)) = size(M,2);
        CallsIDX = [(StartT),(EndT),(StartF),(EndF)];
        Calls = [t(StartT)',t(EndT)',F(StartF)'+1000,F(EndF)'+1000];
    end
    if ~isempty(h)
        set(h(1),'XData',1:numel(M),'YData',M(:));
        set(h(2),'XData',1:numel(M),'YData',up);
        set(h(3),'XData',Locs,'YData',M(Locs));
        set(h(4),'XData',[1,numel(M)],'YData',Thresh*[1,1],'ZData',[0,0],...
            'Visible','on');
    end
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
