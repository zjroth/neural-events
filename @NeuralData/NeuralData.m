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
        Clu
        Laps
        Spike
        Track
        xml

        smoothingRadius = 0.03;
        ripples

        rawSampleTimes
    end

    properties (GetAccess = public, SetAccess = public)
        saved = []
        parameters = []
    end

    properties (GetAccess = protected, SetAccess = protected)
        baseFolder
        baseFileName

        currentChannels = []
        currentLfps = []

        current = []
    end

    methods (Access = public)
        %---------------------------------------------------------------
        %
        % USAGE:
        %
        %    obj = NeuralData()
        %
        % DESCRIPTION:
        %
        %    Initialize a `NeuralData` object by loading from a specified
        %    data folder.
        %
        % ARGUMENTS:
        %
        %    strFolder
        %       The path to the folder in which the data resides. This must
        %       end with a path separator (e.g., `/` on unix systems).
        %
        %---------------------------------------------------------------
        function this = NeuralData(strFolder)
            % First, read in the base file name from the meta.txt file. Find
            % the data on the line that starts with "strBaseFileName = ".
            strMetaText = fileread([strFolder 'meta.txt']);
            strBaseFileName = regexp( ...
                strMetaText, '^strBaseFileName = (.*)$', ...
                'tokens', 'lineanchors', 'dotexceptnewline');
            strBaseFileName = strBaseFileName{1}{1};

            % Store the folder and base filename in this object.
            this.baseFolder = strFolder;
            this.baseFileName = strBaseFileName;

            % Load and store information about the data in this recording.
            load(fullfile(strFolder, [strBaseFileName '_BehavElectrDataLFP.mat']));
            this.Clu = Clu;
            this.Laps = Laps;
            this.Spike = Spike;
            this.Track = Track;
            this.xml = xml;

            % Load ripple information if it has been saved.
            strRippleFile = [strFolder filesep 'computed' filesep 'ripples.mat'];
            if exist(strRippleFile, 'file')
                load(strRippleFile, 'mtxRipples');
                this.saved.ripples = mtxRipples;
                this.current.ripples = mtxRipples;
            end
        end
    end

    methods (Access = public)
        clusterSpikeTimes = groupSpikes(this)

        loadChannels(this)

        [lfp, ch] = mainLfp(this, indices)
        [lfp, ch] = lowLfp(this, indices)
        [lfp, ch] = highLfp(this, indices)

        sharpWave = getSharpWave(this, bDownsample);
        computeSharpWave(this);
        objRippleWave = getRippleWave(this, varargin);

        [spect, spectTimes, spectFrequencies] = getRippleSpectrogram(this, varargin);

        n = numDataChannels(this)

        %plt = plotRipples(this, ...)
        fig = plotRipplesVsSpikes(this, varargin)
        hndl = plotRipple(this, nRipple, varargin)
        plotRippleSpikeTrains(this, nRipple, varargin)
        plotSpikeTrains(this, vTimeWindow, varargin)

        ripples = detectRipples(this, sharpWave, rippleWave, timeData, varargin)

        rate = rawSampleRate(this)
        rate = sampleRate(this)

        vOrdering = sortNeuronsInWindow(this, vTimeWindow, varargin)
        vOrdering = sortNeuronsForRipple(this, nRipple, varargin)

        ripples = getRipples(this, rippleNums)
        setRipple(this, rippleNum, vStartPeakEnd)
        trains = getSpikeTrains(this, bRemoveInterneurons)
        plotLfps(this, varargin)
        vNearest = getNearestRipples(this, nRipple)
        computeRippleSpikeMatrix(this)
        rippleSpikeMatrix = getRippleSpikeMatrix(this)

        activeNeurons = getRippleActivity(this, nRipple)
        nRipples = getRippleCount(this)
        removeRipple(this, nRipple)
        vSequence = getSequence(this, vTimeWindow, varargin)
        cellSequences = getSequences(this, mtxTimeWindows, varargin)
        vSequence = getRippleSequence(this, nRipple, varargin)
        cellSequences = getRippleSequences(this, varargin)
        cellSequences = getPlaceCellSequences(this, varargin)
        cellSequences = getWheelSequences(this, varargin)

        mtxTimeWindows = getWheelIntervals(this)
        mtxTimeWindows = getPlaceFieldIntervals(this)

        modifyRipple(this, nRipple, nStartTime, nEndTime)
        modifyRipples(this, varargin)
    end
end