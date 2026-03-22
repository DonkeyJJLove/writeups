function M = loci_mode_classifier_v2(sampleFile)
% LOCI_MODE_CLASSIFIER_V2
% Klasyfikator przejścia:
% deklaratywno-proceduralny -> przejściowy -> generatywny
%
% Użycie:
%   M = loci_mode_classifier_v2('sample/norm/Sample_0001n.m');
%   M = loci_mode_classifier_v2('Sample_0001n.m');
%
% Wymaga:
%   - loci_sample_text_all_in_one.m
%   - parsera parse_sample_0001n_fixed.m albo kompatybilnego parsera norm
%
% Reżim:
%   - najpierw bierze LOCI jako detektor lokalnego przejścia
%   - potem buduje geometryczno-dynamiczny klasyfikator trybu
%   - werdykt daje tylko wtedy, gdy sygnały są spójne

    clc;
    fprintf('============================================================\n');
    fprintf('LOCI MODE CLASSIFIER V2\n');
    fprintf('============================================================\n');

    thisFile = mfilename('fullpath');
    if isempty(thisFile)
        scriptDir = pwd;
    else
        scriptDir = fileparts(thisFile);
    end

    addpath(scriptDir);
    addpath(fullfile(scriptDir, 'sample'));
    addpath(fullfile(scriptDir, 'sample', 'norm'));
    addpath(fullfile(scriptDir, 'sample', 'raw'));

    sampleFile = i_resolve_file(sampleFile, scriptDir);

    % --- krok 1: LOCI ---
    R = loci_sample_text_all_in_one(sampleFile);

    % --- krok 2: dane wejściowe ---
    data = i_load_any_sample(sampleFile, scriptDir);

    % --- krok 3: cechy bazowe ---
    X = i_build_feature_matrix(data, R);

    % --- krok 4: trajektoria 27D -> 9R ---
    [Z, pcaInfo] = i_project_to_9R(X);

    % --- krok 5: cechy geometryczne / dynamiczne ---
    geom = i_geometry_stats(Z);
    textdyn = i_text_dynamics(data);
    lociStats = i_loci_alignment(R, geom);

    % --- krok 6: segmentacja pre/post ---
    split = i_split_stats(Z, geom, textdyn, R.onset_idx);

    % --- krok 7: scoring reżimu ---
    verdict = i_classify_mode(split, lociStats, R);

    % --- krok 8: wizualizacja ---
    i_plot_mode_classifier_v2(Z, geom, split, R, verdict);

    % --- wynik ---
    M = struct();
    M.sample_file   = sampleFile;
    M.loci_result   = R;
    M.feature_matrix = X;
    M.projection_9R = Z;
    M.pca_info      = pcaInfo;
    M.geometry      = geom;
    M.text_dynamics = textdyn;
    M.loci_stats    = lociStats;
    M.split_stats   = split;
    M.verdict       = verdict;

    % --- raport ---
    fprintf('\n==================== MODE SUMMARY V2 ====================\n');
    fprintf('Liczba generacji            : %d\n', size(Z,1));
    fprintf('LOCI onset                  : G%04d\n', R.onset_idx);
    fprintf('Pre-window                  : [%d, %d]\n', split.pre_range(1), split.pre_range(2));
    fprintf('Post-window                 : [%d, %d]\n', split.post_range(1), split.post_range(2));
    fprintf('--------------------------------------------------------\n');
    fprintf('PRE  mean step              : %.4f\n', split.pre.mean_step);
    fprintf('POST mean step              : %.4f\n', split.post.mean_step);
    fprintf('DELTA step                  : %.4f\n', split.delta.mean_step);
    fprintf('--------------------------------------------------------\n');
    fprintf('PRE  curvature              : %.4f\n', split.pre.mean_curvature);
    fprintf('POST curvature              : %.4f\n', split.post.mean_curvature);
    fprintf('DELTA curvature             : %.4f\n', split.delta.mean_curvature);
    fprintf('--------------------------------------------------------\n');
    fprintf('PRE  density                : %.4f\n', split.pre.mean_density);
    fprintf('POST density                : %.4f\n', split.post.mean_density);
    fprintf('DELTA density               : %.4f\n', split.delta.mean_density);
    fprintf('--------------------------------------------------------\n');
    fprintf('PRE  plateau ratio          : %.4f\n', split.pre.plateau_ratio);
    fprintf('POST plateau ratio          : %.4f\n', split.post.plateau_ratio);
    fprintf('DELTA plateau               : %.4f\n', split.delta.plateau_ratio);
    fprintf('--------------------------------------------------------\n');
    fprintf('PRE  lexical expansion      : %.4f\n', split.pre.mean_lex_growth);
    fprintf('POST lexical expansion      : %.4f\n', split.post.mean_lex_growth);
    fprintf('DELTA lexical expansion     : %.4f\n', split.delta.mean_lex_growth);
    fprintf('--------------------------------------------------------\n');
    fprintf('LOCI alignment              : %.4f\n', lociStats.alignment_score);
    fprintf('Mode score                  : %.4f\n', verdict.mode_score);
    fprintf('Confidence                  : %.4f\n', verdict.confidence);
    fprintf('========================================================\n');
    fprintf('Werdykt klasyfikatora V2    : %s\n', verdict.label_text);
    fprintf('========================================================\n');
end

% =========================================================
% RESOLVE
% =========================================================
function p = i_resolve_file(sampleFile, scriptDir)
    candidates = {
        sampleFile
        fullfile(scriptDir, sampleFile)
        fullfile(scriptDir, 'sample', 'norm', sampleFile)
        fullfile(scriptDir, 'sample', 'raw', sampleFile)
    };

    p = '';
    for k = 1:numel(candidates)
        if exist(candidates{k}, 'file')
            p = candidates{k};
            return;
        end
    end

    error('Nie znaleziono pliku sample: %s', sampleFile);
end

% =========================================================
% LOAD SAMPLE
% =========================================================
function data = i_load_any_sample(sampleFile, scriptDir)
    [folder, name, ext] = fileparts(sampleFile); %#ok<ASGLU>
    base = [name ext];

    % parser dla norm
    if contains(lower(base), 'sample_0001n')
        if exist('parse_sample_0001n_fixed', 'file')
            data = parse_sample_0001n_fixed(sampleFile);
            return;
        end
    end

    % fallback: prosty loader tekstu z pliku
    data = i_fallback_text_loader(sampleFile, scriptDir);

    if ~isfield(data, 'entries') || numel(data.entries) < 5
        error('Nie udało się sparsować pliku sample w trybie fallback.');
    end
end

function data = i_fallback_text_loader(sampleFile, ~)
    txt = fileread(sampleFile);

    % próba rozbicia na wpisy typu generation / entry / text block
    % celowo prosta, odporna heurystyka
    blocks = regexp(txt, '(?m)^\s*%+\s*G\d+.*$', 'split');
    if numel(blocks) < 3
        blocks = regexp(txt, '\n\s*\n\s*\n+', 'split');
    end

    entries = struct('text', {});
    idx = 0;
    for i = 1:numel(blocks)
        t = strtrim(blocks{i});
        if strlength(string(t)) < 20
            continue;
        end
        idx = idx + 1;
        entries(idx).text = string(t); %#ok<AGROW>
    end

    data = struct();
    data.entries = entries;
end

% =========================================================
% FEATURE MATRIX
% =========================================================
function X = i_build_feature_matrix(data, R)
    n = numel(data.entries);

    text = strings(n,1);
    charsN = zeros(n,1);
    tokensN = zeros(n,1);
    uniqN   = zeros(n,1);
    entropyV = zeros(n,1);
    repRatio = zeros(n,1);
    avgTokLen = zeros(n,1);
    punctRatio = zeros(n,1);
    upperRatio = zeros(n,1);
    digitRatio = zeros(n,1);
    jaccPrev = nan(n,1);
    newTokRatio = nan(n,1);
    driftPrev = nan(n,1);

    prevTokens = strings(0,1);
    prevTextVec = [];

    for i = 1:n
        t = string(data.entries(i).text);
        text(i) = t;

        charsN(i) = strlength(t);

        toks = i_tokenize(t);
        tokensN(i) = numel(toks);
        uniqN(i) = numel(unique(toks));

        if ~isempty(toks)
            tokLens = strlength(toks);
            avgTokLen(i) = mean(tokLens);
            repRatio(i) = 1 - numel(unique(toks)) / max(numel(toks),1);

            counts = groupcounts(categorical(toks));
            p = counts / sum(counts);
            entropyV(i) = -sum(p .* log2(p + eps));
        else
            avgTokLen(i) = 0;
            repRatio(i) = 0;
            entropyV(i) = 0;
        end

        punctRatio(i) = double(sum(ismember(char(t), '.,;:!?-"''()[]{}'))) / max(strlength(t),1);
        upperRatio(i) = double(sum(isstrprop(char(t), 'upper'))) / max(strlength(t),1);
        digitRatio(i) = double(sum(isstrprop(char(t), 'digit'))) / max(strlength(t),1);

        if i > 1
            jaccPrev(i) = i_jaccard_tokens(prevTokens, toks);
            newTokRatio(i) = i_new_token_ratio(prevTokens, toks);

            vec = [charsN(i), tokensN(i), uniqN(i), entropyV(i), repRatio(i), avgTokLen(i)];
            driftPrev(i) = norm(vec - prevTextVec);
        else
            jaccPrev(i) = 1;
            newTokRatio(i) = 1;
            driftPrev(i) = 0;
        end

        prevTokens = toks;
        prevTextVec = [charsN(i), tokensN(i), uniqN(i), entropyV(i), repRatio(i), avgTokLen(i)];
    end

    % cechy z LOCI
    score = i_fix_len(R.score_smooth, n);
    dscore = i_fix_len(R.dscore, n);
    d2score = i_fix_len(R.d2score, n);

    T = [
        i_z(charsN), ...
        i_z(tokensN), ...
        i_z(uniqN), ...
        i_z(entropyV), ...
        i_z(repRatio), ...
        i_z(avgTokLen), ...
        i_z(punctRatio), ...
        i_z(upperRatio), ...
        i_z(digitRatio), ...
        i_z(1 - jaccPrev), ...
        i_z(newTokRatio), ...
        i_z(driftPrev), ...
        i_z(score), ...
        i_z(dscore), ...
        i_z(d2score)
    ];

    X = T;
end

% =========================================================
% 27D -> 9R
% =========================================================
function [Z, info] = i_project_to_9R(X)
    if size(X,2) < 9
        error('Za mało cech do projekcji 9R.');
    end

    [coeff, score, latent, ~, explained, mu] = pca(X, 'Rows', 'complete');

    k = min(9, size(score,2));
    Z = score(:,1:k);

    if k < 9
        Z = [Z zeros(size(Z,1), 9-k)];
    end

    info = struct();
    info.coeff = coeff;
    info.latent = latent;
    info.explained = explained;
    info.mu = mu;
end

% =========================================================
% GEOMETRY
% =========================================================
function geom = i_geometry_stats(Z)
    n = size(Z,1);

    dZ = [zeros(1,size(Z,2)); diff(Z,1,1)];
    ddZ = [zeros(1,size(Z,2)); diff(dZ,1,1)];

    step = sqrt(sum(dZ.^2, 2));
    curvature = sqrt(sum(ddZ.^2, 2));

    density = zeros(n,1);
    nn = zeros(n,1);

    for i = 1:n
        D = sqrt(sum((Z - Z(i,:)).^2, 2));
        D(i) = inf;
        nn(i) = min(D);

        rad = median(D(isfinite(D)));
        if isempty(rad) || isnan(rad) || rad == 0
            rad = 1;
        end
        density(i) = sum(D < 0.5*rad) / max(n-1,1);
    end

    plateau_thr = prctile(step, 25);
    plateau_mask = step <= plateau_thr;
    [plateau_ratio, max_plateau] = i_plateau_stats(plateau_mask);

    geom = struct();
    geom.step = step;
    geom.curvature = curvature;
    geom.nn = nn;
    geom.density = density;
    geom.plateau_mask = plateau_mask;
    geom.plateau_ratio = plateau_ratio;
    geom.max_plateau = max_plateau;
    geom.traj_length = sum(step);
end

% =========================================================
% TEXT DYNAMICS
% =========================================================
function td = i_text_dynamics(data)
    n = numel(data.entries);

    charsN = zeros(n,1);
    tokensN = zeros(n,1);
    lexGrowth = zeros(n,1);
    vocabCum = strings(0,1);

    for i = 1:n
        t = string(data.entries(i).text);
        charsN(i) = strlength(t);
        toks = i_tokenize(t);
        tokensN(i) = numel(toks);

        oldN = numel(unique(vocabCum));
        vocabCum = [vocabCum; toks(:)]; %#ok<AGROW>
        newN = numel(unique(vocabCum));

        lexGrowth(i) = newN - oldN;
    end

    td = struct();
    td.chars = charsN;
    td.tokens = tokensN;
    td.lex_growth = lexGrowth;
    td.d_chars = [0; diff(charsN)];
    td.d_tokens = [0; diff(tokensN)];
end

% =========================================================
% ALIGNMENT WITH LOCI
% =========================================================
function ls = i_loci_alignment(R, geom)
    n = numel(geom.step);
    onset = min(max(round(R.onset_idx),1), n);

    % blisko onset powinny rosnąć: step/curvature/density break
    win = max(1, onset-3):min(n, onset+3);

    local_step = mean(geom.step(win));
    local_curv = mean(geom.curvature(win));
    local_nn   = mean(geom.nn(win));

    global_step = mean(geom.step);
    global_curv = mean(geom.curvature);
    global_nn   = mean(geom.nn);

    s1 = local_step / max(global_step, eps);
    s2 = local_curv / max(global_curv, eps);
    s3 = local_nn / max(global_nn, eps);

    align = mean([min(s1/1.2,1.5), min(s2/1.2,1.5), min(s3/1.1,1.5)]);
    align = min(max((align - 0.8)/0.7, 0), 1);

    ls = struct();
    ls.local_step = local_step;
    ls.local_curvature = local_curv;
    ls.local_nn = local_nn;
    ls.alignment_score = align;
end

% =========================================================
% PRE/POST SPLIT
% =========================================================
function split = i_split_stats(Z, geom, td, onset)
    n = size(Z,1);

    preA = max(1, onset-24);
    preB = max(1, onset-1);
    postA = min(n, onset+1);
    postB = min(n, onset+24);

    if preB <= preA
        preA = 1;
        preB = floor(n/2);
    end
    if postB <= postA
        postA = floor(n/2)+1;
        postB = n;
    end

    preIdx = preA:preB;
    postIdx = postA:postB;

    pre = i_segment_stats(preIdx, Z, geom, td);
    post = i_segment_stats(postIdx, Z, geom, td);

    delta = struct();
    delta.mean_step = post.mean_step - pre.mean_step;
    delta.mean_curvature = post.mean_curvature - pre.mean_curvature;
    delta.mean_density = post.mean_density - pre.mean_density;
    delta.plateau_ratio = post.plateau_ratio - pre.plateau_ratio;
    delta.mean_lex_growth = post.mean_lex_growth - pre.mean_lex_growth;
    delta.mean_nn = post.mean_nn - pre.mean_nn;
    delta.mean_dispersion = post.mean_dispersion - pre.mean_dispersion;

    split = struct();
    split.pre = pre;
    split.post = post;
    split.delta = delta;
    split.pre_range = [preA preB];
    split.post_range = [postA postB];
end

function s = i_segment_stats(idx, Z, geom, td)
    Zi = Z(idx,:);

    s.mean_step = mean(geom.step(idx));
    s.mean_curvature = mean(geom.curvature(idx));
    s.mean_density = mean(geom.density(idx));
    s.mean_nn = mean(geom.nn(idx));
    s.plateau_ratio = mean(geom.plateau_mask(idx));
    s.mean_lex_growth = mean(td.lex_growth(idx));

    ctr = mean(Zi,1);
    s.mean_dispersion = mean(sqrt(sum((Zi - ctr).^2, 2)));
end

% =========================================================
% CLASSIFIER
% =========================================================
function verdict = i_classify_mode(split, lociStats, R)
    % Intuicja:
    % generatywność = większa reorganizacja po onset:
    % + wzrost krzywizny / dyspersji / kroku lokalnie
    % + spadek plateau
    % + rozrzedzenie lub przeorganizowanie gęstości
    % + zgodność z LOCI

    f_step = tanh(split.delta.mean_step / 0.35);
    f_curv = tanh(split.delta.mean_curvature / 0.35);
    f_disp = tanh(split.delta.mean_dispersion / 0.25);
    f_plateau = tanh((-split.delta.plateau_ratio) / 0.20);
    f_lex = tanh(split.delta.mean_lex_growth / 1.0);
    f_nn = tanh(split.delta.mean_nn / 0.08);
    f_align = 2*lociStats.alignment_score - 1;

    % Wagi dobrane pod Twoje przypadki:
    mode_score = ...
        0.20*f_step + ...
        0.22*f_curv + ...
        0.20*f_disp + ...
        0.15*f_plateau + ...
        0.08*f_lex + ...
        0.05*f_nn + ...
        0.10*f_align;

    % confidence bardziej konserwatywne
    evidence_count = 0;
    evidence_count = evidence_count + (split.delta.mean_curvature > 0.03);
    evidence_count = evidence_count + (split.delta.mean_dispersion > 0.03);
    evidence_count = evidence_count + (split.delta.plateau_ratio < -0.05);
    evidence_count = evidence_count + (lociStats.alignment_score > 0.55);
    evidence_count = evidence_count + isfield(R,'verdict');

    confidence = min(max((abs(mode_score) + 0.15*evidence_count)/1.4, 0), 1);

    if mode_score >= 0.28 && confidence >= 0.58
        label = 2;
        label_text = 'generatywny';
    elseif mode_score <= -0.20 && confidence >= 0.55
        label = 0;
        label_text = 'deklaratywno-proceduralny';
    else
        label = 1;
        label_text = 'przejściowy / hybrydowy';
    end

    % epistemiczne doprecyzowanie
    if label == 2 && contains(lower(R.verdict.label), 'p2')
        note = 'LOCI dodatni, a geometria po onset wspiera przejście ku generatywności.';
    elseif label == 1
        note = 'Wykryto reorganizację, ale bez pełnego dowodu stabilnego nowego reżimu.';
    else
        note = 'Przeważa organizacja proceduralna mimo lokalnych zmian.';
    end

    verdict = struct();
    verdict.label = label;
    verdict.label_text = label_text;
    verdict.mode_score = mode_score;
    verdict.confidence = confidence;
    verdict.note = note;
    verdict.components = struct( ...
        'step', f_step, ...
        'curvature', f_curv, ...
        'dispersion', f_disp, ...
        'plateau', f_plateau, ...
        'lex', f_lex, ...
        'nn', f_nn, ...
        'alignment', f_align ...
    );
end

% =========================================================
% PLOTS
% =========================================================
function i_plot_mode_classifier_v2(Z, geom, split, R, verdict)
    n = size(Z,1);
    g = (1:n)';

    figure('Color','k','Name','LOCI Mode Classifier V2','Position',[50 50 1800 950]);

    subplot(2,2,1);
    hold on;
    grid on;
    plot3(Z(:,1), Z(:,2), Z(:,3), '-', 'Color', [0.8 0.8 0.8], 'LineWidth', 1.0);
    scatter3(Z(:,1), Z(:,2), Z(:,3), 18, linspace(0,1,n), 'filled');
    scatter3(Z(R.onset_idx,1), Z(R.onset_idx,2), Z(R.onset_idx,3), 70, 'r', 'filled');
    title(sprintf('Trajektoria artefaktu (9R) | tryb: %s', verdict.label_text), 'Color','w');
    xlabel('R1','Color','w'); ylabel('R2','Color','w'); zlabel('R3','Color','w');
    set(gca,'Color','k','XColor','w','YColor','w','ZColor','w');

    subplot(2,2,2);
    hold on;
    grid on;
    plot(g, geom.step, 'c', 'LineWidth', 1.2);
    plot(g, movmean(geom.step,5), 'y', 'LineWidth', 1.0);
    xline(R.onset_idx, '--r', 'onset');
    title('Dynamika kroku trajektorii', 'Color','w');
    xlabel('Generacja','Color','w'); ylabel('step','Color','w');
    set(gca,'Color','k','XColor','w','YColor','w');

    subplot(2,2,3);
    hold on;
    grid on;
    plot(g, geom.curvature, 'm', 'LineWidth', 1.2);
    plot(g, movmean(geom.density,5), 'g', 'LineWidth', 1.0);
    xline(R.onset_idx, '--r', 'onset');
    title('Krzywizna i gęstość lokalna', 'Color','w');
    xlabel('Generacja','Color','w'); ylabel('value','Color','w');
    legend({'curvature','density'}, 'TextColor','w', 'Color','k', 'Location','best');
    set(gca,'Color','k','XColor','w','YColor','w');

    subplot(2,2,4);
    cats = zeros(n,1) + 1; % 1=przejściowy
    cats(1:split.pre_range(2)) = 0;
    cats(split.post_range(1):end) = 2;

    stairs(g, cats, 'LineWidth', 1.2, 'Color', [1 1 0]); hold on; grid on;
    xline(R.onset_idx, '--r', 'onset');
    yline(verdict.label, ':c', verdict.label_text);

    title(sprintf('Mode score = %.3f | conf = %.3f', verdict.mode_score, verdict.confidence), 'Color','w');
    xlabel('Generacja','Color','w'); ylabel('label','Color','w');
    ylim([-0.2 2.2]);
    yticks([0 1 2]);
    yticklabels({'proceduralny','przejściowy','generatywny'});
    set(gca,'Color','k','XColor','w','YColor','w');
end

% =========================================================
% HELPERS
% =========================================================
function toks = i_tokenize(t)
    t = lower(string(t));
    toks = regexpi(t, '[\p{L}\p{N}_-]+', 'match');
    toks = string(toks(:));
    toks = toks(strlength(toks) > 0);
end

function j = i_jaccard_tokens(a, b)
    if isempty(a) && isempty(b)
        j = 1;
        return;
    end
    ua = unique(a);
    ub = unique(b);
    inter = intersect(ua, ub);
    uni = union(ua, ub);
    j = numel(inter) / max(numel(uni),1);
end

function r = i_new_token_ratio(prev, curr)
    if isempty(curr)
        r = 0;
        return;
    end
    uPrev = unique(prev);
    uCurr = unique(curr);
    newT = setdiff(uCurr, uPrev);
    r = numel(newT) / max(numel(uCurr),1);
end

function z = i_z(x)
    x = double(x(:));
    mu = mean(x, 'omitnan');
    sd = std(x, 'omitnan');
    if sd < eps
        z = zeros(size(x));
    else
        z = (x - mu) ./ sd;
    end
    z(~isfinite(z)) = 0;
end

function y = i_fix_len(x, n)
    x = double(x(:));
    if isempty(x)
        y = zeros(n,1);
        return;
    end
    if numel(x) == n
        y = x;
        return;
    end
    if numel(x) > n
        y = x(1:n);
    else
        y = [x; repmat(x(end), n-numel(x), 1)];
    end
end

function [ratio, maxLen] = i_plateau_stats(mask)
    mask = logical(mask(:));
    ratio = mean(mask);

    d = diff([false; mask; false]);
    s = find(d == 1);
    e = find(d == -1) - 1;

    if isempty(s)
        maxLen = 0;
    else
        maxLen = max(e - s + 1);
    end
end