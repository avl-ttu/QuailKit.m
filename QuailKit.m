
% --------------------------------------------------------- Initialization

function varargout = QuailKit(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @QuailKit_OpeningFcn, ...
    'gui_OutputFcn',  @QuailKit_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function QuailKit_OpeningFcn(hObject, eventdata, handles, varargin)
handles.Path.Results='./results/';
handles.Path.Recordings = '';
handles.Path.MicData = './MicrophoneData.xlsx';
handles=SetValues(handles);
handles=SetAxis(handles,true);
handles=SetGraphics_All(handles);
handles=SetToolbar(handles);
handles=SetPlay(handles);
handles=Set12(handles,true);
handles=Set34(handles);
handles.Graphics.Credits=Credits(...
    handles.Graphics.Watermark,...
    handles.Graphics.Color,true);
handles.Graphics.Watermark=HT_Transition(...
    handles.Graphics.Watermark,{'YLim'},...
    [1-handles.Graphics.Watermark.Position(4),0],...
    handles.UserData.Frames,handles);
handles=Wait(handles,'off');
handles.Data.j=1;
handles=SetLayout(handles,handles.UserData.Frames);
handles.output = hObject;
guidata(hObject,handles);

function handles = getRecordings(handles)
    handles.One_List.String = '';
    dirs = dir(handles.Path.Recordings);
    numDirs = size(dirs,1);
    numinList = 1;
    for i = 1:numDirs
        recordingName = convertCharsToStrings(dirs(i).name);
        if recordingName ~= ".." && recordingName ~= "."
            if numinList == 1
                handles.One_List.String = recordingName;
            else
                handles.One_List.String = [handles.One_List.String; recordingName];
            end
            numinList = numinList + 1;
        end
    end

function varargout = QuailKit_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% ------------------------------------------------------- Figure Callbacks

function Fig_SizeChangedFcn(hObject, eventdata, handles)
handles=SetLayout(handles,2);
guidata(handles.Fig,handles);

function Fig_KeyReleaseFcn(hObject, eventdata, handles)
handles = HTcompute(handles);
handles=SetView(handles,false);
handles=Set12(handles,false);
guidata(handles.Fig,handles);

function Fig_KeyPressFcn(hObject, eventdata, handles)
switch eventdata.Key
    case 'rightarrow'
        handles.Data.j=min(handles.Data.j+1,length(handles.Data.Bins)-1);
    case 'leftarrow'
        handles.Data.j=max(1,handles.Data.j-1);
    case 'downarrow'
        handles.Data.j=max(1,handles.Data.j-10);
    case 'uparrow'
        handles.Data.j=min(handles.Data.j+10,length(handles.Data.Bins)-1);
end
if ismember(eventdata.Key,{'rightarrow','leftarrow','downarrow','uparrow'})
    for k=1:size(handles.Graphics.Axis,2)
        set(handles.Graphics.Axis(3,k).Children,'Visible','off');
        set(handles.Graphics.Axis(2,k).Children,'Visible','off');
    end
    set(handles.Graphics.Patch(:,:,1),'XData',handles.Data.TS.Time(...
        [handles.Data.Edges(handles.Data.j),...
        handles.Data.Edges(handles.Data.j+1),...
        handles.Data.Edges(handles.Data.j+1),...
        handles.Data.Edges(handles.Data.j)]));
    set(handles.Graphics.Axis(2,:),...
        'XLim',handles.Graphics.Patch(1).XData(1:2));
    guidata(hObject,handles);
end

% ---------------------------------------------------- GroupPlay Callbacks

function Clear_Callback(hObject, eventdata, handles)
handles.Data.j=1;
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);

function Reset_Callback(hObject, eventdata, handles)
handles=SetAxis(handles,initialize);
handles=Wait(handles,'off');
handles.Data.j=1;
handles=SetLayout(handles,handles.UserData.Frames);
handles=HTdataAccess(handles,'read');
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);gui

function Skip_Callback(hObject, eventdata, handles)
hObject.UserData=1;
if handles.Data.j<length(handles.Data.Bins)-1
    handles.Data.j=handles.Data.j+1;
else
    handles.Data.j=1;
end
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);

function Next_Callback(hObject, eventdata, handles)
hObject.UserData=1;
handles.Data.j=min(handles.Data.j+10,length(handles.Data.Bins)-1);
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);

function PlayMode_Callback(hObject, eventdata, handles)
handles.PlayMode.UserData=rem(handles.PlayMode.UserData+1,4);
handles=SetGraphics_All(handles);
handles=SetToolbar(handles);
handles=SetPlay(handles);
handles=Set34(handles);
handles=Wait(handles,'off');
handles=SetLayout(handles,handles.UserData.Frames);
guidata(hObject,handles);

function Mode_Callback(hObject, eventdata, handles)
handles.Mode.UserData=rem(handles.Mode.UserData+1,3);
handles=SetGraphics_All(handles);
handles=SetToolbar(handles);
handles=SetPlay(handles);
handles=Set34(handles);
handles=Wait(handles,'off');
handles=SetLayout(handles,handles.UserData.Frames);
guidata(hObject,handles);

function Localize_Callback(hObject, eventdata, handles)
if hObject.Value==1
    handles=Wait(handles,'on');
    hObject.Enable='on';
    audioPaths = [handles.Two_Pop.UserData{2,2}{:,3}];
    audioPaths = [fullfile(handles.Path.Recordings,string(handles.RecordingSelected),"Mics",audioPaths)];
    micDataPaths = [handles.Two_Pop.UserData{2,2}{:,3}];
    micDataPaths = split(micDataPaths,'_');
    micDataPaths = micDataPaths(:,:,1);
    micDataPaths = [fullfile(handles.Path.Recordings,string(handles.RecordingSelected),"Mics",micDataPaths+"_A_Summary.txt")];
    results = LocalizeCalls(audioPaths, micDataPaths);
    map = JRmapMake(handles.Graphics.Map,'',results, 200);
    handles.Graphics.Map.Visible='on';
else
    handles.Graphics.Map.Visible='off';
    set(handles.Graphics.Map.Children,'Visible','off');
    handles=Wait(handles,'off');
end
guidata(hObject,handles);

function Previous_Callback(hObject, eventdata, handles)
hObject.UserData=1;
handles.Data.j=max(1,handles.Data.j-10);
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);

function Back_Callback(hObject, eventdata, handles)
hObject.UserData=1;
if handles.Data.j>1
    handles.Data.j=handles.Data.j-1;
else
    handles.Data.j=length(handles.Data.Bins);
end
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);

function QueueMode_Callback(hObject, eventdata, handles)
handles.QueueMode.UserData=rem(handles.QueueMode.UserData+1,2);
handles=SetGraphics_All(handles);
handles=SetToolbar(handles);
handles=SetPlay(handles);
handles=Set34(handles);
handles=Wait(handles,'off');
handles=SetLayout(handles,handles.UserData.Frames);
guidata(hObject,handles);

function Play_Callback(hObject, eventdata, handles)
if handles.Data.Audio.isplaying
    handles.Data.Audio.pause;
elseif hObject.UserData==1
    hObject.UserData=0;
else
    hObject.UserData=1;
    hObject.CData=handles.icons.Pause;
    flag=false;
    while hObject.UserData==1
        if handles.PlayMode.UserData==0
            handles.Skip.UserData=0;
            handles.Back.UserData=0;
            hObject.UserData=0;
        else
            if flag
                if handles.Data.j<length(handles.Data.Edges)-2
                    handles.Data.j=handles.Data.j+1;
                    if handles.PlayMode.UserData==1
                        hObject.UserData=0;
                    end
                elseif handles.PlayMode.UserData==3
                    handles.Data.j=1;
                elseif handles.QueueMode.Value==1
                    Next_Callback(handles.Next, eventdata, handles);
                    handles.Skip.UserData=0;
                end
                handles=HTcompute(handles);
                handles=SetView(handles,false);
            end
        end
        if strcmp(handles.Sound.State,'on')
            handles.Data.Audio.resume;
            set(handles.Graphics.Line(1:2),'Visible','on');
            waitfor(handles.Data.Audio,'Running','off');
            set(handles.Graphics.Line(1:2),'Visible','off');
        end
        flag=true;
    end
end
hObject.UserData=0;
hObject.CData=handles.icons.Play;
guidata(hObject,handles);

% ----------------------------------------------------- Group12 Callbacks

function One_List_Callback(hObject, eventdata, handles)
handles=Wait(handles,'on');

if size(hObject.String,1) > 1
    handles.RecordingSelected = hObject.String(hObject.Value);
else
    handles.RecordingSelected = hObject.String;
end

handles = Set12(handles, true);
handles=HTdataAccess(handles,'prepare');
handles=HTdataAccess(handles,'read');
handles = SetLayout(handles, handles.UserData.Frames);
handles = HTcompute(handles);
handles=SetGraphics_All(handles);
handles = SetView(handles, false);
handles=SetToolbar(handles);
handles=SetPlay(handles);
handles=Set12(handles,false);
handles=Set34(handles);

handles=Wait(handles,'off');
guidata(hObject,handles);

function Two_List_Callback(hObject, eventdata, handles)
value=handles.Two_Pop.UserData{handles.Two_Pop.Value,2}{hObject.Value,2};
switch class(value)
    case 'logical'
        handles.Two_Slide.Value=double(value);
    case 'double'
        handles.Two_Slide.Value=value;
end
handles=Set12(handles,false);
guidata(hObject,handles);

function Two_Slide_Callback(hObject, eventdata, handles)
handles=Wait(handles,'on');
switch hObject.Style
    case 'slider'
        temp=hObject.Value;
    case 'checkbox'
        temp=logical(hObject.Value);
end
handles.Two_Pop.UserData{handles.Two_Pop.Value,2}...
    {handles.Two_List.Value,2}=temp;
handles=Set12(handles,false);
handles=SetLayout(handles,handles.UserData.Frames);
handles=HTdataAccess(handles,'read');
handles=HTcompute(handles);
handles=SetView(handles,false);
handles=SetGraphics_All(handles);
handles=SetToolbar(handles);
handles=SetPlay(handles);
handles=Set12(handles,false);
handles=Set34(handles);
handles=Wait(handles,'off');
guidata(hObject,handles);

% ------------------------------------------------------ Group45 Callbacks

function Four_Pop_Callback(hObject, eventdata, handles)
handles = Set34(handles);
handles=HTcompute(handles);
handles=SetView(handles,false);
handles=SetLayout(handles,handles.UserData.Frames);
guidata(hObject,handles);

function Four_List_Callback(hObject, eventdata, handles)
handles = Set34(handles);
value=hObject.UserData{handles.Four_Pop.Value}{2,hObject.Value};
switch class(value)
    case 'logical'
        handles.Four_Slide.Value=double(value);
    case 'double'
        handles.Four_Slide.Value=value;
end
guidata(hObject,handles);

function Four_Slide_Callback(hObject, eventdata, handles)
switch hObject.Style
    case 'slider'
        temp=hObject.Value;
    case 'checkbox'
        temp=logical(hObject.Value);
end
handles.Four_List.UserData{handles.Four_Pop.Value}...
    {2,handles.Four_List.Value}=temp;
handles = Set34(handles);
handles=SetLayout(handles,handles.UserData.Frames);
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);

function Five_Pop_Callback(hObject, eventdata, handles)
handles = Set34(handles);
handles=SetLayout(handles,handles.UserData.Frames);
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);

function Five_List_Callback(hObject, eventdata, handles)
handles = Set34(handles);
handles=SetLayout(handles,handles.UserData.Frames);
value=hObject.UserData{hObject.Value,2};
switch class(value)
    case 'logical'
        handles.Five_Slide.Value=double(value);
    case 'double'
        handles.Five_Slide.Value=value;
end
guidata(hObject,handles);

function Five_Slide_Callback(hObject, eventdata, handles)
switch hObject.Style
    case 'slider'
        temp=hObject.Value;
    case 'checkbox'
        temp=logical(hObject.Value);
end
handles.Five_List.UserData{handles.Five_List.Value,2}=temp;
handles = Set34(handles);
handles=SetLayout(handles,handles.UserData.Frames);
handles=HTcompute(handles);
handles=SetView(handles,false);
guidata(hObject,handles);

% ------------------------------------------------------ Toolbar Callbacks

function HT_OffCallback(hObject, eventdata, handles)
handles=Wait(handles,'on');
handles=SetGraphics_All(handles);
handles=SetToolbar(handles);
handles=SetPlay(handles);
handles=Set12(handles,false);
handles=Set34(handles);
handles=Wait(handles,'off');
guidata(hObject,handles);

function HT_OnCallback(hObject, eventdata, handles)
handles=Wait(handles,'on');
handles.Graphics.Watermark=...
    HT_Transition(handles.Graphics.Watermark,{'YLim'},...
    [1-handles.Graphics.Watermark.Position(4),0],...
    handles.UserData.Frames,handles);
set(handles.HT,'Enable','on');
guidata(hObject,handles);

function Zoom_ClickedCallback(hObject, eventdata, handles)
    if exist(handles.Data.TS)
        hObject=Feedback(hObject);
        drawnow
        handles.UserData.ZoomMode=rem(handles.UserData.ZoomMode+1,4);
        SetView(handles,handles.UserData.Frames);
        hObject=Feedback(hObject);
        guidata(hObject,handles);
    end

function Theme_ClickedCallback(hObject, eventdata, handles)
hObject=Feedback(hObject);
drawnow
hObject.UserData=max(1,rem(hObject.UserData+1,14));
handles=SetGraphics_All(handles);
handles=SetLayout(handles,handles.UserData.Frames);
handles=SetToolbar(handles);
guidata(hObject,handles);

function Display_ClickedCallback(hObject, eventdata, handles)
hObject=Feedback(hObject);
drawnow
handles.DisplayMode=rem(handles.DisplayMode+1,4);
handles=SetLayout(handles,handles.UserData.Frames);
hObject=Feedback(hObject);
guidata(hObject,handles);

function InvertColors_ClickedCallback(hObject, eventdata, handles)
handles=SetGraphics_All(handles);
handles=SetLayout(handles,handles.UserData.Frames);
handles=SetToolbar(handles);
guidata(hObject,handles);

function Animation_ClickedCallback(hObject, eventdata, handles)
handles=SetToolbar(handles);
guidata(hObject,handles);

function Sound_ClickedCallback(hObject, eventdata, handles)
handles=SetToolbar(handles);
guidata(hObject,handles);

function Save_ClickedCallback(hObject, eventdata, handles)
hObject=Feedback(hObject);
pause(0.5);
Feedback(hObject);
guidata(hObject,handles);

function Capture_OnCallback(hObject, eventdata, handles)
handles.UserData.HiddenFig=...
    figure('Visible','off','Position',[0,0,1008,504],'Unit','normalized');
colormap(handles.UserData.HiddenFig,handles.Graphics.Colormap);
path=[handles.Path.Results,'Videos\',handles.Data.Date,'\'];
mkdir(path);
handles.UserData.Video = VideoWriter(...
    sprintf('%s%s.mp4',...
    path,[handles.Data.Date,'.',...
    num2str(handles.Data.TS.Time(handles.Data.Edges(handles.Data.j)),...
    '_%07.2f')]));
open(handles.UserData.Video);
handles=SetToolbar(handles);
guidata(hObject,handles);

function Capture_OffCallback(hObject, eventdata, handles)
close(handles.UserData.Video);
delete(handles.UserData.HiddenFig);
handles=SetToolbar(handles);
guidata(hObject,handles);

% -------------------------------------------------------------- Functions
function handles=SetView(handles,flag)
set(handles.Fig.Children([1,2,3,4]),'Units','pixels');
set(handles.Graphics.Axis(:),'Units','pixels');
flag2=0;
if handles.Data.TS.Time(handles.Data.Edges(handles.Data.j+1))>...
        handles.Graphics.Patch(1,1,1).XData(1)
    flag2=1;
end
active=find([handles.Two_Pop.UserData{2,2}{:,2}]);
if ~flag
    set([handles.Graphics.Axis(3,active).Children],...
        'Visible','off');
end
switch handles.UserData.ZoomMode
    case 0
        Trans(1:2)=handles.Data.TS.Time([1,end]);
        Trans(3:4)=max(abs(handles.Graphics.Plot(1,1,1).YData(2:end)))*[-1,1];%workaround
        Trans(7)=0.1;
    case 1
        Trans(1:2)=...
            [handles.Data.TS.Time(handles.Data.Edges(handles.Data.j))-295,...
            handles.Data.TS.Time(handles.Data.Edges(handles.Data.j+1))+295];
        Trans(3:4)=max(abs(handles.Graphics.Plot(1,1,1).YData(round(...
            max(2,0.001*(handles.Data.Edges(handles.Data.j)-295*...
            handles.Data.fs)):...
            min(length(handles.Graphics.Plot(1,1,1).XData),...
            0.001*(handles.Data.Edges(handles.Data.j+1)+295*...
            handles.Data.fs))))))*[-1,1];%workaround
        Trans(7)=0.1;
    case 2
        Trans(1:2)=[handles.Data.TS.Time(handles.Data.Edges(handles.Data.j))-25,...
            handles.Data.TS.Time(handles.Data.Edges(handles.Data.j+1))+25];
        Trans(3:4)=max(abs(handles.Data.TS.Data(handles.Data.Edges(handles.Data.j):...
            handles.Data.Edges(handles.Data.j+1))))*[-1,1];
        Trans(7)=1;
    case 3
        Trans(1:2)=[handles.Data.TS.Time(handles.Data.Edges(handles.Data.j)),...
            handles.Data.TS.Time(handles.Data.Edges(handles.Data.j+1))];
        Trans(3:4)=max(abs(...
            handles.Data.TS.Data(handles.Data.Edges(handles.Data.j):...
            handles.Data.Edges(handles.Data.j+1))))*[-1,1];
        Trans(7)=1;
end
if ismember(handles.UserData.ZoomMode,[2,3])
    if ~flag2
        set(handles.Graphics.Patch(1,active,1),...
            'XData',handles.Data.TS.Time(...
            [handles.Data.Edges(handles.Data.j-flag2),...
            handles.Data.Edges(handles.Data.j+2-flag2),...
            handles.Data.Edges(handles.Data.j+2-flag2),...
            handles.Data.Edges(handles.Data.j-flag2)]));
        for k=active
            set(handles.Graphics.Plot(1,k,2),...
                'XData',handles.Data.TS.Time(...
                handles.Data.Edges(handles.Data.j-flag2):...
                handles.Data.Edges(handles.Data.j+2-flag2)),...
                'YData',handles.Data.TS.Data(...
                handles.Data.Edges(handles.Data.j-flag2):...
                handles.Data.Edges(handles.Data.j+2-flag2),k));
        end
    end
else
    set(handles.Graphics.Plot(1,active,2),...
        'XData',NaN,...
        'YData',NaN,...
        'ZData',NaN);
end
Trans(5:6)=handles.Data.TS.Time([handles.Data.Edges(handles.Data.j),...
    handles.Data.Edges(handles.Data.j+1)]);

Object=[handles.Graphics.Axis(1,active)',handles.Graphics.Axis(1,active)',...
    handles.Graphics.Axis(2,active)',handles.Graphics.Patch(1,active,1)'];
Prop={'XLim','YLim','XLim','FaceAlpha'};

HT_Transition(Object,Prop,Trans,1);
for k=active
    if ~flag && ~ismember(handles.UserData.ZoomMode,[2,3])
        set(handles.Graphics.Patch(1,k,1),...
            'XData',handles.Data.TS.Time(...
            [handles.Data.Edges(handles.Data.j),...
            handles.Data.Edges(handles.Data.j+1),...
            handles.Data.Edges(handles.Data.j+1),...
            handles.Data.Edges(handles.Data.j)]));
        set(handles.Graphics.Line(1,k,1),...
            'XData',handles.Data.TS.Time(...
            handles.Data.Edges(handles.Data.j))*[1,1],...
            'YData',2*handles.Data.Max*[-1,1],...
            'ZData',[0,0]);
    end
    if ismember(handles.UserData.ZoomMode,[2,3])
        set(handles.Graphics.Plot(1,k,2),...
            'XData',handles.Data.TS.Time(...
            handles.Data.Edges(handles.Data.j):...
            handles.Data.Edges(handles.Data.j+1)),...
            'YData',handles.Data.TS.Data(...
            handles.Data.Edges(handles.Data.j):...
            handles.Data.Edges(handles.Data.j+1),k),...
            'ZData',ones(handles.Data.Edges(handles.Data.j+1)-...
            handles.Data.Edges(handles.Data.j)+1,1));
    end
    if ~flag && ismember(handles.UserData.ZoomMode,[2,3])
        set(handles.Graphics.Patch(1,k,1),...
            'XData',handles.Data.TS.Time(...
            [handles.Data.Edges(handles.Data.j),...
            handles.Data.Edges(handles.Data.j+1),...
            handles.Data.Edges(handles.Data.j+1),...
            handles.Data.Edges(handles.Data.j)]));
        set(handles.Graphics.Line(1,k,1),...
            'XData',handles.Data.TS.Time(...
            handles.Data.Edges(handles.Data.j))*[1,1],...
            'YData',2*handles.Data.Max*[-1,1],...
            'ZData',[0,0]);
    end
    if handles.Four_Pop.UserData
        set(handles.Graphics.Axis(2,k),...
            'XLim',handles.Data.TS.Time(...
            [handles.Data.Edges(handles.Data.j),...
            handles.Data.Edges(handles.Data.j+1)]),...
            'YLim',handles.UserData.Freq);
        set(handles.Graphics.Line(2,k,1),...
            'YData',handles.Graphics.Axis(2,k).YLim,...
            'ZData',1+max(max(handles.Graphics.Surf(2,k,1).ZData))*[1,1]);
    end
    temp=handles.UserData.Freq(1):1000:handles.UserData.Freq(end);
    set(handles.Graphics.Axis(2,k),...
        'YTick',temp,...
        'YTickLabel',string([char(string(temp/1000)'),...
        repmat('k',length(temp),1)]));
    axis(handles.Graphics.Axis(3,k),'tight');
    for i=find([handles.Four_List.UserData{handles.Four_Pop.Value}{2,1:3}]==true)
        set([handles.Graphics.Axis(i,k).Children],'Visible','on');
    end
    guidata(handles.Fig,handles);
end

function handles=Set12(handles,initialize)
if ~isnan(initialize)
    if initialize
        set(handles.Two.Children(2:end),'Enable','off');
        handles.Two_List.String='';
    else
        Mics = handles.Two_Pop.UserData{2,2};
        for i = 1:size(Mics,1)
            handles.Two_List.String = [handles.Two_List.String; Mics{i,1}];
        end
    end
end
switch class(handles.Two_Pop.UserData{handles.Two_Pop.Value,2}...
        {handles.Two_List.Value,2})
    case 'double'
        handles.Two_Slide.Visible='on';
        handles.Two_Slide.Style='slider';
    case 'logical'
        handles.Two_Slide.Visible='on';
        handles.Two_Slide.Style='checkbox';
    otherwise
        handles.Two_Slide.Visible='off';
end

function Two_Pop_Callback(hObject, eventdata, handles)
handles=Set12(handles, true);
guidata(hObject,handles);

function handles=Set34(handles)
temp=SHfindCalls();
handles.Five_List.UserData=temp(2:end,:);
handles.Five_Pop.String{2}=temp{1,2};
Parameters=handles.Four_List.UserData{handles.Four_Pop.Value};
switch handles.Four_Pop.Value
    case 1
        set(handles.Four.Children(2:end),'Enable','off');
        handles.Four_List.String='';
    case 2
        set(handles.Four.Children,'Enable','on');
        handles.Four_List.String=cell(size(Parameters,2),1);
        for i=1:size(Parameters,2)
            switch class(Parameters{2,i})
                case {'char','string'}
                    format='%s';
                case 'logical'
                    format='%d';
                case 'double'
                    format='%0.3f';
            end
            handles.Four_List.String{i}=...
                sprintf(['%s: ',format],Parameters{1,i},Parameters{2,i});
        end
end
switch class(Parameters{2,handles.Four_List.Value})
    case 'double'
        handles.Four_Slide.Visible='on';
        handles.Four_Slide.Style='slider';
    case 'logical'
        handles.Four_Slide.Visible='on';
        handles.Four_Slide.Style='checkbox';
    otherwise
        handles.Four_Slide.Visible='off';
end

switch handles.Five_Pop.Value
    case 1
        set(handles.Five.Children(2:end),'Enable','off');
        handles.Five_List.UserData={};
        handles.Five_List.String='';
    case 2
        set(handles.Five.Children,'Enable','on');
        handles.Five_List.String=cell(size(handles.Five_List.UserData,1),1);
        for i=1:size(handles.Five_List.UserData,1)
            switch class(handles.Five_List.UserData{i,2})
                case {'char','string'}
                    format='%s';
                case 'logical'
                    format='%d';
                case 'double'
                    format='%0.3f';
            end
            handles.Five_List.String{i}=...
                sprintf(['%s: ',format],handles.Five_List.UserData{i,1},...
                handles.Five_List.UserData{i,2});
        end
end
if handles.Five_Pop.Value>1
    switch class(handles.Five_List.UserData{handles.Five_List.Value,2})
        case 'double'
            handles.Five_Slide.Visible='on';
            handles.Five_Slide.Style='slider';
        case 'logical'
            handles.Five_Slide.Visible='on';
            handles.Five_Slide.Style='checkbox';
        otherwise
            handles.Five_Slide.Visible='off';
    end
end

function handles=SetValues(handles)
handles.Four_List.UserData{2}{2,1}=false;
handles.UserData.AnnMode=0;
handles.UserData.Frames=20;
handles.UserData.ZoomMode=0;
handles.UserData.LayoutMode=0;
handles.UserData.Freq=[0,4000];
handles.UserData.Margin=5;
handles.UserData.Spacing=5;
handles.MicData = readcell(handles.Path.MicData);

function handles=SetToolbar(handles)
if strcmp(handles.Animation.State,'on')
    handles.UserData.Frames=20;
else
    handles.UserData.Frames=2;
end
handles=SetGraphics_Toolbar(handles);

function handles=SetPlay(handles)
switch handles.Mode.UserData
    case 0
        handles.UserData.LayoutMode=1;
    case 1
        handles.UserData.LayoutMode=2;
    case 2
        handles.UserData.LayoutMode=2;
end

function handles=SetLayout(handles,frames)

%Finds the microphones set inactive and active by the user
activeMics=find([handles.Two_Pop.UserData{2,2}{:,2}]);
inactiveMics=find(~[handles.Two_Pop.UserData{2,2}{:,2}]);

%Finds the displays set on by the user
activeAxes=find(...
    [handles.Four_List.UserData{handles.Four_Pop.Value}{2,:}]==true);
inactiveAxes=find(...
    [handles.Four_List.UserData{handles.Four_Pop.Value}{2,1:3}]==false);

%Sets a new property of all the objects in the vector in the first argument
%of the set invocation.
set([findobj(handles.Fig,'-depth',1,'-and','-not','Tag','Toolbar');...
    handles.Group123.Children;...
    handles.Group45.Children;...
    handles.Panel.Children],'Units','pixels');

%Width of the figure
W= handles.Fig.Position(3);
%Height of the figure
H=handles.Fig.Position(4);
%Margin
M=handles.UserData.Margin;
%Spacing
s=handles.UserData.Spacing;
%t?
t=5*M;

%Amount of buttons in Group123
nd=length(handles.Group123.Children);
%Amount of buttons in Group45
na=length(handles.Group45.Children);

if W>H
    
    h=round(H/4);
    w=round(h*200/140);
    handles.Panel.Position=[M,h+2*M,W-2*M+1,H-h-3*M+1];
    handles.Group123.Position=[w+2*M,M,(W-w-4*M+1)*nd/(na+nd),h];
    handles.Group45.Position=[sum(handles.Group123.Position([1,3]))+M,...
        M,(W-w-4*M+1)*na/(na+nd),h];
else
    w=round(W/5);
    h=round(w*140/200);
    handles.Panel.Position=[M,2*h+3*M,W-2*M+1,H-2*h-4*M+1];
    handles.Group123.Position=[w+2*M,M,W-w-3*M+1,h];
    handles.Group45.Position=[M,h+2*M,W-2*M+1,h];
end
handles.GroupPlay.Position=[M,M,w,h];
handles.One.Position=[s,s,(handles.Group123.Position(3)-(nd+1)*s)/nd,...
    handles.Group123.Position(4)-2*s];
handles.Two.Position=[sum(handles.One.Position([1,3]))+s,s,...
    (handles.Group123.Position(3)-(nd+1)*s)/nd,...
    handles.Group123.Position(4)-2*s];
handles.Four.Position=[s,s,(handles.Group45.Position(3)-(na+1)*s)/na,...
    handles.Group45.Position(4)-2*s];
handles.Five.Position=[sum(handles.Four.Position([1,3]))+s,s,...
    (handles.Group45.Position(3)-(na+1)*s)/na,...
    handles.Group45.Position(4)-2*s];
set(handles.Group45,'Visible','on');
if handles.UserData.LayoutMode==2
    set(handles.Group45,'Visible','off');
    if W>H
        handles.Panel.Position=[w+2*M,M,W-w-3*M+1,H-2*M+1];
        handles.Group123.Position=[M,h+2*M,w,H-h-3*M+1];
        handles.Two.Position=[s,s,handles.Group123.Position(3)-2*s,...
            (handles.Group123.Position(4)-(nd+1)*s)/nd];
        handles.One.Position=[s,sum(handles.Two.Position([2,4]))+s,...
            handles.Group123.Position(3)-2*s,...
            (handles.Group123.Position(4)-(nd+1)*s)/nd];
    else
        handles.Panel.Position=[M,h+2*M,W-2*M+1,H-h-3*M+1];
    end
end
x = handles.One_List.Position(1);
y = handles.One_List.Position(2);
w = handles.One_List.Position(3);
h = handles.One_List.Position(4);
handles.One_Pop.Position = [x,y+h,w,h/2];
n=frames-1;
if n>1
    a=[1,1,1;n^2,n,1;n*(n+1)*(2*n+1)/6,n*(n+1)/2,n]\[0.1;0.1;n];
    HT_Smooth=@(x,a) cumsum(a(1)*x.^2+a(2)*x+a(3));
else
    a=[1,1,1];
    HT_Smooth=@(x,a) x;
end
m=length(activeAxes);
l=length(activeMics);
temp=handles.Graphics.Axis(activeAxes,activeMics)';
Start=cat(1,temp.Position);
End=repmat([t,t,handles.Panel.Position(3:4)-2*t],l*m,1);
End(:,4)=(handles.Panel.Position(4)-(m+1)*t)/(l*m);
m=1;
l=1;
for i=activeAxes
    for k=activeMics
        End(l,2)=handles.Panel.Position(4)-l*End(l,4)-m*t;
        l=l+1;
    end
    m=m+1;
end
Step=(End-Start)/n;

%if max(Step(:))<1
%    n=1;
%    Step=(End-Start)/n;
%end

Path=(repmat(permute(Start,[3,2,1]),n,1,1)+...
    permute(Step,[3,2,1]).*HT_Smooth((1:n)',a));
for i=inactiveAxes
    set([handles.Graphics.Axis(i,:);...
        handles.Graphics.Axis(i,:).Children],'Visible','off');
end
set([reshape(handles.Graphics.Axis(:,inactiveMics),[],1);...
    cat(1,handles.Graphics.Axis(:,inactiveMics).Children)],...
    'Visible','off');
set(handles.Graphics.Watermark,'Position',handles.Panel.Position);
handles.Graphics.Map.Position=[0,0,handles.Panel.Position(3),handles.Panel.Position(4)];
handles.Graphics.Credits=...
    Credits(handles.Graphics.Watermark,handles.Graphics.Color,false);



for l=1:size(Path,1)
    j=1;
    for i=activeAxes
        for k=activeMics
            set(handles.Graphics.Axis(i,k),'Position',Path(l,:,j));
            j=j+1;
        end
    end
    drawnow;
end
for i=activeAxes
    set([handles.Graphics.Axis(i,activeMics);...
        handles.Graphics.Axis(i,activeMics).Children],'Visible','on');
end

function handles=SetAxis(handles,initialize)
if initialize
    delete(handles.Panel.Children);
    for k=1:size(handles.Two_Pop.UserData{2,2},1)
        handles.Graphics.Axis(1,k)=axes(handles.Panel,'Box','on');
        handles.Graphics.Axis(2,k)=axes(handles.Panel,'Box','on');
        handles.Graphics.Axis(3,k)=axes(handles.Panel,'Box','on');
        handles.Graphics.Watermark=axes(handles.Panel,'Color','none','XColor',...
            'none','YColor','none',...
            'XTick',[],'YTick',[],'Units','pixels','NextPlot','add');
        handles.Graphics.Map=axes(handles.Panel,'Color','none','XColor',...
            'none','YColor','none',...
            'XTick',[],'YTick',[],'Units','pixels','NextPlot','add');        
        set(handles.Graphics.Axis(:),'NextPlot','add');
        for i=1:size(handles.Graphics.Axis,1)
            handles.Graphics.Plot(i,k,1)=...
                plot(handles.Graphics.Axis(i,k),NaN(1,2),NaN(1,2));
            handles.Graphics.Plot(i,k,2)=...
                plot(handles.Graphics.Axis(i,k),NaN(1,2),NaN(1,2),...
                'Color','r','LineWidth',1);
            handles.Graphics.Scatter(i,k,1)=...
                scatter(handles.Graphics.Axis(i,k),NaN(1,2),NaN(1,2),'s');
            handles.Graphics.Scatter(i,k,2)=...
                scatter(handles.Graphics.Axis(i,k),NaN(1,2),NaN(1,2),...
                'MarkerFaceColor','r');
            handles.Graphics.Surf(i,k,1)=...
                surf(handles.Graphics.Axis(i,k),NaN(1,2),NaN(1,2),NaN(2,2),...
                'EdgeColor','none');
            handles.Graphics.Surf(i,k,2)=...
                surf(handles.Graphics.Axis(i,k),NaN(1,2),NaN(1,2),NaN(2,2),...
                'EdgeColor','none','FaceColor','interp','FaceAlpha','interp');
            handles.Graphics.Surf(i,k,3)=...
                surf(handles.Graphics.Axis(i,k),NaN(1,2),NaN(1,2),NaN(2,2),...
                'EdgeColor','none','FaceColor','interp','FaceAlpha','interp');
            handles.Graphics.Patch(i,k,1)=...
                fill(handles.Graphics.Axis(i,k),NaN,NaN,'k',...
                'FaceAlpha',0.1,'EdgeAlpha',1);
            handles.Graphics.Line(i,k,1)=...
                line(handles.Graphics.Axis(i,k),NaN(1,2),NaN(1,2),NaN(1,2),...
                'LineWidth',1,'Visible','off');
        end
        set(handles.Graphics.Axis(:),'Visible','off','XMinorTick','on',...
            'YMinorTick','on','YTickLabel',[],...
            'NextPlot','replacechildren',...
            'GridLineStyle','none','View',[0,90],...
            'Color',1*[1,1,1],'FontSize',8);
        axis(handles.Graphics.Axis(3,k),'tight')
        set(handles.Graphics.Axis(3,k),'XTick',[],'YTick',-1:0.5:1,...
            'YLim',[-1,1],'YTickLabelMode','auto');
        set(handles.Graphics.Plot(1,k,2),'Color',[1,1,1]);
    end
else
    set(handles.Graphics.Plot(:),'XData',NaN,'YData',NaN);
    set(handles.Graphics.Scatter(:),'XData',NaN,'YData',NaN);
    set(handles.Graphics.Surf(:),...
        'XData',NaN(1,2),'YData',NaN(1,2),'ZData',NaN(2,2));
    set(handles.Graphics.Patch(:),'XData',NaN,'YData',NaN);
    set(handles.Graphics.Line(:),...
        'XData',NaN,'YData',NaN,'ZData',NaN);
end

function handles=Wait(handles,state)
h=repmat(handles.Graphics.Watermark,1,2);
switch state
    case 'on'
        handles=Lock(handles,'on');
        handles.Graphics.Credits.Visible='on';
        h=HT_Transition(h,{'XLim','YLim'},...
            [round([1,h(1).Position(3),1,...
            h(1).Position(4)])],handles.UserData.Frames,handles);
        handles.Graphics.Watermark=h(1);
    case 'off'
        h=HT_Transition(h,{'XLim','YLim'},...
            round([h(1).Position(3)/2+[-20,-18],...
            h(1).Position(4)/2+[18,20]]),handles.UserData.Frames,handles);
        handles.Graphics.Watermark=h(1);
        handles.Graphics.Credits.Visible='off';
        handles=Lock(handles,'off');
end

function handles=Lock(handles,state)
switch state
    case 'on'
        h=findobj(handles.Fig,...
            {'Enable','on','-and','-not','Parent',handles.Toolbar});
        set(h,'Enable','inactive');
        h=findobj(handles.Fig,...
            {'Enable','on','-and','Parent',handles.Toolbar});
        set(h,'Enable','off');
    case 'off'
        h=findobj(handles.Fig,{'Enable','inactive'});
        set(h,'Enable','on');
        h=findobj(handles.Fig,...
            {'Visible','on','-and','Parent',handles.Toolbar});
        set(h,'Enable','on');
end

function handles=SetTheme(handles)
colormaps={'parula','jet','hsv','hot','cool','spring','summer','autumn',...
    'winter','gray','bone','copper','pink'};
if strcmp(handles.InvertColors.State,'on')
    temp1='handles.Graphics.Colormap=flipud(';
    temp2=');';
else
    temp1='handles.Graphics.Colormap=';
    temp2=';';
end
eval([temp1,char(colormaps{handles.Theme.UserData}),temp2]);
handles.Theme.TooltipString=['Theme (',...
    char(colormaps(handles.Theme.UserData)),')'];
handles.Graphics.Color=handles.Graphics.Colormap(32,:)/...
    (3*max(handles.Graphics.Colormap(32,:)));
handles.icons=handles.Fig.UserData;
temp=fieldnames(handles.icons);
for i=1:length(temp)
    handles.icons.(char(temp(i)))(:,:,1:3:end)=...
        handles.icons.(char(temp(i)))(:,:,1:3:end)*...
        handles.Graphics.Color(1);
    handles.icons.(char(temp(i)))(:,:,2:3:end)=...
        handles.icons.(char(temp(i)))(:,:,2:3:end)*...
        handles.Graphics.Color(2);
    handles.icons.(char(temp(i)))(:,:,3:3:end)=...
        handles.icons.(char(temp(i)))(:,:,3:3:end)*...
        handles.Graphics.Color(3);
end

function handles=SetGraphics_Toolbar(handles,varargin)
handles=SetTheme(handles);
Buttons={'Animation','InvertColors','Sound','Capture'};
for j=1:length(Buttons)
    if strcmp(handles.(Buttons{j}).State,'off')
        handles.(Buttons{j}).CData=handles.icons.(Buttons{j});
    else
        handles.(Buttons{j}).CData=Feedback(handles.icons.(Buttons{j}));
    end
end
handles.HT.CData=handles.icons.HT;
handles.Save.CData=handles.icons.Save;
handles.Display.CData=handles.icons.Display;
handles.Zoom.CData=handles.icons.Zoom;
handles.Theme.CData=handles.icons.Theme;

function handles=SetGraphics_GroupPlay(handles,varargin)
handles=SetTheme(handles);
handles.Play.CData=handles.icons.Play;
handles.Back.CData=handles.icons.Left;
handles.Skip.CData=handles.icons.Right;
handles.Next.CData=handles.icons.Next;
handles.Previous.CData=handles.icons.Previous;
handles.QueueMode.CData=handles.icons.QueueMode;
handles.Reset.CData=handles.icons.Reset;
handles.Clear.CData=handles.icons.Clear;
handles.PlayMode.CData=...
    handles.icons.PlayMode(:,:,3*handles.PlayMode.UserData+(1:3));
handles.Mode.CData=...
    handles.icons.Mode(:,:,3*handles.Mode.UserData+(1:3));
handles.Localize.CData=...
    handles.icons.Localize(:,:,3*handles.Localize.UserData+(1:3));

function handles=SetGraphics_All(handles,varargin)
handles=SetTheme(handles);
handles=SetGraphics_Toolbar(handles);
handles=SetGraphics_GroupPlay(handles);
for i=1:length(handles.Group45.Children)
    set(handles.Group45.Children(i).Children,...
        'ForegroundColor',handles.Graphics.Color);
end
for i=1:length(handles.Group123.Children)
    set(handles.Group123.Children(i).Children,...
        'ForegroundColor',handles.Graphics.Color);
end
set(handles.Graphics.Plot(:,:,1),'Color',handles.Graphics.Color);
set(handles.Graphics.Plot(1,:,2),...
    'Color',handles.Graphics.Colormap(32,:));
set(handles.Graphics.Scatter(3,:,1),...
    'MarkerEdgeColor',handles.Graphics.Color);
set(handles.Graphics.Line(:),'Color',handles.Graphics.Color);
set(handles.Graphics.Line(3,:,:),'Color','r');
set(handles.Graphics.Patch(:),'FaceColor',handles.Graphics.Color,...
    'EdgeColor',handles.Graphics.Color);
colormap(handles.Fig,handles.Graphics.Colormap);

function Object=Feedback(Object)
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
end

function p=Credits(h,color,initialize)
a=0.98;
b=0.98;
set(h,...
    'Position',[1,1,h.Position([3,4])],...
    'XLim',[1,h.Position(3)],...
    'YLim',[1,h.Position(4)]);
s=round(h.Position(3:4));

alpha=a*ones(2*s(2)+1,s(1));
cdata=uint8(ones(2*s(2)+1,s(1),3));
logo=h.Parent.Parent.UserData.TTU_COA;
logo=imresize(logo,0.5*min(s)/ceil(max(size(logo))),'bilinear');
logo=flipud(logo);
m=size(logo(:,:,1));
corner=round((flip(s)-size(logo(:,:,1)))/2-[0.33*s(2),0]);
alpha(1+corner(1):m(1)+corner(1),1+corner(2):m(2)+corner(2))=logo(:,:,4);
cdata(1+corner(1):m(1)+corner(1),1+corner(2):m(2)+corner(2),:)=...
    logo(:,:,1:3);
for i=1:3
    temp=cdata(:,:,i);
    temp(alpha==0 | temp==1)=color(i)*255;
    cdata(:,:,i)=temp;
end

alpha(alpha==0)=a;
logo=h.Parent.Parent.UserData.Quail_Big;
logo=imresize(logo,1/ceil(max(size(logo))/min(s)),'bilinear');
logo=flipud(logo);
m=size(logo(:,:,1));
corner=round((flip(s)-size(logo(:,:,1)))/2+[s(2),0]);
alpha(1+corner(1):m(1)+corner(1),1+corner(2):m(2)+corner(2))=...
    b*double(logo(:,:,4));
alpha(alpha==0)=1;
cdata(1+corner(1):m(1)+corner(1),1+corner(2):m(2)+corner(2),:)=...
    logo(:,:,1:3);
for i=1:3
    temp=cdata(:,:,i);
    temp(alpha==b | temp==1)=color(i)*255;
    cdata(:,:,i)=temp;
end
alpha=im2double(alpha);
cdata=im2double(cdata);
if initialize
    delete(h.Children);
    p=surf(h,...
        'XData',1:s(1),...
        'YData',-s(2):s(2),...
        'ZData',ones(2*s(2)+1,s(1)),...
        'CData',cdata,...
        'AlphaData',alpha,...
        'FaceAlpha','flat',...
        'FaceColor','flat',...
        'EdgeAlpha',0,...
        'AlphaDataMapping','none','Visible','on');
    text(h,1,1,sprintf('%s\n',...
        'Quail Kit',' ',' ',' ',' ',' ',' ',...
        'Supervisor'),'FontUnits','normalized',...
        'FontWeight','normal','Color',[1,1,1],...
        'HorizontalAlignment','center');
    text(h,1,1,sprintf('%s\n',...
        ' ',' ',' ','Hanif Tiznobake',...
        'Stephen Huang', 'Golnaz Moallem', 'Joel Reznick',' ',' ',' ',...
        'Hamed Sari-Sarraf'),'FontUnits','normalized',...
        'FontWeight','bold','Color',[1,1,1],...
        'HorizontalAlignment','center');
else
    p=h.Children(end);
    set(p,...
        'XData',1:s(1),...
        'YData',-s(2):s(2),...
        'ZData',ones(2*s(2)+1,s(1)),...
        'CData',cdata,...
        'AlphaData',alpha,...
        'FaceAlpha','flat',...
        'FaceColor','flat',...
        'EdgeAlpha',0,...
        'AlphaDataMapping','none');
end
h.Children(1).Position(1:2)=[mean(p.XData),0.5*p.YData(1)];
h.Children(2).Position(1:2)=[mean(p.XData),0.5*p.YData(1)];


function One_Slide_Callback(hObject, eventdata, handles)
    handles.Path.Recordings = [uigetdir(userpath,'Select Recordings Folder'),'\'];
    handles = getRecordings(handles);
    guidata(handles.Fig,handles);
