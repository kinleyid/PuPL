
function EYE = definePolyAOIs(EYE, varargin)

% Populates aoi field of EYE
%   Inputs:
% EYE: struct array
% aoidescs: AOI decsriptions, struct array with fields:
%   coords: struct with fields:
%       x: vector
%       y: vector
%   spandesc: span description struct
%   Outputs:
% EYE: struct array with aoi field populated

callstr = sprintf('eyeData = %s(eyeData, ', mfilename);
p = inputParser;
addParameter(p, 'aoidescs', []);
parse(p, varargin{:});

if isempty(p.Results.aoidescs)
    aoidescs = UI_getaoidescs(EYE);
else
    aoidescs = p.Results.aoidescs;
end
callstr = sprintf('%s''aoidescs'', %s)', callstr, all2str(aoidescs));

fprintf('Defining areas of interest (AOIs)...\n')
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    for aoiidx = 1:numel(aoidescs)
        currAOIdesc = aoidescs{aoiidx};
        allLatencies = spandesc2lats(EYE(dataidx), currAOIdesc.spandesc);
        for latidx = 1:numel(allLatencies)
            EYE(dataidx).aoi = cat(1, EYE(dataidx).aoi,...
                    struct(...
                        'name', currAOIdesc.spandesc.name,...
                        'type', 'polygon',...
                        'absLatencies', allLatencies{latidx},...
                        'coords', struct(...
                            'x', repmat(currAOIdesc.coords.x(:), 1, numel(allLatencies{latidx})),...
                            'y', repmat(currAOIdesc.coords.y(:), 1, numel(allLatencies{latidx}))...
                            ),...
                        'gaze', struct(...
                            'x', EYE(dataidx).gaze.x(allLatencies{latidx}),...
                            'y', EYE(dataidx).gaze.y(allLatencies{latidx})...
                            ),...
                        'stats', struct([])...
                    )...
                );
        end
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end
fprintf('Done\n');

end

function aoidescs = UI_getaoidescs(EYE)

aoidescs = struct([]);
while true
    coords = inputdlg({sprintf('Polygon coordinates\n\nx') 'y'}, 'Coordinates');
    if any(cellfun(@isempty, coords)) || isempty(coords)
        aoidescs = [];
        return
    end
    spandesc = UI_getspandescs(EYE, 'spanName', 'AOI', 'basic', 'off', 'n', 'single');
    if isempty(spandesc)
        aoidescs = [];
        return
    end
    aoidescs = cat(2, aoidescs, struct(...
        'coords', struct(...
            'x', str2num(coords(1)),...
            'y', str2num(coords(2))),...
        'spandesc', spandesc));
    q = 'Define more AOIs?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel');
    switch a
        case 'Yes'
            continue
        case 'No'
            break
        otherwise
            aoidescs = [];
            return
    end
end

end