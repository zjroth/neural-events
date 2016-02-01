% USAGE:
%    ripples = detectRipples(this, ...)
%
% DESCRIPTION:
%    Detect sharp-wave ripples.
%
% ARGUMENTS:
%    sharpWave
%       .
%    rippleWave
%       .
%
% OPTIONAL PARAMETERS:
%    sampleRate (default: 2e4)
%       .
%    vDuration (default: [0.025, 0.200])
%       .
%    minSeparation (default: 0.030)
%       .
%    minSharpWavePeak (default: 4)
%       .
%    minSharpWave (default: 1.5)
%       .
%    minRippleWavePeak (default: 2)
%       .
%    minRippleWave (default: 1)
%       .
%    minFirstDerivative (default: 3)
%       .
%    minSecondDerivative (default: 3)
%       .
%    dMinSmoothedSpike (default: 0)
%       .
%
% RETURNS:
%    ripples
%       Matrix with entries in seconds and rows of the form [start, peak, end]
function ripples = detectRipples(this, varargin)
    %=======================================================================
    % Optional parameter values
    %=======================================================================
    parseNamedParams(this.default_ripple_params);
    parseNamedParams(varargin);

    %=======================================================================
    % Initialization and value-checking
    %=======================================================================

    % Convert the time data into index data for the sharp-wave signal, which has
    % the same time data as the raw LFP data. Use this to extract the sharp-wave
    % data at the appropriate times.
    objSharpWave = getSharpWave(this);
    objSpikeWave = getSpikeWave(this, objSharpWave);

    vSharpWave = objSharpWave.Data;
    vSpikeWave = objSpikeWave.Data;

    % Now that the optional parameter values have been set, we can use them to
    % deterine the values of certain variables to be used during the
    % computation.
    minDuration = ceil(vDuration(1) * sampleRate(this));
    maxDuration = floor(vDuration(2) * sampleRate(this));
    minSeparation = ceil(minSeparation * sampleRate(this));
    minPeakSep = minDuration + minSeparation;

    %=======================================================================
    % Actual computations
    %=======================================================================

    % Find the first and second derivatives of the sharp-wave. Smoothing here
    % is important for the second derivative since it is used to split events
    % in to multiple events by considering its peaks.
    firstDerivative = zscore(conv([0; diff(vSharpWave)], ...
                                  gaussfilt(100, 5), 'same'));
    secondDerivative = zscore(conv([0; diff(firstDerivative)], ...
                                   gaussfilt(100, 5), 'same'));

    % Our initial guess for where ripples are occuring will be based solely on
    % thresholding the sharp-wave signal.
    rippleIntervals = findIntervals(vSharpWave >= minSharpWave);

    % The above thresholding likely detected lots of very short event intervals.
    % Remove events that are too short (which we do now to speed up later
    % processing).
    rippleIntervals = rippleIntervals( ...
        rippleIntervals(:, 2) - rippleIntervals(:, 1) >= minDuration, :);

    % Now that we have the necessary intervals to consider, we want to classify
    % those events as ripples or not ripples. Initially, we say that each ripple
    % interval contains a ripple. Store each ripple as a triple, specifically in
    % the form [start, peak, end].
    ripplePeaks = arrayfun(@(s, e) getPeak(vSharpWave, s, e), ...
        rippleIntervals(:, 1), rippleIntervals(:, 2));
    ripples = [rippleIntervals(:, 1), ripplePeaks, rippleIntervals(:, 2)];

    % Split the ripples where there's a high second derivative in the sharp wave
    % signal.
    secondDerivativePeaks = findpeaks(secondDerivative);
    splitPoints = secondDerivativePeaks.loc;
    splitPointVals = secondDerivative(splitPoints);
    splitPoints = splitPoints(splitPointVals > minSecondDerivative);
    ripples = splitRipples(ripples, vSharpWave, splitPoints);

    % Remove short ripples (which could have been reintroduced by splitting
    % events), and shorten long ones.
    ripples = ripples(ripples(:, 3) - ripples(:, 1) >= minDuration, :);
    ripples = shortenRipples(ripples, maxDuration);

    % Ensure that each ripple satisfies the following conditions.
    vSharpWaveAboveMaxThresh = (vSharpWave > minSharpWavePeak);
    vFirstDerivativeAboveThresh = (abs(firstDerivative) > minFirstDerivative);
    vSpikeWaveAboveThresh = (vSpikeWave >= dMinSmoothedSpike);

    if minRippleWavePeak > -Inf
        % The ripple-wave is expensive to compute and expensive to load if it
        % has been pre-computed. Thus the check here.
        objRippleWave = getRippleWave(this);
        vRippleWave = objRippleWave.Data;
        vRippleWaveAboveMaxThresh = (vRippleWave > minRippleWavePeak);
    else
        vRippleWaveAboveMaxThresh = true(size(vSpikeWave));
    end

    vSatisfiesSharpWaveThresh = ...
        maxInIntervals(vSharpWaveAboveMaxThresh, ripples(:, [1, 3]));
    vSatisfiesRippleWaveThresh = ...
        maxInIntervals(vRippleWaveAboveMaxThresh, ripples(:, [1, 3]));
    vSatisfiesFirstDerivativeThresh = ...
        maxInIntervals(vFirstDerivativeAboveThresh, ripples(:, [1, 3]));
    vSatisfiesSpikeWaveThresh = ...
        maxInIntervals(vSpikeWaveAboveThresh, ripples(:, [1, 3]));

    % Keep only those ripples that satisfy all of the thresholds.
    ripples = ripples(vSatisfiesSharpWaveThresh ...
                      & vSatisfiesRippleWaveThresh ...
                      & vSatisfiesFirstDerivativeThresh ...
                      & vSatisfiesSpikeWaveThresh, :);

    % Convert the ripples from index data to time data and store them in this
    % object.
    ripples = (ripples - 1) / sampleRate(this) + objSharpWave.Time(1);
    this.current.ripples = ripples;

    ripples = getEvents(this, ripples(:, [1, 3]), 'ripple');
end

function vSpikes = getSpikeTimes(this)
    vSpikes = col(getSpike(this, 'res'));
end

function objSpikeWave = getSpikeWave(this, objSharpWave)
    % Retrieve the spikes and bin them by firing time. Then smooth the resultant
    % signal.
    nSamples = length(getTrack(this, 'eeg'));
    vSpikes = getSpikeTimes(this);
    vSpikeCounts = accumarray(vSpikes, 1, [nSamples, 1]);
    vSpikeWave = conv(vSpikeCounts, gaussfilt(100, 5), 'same');
    vSpikeWave = zscore(vSpikeWave);

    objSpikeWave = TimeSeries( ...
        vSpikeWave, (0 : nSamples - 1) ./ sampleRate(this));
    objSpikeWave = subseries(objSpikeWave, objSharpWave.Time(1), ...
                             objSharpWave.Time(end));
end

function vMaxes = maxInIntervals(vFunction, mtxIntervals)
    nIntervals = size(mtxIntervals, 1);
    vMaxes = zeros(nIntervals, 1);

    for i = 1 : nIntervals
        vMaxes(i) = max(vFunction(mtxIntervals(i, 1) : mtxIntervals(i, 2)));
    end
end

function ripplesOut = splitRipples(ripplesIn, sharpWave, splitPoints)
    ripplesOut = NaN(size(ripplesIn));
    numRipples = 0;

    % Split the ripples.
    for i = 1 : size(ripplesIn, 1)
        % The start and end of the current ripple.
        rippleStart = ripplesIn(i, 1);
        rippleEnd = ripplesIn(i, 3);

        % The split points that are local to the current ripple.
        localSplitPoints = splitPoints( ...
            splitPoints > rippleStart & ...
            splitPoints < rippleEnd);

        % The lists of starting and ending points of the found subripples.
        starts = [rippleStart; localSplitPoints];
        ends   = [localSplitPoints; rippleEnd];

        % Append to the output each newly-found subripple.
        for j = 1 : length(starts)
            numRipples = numRipples + 1;

            ripplesOut(numRipples, 1) = starts(j);
            ripplesOut(numRipples, 2) = getPeak( ...
                sharpWave, starts(j), ends(j));
            ripplesOut(numRipples, 3) = ends(j);
        end
    end
end

function ripplesOut = shortenRipples(ripplesIn, maxDuration)
    ripplesOut = ripplesIn;

    for i = 1 : size(ripplesOut, 1)
        % Initialize the return variables.
        rippleStart = ripplesOut(i, 1);
        ripplePeak  = ripplesOut(i, 2);
        rippleEnd   = ripplesOut(i, 3);

        % Only do something if the ripple is too long.
        if (rippleEnd - rippleStart > maxDuration)
            % At least one end point of the ripple has to be more than
            % half of the maximum allowed period.
            headLength = ripplePeak - rippleStart;
            tailLength = rippleEnd - ripplePeak;

            % Variables to store whether the head and tail of the ripple
            % (i.e., the parts before and after the peak) are too long.
            headTooLong = (headLength > maxDuration / 2);
            tailTooLong = (tailLength > maxDuration / 2);

            % Now simply shorten the appropriate parts of the ripple.
            if headTooLong && tailTooLong
                rippleStart = ripplePeak - maxDuration / 2;
                rippleEnd = ripplePeak + maxDuration / 2;
            elseif headTooLong
                rippleStart = ripplePeak - (maxDuration - tailLength);
            elseif tailTooLong
                rippleEnd = ripplePeak + (maxDuration - headLength);
            end

            % Save the shortened ripple.
            ripplesOut(i, [1, 3]) = [rippleStart, rippleEnd];
        end
    end
end

function peak = getPeak(data, startIndex, endIndex)
    [~, peak] = max(data(startIndex : endIndex));
    peak = startIndex + (peak - 1);
end
