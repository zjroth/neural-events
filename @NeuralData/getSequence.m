% USAGE:
%    vSequence = getSequence(this, vTimeWindow, bRemoveInterneurons)
%
% DESCRIPTION:
%    Get the sequence of neuron firings in the given time window
%
% ARGUMENTS:
%    vTimeWindow
%       The time window from which to extract a sequence
%    bRemoveInterneurons (default: true)
%       A boolean specifying whether the returned sequence should contain
%       interneurons
%
% RETURNS:
%    vSequence
%       The desired sequence of firings
function [vSequence, vTimes] = getSequence(this, vTimeWindow, bRemoveInterneurons)
    if nargin < 3
        bRemoveInterneurons = true;
    end

    % Figure out the min/max index corresponding to the time window.
    nMinIndex = vTimeWindow(1) * sampleRate(this);
    nMaxIndex = vTimeWindow(2) * sampleRate(this);

    % The sequence of neuron firings is stored in two separate fields of
    % `this.Spike`. First, `this.Spike.res` has the firing times (indices) at
    % which spikes occur; however, these spike times seem not to be increasing
    % with respect to their corresponding indices. Next, the actual neuron that
    % spiked is stored in `this.Spike.totclu`; retrieve this list in the order
    % sorted by spike times.
    vRes = getSpike(this, 'res');
    vTotclu = getSpike(this, 'totclu');
    vIndices = find((nMinIndex < vRes) & (vRes < nMaxIndex));

    [vTimes, vOrder] = sort(vRes(vIndices));
    vSequence = vTotclu(vIndices(vOrder));
    vTimes = vTimes / sampleRate(this);

    % Remove interneurons from this sequence if requested. This is only possible
    % if this object contains the appropriate reference to identified
    % interneurons.
    if bRemoveInterneurons
        vInterneurons = getInterneurons(this);

        for i = 1 : length(vInterneurons)
            vRemove = (vSequence == vInterneurons(i));
            vSequence(vRemove) = [];
            vTimes(vRemove) = [];
        end
    end
end