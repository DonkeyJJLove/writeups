function R = loci_dual_mode_model_v2(sampleFile, varargin)
% LOCI_DUAL_MODE_MODEL_V2
% ------------------------------------------------------------
% Wersja rozwojowa modelu dual-mode:
%   - kompresja vs eksploracja
%   - rzutowanie do metaprzestrzeni 27D
%   - projekcja 9R
%   - Sobol / Hypercube jako rama referencyjna
%
% Uzycie:
%   R = loci_dual_mode_model_v2('sample/norm/Sample_0001n.m');
%
% Opcjonalne parametry:
%   'NRef'         : liczba punktow referencyjnych w 27D (domyslnie 1024)
%   'UseSobol'     : true/false (domyslnie true)
%   'DoPlots'      : true/false (domyslnie true)
%   'WindowHalf'   : pol-okno wokol onset do porownan PRE/POST (domyslnie 24)
%   'PlateauThr'   : prog detekcji plateau w przestrzeni krokow (domyslnie 0.15)
%
% Wymaga:
%   - loci_sample_text_all_in_one.m
%
% Rezim:
%   - analiza formalna / reprodukowalna
% ------------------------------------------------------------

    p = inputParser;
    addRequired(p, 'sampleFile', @(x) ischar(x) || isstring(x));
    addParameter(p, 'NRef', 1024, @(x) isnumeric(x) && isscalar(x) && x > 16);
    addParameter(p, 'UseSobol', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'DoPlots', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'WindowHalf', 24, @(x) isnumeric(x) && isscalar(x) && x >= 5);
    addParameter(p, 'PlateauThr', 0.15, @(x) isnumeric(x) && isscalar(x) && x > 0);
    parse(p, sampleFile, varargin{:});

    cfg = p.Results;
    sampleFile = char(sampleFile);

    fprintf('============================================================\n');
    fprintf('LOCI DUAL-MODE MODEL V2: KOMPRESJA vs EKSPLORACJA + 27D/9R\n');
    fprintf('============================================================\n');
    fprintf('Plik wejściowy : %s\n', sampleFile);
    fprintf('============================================================\n\n');

    % --------------------------------------------------------
    % [1] BAZA LOCI
    % --------------------------------------------------------
    base = loci_sample_text_all_in_one(sampleFile);

    n = base.n_generations;
    onset = i_pick_scalar_field(base, 'onset_idx', round(0.75*n), n);
    maxSlope = i_pick_scalar_field(base, 'max_slope_idx', onset, n);
    maxCurv  = i_pick_scalar_field(base, 'max_curv_idx', onset, n);

    T = i_extract_feature_matrix(base);
    featNames = T.Properties.VariableNames;
    X0 = table2array(T);
    X0 = double(X0);

    % czyszczenie
    X0(~isfinite(X0)) = NaN;
    X0 = i_fillmissing_local(X0);

    % --------------------------------------------------------
    % [2] BUDOWA 27D
    % --------------------------------------------------------
    [X27, dim27Names, aux] = i_build_27d_space(X0);

    % --------------------------------------------------------
    % [3] PROJEKCJA 9R
    % --------------------------------------------------------
    [X9R, dim9Names] = i_project_27d_to_9r(X27);

    % --------------------------------------------------------
    % [4] DUAL-MODE: KOMPRESJA / EKSPLORACJA
    % --------------------------------------------------------
    dual = i_compute_dual_mode(X27, X9R, cfg.PlateauThr);

    % --------------------------------------------------------
    % [5] METRYKI TRAJEKTORII 27D
    % --------------------------------------------------------
    meta27 = i_compute_metaspace_metrics(X27, onset, cfg.PlateauThr);

    % --------------------------------------------------------
    % [6] PRE / POST wokol onset
    % --------------------------------------------------------
    W = cfg.WindowHalf;
    preIdx  = max(1, onset-W) : max(1, onset-1);
    postIdx = min(n, onset+1) : min(n, onset+W);

    cmp = i_compare_pre_post(X27, X9R, dual, preIdx, postIdx);

    % --------------------------------------------------------
    % [7] SOBOL / HYPERCUBE REF
    % --------------------------------------------------------
    ref = i_reference_27d(size(X27,2), cfg.NRef, logical(cfg.UseSobol));
    refStats = i_compare_to_reference(X27, ref);

    % --------------------------------------------------------
    % [8] OCENA TRYBU
    % --------------------------------------------------------
    verdict = i_build_verdict(dual, cmp, meta27, onset);

    % --------------------------------------------------------
    % [9] RAPORT TEKSTOWY
    % --------------------------------------------------------
    fprintf('==================== MODE SUMMARY V2 ====================\n');
    fprintf('Liczba generacji            : %d\n', n);
    fprintf('LOCI onset                  : G%04d\n', onset);
    fprintf('Max slope                   : G%04d\n', maxSlope);
    fprintf('Max curvature               : G%04d\n', maxCurv);
    fprintf('Pre-window                  : [%d, %d]\n', preIdx(1), preIdx(end));
    fprintf('Post-window                 : [%d, %d]\n', postIdx(1), postIdx(end));
    fprintf('--------------------------------------------------------\n');
    fprintf('PRE  compression mean       : %.4f\n', cmp.pre_compression);
    fprintf('POST compression mean       : %.4f\n', cmp.post_compression);
    fprintf('DELTA compression           : %.4f\n', cmp.delta_compression);
    fprintf('--------------------------------------------------------\n');
    fprintf('PRE  exploration mean       : %.4f\n', cmp.pre_exploration);
    fprintf('POST exploration mean       : %.4f\n', cmp.post_exploration);
    fprintf('DELTA exploration           : %.4f\n', cmp.delta_exploration);
    fprintf('--------------------------------------------------------\n');
    fprintf('PRE  dual balance           : %.4f\n', cmp.pre_balance);
    fprintf('POST dual balance           : %.4f\n', cmp.post_balance);
    fprintf('DELTA balance               : %.4f\n', cmp.delta_balance);
    fprintf('--------------------------------------------------------\n');
    fprintf('Trajectory length 27D       : %.4f\n', meta27.trajectory_length);
    fprintf('Mean step 27D               : %.4f\n', meta27.mean_step);
    fprintf('Max step 27D                : %.4f\n', meta27.max_step);
    fprintf('Plateau ratio 27D           : %.4f\n', meta27.plateau_ratio);
    fprintf('Longest plateau 27D         : %d\n', meta27.longest_plateau);
    fprintf('--------------------------------------------------------\n');
    fprintf('9R pre entropy              : %.4f\n', cmp.pre_9r_entropy);
    fprintf('9R post entropy             : %.4f\n', cmp.post_9r_entropy);
    fprintf('DELTA 9R entropy            : %.4f\n', cmp.delta_9r_entropy);
    fprintf('--------------------------------------------------------\n');
    fprintf('Reference mode              : %s\n', refStats.mode_name);
    fprintf('Coverage vs ref             : %.4f\n', refStats.coverage_score);
    fprintf('Dispersion vs ref           : %.4f\n', refStats.dispersion_score);
    fprintf('Occupancy vs ref            : %.4f\n', refStats.occupancy_score);
    fprintf('--------------------------------------------------------\n');
    fprintf('Mode score                  : %.4f\n', verdict.mode_score);
    fprintf('Confidence                  : %.4f\n', verdict.confidence);
    fprintf('========================================================\n');
    fprintf('Werdykt klasyfikatora V2    : %s\n', verdict.label);
    fprintf('========================================================\n');

    % --------------------------------------------------------
    % [10] WYKRESY
    % --------------------------------------------------------
    if logical(cfg.DoPlots)
        i_make_plots(X27, X9R, dual, onset, maxSlope, maxCurv, dim9Names);
    end

    % --------------------------------------------------------
    % [11] OUTPUT
    % --------------------------------------------------------
    R = struct();
    R.sample_file = sampleFile;
    R.base = base;
    R.n_generations = n;
    R.onset_idx = onset;
    R.max_slope_idx = maxSlope;
    R.max_curv_idx = maxCurv;

    R.feature_names = featNames;
    R.features_table = T;

    R.space27 = X27;
    R.space27_names = dim27Names;
    R.space27_aux = aux;

    R.space9R = X9R;
    R.space9R_names = dim9Names;

    R.dual_mode = dual;
    R.meta27 = meta27;
    R.compare_pre_post = cmp;

    R.reference = ref;
    R.reference_stats = refStats;
    R.verdict = verdict;
end

% ============================================================
% HELPERS
% ============================================================

function v = i_pick_scalar_field(S, fieldName, fallback, n)

    v = [];

    if isfield(S, fieldName) && ~isempty(S.(fieldName))
        v = S.(fieldName);
    elseif isfield(S, 'rigorous') && isstruct(S.rigorous) && isfield(S.rigorous, fieldName)
        v = S.rigorous.(fieldName);
    end

    if isempty(v)
        v = fallback;
    end

    if ~isscalar(v)
        v = v(:);
        idx = find(isfinite(v) & v > 0, 1, 'first');
        if isempty(idx)
            v = fallback;
        else
            v = v(idx);
        end
    end

    if isempty(v) || ~isfinite(v) || v < 1
        v = fallback;
    end

    v = min(max(round(v), 1), n);
end

function T = i_extract_feature_matrix(base)
    if isfield(base, 'features') && istable(base.features)
        T = base.features;
        return;
    end
    if isfield(base, 'result_table') && istable(base.result_table)
        T = base.result_table;
        return;
    end
    error('Nie znaleziono tabeli cech ani result_table w strukturze wejściowej.');
end

function X = i_fillmissing_local(X)
    for j = 1:size(X,2)
        col = X(:,j);
        if all(isnan(col))
            col(:) = 0;
        else
            medv = median(col(~isnan(col)));
            col(isnan(col)) = medv;
        end
        X(:,j) = col;
    end
end

function [X27, names, aux] = i_build_27d_space(X0)
    % Wejście: bazowe cechy z LOCI
    % Wyjście: 27D = bazowe + pochodne + lokalna geometria

    [n, d] = size(X0);

    Z0 = i_robust_zscore(X0);
    D1 = [zeros(1,d); diff(Z0,1,1)];
    D2 = [zeros(2,d); diff(Z0,2,1)];
    S1 = i_movstd_rows(Z0, 5);
    M1 = i_movmean_rows(Z0, 5);

    step = [0; sqrt(sum(diff(Z0,1,1).^2,2))];
    curv = i_curvature_from_traj(Z0);
    dens = i_local_density(Z0, 5);
    pers = i_local_persistence(Z0);

    cols = {};

    % 1..10: bazowe
    for j = 1:min(d,10)
        cols{end+1} = Z0(:,j); %#ok<AGROW>
    end

    % 11..18: pierwsze 8 pochodnych
    for j = 1:min(d,8)
        cols{end+1} = D1(:,j); %#ok<AGROW>
    end

    % 19..22: drugie pochodne
    for j = 1:min(d,4)
        cols{end+1} = D2(:,j); %#ok<AGROW>
    end

    % 23..24: lokalne uśrednienie
    cols{end+1} = mean(M1(:,1:min(d,5)),2);
    cols{end+1} = mean(S1(:,1:min(d,5)),2);

    % 25..27: geometria trajektorii
    cols{end+1} = i_rescale01(step);
    cols{end+1} = i_rescale01(curv);
    cols{end+1} = i_rescale01(dens + pers);

    X27 = zeros(n, 27);
    for k = 1:27
        X27(:,k) = cols{k};
    end

    X27 = i_robust_zscore(X27);

    names = arrayfun(@(k) sprintf('D%02d', k), 1:27, 'UniformOutput', false);

    aux = struct();
    aux.step = step;
    aux.curvature = curv;
    aux.density = dens;
    aux.persistence = pers;
end

function [X9, names] = i_project_27d_to_9r(X27)
    % 9R = 9 osi zlozonych po 3 wymiary
    X9 = zeros(size(X27,1), 9);
    names = cell(1,9);

    for r = 1:9
        idx = (r-1)*3 + (1:3);
        X9(:,r) = mean(X27(:,idx), 2);
        names{r} = sprintf('R%d', r);
    end
end

function dual = i_compute_dual_mode(X27, X9R, plateauThr)

    step = [0; sqrt(sum(diff(X27,1,1).^2,2))];
    curv = i_curvature_from_traj(X27);
    dens = i_local_density(X27, 7);
    pers = i_local_persistence(X27);
    entropy9 = i_axis_entropy(X9R);

    stepN    = i_rescale01(step);
    curvN    = i_rescale01(curv);
    densN    = i_rescale01(dens);
    persN    = i_rescale01(pers);
    entrN    = i_rescale01(entropy9);

    plateauMask = stepN <= plateauThr;
    plateauRun = i_run_length_mask(plateauMask);
    plateauN = i_rescale01(plateauRun);

    compression = 0.35*(1-stepN) + ...
                  0.20*persN + ...
                  0.20*plateauN + ...
                  0.15*(1-curvN) + ...
                  0.10*densN;

    exploration = 0.35*stepN + ...
                  0.25*curvN + ...
                  0.15*(1-densN) + ...
                  0.15*entrN + ...
                  0.10*(1-persN);

    balance = exploration - compression;
    modeLabel = strings(numel(balance),1);
    modeLabel(balance >  0.10) = "eksploracja";
    modeLabel(balance < -0.10) = "kompresja";
    modeLabel(balance >= -0.10 & balance <= 0.10) = "hybrydowy";

    dual = struct();
    dual.step = step;
    dual.curvature = curv;
    dual.density = dens;
    dual.persistence = pers;
    dual.entropy9 = entropy9;
    dual.plateau_mask = plateauMask;
    dual.plateau_run = plateauRun;
    dual.compression = compression;
    dual.exploration = exploration;
    dual.balance = balance;
    dual.mode_label = modeLabel;
end

function M = i_compute_metaspace_metrics(X, onset, plateauThr)
    steps = [0; sqrt(sum(diff(X,1,1).^2,2))];
    nn = i_nearest_neighbor_distance(X);

    plateauMask = i_rescale01(steps) <= plateauThr;
    runLen = i_run_length_mask(plateauMask);

    M = struct();
    M.trajectory_length = sum(steps);
    M.mean_step = mean(steps);
    M.median_step = median(steps);
    M.max_step = max(steps);
    M.mean_nn = mean(nn);
    M.plateau_ratio = mean(plateauMask);
    M.longest_plateau = max(runLen);
    M.onset_local_step = steps(onset);
    M.onset_local_nn = nn(onset);
end

function cmp = i_compare_pre_post(X27, X9R, dual, preIdx, postIdx)

    cmp = struct();

    cmp.pre_compression  = mean(dual.compression(preIdx));
    cmp.post_compression = mean(dual.compression(postIdx));
    cmp.delta_compression = cmp.post_compression - cmp.pre_compression;

    cmp.pre_exploration  = mean(dual.exploration(preIdx));
    cmp.post_exploration = mean(dual.exploration(postIdx));
    cmp.delta_exploration = cmp.post_exploration - cmp.pre_exploration;

    cmp.pre_balance  = mean(dual.balance(preIdx));
    cmp.post_balance = mean(dual.balance(postIdx));
    cmp.delta_balance = cmp.post_balance - cmp.pre_balance;

    cmp.pre_9r_entropy  = mean(i_axis_entropy(X9R(preIdx,:)));
    cmp.post_9r_entropy = mean(i_axis_entropy(X9R(postIdx,:)));
    cmp.delta_9r_entropy = cmp.post_9r_entropy - cmp.pre_9r_entropy;

    preSteps  = [0; sqrt(sum(diff(X27(preIdx,:),1,1).^2,2))];
    postSteps = [0; sqrt(sum(diff(X27(postIdx,:),1,1).^2,2))];

    cmp.pre_step_mean  = mean(preSteps);
    cmp.post_step_mean = mean(postSteps);
    cmp.delta_step_mean = cmp.post_step_mean - cmp.pre_step_mean;
end

function ref = i_reference_27d(d, N, useSobol)

    if useSobol
        try
            p = sobolset(d, 'Skip', 1024, 'Leap', 37);
            p = scramble(p, 'MatousekAffineOwen');
            X = net(p, N);
            modeName = 'Sobol';
        catch
            try
                X = lhsdesign(N, d, 'criterion', 'maximin', 'iterations', 20);
                modeName = 'LatinHypercubeFallback';
            catch
                X = rand(N, d);
                modeName = 'RandomFallback';
            end
        end
    else
        try
            X = lhsdesign(N, d, 'criterion', 'maximin', 'iterations', 20);
            modeName = 'LatinHypercube';
        catch
            X = rand(N, d);
            modeName = 'RandomFallback';
        end
    end

    X = i_robust_zscore(X);

    ref = struct();
    ref.X = X;
    ref.mode_name = modeName;
end

function out = i_compare_to_reference(X, ref)
    % proste porównanie rozproszenia i zajętości
    Xn = i_rescale01(X);
    Rn = i_rescale01(ref.X);

    % coverage: porownanie wariancji rozkładu po wymiarach
    varX = var(Xn,0,1);
    varR = var(Rn,0,1);
    coverage_score = mean(min(varX ./ (varR + eps), 1.5)) / 1.5;

    % dispersion: jak szeroko trajektoria korzysta z 27D
    dispersion_score = mean(std(Xn,0,1));

    % occupancy: zajętość prostych binów
    nb = 4;
    occX = i_grid_occupancy(Xn, nb);
    occR = i_grid_occupancy(Rn, nb);
    occupancy_score = min(occX / max(occR, eps), 1);

    out = struct();
    out.mode_name = ref.mode_name;
    out.coverage_score = coverage_score;
    out.dispersion_score = dispersion_score;
    out.occupancy_score = occupancy_score;
end

function verdict = i_build_verdict(dual, cmp, meta27, onset)

    score = 0;
    crit = zeros(1,6);

    if cmp.delta_exploration > 0.05
        score = score + 1; crit(1)=1;
    end
    if cmp.delta_compression < -0.03
        score = score + 1; crit(2)=1;
    end
    if cmp.delta_balance > 0.08
        score = score + 1; crit(3)=1;
    end
    if cmp.delta_9r_entropy > 0.02
        score = score + 1; crit(4)=1;
    end
    if meta27.onset_local_step > median(dual.step)
        score = score + 1; crit(5)=1;
    end
    if mean(strcmp(cellstr(dual.mode_label(onset:min(end,onset+10))), 'eksploracja')) > 0.4
        score = score + 1; crit(6)=1;
    end

    modeScore = score / numel(crit);
    confidence = min(0.55 + 0.4*modeScore, 0.98);

    if modeScore >= 0.66
        label = 'generatywno-eksploracyjny';
    elseif modeScore >= 0.33
        label = 'hybrydowy / przejściowy';
    else
        label = 'deklaratywno-kompresyjny';
    end

    verdict = struct();
    verdict.criteria = crit;
    verdict.mode_score = modeScore;
    verdict.confidence = confidence;
    verdict.label = label;
end

function i_make_plots(X27, X9R, dual, onset, maxSlope, maxCurv, dim9Names)

    % 1. dual mode
    figure('Name','LOCI Dual Mode V2 - balance','Color','w');
    plot(dual.compression, 'LineWidth', 1.2); hold on;
    plot(dual.exploration, 'LineWidth', 1.2);
    plot(dual.balance, 'LineWidth', 1.5);
    xline(onset, '--');
    xline(maxSlope, ':');
    xline(maxCurv, ':');
    grid on;
    legend({'compression','exploration','balance','onset','max slope','max curvature'}, 'Location','best');
    title('Dual-mode dynamics');
    xlabel('Generacja');
    ylabel('Skala');

    % 2. 9R heatmap
    figure('Name','LOCI Dual Mode V2 - 9R map','Color','w');
    imagesc(X9R');
    colorbar;
    yticklabels(dim9Names);
    xlabel('Generacja');
    ylabel('9R');
    title('Projekcja 9R');
    hold on;
    xline(onset, 'w--', 'LineWidth', 1.5);

    % 3. PCA dla 27D
    try
        [coeff, score] = pca(X27);
        figure('Name','LOCI Dual Mode V2 - 27D PCA','Color','w');
        plot(score(:,1), score(:,2), '-o', 'MarkerSize', 3); hold on;
        scatter(score(onset,1), score(onset,2), 80, 'filled');
        grid on;
        xlabel('PC1');
        ylabel('PC2');
        title('Trajektoria w 27D (PCA)');
        legend({'trajectory','onset'}, 'Location','best');
    catch
    end
end

% ============================================================
% NARZEDZIA MATEMATYCZNE
% ============================================================

function Z = i_robust_zscore(X)
    medv = median(X,1);
    madv = median(abs(X-medv),1) + eps;
    Z = (X - medv) ./ (1.4826*madv + eps);
end

function Y = i_rescale01(X)
    xmin = min(X,[],1);
    xmax = max(X,[],1);
    Y = (X - xmin) ./ (xmax - xmin + eps);
end

function Y = i_movstd_rows(X, w)
    Y = zeros(size(X));
    for j = 1:size(X,2)
        Y(:,j) = movstd(X(:,j), w, 'omitnan');
    end
end

function Y = i_movmean_rows(X, w)
    Y = zeros(size(X));
    for j = 1:size(X,2)
        Y(:,j) = movmean(X(:,j), w, 'omitnan');
    end
end

function c = i_curvature_from_traj(X)
    v1 = [zeros(1,size(X,2)); diff(X,1,1)];
    v2 = [zeros(1,size(X,2)); diff(v1,1,1)];
    c = sqrt(sum(v2.^2,2));
end

function d = i_local_density(X, k)
    n = size(X,1);
    d = zeros(n,1);
    for i = 1:n
        lo = max(1, i-k);
        hi = min(n, i+k);
        Xi = X(lo:hi,:);
        mu = mean(Xi,1);
        d(i) = 1 ./ (mean(sqrt(sum((Xi-mu).^2,2))) + eps);
    end
end

function p = i_local_persistence(X)
    n = size(X,1);
    p = zeros(n,1);
    for i = 2:n
        a = X(i-1,:);
        b = X(i,:);
        p(i) = dot(a,b) / (norm(a)*norm(b) + eps);
    end
    p = (p + 1)/2; % do [0,1]
end

function e = i_axis_entropy(X)
    Xn = i_rescale01(X);
    e = zeros(size(Xn,1),1);

    for i = 1:size(Xn,1)
        row = Xn(i,:);
        row = row - min(row);
        row = row + eps;
        row = row / sum(row);
        e(i) = -sum(row .* log(row + eps)) / log(numel(row));
    end
end

function runLen = i_run_length_mask(mask)
    mask = logical(mask(:));
    runLen = zeros(size(mask));
    count = 0;
    for i = 1:numel(mask)
        if mask(i)
            count = count + 1;
        else
            count = 0;
        end
        runLen(i) = count;
    end
end

function nn = i_nearest_neighbor_distance(X)
    n = size(X,1);
    nn = zeros(n,1);
    for i = 1:n
        d = sqrt(sum((X - X(i,:)).^2,2));
        d(i) = inf;
        nn(i) = min(d);
    end
end

function occ = i_grid_occupancy(X, nb)
    % Przybliżona zajętość binów
    d = size(X,2);
    dUse = min(d, 6); % ograniczenie eksplozji stanów
    X = X(:,1:dUse);

    idx = zeros(size(X));
    for j = 1:dUse
        idx(:,j) = min(floor(X(:,j)*nb), nb-1);
    end

    mult = nb.^(0:dUse-1);
    lin = 1 + idx * mult';
    occ = numel(unique(lin)) / (nb^dUse);
end