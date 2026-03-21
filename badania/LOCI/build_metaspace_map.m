function R = build_metaspace_map(method, N, bounds, varargin)
% BUILD_METASPACE_MAP
% ------------------------------------------------------------
% Budowa mapy metaprzestrzeni w reżimie:
%   - 'sobol'
%   - 'lhs'
%
% Wejście:
%   method  : 'sobol' albo 'lhs'
%   N       : liczba punktów
%   bounds  : macierz D x 2, [min max] dla każdego wymiaru
%
% Parametry opcjonalne (Name-Value):
%   'Seed'          : seed RNG (domyślnie 42)
%   'Skip'          : skip dla Sobola (domyślnie 1024)
%   'Leap'          : leap dla Sobola (domyślnie 0)
%   'Scramble'      : true/false, scramble Sobola (domyślnie true)
%   'BinCount'      : liczba binów do occupancy (domyślnie 8)
%   'MakePlots'     : true/false (domyślnie true)
%   'ProjectionDims': wymiary do projekcji, np. [1 2 3] (domyślnie pierwsze min(3,D))
%
% Wyjście:
%   R struct:
%       .method
%       .N
%       .D
%       .bounds
%       .X_unit           % punkty w [0,1]^D
%       .X_scaled         % punkty w zadanych zakresach
%       .coverage
%       .distances
%       .occupancy
%       .meta
%
% Przykład:
%   bounds = [0 1; -5 5; 10 20; 100 200];
%   R = build_metaspace_map('sobol', 1024, bounds, 'MakePlots', true);
%
% ------------------------------------------------------------

    p = inputParser;
    addRequired(p, 'method', @(x) ischar(x) || isstring(x));
    addRequired(p, 'N', @(x) isnumeric(x) && isscalar(x) && x > 1);
    addRequired(p, 'bounds', @(x) isnumeric(x) && size(x,2) == 2);
    addParameter(p, 'Seed', 42, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'Skip', 1024, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'Leap', 0, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'Scramble', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'BinCount', 8, @(x) isnumeric(x) && isscalar(x) && x >= 2);
    addParameter(p, 'MakePlots', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'ProjectionDims', [], @(x) isnumeric(x) && isvector(x));
    parse(p, method, N, bounds, varargin{:});

    method   = lower(string(p.Results.method));
    N        = p.Results.N;
    bounds   = p.Results.bounds;
    seed     = p.Results.Seed;
    skip     = p.Results.Skip;
    leap     = p.Results.Leap;
    scramble = logical(p.Results.Scramble);
    binCount = p.Results.BinCount;
    makePlots = logical(p.Results.MakePlots);
    projDims = p.Results.ProjectionDims;

    rng(seed, 'twister');

    D = size(bounds, 1);
    mins = bounds(:,1)';
    maxs = bounds(:,2)';
    spans = maxs - mins;

    if any(spans <= 0)
        error('Każdy wymiar w bounds musi spełniać: max > min.');
    end

    % --------------------------------------------------------
    % 1. Generacja punktów w [0,1]^D
    % --------------------------------------------------------
    switch method
        case "sobol"
            ps = sobolset(D, 'Skip', skip, 'Leap', leap);
            if scramble
                ps = scramble(ps, 'MatousekAffineOwen');
            end
            X_unit = net(ps, N);

        case {"lhs", "hypercube", "latin", "latin_hypercube"}
            X_unit = lhsdesign(N, D, 'criterion', 'maximin', 'iterations', 50);

        otherwise
            error('Nieznana metoda. Użyj: ''sobol'' albo ''lhs''.');
    end

    % --------------------------------------------------------
    % 2. Skalowanie do zakresów fizycznych / semantycznych
    % --------------------------------------------------------
    X_scaled = mins + X_unit .* spans;

    % --------------------------------------------------------
    % 3. Statystyki pokrycia przestrzeni
    % --------------------------------------------------------
    coverage = i_compute_coverage(X_unit, binCount);

    % --------------------------------------------------------
    % 4. Statystyki odległości
    % --------------------------------------------------------
    distances = i_compute_distance_stats(X_unit);

    % --------------------------------------------------------
    % 5. Occupancy histogram per dimension
    % --------------------------------------------------------
    occupancy = i_compute_occupancy(X_unit, binCount);

    % --------------------------------------------------------
    % 6. Meta
    % --------------------------------------------------------
    meta = struct();
    meta.seed = seed;
    meta.bin_count = binCount;
    meta.skip = skip;
    meta.leap = leap;
    meta.scramble = scramble;
    meta.projection_dims = projDims;

    % --------------------------------------------------------
    % 7. Wynik
    % --------------------------------------------------------
    R = struct();
    R.method = char(method);
    R.N = N;
    R.D = D;
    R.bounds = bounds;
    R.X_unit = X_unit;
    R.X_scaled = X_scaled;
    R.coverage = coverage;
    R.distances = distances;
    R.occupancy = occupancy;
    R.meta = meta;

    % --------------------------------------------------------
    % 8. Raport tekstowy
    % --------------------------------------------------------
    fprintf('============================================================\n');
    fprintf('BUILD METASPACE MAP\n');
    fprintf('============================================================\n');
    fprintf('Metoda              : %s\n', upper(char(method)));
    fprintf('Liczba punktów      : %d\n', N);
    fprintf('Wymiarowość         : %d\n', D);
    fprintf('Śr. nearest-neighbor: %.6f\n', distances.nn_mean);
    fprintf('Min nearest-neighbor: %.6f\n', distances.nn_min);
    fprintf('Max nearest-neighbor: %.6f\n', distances.nn_max);
    fprintf('Cover ratio         : %.6f\n', coverage.cover_ratio);
    fprintf('Empty cell ratio    : %.6f\n', coverage.empty_ratio);
    fprintf('Occupancy entropy   : %.6f\n', coverage.occupancy_entropy);
    fprintf('============================================================\n');

    % --------------------------------------------------------
    % 9. Wizualizacja
    % --------------------------------------------------------
    if makePlots
        if isempty(projDims)
            projDims = 1:min(3, D);
        end
        i_make_plots(X_unit, X_scaled, projDims, method, bounds, coverage, distances);
    end
end

% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function coverage = i_compute_coverage(X, binCount)
    [N, D] = size(X);

    % Dla wysokich wymiarów pełna siatka bin^D szybko eksploduje.
    % Robimy analizę na parach wymiarów i uśredniamy.
    pair_list = nchoosek(1:D, 2);
    nPairs = size(pair_list, 1);

    cover_ratios = zeros(nPairs,1);
    empty_ratios = zeros(nPairs,1);
    entropies = zeros(nPairs,1);

    edges = linspace(0,1,binCount+1);

    for k = 1:nPairs
        i = pair_list(k,1);
        j = pair_list(k,2);

        xi = discretize(X(:,i), edges);
        xj = discretize(X(:,j), edges);

        xi(isnan(xi)) = binCount;
        xj(isnan(xj)) = binCount;

        occ = accumarray([xi xj], 1, [binCount binCount]);
        occ_vec = occ(:);

        filled = sum(occ_vec > 0);
        total = numel(occ_vec);

        p = occ_vec / sum(occ_vec);
        p = p(p > 0);

        cover_ratios(k) = filled / total;
        empty_ratios(k) = 1 - cover_ratios(k);
        entropies(k) = -sum(p .* log2(p));
    end

    coverage = struct();
    coverage.cover_ratio = mean(cover_ratios);
    coverage.empty_ratio = mean(empty_ratios);
    coverage.occupancy_entropy = mean(entropies);
    coverage.pair_cover_ratios = cover_ratios;
    coverage.pair_empty_ratios = empty_ratios;
    coverage.pair_entropies = entropies;
    coverage.bin_count = binCount;
    coverage.n_pairs = nPairs;
end

function distances = i_compute_distance_stats(X)
    Dm = pdist2(X, X, 'euclidean');
    Dm(Dm == 0) = inf;

    nn = min(Dm, [], 2);

    distances = struct();
    distances.nn = nn;
    distances.nn_mean = mean(nn);
    distances.nn_std = std(nn);
    distances.nn_min = min(nn);
    distances.nn_max = max(nn);
    distances.nn_median = median(nn);
end

function occupancy = i_compute_occupancy(X, binCount)
    [~, D] = size(X);
    edges = linspace(0,1,binCount+1);

    occupancy = struct();
    occupancy.per_dim = cell(D,1);

    for d = 1:D
        idx = discretize(X(:,d), edges);
        idx(isnan(idx)) = binCount;
        occ = accumarray(idx, 1, [binCount 1]);

        p = occ / sum(occ);
        p_nz = p(p > 0);

        s = struct();
        s.counts = occ;
        s.prob = p;
        s.entropy = -sum(p_nz .* log2(p_nz));
        s.min_count = min(occ);
        s.max_count = max(occ);
        s.std_count = std(occ);

        occupancy.per_dim{d} = s;
    end
end

function i_make_plots(X_unit, X_scaled, projDims, method, bounds, coverage, distances)
    projDims = unique(projDims(:)');
    projDims = projDims(projDims >= 1 & projDims <= size(X_unit,2));

    if numel(projDims) >= 2
        figure('Name', 'Metaspace Map - Unit Projection', 'Color', 'w');
        scatter(X_unit(:,projDims(1)), X_unit(:,projDims(2)), 16, 'filled');
        grid on;
        xlabel(sprintf('dim %d', projDims(1)));
        ylabel(sprintf('dim %d', projDims(2)));
        title(sprintf('Unit projection | %s | cover=%.3f', upper(char(method)), coverage.cover_ratio));
    end

    if numel(projDims) >= 3
        figure('Name', 'Metaspace Map - 3D Projection', 'Color', 'w');
        scatter3( ...
            X_scaled(:,projDims(1)), ...
            X_scaled(:,projDims(2)), ...
            X_scaled(:,projDims(3)), ...
            14, 'filled');
        grid on;
        xlabel(sprintf('dim %d [%.3g, %.3g]', projDims(1), bounds(projDims(1),1), bounds(projDims(1),2)));
        ylabel(sprintf('dim %d [%.3g, %.3g]', projDims(2), bounds(projDims(2),1), bounds(projDims(2),2)));
        zlabel(sprintf('dim %d [%.3g, %.3g]', projDims(3), bounds(projDims(3),1), bounds(projDims(3),2)));
        title(sprintf('Scaled 3D projection | %s', upper(char(method))));
    end

    figure('Name', 'Nearest Neighbor Distribution', 'Color', 'w');
    histogram(distances.nn, 30);
    grid on;
    xlabel('nearest-neighbor distance');
    ylabel('count');
    title(sprintf('NN distribution | mean=%.4f | std=%.4f', distances.nn_mean, distances.nn_std));
end