% Enable parallel processing
% matlabpool('open');

% Ensure that this directory is the current directory.
[folder, ~, ~] = fileparts(mfilename('fullpath'));
cd(folder);

% Add the appropriate folders to the path.
addpath('./matlab-incremented');
%addpath('./comparison/')
addpath('./xmltree/');
addpath(genpath('./chronux/chronux/'))
addpath(genpath('./fma-toolbox/'))
