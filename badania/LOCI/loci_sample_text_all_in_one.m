function R = loci_sample_text_all_in_one(sampleFile)
% LOCI SAMPLE TEXT ALL IN ONE
% Wersja rygorystyczna: detekcja LOCI + dowód realności sygnału
%
% Użycie:
%   R = loci_sample_text_all_in_one('Sample_0001.m');

    clc;
    fprintf('============================================================\n');
    fprintf('LOCI SAMPLE TEXT ALL IN ONE\n');
    fprintf('Plik wejściowy: %s\n', sampleFile);
    fprintf('============================================================\n\n');

    rng(42, 'twister');

    cfg = i_default_cfg();

    [generations, sourceInfo] = i_load_generations(sampleFile);
    nG = numel(generations);

    fprintf('Wykryto generacji: %d\n\n', nG);

    features = i_build_features(generations, cfg);
    resultTable = i_build_score_table(features, cfg);

    onsetIdx    = resultTable.onset_idx;
    maxSlopeIdx = resultTable.max_slope_idx;
    maxCurvIdx  = resultTable.max_curv_idx;

    evidence = i_basic_evidence(resultTable, cfg);

    % ================= RYGOR DOWODOWY =================
    rigorous = i_run_rigorous_evidence(features, resultTable, cfg);
    verdict  = i_final_verdict(evidence, rigorous, cfg);

    i_print_summary(nG, onsetIdx, maxSlopeIdx, maxCurvIdx, verdict);
    i_print_rigorous_report(sampleFile, nG, resultTable, evidence, rigorous, verdict);

    i_plot_all(resultTable, cfg, verdict);

    R = struct();
    R.sample_file    = sampleFile;
    R.source_info    = sourceInfo;
    R.generations    = generations;
    R.features       = features;
    R.result_table   = resultTable;
    R.n_generations  = nG;
    R.onset_idx      = onsetIdx;
    R.max_slope_idx  = maxSlopeIdx;
    R.max_curv_idx   = maxCurvIdx;
    R.score_raw      = resultTable.score_raw;
    R.score_smooth   = resultTable.score_smooth;
    R.dscore         = resultTable.dscore;
    R.d2score        = resultTable.d2score;
    R.interior_mask  = resultTable.interior_mask;
    R.onset_mask     = resultTable.onset_mask;
    R.evidence       = evidence;
    R.rigorous       = rigorous;
    R.verdict        = verdict;
end

% ============================================================
% KONFIGURACJA
% ============================================================

function cfg = i_default_cfg()
    cfg = struct();

    cfg.smooth_window = 9;
    cfg.min_onset_idx = 8;
    cfg.max_onset_frac = 0.90;

    % Wagi score
    cfg.w_len_jump       = 0.22;
    cfg.w_novelty_prev   = 0.20;
    cfg.w_drift_prev     = 0.18;
    cfg.w_new_vocab      = 0.16;
    cfg.w_entropy_delta  = 0.10;
    cfg.w_repetition_inv = 0.14;

    % Bootstrap / rygor
    cfg.bootstrap_B          = 400;
    cfg.jackknife_stride     = 5;
    cfg.null_B               = 300;
    cfg.split_B              = 120;
    cfg.block_min            = 6;
    cfg.block_max            = 20;
    cfg.stability_tol        = 12;   % tolerancja indeksu onset
    cfg.min_effect_z         = 2.0;  % minimum dla mocnego sygnału
    cfg.max_emp_p            = 0.05; % próg istotności empirycznej
    cfg.min_split_agreement  = 0.60;
    cfg.min_jackknife_agree  = 0.60;
    cfg.min_bootstrap_agree  = 0.60;

    % Dla split-half / null
    cfg.fast_mode_surrogates = false;
end

% ============================================================
% WCZYTANIE GENERACJI
% ============================================================

function [generations, sourceInfo] = i_load_generations(sampleFile)
    txt = fileread(sampleFile);
    lines = splitlines(string(txt));
    lines = strip(lines);
    lines(lines=="") = [];

    generations = struct('idx', {}, 'text', {});
    k = 0;
    for i = 1:numel(lines)
        t = lines(i);
        if strlength(t) == 0
            continue;
        end
        k = k + 1;
        generations(k).idx = k;
        generations(k).text = char(t);
    end

    if isempty(generations)
        error('Nie wykryto żadnych generacji tekstu w pliku wejściowym.');
    end

    sourceInfo = struct();
    sourceInfo.mode = 'text_generations';
    sourceInfo.n_lines = numel(generations);
end

% ============================================================
% CECHY
% ============================================================

function T = i_build_features(generations, cfg)
    n = numel(generations);

    len_words       = zeros(n,1);
    len_chars       = zeros(n,1);
    novelty_prev    = zeros(n,1);
    drift_prev      = zeros(n,1);
    new_vocab_ratio = zeros(n,1);
    entropy         = zeros(n,1);
    repetition      = zeros(n,1);

    vocab_seen = containers.Map('KeyType','char','ValueType','double');

    prevTokens = {};
    prevText   = "";

    for i = 1:n
        txt = string(generations(i).text);
        tokens = i_tokenize_words(txt);

        len_words(i) = numel(tokens);
        len_chars(i) = strlength(txt);

        if isempty(tokens)
            entropy(i)    = 0;
            repetition(i) = 1;
        else
            entropy(i)    = i_entropy_tokens(tokens);
            repetition(i) = i_repetition_ratio(tokens);
        end

        if i > 1
            novelty_prev(i) = i_novelty_ratio(prevTokens, tokens);
            drift_prev(i)   = i_normalized_edit_distance_words(prevTokens, tokens);
        else
            novelty_prev(i) = 0;
            drift_prev(i)   = 0;
        end

        if isempty(tokens)
            new_vocab_ratio(i) = 0;
        else
            isNew = false(numel(tokens),1);
            for j = 1:numel(tokens)
                key = tokens{j};
                if ~isKey(vocab_seen, key)
                    vocab_seen(key) = 1;
                    isNew(j) = true;
                else
                    vocab_seen(key) = vocab_seen(key) + 1;
                end
            end
            new_vocab_ratio(i) = mean(isNew);
        end

        prevTokens = tokens;
        prevText   = txt; %#ok<NASGU>
    end

    d_len_words = [0; diff(len_words)];
    d_entropy   = [0; diff(entropy)];

    T = table( ...
        (1:n)', len_words, len_chars, novelty_prev, drift_prev, ...
        new_vocab_ratio, entropy, repetition, d_len_words, d_entropy, ...
        'VariableNames', { ...
        'gen_idx','len_words','len_chars','novelty_prev','drift_prev', ...
        'new_vocab_ratio','entropy','repetition','d_len_words','d_entropy' ...
        });
end

function tokens = i_tokenize_words(txt)
    txt = lower(string(txt));
    txt = regexprep(txt, '[^\p{L}\p{N}\s]+', ' ');
    txt = regexprep(txt, '\s+', ' ');
    txt = strip(txt);

    if strlength(txt) == 0
        tokens = {};
        return;
    end

    parts = split(txt, " ");
    parts(parts=="") = [];
    tokens = cellstr(parts);
end

function h = i_entropy_tokens(tokens)
    if isempty(tokens)
        h = 0;
        return;
    end
    [~,~,ic] = unique(tokens);
    cnt = accumarray(ic,1);
    p = cnt / sum(cnt);
    h = -sum(p .* log2(p + eps));
end

function r = i_repetition_ratio(tokens)
    if isempty(tokens)
        r = 1;
        return;
    end
    u = numel(unique(tokens));
    r = 1 - u / max(numel(tokens),1);
end

function v = i_novelty_ratio(prevTokens, tokens)
    if isempty(tokens)
        v = 0;
        return;
    end
    if isempty(prevTokens)
        v = 1;
        return;
    end
    prevSet = unique(prevTokens);
    curSet  = unique(tokens);
    v = sum(~ismember(curSet, prevSet)) / max(numel(curSet),1);
end

% =================== NAPRAWIONA FUNKCJA =======================
function d = i_normalized_edit_distance_words(a, b)
    % Bezpieczna wersja; naprawia błąd:
    % max(strlength(sa), strlength(sb), 1)

    if isempty(a) && isempty(b)
        d = 0;
        return;
    end

    sa = string(strjoin(a, " "));
    sb = string(strjoin(b, " "));

    ca = char(sa);
    cb = char(sb);

    dRaw = i_levenshtein_chars(ca, cb);
    denom = max([strlength(sa), strlength(sb), 1]);
    d = double(dRaw) / double(denom);
end

function d = i_levenshtein_chars(s, t)
    m = length(s);
    n = length(t);

    D = zeros(m+1, n+1);
    D(:,1) = 0:m;
    D(1,:) = 0:n;

    for i = 2:m+1
        for j = 2:n+1
            cost = ~(s(i-1) == t(j-1));
            D(i,j) = min([ ...
                D(i-1,j) + 1, ...
                D(i,j-1) + 1, ...
                D(i-1,j-1) + cost ...
            ]);
        end
    end
    d = D(end,end);
end

% ============================================================
% SCORE I POCHODNE
% ============================================================

function R = i_build_score_table(F, cfg)
    n = height(F);

    z_len_jump       = i_robust_z(abs(F.d_len_words));
    z_novelty_prev   = i_robust_z(F.novelty_prev);
    z_drift_prev     = i_robust_z(F.drift_prev);
    z_new_vocab      = i_robust_z(F.new_vocab_ratio);
    z_entropy_delta  = i_robust_z(abs(F.d_entropy));
    z_repetition_inv = i_robust_z(1 - F.repetition);

    score_raw = ...
          cfg.w_len_jump       * z_len_jump ...
        + cfg.w_novelty_prev   * z_novelty_prev ...
        + cfg.w_drift_prev     * z_drift_prev ...
        + cfg.w_new_vocab      * z_new_vocab ...
        + cfg.w_entropy_delta  * z_entropy_delta ...
        + cfg.w_repetition_inv * z_repetition_inv;

    score_smooth = i_movmean_reflect(score_raw, cfg.smooth_window);
    dscore  = [0; diff(score_smooth)];
    d2score = [0; diff(dscore)];

    interior_mask = false(n,1);
    lo = max(2, cfg.min_onset_idx);
    hi = max(lo, floor(cfg.max_onset_frac*n));
    interior_mask(lo:hi) = true;

    onset_mask = interior_mask & dscore > 0 & d2score > 0;

    if any(onset_mask)
        [~, idxLocal] = max(score_smooth .* onset_mask);
        onset_idx = idxLocal;
    else
        onset_idx = max(lo, 1);
    end

    [~, max_slope_idx] = max(dscore .* interior_mask);
    [~, max_curv_idx]  = max(d2score .* interior_mask);

    R = table((1:n)', score_raw, score_smooth, dscore, d2score, interior_mask, onset_mask, ...
        'VariableNames', {'gen_idx','score_raw','score_smooth','dscore','d2score','interior_mask','onset_mask'});

    R.onset_idx(:)     = onset_idx;
    R.max_slope_idx(:) = max_slope_idx;
    R.max_curv_idx(:)  = max_curv_idx;
end

function z = i_robust_z(x)
    x = double(x(:));
    med = median(x, 'omitnan');
    madv = median(abs(x - med), 'omitnan');
    s = 1.4826 * madv + eps;
    z = (x - med) / s;
end

function y = i_movmean_reflect(x, w)
    x = x(:);
    n = numel(x);
    h = floor(w/2);
    y = zeros(n,1);

    for i = 1:n
        lo = max(1, i-h);
        hi = min(n, i+h);
        y(i) = mean(x(lo:hi), 'omitnan');
    end
end

% ============================================================
% PODSTAWOWE EVIDENCE
% ============================================================

function E = i_basic_evidence(RT, cfg)
    onsetIdx = RT.onset_idx(1);
    slopeIdx = RT.max_slope_idx(1);
    curvIdx  = RT.max_curv_idx(1);

    E = struct();
    E.amplitude_score = max(RT.score_smooth) - min(RT.score_smooth);
    E.slope_onset_gap = abs(slopeIdx - onsetIdx);
    E.curv_onset_gap  = abs(curvIdx  - onsetIdx);
    E.phase_consistent = double((E.slope_onset_gap <= 8) && (E.curv_onset_gap <= 8));
end

% ============================================================
% RYGOR DOWODOWY
% ============================================================

function G = i_run_rigorous_evidence(F, RT, cfg)
    n = height(F);

    fprintf('==================== RYGOR DOWODOWY ====================\n');
    fprintf('Start testów rygorystycznych...\n');

    realOnset = RT.onset_idx(1);
    realAmp   = max(RT.score_smooth) - min(RT.score_smooth);
    realSlope = max(RT.dscore(RT.interior_mask));
    realCurv  = max(RT.d2score(RT.interior_mask));

    % 1) Bootstrap onset stability
    fprintf(' [1/5] Bootstrap stabilności...\n');
    bootOnsets = nan(cfg.bootstrap_B,1);
    for b = 1:cfg.bootstrap_B
        idx = randi(n, n, 1);
        idx = sort(idx); % zachowujemy porządek czasowy przez resampling indeksów
        Fb = F(idx, :);
        RTb = i_build_score_table(Fb, cfg);
        bootOnsets(b) = RTb.onset_idx(1);
    end
    bootCI = prctile(bootOnsets, [2.5 50 97.5]);
    bootAgree = mean(abs(bootOnsets - median(bootOnsets,'omitnan')) <= cfg.stability_tol, 'omitnan');

    % 2) Jackknife stride stability
    fprintf(' [2/5] Jackknife stabilności...\n');
    jkOnsets = [];
    for s = 1:cfg.jackknife_stride
        keep = true(n,1);
        keep(s:cfg.jackknife_stride:end) = false;
        if sum(keep) < max(20, round(0.5*n))
            continue;
        end
        RTj = i_build_score_table(F(keep,:), cfg);
        jkOnsets(end+1,1) = RTj.onset_idx(1); %#ok<AGROW>
    end
    if isempty(jkOnsets)
        jkOnsets = realOnset;
    end
    jkAgree = mean(abs(jkOnsets - median(jkOnsets,'omitnan')) <= cfg.stability_tol, 'omitnan');
    jkCI = prctile(jkOnsets, [2.5 50 97.5]);

    % 3) Split-half temporal stability
    fprintf(' [3/5] Split-half zgodności...\n');
    splitAgreeVec = false(cfg.split_B,1);
    splitDeltaVec = nan(cfg.split_B,1);

    for b = 1:cfg.split_B
        cut = randi([round(0.30*n), round(0.70*n)]);
        left  = F(1:cut,:);
        right = F(cut:end,:);

        if height(left) < 15 || height(right) < 15
            continue;
        end

        RTl = i_build_score_table(left, cfg);
        RTr = i_build_score_table(right, cfg);

        % onset prawy przenosimy do skali globalnej
        onsetL = RTl.onset_idx(1);
        onsetR = cut - 1 + RTr.onset_idx(1);

        splitDeltaVec(b) = abs(onsetL - onsetR);
        splitAgreeVec(b) = splitDeltaVec(b) <= max(cfg.stability_tol, round(0.08*n));
    end
    splitAgreement = mean(splitAgreeVec, 'omitnan');

    % 4) Null models / surrogate testing
    fprintf(' [4/5] Surrogaty zerowe...\n');
    nullAmp_perm   = nan(cfg.null_B,1);
    nullSlope_perm = nan(cfg.null_B,1);
    nullCurv_perm  = nan(cfg.null_B,1);
    nullOnset_perm = nan(cfg.null_B,1);

    nullAmp_block   = nan(cfg.null_B,1);
    nullSlope_block = nan(cfg.null_B,1);
    nullCurv_block  = nan(cfg.null_B,1);
    nullOnset_block = nan(cfg.null_B,1);

    for b = 1:cfg.null_B
        % permutacja pełna: niszczy temporalność
        idxPerm = randperm(n);
        RTp = i_build_score_table(F(idxPerm,:), cfg);
        nullAmp_perm(b)   = max(RTp.score_smooth) - min(RTp.score_smooth);
        nullSlope_perm(b) = max(RTp.dscore(RTp.interior_mask));
        nullCurv_perm(b)  = max(RTp.d2score(RTp.interior_mask));
        nullOnset_perm(b) = RTp.onset_idx(1);

        % block shuffle: zachowuje lokalne pakiety, niszczy globalny porządek
        idxBlock = i_make_block_shuffle_indices(n, cfg.block_min, cfg.block_max);
        RTb = i_build_score_table(F(idxBlock,:), cfg);
        nullAmp_block(b)   = max(RTb.score_smooth) - min(RTb.score_smooth);
        nullSlope_block(b) = max(RTb.dscore(RTb.interior_mask));
        nullCurv_block(b)  = max(RTb.d2score(RTb.interior_mask));
        nullOnset_block(b) = RTb.onset_idx(1);
    end

    empP_amp_perm   = (1 + sum(nullAmp_perm   >= realAmp))   / (1 + cfg.null_B);
    empP_slope_perm = (1 + sum(nullSlope_perm >= realSlope)) / (1 + cfg.null_B);
    empP_curv_perm  = (1 + sum(nullCurv_perm  >= realCurv))  / (1 + cfg.null_B);

    empP_amp_block   = (1 + sum(nullAmp_block   >= realAmp))   / (1 + cfg.null_B);
    empP_slope_block = (1 + sum(nullSlope_block >= realSlope)) / (1 + cfg.null_B);
    empP_curv_block  = (1 + sum(nullCurv_block  >= realCurv))  / (1 + cfg.null_B);

    zAmp_perm   = (realAmp   - mean(nullAmp_perm,'omitnan'))   / (std(nullAmp_perm,'omitnan')   + eps);
    zSlope_perm = (realSlope - mean(nullSlope_perm,'omitnan')) / (std(nullSlope_perm,'omitnan') + eps);
    zCurv_perm  = (realCurv  - mean(nullCurv_perm,'omitnan'))  / (std(nullCurv_perm,'omitnan')  + eps);

    zAmp_block   = (realAmp   - mean(nullAmp_block,'omitnan'))   / (std(nullAmp_block,'omitnan')   + eps);
    zSlope_block = (realSlope - mean(nullSlope_block,'omitnan')) / (std(nullSlope_block,'omitnan') + eps);
    zCurv_block  = (realCurv  - mean(nullCurv_block,'omitnan'))  / (std(nullCurv_block,'omitnan')  + eps);

    % 5) Ablation: czy sygnał jest wielocechowy
    fprintf(' [5/5] Ablation cech...\n');
    ablation = i_run_ablation(F, cfg, realOnset);

    G = struct();
    G.real_onset = realOnset;
    G.real_amp   = realAmp;
    G.real_slope = realSlope;
    G.real_curv  = realCurv;

    G.bootstrap_onsets = bootOnsets;
    G.bootstrap_ci95   = bootCI;
    G.bootstrap_agree  = bootAgree;

    G.jackknife_onsets = jkOnsets;
    G.jackknife_ci95   = jkCI;
    G.jackknife_agree  = jkAgree;

    G.split_agreement  = splitAgreement;
    G.split_delta      = splitDeltaVec;

    G.null_perm = struct( ...
        'amp', nullAmp_perm, ...
        'slope', nullSlope_perm, ...
        'curv', nullCurv_perm, ...
        'onset', nullOnset_perm, ...
        'p_amp', empP_amp_perm, ...
        'p_slope', empP_slope_perm, ...
        'p_curv', empP_curv_perm, ...
        'z_amp', zAmp_perm, ...
        'z_slope', zSlope_perm, ...
        'z_curv', zCurv_perm);

    G.null_block = struct( ...
        'amp', nullAmp_block, ...
        'slope', nullSlope_block, ...
        'curv', nullCurv_block, ...
        'onset', nullOnset_block, ...
        'p_amp', empP_amp_block, ...
        'p_slope', empP_slope_block, ...
        'p_curv', empP_curv_block, ...
        'z_amp', zAmp_block, ...
        'z_slope', zSlope_block, ...
        'z_curv', zCurv_block);

    G.ablation = ablation;

    fprintf('Rygor zakończony.\n');
    fprintf('=========================================================\n\n');
end

function idx = i_make_block_shuffle_indices(n, bmin, bmax)
    blocks = {};
    s = 1;
    while s <= n
        bl = randi([bmin, bmax],1,1);
        e = min(n, s + bl - 1);
        blocks{end+1} = s:e; %#ok<AGROW>
        s = e + 1;
    end
    ord = randperm(numel(blocks));
    idx = [];
    for k = 1:numel(ord)
        idx = [idx, blocks{ord(k)}]; %#ok<AGROW>
    end
    idx = idx(:);
end

function A = i_run_ablation(F, cfg, realOnset)
    feats = {'d_len_words','novelty_prev','drift_prev','new_vocab_ratio','d_entropy','repetition'};
    nA = numel(feats);

    A = struct();
    A.names = feats(:);
    A.onset = nan(nA,1);
    A.delta = nan(nA,1);

    for k = 1:nA
        RTa = i_build_score_table_ablation(F, cfg, feats{k});
        A.onset(k) = RTa.onset_idx(1);
        A.delta(k) = abs(A.onset(k) - realOnset);
    end

    A.agreement = mean(A.delta <= max(cfg.stability_tol,8), 'omitnan');
end

function R = i_build_score_table_ablation(F, cfg, dropName)
    z_len_jump       = i_robust_z(abs(F.d_len_words));
    z_novelty_prev   = i_robust_z(F.novelty_prev);
    z_drift_prev     = i_robust_z(F.drift_prev);
    z_new_vocab      = i_robust_z(F.new_vocab_ratio);
    z_entropy_delta  = i_robust_z(abs(F.d_entropy));
    z_repetition_inv = i_robust_z(1 - F.repetition);

    W = struct( ...
        'd_len_words',     cfg.w_len_jump, ...
        'novelty_prev',    cfg.w_novelty_prev, ...
        'drift_prev',      cfg.w_drift_prev, ...
        'new_vocab_ratio', cfg.w_new_vocab, ...
        'd_entropy',       cfg.w_entropy_delta, ...
        'repetition',      cfg.w_repetition_inv);

    W.(dropName) = 0;

    score_raw = ...
          W.d_len_words     * z_len_jump ...
        + W.novelty_prev    * z_novelty_prev ...
        + W.drift_prev      * z_drift_prev ...
        + W.new_vocab_ratio * z_new_vocab ...
        + W.d_entropy       * z_entropy_delta ...
        + W.repetition      * z_repetition_inv;

    score_smooth = i_movmean_reflect(score_raw, cfg.smooth_window);
    dscore  = [0; diff(score_smooth)];
    d2score = [0; diff(dscore)];

    n = numel(score_raw);
    interior_mask = false(n,1);
    lo = max(2, cfg.min_onset_idx);
    hi = max(lo, floor(cfg.max_onset_frac*n));
    interior_mask(lo:hi) = true;

    onset_mask = interior_mask & dscore > 0 & d2score > 0;
    if any(onset_mask)
        [~, onset_idx] = max(score_smooth .* onset_mask);
    else
        onset_idx = lo;
    end
    [~, max_slope_idx] = max(dscore .* interior_mask);
    [~, max_curv_idx]  = max(d2score .* interior_mask);

    R = table((1:n)', score_raw, score_smooth, dscore, d2score, interior_mask, onset_mask, ...
        'VariableNames', {'gen_idx','score_raw','score_smooth','dscore','d2score','interior_mask','onset_mask'});
    R.onset_idx(:)     = onset_idx;
    R.max_slope_idx(:) = max_slope_idx;
    R.max_curv_idx(:)  = max_curv_idx;
end

% ============================================================
% WERDYKT KOŃCOWY
% ============================================================

function V = i_final_verdict(E, G, cfg)
    pass_boot  = G.bootstrap_agree >= cfg.min_bootstrap_agree;
    pass_jack  = G.jackknife_agree >= cfg.min_jackknife_agree;
    pass_split = G.split_agreement >= cfg.min_split_agreement;

    pass_perm  = ...
        (G.null_perm.p_amp   <= cfg.max_emp_p) && ...
        (G.null_perm.p_slope <= cfg.max_emp_p) && ...
        (G.null_perm.z_amp   >= cfg.min_effect_z);

    pass_block = ...
        (G.null_block.p_amp   <= cfg.max_emp_p) && ...
        (G.null_block.p_slope <= cfg.max_emp_p) && ...
        (G.null_block.z_amp   >= cfg.min_effect_z);

    pass_ablation = G.ablation.agreement >= 0.50;
    pass_phase = E.phase_consistent == 1;

    score = sum([pass_boot, pass_jack, pass_split, pass_perm, pass_block, pass_ablation, pass_phase]);

    V = struct();
    V.pass_boot  = pass_boot;
    V.pass_jack  = pass_jack;
    V.pass_split = pass_split;
    V.pass_perm  = pass_perm;
    V.pass_block = pass_block;
    V.pass_ablation = pass_ablation;
    V.pass_phase = pass_phase;
    V.score = score;

    if score >= 6
        V.label = 'P0/P1 — sygnał LOCI realny i rygorystycznie wsparty';
    elseif score >= 4
        V.label = 'P1 — silny sygnał LOCI, częściowo potwierdzony rygorystycznie';
    elseif score >= 3
        V.label = 'P2 — sygnał obecny, ale wymaga ostrożności interpretacyjnej';
    else
        V.label = 'P3 — brak wystarczającego dowodu realności sygnału';
    end
end

% ============================================================
% RAPORT
% ============================================================

function i_print_summary(nG, onsetIdx, maxSlopeIdx, maxCurvIdx, verdict)
    fprintf('==================== PODSUMOWANIE ====================\n');
    fprintf('Liczba generacji: %d\n', nG);
    fprintf('ONSET LOCI         = G%04d\n', onsetIdx);
    fprintf('MAX SLOPE          = G%04d\n', maxSlopeIdx);
    fprintf('MAX CURVATURE      = G%04d\n', maxCurvIdx);
    fprintf('Werdykt            = %s\n', verdict.label);
    fprintf('=====================================================\n\n');
end

function i_print_rigorous_report(sampleFile, nG, RT, E, G, V)
    fprintf('==================== RAPORT DOWODOWY ====================\n');
    fprintf('Plik: %s\n', sampleFile);
    fprintf('Liczba generacji: %d\n\n', nG);

    fprintf('[1] Punkty charakterystyczne LOCI\n');
    fprintf('  onset_idx      = %d\n', RT.onset_idx(1));
    fprintf('  max_slope_idx  = %d\n', RT.max_slope_idx(1));
    fprintf('  max_curv_idx   = %d\n\n', RT.max_curv_idx(1));

    fprintf('[2] Spójność fazowa\n');
    fprintf('  amplitude score = %.6f\n', E.amplitude_score);
    fprintf('  |slope-onset|   = %d\n', E.slope_onset_gap);
    fprintf('  |curv-onset|    = %d\n', E.curv_onset_gap);
    fprintf('  phase_consistent= %d\n\n', E.phase_consistent);

    fprintf('[3] Stabilność bootstrap / jackknife / split-half\n');
    fprintf('  bootstrap CI95  = [%.2f, %.2f, %.2f]\n', G.bootstrap_ci95(1), G.bootstrap_ci95(2), G.bootstrap_ci95(3));
    fprintf('  bootstrap agree = %.3f\n', G.bootstrap_agree);
    fprintf('  jackknife CI95  = [%.2f, %.2f, %.2f]\n', G.jackknife_ci95(1), G.jackknife_ci95(2), G.jackknife_ci95(3));
    fprintf('  jackknife agree = %.3f\n', G.jackknife_agree);
    fprintf('  split agreement = %.3f\n\n', G.split_agreement);

    fprintf('[4] Testy modeli zerowych\n');
    fprintf('  PERM p_amp      = %.6f | z_amp   = %.3f\n', G.null_perm.p_amp,   G.null_perm.z_amp);
    fprintf('  PERM p_slope    = %.6f | z_slope = %.3f\n', G.null_perm.p_slope, G.null_perm.z_slope);
    fprintf('  PERM p_curv     = %.6f | z_curv  = %.3f\n', G.null_perm.p_curv,  G.null_perm.z_curv);
    fprintf('  BLOCK p_amp     = %.6f | z_amp   = %.3f\n', G.null_block.p_amp,   G.null_block.z_amp);
    fprintf('  BLOCK p_slope   = %.6f | z_slope = %.3f\n', G.null_block.p_slope, G.null_block.z_slope);
    fprintf('  BLOCK p_curv    = %.6f | z_curv  = %.3f\n\n', G.null_block.p_curv, G.null_block.z_curv);

    fprintf('[5] Ablation wielocechowa\n');
    for k = 1:numel(G.ablation.names)
        fprintf('  drop %-14s onset=%6.1f | delta=%6.1f\n', ...
            G.ablation.names{k}, G.ablation.onset(k), G.ablation.delta(k));
    end
    fprintf('  ablation agreement = %.3f\n\n', G.ablation.agreement);

    fprintf('[6] Werdykt końcowy\n');
    fprintf('  %s\n', V.label);
    fprintf('  score_criteria = %d / 7\n', V.score);
    fprintf('=========================================================\n\n');
end

% ============================================================
% PLOT
% ============================================================

function i_plot_all(RT, cfg, verdict)
    x = RT.gen_idx;

    figure('Color',[0.12 0.12 0.12], 'Position', [50 50 1350 850]);

    tiledlayout(4,1,'TileSpacing','compact','Padding','compact');

    nexttile;
    plot(x, cumsum(max(RT.score_raw,0)+0.05), 'LineWidth', 1.4);
    grid on;
    title('Dynamika skumulowana');
    ylabel('cum');

    nexttile;
    plot(x, RT.score_raw, 'LineWidth', 1.0); hold on;
    plot(x, RT.score_smooth, 'LineWidth', 1.5);
    xline(RT.onset_idx(1),'--','onset');
    xline(RT.max_slope_idx(1),'--','slope');
    xline(RT.max_curv_idx(1),'--','curv');
    grid on;
    legend({'raw','smooth'}, 'Location','best');
    title(sprintf('Wskaźnik LOCI | %s', verdict.label));
    ylabel('score');

    nexttile;
    plot(x, RT.dscore, 'LineWidth', 1.0); hold on;
    xline(RT.onset_idx(1),'--','onset');
    grid on;
    title('Pierwsza pochodna');
    ylabel('dscore');

    nexttile;
    plot(x, RT.d2score, 'LineWidth', 1.0); hold on;
    xline(RT.onset_idx(1),'--','onset');
    grid on;
    title('Druga pochodna');
    ylabel('d2score');
    xlabel('Generacja');
end