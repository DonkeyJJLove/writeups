function summary = run_all_loci_pipeline_tests(lociRoot)
% RUN_ALL_LOCI_PIPELINE_TESTS
% Full pipeline test runner for LOCI.
%
% Tests:
%   1) load_sample_norm
%   2) sample_norm_to_series
%   3) build_loci_feature_matrix
%   4) export_sample_norm_mat
%   5) loci_27D_9R_visualizer_canonical
%
% Writes reports to:
%   LOCI/tests/results/
%
% USAGE:
%   cd('C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\tests');
%   summary = run_all_loci_pipeline_tests();
%
% OPTIONAL:
%   summary = run_all_loci_pipeline_tests('C:\...\LOCI');

    if nargin < 1 || isempty(lociRoot)
        lociRoot = i_detectLociRoot();
    end

    testsDir   = fullfile(lociRoot, 'tests');
    resultsDir = fullfile(testsDir, 'results');
    sampleRoot = fullfile(lociRoot, 'sample');

    i_ensureDir(resultsDir);

    addpath(fullfile(lociRoot, 'matlab', 'adapters'));
    addpath(fullfile(lociRoot, 'matlab', 'visualizers'));

    sampleDirs = dir(fullfile(sampleRoot, 'Sample_*'));
    sampleDirs = sampleDirs([sampleDirs.isdir]);

    timestampStr = datestr(now, 'yyyy-mm-dd_HHMMSS');

    summary = struct();
    summary.created_at   = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    summary.loci_root    = lociRoot;
    summary.tests_dir    = testsDir;
    summary.results_dir  = resultsDir;
    summary.sample_root  = sampleRoot;
    summary.sample_count = numel(sampleDirs);
    summary.pass_count   = 0;
    summary.fail_count   = 0;
    summary.samples      = repmat(i_emptySampleEntry(), 0, 1);

    fprintf('=========================================\n');
    fprintf('LOCI PIPELINE TEST RUNNER\n');
    fprintf('=========================================\n');
    fprintf('LOCI root   : %s\n', lociRoot);
    fprintf('Sample root : %s\n', sampleRoot);
    fprintf('Samples     : %d\n\n', numel(sampleDirs));

    for i = 1:numel(sampleDirs)
        sampleId   = sampleDirs(i).name;
        samplePath = fullfile(sampleDirs(i).folder, sampleDirs(i).name);
        normDir    = fullfile(samplePath, 'norm');
        jsonPath   = fullfile(normDir, 'sample_norm.json');
        matPath    = fullfile(normDir, 'sample_norm.mat');

        entry = i_emptySampleEntry();
        entry.sample_id   = sampleId;
        entry.sample_path = samplePath;
        entry.norm_dir    = normDir;
        entry.json_path   = jsonPath;
        entry.mat_path    = matPath;

        fprintf('--- [%d/%d] %s ---\n', i, numel(sampleDirs), sampleId);

        try
            if ~isfolder(samplePath)
                error('Sample directory not found: %s', samplePath);
            end
            if ~isfolder(normDir)
                error('Norm directory not found: %s', normDir);
            end
            entry.steps(end+1) = i_step('sample_layout', true, 'sample and norm directories exist'); %#ok<AGROW>

            sourceFile = '';
            sourceKind = '';

            if isfile(jsonPath)
                sourceFile = jsonPath;
                sourceKind = 'json';
            elseif isfile(matPath)
                sourceFile = matPath;
                sourceKind = 'mat';
            else
                error('Neither sample_norm.json nor sample_norm.mat exists in %s', normDir);
            end
            entry.steps(end+1) = i_step('detect_source', true, sprintf('%s [%s]', sourceFile, sourceKind)); %#ok<AGROW>

            S = load_sample_norm(sourceFile);
            entry.steps(end+1) = i_step('load_sample_norm', true, sprintf('loaded from %s; class=%s', sourceKind, class(S))); %#ok<AGROW>

            T = sample_norm_to_series(S);
            if ~isstruct(T)
                error('sample_norm_to_series did not return a struct');
            end
            if ~isfield(T, 'count') || T.count < 1
                error('sample_norm_to_series returned empty series');
            end
            entry.steps(end+1) = i_step('sample_norm_to_series', true, sprintf('count=%d', T.count)); %#ok<AGROW>

            [X, featureNames, meta] = build_loci_feature_matrix(T);
            if ~isnumeric(X) || isempty(X)
                error('build_loci_feature_matrix returned empty X');
            end
            if size(X,1) ~= T.count
                error('Feature row count mismatch: size(X,1)=%d, T.count=%d', size(X,1), T.count);
            end

            entry.feature_meta.sample_id = i_safeStructField(meta, 'sample_id', '');
            entry.feature_meta.n         = i_safeStructField(meta, 'n', size(X,1));
            entry.feature_meta.d         = i_safeStructField(meta, 'd', size(X,2));
            entry.feature_meta.feature_names = featureNames;

            entry.steps(end+1) = i_step( ...
                'build_loci_feature_matrix', ...
                true, ...
                sprintf('size=%dx%d, features=%d', size(X,1), size(X,2), numel(featureNames))); %#ok<AGROW>

            if isfile(jsonPath)
                export_sample_norm_mat(jsonPath);
                if ~isfile(matPath)
                    error('export_sample_norm_mat did not create MAT: %s', matPath);
                end
                entry.steps(end+1) = i_step('export_sample_norm_mat', true, matPath); %#ok<AGROW>
            else
                entry.steps(end+1) = i_step('export_sample_norm_mat', true, 'skipped (JSON missing, MAT already used)'); %#ok<AGROW>
            end

            if isfile(matPath)
                S2 = load_sample_norm(matPath);
                T2 = sample_norm_to_series(S2);
                [X2, featureNames2, meta2] = build_loci_feature_matrix(T2); %#ok<ASGLU>

                if size(X2,1) ~= T2.count
                    error('MAT roundtrip feature row count mismatch');
                end
                if size(X2,2) ~= numel(featureNames2)
                    error('MAT roundtrip feature column count mismatch');
                end

                entry.steps(end+1) = i_step('mat_roundtrip', true, sprintf('size=%dx%d', size(X2,1), size(X2,2))); %#ok<AGROW>
            else
                entry.steps(end+1) = i_step('mat_roundtrip', false, 'MAT file missing after export'); %#ok<AGROW>
                error('MAT file missing after export: %s', matPath);
            end

            visOut = loci_27D_9R_visualizer_canonical(sourceFile);

            entry.visualizer_output.sample_id          = i_safeStructField(visOut, 'sample_id', sampleId);
            entry.visualizer_output.input_file         = i_safeStructField(visOut, 'input_file', sourceFile);
            entry.visualizer_output.result_dir         = i_safeStructField(visOut, 'result_dir', '');
            entry.visualizer_output.timestamp          = i_safeStructField(visOut, 'timestamp', '');
            entry.visualizer_output.generations        = i_safeStructField(visOut, 'generations', NaN);
            entry.visualizer_output.feature_count      = i_safeStructField(visOut, 'feature_count', NaN);
            entry.visualizer_output.feature_source     = i_safeStructField(visOut, 'feature_source', '');
            entry.visualizer_output.onset_generation   = i_safeStructField(visOut, 'onset_generation', NaN);
            entry.visualizer_output.mean_step          = i_safeStructField(visOut, 'mean_step', NaN);
            entry.visualizer_output.max_step           = i_safeStructField(visOut, 'max_step', NaN);
            entry.visualizer_output.trajectory_length  = i_safeStructField(visOut, 'trajectory_length', NaN);
            entry.visualizer_output.explained_variance_3d = i_safeStructField(visOut, 'explained_variance_3d', []);
            entry.visualizer_output.saved_files        = i_safeSavedFiles(visOut);

            missingArtifacts = i_checkVisualizerArtifacts(entry.visualizer_output);

            if isempty(missingArtifacts)
                entry.steps(end+1) = i_step( ...
                    'loci_27D_9R_visualizer_canonical', ...
                    true, ...
                    sprintf('onset=G%04d, traj=%.4f', ...
                        entry.visualizer_output.onset_generation, ...
                        entry.visualizer_output.trajectory_length)); %#ok<AGROW>
            else
                entry.steps(end+1) = i_step( ...
                    'loci_27D_9R_visualizer_canonical', ...
                    false, ...
                    ['missing artifacts: ' strjoin(missingArtifacts, ', ')]); %#ok<AGROW>
                error('Visualizer finished, but some output artifacts are missing.');
            end

            entry.ok = true;
            summary.pass_count = summary.pass_count + 1;

            fprintf('[PASS] %s\n\n', sampleId);

        catch ME
            entry.ok = false;
            entry.error_message = sprintf('%s | %s', ME.identifier, ME.message);
            entry.steps(end+1) = i_step('fatal', false, entry.error_message); %#ok<AGROW>
            summary.fail_count = summary.fail_count + 1;

            fprintf('[FAIL] %s\n', sampleId);
            fprintf('       %s\n\n', entry.error_message);
        end

        summary.samples(end+1,1) = entry; %#ok<AGROW>
    end

    summary.completed_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

    reportBase = fullfile(resultsDir, ['test_loci_pipeline_' timestampStr]);
    txtPath  = [reportBase '.txt'];
    jsonPath = [reportBase '.json'];

    i_writeTxtReport(txtPath, summary);
    i_writeJsonReport(jsonPath, summary);

    fprintf('=========================================\n');
    fprintf('TEST SUMMARY\n');
    fprintf('=========================================\n');
    fprintf('PASS: %d\n', summary.pass_count);
    fprintf('FAIL: %d\n', summary.fail_count);
    fprintf('Raport TXT : %s\n', txtPath);
    fprintf('Raport JSON: %s\n', jsonPath);
end

% =========================================================================
% ENTRY TEMPLATES
% =========================================================================

function entry = i_emptySampleEntry()
    entry = struct( ...
        'sample_id', '', ...
        'sample_path', '', ...
        'norm_dir', '', ...
        'json_path', '', ...
        'mat_path', '', ...
        'steps', repmat(i_emptyStep(), 0, 1), ...
        'ok', false, ...
        'error_message', '', ...
        'visualizer_output', i_emptyVisualizerOutput(), ...
        'feature_meta', i_emptyFeatureMeta() ...
    );
end

function step = i_emptyStep()
    step = struct( ...
        'name', '', ...
        'status', false, ...
        'details', '' ...
    );
end

function vis = i_emptyVisualizerOutput()
    vis = struct( ...
        'sample_id', '', ...
        'input_file', '', ...
        'result_dir', '', ...
        'timestamp', '', ...
        'generations', NaN, ...
        'feature_count', NaN, ...
        'feature_source', '', ...
        'onset_generation', NaN, ...
        'mean_step', NaN, ...
        'max_step', NaN, ...
        'trajectory_length', NaN, ...
        'explained_variance_3d', [], ...
        'saved_files', i_emptySavedFiles() ...
    );
end

function meta = i_emptyFeatureMeta()
    meta = struct( ...
        'sample_id', '', ...
        'n', NaN, ...
        'd', NaN, ...
        'feature_names', {cell(0,1)} ...
    );
end

function sf = i_emptySavedFiles()
    sf = struct( ...
        'png', '', ...
        'fig', '', ...
        'txt', '', ...
        'json', '', ...
        'md', '' ...
    );
end

% =========================================================================
% STEP / VALIDATION
% =========================================================================

function step = i_step(name, status, details)
    step = i_emptyStep();
    step.name = char(name);
    step.status = logical(status);
    step.details = char(details);
end

function saved = i_safeSavedFiles(visOut)
    saved = i_emptySavedFiles();

    if isstruct(visOut) && isfield(visOut, 'saved_files') && isstruct(visOut.saved_files)
        saved.png  = i_safeStructField(visOut.saved_files, 'png', '');
        saved.fig  = i_safeStructField(visOut.saved_files, 'fig', '');
        saved.txt  = i_safeStructField(visOut.saved_files, 'txt', '');
        saved.json = i_safeStructField(visOut.saved_files, 'json', '');
        saved.md   = i_safeStructField(visOut.saved_files, 'md', '');
    end
end

function missing = i_checkVisualizerArtifacts(visOut)
    missing = {};

    if ~isstruct(visOut) || ~isfield(visOut, 'saved_files')
        missing = {'saved_files struct missing'};
        return;
    end

    req = {'png', 'fig', 'txt', 'json', 'md'};
    for k = 1:numel(req)
        key = req{k};

        if ~isfield(visOut.saved_files, key)
            missing{end+1} = key; %#ok<AGROW>
            continue;
        end

        p = visOut.saved_files.(key);
        if ~(ischar(p) || (isstring(p) && isscalar(p)))
            missing{end+1} = key; %#ok<AGROW>
            continue;
        end

        p = char(p);
        if isempty(p) || ~isfile(p)
            missing{end+1} = key; %#ok<AGROW>
        end
    end
end

% =========================================================================
% REPORTS
% =========================================================================

function i_writeTxtReport(pathOut, summary)
    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write TXT report: %s', pathOut);
        return;
    end

    fprintf(fid, '=========================================\n');
    fprintf(fid, 'LOCI PIPELINE TEST REPORT\n');
    fprintf(fid, '=========================================\n\n');

    fprintf(fid, 'created_at   : %s\n', i_toStr(i_safeStructField(summary, 'created_at', '')));
    fprintf(fid, 'completed_at : %s\n', i_toStr(i_safeStructField(summary, 'completed_at', '')));
    fprintf(fid, 'loci_root    : %s\n', i_toStr(i_safeStructField(summary, 'loci_root', '')));
    fprintf(fid, 'sample_root  : %s\n', i_toStr(i_safeStructField(summary, 'sample_root', '')));
    fprintf(fid, 'sample_count : %s\n', i_toStr(i_safeStructField(summary, 'sample_count', NaN)));
    fprintf(fid, 'pass_count   : %s\n', i_toStr(i_safeStructField(summary, 'pass_count', NaN)));
    fprintf(fid, 'fail_count   : %s\n\n', i_toStr(i_safeStructField(summary, 'fail_count', NaN)));

    for i = 1:numel(summary.samples)
        s = summary.samples(i);

        fprintf(fid, '-----------------------------------------\n');
        fprintf(fid, 'sample_id    : %s\n', i_toStr(s.sample_id));
        fprintf(fid, 'sample_path  : %s\n', i_toStr(s.sample_path));
        fprintf(fid, 'norm_dir     : %s\n', i_toStr(s.norm_dir));
        fprintf(fid, 'json_path    : %s\n', i_toStr(s.json_path));
        fprintf(fid, 'mat_path     : %s\n', i_toStr(s.mat_path));
        fprintf(fid, 'ok           : %d\n', s.ok);

        if ~isempty(s.error_message)
            fprintf(fid, 'error        : %s\n', s.error_message);
        end

        if isstruct(s.feature_meta)
            fprintf(fid, 'feature_n    : %s\n', i_toStr(i_safeStructField(s.feature_meta, 'n', NaN)));
            fprintf(fid, 'feature_d    : %s\n', i_toStr(i_safeStructField(s.feature_meta, 'd', NaN)));
        end

        if isstruct(s.visualizer_output)
            onsetVal = i_safeStructField(s.visualizer_output, 'onset_generation', NaN);
            trajVal  = i_safeStructField(s.visualizer_output, 'trajectory_length', NaN);

            if ~isnan(onsetVal)
                fprintf(fid, 'onset        : G%04d\n', onsetVal);
            end
            if ~isnan(trajVal)
                fprintf(fid, 'trajectory   : %.6f\n', trajVal);
            end
        end

        fprintf(fid, 'steps:\n');
        for j = 1:numel(s.steps)
            mark = 'FAIL';
            if s.steps(j).status
                mark = 'PASS';
            end
            fprintf(fid, '  - [%s] %s :: %s\n', mark, s.steps(j).name, s.steps(j).details);
        end
        fprintf(fid, '\n');
    end

    fclose(fid);
end

function i_writeJsonReport(pathOut, summary)
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

% =========================================================================
% GENERIC HELPERS
% =========================================================================

function value = i_safeStructField(s, fieldName, defaultValue)
    value = defaultValue;

    if isstruct(s) && isfield(s, fieldName)
        tmp = s.(fieldName);
        if ~isempty(tmp)
            value = tmp;
        end
    end
end

function s = i_toStr(v)
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
        if isempty(v)
            s = '';
        elseif isscalar(v)
            s = num2str(v);
        else
            s = mat2str(v);
        end
        return;
    end

    if iscell(v)
        if isempty(v)
            s = '';
        else
            try
                s = i_toStr(v{1});
            catch
                s = '';
            end
        end
        return;
    end

    s = '';
end

function root = i_detectLociRoot()
    here = fileparts(mfilename('fullpath'));
    root = here;

    for k = 1:10
        if isfolder(fullfile(root, 'sample')) && ...
           isfolder(fullfile(root, 'matlab')) && ...
           isfolder(fullfile(root, 'tests'))
            return;
        end

        parent = fileparts(root);
        if strcmp(parent, root)
            break;
        end
        root = parent;
    end

    error('Could not auto-detect LOCI root from: %s', here);
end

function i_ensureDir(p)
    if ~isfolder(p)
        mkdir(p);
    end
end