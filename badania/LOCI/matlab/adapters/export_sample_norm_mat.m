function outPath = export_sample_norm_mat(inputPath, outPath)
% EXPORT_SAMPLE_NORM_MAT
% Eksportuje sample_norm.json do sample_norm.mat w sposób zgodny z LOCI.
%
% Zapisuje:
%   - sample_norm : surowa struktura z jsondecode
%   - meta        : metadane eksportu
%
% UŻYCIE:
%   export_sample_norm_mat('C:\...\sample_norm.json')
%   export_sample_norm_mat('C:\...\sample_norm.json', 'C:\...\sample_norm.mat')

    if nargin < 1 || isempty(inputPath)
        error('export_sample_norm_mat:MissingInput', 'Musisz podać ścieżkę do sample_norm.json');
    end

    if ~isfile(inputPath)
        error('export_sample_norm_mat:FileNotFound', 'Nie znaleziono pliku: %s', inputPath);
    end

    if nargin < 2 || isempty(outPath)
        [folder, ~, ~] = fileparts(inputPath);
        outPath = fullfile(folder, 'sample_norm.mat');
    end

    raw = fileread(inputPath);
    sample_norm = jsondecode(raw); %#ok<NASGU>

    meta = build_export_meta(inputPath, sample_norm); %#ok<NASGU>

    save(outPath, 'sample_norm', 'meta', '-v7');

    fprintf('Saved MAT: %s\n', outPath);
end

% =========================================================================
% META
% =========================================================================

function meta = build_export_meta(inputPath, sample_norm)
    meta = struct();
    meta.exported_at   = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    meta.source_file   = inputPath;
    meta.source_format = 'json';

    meta.sample_id    = '';
    meta.entry_id     = '';
    meta.author_id    = '';
    meta.entry_type   = '';
    meta.record_count = 0;
    meta.root_class   = class(sample_norm);
    meta.root_size    = size(sample_norm);

    if isstruct(sample_norm)
        meta.record_count = numel(sample_norm);

        if numel(sample_norm) >= 1
            firstRec = sample_norm(1);

            if isfield(firstRec, 'sample_id')
                meta.sample_id = local_to_char(firstRec.sample_id);
            end

            if isfield(firstRec, 'entry_id')
                meta.entry_id = local_to_char(firstRec.entry_id);
            end

            if isfield(firstRec, 'author_id')
                meta.author_id = local_to_char(firstRec.author_id);
            end

            if isfield(firstRec, 'entry_type')
                meta.entry_type = local_to_char(firstRec.entry_type);
            end
        end
    elseif iscell(sample_norm)
        meta.record_count = numel(sample_norm);
    else
        meta.record_count = 1;
    end
end

% =========================================================================
% HELPERS
% =========================================================================

function s = local_to_char(v)
    if ischar(v)
        s = v;
        return;
    end

    if isstring(v)
        if isempty(v)
            s = '';
        else
            s = char(v(1));
        end
        return;
    end

    if isnumeric(v) || islogical(v)
        s = num2str(v);
        return;
    end

    if iscell(v)
        if isempty(v)
            s = '';
            return;
        end
        s = local_to_char(v{1});
        return;
    end

    s = '';
end