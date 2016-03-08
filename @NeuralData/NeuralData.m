%
% DESCRIPTION:
%
%    Provide convenient access to neural data and methods related to ripple
%    detection.
%
% PROPERTIES:
%
%    .
%
% METHODS:
%
%    .
%
% STATIC METHODS:
%
%    .
%
classdef NeuralData < handle
    properties (GetAccess = public, SetAccess = protected)
        Clu = []
        Laps = []
        Spike = []
        Track = []
        xml = []

        smoothingRadius = 0.005;

        default_ripple_params = { ...
            'dMinSmoothedSpike'   , 1.3,            ...
            'vDuration'           , [0.025, 0.250], ...
            'minFirstDerivative'  , 2.75,           ...
            'minRippleWave'       , -Inf,           ...
            'minRippleWavePeak'   , -Inf,           ...
            'minSecondDerivative' , 6,              ...
            'minSeparation'       , 0.030,          ...
            'minSharpWave'        , 1.25,           ...
            'minSharpWavePeak'    , 4};
        ripples

        rawSampleTimes


        bOldBehavElectrData = false;
        strBehavElectrDataLFP

        baseFolder
        baseFileName
        cachePath

        currentChannels = []
        currentLfps = []
    end

    properties (GetAccess = public, SetAccess = public)
        data = []
        saved = []
        parameters = []
    end

    properties (GetAccess = protected, SetAccess = protected)
        current = []
    end

    methods (Access = public)
        %---------------------------------------------------------------
        % USAGE:
        %    obj = NeuralData()
        %
        % DESCRIPTION:
        %    Initialize a `NeuralData` object by loading from a specified
        %    data folder.
        %
        % ARGUMENTS:
        %    uknDataPath
        %       If a cell array:
        %       - its first element is the directory containing the data
        %       - its second element is the base recording name; there must be
        %         a file named [uknDataPath{2} '.dat'] in the data directory.
        %       If a string, it is the directory containing the data; and the
        %       base recording name is inferred from directory path.
        %    strCachePath
        %       The path in which to store cached the data
        %---------------------------------------------------------------
        function this = NeuralData(uknDataPath, strCachePath)
            % Find the location of the .dat file for this recording.
            if iscell(uknDataPath)
                % Things are easy: A recording name was explicitly specified.
                strDataDir = uknDataPath{1};
                strDatFile = [uknDataPath{2} '.dat'];
            elseif ischar(uknDataPath)
                % A recording name wasn't specified explicitly, so we need to
                % work a little harder.
                strDataDir = uknDataPath;

                % Find all .dat files in the specified directory.
                cellDatFiles = findfiles(strDataDir, '\.dat$');

                if length(cellDatFiles) == 1
                    strDatFile = cellDatFiles{1};
                elseif length(cellDatFiles) > 1
                    strPrefix = commonprefix(cellDatFiles);
                    [nMinLength, nIndex] = min(cellfun(@length, cellDatFiles));

                    if length(strPrefix) == (nMinLength - 4)
                        strDatFile = cellDatFiles{nIndex};
                    end
                end
            else
                error('NeuralData: unrecognized first input parameter');
            end

            % Ensure that we can find the data file in the data directory.
            bFileExists = (exist('strDatFile', 'var') && ...
                           exist(fullfile(strDataDir, strDatFile), 'file'));
            assert(bFileExists, ...
                   ['NeuralData: incorrect base recording name; ', ...
                    'see `help NeuralData` for more information']);

            % If the file above exists, we know what the recording name is.
            strRecording = strDatFile(1 : end - 4);

            % Make sure that the cache exists.
            assert(logical(exist(strCachePath, 'dir')), ...
                   'Please ensure that the cache is a valid directory');

            % Store the folder and recording name in this object.
            this.baseFolder = strDataDir;
            this.baseFileName = strRecording;
            this.cachePath = fullfile(strCachePath, strRecording);

            if ~exist(this.cachePath, 'dir')
                mkdir(this.cachePath);
            end

            % Load and store information about the data in this recording.
            this.strBehavElectrDataLFP = ...
                fullfile(strDataDir, [strRecording '_BehavElectrDataLFP.mat']);

            if ~exist(this.strBehavElectrDataLFP, 'file')
                this.strBehavElectrDataLFP = ...
                    fullfile(strDataDir, [strRecording '_BehavElectrData.mat']);

                assert(logical(exist(this.strBehavElectrDataLFP, 'file')), ...
                       'NeuralData: no *_BehavElectrDataLFP.mat file found');

                this.bOldBehavElectrData = true;
                this.xml = loadvar(this.strBehavElectrDataLFP, 'Par');
            end
        end
    end

    % getters and setters
    methods (Access = public)
        function uknOut = getClu(this, strField)
            if isempty(this.Clu)
                this.Clu = loadvar(this.strBehavElectrDataLFP, 'Clu');
            end

            if nargin == 2
                uknOut = this.Clu.(strField);
            else
                uknOut = this.Clu;
            end
        end

        function uknOut = getLaps(this, strField)
            if isempty(this.Laps)
                this.Laps = loadvar(this.strBehavElectrDataLFP, 'Laps');
            end

            if nargin == 2
                uknOut = this.Laps.(strField);
            else
                uknOut = this.Laps;
            end
        end

        function uknOut = getSpike(this, strField)
            if isempty(this.Spike)
                this.Spike = loadvar(this.strBehavElectrDataLFP, 'Spike');
            end

            if nargin == 2
                uknOut = this.Spike.(strField);
            else
                uknOut = this.Spike;
            end
        end

        function uknOut = getTrack(this, strField)
            if isempty(this.Track)
                this.Track = loadvar(this.strBehavElectrDataLFP, 'Track');
            end

            if nargin == 2
                uknOut = this.Track.(strField);
            else
                uknOut = this.Track;
            end
        end

        function uknOut = getXml(this, strField)
            if isempty(this.xml)
                this.xml = loadvar(this.strBehavElectrDataLFP, 'xml');
            end

            if nargin == 2
                uknOut = this.xml.(strField);
            else
                uknOut = this.xml;
            end
        end

        function clearBehavElectrDataLFP(this)
            this.Clu = [];
            this.Laps = [];
            this.Spike = [];
            this.Track = [];
            % this.xml = [];
        end

        function clearLfpData(this)
            this.currentLfps = [];
        end

        function setDefaultRippleParams(this, cellNewDefaults)
            hashParams = containers.Map( ...
                this.default_ripple_params(1 : 2 : end), ...
                this.default_ripple_params(2 : 2 : end));

            cellNames = cellNewDefaults(1 : 2 : end);
            cellValues = cellNewDefaults(2 : 2 : end);

            for i = 1 : length(cellNames)
                hashParams(cellNames{i}) = cellValues{i};
            end

            this.default_ripple_params = ...
                row([row(keys(hashParams)); row(values(hashParams))]);
        end
    end

    % Other methods
    methods (Access = public)
        % Recording information
        nNeurons = getNeuronCount(this)
        n = numDataChannels(this)
        rate = rawSampleRate(this)
        rate = sampleRate(this)
        dDuration = getRecordingDuration(this)
        mtxLocations = getLocations(this)
        mtxLocations = getSpikeLocations(this)

        % Channels
        loadChannels(this, nMain, nLow, nHigh)
        objLfps = getLfps(this)
        [lfp, ch] = mainLfp(this, indices)
        [lfp, ch] = lowLfp(this, indices)
        [lfp, ch] = highLfp(this, indices)
        plotLfps(this, varargin)

        % Neuron-related
        cellSpikeTimes = groupSpikes(this)
        vOrdering = sortNeuronsInWindow(this, vTimeWindow, varargin)
        trains = getSpikeTrains(this, bRemoveInterneurons)
        detectInterneurons(this)
        vInterneurons = getInterneurons(this)

        % Ripple detection
        ripples = detectRipples(this, varargin)
        sharpWave = getSharpWave(this, bDownsample);
        computeSharpWave(this);
        objRippleWave = getRippleWave(this, varargin);
        [spect, spectTimes, spectFrequencies] = getRippleSpectrogram(this, varargin);

        % Sequences retrieval
        [vSequence, vTimes] = getSequence(this, vTimeWindow, varargin)
        [cellSequences, cellTimes] = getSequences(this, mtxTimeWindows, bRemoveInterneurons)
        cellSequences = getPlaceFieldSequences(this, varargin)
        cellSequences = getWheelSequences(this, varargin)
        [cellSequences, cellClassification] = getThetaSequences(this, varargin)

        % Intervals retrieval
        [mtxTimeWindows, cellClassification] = getThetaIntervals(this, bSliding)
        mtxTimeWindows = getWheelIntervals(this)
        [mtxTimeWindows, cellClassification] = getPlaceFieldIntervals(this)

        % Events retrieval
        ripples = getRipples(this, rippleNums)
        objEvent = getEvent(this, vTimeWindow, strClassification)
        cellEvents = getEvents(this, mtxTimeWindows, uknClassification)
        cellEvents = getPlaceFieldEvents(this);
        cellEvents = getThetaEvents(this, bSliding);
        cellEvents = getWheelEvents(this);
        cellSequenceEvents = refineRippleSequences(this, cellRippleEvents, varargin)

        % Miscellaneous
        vPoint = getLocationsAtTime(this, dTime, strUnits)
        vSpeeds = getSpeedsAtTimes(this, vTimes, dWindowWidth, strUnits)
        dPeakFreq = getPeakFrequency(this, vTimeWindow, vFrequencyWindow, bWhiten)
        vPeakFreqs = getPeakFrequencies(this, mtxTimeWindows, vFrequencyWindow, cellSpectParams)
        nSection = getSection(this, objEvent)
        vIndices = getTimeIndices(this, vTimes)
    end
end
