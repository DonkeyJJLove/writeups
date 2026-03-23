function out = run_loci_cognitive_readiness_test(sampleFile)
% RUN_LOCI_COGNITIVE_READINESS_TEST
% LOCI Cognitive Readiness Test (LCRT)
%
% Cel:
%   Oszacować, od której generacji artefakt staje się poznawczo stabilny
%   oraz bardziej "właściwy" dla pracy z LLM, tzn. ogranicza ryzyko
%   nadinterpretacji, błędów i halucynacji.
%
% Wersja ta dodaje:
%   - fallback candidate generation
%   - rozstrzygnięcie przybliżone, gdy brak pełnego window-pass

    clc;
    fprintf('=========================================\n');
    fprintf('LOCI COGNITIVE READINESS TEST\n');
    fprintf('=========================================\n');

    if nargin < 1 || isempty(sampleFile)
        sampleFile = lc_autoDetectSampleFile();
    end

    if ~isfile(sampleFile)
        error('run_loci_cognitive_readiness_test:InputNotFound', ...
            'Input file not found: %s', sampleFile);
    end

    lociRoot = lc_inferLociRoot(sampleFile);
    lc_addRequiredPaths(lociRoot);

    sampleStruct = load_sample_norm(sampleFile);
    series = sample_norm_to_series(sampleStruct);
    [X, featureNames, meta] = build_loci_feature_matrix(series);

    n = series.count;
    if n < 2
        error('run_loci_cognitive_readiness_test:TooFewGenerations', ...
            'Need at least 2 generations.');
    end

    sampleId = lc_resolveSampleId(series, meta, sampleFile);
    sampleId = lc_sanitizePathPart(sampleId);

    resultDir = fullfile(lociRoot, 'results', sampleId);
    lc_ensureDir(resultDir);

    timestampStr = datestr(now, 'yyyy-mm-dd_HHMMSS');
    runId = ['lcrt_' timestampStr];

    figPng  = fullfile(resultDir, [sampleId '_' runId '.png']);
    figFig  = fullfile(resultDir, [sampleId '_' runId '.fig']);
    txtOut  = fullfile(resultDir, [sampleId '_' runId '.txt']);
    jsonOut = fullfile(resultDir, [sampleId '_' runId '.json']);
    mdOut   = fullfile(resultDir, [sampleId '_' runId '.md']);

    stopwords = lc_stopwords_pl_en();
    negativeProbeTerms = { ...
        'grupa kontrolna', 'laboratoryjny', 'roc', 'auc', 'bibliografia', ...
        'cytowanie', 'publikacja', 'dowod formalny', 'formalny dowod', ...
        'twierdzenie matematyczne', 'eksperyment randomizowany' ...
    };

    rows = repmat(lc_empty_row(), n, 1);
    prevKeywords = {};
    prevAnswers = struct();

    for i = 1:n
        rec = series.records(i);
        text = lc_get_record_text(rec);
        textLower = lower(text);

        words = lc_tokenize(textLower);
        keywords = lc_top_keywords(words, stopwords, 12);

        answerProfile = lc_answer_profile(textLower, words, keywords);
        groundedness = lc_groundedness_proxy(textLower, words);
        ambiguity = lc_ambiguity_proxy(textLower, words);
        negRisk = lc_negative_hallucination_proxy(textLower, words, negativeProbeTerms);
        interpDebt = lc_interpretive_debt(ambiguity, groundedness);
        structureScore = lc_structure_score(textLower, words);

        if i == 1
            coreStability = 0;
            answerStability = 0;
        else
            coreStability = lc_jaccard(prevKeywords, keywords);
            answerStability = lc_answer_stability(prevAnswers, answerProfile);
        end

        maturityScore = lc_maturity_score(coreStability, answerStability, ...
            groundedness, structureScore, negRisk, interpDebt);

        rows(i).generation = i;
        rows(i).char_len = length(text);
        rows(i).word_count = numel(words);
        rows(i).core_stability = coreStability;
        rows(i).answer_stability = answerStability;
        rows(i).groundedness = groundedness;
        rows(i).negative_hallucination_risk = negRisk;
        rows(i).interpretive_debt = interpDebt;
        rows(i).structure_score = structureScore;
        rows(i).maturity_score = maturityScore;
        rows(i).keywords = keywords;
        rows(i).snapshot_title = lc_safe_trim(text, 140);

        prevKeywords = keywords;
        prevAnswers = answerProfile;
    end

    coreVec   = [rows.core_stability]';
    ansVec    = [rows.answer_stability]';
    grVec     = [rows.groundedness]';
    negVec    = [rows.negative_hallucination_risk]';
    debtVec   = [rows.interpretive_debt]';
    structVec = [rows.structure_score]';
    matVec    = [rows.maturity_score]';

    coreSmooth   = lc_moving_average(coreVec, 3);
    ansSmooth    = lc_moving_average(ansVec, 3);
    grSmooth     = lc_moving_average(grVec, 3);
    negSmooth    = lc_moving_average(negVec, 3);
    debtSmooth   = lc_moving_average(debtVec, 3);
    structSmooth = lc_moving_average(structVec, 3);
    matSmooth    = lc_moving_average(matVec, 3);

    thr = lc_compute_adaptive_thresholds(coreSmooth, ansSmooth, grSmooth, ...
        negSmooth, debtSmooth, structSmooth, matSmooth);

    cognitiveMask = ...
        coreSmooth   >= thr.core_stability & ...
        ansSmooth    >= thr.answer_stability & ...
        grSmooth     >= thr.groundedness;

    llmReadyMask = ...
        matSmooth    >= thr.maturity & ...
        grSmooth     >= thr.groundedness & ...
        negSmooth    <= thr.neg_risk & ...
        debtSmooth   <= thr.interpretive_debt;

    Xz = lc_zscoreSafe(double(X));
    coords3 = lc_reduceTo3D_safe(Xz);
    dSteps = vecnorm(diff(coords3, 1, 1), 2, 2);
    if isempty(dSteps)
        lociOnset = 1;
    else
        lociOnset = lc_detectOnset(dSteps);
    end

    firstStableGeneration = lc_find_first_window(cognitiveMask, 3);
    firstLLMReadyGeneration = lc_find_first_window(llmReadyMask, 3);

    candidateCognitiveStable = lc_find_candidate_generation( ...
        lociOnset, coreSmooth, ansSmooth, grSmooth, negSmooth, debtSmooth, structSmooth, matSmooth, ...
        'cognitive');

    candidateLLMReady = lc_find_candidate_generation( ...
        lociOnset, coreSmooth, ansSmooth, grSmooth, negSmooth, debtSmooth, structSmooth, matSmooth, ...
        'llm');

    if isnan(firstStableGeneration) && ~isnan(candidateCognitiveStable)
        approxStable = candidateCognitiveStable;
    else
        approxStable = firstStableGeneration;
    end

    if isnan(firstLLMReadyGeneration) && ~isnan(candidateLLMReady)
        approxLLMReady = candidateLLMReady;
    else
        approxLLMReady = firstLLMReadyGeneration;
    end

    if isnan(approxStable)
        transitionWindow = '';
    elseif isnan(approxLLMReady)
        transitionWindow = sprintf('G%04d -> unresolved', approxStable);
    else
        transitionWindow = sprintf('G%04d -> G%04d', approxStable, approxLLMReady);
    end

    readinessStatus = lc_readiness_status(firstStableGeneration, firstLLMReadyGeneration, ...
        candidateCognitiveStable, candidateLLMReady, matSmooth);

    hFig = figure( ...
        'Color', 'w', ...
        'Name', 'LOCI Cognitive Readiness Test', ...
        'NumberTitle', 'off', ...
        'Position', [60 60 1500 900]);

    try
        set(hFig, 'Toolbar', 'none');
    catch
    end

    gen = (1:n)';

    subplot(2,2,1);
    hold on; grid on; box on;
    h1 = plot(gen, coreVec, '-o', 'LineWidth', 1.2);
    h2 = plot(gen, ansVec, '-s', 'LineWidth', 1.2);
    h3 = plot(gen, grVec, '-d', 'LineWidth', 1.2);
    ylim([0 1]);
    xlabel('Generacja');
    ylabel('Score');
    title('Stability / Groundedness');
    legend([h1 h2 h3], {'Core stability','Answer stability','Groundedness'}, 'Location', 'best');

    subplot(2,2,2);
    hold on; grid on; box on;
    h4 = plot(gen, negVec, '-o', 'LineWidth', 1.2);
    h5 = plot(gen, debtVec, '-s', 'LineWidth', 1.2);
    h6 = plot(gen, structVec, '-d', 'LineWidth', 1.2);
    ylim([0 1]);
    xlabel('Generacja');
    ylabel('Risk / Debt / Structure');
    title('Risk / Debt / Structure');
    legend([h4 h5 h6], {'Negative hallucination risk','Interpretive debt','Structure score'}, 'Location', 'best');

    subplot(2,2,3);
    hold on; grid on; box on;
    lh = [];
    ln = {};

    h7 = plot(gen, matVec, '-o', 'LineWidth', 1.2);
    lh(end+1) = h7; ln{end+1} = 'Maturity raw';

    h8 = plot(gen, matSmooth, '--', 'LineWidth', 1.8);
    lh(end+1) = h8; ln{end+1} = 'Maturity smooth';

    h9 = xline(lociOnset, '--r', 'LineWidth', 1.2);
    lh(end+1) = h9; ln{end+1} = 'LOCI onset';

    if ~isnan(firstStableGeneration)
        h10 = xline(firstStableGeneration, '--g', 'LineWidth', 1.2);
        lh(end+1) = h10; ln{end+1} = 'Cognitive stable';
    elseif ~isnan(candidateCognitiveStable)
        h10 = xline(candidateCognitiveStable, ':g', 'LineWidth', 1.5);
        lh(end+1) = h10; ln{end+1} = 'Cognitive stable (candidate)';
    end

    if ~isnan(firstLLMReadyGeneration)
        h11 = xline(firstLLMReadyGeneration, '--k', 'LineWidth', 1.2);
        lh(end+1) = h11; ln{end+1} = 'LLM-ready';
    elseif ~isnan(candidateLLMReady)
        h11 = xline(candidateLLMReady, ':k', 'LineWidth', 1.5);
        lh(end+1) = h11; ln{end+1} = 'LLM-ready (candidate)';
    end

    ylim([0 1]);
    xlabel('Generacja');
    ylabel('Maturity');
    title('Cognitive maturity');
    legend(lh, ln, 'Location', 'best');

    subplot(2,2,4);
    hold on; grid on; box on;
    charLens = [rows.char_len]';
    wordCounts = [rows.word_count]';
    yyaxis left;
    plot(gen, charLens, '-o', 'LineWidth', 1.2);
    ylabel('Char length');
    yyaxis right;
    plot(gen, wordCounts, '-s', 'LineWidth', 1.2);
    ylabel('Word count');
    xlabel('Generacja');
    title('Artifact growth');

    sgtitle(sprintf('LCRT :: %s :: %s', sampleId, readinessStatus), 'FontWeight', 'bold');

    drawnow;

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

    out = struct();
    out.sample_id = sampleId;
    out.input_file = sampleFile;
    out.result_dir = resultDir;
    out.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    out.generations = n;
    out.feature_count = size(X, 2);
    out.feature_names = featureNames;
    out.loci_onset_generation = lociOnset;
    out.first_cognitive_stable_generation = firstStableGeneration;
    out.first_llm_ready_generation = firstLLMReadyGeneration;
    out.candidate_cognitive_stable_generation = candidateCognitiveStable;
    out.candidate_llm_ready_generation = candidateLLMReady;
    out.approx_cognitive_stable_generation = approxStable;
    out.approx_llm_ready_generation = approxLLMReady;
    out.transition_window = transitionWindow;
    out.readiness_status = readinessStatus;
    out.cognitive_ready_level = lc_resolution_level(out.first_cognitive_stable_generation, out.candidate_cognitive_stable_generation);
    out.llm_ready_level = lc_resolution_level( out.first_llm_ready_generation, out.candidate_llm_ready_generation);    
    out.thresholds = thr;
    out.mean_core_stability = mean(coreVec, 'omitnan');
    out.mean_answer_stability = mean(ansVec, 'omitnan');
    out.mean_groundedness = mean(grVec, 'omitnan');
    out.mean_negative_hallucination_risk = mean(negVec, 'omitnan');
    out.mean_interpretive_debt = mean(debtVec, 'omitnan');
    out.mean_structure_score = mean(structVec, 'omitnan');
    out.mean_maturity_score = mean(matVec, 'omitnan');
    out.max_maturity_score = max(matVec, [], 'omitnan');
    out.rows = rows;
    out.saved_files = struct( ...
        'png', figPng, ...
        'fig', figFig, ...
        'txt', txtOut, ...
        'json', jsonOut, ...
        'md', mdOut);

    lc_writeTxtSummary(txtOut, out);
    lc_writeJsonSummary(jsonOut, out);
    lc_writeMarkdownSummary(mdOut, out);

    fprintf('Generations                   : %d\n', n);
    fprintf('LOCI onset                    : G%04d\n', lociOnset);

    if isnan(firstStableGeneration)
        fprintf('First cognitive stable        : unresolved\n');
    else
        fprintf('First cognitive stable        : G%04d\n', firstStableGeneration);
    end

    if isnan(firstLLMReadyGeneration)
        fprintf('First LLM-ready               : unresolved\n');
    else
        fprintf('First LLM-ready               : G%04d\n', firstLLMReadyGeneration);
    end

    if ~isnan(candidateCognitiveStable)
        fprintf('Candidate cognitive stable    : G%04d\n', candidateCognitiveStable);
    end
    if ~isnan(candidateLLMReady)
        fprintf('Candidate LLM-ready           : G%04d\n', candidateLLMReady);
    end

    fprintf('Readiness status              : %s\n', readinessStatus);
    fprintf('Mean groundedness             : %.4f\n', out.mean_groundedness);
    fprintf('Mean hallucination risk proxy : %.4f\n', out.mean_negative_hallucination_risk);
    fprintf('Mean interpretive debt        : %.4f\n', out.mean_interpretive_debt);
    fprintf('Mean maturity score           : %.4f\n', out.mean_maturity_score);
    fprintf('Max maturity score            : %.4f\n', out.max_maturity_score);
    fprintf('\nSaved to:\n');
    fprintf('  PNG : %s\n', figPng);
    fprintf('  FIG : %s\n', figFig);
    fprintf('  TXT : %s\n', txtOut);
    fprintf('  JSON: %s\n', jsonOut);
    fprintf('  MD  : %s\n', mdOut);
end

function row = lc_empty_row()
    row = struct( ...
        'generation', NaN, ...
        'char_len', NaN, ...
        'word_count', NaN, ...
        'core_stability', NaN, ...
        'answer_stability', NaN, ...
        'groundedness', NaN, ...
        'negative_hallucination_risk', NaN, ...
        'interpretive_debt', NaN, ...
        'structure_score', NaN, ...
        'maturity_score', NaN, ...
        'keywords', {{}}, ...
        'snapshot_title', '' ...
    );
end

function p = lc_answer_profile(textLower, words, keywords)
    p = struct();
    p.main_topic = strjoin(keywords(1:min(numel(keywords), 5)), '|');
    p.has_goal = double(lc_contains_any(textLower, {'cel','chce','zamierz','model','metoda','analiza','badawcz','opracow'}));
    p.mode_code = lc_mode_code(textLower);
    p.has_definition = double(lc_contains_any(textLower, {'to jest','oznacza','mozna opisac','model','metoda','jest figura','jest interfejsem'}));
    p.meta_boundary = double(lc_contains_any(textLower, {'to nie jest','nie traktuje','nie oznacza','nie mylic','nie myl','nie jest maska'}));

    specMarkers = lc_contains_count(textLower, {'moze','chyba','jakby','wydaje','zobaczymy','wrazenie'});
    p.speculation_band = lc_bucket_3(specMarkers);

    structMarkers = lc_contains_count(textLower, {'analiza','model','metoda','struktura','proces','badaw','korpus','dane'});
    p.research_band = lc_bucket_3(structMarkers);

    p.length_band = lc_bucket_4(numel(words));
    p.epistemic_brakes = double(lc_contains_any(textLower, {'poczekamy','dowody','nie wiadomo','nie rozstrzyga','to nie znaczy','nie musi','nie traktuje','nie jest'}));
    p.formalization = double(lc_contains_any(textLower, {'formaln','metryk','model','struktura poznawcza','llm','halucynac','bled','ryzyko','interfejs','proces poznawczy'}));
end

function groundedness = lc_groundedness_proxy(textLower, words)
    evidenceTerms = {'to jest','oznacza','model','metoda','analiza','struktura','proces','korpus','dane','badawczy','definic','formaln','w tym sensie','z perspektywy','mozna opisac','wynika','interfejs','warstwa','rdzen','poznawcz'};
    evidenceCount = lc_contains_count(textLower, evidenceTerms);
    sentenceCount = max(1, lc_sentence_count(textLower));
    wordCount = max(1, numel(words));
    raw = 0.65 * (evidenceCount / max(sentenceCount, 1)) + 0.35 * min(wordCount / 120, 1);
    groundedness = lc_clip01(raw / 2.0);
end

function ambiguity = lc_ambiguity_proxy(textLower, words)
    ambiguityTerms = {'...','?','moze','chyba','jakby','zobaczymy','wydaje','mam wrazenie','dla mnie','moim zdaniem'};
    a = lc_contains_count(textLower, ambiguityTerms);
    s = max(1, lc_sentence_count(textLower));
    w = max(1, numel(words));
    raw = 0.75 * (a / max(s, 1)) + 0.25 * min(w / 300, 1);
    ambiguity = lc_clip01(raw / 2.5);
end

function risk = lc_negative_hallucination_proxy(textLower, words, negativeProbeTerms)
    unsupportedCount = lc_contains_count(textLower, negativeProbeTerms);
    formalCount = lc_contains_count(textLower, {'model','metoda','analiza','struktura','dane','korpus','formaln','dowody','interfejs','poznawcz','ryzyko'});
    ambiguityCount = lc_contains_count(textLower, {'moze','chyba','jakby','zobaczymy','...'});
    wordCount = max(1, numel(words));

    raw = 0.20 + ...
        0.20 * min(ambiguityCount / 6, 1) + ...
        0.20 * min(wordCount / 400, 1) + ...
        0.25 * min(unsupportedCount / 3, 1) - ...
        0.25 * min(formalCount / 10, 1);

    risk = lc_clip01(raw);
end

function debt = lc_interpretive_debt(ambiguity, groundedness)
    debt = lc_clip01(0.60 * ambiguity + 0.40 * (1 - groundedness));
end

function score = lc_structure_score(textLower, words)
    structureTerms = {'model','metoda','struktura','proces','analiza','warstwa','rdzen','korpus','heurystyk','metacode','llm','loci','poznawcz','interfejs','formaln','ryzyko','generacji','stabilizacji','ontologii emocji'};
    countStruct = lc_contains_count(textLower, structureTerms);
    sentenceCount = max(1, lc_sentence_count(textLower));
    wordCount = max(1, numel(words));
    raw = 0.70 * (countStruct / max(sentenceCount, 1)) + 0.30 * min(wordCount / 160, 1);
    score = lc_clip01(raw / 2.5);
end

function score = lc_maturity_score(coreStability, answerStability, groundedness, structureScore, negRisk, interpDebt)
    score = 0.22 * coreStability + 0.20 * answerStability + 0.22 * groundedness + 0.20 * structureScore + 0.16 * (1 - negRisk) - 0.08 * interpDebt;
    score = lc_clip01(score);
end

function thr = lc_compute_adaptive_thresholds(coreSmooth, ansSmooth, grSmooth, negSmooth, debtSmooth, structSmooth, matSmooth)
    thr = struct();
    thr.core_stability    = max(0.30, min(0.65, lc_q75(coreSmooth)  * 0.90));
    thr.answer_stability  = max(0.30, min(0.65, lc_q75(ansSmooth)   * 0.90));
    thr.groundedness      = max(0.22, min(0.55, lc_q60(grSmooth)));
    thr.neg_risk          = max(0.35, min(0.75, lc_q40(negSmooth)));
    thr.interpretive_debt = max(0.35, min(0.70, lc_q50(debtSmooth)));
    thr.structure_score   = max(0.20, min(0.60, lc_q60(structSmooth)));
    thr.maturity          = max(0.35, min(0.75, lc_q70(matSmooth)));
end

function idx = lc_find_candidate_generation(lociOnset, coreSmooth, ansSmooth, grSmooth, negSmooth, debtSmooth, structSmooth, matSmooth, mode)
    idx = NaN;
    n = numel(matSmooth);
    if n == 0
        return;
    end

    startIdx = max(1, lociOnset);

    score = zeros(n,1);
    for i = startIdx:n
        if strcmp(mode, 'cognitive')
            score(i) = ...
                0.30 * coreSmooth(i) + ...
                0.25 * ansSmooth(i) + ...
                0.20 * grSmooth(i) + ...
                0.15 * structSmooth(i) + ...
                0.10 * (1 - debtSmooth(i));
        else
            score(i) = ...
                0.30 * matSmooth(i) + ...
                0.20 * grSmooth(i) + ...
                0.15 * structSmooth(i) + ...
                0.20 * (1 - negSmooth(i)) + ...
                0.15 * (1 - debtSmooth(i));
        end
    end

    [bestScore, bestIdx] = max(score(startIdx:end));
    if isempty(bestScore) || ~isfinite(bestScore)
        return;
    end

    bestIdx = bestIdx + startIdx - 1;

    if strcmp(mode, 'cognitive')
        if bestScore >= 0.40
            idx = bestIdx;
        end
    else
        if bestScore >= 0.45
            idx = bestIdx;
        end
    end
end

function status = lc_readiness_status(firstStableGeneration, firstLLMReadyGeneration, candidateStable, candidateReady, matSmooth)
    maxMat = max(matSmooth, [], 'omitnan');

    if ~isnan(firstLLMReadyGeneration)
        status = 'LLM_READY';
    elseif ~isnan(firstStableGeneration)
        status = 'COGNITIVELY_STABLE';
    elseif ~isnan(candidateReady)
        status = 'LLM_READY_CANDIDATE';
    elseif ~isnan(candidateStable)
        status = 'COGNITIVE_CANDIDATE';
    elseif maxMat >= 0.45
        status = 'TRANSITIONAL';
    else
        status = 'PRE_STABLE';
    end
end

function text = lc_get_record_text(rec)
    text = '';
    if isfield(rec, 'content_norm') && ~isempty(rec.content_norm)
        text = rec.content_norm;
    elseif isfield(rec, 'content_display') && ~isempty(rec.content_display)
        text = rec.content_display;
    end
    if isstring(text)
        text = char(text);
    end
    if ~ischar(text)
        text = '';
    end
end

function words = lc_tokenize(textLower)
    words = regexp(textLower, '[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ0-9_-]+', 'match');
    if isempty(words)
        words = {};
    end
end

function keywords = lc_top_keywords(words, stopwords, k)
    if isempty(words)
        keywords = {};
        return;
    end
    words = words(:);
    keep = true(size(words));
    for i = 1:numel(words)
        w = words{i};
        if numel(w) < 3 || any(strcmp(w, stopwords))
            keep(i) = false;
        end
    end
    words = words(keep);
    if isempty(words)
        keywords = {};
        return;
    end
    [u, ~, idx] = unique(words);
    freq = accumarray(idx, 1);
    [~, ord] = sort(freq, 'descend');
    u = u(ord);
    keywords = u(1:min(k, numel(u)))';
end

function tf = lc_contains_any(textLower, patterns)
    tf = false;
    for i = 1:numel(patterns)
        if ~isempty(strfind(textLower, patterns{i})) %#ok<STREMP>
            tf = true;
            return;
        end
    end
end

function c = lc_contains_count(textLower, patterns)
    c = 0;
    for i = 1:numel(patterns)
        c = c + numel(strfind(textLower, patterns{i})); %#ok<STREMP>
    end
end

function n = lc_sentence_count(textLower)
    if isempty(textLower)
        n = 0;
        return;
    end
    n = sum(textLower == '.') + sum(textLower == '!') + sum(textLower == '?');
    n = max(n, 1);
end

function c = lc_mode_code(textLower)
    hasResearch = lc_contains_any(textLower, {'analiza','model','metoda','badaw','korpus','dane'});
    hasPerform  = lc_contains_any(textLower, {'teatr','scena','postac','rola','maska','perform'});
    hasReflect  = lc_contains_any(textLower, {'mam poczucie','widze','dla mnie','moim zdaniem','wrazenie'});
    c = hasResearch + 2 * hasPerform + 4 * hasReflect;
end

function b = lc_bucket_3(v)
    if v <= 0
        b = 0;
    elseif v == 1
        b = 0.5;
    else
        b = 1.0;
    end
end

function b = lc_bucket_4(v)
    if v < 50
        b = 0.25;
    elseif v < 150
        b = 0.50;
    elseif v < 300
        b = 0.75;
    else
        b = 1.0;
    end
end

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
        else
            s = lc_valueToChar(v{1});
        end
        return;
    end

    s = '';
end

function v = lc_clip01(v)
    v = max(0, min(1, v));
end

function j = lc_jaccard(a, b)
    if isempty(a) && isempty(b)
        j = 1;
        return;
    end
    a = unique(a);
    b = unique(b);
    inter = numel(intersect(a, b));
    uni = numel(union(a, b));
    if uni == 0
        j = 0;
    else
        j = inter / uni;
    end
end

function s = lc_answer_stability(prev, curr)
    if isempty(fieldnames(prev)) || isempty(fieldnames(curr))
        s = 0;
        return;
    end
    names = fieldnames(curr);
    scores = zeros(numel(names), 1);
    for i = 1:numel(names)
        f = names{i};
        if ~isfield(prev, f)
            scores(i) = 0;
            continue;
        end
        a = prev.(f);
        b = curr.(f);
        if ischar(a) && ischar(b)
            ta = regexp(a, '[^|]+', 'match');
            tb = regexp(b, '[^|]+', 'match');
            scores(i) = lc_jaccard(ta, tb);
        elseif isnumeric(a) && isnumeric(b)
            scores(i) = 1 - min(abs(double(a) - double(b)), 1);
        else
            scores(i) = 0;
        end
    end
    s = mean(scores, 'omitnan');
    s = lc_clip01(s);
end

function y = lc_moving_average(x, w)
    if nargin < 2
        w = 3;
    end
    y = zeros(size(x));
    for i = 1:numel(x)
        a = max(1, i-w+1);
        b = i;
        y(i) = mean(x(a:b), 'omitnan');
    end
end

function idx = lc_find_first_window(mask, win)
    if nargin < 2
        win = 3;
    end
    idx = NaN;
    if isempty(mask)
        return;
    end
    for i = win:numel(mask)
        if all(mask(i-win+1:i))
            idx = i;
            return;
        end
    end
end

function q = lc_q40(x), q = lc_quantile_basic(x, 0.40); end
function q = lc_q50(x), q = lc_quantile_basic(x, 0.50); end
function q = lc_q60(x), q = lc_quantile_basic(x, 0.60); end
function q = lc_q70(x), q = lc_quantile_basic(x, 0.70); end
function q = lc_q75(x), q = lc_quantile_basic(x, 0.75); end

function q = lc_quantile_basic(x, p)
    x = x(isfinite(x));
    if isempty(x)
        q = NaN;
        return;
    end
    x = sort(x(:));
    idx = max(1, min(numel(x), round(1 + (numel(x)-1)*p)));
    q = x(idx);
end

function Xz = lc_zscoreSafe(X)
    mu = mean(X, 1, 'omitnan');
    sigma = std(X, 0, 1, 'omitnan');
    sigma(sigma == 0 | isnan(sigma)) = 1;
    Xz = (X - mu) ./ sigma;
    Xz(~isfinite(Xz)) = 0;
end

function coords3 = lc_reduceTo3D_safe(X)
    [n, d] = size(X);
    coords3 = zeros(n, 3);
    if d >= 3
        try
            [~, score] = pca(X, 'Rows', 'complete');
            if size(score,2) >= 3
                coords3 = score(:,1:3);
                return;
            end
        catch
        end
    end
    coords3(:,1:min(d,3)) = X(:,1:min(d,3));
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

function lc_writeTxtSummary(pathOut, out)
    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write TXT summary: %s', pathOut);
        return;
    end

    fprintf(fid, '=========================================\n');
    fprintf(fid, 'LOCI COGNITIVE READINESS TEST\n');
    fprintf(fid, '=========================================\n\n');

    fprintf(fid, 'sample_id                         : %s\n', out.sample_id);
    fprintf(fid, 'timestamp                         : %s\n', out.timestamp);
    fprintf(fid, 'input_file                        : %s\n', out.input_file);
    fprintf(fid, 'result_dir                        : %s\n', out.result_dir);
    fprintf(fid, 'generations                       : %d\n', out.generations);
    fprintf(fid, 'feature_count                     : %d\n', out.feature_count);
    fprintf(fid, 'loci_onset_generation             : G%04d\n', out.loci_onset_generation);

    if isnan(out.first_cognitive_stable_generation)
        fprintf(fid, 'first_cognitive_stable_generation : unresolved\n');
    else
        fprintf(fid, 'first_cognitive_stable_generation : G%04d\n', out.first_cognitive_stable_generation);
    end

    if isnan(out.first_llm_ready_generation)
        fprintf(fid, 'first_llm_ready_generation        : unresolved\n');
    else
        fprintf(fid, 'first_llm_ready_generation        : G%04d\n', out.first_llm_ready_generation);
    end

    if isnan(out.candidate_cognitive_stable_generation)
        fprintf(fid, 'candidate_cognitive_stable_generation : unresolved\n');
    else
        fprintf(fid, 'candidate_cognitive_stable_generation : G%04d\n', out.candidate_cognitive_stable_generation);
    end

    if isnan(out.candidate_llm_ready_generation)
        fprintf(fid, 'candidate_llm_ready_generation    : unresolved\n');
    else
        fprintf(fid, 'candidate_llm_ready_generation    : G%04d\n', out.candidate_llm_ready_generation);
    end

    fprintf(fid, 'transition_window                 : %s\n', out.transition_window);
    fprintf(fid, 'readiness_status                  : %s\n', out.readiness_status);

    fprintf(fid, '\n=== THRESHOLDS ===\n');
    fprintf(fid, 'core_stability     : %.6f\n', out.thresholds.core_stability);
    fprintf(fid, 'answer_stability   : %.6f\n', out.thresholds.answer_stability);
    fprintf(fid, 'groundedness       : %.6f\n', out.thresholds.groundedness);
    fprintf(fid, 'neg_risk           : %.6f\n', out.thresholds.neg_risk);
    fprintf(fid, 'interpretive_debt  : %.6f\n', out.thresholds.interpretive_debt);
    fprintf(fid, 'structure_score    : %.6f\n', out.thresholds.structure_score);
    fprintf(fid, 'maturity           : %.6f\n', out.thresholds.maturity);

    fprintf(fid, '\n=== GLOBAL MEANS ===\n');
    fprintf(fid, 'mean_core_stability              : %.6f\n', out.mean_core_stability);
    fprintf(fid, 'mean_answer_stability            : %.6f\n', out.mean_answer_stability);
    fprintf(fid, 'mean_groundedness                : %.6f\n', out.mean_groundedness);
    fprintf(fid, 'mean_negative_hallucination_risk : %.6f\n', out.mean_negative_hallucination_risk);
    fprintf(fid, 'mean_interpretive_debt           : %.6f\n', out.mean_interpretive_debt);
    fprintf(fid, 'mean_structure_score             : %.6f\n', out.mean_structure_score);
    fprintf(fid, 'mean_maturity_score              : %.6f\n', out.mean_maturity_score);
    fprintf(fid, 'max_maturity_score               : %.6f\n', out.max_maturity_score);

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

    fprintf(fid, '# %s - LOCI Cognitive Readiness Test\n\n', out.sample_id);
    fprintf(fid, '- **Timestamp:** %s\n', out.timestamp);
    fprintf(fid, '- **Input file:** `%s`\n', out.input_file);
    fprintf(fid, '- **Generations:** `%d`\n', out.generations);
    fprintf(fid, '- **Feature count:** `%d`\n', out.feature_count);
    fprintf(fid, '- **LOCI onset:** `G%04d`\n', out.loci_onset_generation);

    if isnan(out.first_cognitive_stable_generation)
        fprintf(fid, '- **First cognitive stable:** `unresolved`\n');
    else
        fprintf(fid, '- **First cognitive stable:** `G%04d`\n', out.first_cognitive_stable_generation);
    end

    if isnan(out.first_llm_ready_generation)
        fprintf(fid, '- **First LLM-ready:** `unresolved`\n');
    else
        fprintf(fid, '- **First LLM-ready:** `G%04d`\n', out.first_llm_ready_generation);
    end

    if isnan(out.candidate_cognitive_stable_generation)
        fprintf(fid, '- **Candidate cognitive stable:** `unresolved`\n');
    else
        fprintf(fid, '- **Candidate cognitive stable:** `G%04d`\n', out.candidate_cognitive_stable_generation);
    end

    if isnan(out.candidate_llm_ready_generation)
        fprintf(fid, '- **Candidate LLM-ready:** `unresolved`\n');
    else
        fprintf(fid, '- **Candidate LLM-ready:** `G%04d`\n', out.candidate_llm_ready_generation);
    end

    fprintf(fid, '- **Transition window:** `%s`\n', out.transition_window);
    fprintf(fid, '- **Readiness status:** `%s`\n', out.readiness_status);
    fprintf(fid, '- **Cognitive ready level:** `%s`\n', out.cognitive_ready_level);
    fprintf(fid, '- **LLM ready level:** `%s`\n', out.llm_ready_level);
    fprintf('Cognitive ready level         : %s\n', out.cognitive_ready_level);
    fprintf('LLM ready level               : %s\n', out.llm_ready_level);
    fprintf(fid, '- **Mean groundedness:** `%.6f`\n', out.mean_groundedness);
    fprintf(fid, '- **Mean hallucination risk proxy:** `%.6f`\n', out.mean_negative_hallucination_risk);
    fprintf(fid, '- **Mean interpretive debt:** `%.6f`\n', out.mean_interpretive_debt);
    fprintf(fid, '- **Mean maturity score:** `%.6f`\n', out.mean_maturity_score);
    fprintf(fid, '- **Max maturity score:** `%.6f`\n\n', out.max_maturity_score);

    fprintf(fid, '## Figure\n\n');
    fprintf(fid, '![%s](./%s%s)\n\n', out.sample_id, pngName, pngExt);

    fclose(fid);
end

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

    matFiles = dir(fullfile(lociRoot, 'sample', 'Sample_*', 'norm', 'sample_norm.mat'));
    if ~isempty(matFiles)
        sampleFile = fullfile(matFiles(1).folder, matFiles(1).name);
        return;
    end

    jsonFiles = dir(fullfile(lociRoot, 'sample', 'Sample_*', 'norm', 'sample_norm.json'));
    if ~isempty(jsonFiles)
        sampleFile = fullfile(jsonFiles(1).folder, jsonFiles(1).name);
        return;
    end

    error('run_loci_cognitive_readiness_test:AutoDetectFailed', ...
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
    p = { ...
        fullfile(lociRoot, 'matlab', 'adapters'), ...
        fullfile(lociRoot, 'matlab', 'features'), ...
        fullfile(lociRoot, 'matlab', 'visualizers'), ...
        fullfile(lociRoot, 'matlab', 'compat') ...
    };
    for i = 1:numel(p)
        if isfolder(p{i})
            addpath(p{i});
        end
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

function sw = lc_stopwords_pl_en()
    sw = { ...
        'i','oraz','ale','albo','czy','a','o','u','w','z','ze','za','na','do','od', ...
        'to','ten','ta','te','tych','tym','taki','taka','takie','tak','nie','jest', ...
        'sa','byc','bylo','byla','byly','go','jej','ich','jego','moja','moj','moje', ...
        'dla','sie','się','juz','już','jak','jako','po','pod','nad','przez','przy', ...
        'mam','ma','mial','miała','miec','mieć','który','ktora','ktore','które', ...
        'that','this','with','from','into','about','over','under','the','and','for', ...
        'are','was','were','will','shall','have','has','had','not','but','you','your', ...
        'our','their','them','they','its','his','her','also','than','then','there', ...
        'just','very','more','most','less','much' ...
    };
end

function s = lc_safe_trim(text, n)
    if nargin < 2
        n = 120;
    end

    if isempty(text)
        s = '';
        return;
    end

    if isstring(text)
        text = char(text);
    end

    if ~ischar(text)
        s = '';
        return;
    end

    text = strrep(text, sprintf('\n'), ' ');
    text = strrep(text, sprintf('\r'), ' ');

    if length(text) <= n
        s = text;
    else
        s = [text(1:n) '...'];
    end
end

function level = lc_resolution_level(firstIdx, candidateIdx)
    if ~isnan(firstIdx)
        level = 'confirmed';
    elseif ~isnan(candidateIdx)
        level = 'candidate';
    else
        level = 'none';
    end
end