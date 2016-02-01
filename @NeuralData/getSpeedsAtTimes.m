% USAGE:
%    vSpeeds = getSpeedsAtTimes(this, vTimes, dWindowWidth, strUnits)
%
% DESCRIPTION:
%    Retrieve the speed of the animal at the given times, potentially averaging
%    over time windows surrounding those points.
%
% ARGUMENTS:
%    vTimes
%       A vector containing the times at which to retrieve the animal's speed
%    dWindowWidth (default: 0)
%       The width of the windows to use for averaging speeds over. The
%       windows will be centered at the provided times and have total width
%       as specified in this parameter, depending on the units.
%    strUnits (default: 'seconds')
%       A string specifying the units of the given times; can be 'seconds',
%       'milliseconds', or 'indices'
%
% RETURNS:
%    vSpeeds
%       A vector containing the requested speeds
function vSpeeds = getSpeedsAtTimes(this, vTimes, dWindowWidth, strUnits)
    if nargin < 3
        dWindowWidth = 0;
    end

    if nargin < 4 || isempty(strUnits)
        strUnits = 'seconds';
    end

    % Define a matrix of windows based on the given window width and the given
    % times.
    vStartTimes = col(vTimes) - (dWindowWidth / 2);

    % Convert the above-determined windows into index windows.
    switch strUnits
      case 'seconds'
        vStartIndices = round(vStartTimes * sampleRate(this));
        nIndicesInWindow = round(dWindowWidth * sampleRate(this));
      case 'milliseconds'
        vStartIndices = round(vStartTimes * (sampleRate(this) / 1000));
        nIndicesInWindow = round(dWindowWidth * sampleRate(this) / 1000);
      case 'indices'
        vStartIndices = vStartTimes;
        nIndicesInWindow = dWindowWidth;
    end

    % Expand the index windows into complete lists of indices, and then retrieve
    % the speeds and average them.
    if this.bOldBehavElectrData
        vRawSpeeds = getTrack(this, 'speed');
    else
        vRawSpeeds = getTrack(this, 'speed_MMsec');
    end

    nLength = length(vRawSpeeds);

    cellIndices = arrayfun(@(s) colon(s, s + nIndicesInWindow - 1), ...
                           vStartIndices, 'UniformOutput', false);
    cellIndices = cellfun(@(v) v(v >= 1 & v <= nLength), cellIndices, ...
                          'UniformOutput', false);
    vSpeeds = cellfun(@(i) mean(vRawSpeeds(i)), cellIndices);
end