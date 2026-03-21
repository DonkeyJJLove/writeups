function OUT = run_loci_sample_metaspace(samplePath, varargin)
%RUN_LOCI_SAMPLE_METASPACE
% Jednoplikowy launcher do analizy sample tekstowego metodą LOCI
% oraz osadzenia trajektorii generacji w metaprzestrzeni cech.
%
% Uzycie:
%   OUT = run_loci_sample_metaspace('sample/norm/Sample_0001n.m');
%   OUT = run_loci_sample_metaspace('Sample_0001n.m', 'Method', 'sobol');
%
% Wymagania:
%   - loci_sample_text_all_in_one.m musi byc na MATLAB path albo w biezacym katalogu.
%
% Parametry opcjonalne:
%   'Method'        : 'sobol' (domyslnie) lub 'lhs'
%   'MakePlots'     : true/false (domyslnie true)
%   'SyntheticN'    : liczba punktow syntetycznych; [] = liczba generacji
%   'UseScoreColor' : true/false (domyslnie true)
%
% Wynik OUT zawiera:
%   .loci               - pelny wynik z loci_sample_text_all_in_one
%   .X                  - surowa macierz cech [N x D]
%   .X_norm             - cechy znormalizowane do [0,1]
%   .meta               - struktura z punktami syntetycznymi i statystykami
%   .trajectory_stats   - statystyki trajektorii sample
%   .repro              - dane do reprodukcji
%
% Rezim: naukowy / reprodukowalny
% Autor: OpenAI / ChatGPT dla projektu LOCI

    p = inputParser;
    addRequired(p, 'samplePath', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Method', 'sobol', @(x) any(strcmpi(string(x), ["sobol","lhs"])));
    addParameter(p, 'MakePlots', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'SyntheticN', [], @(x) isempty(x) || (isscalar(x) && x > 0));
    addParameter(p, 'UseScoreColor', true, @(x) islogical(x) || isnumeric(x));
    parse(p, samplePath, varargin{:});

    opts = p.Results;
    opts.Method = lower(string(opts.Method));
    samplePath = char(samplePath);

    rng(42, 'twister');

    if exist('loci_sample_text_all_in_one', 'file') ~= 2
        error(['Nie znaleziono funkcji loci_sample_text_all_in_one.m na sciezce MATLAB. ' ...
               'Ustaw biezacy katalog na folder LOCI albo dodaj go przez addpath().']);
    end

    fprintf('============================================================\n');
    fprintf('RUN LOCI SAMPLE METASPACE\n');
    fprintf('Sample          : %s\n', samplePath);
    fprintf('Method          : %s\n', upper(char(opts.Method)));
    fprintf('MakePlots       : %d\n', logical(opts.MakePlots));
    fprintf('============================================================\n\n');

    % ------------------------------------------------------------
    % 1. LOCI
    % ------------------------------------------------------------
    R = loci_sample_text_all_in_one(samplePath);

    if ~isfield(R, 'features') || isempty(R.features)
        error('Wynik LOCI nie zawiera pola features albo jest ono puste.');
    end

    X = i_table_to_numeric(R.features);
    [N, D] = size(X);

    if N < 3 || D < 2
        error('Za malo danych do budowy metaprzestrzeni. Wymagane co najmniej N>=3 i D>=2.');
    end

    synN = opts.SyntheticN;
    if isempty(synN)
        synN = N;
    end

    % ------------------------------------------------------------
    % 2. CZYSZCZENIE / NORMALIZACJA
    % ------------------------------------------------------------
    X = i_fill_missing(X);
    mins = min(X, [], 1);
    maxs = max(X, [], 1);
    spans = maxs - mins;
    spans(spans == 0) = 1;
    X_norm = (X - mins) ./ spans;

    % ------------------------------------------------------------
    % 3. METAPRZESTRZEN SYNTETYCZNA
    % ------------------------------------------------------------
    switch opts.Method
        case "sobol"
            P = i_make_sobol_points(synN, D);
        case "lhs"
            P = lhsdesign(synN, D, 'criterion', 'maximin', 'iterations', 50);
        otherwise
            error('Nieobslugiwana metoda: %s', opts.Method);
    end

    % ------------------------------------------------------------
    % 4. STATYSTYKI TRAJEKTORII SAMPLE
    % ------------------------------------------------------------
    traj = i_compute_trajectory_stats(X_norm, R);

    % ------------------------------------------------------------
    % 5. DENSITY / NN / COVERAGE
    % ------------------------------------------------------------
    meta = i_compute_meta_stats(X_norm, P);
    meta.method = char(opts.Method);
    meta.synthetic_points = P;
    meta.synthetic_n = synN;
    meta.bounds_raw = [mins(:), maxs(:)];

    % ------------------------------------------------------------
    % 6. RAPORT TEKSTOWY
    % ------------------------------------------------------------
    i_print_summary(N, D, traj, meta, R);

    % ------------------------------------------------------------
    % 7. WYKRESY
    % ------------------------------------------------------------
    if logical(opts.MakePlots)
        i_make_plots(X_norm, P, R, traj, logical(opts.UseScoreColor));
    end

    % ------------------------------------------------------------
    % 8. OUTPUT
    % ------------------------------------------------------------
    OUT = struct();
    OUT.loci = R;
    OUT.X = X;
    OUT.X_norm = X_norm;
    OUT.meta = meta;
    OUT.trajectory_stats = traj;
    OUT.repro = struct(...
        'rng_seed', 42, ...
        'method', char(opts.Method), ...
        'sample_path', samplePath, ...
        'n_generations', N, ...
        'n_features', D, ...
        'synthetic_n', synN);
end

% ========================================================================
% HELPERS
% ========================================================================

function X = i_table_to_numeric(T)
    if istable(T)
        X = table2array(T);
    elseif isnumeric(T)
        X = T;
    else
        error('features musi byc tabela albo macierza numeryczna.');
    end

    if ~isnumeric(X)
        error('Po konwersji features nie jest numeryczne.');
    end
end

function X = i_fill_missing(X)
    if any(isnan(X), 'all')
        for j = 1:size(X,2)
            col = X(:,j);
            mask = isnan(col);
            if all(mask)
                col(:) = 0;
            else
                med = median(col(~mask));
                col(mask) = med;
            end
            X(:,j) = col;
        end
    end
end

function P = i_make_sobol_points(N, D)
    try
        s = sobolset(D, 'Skip', 1e3, 'Leap', 1e2);
        s = scramble(s, 'MatousekAffineOwen');
        P = net(s, N);
    catch
        warning('sobolset niedostepny lub scramble nieudany; fallback na rand().');
        P = rand(N, D);
    end
end

function traj = i_compute_trajectory_stats(X_norm, R)
    N = size(X_norm,1);

    step_vec = diff(X_norm, 1, 1);
    step_len = sqrt(sum(step_vec.^2, 2));

    if N > 2
        acc_vec = diff(X_norm, 2, 1);
        acc_len = sqrt(sum(acc_vec.^2, 2));
    else
        acc_len = [];
    end

    Dfull = pdist2(X_norm, X_norm);
    Dnn = Dfull;
    Dnn(Dnn == 0) = inf;
    nn = min(Dnn, [], 2);

    % Plateau z perspektywy geometrii trajektorii:
    plateau_thr = median(step_len) * 0.5;
    if plateau_thr == 0
        plateau_thr = 1e-9;
    end
    plateau_mask = [false; step_len <= plateau_thr];

    traj = struct();
    traj.n_generations = N;
    traj.path_length = sum(step_len);
    traj.mean_step = mean(step_len);
    traj.median_step = median(step_len);
    traj.max_step = max(step_len);
    traj.min_step = min(step_len);
    traj.mean_acceleration = i_safe_mean(acc_len);
    traj.max_acceleration = i_safe_max(acc_len);
    traj.mean_nn = mean(nn);
    traj.min_nn = min(nn);
    traj.max_nn = max(nn);
    traj.plateau_threshold = plateau_thr;
    traj.plateau_ratio_geom = mean(plateau_mask);
    traj.longest_plateau_geom = i_longest_run(plateau_mask);

    if isfield(R, 'onset_idx') && ~isempty(R.onset_idx)
        traj.loci_onset_idx = i_collapse_idx(R.onset_idx);
    else
        traj.loci_onset_idx = NaN;
    end
    if isfield(R, 'max_slope_idx') && ~isempty(R.max_slope_idx)
        traj.loci_max_slope_idx = i_collapse_idx(R.max_slope_idx);
    else
        traj.loci_max_slope_idx = NaN;
    end
    if isfield(R, 'max_curv_idx') && ~isempty(R.max_curv_idx)
        traj.loci_max_curv_idx = i_collapse_idx(R.max_curv_idx);
    else
        traj.loci_max_curv_idx = NaN;
    end

    if isfield(R, 'score_smooth') && ~isempty(R.score_smooth)
        s = R.score_smooth(:);
        traj.score_range = max(s) - min(s);
        traj.score_mean = mean(s);
        traj.score_std = std(s);
    else
        traj.score_range = NaN;
        traj.score_mean = NaN;
        traj.score_std = NaN;
    end
end

function meta = i_compute_meta_stats(X_norm, P)
    % Dystans sample -> syntetyczna metaprzestrzen
    Dsp = pdist2(X_norm, P);
    d_cover = min(Dsp, [], 2);

    % Dystans syntetyczna -> sample
    Dps = pdist2(P, X_norm);
    d_back = min(Dps, [], 2);

    % Prosty indeks gestosci na podstawie kNN w sample
    k = min(5, size(X_norm,1)-1);
    if k >= 1
        D = pdist2(X_norm, X_norm);
        D(D == 0) = inf;
        Ds = sort(D, 2, 'ascend');
        knn = mean(Ds(:,1:k), 2);
        density = 1 ./ (knn + eps);
    else
        knn = zeros(size(X_norm,1),1);
        density = zeros(size(X_norm,1),1);
    end

    meta = struct();
    meta.coverage_mean = mean(d_cover);
    meta.coverage_median = median(d_cover);
    meta.coverage_max = max(d_cover);
    meta.back_projection_mean = mean(d_back);
    meta.back_projection_median = median(d_back);
    meta.knn_mean = i_safe_mean(knn);
    meta.knn_median = i_safe_median(knn);
    meta.density_mean = i_safe_mean(density);
    meta.density_std = i_safe_std(density);
    meta.density_min = i_safe_min(density);
    meta.density_max = i_safe_max(density);
end

function i_print_summary(N, D, traj, meta, R)
    fprintf('==================== METASPACE SUMMARY ====================\n');
    fprintf('Liczba generacji            : %d\n', N);
    fprintf('Liczba cech                 : %d\n', D);
    fprintf('Dlugosc trajektorii         : %.6f\n', traj.path_length);
    fprintf('Sredni krok                 : %.6f\n', traj.mean_step);
    fprintf('Mediana kroku               : %.6f\n', traj.median_step);
    fprintf('Max krok                    : %.6f\n', traj.max_step);
    fprintf('Sredni NN                   : %.6f\n', traj.mean_nn);
    fprintf('Plateau ratio (geom)        : %.6f\n', traj.plateau_ratio_geom);
    fprintf('Najdluzsze plateau (geom)   : %d\n', traj.longest_plateau_geom); 
    fprintf('Coverage mean               : %.6f\n', meta.coverage_mean);
    fprintf('Coverage median             : %.6f\n', meta.coverage_median);
    fprintf('Coverage max                : %.6f\n', meta.coverage_max);
    fprintf('Density mean                : %.6f\n', meta.density_mean);
    fprintf('Density std                 : %.6f\n', meta.density_std);

    if isfield(R, 'verdict') && isstruct(R.verdict)
        if isfield(R.verdict, 'label')
            verdict_str = R.verdict.label;
        elseif isfield(R.verdict, 'text')
            verdict_str = R.verdict.text;
        else
            verdict_str = '[brak etykiety]';
        end
        fprintf('Werdykt LOCI                : %s\n', verdict_str);
    end

    if ~isnan(traj.loci_onset_idx)
        fprintf('LOCI onset                  : G%04d\n', round(traj.loci_onset_idx));
    end
    if ~isnan(traj.loci_max_slope_idx)
        fprintf('LOCI max slope              : G%04d\n', round(traj.loci_max_slope_idx));
    end
    if ~isnan(traj.loci_max_curv_idx)
        fprintf('LOCI max curvature          : G%04d\n', round(traj.loci_max_curv_idx));
    end
    fprintf('==========================================================\n');
end

function i_make_plots(X_norm, P, R, traj, useScoreColor)
    N = size(X_norm,1);
    D = size(X_norm,2);

    if useScoreColor && isfield(R, 'score_smooth') && numel(R.score_smooth) == N
        c = R.score_smooth(:);
    else
        c = (1:N)';
    end

    % Wykres 3D: pierwsze trzy osie albo fallback 2D
    if D >= 3
        figure('Name', 'LOCI Metaspace 3D');
        if ~isempty(P)
            scatter3(P(:,1), P(:,2), P(:,3), 8, '.', 'MarkerEdgeAlpha', 0.15); hold on;
        end
        scatter3(X_norm(:,1), X_norm(:,2), X_norm(:,3), 34, c, 'filled');
        plot3(X_norm(:,1), X_norm(:,2), X_norm(:,3), 'k-', 'LineWidth', 1);
        i_mark_loci_points_3d(X_norm, traj);
        title('Trajektoria sample w metaprzestrzeni (3D)');
        xlabel('F1'); ylabel('F2'); zlabel('F3');
        grid on; colorbar; hold off;
    else
        figure('Name', 'LOCI Metaspace 2D');
        if ~isempty(P)
            scatter(P(:,1), P(:,2), 8, '.'); hold on;
        end
        scatter(X_norm(:,1), X_norm(:,2), 34, c, 'filled');
        plot(X_norm(:,1), X_norm(:,2), 'k-', 'LineWidth', 1);
        i_mark_loci_points_2d(X_norm, traj);
        title('Trajektoria sample w metaprzestrzeni (2D)');
        xlabel('F1'); ylabel('F2');
        grid on; colorbar; hold off;
    end

    % Score po generacjach
    if isfield(R, 'score_smooth') && ~isempty(R.score_smooth)
        figure('Name', 'LOCI score');
        plot(R.score_smooth, 'LineWidth', 1.5); hold on;
        xline_if_valid(traj.loci_max_slope_idx, '--', 'max slope');
        xline_if_valid(traj.loci_max_curv_idx, ':', 'max curvature');
        xline_if_valid(traj.loci_onset_idx, '-', 'onset');
        title('Score smooth + punkty LOCI');
        xlabel('Generacja'); ylabel('Score');
        grid on; hold off;
    end

    % Dlugosc kroku
    step_len = sqrt(sum(diff(X_norm,1,1).^2, 2));
    figure('Name', 'Metaspace step length');
    plot(2:N, step_len, 'LineWidth', 1.2); hold on;
    xline_if_valid(traj.loci_max_slope_idx, '--', 'max slope');
    xline_if_valid(traj.loci_max_curv_idx, ':', 'max curvature');
    xline_if_valid(traj.loci_onset_idx, '-', 'onset');
    title('Dlugosc kroku trajektorii w metaprzestrzeni');
    xlabel('Generacja'); ylabel('||x_t - x_{t-1}||');
    grid on; hold off;
end

function i_mark_loci_points_3d(X_norm, traj)
    idxs = [traj.loci_max_slope_idx, traj.loci_max_curv_idx, traj.loci_onset_idx];
    labels = {'slope','curv','onset'};
    for i = 1:numel(idxs)
        idx = round(idxs(i));
        if ~isnan(idx) && idx >= 1 && idx <= size(X_norm,1)
            plot3(X_norm(idx,1), X_norm(idx,2), X_norm(idx,3), 'ro', 'MarkerSize', 10, 'LineWidth', 1.5);
            text(X_norm(idx,1), X_norm(idx,2), X_norm(idx,3), ['  ' labels{i}]);
        end
    end
end

function i_mark_loci_points_2d(X_norm, traj)
    idxs = [traj.loci_max_slope_idx, traj.loci_max_curv_idx, traj.loci_onset_idx];
    labels = {'slope','curv','onset'};
    for i = 1:numel(idxs)
        idx = round(idxs(i));
        if ~isnan(idx) && idx >= 1 && idx <= size(X_norm,1)
            plot(X_norm(idx,1), X_norm(idx,2), 'ro', 'MarkerSize', 10, 'LineWidth', 1.5);
            text(X_norm(idx,1), X_norm(idx,2), ['  ' labels{i}]);
        end
    end
end

function xline_if_valid(idx, style, labeltxt)
    if ~isnan(idx) && isfinite(idx)
        xline(round(idx), style, labeltxt, 'LabelOrientation', 'horizontal');
    end
end

function r = i_longest_run(mask)
    if isempty(mask)
        r = 0;
        return;
    end
    mask = logical(mask(:));
    d = diff([false; mask; false]);
    starts = find(d == 1);
    stops  = find(d == -1) - 1;
    if isempty(starts)
        r = 0;
    else
        r = max(stops - starts + 1);
    end
end

function x = i_collapse_idx(v)
    v = v(:);
    v = v(isfinite(v));
    if isempty(v)
        x = NaN;
    else
        x = median(v);
    end
end

function y = i_safe_mean(x)
    if isempty(x), y = NaN; else, y = mean(x); end
end
function y = i_safe_median(x)
    if isempty(x), y = NaN; else, y = median(x); end
end
function y = i_safe_std(x)
    if isempty(x), y = NaN; else, y = std(x); end
end
function y = i_safe_min(x)
    if isempty(x), y = NaN; else, y = min(x); end
end
function y = i_safe_max(x)
    if isempty(x), y = NaN; else, y = max(x); end
end
