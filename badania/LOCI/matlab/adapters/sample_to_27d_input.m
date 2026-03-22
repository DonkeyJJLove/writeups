function data = sample_to_27d_input(sample)
%SAMPLE_TO_27D_INPUT Convert canonical normalized sample into legacy-like LOCI input.
%   DATA = SAMPLE_TO_27D_INPUT(SAMPLE) maps normalized JSON/MAT payload to a struct
%   compatible with existing feature extraction code expecting:
%       data.meta
%       data.entries(i).id/date/type/text/eot
%
%   Accepted input:
%   - struct array returned by jsondecode(sample_norm.json)
%   - struct with field `sample`
%   - struct with field `entries`

    if isstruct(sample) && isscalar(sample) && isfield(sample, 'sample')
        sample = sample.sample;
    end

    if isstruct(sample) && isscalar(sample) && isfield(sample, 'entries')
        data = sample;
        return;
    end

    if ~isstruct(sample)
        error('sample_to_27d_input:InvalidInput', ...
            'Expected struct/struct array loaded from sample_norm.json or .mat');
    end

    rows = sample(:);
    n = numel(rows);
    entries = repmat(struct('id', '', 'date', '', 'type', '', 'text', '', 'eot', false), n, 1);

    for i = 1:n
        row = rows(i);

        if isfield(row, 'entry_id')
            entries(i).id = char(string(row.entry_id));
        else
            entries(i).id = sprintf('E%04d', i-1);
        end

        if isfield(row, 'timestamp_text') && ~isempty(row.timestamp_text)
            entries(i).date = char(string(row.timestamp_text));
        else
            entries(i).date = '';
        end

        if isfield(row, 'entry_type') && ~isempty(row.entry_type)
            entries(i).type = char(string(row.entry_type));
        else
            entries(i).type = 'unknown';
        end

        if isfield(row, 'content_norm') && ~isempty(row.content_norm)
            entries(i).text = char(string(row.content_norm));
        elseif isfield(row, 'content_display') && ~isempty(row.content_display)
            entries(i).text = char(string(row.content_display));
        else
            entries(i).text = '';
        end

        entries(i).eot = false;
    end

    meta = struct();
    if n > 0 && isfield(rows(1), 'sample_id')
        meta.sample_id = char(string(rows(1).sample_id));
    else
        meta.sample_id = 'UNKNOWN_SAMPLE';
    end
    meta.source = 'canonical_sample_norm';
    meta.entry_count = n;

    data = struct('meta', meta, 'entries', entries);
end
