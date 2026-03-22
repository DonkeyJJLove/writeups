function summary = run_loci_aggregate_report()
% RUN_LOCI_AGGREGATE_REPORT
% Zbiorczy raport dla wszystkich sampli LOCI.
%
% Pipeline:
%   sample_norm.(json|mat) -> visualizer canonical -> aggregate summary
%
% OUTPUT:
%   summary - struct z wynikami zbiorczymi
%
% Zapis:
%   LOCI/results/_aggregate/loci_aggregate_report_<timestamp>.{txt,json,md}

    clc;
    fprintf('=========================================\n');
    fprintf('LOCI AGGREGATE REPORT\n');
    fprintf('=========================================\n');

    lociRoot = lc_find_loci_root();
    lc_add_required_paths(lociRoot);

    sampleRoot = fullfile(lociRoot, 'sample');
    if ~isfolder(sampleRoot)
        error('run_loci_aggregate_report:MissingSampleDir', ...
            'Directory not found: %s', sampleRoot);
    end

    sampleDirs = dir(fullfile(sampleRoot, 'Sample_*'));
    sampleDirs = sampleDirs([sampleDirs.isdir]);

    if isempty(sampleDirs)
        error('run_loci_aggregate_report:NoSamples', ...
            'No Sample_* directories found in: %s', sampleRoot);
    end

    aggregateDir = fullfile(lociRoot, 'results', '_aggregate');
    lc_ensure_dir(aggregateDir);

    timestampStr = datestr(now, 'yyyy-mm-dd_HHMMSS');
    txtOut  = fullfile(aggregateDir, ['loci_aggregate_report_' timestampStr '.txt']);
    jsonOut = fullfile(aggregateDir, ['loci_aggregate_report_' timestampStr '.json']);
    mdOut   = fullfile(aggregateDir, ['loci_aggregate_report_' timestampStr '.md']);

    entries = repmat(lc_empty_entry(), 0, 1);

    passCount = 0;
    failCount = 0;

    for i = 1:numel(sampleDirs)
        sampleId = sampleDirs(i).name;
        fprintf('\n[%d/%d] %s\n', i, numel(sampleDirs), sampleId);

        entry = lc_empty_entry();
        entry.sample_id = sampleId;

        try
            sampleFile = lc_resolve_sample_file(fullfile(sampleDirs(i).folder, sampleId));

            if isempty(sampleFile)
                error('No sample_norm.json or sample_norm.mat found.');
            end

            out = loci_27D_9R_visualizer_canonical(sampleFile);

            entry.ok = true;
            entry.input_file = sampleFile;
            entry.generations = lc_safe_get_num(out, 'generations', NaN);
            entry.feature_count = lc_safe_get_num(out, 'feature_count', NaN);
            entry.onset_generation = lc_safe_get_num(out, 'onset_generation', NaN);
            entry.mean_step = lc_safe_get_num(out, 'mean_step', NaN);
            entry.max_step = lc_safe_get_num(out, 'max_step', NaN);
            entry.trajectory_length = lc_safe_get_num(out, 'trajectory_length', NaN);
            entry.explained_variance_3d = lc_safe_get_array(out, 'explained_variance_3d');
            entry.result_dir = lc_safe_get_char(out, 'result_dir', '');
            entry.png = lc_safe_get_nested_char(out, {'saved_files','png'}, '');
            entry.fig = lc_safe_get_nested_char(out, {'saved_files','fig'}, '');
            entry.txt = lc_safe_get_nested_char(out, {'saved_files','txt'}, '');
            entry.json = lc_safe_get_nested_char(out, {'saved_files','json'}, '');
            entry.md = lc_safe_get_nested_char(out, {'saved_files','md'}, '');
            entry.error_message = '';

            passCount = passCount + 1;
            fprintf('[PASS] %s | G=%d | F=%d | onset=G%04d | traj=%.4f\n', ...
                entry.sample_id, ...
                lc_nan_to_zero(entry.generations), ...
                lc_nan_to_zero(entry.feature_count), ...
                lc_nan_to_zero(entry.onset_generation), ...
                lc_nan_to_zero(entry.trajectory_length));

        catch ME
            entry.ok = false;
            entry.error_message = ME.message;
            failCount = failCount + 1;
            fprintf('[FAIL] %s | %s\n', sampleId, ME.message);
        end

        entries(end+1,1) = entry; %#ok<AGROW>
    end

    summary = struct();
    summary.generated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    summary.loci_root = lociRoot;
    summary.sample_root = sampleRoot;
    summary.aggregate_dir = aggregateDir;
    summary.total_samples = numel(entries);
    summary.passed = passCount;
    summary.failed = failCount;
    summary.ok = (failCount == 0);
    summary.samples = entries;

    metrics = lc_compute_aggregate_metrics(entries);
    summary.metrics = metrics;

    lc_write_txt_report(txtOut, summary);
    lc_write_json_report(jsonOut, summary);
    lc_write_md_report(mdOut, summary);

    fprintf('\n=========================================\n');
    fprintf('AGGREGATE COMPLETE\n');
    fprintf('=========================================\n');
    fprintf('Samples tested : %d\n', summary.total_samples);
    fprintf('Passed         : %d\n', summary.passed);
    fprintf('Failed         : %d\n', summary.failed);
    fprintf('TXT report     : %s\n', txtOut);
    fprintf('JSON report    : %s\n', jsonOut);
    fprintf('MD report      : %s\n', mdOut);
end

% =========================================================================
% CORE HELPERS
% =========================================================================

function entry = lc_empty_entry()
    entry = struct( ...
        'sample_id', '', ...
        'ok', false, ...
        'input_file', '', ...
        'generations', NaN, ...
        'feature_count', NaN, ...
        'onset_generation', NaN, ...
        'mean_step', NaN, ...
        'max_step', NaN, ...
        'trajectory_length', NaN, ...
        'explained_variance_3d', [], ...
        'result_dir', '', ...
        'png', '', ...
        'fig', '', ...
        'txt', '', ...
        'json', '', ...
        'md', '', ...
        'error_message', '' ...
    );
end

function sampleFile = lc_resolve_sample_file(sampleDir)
    sampleFile = '';

    jsonPath = fullfile(sampleDir, 'norm', 'sample_norm.json');
    matPath  = fullfile(sampleDir, 'norm', 'sample_norm.mat');

    if isfile(matPath)
        sampleFile = matPath;
        return;
    end

    if isfile(jsonPath)
        sampleFile = jsonPath;
        return;
    end
end

function metrics = lc_compute_aggregate_metrics(entries)
    metrics = struct();

    okMask = arrayfun(@(e) logical(e.ok), entries);
    okEntries = entries(okMask);

    metrics.sample_ids = {entries.sample_id};

    if isempty(okEntries)
        metrics.mean_generations = NaN;
        metrics.mean_feature_count = NaN;
        metrics.mean_onset_generation = NaN;
        metrics.mean_step = NaN;
        metrics.mean_max_step = NaN;
        metrics.mean_trajectory_length = NaN;
        metrics.max_trajectory_sample = '';
        metrics.max_trajectory_value = NaN;
        metrics.min_trajectory_sample = '';
        metrics.min_trajectory_value = NaN;
        return;
    end

    generations = [okEntries.generations];
    featureCounts = [okEntries.feature_count];
    onsetVals = [okEntries.onset_generation];
    meanSteps = [okEntries.mean_step];
    maxSteps = [okEntries.max_step];
    trajVals = [okEntries.trajectory_length];

    metrics.mean_generations = mean(generations, 'omitnan');
    metrics.mean_feature_count = mean(featureCounts, 'omitnan');
    metrics.mean_onset_generation = mean(onsetVals, 'omitnan');
    metrics.mean_step = mean(meanSteps, 'omitnan');
    metrics.mean_max_step = mean(maxSteps, 'omitnan');
    metrics.mean_trajectory_length = mean(trajVals, 'omitnan');

    [maxTraj, idxMax] = max(trajVals);
    [minTraj, idxMin] = min(trajVals);

    metrics.max_trajectory_sample = okEntries(idxMax).sample_id;
    metrics.max_trajectory_value = maxTraj;
    metrics.min_trajectory_sample = okEntries(idxMin).sample_id;
    metrics.min_trajectory_value = minTraj;
end

% =========================================================================
% PATHS
% =========================================================================

function lociRoot = lc_find_loci_root()
    here = fileparts(mfilename('fullpath'));
    lociRoot = here;

    for k = 1:12
        if isfolder(fullfile(lociRoot, 'sample')) && isfolder(fullfile(lociRoot, 'matlab'))
            return;
        end

        [~, lastPart] = fileparts(lociRoot);
        if strcmpi(lastPart, 'LOCI') && isfolder(fullfile(lociRoot, 'sample'))
            return;
        end

        parent = fileparts(lociRoot);
        if strcmp(parent, lociRoot)
            break;
        end
        lociRoot = parent;
    end

    error('run_loci_aggregate_report:RootNotFound', ...
        'Could not infer LOCI root from: %s', here);
end

function lc_add_required_paths(lociRoot)
    paths = { ...
        fullfile(lociRoot, 'matlab', 'adapters'), ...
        fullfile(lociRoot, 'matlab', 'features'), ...
        fullfile(lociRoot, 'matlab', 'visualizers'), ...
        fullfile(lociRoot, 'matlab', 'compat') ...
    };

    for i = 1:numel(paths)
        if isfolder(paths{i})
            addpath(paths{i});
        end
    end
end

function lc_ensure_dir(p)
    if ~isfolder(p)
        mkdir(p);
    end
end

% =========================================================================
% WRITERS
% =========================================================================

function lc_write_txt_report(pathOut, summary)
    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write TXT report: %s', pathOut);
        return;
    end

    fprintf(fid, '=========================================\n');
    fprintf(fid, 'LOCI AGGREGATE REPORT\n');
    fprintf(fid, '=========================================\n\n');

    fprintf(fid, 'generated_at      : %s\n', summary.generated_at);
    fprintf(fid, 'loci_root         : %s\n', summary.loci_root);
    fprintf(fid, 'sample_root       : %s\n', summary.sample_root);
    fprintf(fid, 'aggregate_dir     : %s\n', summary.aggregate_dir);
    fprintf(fid, 'total_samples     : %d\n', summary.total_samples);
    fprintf(fid, 'passed            : %d\n', summary.passed);
    fprintf(fid, 'failed            : %d\n', summary.failed);
    fprintf(fid, 'ok                : %d\n', summary.ok);

    fprintf(fid, '\n=== METRICS ===\n');
    fprintf(fid, 'mean_generations      : %.6f\n', summary.metrics.mean_generations);
    fprintf(fid, 'mean_feature_count    : %.6f\n', summary.metrics.mean_feature_count);
    fprintf(fid, 'mean_onset_generation : %.6f\n', summary.metrics.mean_onset_generation);
    fprintf(fid, 'mean_step             : %.6f\n', summary.metrics.mean_step);
    fprintf(fid, 'mean_max_step         : %.6f\n', summary.metrics.mean_max_step);
    fprintf(fid, 'mean_trajectory_len   : %.6f\n', summary.metrics.mean_trajectory_length);
    fprintf(fid, 'max_trajectory_sample : %s\n', summary.metrics.max_trajectory_sample);
    fprintf(fid, 'max_trajectory_value  : %.6f\n', summary.metrics.max_trajectory_value);
    fprintf(fid, 'min_trajectory_sample : %s\n', summary.metrics.min_trajectory_sample);
    fprintf(fid, 'min_trajectory_value  : %.6f\n', summary.metrics.min_trajectory_value);

    fprintf(fid, '\n=== SAMPLES ===\n');
    for i = 1:numel(summary.samples)
        e = summary.samples(i);
        fprintf(fid, '\n[%02d] %s\n', i, e.sample_id);
        fprintf(fid, '  ok                : %d\n', e.ok);
        fprintf(fid, '  input_file        : %s\n', e.input_file);
        fprintf(fid, '  generations       : %.0f\n', e.generations);
        fprintf(fid, '  feature_count     : %.0f\n', e.feature_count);
        fprintf(fid, '  onset_generation  : %.0f\n', e.onset_generation);
        fprintf(fid, '  mean_step         : %.6f\n', e.mean_step);
        fprintf(fid, '  max_step          : %.6f\n', e.max_step);
        fprintf(fid, '  trajectory_length : %.6f\n', e.trajectory_length);
        fprintf(fid, '  result_dir        : %s\n', e.result_dir);
        fprintf(fid, '  png               : %s\n', e.png);
        fprintf(fid, '  md                : %s\n', e.md);
        if ~isempty(e.error_message)
            fprintf(fid, '  error             : %s\n', e.error_message);
        end
    end

    fclose(fid);
end

function lc_write_json_report(pathOut, summary)
    try
        txt = jsonencode(summary, 'PrettyPrint', true);
    catch
        txt = jsonencode(summary);
    end

    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write JSON report: %s', pathOut);
        return;
    end
    fwrite(fid, txt, 'char');
    fclose(fid);
end

function lc_write_md_report(pathOut, summary)
    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write MD report: %s', pathOut);
        return;
    end

    fprintf(fid, '# LOCI aggregate report\n\n');
    fprintf(fid, '- **Generated at:** %s\n', summary.generated_at);
    fprintf(fid, '- **Total samples:** %d\n', summary.total_samples);
    fprintf(fid, '- **Passed:** %d\n', summary.passed);
    fprintf(fid, '- **Failed:** %d\n', summary.failed);
    fprintf(fid, '- **Global OK:** %d\n\n', summary.ok);

    fprintf(fid, '## Aggregate metrics\n\n');
    fprintf(fid, '- **Mean generations:** `%.6f`\n', summary.metrics.mean_generations);
    fprintf(fid, '- **Mean feature count:** `%.6f`\n', summary.metrics.mean_feature_count);
    fprintf(fid, '- **Mean onset generation:** `%.6f`\n', summary.metrics.mean_onset_generation);
    fprintf(fid, '- **Mean step:** `%.6f`\n', summary.metrics.mean_step);
    fprintf(fid, '- **Mean max step:** `%.6f`\n', summary.metrics.mean_max_step);
    fprintf(fid, '- **Mean trajectory length:** `%.6f`\n', summary.metrics.mean_trajectory_length);
    fprintf(fid, '- **Max trajectory sample:** `%s` (`%.6f`)\n', ...
        summary.metrics.max_trajectory_sample, summary.metrics.max_trajectory_value);
    fprintf(fid, '- **Min trajectory sample:** `%s` (`%.6f`)\n\n', ...
        summary.metrics.min_trajectory_sample, summary.metrics.min_trajectory_value);

    fprintf(fid, '## Samples\n\n');
    for i = 1:numel(summary.samples)
        e = summary.samples(i);
        fprintf(fid, '### %s\n\n', e.sample_id);
        fprintf(fid, '- **OK:** `%d`\n', e.ok);
        fprintf(fid, '- **Input file:** `%s`\n', e.input_file);
        fprintf(fid, '- **Generations:** `%.0f`\n', e.generations);
        fprintf(fid, '- **Feature count:** `%.0f`\n', e.feature_count);
        fprintf(fid, '- **Onset generation:** `%.0f`\n', e.onset_generation);
        fprintf(fid, '- **Mean step:** `%.6f`\n', e.mean_step);
        fprintf(fid, '- **Max step:** `%.6f`\n', e.max_step);
        fprintf(fid, '- **Trajectory length:** `%.6f`\n', e.trajectory_length);
        fprintf(fid, '- **PNG:** `%s`\n', e.png);
        fprintf(fid, '- **MD:** `%s`\n', e.md);
        if ~isempty(e.error_message)
            fprintf(fid, '- **Error:** `%s`\n', e.error_message);
        end
        fprintf(fid, '\n');
    end

    fclose(fid);
end

% =========================================================================
% SAFE GETTERS
% =========================================================================

function v = lc_safe_get_num(S, fieldName, defaultValue)
    if isstruct(S) && isfield(S, fieldName)
        v = S.(fieldName);
        if isempty(v) || ~isnumeric(v)
            v = defaultValue;
        end
    else
        v = defaultValue;
    end
end

function v = lc_safe_get_array(S, fieldName)
    v = [];
    if isstruct(S) && isfield(S, fieldName)
        vv = S.(fieldName);
        if isnumeric(vv)
            v = vv;
        end
    end
end

function v = lc_safe_get_char(S, fieldName, defaultValue)
    if isstruct(S) && isfield(S, fieldName)
        v = lc_value_to_char(S.(fieldName));
        if isempty(v)
            v = defaultValue;
        end
    else
        v = defaultValue;
    end
end

function v = lc_safe_get_nested_char(S, fieldPath, defaultValue)
    v = defaultValue;
    try
        cur = S;
        for i = 1:numel(fieldPath)
            if isstruct(cur) && isfield(cur, fieldPath{i})
                cur = cur.(fieldPath{i});
            else
                return;
            end
        end
        vv = lc_value_to_char(cur);
        if ~isempty(vv)
            v = vv;
        end
    catch
    end
end

function s = lc_value_to_char(v)
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
        else
            s = lc_value_to_char(v{1});
        end
        return;
    end
    s = '';
end

function x = lc_nan_to_zero(x)
    if isempty(x) || ~isfinite(x)
        x = 0;
    end
end