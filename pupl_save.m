function pupl_save(varargin)

% Save eye data or event logs
%   Inputs
% type--data type: see getextfromdatatype for more info
% data--struct array of eye dats to be saved
% directory--directory to save to
% name--char description of data being saved

p = inputParser;
addParameter(p, 'type', [])
addParameter(p, 'data', [])
addParameter(p, 'directory', [])
addParameter(p, 'name', [])
parse(p, varargin{:});

fileExt = getextfromdatatype(p.Results.type);

if isempty(p.Results.data)
    vars = who;
    cmd = sprintf('structArray = %s',...
        vars{listdlg('PromptString', 'Save which variables from the workspace?',...
            'ListString', vars)});
    eval(cmd);
else
    structArray = p.Results.data;
end

if isempty(p.Results.name)
    name = 'data';
else
    name = p.Results.name;
end

if isempty(p.Results.directory)
    saveDirectory = uigetdir('.',...
        sprintf('Save %s', name));
    if saveDirectory == 0
        fprintf('Not saving %s\n', name);
        return
    end
else
    saveDirectory = p.Results.directory;
end

for data = structArray(:)'
    save(strcat(saveDirectory, '\\', data.name, fileExt), 'data');
end

end