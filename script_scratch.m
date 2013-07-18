
%% Plot ripple spike positions

idxs = round(ripples(:, 2) * 1250);
% idxs = round(ripples(24, 2) * 1250);

figure();

hold('on');
plot(neuralData.Track.xPix, neuralData.Track.yPix, '.', 'Color', [0.75, 0.75, 0.75])
h = plot(neuralData.Track.xPix(round(idxs)), neuralData.Track.yPix(round(idxs)), 'r.');
hold('off');

%% Plot Carina's figures

clear plotRipples
plotRipples(ripples, lfpTripleTs, data, ...
    'events', 1:size(ripples, 1), ...
    'ripplePadding', 0.05)

%% Animate path through maze

figure();
hold('on')
xlim([0, 700]);
ylim([0, 400]);

for i = 0 : 975
    idxs = 1250 * i + (1 : 1250);
    color = rand(1, 3);
    plot(neuralData.Track.xPix(idxs), neuralData.Track.yPix(idxs), '.', 'Color', color);
    pause(0.001);
end

hold('off');

%% Show cell spike positions

navigateFigures(@(nFig) ...
    plot(neuralData.Track.xPix, neuralData.Track.yPix, ...
        'k.', ...
        neuralData.Track.xPix(spikeTimes{nFig}), ...
        neuralData.Track.yPix(spikeTimes{nFig}), ...
        'r.') ...
);

%%
figure();
hold('on')
plot(neuralData.Track.xPix, neuralData.Track.yPix, '.');
h = [];

spikeTimes = neuralData.groupSpikes();

i = 1;
while true % i = neurons %1 : length(spikeTimes)
    delete(h);
    idxs = spikeTimes{i};
    color = rand(1, 3);
    h = plot(neuralData.Track.xPix(idxs), neuralData.Track.yPix(idxs), '.', 'Color', [1, 0, 0]);
%     pause;
    [~, ~, b] = ginput(1);
    while b ~= 28 && b ~= 29
        [~, ~, b] = ginput(1);
    end
    
    if b == 28
        i = max(i - 1, 1);
    else
        i = min(i + 1, length(neurons));
    end
end

hold('off');