% USAGE:
%    nSection = getSection(this, objEvent)
%
% RETURN CODES:
%    del = 1 (region-2)
%    whlL = 2 (region-1)
%    whlR = 3 (region-1)
%    armL = 4 (region-4)
%    armR = 5 (region-3)
%    armC = 6 (region-5)
%    rewL = 7 (region-7)
%    rewR = 8 (region-6)
%    rewC = 9 (region-8)
%    turnL = 10 (region-10)
%    turnR = 11 (region-9)
%
% NOTE:
%    This will not work with the "old" BehavElectrDataLFP files.
function nSection = getSection(this, objEvent)
    vSection = getTrack(this, 'mazeSect');
    vWindow = getTimeIndices(this, objEvent.window);
    nSection = mode(vSection(vWindow(1) : vWindow(2)));
end
