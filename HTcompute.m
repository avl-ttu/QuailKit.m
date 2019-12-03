function handles=HT_Compute(handles)
handles.Data.Audio=audioplayer(handles.Data.TS.Data(...
    handles.Data.Edges(handles.Data.j):...
    handles.Data.Edges(handles.Data.j+1),1),handles.Data.fs); %workaround
handles.Data.Audio.TimerFcn={@TimerFcn, handles};
handles.Data.Audio.TimerPeriod=0.05;
handles.Data.F=handles.UserData.Freq(1):10:handles.UserData.Freq(2);
n=round(0.1*handles.Four_List.UserData{handles.Four_Pop.Value}{2,4}*handles.Data.fs);
Mics=handles.MicDataInfo{2,2};
activeMics=find([Mics{:,2}]);
for k=activeMics
        if handles.Five_Pop.Value>1
            Template=importdata('Template_291.mat');
            GT = getGT(handles,k)
            Calls = SHfindCalls(...
                handles.Data.TS.Data(handles.Data.Edges(handles.Data.j):...
                handles.Data.Edges(handles.Data.j+1),k),...
                handles.Data.F,handles.Data.fs,...
                handles.Data.TS.Time(handles.Data.Edges(handles.Data.j)),...
                n,Template,...
                handles.Five_List.UserData{3,2},...
                handles.Five_List.UserData{2,2},...
                handles.Five_List.UserData{4,2},...
                [handles.Graphics.Surf(2,k,1),...
                handles.Graphics.Surf(2,k,2),...
                handles.Graphics.Plot(3,k,1),...
                handles.Graphics.Plot(3,k,1),...
                handles.Graphics.Scatter(3,k,2),...
                handles.Graphics.Line(3,k)], GT);

%             l=size(Calls,1);
%             for i = 1:l
%                 HT_DataAccess(handles,'query',...
%                     ['insert into audio_detection([audio_id], [start], [end], [low], [high]) ',...
%                      'values (''',char(string(Mics{k,4})),...
%                      ''', ''',datestr(milliseconds(Calls(i,1)*1000)+handles.Data.Date,'yyyy-mm-ddTHH:MM:SS.FFF'),''', ''',datestr(milliseconds(Calls(i,2)*1000)+handles.Data.Date,'yyyy-mm-ddTHH:MM:SS.FFF'),...
%                      ''', ',char(string(Calls(i,3))),', ',char(string(Calls(i,4))),')'],'cellarray');
%             end

        elseif handles.Four_Pop.Value>1
            [handles.Data.S(:,:,k),handles.Data.t(k,:)]=HTspectrogram(...
                handles.Data.TS.Data(handles.Data.Edges(handles.Data.j):...
                handles.Data.Edges(handles.Data.j+1),k),n,...
                handles.Data.F,...
                handles.Data.fs,...
                handles.Data.TS.Time(handles.Data.Edges(handles.Data.j)),...
                handles.Graphics.Surf(2,k,1));
        end
%         Ann = HTdataAccess(handles,'query',...
%                     ['SELECT * ',...
%                      'FROM Annotations ',...
%                      'WHERE [DateTime] = #', handles.Data.Date,'#',...
%                      ' AND [Channel ID] IN (',sprintf('%d, ',Mics{[Mics{:,2}],1}),')',...
%                      ' AND [Start Time] >=', char(string(handles.Data.t(k,1))),...
%                      ' AND [End Time] <=', char(string(handles.Data.t(k,end))),...
%                      ' AND [Created By] = ''23'''],'table');
%         HT_BBPlot(handles.Data.t(k,:),handles.Data.F,handles.Data.S(:,:,k),...
%             Ann,handles.Graphics.Surf(2,k,2),[0,0,0],...
%             handles.Five_Pop.Value==1);
end
HTdataAccess(handles,'write');

function TimerFcn(audio,~,handles)
set(handles.Graphics.Line(1:2),'XData',handles.Data.TS.Time(handles.Data.Edges(handles.Data.j)+...
    audio.CurrentSample*[1,1]));
guidata(handles.Fig,handles);