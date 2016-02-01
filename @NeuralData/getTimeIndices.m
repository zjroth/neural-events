% USAGE:
%    vIndices = getTimeIndices(this, vTimes)
%
% DESCRIPTION:
%    Convert a list of times to (their nearest) indices in the recording data.
%
% ARGUMENTS:
%    vTimes
%       The times (in seconds) to convert to indices
%
% RETURNS:
%    vIndices
%       The requested indices
function vIndices = getTimeIndices(this, vTimes)
    vIndices = round(vTimes * sampleRate(this)) + 1;
end
