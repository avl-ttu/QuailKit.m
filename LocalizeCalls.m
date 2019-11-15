function estimatedLocs = LocalizeCalls(calls,summaryData)
    %% Initialization
    % Microphone Locations
    mLoc = [];
%     mLoc = [33.421955 -100.885673 0 40;...
%         33.421947 -100.886211 0 40;...
%         33.421496 -100.886201 0 40;...
%         33.421505 -100.885663 0 40];

    for i = 1: size(summaryData,2)
        micData = readtable(summaryData(i));
        temp = []
        if char(micData{2,4}) == 'N'
            temp(1) = mean(micData{:,3});
        else
            temp(1) = - mean(micData{:,3});
        end
        if char(micData{2,6}) == 'E'
            temp(2) =  mean(micData{:,5});
        else
            temp(2) = - mean(micData{:,5});
        end
        temp(3) = 0;
        temp(4) =  mean(micData{:,9});
        mLoc = [mLoc; temp];
    end
    
    Template = load('Template_291');
    Template = Template.Template_291;
    F=0:10:4000;Thresh = 0.296;Distance = 0.725;DoublePass = false;
    window_size = 0.03; scale=0.08; overlap=0.8; freqs=[0,4000,10];doublepass=false;
    locRate = (1.44e7)/2;
    estimatedLocs = [];
    
    %% Read All Mics Recordings
    [audioA,Fs]=audioread(calls(1));
    [audioB,~]=audioread(calls(2));
    [audioC,~]=audioread(calls(3));
    [audioD,~]=audioread(calls(4));

    %% Obtain Spectrograms
    window = Fs*window_size; 
    i = 1;
    while true
        if (i*locRate - (i-1)*Fs) <= size(audioA,1)
            if (i-1) == 0
                [sA, ~, tA] = spectrogram(audioA(1:locRate,1), window ,round(overlap*window), F, Fs);
                [sB, ~, tB] = spectrogram(audioB(1:locRate,1), window ,round(overlap*window), F, Fs);
                [sC, ~, tC] = spectrogram(audioC(1:locRate,1), window ,round(overlap*window), F, Fs);
                [sD, ~, tD] = spectrogram(audioD(1:locRate,1), window ,round(overlap*window), F, Fs);
            else
                [sA, ~, tA] = spectrogram(audioA((i - 1)*(locRate - Fs):(i*locRate - (i-1)*Fs),1), window ,round(overlap*window), F, Fs);
                [sB, ~, tB] = spectrogram(audioB((i - 1)*(locRate - Fs):(i*locRate - (i-1)*Fs),1), window ,round(overlap*window), F, Fs);
                [sC, ~, tC] = spectrogram(audioC((i - 1)*(locRate - Fs):(i*locRate - (i-1)*Fs),1), window ,round(overlap*window), F, Fs);
                [sD, ~, tD] = spectrogram(audioD((i - 1)*(locRate - Fs):(i*locRate - (i-1)*Fs),1), window ,round(overlap*window), F, Fs);
            end
        else
            [sA, ~, tA] = spectrogram(audioA((i - 1)*(locRate - Fs):end,1), window ,round(overlap*window), F, Fs);
            [sB, ~, tB] = spectrogram(audioB((i - 1)*(locRate - Fs):end,1), window ,round(overlap*window), F, Fs);
            [sC, ~, tC] = spectrogram(audioC((i - 1)*(locRate - Fs):end,1), window ,round(overlap*window), F, Fs);
            [sD, ~, tD] = spectrogram(audioD((i - 1)*(locRate - Fs):end,1), window ,round(overlap*window), F, Fs);
        end
        
        sA=db(abs(sA));
        sB=db(abs(sB));
        sC=db(abs(sC));
        sD=db(abs(sD));

        %% Detect Calls

        [CallsA,~,~] = SH_FindCalls(sA,tA,F,Template,Thresh,Distance,DoublePass,[]);
        [CallsB,~,~] = SH_FindCalls(sB,tB,F,Template,Thresh,Distance,DoublePass,[]);
        [CallsC,~,~] = SH_FindCalls(sC,tC,F,Template,Thresh,Distance,DoublePass,[]);
        [CallsD,~,~] = SH_FindCalls(sD,tD,F,Template,Thresh,Distance,DoublePass,[]);
        mADETStart=CallsA(:,1);
        mBDETStart=CallsB(:,1);
        mCDETStart=CallsC(:,1);
        mDDETStart=CallsD(:,1);

        %% Read Annotation File
        % [mAANNStart, mBANNStart, mCANNStart, mDANNStart] = getData("11_00_annotation", 1, 'start');

        %% Find Matched Calls
        [lagMatrix, matchedMatrixDETStart] = findMatches(mADETStart, mBDETStart, mCDETStart, mDDETStart);
        %[~,matchedMatrixANNStart] = findMatches(mAANNStart, mBANNStart, mCANNStart, mDANNStart);

        %% Localize Calls
        Num_Calls=size(matchedMatrixDETStart,2);
        tempMLoc = mLoc; 
        if Num_Calls > 0
            estimatedLocs2 = zeros(1,4);
            i = 1;
            j = 1;
            while (j < Num_Calls)
                indCond = find(lagMatrix(:,j) == 0);
                mLoc(:,3) = lagMatrix(:, j);
                if size(indCond,1) > 1
                    mLoc(indCond,:) = [];
                end
                if (sum(lagMatrix(:, i)==0)<2)
                    [location] = HT_Localizer(mLoc);
                    if (~isempty(location))
                        estimatedLocs2(i,:) = location(1,:);
                        i = i + 1;
                    end
                end
                j = j + 1;
                mLoc = tempMLoc;
            end
            estimatedLocs = [estimatedLocs; estimatedLocs2];
        end
        if (i*locRate - (i-1)*Fs) <= size(audioA,1)
            i = i + 1;
        else
            break;
        end
    end
end

%% Functions
function [mA, mB, mC, mD] = getData(filename, sheet, set)

    %Excel for ease
    xLData = xlsread(filename+".xlsx", sheet);
    if (strcmp(set, 'end'))
        i = 1;
    else
        i = 0;
    end
    mA = removeNaNSpots(xLData(:,1+i));
    mB = removeNaNSpots(xLData(:,2+i));
    mC = removeNaNSpots(xLData(:,3+i));
    mD = removeNaNSpots(xLData(:,4+i));
end

function mA = removeNaNSpots(mA)
    nanSpots = find(isnan(mA) == 1);
    for i=1:length(nanSpots)
        mA(nanSpots(1)) = [];
    end
end

function [lagMatrix, matchedMatrix] = findMatches(mA,mB,mC, mD)

maxTDistance=0.2;
matchedMatrix = [];
lagMatrix=[];
i = 1;

while (i <= length(mA) && i <= length(mB) && i <= length(mC) && i <= length(mD))
    A=mA(i);
    if sum(abs(mB-A)<maxTDistance)>0 && sum(abs(mC-A)<maxTDistance)>0 && sum(abs(mD-A)<maxTDistance)>0
        B=min(mB(abs(mB-A)<maxTDistance));
        C=min(mC(abs(mC-A)<maxTDistance));
        D=min(mD(abs(mD-A)<maxTDistance));
        columnN = [A; B; C; D];
        if (A == B && B == C && C == D && A == 0)% Can include more logic based on nessesity.
            continue;
        else
            matchedMatrix = [matchedMatrix columnN];
            lagMatrix = [lagMatrix columnN - min(columnN)];
        end 
    end
   
    i = i+1;
end
matchedMatrix( :, ~any(matchedMatrix,1) ) = [];
lagMatrix( :, ~any(lagMatrix,1) ) = [];
end


function [TP, FP, FN] = compareData(DET, ANN)
    %find TP
    TP = 0;
    FN = 0;
    FP = 0;
    for incJ = 1:length(ANN)
        mTable = abs(DET-ANN(incJ));
        ref = min(mTable);
        if ref < 0.3
            TP = TP + 1;
        end
    end

    FP = length(DET) - TP;
    FN = length(ANN) - TP;
end
