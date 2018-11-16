function plotcontinuous(EYE, varargin)

if numel(unique([EYE.srate])) > 1
    uiwait(msgbox('Inconsistent sample rates'))
    return
else
    srate = EYE(1).srate;
end
nSeconds = 5;
x = 1:(nSeconds*srate);

f = figure('KeyPressFcn', @moveData,...
    'UserData', struct(...
        'x', x,...
        'data', EYE,...
        'srate', srate));

plothelperfunc(f)

end

function moveData(h, e)

if e.Key == 'h'
    change = -5;
elseif e.Key == 'l'
    change = 5;
elseif e.Key == 'k'
    change = 1;
elseif e.Key == 'j'
    change = -1;
else
    change = 0;
end
h.UserData.x = h.UserData.x + change*h.UserData.srate;
if any(h.UserData.x < 1)
    h.UserData.x = h.UserData.x - min(h.UserData.x) + 1;
end

plothelperfunc(h);

end

function plothelperfunc(h)

figure(h);

EYE = h.UserData.data;
x = h.UserData.x;
srate = h.UserData.srate;
xtimes = (x - 1)/srate;
for dataIdx = 1:numel(EYE)
    if any(x > numel(EYE(dataIdx).data.right))
        return
    end
end
for dataIdx = 1:numel(EYE)
    
    cla(subplot(numel(EYE), 1, dataIdx)); hold on
    plot(xtimes, EYE(dataIdx).data.right(x), 'r');
    plot(xtimes, EYE(dataIdx).data.left(x), 'b');
    if isfield(EYE(dataIdx).data, 'both')
        plot(xtimes, EYE(dataIdx).data.both(x), 'k');
    end
    
    xlim([xtimes(1) xtimes(end)]);
    ylimits = [min(structfun(@min, EYE(dataIdx).data)) max(structfun(@max, EYE(dataIdx).data))];
    for eventIdx = find(ismember([EYE(dataIdx).event.latency], x))
        t = EYE(dataIdx).event(eventIdx).time/1000;
        plot(repmat(t, 1, 2), ylimits, 'k');
        text(t, mean(ylimits), EYE(dataIdx).event(eventIdx).type,...
            'FontSize', 8,...
            'Rotation', 20);
    end
    ylim(ylimits);
end

end
