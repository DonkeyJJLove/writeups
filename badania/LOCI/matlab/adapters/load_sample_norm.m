function S = load_sample_norm(inputPath)
% LOAD_SAMPLE_NORM
% Ładuje sample_norm z JSON lub MAT i zwraca spójny wrapper:
%
%   S.source_file
%   S.source_ext
%   S.loaded_at
%   S.format
%   S.data
%
% UŻYCIE:
%   S = load_sample_norm('...\sample_norm.json');
%   S = load_sample_norm('...\sample_norm.mat');

    if nargin < 1 || isempty(inputPath)
        error('load_sample_norm:MissingInput', 'Musisz podać ścieżkę wejściową.');
    end

    if ~isfile(inputPath)
        error('load_sample_norm:FileNotFound', 'Nie znaleziono pliku: %s', inputPath);
    end

    [~, ~, ext] = fileparts(inputPath);
    ext = lower(ext);

    switch ext
        case '.json'
            raw = fileread(inputPath);
            data = jsondecode(raw);

            S = struct();
            S.source_file = inputPath;
            S.source_ext  = '.json';
            S.loaded_at   = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

            if isstruct(data) && numel(data) > 1
                S.format = 'json_struct_array';
            elseif isstruct(data)
                S.format = 'json_struct';
            elseif iscell(data)
                S.format = 'json_cell';
            else
                S.format = 'json_scalar';
            end

            S.data = data;

        case '.mat'
            tmp = load(inputPath);

            if isfield(tmp, 'sample_norm')
                sn = tmp.sample_norm;
            else
                f = fieldnames(tmp);
                if isempty(f)
                    error('load_sample_norm:EmptyMat', 'Plik MAT jest pusty: %s', inputPath);
                end
                sn = tmp.(f{1});
            end

            if isstruct(sn) && isfield(sn, 'data')
                S = sn;

                if ~isfield(S, 'source_file') || isempty(S.source_file)
                    S.source_file = inputPath;
                end
                if ~isfield(S, 'source_ext') || isempty(S.source_ext)
                    S.source_ext = '.mat';
                end
                if ~isfield(S, 'loaded_at') || isempty(S.loaded_at)
                    S.loaded_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
                end
                if ~isfield(S, 'format') || isempty(S.format)
                    S.format = 'mat_wrapper';
                end

            else
                S = struct();
                S.source_file = inputPath;
                S.source_ext  = '.mat';
                S.loaded_at   = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
                S.format      = 'mat_flat';
                S.data        = sn;
            end

        otherwise
            error('load_sample_norm:UnsupportedExtension', ...
                'Nieobsługiwane rozszerzenie: %s', ext);
    end
end