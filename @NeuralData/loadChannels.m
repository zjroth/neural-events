% USAGE:
%    loadChannels(this, nMain, nLow, nHigh)
%
% DESCRIPTION:
%    Load the specified LFP channels into memory
%
% ARGUMENTS:
%    nMain, nLow, nHigh (optional)
%       Integers specifying the 1-indexed LFP channels to load. If any of these
%       is specified, all must be specified. See `NeuralData.setCurrentChannels`
%       for more information.
%
% NOTES:
%    If LFP channels are not specified, then the method `setCurrentChannels`
%    must be invoked first.
function loadChannels(this, nMain, nLow, nHigh)
    if nargin == 4
        setCurrentChannels(this, nMain, nLow, nHigh);
    end

    % The set of current channels must be set before calling this function.
    assert(~isempty(this.currentChannels), ...
           ['A collection of channels must be specified. Use ' ...
            '`setCurrentChannels` or the additional arguments to ' ...
            '`loadChannels` to do this.']);

    % Use the FMA toolbox to load the binary data.
    strDataFile = fullfile(this.baseFolder, [this.baseFileName '.dat']);

    this.currentLfps = [];

    % Ensure that the folder that we're going to be saving to exists.
    strLfpCacheDir = fullfile(this.cachePath, 'lfps');

    if ~exist(strLfpCacheDir, 'dir')
        mkdir(strLfpCacheDir);
    end

    % Load each of the channels
    for i = 1 : 3
        % Each channel must be extracted from the data, which is an expensive
        % operation. So, when a channel is extracted, the extracted data is
        % saved to a separate file. Set the name of the file here.
        strFilename = fullfile( ...
            strLfpCacheDir, ['ch' num2str(this.currentChannels(i)) '.mat']);

        % If the file already exists, simply load the data from that file.
        if exist(strFilename, 'file')
            stctFileContents = load(strFilename, 'lfp');
            this.currentLfps(:, i) = stctFileContents.lfp;
            clear('stctFileContents');
        else
            % ...otherwise, extract the data and save it to a file.
            lfp = LoadBinary(strDataFile,            ...
                'nChannels', this.numDataChannels(), ...
                'channels', this.currentChannels(i));

            save(strFilename, 'lfp');
            this.currentLfps(:, i) = lfp;
            clear('lfp');
        end
    end

    % Finally, set the raw sample times corresponding to the loaded LFPs.
    this.rawSampleTimes = (0 : size(this.currentLfps, 1) - 1) / this.rawSampleRate;
end