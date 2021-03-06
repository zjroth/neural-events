% mtxTimeWindows = getPlaceCellSequences(this)
function [mtxTimeWindows, cellClassification] = getPlaceFieldIntervals(this)
    % del = 1 (region-2)
    % whlL = 2 (region-1)
    % whlR = 3 (region-1)
    % armL = 4 (region-4)
    % armR = 5 (region-3)
    % armC = 6 (region-5)
    % rewL = 7 (region-7)
    % rewR = 8 (region-6)
    % rewC = 9 (region-8)
    % turnL = 10 (region-10)
    % turnR = 11 (region-9)

    % Retrieve the intervals in which the animal is in one of the arms.
    [mtxLeftOut, mtxLeftIn] = getArmIntervals(this, 'left');
    [mtxRightOut, mtxRightIn] = getArmIntervals(this, 'right');

    % Join the above lists into a master list and save the classification for
    % each event.
    mtxIntervals = [mtxLeftOut;  ...
                    mtxLeftIn; ...
                    mtxRightOut; ...
                    mtxRightIn];

    cellClassification = vertcat( ...
        repmat({'arm/left/outbound'}, size(mtxLeftOut, 1), 1), ...
        repmat({'arm/left/inbound'}, size(mtxLeftIn, 1), 1), ...
        repmat({'arm/right/outbound'}, size(mtxRightOut, 1), 1), ...
        repmat({'arm/right/inbound'}, size(mtxRightIn, 1), 1));

    % Now, simply convert the index data to time data.
    mtxTimeWindows = mtxIntervals / sampleRate(this);
end

function [mtxOut, mtxIn] = getArmIntervals(this, strArm)
    if strcmp(strArm, 'left')
        nSection = 4;
    elseif strcmp(strArm, 'right')
        nSection = 5;
    else
        error();
    end

    strSuffix = ['_DataStructure_mazeSection' num2str(nSection) '_TypeMaze1.mat'];
    strFile = fullfile(this.baseFolder, [this.baseFileName strSuffix]);
    stctFile = load(strFile);

    vTrials = find(~cellfun(@isempty, stctFile.trials));

    for i = 1 : length(vTrials)
        nTrial = vTrials(i);

        mtxOut(i, :) = [stctFile.trials{nTrial}.lfpIndStart(1), ...
                        stctFile.trials{nTrial}.lfpIndEnd(1)];
        mtxIn(i, :) = [stctFile.trials{nTrial}.lfpIndStart(3), ...
                       stctFile.trials{nTrial}.lfpIndEnd(3)];
    end
end