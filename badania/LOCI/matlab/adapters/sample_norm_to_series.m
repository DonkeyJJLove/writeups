function T = sample_norm_to_series(S)
% SAMPLE_NORM_TO_SERIES
% Zamienia sample_norm na spójną serię analityczną do dalszych obliczeń LOCI.
%
% OBSŁUGIWANE WEJŚCIA:
%   1. wrapper:
%      S.data = [Nx1 struct]
%
%   2. płaskie:
%      S = [Nx1 struct]
%
%   3. rekord pojedynczy:
%      S = struct(...)
%
% ZWRACA:
%   T.sample_id
%   T.count
%   T.records
%   T.entry_ids
%   T.parent_entry_ids
%   T.author_ids
%   T.author_roles
%   T.timestamps_text
%   T.timestamps_iso
%   T.content_norm
%   T.content_display
%   T.entry_types
%   T.similarity_scores
%   T.links
%   T.entities_masked
%   T.source

    records = local_extract_records(S);

    if isempty(records)
        error('sample_norm_to_series:EmptyRecords', ...
            'Nie znaleziono rekordów do konwersji.');
    end

    n = numel(records);

    T = struct();
    T.sample_id         = local_first_nonempty(records, 'sample_id', 'Sample_UNKNOWN');
    T.count             = n;
    T.records           = records;

    T.entry_ids         = cell(n,1);
    T.parent_entry_ids  = cell(n,1);
    T.author_ids        = cell(n,1);
    T.author_roles      = cell(n,1);
    T.timestamps_text   = cell(n,1);
    T.timestamps_iso    = cell(n,1);
    T.content_norm      = cell(n,1);
    T.content_display   = cell(n,1);
    T.entry_types       = cell(n,1);
    T.similarity_scores = nan(n,1);
    T.links             = cell(n,1);
    T.entities_masked   = cell(n,1);
    T.source            = cell(n,1);

    for i = 1:n
        r = records(i);

        T.entry_ids{i}        = local_get_field(r, 'entry_id', '');
        T.parent_entry_ids{i} = local_get_field(r, 'parent_entry_id', '');
        T.author_ids{i}       = local_get_field(r, 'author_id', '');
        T.author_roles{i}     = local_get_field(r, 'author_role', '');
        T.timestamps_text{i}  = local_get_field(r, 'timestamp_text', '');
        T.timestamps_iso{i}   = local_get_field(r, 'timestamp_iso', '');
        T.content_norm{i}     = local_get_field(r, 'content_norm', '');
        T.content_display{i}  = local_get_field(r, 'content_display', '');
        T.entry_types{i}      = local_get_field(r, 'entry_type', '');

        simVal = local_get_field_raw(r, 'similarity_score', NaN);
        if isnumeric(simVal) && isscalar(simVal)
            T.similarity_scores(i) = double(simVal);
        else
            T.similarity_scores(i) = NaN;
        end

        T.links{i}           = local_get_cellstr_field(r, 'links');
        T.entities_masked{i} = local_get_field_raw(r, 'entities_masked', struct());
        T.source{i}          = local_get_field_raw(r, 'source', struct());
    end
end

% =========================================================================
% INTERNALS
% =========================================================================

function records = local_extract_records(S)
    records = [];

    if isempty(S)
        return;
    end

    % wrapper: S.data
    if isstruct(S) && isscalar(S) && isfield(S, 'data')
        data = S.data;

        if isstruct(data)
            records = data(:);
            return;
        end

        if iscell(data)
            data = data(:);
            if all(cellfun(@isstruct, data))
                records = vertcat(data{:});
                records = records(:);
                return;
            end
        end
    end

    % płaski struct array
    if isstruct(S)
        records = S(:);
        return;
    end

    % cell array of structs
    if iscell(S)
        S = S(:);
        if all(cellfun(@isstruct, S))
            records = vertcat(S{:});
            records = records(:);
            return;
        end
    end
end

function value = local_get_field(r, fieldName, defaultValue)
    value = defaultValue;

    if ~isstruct(r) || ~isfield(r, fieldName)
        return;
    end

    raw = r.(fieldName);
    value = local_to_char(raw, defaultValue);
end

function value = local_get_field_raw(r, fieldName, defaultValue)
    value = defaultValue;

    if ~isstruct(r) || ~isfield(r, fieldName)
        return;
    end

    value = r.(fieldName);
end

function value = local_get_cellstr_field(r, fieldName)
    value = {};

    if ~isstruct(r) || ~isfield(r, fieldName)
        return;
    end

    raw = r.(fieldName);

    if isempty(raw)
        value = {};
        return;
    end

    if ischar(raw)
        value = {raw};
        return;
    end

    if isstring(raw)
        value = cellstr(raw(:));
        return;
    end

    if iscell(raw)
        out = cell(size(raw));
        for k = 1:numel(raw)
            out{k} = local_to_char(raw{k}, '');
        end
        value = out(:).';
        return;
    end

    value = {local_to_char(raw, '')};
end

function out = local_first_nonempty(records, fieldName, fallback)
    out = fallback;

    for i = 1:numel(records)
        if isfield(records(i), fieldName)
            v = local_to_char(records(i).(fieldName), '');
            if ~isempty(strtrim(v))
                out = v;
                return;
            end
        end
    end
end

function s = local_to_char(v, defaultValue)
    if nargin < 2
        defaultValue = '';
    end

    s = defaultValue;

    if isempty(v)
        return;
    end

    if ischar(v)
        s = v;
        return;
    end

    if isstring(v)
        if ~isempty(v)
            s = char(v(1));
        end
        return;
    end

    if isnumeric(v) || islogical(v)
        if isscalar(v)
            s = num2str(v);
        else
            s = mat2str(v);
        end
        return;
    end

    if iscell(v)
        if ~isempty(v)
            s = local_to_char(v{1}, defaultValue);
        end
        return;
    end

    if isstruct(v)
        try
            s = jsonencode(v);
        catch
            s = defaultValue;
        end
        return;
    end
end