function out = loci_27D_9R_visualizer_canonical(sampleFile)
% LOCI_27D_9R_VISUALIZER_CANONICAL
% Canonical visualizer for LOCI 27D -> 9R metaspace projections.
%
% Stable pipeline:
%   sampleFile -> load_sample_norm -> sample_norm_to_series
%              -> build_loci_feature_matrix -> visualization + reports
%
% INPUT:
%   sampleFile : path to sample_norm.json or sample_norm.mat
%
% OUTPUT:
%   out : struct with computed metrics and saved file paths
%
% EXAMPLE:
%   loci_27D_9R_visualizer_canonical( ...
%     'C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\sample\Sample_0002\norm\sample_norm.json')

    clc;
    fprintf('=========================================\n');
    fprintf('LOCI 27D -> 9R METASPACE VISUALIZER\n');
    fprintf('=========================================\n');

    if nargin < 1 || isempty(sampleFile)
        sampleFile = lc_autoDetectSampleFile();
    end

    if ~isfile(sampleFile)
        error('loci_27D_9R_visualizer_canonical:InputNotFound', ...
            'Input file not found: %s', sampleFile);
    end

    lociRoot = lc_inferLociRoot(sampleFile);
    lc_addRequiredPaths(lociRoot);

    % ---------------------------------------------------------------------
    % LOAD -> SERIES -> FEATURES
    % ---------------------------------------------------------------------
    sampleStruct = load_sample_norm(sampleFile);
    series = sample_norm_to_series(sampleStruct);
    [X, featureNames, meta] = build_loci_feature_matrix(series);

    if isempty(X) || size(X,1) < 2 || size(X,2) < 2
        error('loci_27D_9R_visualizer_canonical:FeatureMatrixTooSmall', ...
            'Feature matrix is empty or too small to visualize.');
    end

    sampleId = lc_resolveSampleId(series, meta, sampleFile);
    sampleId = lc_sanitizePathPart(sampleId);

    resultDir = fullfile(lociRoot, 'results', sampleId);
    lc_ensureDir(resultDir);

    timestampStr = datestr(now, 'yyyy-mm-dd_HHMMSS');
    runId = ['run_' timestampStr];

    figPng  = fullfile(resultDir, [sampleId '_metaspace_' runId '.png']);
    figFig  = fullfile(resultDir, [sampleId '_metaspace_' runId '.fig']);
    txtOut  = fullfile(resultDir, [sampleId '_metaspace_' runId '.txt']);
    jsonOut = fullfile(resultDir, [sampleId '_metaspace_' runId '.json']);
    mdOut   = fullfile(resultDir, [sampleId '_metaspace_' runId '.md']);

    % ---------------------------------------------------------------------
    % PREPARE DATA
    % ---------------------------------------------------------------------
    X = double(X);
    Xz = lc_zscoreSafe(X);

    [coords3, explained] = lc_reduceTo3D(Xz);

    dSteps = vecnorm(diff(coords3, 1, 1), 2, 2);
    trajLen = sum(dSteps, 'omitnan');

    if isempty(dSteps)
        meanStep = 0;
        maxStep = 0;
        onsetIdx = 1;
    else
        meanStep = mean(dSteps, 'omitnan');
        maxStep  = max(dSteps, [], 'omitnan');
        onsetIdx = lc_detectOnset(dSteps);
    end

    nnDist = lc_nearestNeighborDistance(coords3);

    n = size(coords3, 1);
    gen = (1:n).';

    % ---------------------------------------------------------------------
    % FIGURE
    % ---------------------------------------------------------------------
    hFig = figure( ...
        'Color', 'k', ...
        'Name', 'LOCI 27D -> 9R METASPACE VISUALIZER', ...
        'NumberTitle', 'off', ...
        'Position', [80 60 1400 900]);

    cmap = turbo(max(n, 2));

    % Try to suppress toolbar artifacts in exported images
    try
        set(hFig, 'Toolbar', 'none');
    catch
    end

    % --- subplot 1: 3D trajectory
    subplot(2,2,1);
    hold on;
    grid on;
    box on;
    set(gca, ...
        'Color', 'k', ...
        'XColor', 'w', ...
        'YColor', 'w', ...
        'ZColor', 'w', ...
        'GridColor', [0.4 0.4 0.4]);
    title('Trajektoria artefaktu (9R)', 'Color', 'w', 'FontWeight', 'bold');

    for i = 1:n-1
        plot3(coords3(i:i+1,1), coords3(i:i+1,2), coords3(i:i+1,3), ...
            '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 1.2);
    end

    scatter3(coords3(:,1), coords3(:,2), coords3(:,3), 30, gen, 'filled');
    plot3(coords3(1,1), coords3(1,2), coords3(1,3), 'o', ...
        'MarkerSize', 10, 'MarkerFaceColor', [0 1 1], 'MarkerEdgeColor', 'none');
    plot3(coords3(end,1), coords3(end,2), coords3(end,3), 'o', ...
        'MarkerSize', 10, 'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', 'none');

    xlabel('R1', 'Color', 'w');
    ylabel('R2', 'Color', 'w');
    zlabel('R3', 'Color', 'w');
    view(35, 20);

    % --- subplot 2: dynamics
    subplot(2,2,2);
    hold on;
    grid on;
    box on;
    set(gca, ...
        'Color', 'k', ...
        'XColor', 'w', ...
        'YColor', 'w', ...
        'GridColor', [0.4 0.4 0.4]);

    if n >= 2
        plot(2:n, dSteps, 'c-', 'LineWidth', 1.8);
        xline(onsetIdx, '--r', 'LineWidth', 1.5);
    else
        plot(1, 0, 'c.');
    end

    title('Dynamika trajektorii', 'Color', 'w', 'FontWeight', 'bold');
    xlabel('Generacja', 'Color', 'w');
    ylabel('||\Delta x||', 'Color', 'w');

    % --- subplot 3: nearest neighbor density
    subplot(2,2,3);
    hold on;
    grid on;
    box on;
    set(gca, ...
        'Color', 'k', ...
        'XColor', 'w', ...
        'YColor', 'w', ...
        'GridColor', [0.4 0.4 0.4]);

    plot(gen, nnDist, 'y-', 'LineWidth', 1.8);
    xline(onsetIdx, '--r', 'LineWidth', 1.5);

    title('Gęstość (Nearest Neighbor)', 'Color', 'w', 'FontWeight', 'bold');
    xlabel('Generacja', 'Color', 'w');
    ylabel('Dystans', 'Color', 'w');

    % --- subplot 4: 2D projection
    subplot(2,2,4);
    hold on;
    grid on;
    box on;
    set(gca, ...
        'Color', 'k', ...
        'XColor', 'w', ...
        'YColor', 'w', ...
        'GridColor', [0.4 0.4 0.4]);

    for i = 1:n-1
        plot(coords3(i:i+1,1), coords3(i:i+1,2), ...
            '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 1.2);
    end

    scatter(coords3(:,1), coords3(:,2), 30, gen, 'filled');
    plot(coords3(1,1), coords3(1,2), 'o', ...
        'MarkerSize', 10, 'MarkerFaceColor', [0 1 1], 'MarkerEdgeColor', 'none');
    plot(coords3(end,1), coords3(end,2), 'o', ...
        'MarkerSize', 10, 'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', 'none');

    title('Projekcja 2D (R1-R2)', 'Color', 'w', 'FontWeight', 'bold');
    xlabel('R1', 'Color', 'w');
    ylabel('R2', 'Color', 'w');
    cb = colorbar;
    cb.Color = 'w';

    sgtitle('LOCI 27D -> 9R METASPACE VISUALIZER', 'Color', 'w', 'FontWeight', 'bold');

    drawnow;

    % ---------------------------------------------------------------------
    % SAVE FIGURES
    % ---------------------------------------------------------------------
    try
        exportgraphics(hFig, figPng, 'Resolution', 180);
    catch
        saveas(hFig, figPng);
    end

    try
        savefig(hFig, figFig);
    catch
        saveas(hFig, figFig);
    end

    % ---------------------------------------------------------------------
    % BUILD OUTPUT STRUCT
    % ---------------------------------------------------------------------
    out = struct();
    out.sample_id = sampleId;
    out.input_file = sampleFile;
    out.result_dir = resultDir;
    out.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    out.generations = n;
    out.feature_count = size(X,2);
    out.feature_names = featureNames;
    out.feature_source = 'build_loci_feature_matrix';
    out.onset_generation = onsetIdx;
    out.mean_step = meanStep;
    out.max_step = maxStep;
    out.trajectory_length = trajLen;
    out.explained_variance_3d = explained(:).';
    out.meta = meta;
    out.saved_files = struct( ...
        'png', figPng, ...
        'fig', figFig, ...
        'txt', txtOut, ...
        'json', jsonOut, ...
        'md', mdOut);

    % ---------------------------------------------------------------------
    % WRITE REPORTS
    % ---------------------------------------------------------------------
    lc_writeTxtSummary(txtOut, out);
    lc_writeJsonSummary(jsonOut, out);
    lc_writeMarkdownSummary(mdOut, out);

    % ---------------------------------------------------------------------
    % CONSOLE
    % ---------------------------------------------------------------------
    fprintf('Generations: %d\n', n);
    fprintf('Features   : %d\n', size(X,2));
    fprintf('=== META-WYNIKI ===\n');
    fprintf('Onset (LOCI approx): G%04d\n', onsetIdx);
    fprintf('Mean step          : %.4f\n', meanStep);
    fprintf('Max step           : %.4f\n', maxStep);
    fprintf('Trajectory length  : %.4f\n', trajLen);
    fprintf('\nSaved to:\n');
    fprintf('  PNG : %s\n', figPng);
    fprintf('  FIG : %s\n', figFig);
    fprintf('  TXT : %s\n', txtOut);
    fprintf('  JSON: %s\n', jsonOut);
    fprintf('  MD  : %s\n', mdOut);
end

% =========================================================================
% PATHS / DETECTION
% =========================================================================

function sampleFile = lc_autoDetectSampleFile()
    here = fileparts(mfilename('fullpath'));
    lociRoot = here;

    for k = 1:10
        if isfolder(fullfile(lociRoot, 'sample'))
            break;
        end
        parent = fileparts(lociRoot);
        if strcmp(parent, lociRoot)
            break;
        end
        lociRoot = parent;
    end

    jsonFiles = dir(fullfile(lociRoot, 'sample', 'Sample_*', 'norm', 'sample_norm.json'));
    if ~isempty(jsonFiles)
        sampleFile = fullfile(jsonFiles(1).folder, jsonFiles(1).name);
        return;
    end

    matFiles = dir(fullfile(lociRoot, 'sample', 'Sample_*', 'norm', 'sample_norm.mat'));
    if ~isempty(matFiles)
        sampleFile = fullfile(matFiles(1).folder, matFiles(1).name);
        return;
    end

    error('loci_27D_9R_visualizer_canonical:AutoDetectFailed', ...
        'No sample_norm.json or sample_norm.mat found automatically.');
end

function lociRoot = lc_inferLociRoot(sampleFile)
    lociRoot = fileparts(sampleFile);

    for k = 1:12
        if isfolder(fullfile(lociRoot, 'sample'))
            return;
        end

        [~, lastPart] = fileparts(lociRoot);
        if strcmpi(lastPart, 'LOCI')
            return;
        end

        parent = fileparts(lociRoot);
        if strcmp(parent, lociRoot)
            return;
        end
        lociRoot = parent;
    end
end

function lc_addRequiredPaths(lociRoot)
    adapterDir  = fullfile(lociRoot, 'matlab', 'adapters');
    featuresDir = fullfile(lociRoot, 'matlab', 'features');
    compatDir   = fullfile(lociRoot, 'matlab', 'compat');

    if isfolder(adapterDir)
        addpath(adapterDir);
    end

    if isfolder(featuresDir)
        addpath(featuresDir);
    end

    if isfolder(compatDir)
        addpath(compatDir);
    end
end

function sampleId = lc_resolveSampleId(series, meta, sampleFile)
    sampleId = '';

    if isstruct(series) && isfield(series, 'sample_id')
        sampleId = lc_valueToChar(series.sample_id);
    end

    if isempty(sampleId) && isstruct(meta) && isfield(meta, 'sample_id')
        sampleId = lc_valueToChar(meta.sample_id);
    end

    if isempty(sampleId)
        normDir = fileparts(sampleFile);
        sampleDir = fileparts(normDir);
        [~, sampleId] = fileparts(sampleDir);
    end

    if isempty(sampleId)
        [~, sampleId] = fileparts(sampleFile);
    end

    if isempty(sampleId)
        sampleId = 'Sample_UNKNOWN';
    end
end

function lc_ensureDir(p)
    if ~isfolder(p)
        mkdir(p);
    end
end

function s = lc_sanitizePathPart(v)
    s = lc_valueToChar(v);
    s = regexprep(s, '[^\w\-\.\(\)]', '_');
    if isempty(s)
        s = 'Sample_UNKNOWN';
    end
end

% =========================================================================
% COMPUTATION
% =========================================================================

function Xz = lc_zscoreSafe(X)
    mu = mean(X, 1, 'omitnan');
    sigma = std(X, 0, 1, 'omitnan');
    sigma(sigma == 0 | isnan(sigma)) = 1;
    Xz = (X - mu) ./ sigma;
    Xz(~isfinite(Xz)) = 0;
end

function [coords3, explained] = lc_reduceTo3D(X)
    [n, d] = size(X);

    if d >= 3
        try
            [~, score, ~, ~, explained] = pca(X, 'Rows', 'complete');
            if size(score,2) >= 3
                coords3 = score(:,1:3);
                explained = explained(1:min(3, numel(explained)));
                if numel(explained) < 3
                    explained(end+1:3) = 0;
                end
                return;
            end
        catch
            % fallback below
        end
    end

    coords3 = zeros(n,3);
    coords3(:,1:min(d,3)) = X(:,1:min(d,3));
    explained = [NaN NaN NaN];
end

function onsetIdx = lc_detectOnset(dSteps)
    if isempty(dSteps)
        onsetIdx = 1;
        return;
    end

    medVal = median(dSteps, 'omitnan');
    madVal = median(abs(dSteps - medVal), 'omitnan');

    if isempty(madVal) || ~isfinite(madVal)
        madVal = 0;
    end

    thr = medVal + 1.5 * max(madVal, eps);
    idx = find(dSteps > thr, 1, 'first');

    if isempty(idx)
        [~, idx] = max(dSteps);
    end

    onsetIdx = idx + 1;
end

function nn = lc_nearestNeighborDistance(coords)
    n = size(coords,1);
    nn = zeros(n,1);

    for i = 1:n
        diffMat = coords - coords(i,:);
        dist = sqrt(sum(diffMat.^2, 2));
        dist(i) = inf;
        nn(i) = min(dist);
    end
end

% =========================================================================
% WRITERS
% =========================================================================

function lc_writeTxtSummary(pathOut, out)
    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write TXT summary: %s', pathOut);
        return;
    end

    fprintf(fid, '=========================================\n');
    fprintf(fid, 'LOCI 27D -> 9R METASPACE VISUALIZER\n');
    fprintf(fid, '=========================================\n\n');

    fprintf(fid, 'sample_id         : %s\n', out.sample_id);
    fprintf(fid, 'timestamp         : %s\n', out.timestamp);
    fprintf(fid, 'input_file        : %s\n', out.input_file);
    fprintf(fid, 'result_dir        : %s\n', out.result_dir);
    fprintf(fid, 'generations       : %d\n', out.generations);
    fprintf(fid, 'feature_count     : %d\n', out.feature_count);
    fprintf(fid, 'onset_generation  : G%04d\n', out.onset_generation);
    fprintf(fid, 'mean_step         : %.6f\n', out.mean_step);
    fprintf(fid, 'max_step          : %.6f\n', out.max_step);
    fprintf(fid, 'trajectory_length : %.6f\n', out.trajectory_length);
    fprintf(fid, 'explained_var_3d  : [%s]\n', lc_numArrayToStr(out.explained_variance_3d));

    fprintf(fid, '\nFeature names:\n');
    for i = 1:numel(out.feature_names)
        fprintf(fid, '  %02d. %s\n', i, lc_valueToChar(out.feature_names{i}));
    end

    fprintf(fid, '\nSaved files:\n');
    fprintf(fid, 'PNG  : %s\n', out.saved_files.png);
    fprintf(fid, 'FIG  : %s\n', out.saved_files.fig);
    fprintf(fid, 'TXT  : %s\n', out.saved_files.txt);
    fprintf(fid, 'JSON : %s\n', out.saved_files.json);
    fprintf(fid, 'MD   : %s\n', out.saved_files.md);

    fclose(fid);
end

function lc_writeJsonSummary(pathOut, out)
    try
        txt = jsonencode(out, 'PrettyPrint', true);
    catch
        txt = jsonencode(out);
    end

    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write JSON summary: %s', pathOut);
        return;
    end

    fwrite(fid, txt, 'char');
    fclose(fid);
end

function lc_writeMarkdownSummary(pathOut, out)
    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write MD summary: %s', pathOut);
        return;
    end

    [~, pngName, pngExt] = fileparts(out.saved_files.png);

    fprintf(fid, '# %s - LOCI 27D -> 9R report\n\n', out.sample_id);
    fprintf(fid, '- **Timestamp:** %s\n', out.timestamp);
    fprintf(fid, '- **Input file:** `%s`\n', out.input_file);
    fprintf(fid, '- **Result dir:** `%s`\n', out.result_dir);
    fprintf(fid, '- **Generations:** `%d`\n', out.generations);
    fprintf(fid, '- **Feature count:** `%d`\n', out.feature_count);
    fprintf(fid, '- **Onset (LOCI approx):** `G%04d`\n', out.onset_generation);
    fprintf(fid, '- **Mean step:** `%.6f`\n', out.mean_step);
    fprintf(fid, '- **Max step:** `%.6f`\n', out.max_step);
    fprintf(fid, '- **Trajectory length:** `%.6f`\n', out.trajectory_length);
    fprintf(fid, '- **Explained variance (3D):** `%s`\n\n', lc_numArrayToStr(out.explained_variance_3d));

    fprintf(fid, '## Figure\n\n');
    fprintf(fid, '![%s](./%s%s)\n\n', out.sample_id, pngName, pngExt);

    fprintf(fid, '## Feature names\n\n');
    for i = 1:numel(out.feature_names)
        fprintf(fid, '- `%s`\n', lc_valueToChar(out.feature_names{i}));
    end

    fprintf(fid, '\n## Saved files\n\n');
    fprintf(fid, '- PNG: `%s`\n', out.saved_files.png);
    fprintf(fid, '- FIG: `%s`\n', out.saved_files.fig);
    fprintf(fid, '- TXT: `%s`\n', out.saved_files.txt);
    fprintf(fid, '- JSON: `%s`\n', out.saved_files.json);
    fprintf(fid, '- MD: `%s`\n', out.saved_files.md);

    fclose(fid);
end

% =========================================================================
% HELPERS
% =========================================================================

function s = lc_valueToChar(v)
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
        s = lc_valueToChar(v{1});
        return;
    end

    s = '';
end

function s = lc_numArrayToStr(x)
    if isempty(x)
        s = '';
        return;
    end

    x = x(:).';
    parts = arrayfun(@(v) sprintf('%.6f', v), x, 'UniformOutput', false);
    s = strjoin(parts, ', ');
end