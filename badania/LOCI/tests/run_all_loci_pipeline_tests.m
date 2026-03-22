function summary = run_all_loci_pipeline_tests()
% RUN_ALL_LOCI_PIPELINE_TESTS
% End-to-end test runner for the LOCI pipeline.
%
% What it tests:
%   1) load_sample_norm
%   2) sample_norm_to_series
%   3) build_loci_feature_matrix
%   4) export_sample_norm_mat
%   5) loci_27D_9R_visualizer_canonical
%
% Output:
%   summary struct
%
% Notes:
%   - Uses cell array summary.samples to avoid:
%       "Subscripted assignment between dissimilar structures."
%   - Automatically discovers sample folders under LOCI/sample
%   - Saves TXT + JSON reports under LOCI/tests/results

    clc;
    fprintf('=========================================\n');
    fprintf('LOCI PIPELINE - FULL TEST RUNNER\n');
    fprintf('=========================================\n');

    testsRoot = fileparts(mfilename('fullpath'));
    lociRoot  = i_inferLociRoot(testsRoot);

    adaptersDir    = fullfile(lociRoot, 'matlab', 'adapters');
    visualizersDir = fullfile(lociRoot, 'matlab', 'visualizers');
    sampleRoot     = fullfile(lociRoot, 'sample');
    resultsRoot    = fullfile(testsRoot, 'results');

    i_ensureDir(resultsRoot);

    addpath(adaptersDir);
    addpath(visualizersDir);

    sampleDirs = dir(fullfile(sampleRoot, 'Sample_*'));
    sampleDirs = sampleDirs([sampleDirs.isdir]);

    timestampStr = datestr(now, 'yyyy-mm-dd_HHMMSS');

    summary = struct();
    summary.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    summary.loci_root = lociRoot;
    summary.tests_root = testsRoot;
    summary.sample_root = sampleRoot;
    summary.results_root = resultsRoot;
    summary.total_samples = 0;
    summary.passed = 0;
    summary.failed = 0;
    summary.ok = false;
    summary.samples = {};   % <-- cell array, not struct array

    totalPass = 0;
    totalFail = 0;

    if isempty(sampleDirs)
        warning('No Sample_* directories found under: %s', sampleRoot);
    end

    for i = 1:numel(sampleDirs)
        sampleName = sampleDirs(i).name;
        sampleDir  = fullfile(sampleDirs(i).folder, sampleName);
        normDir    = fullfile(sampleDir, 'norm');

        entry = i_emptySampleEntry();
        entry.sample_id = sampleName;
        entry.sample_dir = sampleDir;
        entry.norm_dir = normDir;

        stepIdx = 0;

        fprintf('\n-----------------------------------------\n');
        fprintf('Testing sample: %s\n', sampleName);
        fprintf('-----------------------------------------\n');

        try
            jsonFile = fullfile(normDir, 'sample_norm.json');
            matFile  = fullfile(normDir, 'sample_norm.mat');

            % -------------------------------------------------------------
            % Step 1: locate source
            % -------------------------------------------------------------
            if isfile(jsonFile)
                inputFile = jsonFile;
                [entry, stepIdx] = addStep(entry, stepIdx, ...
                    'detect_input', 'pass', sprintf('Using JSON: %s', jsonFile));
            elseif isfile(matFile)
                inputFile = matFile;
                [entry, stepIdx] = addStep(entry, stepIdx, ...
                    'detect_input', 'pass', sprintf('Using MAT: %s', matFile));
            else
                error('No sample_norm.json or sample_norm.mat found in %s', normDir);
            end

            % -------------------------------------------------------------
            % Step 2: load_sample_norm
            % -------------------------------------------------------------
            S = load_sample_norm(inputFile);

            msg = sprintf('Loaded input successfully (%s)', inputFile);
            [entry, stepIdx] = addStep(entry, stepIdx, ...
                'load_sample_norm', 'pass', msg);

            % -------------------------------------------------------------
            % Step 3: sample_norm_to_series
            % -------------------------------------------------------------
            T = sample_norm_to_series(S);

            msg = sprintf('Series OK: sample_id=%s, count=%d', ...
                i_toCharSafe(T.sample_id), i_safeNum(T.count));
            [entry, stepIdx] = addStep(entry, stepIdx, ...
                'sample_norm_to_series', 'pass', msg);

            entry.series_count = i_safeNum(T.count);

            % -------------------------------------------------------------
            % Step 4: build_loci_feature_matrix
            % -------------------------------------------------------------
            [X, featureNames, meta] = build_loci_feature_matrix(T);

            msg = sprintf('Feature matrix OK: %d x %d', size(X,1), size(X,2));
            [entry, stepIdx] = addStep(entry, stepIdx, ...
                'build_loci_feature_matrix', 'pass', msg);

            entry.feature_rows = size(X,1);
            entry.feature_cols = size(X,2);
            entry.feature_names = featureNames;
            entry.feature_meta = meta;

            % -------------------------------------------------------------
            % Step 5: export_sample_norm_mat
            % -------------------------------------------------------------
            if isfile(jsonFile)
                export_sample_norm_mat(jsonFile);

                if isfile(matFile)
                    [entry, stepIdx] = addStep(entry, stepIdx, ...
                        'export_sample_norm_mat', 'pass', ...
                        sprintf('MAT exported: %s', matFile));
                else
                    error('export_sample_norm_mat did not create MAT file.');
                end
            else
                [entry, stepIdx] = addStep(entry, stepIdx, ...
                    'export_sample_norm_mat', 'pass', ...
                    'Skipped export because source was MAT.');
            end

            % -------------------------------------------------------------
            % Step 6: load MAT after export (if exists)
            % -------------------------------------------------------------
            if isfile(matFile)
                S2 = load_sample_norm(matFile);
                T2 = sample_norm_to_series(S2);

                msg = sprintf('MAT re-load OK: sample_id=%s, count=%d', ...
                    i_toCharSafe(T2.sample_id), i_safeNum(T2.count));
                [entry, stepIdx] = addStep(entry, stepIdx, ...
                    'reload_mat_pipeline', 'pass', msg);
            else
                [entry, stepIdx] = addStep(entry, stepIdx, ...
                    'reload_mat_pipeline', 'skip', 'MAT file not present.');
            end

            % -------------------------------------------------------------
            % Step 7: visualizer
            % -------------------------------------------------------------
            vizInput = inputFile;
            if isfile(matFile)
                vizInput = matFile; % prefer MAT if available
            elseif isfile(jsonFile)
                vizInput = jsonFile;
            end

            vizOut = loci_27D_9R_visualizer_canonical(vizInput);

            msg = sprintf('onset=G%04d, traj=%.4f', ...
                i_safeNum(vizOut.onset_generation), i_safeNum(vizOut.trajectory_length));
            [entry, stepIdx] = addStep(entry, stepIdx, ...
                'loci_27D_9R_visualizer_canonical', 'pass', msg);

            entry.visualizer_output = vizOut;
            entry.ok = true;
            totalPass = totalPass + 1;

            fprintf('[PASS] loci_27D_9R_visualizer_canonical\n');
            fprintf('       onset=G%04d, traj=%.4f\n', ...
                i_safeNum(vizOut.onset_generation), i_safeNum(vizOut.trajectory_length));

        catch ME
            [entry, stepIdx] = addStep(entry, stepIdx, ...
                'pipeline_error', 'fail', ME.message);
            entry.ok = false;
            entry.error_message = ME.message;
            totalFail = totalFail + 1;

            fprintf('[FAIL] %s\n', ME.message);
        end

        % CRITICAL FIX:
        summary.samples{end+1,1} = entry;
    end

    summary.total_samples = numel(sampleDirs);
    summary.passed = totalPass;
    summary.failed = totalFail;
    summary.ok = (totalFail == 0);

    txtReport  = fullfile(resultsRoot, ['test_loci_pipeline_' timestampStr '.txt']);
    jsonReport = fullfile(resultsRoot, ['test_loci_pipeline_' timestampStr '.json']);

    i_writeTxtReport(txtReport, summary);
    i_writeJsonReport(jsonReport, summary);

    summary.report_txt = txtReport;
    summary.report_json = jsonReport;

    fprintf('\n=========================================\n');
    fprintf('TEST RUN COMPLETE\n');
    fprintf('=========================================\n');
    fprintf('Samples tested : %d\n', summary.total_samples);
    fprintf('Passed         : %d\n', summary.passed);
    fprintf('Failed         : %d\n', summary.failed);
    fprintf('TXT report     : %s\n', txtReport);
    fprintf('JSON report    : %s\n', jsonReport);
end

% ========================================================================
% HELPERS
% ========================================================================

function [entry, stepIdx] = addStep(entry, stepIdx, name, status, message)
    stepIdx = stepIdx + 1;

    s = struct();
    s.index = stepIdx;
    s.name = name;
    s.status = status;
    s.message = message;
    s.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

    if isempty(entry.steps)
        entry.steps = s;
    else
        entry.steps(end+1,1) = s;
    end
end

function entry = i_emptySampleEntry()
    entry = struct();
    entry.sample_id = '';
    entry.sample_dir = '';
    entry.norm_dir = '';
    entry.ok = false;
    entry.error_message = '';
    entry.series_count = NaN;
    entry.feature_rows = NaN;
    entry.feature_cols = NaN;
    entry.feature_names = {};
    entry.feature_meta = struct();
    entry.visualizer_output = struct();
    entry.steps = struct('index', {}, 'name', {}, 'status', {}, 'message', {}, 'timestamp', {});
end

function lociRoot = i_inferLociRoot(startPath)
    lociRoot = startPath;

    for k = 1:10
        if isfolder(fullfile(lociRoot, 'sample')) && isfolder(fullfile(lociRoot, 'matlab'))
            return;
        end

        [parent, name] = fileparts(lociRoot);
        if strcmpi(name, 'LOCI') && isfolder(fullfile(lociRoot, 'sample'))
            return;
        end

        if isempty(parent) || strcmp(parent, lociRoot)
            break;
        end
        lociRoot = parent;
    end

    error('Could not infer LOCI root from: %s', startPath);
end

function i_ensureDir(p)
    if ~isfolder(p)
        mkdir(p);
    end
end

function s = i_toCharSafe(v)
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
            s = i_toCharSafe(v{1});
        end
        return;
    end

    s = '';
end

function n = i_safeNum(v)
    if isnumeric(v) || islogical(v)
        if isempty(v)
            n = NaN;
        else
            n = double(v(1));
        end
    else
        n = NaN;
    end
end

function i_writeTxtReport(pathOut, summary)
    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write TXT report: %s', pathOut);
        return;
    end

    fprintf(fid, '=========================================\n');
    fprintf(fid, 'LOCI PIPELINE - FULL TEST REPORT\n');
    fprintf(fid, '=========================================\n\n');

    fprintf(fid, 'timestamp     : %s\n', summary.timestamp);
    fprintf(fid, 'loci_root     : %s\n', summary.loci_root);
    fprintf(fid, 'sample_root   : %s\n', summary.sample_root);
    fprintf(fid, 'results_root  : %s\n', summary.results_root);
    fprintf(fid, 'total_samples : %d\n', summary.total_samples);
    fprintf(fid, 'passed        : %d\n', summary.passed);
    fprintf(fid, 'failed        : %d\n', summary.failed);
    fprintf(fid, 'ok            : %d\n', summary.ok);

    for i = 1:numel(summary.samples)
        s = summary.samples{i};

        fprintf(fid, '\n-----------------------------------------\n');
        fprintf(fid, 'SAMPLE: %s\n', s.sample_id);
        fprintf(fid, '-----------------------------------------\n');
        fprintf(fid, 'ok            : %d\n', s.ok);
        fprintf(fid, 'sample_dir    : %s\n', s.sample_dir);
        fprintf(fid, 'norm_dir      : %s\n', s.norm_dir);
        fprintf(fid, 'series_count  : %s\n', i_numToPrintable(s.series_count));
        fprintf(fid, 'feature_rows  : %s\n', i_numToPrintable(s.feature_rows));
        fprintf(fid, 'feature_cols  : %s\n', i_numToPrintable(s.feature_cols));

        if ~isempty(s.error_message)
            fprintf(fid, 'error_message : %s\n', s.error_message);
        end

        fprintf(fid, '\nSTEPS:\n');
        for j = 1:numel(s.steps)
            st = s.steps(j);
            fprintf(fid, '  [%02d] %-35s %-6s %s\n', ...
                st.index, st.name, upper(st.status), st.message);
        end
    end

    fclose(fid);
end

function i_writeJsonReport(pathOut, summary)
    summaryForJson = summary;
    try
        txt = jsonencode(summaryForJson, 'PrettyPrint', true);
    catch
        txt = jsonencode(summaryForJson);
    end

    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write JSON report: %s', pathOut);
        return;
    end

    fwrite(fid, txt, 'char');
    fclose(fid);
end

function s = i_numToPrintable(x)
    if isempty(x) || ~isnumeric(x) || any(isnan(x))
        s = 'NaN';
        return;
    end

    if numel(x) == 1
        s = num2str(x);
    else
        s = mat2str(x);
    end
end