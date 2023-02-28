
function out = pupl_epoch_reject(EYE, varargin)
% Reject epochs
%
% Inputs:
%   method: string
%       specifies the method of epoch rejection
%   cfg: struct
%       configures the implementation of the method used
% Example:
%   pupl_epoch_reject(eye_data,...
%       'method', 'ppnmissing',...
%       'cfg', struct('thresh', 0.2))
if nargin == 0
    out = @getargs;
else
    out = sub_epoch_reject(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'method' []
    'cfg' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.method)
    method_options = {
        'Proportion missing data' 'ppnmissing'
        'Extreme pupil size' 'extremepupil'
        'Max. pupil size' 'max'
        'Min. pupil size' 'min'
        'Blink proximity' 'blink'
        'Reaction time' 'rt'
        'Event attributes' 'event'
        'Saccades' 'sacc'
        'Median absolute deviation' 'mad'
        'Standard deviation' 'std'
    };
    sel = listdlgregexp(...
        'PromptString', 'Reject trials on what basis?',...
        'ListString', method_options(:, 1),...
        'SelectionMode', 'single',...
        'regexp', false);
    if isempty(sel)
        return
    end
    args.method = method_options{sel, 2};
end

if isempty(args.cfg)
    switch args.method
        case 'ppnmissing'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) nnz(isnan(x))/numel(x), pupl_epoch_getdata(e)), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'lims', [0 1],...
                'threshname', 'Proportion of data missing');
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'max'
            units = sprintf('%s (%s, %s)', EYE(1).units.epoch{:});
            if numel(EYE) > 1
                tmp = [EYE.units];
                if ~isequal(tmp.epoch)
                    units = 'size';
                end
            end
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) max(x), pupl_epoch_getdata(e)), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', sprintf('Max. pupil %s in epoch', units));
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'min'
            units = sprintf('%s (%s, %s)', EYE(1).units.epoch{:});
            if numel(EYE) > 1
                tmp = [EYE.units];
                if ~isequal(tmp.epoch)
                    units = 'size';
                end
            end
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) min(x), pupl_epoch_getdata(e)), EYE, 'UniformOutput', false),...
                'func', @le,...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', sprintf('Min. pupil %s in epoch', units));
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'blink'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) nnz(diff(x == 'b') == 1), pupl_epoch_getdata(e, [], 'datalabel')), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', 'Number of blinks');
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'rt'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) mergefields(e, 'epoch', 'event', 'rt'), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', 'Reaction time');
            if isempty(thresh)
                return
            end
            args.cfg.thresh = thresh;
        case 'event'
            args.cfg.sel = pupl_UI_epoch_select(EYE, 'prompt', 'Reject which epochs?');
            if isempty(args.cfg.sel)
                return
            end
        case 'sacc'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) nnz(diff(x(1:end-1) == 's') == 1), pupl_epoch_getdata(e, [], 'interstices')), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', 'Number of saccades');
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'mad'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) nanmedian_bc(abs(nanmedian_bc(x) - x)), pupl_epoch_getdata(e)), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', 'Median absolute deviation');
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'std'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) nanstd_bc(x), pupl_epoch_getdata(e, [])), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', 'Standard deviation');
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
    end
end

outargs = args;

end

function EYE = sub_epoch_reject(EYE, varargin)

args = parseargs(varargin{:});

switch args.method
    case 'ppnmissing'
        data = cellfun(@(x) nnz(isnan(x))/numel(x), pupl_epoch_getdata(EYE));
        rejidx = data > parsedatastr(args.cfg.thresh, data);
    case 'max'
        data = cellfun(@(x) max(x), pupl_epoch_getdata(EYE));
        rejidx = data > parsedatastr(args.cfg.thresh, data);
    case 'min'
        data = cellfun(@(x) min(x), pupl_epoch_getdata(EYE));
        rejidx = data < parsedatastr(args.cfg.thresh, data);
    case 'blink'
        data = cellfun(@(x) nnz(diff(x == 'b') == 1), pupl_epoch_getdata(EYE, [], 'datalabel'));
        rejidx = data > parsedatastr(args.cfg.thresh, data);
    case 'rt'
        data = mergefields(EYE, 'epoch', 'event', 'rt');
        rejidx = data > parsedatastr(args.cfg.thresh, data);
    case 'event'
        rejidx = pupl_epoch_sel(EYE, args.cfg.sel);
    case 'sacc'
        rejidx = cellfun(@(x) any(x(1:end-1) == 's'), pupl_epoch_getdata(EYE, [], 'interstices'));
    case 'undo'
        rejidx = false(1, numel(EYE.epoch));
        [EYE.epoch.reject] = deal(false);
end

[EYE.epoch(rejidx).reject] = deal(true);

fprintf('%d new epochs rejected, %d epochs rejected in total\n', nnz(rejidx), nnz([EYE.epoch.reject]));

end