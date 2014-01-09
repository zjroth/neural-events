%
% DESCRIPTION:
%
%    A container for neural events and related data.
%
classdef Event
    properties (GetAccess = public, SetAccess = private)
        window, spikes, times, type
    end

    methods (Access = public)
        % ARGUMENTS:
        %   vTimeWindow:   a vector [start_time, end_time]
        %   vSpikeTimes:   the times at which neurons spike
        %   vSpikes:       the neurons that are spiking
        %
        % NOTE: vSpikeTimes and vSpikes must be the same length; the spike
        % times must all lie within the specified time window.
        function this = Event(vTimeWindow, vSpikeTimes, vSpikes, strType)
            assert(all(vSpikeTimes >= vTimeWindow(1)) ...
                   && all(vSpikeTimes <= vTimeWindow(2)), ...
                   'Please ensure that all times lie within the given window');

            this.window = vTimeWindow;

            [~, vOrder] = sort(vSpikeTimes);
            this.times = col(vSpikeTimes(vOrder));
            this.spikes = col(vSpikes(vOrder));

            if nargin < 4
                strType = '';
            end

            this.type = strType;
        end
    end

    methods (Access = public)
        function vActive = activeCells(this)
            vActive = unique(sequence(this));
        end

        function vSequence = sequence(this)
            vSequence = this.spikes;
        end

        function dDuration = duration(this)
            dDuration = endTime(this) - startTime(this);
        end

        function nLength = length(this)
            nLength = length(this.spikes);
        end

        function dTime = startTime(this)
            dTime = this.window(1);
        end

        function dTime = endTime(this)
            dTime = this.window(2);
        end

        function vTimes = firingTimes(this, nCell)
            if nargin < 2
                vTimes = this.times;
            else
                vTimes = this.times(sequence(this) == nCell);
            end
        end

        function cellTrains = spikeTrains(this, vCells)
            if nargin < 2
                vCells = 1 : max(activeCells(this));
            end

            cellTrains = arrayfun(@this.firingTimes, ...
                                  col(vCells), ...
                                  'UniformOutput', false);
        end

        function plot(this, varargin)
            plotSpikeTrains(spikeTrains(this), this.window, varargin{:});
        end

        function plotSequence(this, varargin)
            % Create a new `Event` whose time information has been replaced
            % by an ordering.
            nLength = length(this);
            evtSequence = Event([1, nLength], 1 : nLength, sequence(this));

            % Now just plot the new `Event`.
            plot(evtSequence, varargin{:});
        end

        function vOrder = orderCells(this)
            vSequence = sequence(this);
            vNeurons = unique(sequence(this));
            vCentersOfMass = zeros(size(vNeurons));

            for i = 1 : length(vNeurons)
                vCentersOfMass(i) = mean(find(vSequence == vNeurons(i)));
            end

            [~, vOrder] = sort(vCentersOfMass);
            vOrder = vNeurons(vOrder);
        end

    end
end