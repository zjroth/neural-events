% mtxRipples = getRipples(this, vRippleNums)
function mtxRipples = getRipples(this, vRippleNums)
    % If there is no collection of ripples in this object, we must run the
    % detection method before we can return the collection of ripples.
    if ~isfield(this.current, 'ripples')
        detectRipples(this);
    end

    % If no specific collection of ripples was collected, then we should just
    % return all of the ripples.
    if nargin < 2
        vRippleNums = ':';
    end

    % Set the return variable.
    mtxRipples = this.current.ripples(vRippleNums);
end
