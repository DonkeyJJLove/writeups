function R = loci_sample_text_all_in_one(sampleFile, userCfg)
% LOCI_SAMPLE_TEXT_ALL_IN_ONE
% Kompletny, samowystarczalny detektor LOCI dla sekwencji generacji tekstu.
%
% Wersja naprawiona:
%   - działa bez argumentu wejściowego,
%   - preferuje plik NORM (sample/norm/Sample_0001n.m),
%   - poprawnie parsuje format NORM z nagłówkiem:
%       SAMPLE_0001N / FORMAT_VERSION / TYPE / DATE / Gxxxx,
%   - ma fallback do pliku RAW (sample/raw/Sample_0001.m),
%   - potrafi odczytać także pliki leżące obok skryptu lub w bieżącym katalogu.
%
% Użycie:
%   R = loci_sample_text_all_in_one();
%   R = loci_sample_text_all_in_one('sample/norm/Sample_0001n.m');
%   R = loci_sample_text_all_in_one('sample/raw/Sample_0001.m');
%   R = loci_sample_text_all_in_one([], struct('make_plot', false));
%
% Wejście:
%   sampleFile - opcjonalna ścieżka do pliku wejściowego.
%   userCfg    - opcjonalna struktura nadpisująca pola konfiguracyjne.
%
% Wyjście:
%   R - struktura z pełnym raportem, tabelami i sygnałami pomocniczymi.

    if nargin < 1
        sampleFile = '';
    end
    if nargin < 2 || isempty(userCfg)
        userCfg = struct();
    end

    [sampleFile, repoInfo] = i_resolve_sample_path(sampleFile);

    fprintf('============================================================\n');
    fprintf('LOCI SAMPLE TEXT ALL IN ONE\n');
    fprintf('Plik wejściowy: %s\n', sampleFile);
    fprintf('Katalog skryptu: %s\n', repoInfo.script_dir);
    fprintf('============================================================\n\n');

    cfg = i_default_cfg();
    cfg = i_apply_cfg_overrides(cfg, userCfg);

    [generations, sourceInfo] = i_load_generations(sampleFile);
    sourceInfo.repo_info = repoInfo;

    nG = numel(generations);
    fprintf('Wykryto generacji: %d\n', nG);

    if nG < 12
        error('Za mało generacji do wiarygodnej analizy LOCI. Minimum: 12. Odczytano: %d.', nG);
    end

    features = i_build_features(generations, cfg);
    cfg = i_cfg_local_defaults(cfg, height(features));

    localDet = i_detect_loci_local_multiscale(features, cfg);

    onset_idx      = localDet.onset_idx;
    max_slope_idx  = localDet.max_slope_idx;
    max_curv_idx   = localDet.max_curv_idx;

    score_raw      = localDet.score_local_raw;
    score_smooth   = localDet.score_local_smooth;
    dscore         = localDet.dscore;
    d2score        = localDet.d2score;
    interior_mask  = localDet.valid_mask;
    onset_mask     = false(numel(score_smooth),1);
    if ~isnan(onset_idx) && onset_idx >= 1 && onset_idx <= numel(onset_mask)
        onset_mask(onset_idx) = true;
    end

    evidence = i_build_evidence_local(localDet, features, cfg);
    rigorous = i_run_rigorous_local_test(features, localDet, cfg);
    verdict  = i_make_local_verdict(localDet, rigorous, cfg);

    result_table = i_build_result_table_local(features, score_raw, score_smooth, dscore, d2score, localDet);

    R = struct();
    R.sample_file     = sampleFile;
    R.repo_info       = repoInfo;
    R.source_info     = sourceInfo;
    R.generations     = generations;
    R.features        = features;
    R.result_table    = result_table;
    R.n_generations   = height(features);
    R.onset_idx       = onset_idx;
    R.max_slope_idx   = max_slope_idx;
    R.max_curv_idx    = max_curv_idx;
    R.score_raw       = score_raw;
    R.score_smooth    = score_smooth;
    R.dscore          = dscore;
    R.d2score         = d2score;
    R.interior_mask   = interior_mask;
    R.onset_mask      = onset_mask;
    R.evidence        = evidence;
    R.rigorous        = rigorous;
    R.verdict         = verdict;
    R.local_detector  = localDet;

    i_print_local_summary(R);
    i_print_local_report(R);

    if isfield(cfg, 'make_plot') && cfg.make_plot
        i_plot_local_detector(R, cfg);
    end
end

% ============================================================
% ŚCIEŻKI / NADPISANIA CFG
% ============================================================
function cfg = i_apply_cfg_overrides(cfg, userCfg)
    if nargin < 2 || isempty(userCfg) || ~isstruct(userCfg)
        return;
    end
    fn = fieldnames(userCfg);
    for k = 1:numel(fn)
        cfg.(fn{k}) = userCfg.(fn{k});
    end
end

function [sampleFile, repoInfo] = i_resolve_sample_path(sampleFile)
    thisPath = mfilename('fullpath');
    if isempty(thisPath)
        scriptDir = pwd;
    else
        scriptDir = fileparts(thisPath);
    end

    repoInfo = struct();
    repoInfo.script_dir = scriptDir;
    repoInfo.default_sample_used = false;

    if nargin < 1 || isempty(sampleFile)
        sampleFile = '';
    end
    sampleFile = char(string(sampleFile));

    % 1) jeśli użytkownik podał istniejący plik - użyj go bez zmian
    if ~isempty(sampleFile) && isfile(sampleFile)
        return;
    end

    % 2) kandydaci względni względem katalogu skryptu oraz bieżącego katalogu
    if ~isempty(sampleFile)
        relCandidates = { ...
            fullfile(scriptDir, sampleFile), ...
            fullfile(pwd, sampleFile), ...
            fullfile(scriptDir, 'sample', 'norm', sampleFile), ...
            fullfile(scriptDir, 'sample', 'raw',  sampleFile), ...
            fullfile(pwd, 'sample', 'norm', sampleFile), ...
            fullfile(pwd, 'sample', 'raw',  sampleFile)};
        for i = 1:numel(relCandidates)
            if isfile(relCandidates{i})
                sampleFile = relCandidates{i};
                return;
            end
        end

        % 3) jeżeli użytkownik podał RAW, spróbuj automatycznie odpowiadający NORM
        altNorm = i_find_sidecar_norm(sampleFile, scriptDir);
        if ~isempty(altNorm)
            sampleFile = altNorm;
            repoInfo.default_sample_used = false;
            repoInfo.auto_switched_to_norm = true;
            return;
        end

        error('Nie znaleziono pliku: %s', sampleFile);
    end

    % 4) bez argumentu: preferuj NORM, potem RAW
    candidates = { ...
        fullfile(scriptDir, 'sample', 'norm', 'Sample_0001n.m'), ...
        fullfile(scriptDir, 'sample', 'norm', 'Sample_0001N.m'), ...
        fullfile(scriptDir, 'sample', 'norm', 'SAMPLE_0001N.m'), ...
        fullfile(scriptDir, 'Sample_0001n.m'), ...
        fullfile(scriptDir, 'Sample_0001N.m'), ...
        fullfile(scriptDir, 'SAMPLE_0001N.m'), ...
        fullfile(pwd,      'sample', 'norm', 'Sample_0001n.m'), ...
        fullfile(pwd,      'sample', 'norm', 'Sample_0001N.m'), ...
        fullfile(pwd,      'sample', 'norm', 'SAMPLE_0001N.m'), ...
        fullfile(pwd,      'Sample_0001n.m'), ...
        fullfile(pwd,      'Sample_0001N.m'), ...
        fullfile(pwd,      'SAMPLE_0001N.m'), ...
        fullfile(scriptDir, 'sample', 'raw',  'Sample_0001.m'), ...
        fullfile(scriptDir, 'Sample_0001.m'), ...
        fullfile(pwd,      'sample', 'raw',  'Sample_0001.m'), ...
        fullfile(pwd,      'Sample_0001.m')};

    for i = 1:numel(candidates)
        if isfile(candidates{i})
            sampleFile = candidates{i};
            repoInfo.default_sample_used = true;
            return;
        end
    end

    error(['Nie znaleziono domyślnego pliku wejściowego. Oczekiwano np.:' newline ...
           '  sample/norm/Sample_0001n.m  lub  sample/raw/Sample_0001.m']);
end

function altNorm = i_find_sidecar_norm(sampleFile, scriptDir)
    altNorm = '';
    [p,n,~] = fileparts(sampleFile);

    cands = { ...
        fullfile(p, [n 'n.m']), ...
        fullfile(p, [n 'N.m']), ...
        fullfile(fileparts(p), 'norm', [n 'n.m']), ...
        fullfile(fileparts(p), 'norm', [n 'N.m']), ...
        fullfile(scriptDir, 'sample', 'norm', 'Sample_0001n.m'), ...
        fullfile(scriptDir, 'sample', 'norm', 'Sample_0001N.m')};

    for i = 1:numel(cands)
        if isfile(cands{i})
            altNorm = cands{i};
            return;
        end
    end
end

% ============================================================
% KONFIGURACJA
% ============================================================
function cfg = i_default_cfg()
    cfg = struct();
    cfg.make_plot = true;
    cfg.min_tokens = 1;
    cfg.stopwords = ["the","a","an","and","or","of","to","in","on","for","with","is","are", ...
                     "was","were","be","as","by","at","it","that","this","from","will","after", ...
                     "which","he","she","they","we","you","i"];
    cfg.eps_mad = 1e-9;
    cfg.clip_z = 4.0;
    cfg.winsor_q = 0.01;
    cfg.smooth_span = 11;
    cfg.segment_halfwin_ratio = 0.45;
    cfg.feature_weights = [];
    cfg.cluster_tol_ratio = 0.35;
    cfg.n_bootstrap = 200;
    cfg.n_perm = 200;
    cfg.rng_seed = 42;
    cfg.null_block_min = 25;
    cfg.null_block_max = 120;
    cfg.verdict_min_peak_contrast = 2.5;
    cfg.verdict_min_scale_agree = 0.50;
    cfg.verdict_min_boot_agree = 0.40;
    cfg.verdict_max_boot_ci_width_ratio = 0.35;
    cfg.verdict_min_perm_sep = 0.80;
    cfg.feature_signs = struct( ...
        'd_len_words',      +1, ...
        'novelty_prev',     +1, ...
        'drift_prev',       +1, ...
        'new_vocab_ratio',  +1, ...
        'd_entropy',        +1, ...
        'repetition',       -1, ...
        'char_complexity',  +1, ...
        'punct_ratio',      +1, ...
        'avg_word_len',     +1, ...
        'line_break_ratio', +1);
end

function cfg = i_cfg_local_defaults(cfg, n)
    if nargin < 1 || isempty(cfg), cfg = struct(); end
    if ~isfield(cfg, 'make_plot'), cfg.make_plot = true; end
    if ~isfield(cfg, 'eps_mad'), cfg.eps_mad = 1e-9; end
    if ~isfield(cfg, 'clip_z'), cfg.clip_z = 4.0; end
    if ~isfield(cfg, 'winsor_q'), cfg.winsor_q = 0.01; end
    if ~isfield(cfg, 'smooth_span'), cfg.smooth_span = 11; end
    if ~isfield(cfg, 'local_scales')
        base = unique(max(21, 2 * floor(([31 61 121 241 401] ./ 2)) + 1));
        cfg.local_scales = base(base < max(25, floor(n * 0.35)));
        if isempty(cfg.local_scales)
            s = min(max(21, floor(n/5)), max(21, n-3));
            cfg.local_scales = max(21, 2 * floor(s / 2) + 1);
        end
    end
    if ~isfield(cfg, 'segment_halfwin_ratio'), cfg.segment_halfwin_ratio = 0.45; end
    if ~isfield(cfg, 'feature_weights'), cfg.feature_weights = []; end
    if ~isfield(cfg, 'cluster_tol_ratio'), cfg.cluster_tol_ratio = 0.35; end
    if ~isfield(cfg, 'n_bootstrap'), cfg.n_bootstrap = 250; end
    if ~isfield(cfg, 'n_perm'), cfg.n_perm = 250; end
    if ~isfield(cfg, 'rng_seed'), cfg.rng_seed = 42; end
    if ~isfield(cfg, 'null_block_min'), cfg.null_block_min = 25; end
    if ~isfield(cfg, 'null_block_max'), cfg.null_block_max = 120; end
    if ~isfield(cfg, 'verdict_min_peak_contrast'), cfg.verdict_min_peak_contrast = 2.5; end
    if ~isfield(cfg, 'verdict_min_scale_agree'), cfg.verdict_min_scale_agree = 0.50; end
    if ~isfield(cfg, 'verdict_min_boot_agree'), cfg.verdict_min_boot_agree = 0.40; end
    if ~isfield(cfg, 'verdict_max_boot_ci_width_ratio'), cfg.verdict_max_boot_ci_width_ratio = 0.35; end
    if ~isfield(cfg, 'verdict_min_perm_sep'), cfg.verdict_min_perm_sep = 0.80; end
    if ~isfield(cfg, 'feature_signs'), cfg.feature_signs = struct(); end
end

% ============================================================
% WCZYTANIE GENERACJI
% ============================================================
function [generations, sourceInfo] = i_load_generations(sampleFile)
    txt = fileread(sampleFile);
    txt = strrep(txt, sprintf('\r\n'), sprintf('\n'));
    txt = strrep(txt, sprintf('\r'),   sprintf('\n'));

    sourceInfo = struct();
    sourceInfo.file_size_chars = strlength(string(txt));
    sourceInfo.format_detected = i_detect_file_format(txt, sampleFile);

    generations = struct([]);
    parseMode = '';

    if strcmp(sourceInfo.format_detected, 'norm')
        [generations, metaNorm] = i_parse_generations_norm_file(txt);
        parseMode = 'norm_file';
        sourceInfo.norm_meta = metaNorm;
    end

    if isempty(generations) || numel(generations) < 3
        generations = i_parse_generations_raw_blocks(txt);
        parseMode = 'raw_blocks';
    end
    if isempty(generations) || numel(generations) < 3
        generations = i_parse_generations_structured_lines(txt);
        parseMode = 'structured_lines';
    end
    if isempty(generations) || numel(generations) < 3
        generations = i_parse_generations_quoted_strings(txt);
        parseMode = 'quoted_strings';
    end
    if isempty(generations) || numel(generations) < 3
        generations = i_parse_generations_paragraphs(txt);
        parseMode = 'paragraphs';
    end
    if isempty(generations) || numel(generations) < 3
        generations = i_parse_generations_nonempty_lines(txt);
        parseMode = 'nonempty_lines';
    end

    if isempty(generations) || numel(generations) < 3
        error('Nie udało się odczytać wystarczającej liczby generacji z pliku: %s', sampleFile);
    end

    sourceInfo.parse_mode = parseMode;
    sourceInfo.n_generations = numel(generations);
end

function fmt = i_detect_file_format(txt, sampleFile)
    fmt = 'raw';
    [~,name,~] = fileparts(sampleFile);
    if ~isempty(regexpi(name, '0001n$', 'once'))
        fmt = 'norm';
        return;
    end
    if ~isempty(regexp(txt, '^\s*SAMPLE_\d+N\s*$', 'once', 'lineanchors')) || ...
       ~isempty(regexp(txt, '^\s*FORMAT_VERSION\s*:\s*', 'once', 'lineanchors')) || ...
       ~isempty(regexp(txt, '^\s*BASELINE_ID\s*:\s*G\d+', 'once', 'lineanchors'))
        fmt = 'norm';
    end
end

function [generations, meta] = i_parse_generations_norm_file(txt)
    lines = regexp(txt, '\n', 'split');
    lines = string(lines(:));

    payload = strings(0,1);
    ids     = strings(0,1);
    dates   = strings(0,1);
    types   = strings(0,1);

    meta = struct();
    meta.format_version   = '';
    meta.description      = '';
    meta.source_file      = '';
    meta.total_generations= NaN;
    meta.baseline_id      = '';
    meta.date_format      = '';

    currentDate = '';
    currentType = '';

    i = 1;
    while i <= numel(lines)
        line = strtrim(lines(i));

        if line == ""
            i = i + 1;
            continue;
        end

        if ~isempty(regexpi(line, '^FORMAT_VERSION\s*:', 'once'))
            meta.format_version = i_value_after_colon(line);
            i = i + 1;
            continue;
        end
        if ~isempty(regexpi(line, '^DESCRIPTION\s*:', 'once'))
            meta.description = i_value_after_colon(line);
            i = i + 1;
            continue;
        end
        if ~isempty(regexpi(line, '^SOURCE_FILE\s*:', 'once'))
            meta.source_file = i_value_after_colon(line);
            i = i + 1;
            continue;
        end
        if ~isempty(regexpi(line, '^TOTAL_GENERATIONS\s*:', 'once'))
            tmp = str2double(i_value_after_colon(line));
            if ~isnan(tmp), meta.total_generations = tmp; end
            i = i + 1;
            continue;
        end
        if ~isempty(regexpi(line, '^BASELINE_ID\s*:', 'once'))
            meta.baseline_id = i_value_after_colon(line);
            i = i + 1;
            continue;
        end
        if ~isempty(regexpi(line, '^DATE_FORMAT\s*:', 'once'))
            meta.date_format = i_value_after_colon(line);
            i = i + 1;
            continue;
        end
        if ~isempty(regexpi(line, '^DATE\s*:', 'once'))
            currentDate = i_value_after_colon(line);
            i = i + 1;
            continue;
        end
        if ~isempty(regexpi(line, '^TYPE\s*:', 'once'))
            currentType = i_value_after_colon(line);
            i = i + 1;
            continue;
        end

        tok = regexp(char(line), '^(G\d{4,})\s*:\s*(.*)$', 'tokens', 'once');
        if ~isempty(tok)
            gid = string(tok{1});
            rest = string(tok{2});

            % Jeżeli cytat nie domknął się w tej linii, dociągnij kolejne linie.
            qcount = count(rest, '"');
            while mod(qcount, 2) == 1 && i < numel(lines)
                i = i + 1;
                rest = rest + newline + string(lines(i));
                qcount = count(rest, '"');
            end

            text = i_normalize_generation_payload(rest);

            payload(end+1,1) = text; %#ok<AGROW>
            ids(end+1,1)     = gid;  %#ok<AGROW>
            dates(end+1,1)   = currentDate; %#ok<AGROW>
            types(end+1,1)   = currentType; %#ok<AGROW>
        end

        i = i + 1;
    end

    generations = i_finalize_generations(payload);
    if isempty(generations)
        return;
    end

    if isfield(meta, 'baseline_id') && strlength(string(meta.baseline_id)) == 0
        meta.baseline_id = ids(1);
    end

    for k = 1:numel(generations)
        generations(k).id   = char(ids(k));
        generations(k).date = char(dates(k));
        generations(k).type = char(types(k));
    end
end

function generations = i_parse_generations_raw_blocks(txt)
    lines = regexp(txt, '\n', 'split');
    lines = string(lines(:));

    payload = strings(0,1);
    block = strings(0,1);

    for i = 1:numel(lines)
        line = lines(i);
        if i_is_date_delimiter_line(strtrim(line))
            out = i_collapse_raw_block(block);
            if strlength(out) > 0
                payload(end+1,1) = out; %#ok<AGROW>
            end
            block = strings(0,1);
        else
            block(end+1,1) = line; %#ok<AGROW>
        end
    end

    out = i_collapse_raw_block(block);
    if strlength(out) > 0
        payload(end+1,1) = out; %#ok<AGROW>
    end

    generations = i_finalize_generations(payload);
end

function tf = i_is_date_delimiter_line(line)
    if nargin < 1
        tf = false;
        return;
    end
    line = string(line);
    tf = false;
    if line == ""
        return;
    end
    if ~isempty(regexp(char(line), '^(DATE\s*:\s*)?\d{4}-\d{2}-\d{2}$', 'once', 'ignorecase'))
        tf = true;
        return;
    end
    if ~isempty(regexp(char(line), '^\d{1,2}\s+\S+\s+\d{4}$', 'once'))
        tf = true;
    end
end

function out = i_collapse_raw_block(blockLines)
    if isempty(blockLines)
        out = "";
        return;
    end
    x = string(blockLines(:));
    x = strip(x);
    x(x == "") = [];
    if isempty(x)
        out = "";
        return;
    end
    out = strjoin(cellstr(x), ' ');
    out = regexprep(out, '\s+', ' ');
    out = strtrim(out);
end

function val = i_value_after_colon(line)
    tok = regexp(char(line), '^[^:]+:\s*(.*)$', 'tokens', 'once');
    if isempty(tok)
        val = '';
    else
        val = strtrim(string(tok{1}));
    end
end

function text = i_normalize_generation_payload(rest)
    text = string(rest);
    text = strrep(text, sprintf('\r\n'), sprintf('\n'));
    text = strrep(text, sprintf('\r'),   sprintf('\n'));

    % Jeżeli cały payload jest domknięty w zewnętrznym cudzysłowie - usuń tylko skrajne znaki.
    s = strtrim(text);
    if strlength(s) >= 2
        cs = char(s);
        if cs(1) == '"' && cs(end) == '"'
            s = string(cs(2:end-1));
        end
    end

    s = regexprep(s, '\s+', ' ');
    text = strtrim(s);
end

function generations = i_parse_generations_structured_lines(txt)
    lines = regexp(txt, '\n', 'split');
    lines = string(lines(:));
    keep = false(size(lines));
    payload = strings(size(lines));

    for i = 1:numel(lines)
        line = strtrim(lines(i));
        tok = regexp(char(line), '^(G\d+|Gen\s*\d+|Generation\s*\d+|\d+)\s*[:\-]\s*(.*)$', 'tokens', 'once');
        if ~isempty(tok)
            keep(i) = true;
            payload(i) = string(tok{2});
        end
    end

    payload = payload(keep);
    payload = strip(payload);
    payload(payload == "") = [];
    generations = i_finalize_generations(payload);
end

function generations = i_parse_generations_quoted_strings(txt)
    pat = '"((?:[^"]|"")*)"';
    toks = regexp(txt, pat, 'tokens');
    payload = strings(0,1);
    for i = 1:numel(toks)
        s = string(toks{i}{1});
        s = strrep(s, '""', '"');
        s = strtrim(s);
        if strlength(s) > 0
            payload(end+1,1) = s; %#ok<AGROW>
        end
    end
    generations = i_finalize_generations(payload);
end

function generations = i_parse_generations_paragraphs(txt)
    blocks = regexp(txt, '\n\s*\n+', 'split');
    payload = strings(0,1);
    for i = 1:numel(blocks)
        s = strtrim(string(blocks{i}));
        if strlength(s) > 0
            payload(end+1,1) = s; %#ok<AGROW>
        end
    end
    generations = i_finalize_generations(payload);
end

function generations = i_parse_generations_nonempty_lines(txt)
    lines = regexp(txt, '\n', 'split');
    payload = strings(0,1);
    for i = 1:numel(lines)
        s = strtrim(string(lines{i}));
        if strlength(s) > 0
            payload(end+1,1) = s; %#ok<AGROW>
        end
    end
    generations = i_finalize_generations(payload);
end

function generations = i_finalize_generations(payload)
    payload = string(payload(:));
    payload = strip(payload);
    payload(payload == "") = [];
    if isempty(payload)
        generations = struct('idx', {}, 'text', {}, 'tokens', {});
        return;
    end

    keep = true(numel(payload),1);
    for i = 2:numel(payload)
        if payload(i) == payload(i-1)
            keep(i) = false;
        end
    end
    payload = payload(keep);

    generations = repmat(struct('idx', 0, 'text', "", 'tokens', {{}}), numel(payload), 1);
    for i = 1:numel(payload)
        generations(i).idx = i;
        generations(i).text = payload(i);
        generations(i).tokens = i_tokenize_text(payload(i));
    end
end

% ============================================================
% CECHY TEKSTOWE
% ============================================================
function features = i_build_features(generations, cfg)
    n = numel(generations);

    len_words      = zeros(n,1);
    novelty_prev   = zeros(n,1);
    drift_prev     = zeros(n,1);
    new_vocab_ratio= zeros(n,1);
    entropy_words  = zeros(n,1);
    repetition     = zeros(n,1);
    char_complexity= zeros(n,1);
    punct_ratio    = zeros(n,1);
    avg_word_len   = zeros(n,1);
    line_break_ratio = zeros(n,1);

    vocab_seen = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for i = 1:n
        text = string(generations(i).text);
        tokens = generations(i).tokens;

        len_words(i)       = numel(tokens);
        entropy_words(i)   = i_shannon_entropy(tokens);
        repetition(i)      = i_repetition_ratio(tokens);
        char_complexity(i) = i_char_complexity(text);
        punct_ratio(i)     = i_punct_ratio(text);
        avg_word_len(i)    = i_avg_word_len(tokens);
        line_break_ratio(i)= i_line_break_ratio(text);

        if i > 1
            prevTokens = generations(i-1).tokens;
            novelty_prev(i) = i_token_novelty(prevTokens, tokens);
            drift_prev(i)   = i_normalized_edit_distance_words(prevTokens, tokens);
        else
            novelty_prev(i) = 0;
            drift_prev(i) = 0;
        end

        if isempty(tokens)
            new_vocab_ratio(i) = 0;
        else
            newCount = 0;
            for k = 1:numel(tokens)
                tk = char(tokens{k});
                if ~isKey(vocab_seen, tk)
                    vocab_seen(tk) = 1;
                    newCount = newCount + 1;
                else
                    vocab_seen(tk) = vocab_seen(tk) + 1;
                end
            end
            new_vocab_ratio(i) = newCount / max(numel(tokens), 1);
        end
    end

    d_len_words = [0; diff(len_words)];
    d_entropy   = [0; diff(entropy_words)];

    features = table( ...
        d_len_words, novelty_prev, drift_prev, new_vocab_ratio, d_entropy, ...
        repetition, char_complexity, punct_ratio, avg_word_len, line_break_ratio);
end

function tokens = i_tokenize_text(txt)
    txt = lower(string(txt));
    txt = regexprep(txt, '[^\p{L}\p{N}\s]+', ' ');
    parts = regexp(char(txt), '\s+', 'split');
    parts = parts(~cellfun(@isempty, parts));
    tokens = parts(:)';
end

function h = i_shannon_entropy(tokens)
    if isempty(tokens)
        h = 0;
        return;
    end
    [u,~,idx] = unique(tokens);
    counts = accumarray(idx(:), 1, [numel(u),1]);
    p = counts / sum(counts);
    h = -sum(p .* log2(max(p, eps)));
end

function r = i_repetition_ratio(tokens)
    if isempty(tokens)
        r = 0;
        return;
    end
    [u,~,idx] = unique(tokens);
    counts = accumarray(idx(:), 1, [numel(u),1]);
    r = sum(max(counts - 1, 0)) / max(numel(tokens), 1);
end

function c = i_char_complexity(txt)
    s = char(txt);
    if isempty(s)
        c = 0;
        return;
    end
    chars = cellstr(reshape(s(:),1,[]).');
    [u,~,idx] = unique(chars);
    counts = accumarray(idx(:), 1, [numel(u),1]);
    p = counts / sum(counts);
    c = -sum(p .* log2(max(p, eps)));
end

function r = i_punct_ratio(txt)
    s = char(txt);
    if isempty(s)
        r = 0;
        return;
    end
    nP = sum(~isstrprop(s, 'alphanum') & ~isspace(s));
    r = nP / max(numel(s), 1);
end

function a = i_avg_word_len(tokens)
    if isempty(tokens)
        a = 0;
        return;
    end
    lens = cellfun(@strlength, string(tokens));
    a = mean(double(lens));
end

function r = i_line_break_ratio(txt)
    s = char(txt);
    if isempty(s)
        r = 0;
        return;
    end
    r = sum(s == newline) / max(numel(s),1);
end

function n = i_token_novelty(prevTokens, tokens)
    if isempty(tokens)
        n = 0;
        return;
    end
    if isempty(prevTokens)
        n = 1;
        return;
    end
    prevSet = unique(string(prevTokens));
    tok = string(tokens);
    n = mean(~ismember(tok, prevSet));
end

function d = i_normalized_edit_distance_words(a, b)
    if isstring(a), a = cellstr(a); end
    if isstring(b), b = cellstr(b); end
    if ischar(a),   a = regexp(a, '\s+', 'split'); end
    if ischar(b),   b = regexp(b, '\s+', 'split'); end

    a = a(:)';
    b = b(:)';

    na = numel(a);
    nb = numel(b);

    if na == 0 && nb == 0
        d = 0;
        return;
    end

    D = zeros(na+1, nb+1);
    D(:,1) = 0:na;
    D(1,:) = 0:nb;

    for i = 2:(na+1)
        for j = 2:(nb+1)
            cost = ~strcmp(a{i-1}, b{j-1});
            D(i,j) = min([D(i-1,j) + 1, D(i,j-1) + 1, D(i-1,j-1) + cost]);
        end
    end

    denom = max([na, nb, 1]);
    d = D(end,end) / denom;
end

% ============================================================
% DETEKTOR LOKALNY
% ============================================================
function localDet = i_detect_loci_local_multiscale(featuresTbl, cfg)
    X = table2array(featuresTbl);
    [n,p] = size(X);

    if isempty(cfg.feature_weights)
        w = ones(1,p) / p;
    else
        w = cfg.feature_weights(:)';
        if numel(w) ~= p
            error('cfg.feature_weights musi mieć długość równą liczbie cech.');
        end
        w = w / sum(abs(w));
    end

    rng(cfg.rng_seed, 'twister');
    varNames = featuresTbl.Properties.VariableNames;
    signs = i_feature_sign_vector(varNames, cfg);

    Xw = i_winsorize_matrix(X, cfg.winsor_q);
    Xw = Xw .* signs;

    scales = cfg.local_scales(:)';
    K = numel(scales);

    score_by_scale_raw    = nan(n, K);
    score_by_scale_smooth = nan(n, K);
    contrast_by_scale     = nan(n, K);
    onset_by_scale        = nan(K,1);
    peak_by_scale         = nan(K,1);
    maxSlope_by_scale     = nan(K,1);
    maxCurv_by_scale      = nan(K,1);
    valid_by_scale        = false(n, K);
    Z_by_scale            = cell(K,1);

    for k = 1:K
        local_window = scales(k);
        h = max(10, floor(local_window * cfg.segment_halfwin_ratio));

        Z = i_local_robust_z(Xw, local_window, cfg.clip_z, cfg.eps_mad);
        score_raw = Z * w(:);
        score_smooth = smoothdata(score_raw, 'movmedian', min(cfg.smooth_span, max(3,n-1)));

        [contrast, valid_mask] = i_segment_contrast(score_smooth, h, cfg.eps_mad);

        score_by_scale_raw(:,k)    = score_raw;
        score_by_scale_smooth(:,k) = score_smooth;
        contrast_by_scale(:,k)     = contrast;
        valid_by_scale(:,k)        = valid_mask;
        Z_by_scale{k}              = Z;

        if any(valid_mask)
            tmp = contrast;
            tmp(~valid_mask) = -Inf;
            [peakVal, idx] = max(tmp);
            if isfinite(peakVal)
                onset_by_scale(k) = idx;
                peak_by_scale(k)  = peakVal;
            end
        end

        ds  = [NaN; diff(score_smooth)];
        d2s = [NaN; diff(ds)];
        vv  = valid_mask & isfinite(ds);
        if any(vv)
            tmp = abs(ds);
            tmp(~vv) = -Inf;
            [~, ms] = max(tmp);
            maxSlope_by_scale(k) = ms;
        end
        vv2 = valid_mask & isfinite(d2s);
        if any(vv2)
            tmp = abs(d2s);
            tmp(~vv2) = -Inf;
            [~, mc] = max(tmp);
            maxCurv_by_scale(k) = mc;
        end
    end

    [onset_idx, clusterInfo] = i_cluster_onsets(onset_by_scale, peak_by_scale, scales, n, cfg);

    if isnan(onset_idx)
        [~, bestk] = max(peak_by_scale);
        onset_idx = onset_by_scale(bestk);
    else
        d = abs(onset_by_scale - onset_idx);
        d(isnan(d)) = Inf;
        [~, bestk] = min(d);
    end

    score_local_raw    = median(score_by_scale_raw, 2, 'omitnan');
    score_local_smooth = median(score_by_scale_smooth, 2, 'omitnan');
    contrast_median    = median(contrast_by_scale, 2, 'omitnan');
    valid_mask         = any(valid_by_scale, 2);

    dscore  = [NaN; diff(score_local_smooth)];
    d2score = [NaN; diff(dscore)];

    dSlope = abs(maxSlope_by_scale - onset_idx); dSlope(isnan(dSlope)) = Inf;
    [~, ks] = min(dSlope); max_slope_idx = maxSlope_by_scale(ks);

    dCurv = abs(maxCurv_by_scale - onset_idx); dCurv(isnan(dCurv)) = Inf;
    [~, kc] = min(dCurv); max_curv_idx = maxCurv_by_scale(kc);

    localDet = struct();
    localDet.scales                = scales;
    localDet.score_by_scale_raw    = score_by_scale_raw;
    localDet.score_by_scale_smooth = score_by_scale_smooth;
    localDet.contrast_by_scale     = contrast_by_scale;
    localDet.onset_by_scale        = onset_by_scale;
    localDet.peak_by_scale         = peak_by_scale;
    localDet.maxSlope_by_scale     = maxSlope_by_scale;
    localDet.maxCurv_by_scale      = maxCurv_by_scale;
    localDet.score_local_raw       = score_local_raw;
    localDet.score_local_smooth    = score_local_smooth;
    localDet.contrast_median       = contrast_median;
    localDet.onset_idx             = onset_idx;
    localDet.max_slope_idx         = max_slope_idx;
    localDet.max_curv_idx          = max_curv_idx;
    localDet.dscore                = dscore;
    localDet.d2score               = d2score;
    localDet.valid_mask            = valid_mask;
    localDet.cluster               = clusterInfo;
    localDet.Z_by_scale            = Z_by_scale;
    localDet.feature_names         = varNames;
end

function signs = i_feature_sign_vector(varNames, cfg)
    p = numel(varNames);
    signs = ones(1,p);
    for j = 1:p
        vn = varNames{j};
        if isfield(cfg.feature_signs, vn)
            s = cfg.feature_signs.(vn);
            if ~isscalar(s) || ~ismember(s, [-1 1])
                error('cfg.feature_signs.%s musi być równe -1 albo 1.', vn);
            end
            signs(j) = s;
        end
    end
end

function Xw = i_winsorize_matrix(X, q)
    Xw = X;
    [~,p] = size(X);
    for j = 1:p
        x = X(:,j);
        ok = isfinite(x);
        if nnz(ok) < 5, continue; end
        lo = quantile(x(ok), q);
        hi = quantile(x(ok), 1-q);
        x(x < lo) = lo;
        x(x > hi) = hi;
        Xw(:,j) = x;
    end
end

function Z = i_local_robust_z(X, local_window, clip_z, eps_mad)
    [n,p] = size(X);
    Z = nan(n,p);
    hw = floor(local_window / 2);

    for j = 1:p
        x = X(:,j);
        for t = 1:n
            a = max(1, t - hw);
            b = min(n, t + hw);
            xw = x(a:b);
            xw = xw(isfinite(xw));
            if isempty(xw)
                Z(t,j) = 0;
                continue;
            end
            medw = median(xw);
            madw = mad(xw, 1);
            sigw = 1.4826 * madw + eps_mad;
            z = (x(t) - medw) / sigw;
            z = max(-clip_z, min(clip_z, z));
            if ~isfinite(z), z = 0; end
            Z(t,j) = z;
        end
    end
end

function [contrast, valid_mask] = i_segment_contrast(score, h, eps_mad)
    n = numel(score);
    contrast = nan(n,1);
    valid_mask = false(n,1);
    for t = (h+1):(n-h)
        left  = score((t-h):(t-1));
        right = score(t:(t+h-1));
        both  = score((t-h):(t+h-1));
        left = left(isfinite(left));
        right = right(isfinite(right));
        both = both(isfinite(both));
        if numel(left) < 5 || numel(right) < 5 || numel(both) < 10
            continue;
        end
        num = abs(median(right) - median(left));
        den = 1.4826 * mad(both, 1) + eps_mad;
        contrast(t) = num / den;
        valid_mask(t) = true;
    end
end

function [onset_idx, clusterInfo] = i_cluster_onsets(onsets, peaks, scales, n, cfg)
    onset_idx = NaN;
    clusterInfo = struct('members',[],'center',NaN,'support',0,'scale_agreement',0,'weighted_median',NaN);

    ok = isfinite(onsets) & isfinite(peaks);
    if ~any(ok), return; end

    oo = onsets(ok);
    pp = peaks(ok);
    ss = scales(ok);
    tol = max(8, round(median(ss) * cfg.cluster_tol_ratio));
    m = numel(oo);

    bestSupport = -Inf;
    bestWeight = -Inf;
    bestCenter = NaN;
    bestMembers = false(m,1);

    for i = 1:m
        c = oo(i);
        members = abs(oo - c) <= tol;
        support = sum(members);
        weight = sum(pp(members));
        if support > bestSupport || (support == bestSupport && weight > bestWeight)
            bestSupport = support;
            bestWeight = weight;
            bestCenter = c;
            bestMembers = members;
        end
    end

    oo2 = oo(bestMembers);
    pp2 = pp(bestMembers);
    wm = i_weighted_median(oo2, pp2);
    if ~isfinite(wm), wm = round(median(oo2)); end

    onset_idx = max(1, min(n, round(wm)));

    clusterInfo.members = oo2(:);
    clusterInfo.center = bestCenter;
    clusterInfo.support = bestSupport;
    clusterInfo.scale_agreement = bestSupport / m;
    clusterInfo.weighted_median = onset_idx;
    clusterInfo.tol = tol;
    clusterInfo.all_onsets = oo(:);
    clusterInfo.all_peaks = pp(:);
end

function wm = i_weighted_median(x, w)
    wm = NaN;
    if isempty(x), return; end
    [xs, idx] = sort(x(:));
    ws = w(idx);
    ws(~isfinite(ws) | ws < 0) = 0;
    if sum(ws) <= 0
        wm = median(xs);
        return;
    end
    c = cumsum(ws) / sum(ws);
    k = find(c >= 0.5, 1, 'first');
    wm = xs(k);
end

% ============================================================
% DOWÓD / RYGOR
% ============================================================
function evidence = i_build_evidence_local(localDet, features, cfg)
    n = height(features);
    onset = localDet.onset_idx;
    peakContrast = NaN;
    if isfinite(onset) && onset >= 1 && onset <= n
        peakContrast = localDet.contrast_median(onset);
    end
    dSlope = abs(localDet.max_slope_idx - onset);
    dCurv  = abs(localDet.max_curv_idx - onset);

    evidence = struct();
    evidence.n_generations       = n;
    evidence.onset_idx           = onset;
    evidence.max_slope_idx       = localDet.max_slope_idx;
    evidence.max_curv_idx        = localDet.max_curv_idx;
    evidence.peak_contrast       = peakContrast;
    evidence.scale_agreement     = localDet.cluster.scale_agreement;
    evidence.cluster_support     = localDet.cluster.support;
    evidence.cluster_members     = localDet.cluster.members;
    evidence.cluster_all_onsets  = localDet.cluster.all_onsets;
    evidence.cluster_all_peaks   = localDet.cluster.all_peaks;
    evidence.abs_slope_onset     = dSlope;
    evidence.abs_curv_onset      = dCurv;
    evidence.phase_consistent    = double(dSlope <= 0.20*n && dCurv <= 0.20*n);
    evidence.local_scales        = localDet.scales;
    evidence.cfg_clip_z          = cfg.clip_z;
    evidence.cfg_winsor_q        = cfg.winsor_q;
end

function rigorous = i_run_rigorous_local_test(featuresTbl, localDet, cfg)
    X = table2array(featuresTbl);
    n = size(X,1);
    rng(cfg.rng_seed, 'twister');

    observed_onset = localDet.onset_idx;
    observed_peak = localDet.contrast_median(observed_onset);
    if ~isfinite(observed_peak)
        observed_peak = max(localDet.contrast_median, [], 'omitnan');
    end

    nB = cfg.n_bootstrap;
    boot_onsets = nan(nB,1);
    boot_peaks  = nan(nB,1);
    blockLen = max(cfg.null_block_min, min(cfg.null_block_max, round(median(localDet.scales))));

    for b = 1:nB
        Xb = i_block_bootstrap_rows(X, blockLen);
        Tb = array2table(Xb, 'VariableNames', featuresTbl.Properties.VariableNames);
        detb = i_detect_loci_local_multiscale(Tb, cfg);
        boot_onsets(b) = detb.onset_idx;
        if isfinite(detb.onset_idx)
            boot_peaks(b) = detb.contrast_median(detb.onset_idx);
        end
    end

    finiteBoot = boot_onsets(isfinite(boot_onsets));
    if isempty(finiteBoot)
        boot_ci = [NaN NaN NaN];
    else
        boot_ci = quantile(finiteBoot, [0.025 0.50 0.975]);
    end

    boot_tol = max(10, round(median(localDet.scales) * cfg.cluster_tol_ratio));
    boot_agree = mean(abs(boot_onsets - observed_onset) <= boot_tol, 'omitnan');

    nP = cfg.n_perm;
    perm_peaks = nan(nP,1);
    for r = 1:nP
        Xp = i_block_permute_rows(X, blockLen);
        Tp = array2table(Xp, 'VariableNames', featuresTbl.Properties.VariableNames);
        detp = i_detect_loci_local_multiscale(Tp, cfg);
        if isfinite(detp.onset_idx)
            perm_peaks(r) = detp.contrast_median(detp.onset_idx);
        end
    end
    perm_p = mean(perm_peaks >= observed_peak, 'omitnan');
    if ~isfinite(perm_p), perm_p = 1; end

    split_onsets = nan(2,1);
    split_peaks  = nan(2,1);
    idxA = 1:floor(n/2);
    idxB = (floor(n/2)+1):n;

    if numel(idxA) >= 25
        Ta = featuresTbl(idxA,:);
        deta = i_detect_loci_local_multiscale(Ta, cfg);
        split_onsets(1) = deta.onset_idx;
        if isfinite(deta.onset_idx)
            split_peaks(1) = deta.contrast_median(deta.onset_idx);
        end
    end
    if numel(idxB) >= 25
        Tb = featuresTbl(idxB,:);
        detb = i_detect_loci_local_multiscale(Tb, cfg);
        if isfinite(detb.onset_idx)
            split_onsets(2) = idxB(1) - 1 + detb.onset_idx;
            split_peaks(2) = detb.contrast_median(detb.onset_idx);
        end
    end
    split_agree = mean(abs(split_onsets - observed_onset) <= boot_tol, 'omitnan');

    rigorous = struct();
    rigorous.observed_onset   = observed_onset;
    rigorous.observed_peak    = observed_peak;
    rigorous.bootstrap_onsets = boot_onsets;
    rigorous.bootstrap_peaks  = boot_peaks;
    rigorous.bootstrap_ci95   = boot_ci;
    rigorous.bootstrap_agree  = boot_agree;
    rigorous.bootstrap_tol    = boot_tol;
    rigorous.perm_peaks       = perm_peaks;
    rigorous.perm_p_peak      = perm_p;
    rigorous.split_onsets     = split_onsets;
    rigorous.split_peaks      = split_peaks;
    rigorous.split_agree      = split_agree;
    rigorous.block_length     = blockLen;
end

function Xb = i_block_bootstrap_rows(X, blockLen)
    [n,p] = size(X);
    Xb = nan(n,p);
    pos = 1;
    while pos <= n
        s = randi(max(1, n - blockLen + 1));
        e = min(n, s + blockLen - 1);
        chunk = X(s:e,:);
        m = min(size(chunk,1), n - pos + 1);
        Xb(pos:(pos+m-1),:) = chunk(1:m,:);
        pos = pos + m;
    end
end

function Xp = i_block_permute_rows(X, blockLen)
    [n,p] = size(X);
    starts = 1:blockLen:n;
    blocks = cell(numel(starts),1);
    for i = 1:numel(starts)
        a = starts(i);
        b = min(n, a + blockLen - 1);
        blocks{i} = X(a:b,:);
    end
    ord = randperm(numel(blocks));
    Xp = nan(n,p);
    pos = 1;
    for k = 1:numel(ord)
        blk = blocks{ord(k)};
        m = min(size(blk,1), n - pos + 1);
        Xp(pos:(pos+m-1),:) = blk(1:m,:);
        pos = pos + m;
        if pos > n, break; end
    end
end

function verdict = i_make_local_verdict(localDet, rigorous, cfg)
    n = numel(localDet.score_local_smooth);
    ci = rigorous.bootstrap_ci95;
    ciWidth = ci(3) - ci(1);
    if ~isfinite(ciWidth), ciWidth = Inf; end

    c1 = localDet.contrast_median(localDet.onset_idx) >= cfg.verdict_min_peak_contrast;
    c2 = localDet.cluster.scale_agreement >= cfg.verdict_min_scale_agree;
    c3 = rigorous.bootstrap_agree >= cfg.verdict_min_boot_agree;
    c4 = ciWidth <= cfg.verdict_max_boot_ci_width_ratio * n;
    c5 = rigorous.perm_p_peak <= (1 - cfg.verdict_min_perm_sep);
    c6 = abs(localDet.max_slope_idx - localDet.onset_idx) <= max(15, round(0.15*n));
    c7 = abs(localDet.max_curv_idx  - localDet.onset_idx) <= max(20, round(0.20*n));

    score_criteria = sum([c1 c2 c3 c4 c5 c6 c7]);

    if score_criteria >= 6
        label = 'P1 — silne lokalne przejście LOCI';
    elseif score_criteria >= 4
        label = 'P2 — umiarkowany dowód lokalnego przejścia LOCI';
    else
        label = 'P3 — brak wystarczającego dowodu realności sygnału';
    end

    verdict = struct();
    verdict.label = label;
    verdict.score_criteria = score_criteria;
    verdict.c_peak_contrast = c1;
    verdict.c_scale_agree   = c2;
    verdict.c_boot_agree    = c3;
    verdict.c_boot_ci       = c4;
    verdict.c_perm_peak     = c5;
    verdict.c_slope_phase   = c6;
    verdict.c_curv_phase    = c7;
end

% ============================================================
% TABELA / WYDRUK / WYKRES
% ============================================================
function T = i_build_result_table_local(features, score_raw, score_smooth, dscore, d2score, localDet)
    n = height(features);
    T = table((1:n)', 'VariableNames', {'generation'});
    T.score_raw       = score_raw;
    T.score_smooth    = score_smooth;
    T.dscore          = dscore;
    T.d2score         = d2score;
    T.contrast_median = localDet.contrast_median;
    T.valid_mask      = localDet.valid_mask;
    T.is_onset        = false(n,1);
    if isfinite(localDet.onset_idx)
        T.is_onset(localDet.onset_idx) = true;
    end
    T = [T features];
end

function i_print_local_summary(R)
    fprintf('\n==================== PODSUMOWANIE ====================\n');
    fprintf('Liczba generacji: %d\n', R.n_generations);
    fprintf('ONSET LOCI         = G%04d\n', R.onset_idx);
    fprintf('MAX SLOPE          = G%04d\n', R.max_slope_idx);
    fprintf('MAX CURVATURE      = G%04d\n', R.max_curv_idx);
    fprintf('Werdykt            = %s\n', R.verdict.label);
    fprintf('=====================================================\n');
end

function i_print_local_report(R)
    peakContrast = R.local_detector.contrast_median(R.onset_idx);
    ci = R.rigorous.bootstrap_ci95;

    fprintf('\n==================== RAPORT DOWODOWY ====================\n');
    fprintf('Plik: %s\n', R.sample_file);
    fprintf('Liczba generacji: %d\n\n', R.n_generations);

    fprintf('[1] Lokalna detekcja segmentacyjna\n');
    fprintf('  onset_idx        = %d\n', R.onset_idx);
    fprintf('  max_slope_idx    = %d\n', R.max_slope_idx);
    fprintf('  max_curv_idx     = %d\n', R.max_curv_idx);
    fprintf('  peak contrast    = %.6f\n', peakContrast);
    fprintf('  scale agreement  = %.3f\n', R.local_detector.cluster.scale_agreement);
    fprintf('  cluster support  = %d\n\n', R.local_detector.cluster.support);

    fprintf('[2] Stabilność bootstrap / split-half\n');
    fprintf('  bootstrap CI95   = [%.2f, %.2f, %.2f]\n', ci(1), ci(2), ci(3));
    fprintf('  bootstrap agree  = %.3f\n', R.rigorous.bootstrap_agree);
    fprintf('  split agreement  = %.3f\n\n', R.rigorous.split_agree);

    fprintf('[3] Test modelu zerowego\n');
    fprintf('  perm p_peak      = %.6f\n\n', R.rigorous.perm_p_peak);

    fprintf('[4] Werdykt końcowy\n');
    fprintf('  %s\n', R.verdict.label);
    fprintf('  score_criteria   = %d / 7\n', R.verdict.score_criteria);
    fprintf('=========================================================\n');
end

function i_plot_local_detector(R, ~)
    n = R.n_generations;
    x = 1:n;

    figure('Color', 'w', 'Name', 'LOCI local-window detector');
    tiledlayout(4,1, 'Padding', 'compact', 'TileSpacing', 'compact');

    nexttile;
    plot(x, cumsum(abs(R.score_raw)), 'LineWidth', 1.2);
    hold on;
    xline(R.onset_idx, '--', sprintf('onset %d', R.onset_idx));
    grid on;
    title('Dynamika skumulowana');
    xlabel('Generacja');
    ylabel('cum');

    nexttile;
    plot(x, R.score_raw, 'LineWidth', 0.7);
    hold on;
    plot(x, R.score_smooth, 'LineWidth', 1.4);
    xline(R.onset_idx, '--', sprintf('onset %d', R.onset_idx));
    grid on;
    title(sprintf('Wskaźnik LOCI | %s', R.verdict.label));
    xlabel('Generacja');
    ylabel('score');
    legend({'raw','smooth'}, 'Location', 'best');

    nexttile;
    plot(x, R.local_detector.contrast_median, 'LineWidth', 1.2);
    hold on;
    xline(R.onset_idx, '--', sprintf('onset %d', R.onset_idx));
    grid on;
    title('Kontrast segmentacyjny');
    xlabel('Generacja');
    ylabel('contrast');

    nexttile;
    plot(x, R.dscore, 'LineWidth', 0.9);
    hold on;
    plot(x, R.d2score, 'LineWidth', 0.9);
    xline(R.onset_idx, '--', sprintf('onset %d', R.onset_idx));
    grid on;
    title('Pochodne score');
    xlabel('Generacja');
    ylabel('pochodne');
    legend({'dscore','d2score'}, 'Location', 'best');
end
