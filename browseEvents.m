% USAGE:
%    mtxModifiedEvents = browseEvents(objNeuralData, cellEvents)
%
% DESCRIPTION:
%    Browse (and modify) the supplied list of events
%
% ARGUMENTS:
%    objNeuralData
%       A `NeuralData` object on which `setCurrentChannels` has been called
%    cellEvents
%       A vector cell array of `Event` objects. This must be nonempty.
%
% RETURNS:
%    cellModifiedEvents
%       A vector cell array of `Event` objects containing the list of
%       events once the GUI has been closed
function varargout = browseEvents(varargin)
    % Edit the above text to modify the response to help browseEvents

    % Last Modified by GUIDE v2.5 14-Jul-2014 17:39:24

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 0;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @browseEvents_OpeningFcn, ...
                       'gui_OutputFcn',  @browseEvents_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
end
% End initialization code - DO NOT EDIT

function updateGui(handles)
    % Retrive the event times and the time window to use when displaying the
    % event.
    vEventWindow = getWindow(handles.cellEvents{handles.nCurrentEvent});
    vTimeWindow = getTimeWindow(handles);

    % Plot the main ripple events over the LFP-triple.
    cla(handles.axEvent);
    objLocalLfps = subseries(handles.objLfps, vTimeWindow(1), vTimeWindow(2));
    plot(handles.axEvent, objLocalLfps.Time, objLocalLfps.Data);

    % Set plot niceties.
    axes(handles.axEvent);
    set(handles.axEvent, 'Layer', 'top');
    legend('Main', 'Low', 'High');
    % title(['LFPs and Ripple Event ' num2str(handles.nCurrentEvent)]);
    ylabel('');
    xlabel(handles.axEvent, 'Time (seconds)');
    xlim(vTimeWindow);
    set(handles.axEvent, 'Color', [1, 1, 1]);

    PlotIntervals(vEventWindow, 'rectangles');

    axes(handles.axSpikes);
    evtWindow = getEvent(handles.objNeuralData, vTimeWindow);
    plot(evtWindow, 'vOrdering', orderCells(evtWindow));
    set(handles.axEvent, 'Layer', 'top');
    set(handles.axEvent, 'Color', [1, 1, 1]);
    PlotIntervals(vEventWindow, 'rectangles');

    % % For each of the provided orderings, create plots of the associated spike
    % % trains and activity patterns.
    % for i = 1 : length(cellOrderings)
    %     % Retrieve the current ordering and intersect those cells with
    %     % the provided `neuronSet`.
    %     ordering = cellOrderings{i};
    %     orderingDesc = 'Spike Raster';
    %
    %     if isa(ordering, 'cell')
    %         orderingDesc = ordering{2};
    %         ordering = ordering{1};
    %     end
    %
    %     [ordering, ~, idxs] = intersect(ordering, neuronSet, 'stable');
    %
    %     % Plot the spike trains.
    %     vSubplotLocs = i * nPlotCols + (1 : nPlotCols);
    %     h(i + 1) = subplot(nPlotRows, nPlotCols, vSubplotLocs);
    %     plotSpikeTrains(spikeTrains, ripple([1, 3]), ordering, colors);
    %     title(orderingDesc);
    % end

    % % Set the window's title.
    % speed = this.Track.speed_MMsec(round(ripple(2) * sampleRate(this)));
    % set(gcf, 'name', ...
    %     ['----------Ripple ' num2str(nRipple) '----------' ...
    %      'Speed: ' num2str(speed) ' mm/sec----------' ...
    %      'Width: ' num2str((ripple(3) - ripple(1)) * 1000) ' ms----------']);

    % set(h(end), 'XTickLabelMode', 'auto')
    % xlabel(h(end), 'Time (seconds)');
end

function vWindow = getTimeWindow(handles)
    % Get the current event.
    vEventWindow = getWindow(handles.cellEvents{handles.nCurrentEvent});

    % Retrieve the user-set, padding-related information.
    strEventPadding = get(handles.tbxEventPadding, 'String');
    cellPaddingUnitOptions = get(handles.pbxEventPaddingUnits, 'String');
    strEventPaddingUnits = cellPaddingUnitOptions{ ...
        get(handles.pbxEventPaddingUnits, 'Value')};

    dEventPadding = str2double(strEventPadding);

    switch strEventPaddingUnits
      case '%'
        dEventDuration = diff(vEventWindow);
        dPadding = (dEventPadding / 100) * dEventDuration;
      case 'ms'
        dPadding = dEventPadding / 1000;
      case 's'
        dPadding = dEventPadding;
      case 'total (ms)'
        dPadding = (dEventPadding / 1000 - diff(vEventWindow)) / 2;
    end

    % Now that we have the padding, we can compute the time window.
    vWindow = vEventWindow + [-dPadding, dPadding];
end

function selectEvent(handles, nEvent)
    % Select the provided event, rounding to the appropriate range.
    nNumEvents = length(handles.cellEvents);
    handles.nCurrentEvent = max(1, min(nNumEvents, nEvent));

    % Display which event we're currently viewing.
    set(handles.lblCurrentEvent, 'String', ...
        ['Viewing ' num2str(handles.nCurrentEvent) ' of ' num2str(nNumEvents)]);

    % Make sure that we update the handles object, and then update the GUI.
    guidata(handles.figure1, handles)
    updateGui(handles);
end

function selectNextEvent(handles)
    % Make sure that we select an event in the range.
    nNumEvents = length(handles.cellEvents);
    nCurrentEvent = handles.nCurrentEvent;

    if nCurrentEvent == nNumEvents
        selectEvent(handles, 1);
    else
        selectEvent(handles, nCurrentEvent + 1);
    end
end

function selectPreviousEvent(handles)
    % Make sure that we select an event in the range.
    nNumEvents = length(handles.cellEvents);
    nCurrentEvent = handles.nCurrentEvent;

    if nCurrentEvent == 1
        selectEvent(handles, nNumEvents);
    else
        selectEvent(handles, nCurrentEvent - 1);
    end
end

% --- Executes just before browseEvents is made visible.
function browseEvents_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to browseEvents (see VARARGIN)

    % The first input parameter should be a `NeuralData` object.
    handles.objNeuralData = varargin{1};

    % The second parameter should be a list of events, either as a 2-column
    % matrix of event times or as a cell array of events.
    cellEvents = varargin{2};
    handles.cellEvents = cellEvents;

    % Store the LFPs for this data set. Downsample them to 1250 Hz, and
    % center them (individually) locally at zero.
    handles.objLfps = getLfps(handles.objNeuralData);
    handles.objLfps = TimeSeries(downsample(handles.objLfps.Data, 16), ...
                                 downsample(handles.objLfps.Time, 16));
    nFilterLength = 0.5 * sampleRate(handles.objNeuralData);

    for i = 1 : 3
        vLfp = handles.objLfps.Data(:, i);
        handles.objLfps.Data(:, i) = vLfp - localmean(vLfp, nFilterLength);
    end

    % Ensure that the list of `Event`s is a non-empty list of `Event`s.
    assert(~isempty(handles.cellEvents) && isa(handles.cellEvents{1}, 'Event'), ...
           ['browseEvents: second argument must be a non-empty list of `Event` ' ...
            'objects. See `help browseEvents` for more information.']);

    % Initially, we want to display the first event.
    handles.nCurrentEvent = 1;

    % We also want to know where spikes happen and what the GUI should output.
    handles.cellTrains = getSpikeTrains(handles.objNeuralData);
    handles.output = hObject;

    % Update the `handles` structure for access elsewhere in the GUI.
    guidata(hObject, handles);

    % Update the display.
    updateGui(handles);

    % UIWAIT makes browseEvents wait for user response (see UIRESUME)
    uiwait(handles.figure1);
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: delete(hObject) closes the figure
    if isequal(get(hObject, 'waitstatus'), 'waiting')
        % The GUI is still in UIWAIT, us UIRESUME
        uiresume(hObject);
    else
        % The GUI is no longer waiting, just close it
        delete(hObject);
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = browseEvents_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.figure1;

    % The figure can be deleted now
    %delete(handles.figure1);
end

function tbxEventPadding_Callback(hObject, eventdata, handles)
    % hObject    handle to tbxEventPadding (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of tbxEventPadding as text
    %        str2double(get(hObject,'String')) returns contents of tbxEventPadding as a double
    updateGui(handles);
end

% --- Executes during object creation, after setting all properties.
function tbxEventPadding_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to tbxEventPadding (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on selection change in pbxEventPaddingUnits.
function pbxEventPaddingUnits_Callback(hObject, eventdata, handles)
    % hObject    handle to pbxEventPaddingUnits (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns pbxEventPaddingUnits contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from pbxEventPaddingUnits
    updateGui(handles);
end

% --- Executes during object creation, after setting all properties.
function pbxEventPaddingUnits_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to pbxEventPaddingUnits (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in btnPreviousEvent.
function btnPreviousEvent_Callback(hObject, eventdata, handles)
    % hObject    handle to btnPreviousEvent (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    selectPreviousEvent(handles);
end

% --- Executes on button press in btnNextEvent.
function btnNextEvent_Callback(hObject, eventdata, handles)
    % hObject    handle to btnNextEvent (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    selectNextEvent(handles);
end

function tbxJumpToEvent_Callback(hObject, eventdata, handles)
    % hObject    handle to tbxJumpToEvent (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of tbxJumpToEvent as text
    %        str2double(get(hObject,'String')) returns contents of tbxJumpToEvent as a double

    % Retrieve the input.
    strInput = get(hObject, 'String');

    % Ensure that the user enters a valid integer.
    if all(isstrprop(strInput, 'digit'))
        selectEvent(handles, str2double(strInput));
    else
        errordlg('Please enter a valid event number');
    end
end

% --- Executes during object creation, after setting all properties.
function tbxJumpToEvent_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to tbxJumpToEvent (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in btnRemoveEvent.
function btnRemoveEvent_Callback(hObject, eventdata, handles)
    % hObject    handle to btnRemoveEvent (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    handles.cellEvents(handles.nCurrentEvent) = [];
    selectEvent(handles, handles.nCurrentEvent);
end

% --- Executes on button press in btnMoveLeftEdge.
function btnMoveLeftEdge_Callback(hObject, eventdata, handles)
    % hObject    handle to btnMoveLeftEdge (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    axes(handles.axEvent);
    [x, ~] = ginput(1);

    evt = handles.cellEvents{handles.nCurrentEvent};
    vEventWindow = getWindow(evt);
    setWindow(evt, [x, vEventWindow(2)]);
    guidata(hObject, handles);
    updateGui(handles);
end

% --- Executes on button press in btnMoveRightEdge.
function btnMoveRightEdge_Callback(hObject, eventdata, handles)
    % hObject    handle to btnMoveRightEdge (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    axes(handles.axEvent);
    [x, ~] = ginput(1);

    evt = handles.cellEvents{handles.nCurrentEvent};
    vEventWindow = getWindow(evt);
    setWindow(evt, [vEventWindow(1), x]);
    guidata(hObject, handles);
    updateGui(handles);
end

% --- Executes on button press in btnSplitEvent.
function btnSplitEvent_Callback(hObject, eventdata, handles)
    % hObject    handle to btnSplitEvent (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Retrieve the x value where we want to split.
    axes(handles.axEvent);
    [x, ~] = ginput(1);

    % Some convenience variables.
    cellEvents = handles.cellEvents;
    nCurrentEvent = handles.nCurrentEvent;
    vEventWindow = getWindow(cellEvents{nCurrentEvent});

    % How much time do we want between the newly-created events? Let's go with
    % 20 milliseconds.
    dTimeSpacing = 0.001;

    % Ensure that the selected x value lies within the current event.
    if x <= vEventWindow(1) + dTimeSpacing || x >= vEventWindow(2) - dTimeSpacing
        errordlg('Please select a time within the current event window.');
    else
        % First, duplicate the event.
        cellEvents = [cellEvents(1 : nCurrentEvent); ...
                      cellEvents(nCurrentEvent : end)];

        % Now, set the newly-created events' endpoints.
        setWindow(cellEvents{nCurrentEvent}, [vEventWindow(1), x - dTimeSpacing]);
        setWindow(cellEvents{nCurrentEvent + 1}, [x + dTimeSpacing, vEventWindow(2)]);

        % Save the events to the `handles` object and update the GUI data.
        handles.cellEvents = cellEvents;
        guidata(hObject, handles);
        updateGui(handles);
    end
end
