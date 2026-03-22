function out = run_loci_cognitive_readiness_test(sampleFile)
% RUN_LOCI_COGNITIVE_READINESS_TEST
% LOCI Cognitive Readiness Test (LCRT)
%
% Cel:
%   Oszacować, od której generacji artefakt staje się poznawczo stabilny
%   oraz bardziej "właściwy" dla pracy z LLM, tzn. ogranicza ryzyko
%   nadinterpretacji, błędów i halucynacji.
%
% Pipeline:
%   sample_norm.(json|mat)
%      -> load_sample_norm
%      -> sample_norm_to_series
%      -> build_loci_feature_matrix
%      -> LCRT metrics / plots / reports
%
% OUTPUT:
%   out - struct z wynikami testu
%
% Zapis:
%   results/<Sample_ID>/<Sample_ID>_lcrt_<timestamp>.{png,fig,txt,json,md}
%
% Uwaga:
%   To jest test proxy dla gotowości poznawczej artefaktu.
%   Nie uruchamia zewnętrznego LLM. Mierzy dojrzałość struktury tekstu.

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
        groundedness = lc_groundedness_proxy(textLower);
        ambiguity = lc_ambiguity_proxy(textLower);
        negRisk = lc_negative_hallucination_proxy(textLower, negativeProbeTerms);
        interpDebt = lc_interpretive_debt(ambiguity, groundedness);
        structureScore = lc_structure_score(textLower);

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

    % --- smoothing / readiness detection
    coreVec   = [rows.core_stability]';
    ansVec    = [rows.answer_stability]';
    grVec     = [rows.groundedness]';
    negVec    = [rows.negative_hallucination_risk]';
    debtVec   = [rows.interpretive_debt]';
    matVec    = [rows.maturity_score]';

    matSmooth = lc_moving_average(matVec, 3);
    grSmooth  = lc_moving_average(grVec, 3);
    negSmooth = lc_moving_average(negVec, 3);
    debtSmooth = lc_moving_average(debtVec, 3);
    coreSmooth = lc_moving_average(coreVec, 3);
    ansSmooth = lc_moving_average(ansVec, 3);

    firstStableGeneration = lc_find_first_window( ...
        coreSmooth >= 0.45 & ...
        ansSmooth >= 0.45 & ...
        grSmooth >= 0.45);

    firstLLMReadyGeneration = lc_find_first_window( ...
        matSmooth >= 0.55 & ...
        grSmooth >= 0.45 & ...
        negSmooth <= 0.45 & ...
        debtSmooth <= 0.55);

    if isnan(firstStableGeneration)
        transitionWindow = '';
    elseif isnan(firstLLMReadyGeneration)
        transitionWindow = sprintf('G%04d -> unresolved', firstStableGeneration);
    else
        transitionWindow = sprintf('G%04d -> G%04d', ...
            firstStableGeneration, firstLLMReadyGeneration);
    end

    % --- optional LOCI signal from existing 27D matrix
    Xz = lc_zscoreSafe(double(X));
    coords3 = lc_reduceTo3D_safe(Xz);
    dSteps = vecnorm(diff(coords3, 1, 1), 2, 2);
    if isempty(dSteps)
        lociOnset = 1;
    else
        lociOnset = lc_detectOnset(dSteps);
    end

    % ---------------------------------------------------------------------
    % FIGURE
    % ---------------------------------------------------------------------
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
    plot(gen, coreVec, '-o', 'LineWidth', 1.2);
    plot(gen, ansVec, '-s', 'LineWidth', 1.2);
    plot(gen, grVec, '-d', 'LineWidth', 1.2);
    ylim([0 1]);
    xlabel('Generacja');
    ylabel('Score');
    title('Stability / Groundedness');
    legend({'Core stability','Answer stability','Groundedness'}, 'Location', 'best');

    subplot(2,2,2);
    hold on; grid on; box on;
    plot(gen, negVec, '-o', 'LineWidth', 1.2);
    plot(gen, debtVec, '-s', 'LineWidth', 1.2);
    ylim([0 1]);
    xlabel('Generacja');
    ylabel('Risk / Debt');
    title('Risk / Interpretive debt');
    legend({'Negative hallucination risk','Interpretive debt'}, 'Location', 'best');

    subplot(2,2,3);
    hold on; grid on; box on;
    plot(gen, matVec, '-o', 'LineWidth', 1.2);
    plot(gen, matSmooth, '--', 'LineWidth', 1.8);
    xline(lociOnset, '--r', 'LineWidth', 1.2);

    if ~isnan(firstStableGeneration)
        xline(firstStableGeneration, '--g', 'LineWidth', 1.2);
    end
    if ~isnan(firstLLMReadyGeneration)
        xline(firstLLMReadyGeneration, '--k', 'LineWidth', 1.2);
    end

    ylim([0 1]);
    xlabel('Generacja');
    ylabel('Maturity');
    title('Cognitive maturity');
    legend({'Maturity raw','Maturity smooth','LOCI onset','Cognitive stable','LLM-ready'}, ...
        'Location', 'best');

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

    sgtitle(sprintf('LCRT :: %s', sampleId), 'FontWeight', 'bold');

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

    % ---------------------------------------------------------------------
    % OUTPUT
    % ---------------------------------------------------------------------
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
    out.transition_window = transitionWindow;
    out.mean_core_stability = mean(coreVec, 'omitnan');
    out.mean_answer_stability = mean(ansVec, 'omitnan');
    out.mean_groundedness = mean(grVec, 'omitnan');
    out.mean_negative_hallucination_risk = mean(negVec, 'omitnan');
    out.mean_interpretive_debt = mean(debtVec, 'omitnan');
    out.mean_structure_score = mean([rows.structure_score], 'omitnan');
    out.mean_maturity_score = mean(matVec, 'omitnan');
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

    fprintf('Mean groundedness             : %.4f\n', out.mean_groundedness);
    fprintf('Mean hallucination risk proxy : %.4f\n', out.mean_negative_hallucination_risk);
    fprintf('Mean interpretive debt        : %.4f\n', out.mean_interpretive_debt);
    fprintf('Mean maturity score           : %.4f\n', out.mean_maturity_score);
    fprintf('\nSaved to:\n');
    fprintf('  PNG : %s\n', figPng);
    fprintf('  FIG : %s\n', figFig);
    fprintf('  TXT : %s\n', txtOut);
    fprintf('  JSON: %s\n', jsonOut);
    fprintf('  MD  : %s\n', mdOut);
end

% =========================================================================
% DATA ROW
% =========================================================================

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

% =========================================================================
% SCORING
% =========================================================================

function p = lc_answer_profile(textLower, words, keywords)
    p = struct();

    % Q1: główny temat
    p.main_topic = strjoin(keywords(1:min(numel(keywords), 5)), '|');

    % Q2: cel autora
    p.has_goal = double(lc_contains_any(textLower, { ...
        'cel', 'chce', 'zamierz', 'model', 'metoda', 'analiza', 'badawcz', 'opracow' ...
    }));

    % Q3: charakter artefaktu
    p.mode_code = lc_mode_code(textLower);

    % Q4: czy ma tezę / definicję
    p.has_definition = double(lc_contains_any(textLower, { ...
        'to jest', 'oznacza', 'mozna opisac', 'model', 'metoda', 'jest figura', 'jest interfejsem' ...
    }));

    % Q5: czy rozróżnia metaforę od twierdzenia
    p.meta_boundary = double(lc_contains_any(textLower, { ...
        'nie', 'to nie jest', 'nie traktuje', 'nie oznacza', 'nie mylic', 'nie myl' ...
    }));

    % Q6: czy tekst jest silnie spekulacyjny
    specMarkers = lc_contains_count(textLower, { ...
        'moze', 'chyba', 'jakby', 'wydaje', 'mozliwe', 'zobaczymy' ...
    });
    p.speculation_band = lc_bucket_3(specMarkers);

    % Q7: obecność struktury badawczej
    structMarkers = lc_contains_count(textLower, { ...
        'analiza', 'model', 'metoda', 'struktura', 'proces', 'badaw', 'korpus', 'dane' ...
    });
    p.research_band = lc_bucket_3(structMarkers);

    % Q8: długość i kompozycja
    p.length_band = lc_bucket_4(numel(words));

    % Q9: czy są ograniczniki epistemiczne
    p.epistemic_brakes = double(lc_contains_any(textLower, { ...
        'poczekamy', 'dowody', 'nie wiadomo', 'nie rozstrzyga', 'nie jest dowodem', ...
        'to nie znaczy', 'nie musi' ...
    }));

    % Q10: czy są sygnały formalizacji
    p.formalization = double(lc_contains_any(textLower, { ...
        'formaln', 'metryk', 'model', 'grupy cech', 'struktura poznawcza', ...
        'llm', 'halucynac', 'bled', 'ryzyko' ...
    }));
end

function groundedness = lc_groundedness_proxy(textLower)
    evidenceTerms = { ...
        'to jest', 'oznacza', 'model', 'metoda', 'analiza', 'struktura', ...
        'proces', 'korpus', 'dane', 'badawczy', 'definic', 'formaln', ...
        'w tym sensie', 'z perspektywy', 'mozna opisac', 'wynika' ...
    };

    evidenceCount = lc_contains_count(textLower, evidenceTerms);
    sentenceCount = max(1, lc_sentence_count(textLower));

    groundedness = lc_clip01(evidenceCount / max(sentenceCount * 0.7, 1));
end

function ambiguity = lc_ambiguity_proxy(textLower)
    ambiguityTerms = { ...
        '...', '?', 'moze', 'chyba', 'jakby', 'zobaczymy', 'wydaje', ...
        'upiornym', 'widze', 'mam wrazenie', 'moim zdaniem' ...
    };

    a = lc_contains_count(textLower, ambiguityTerms);
    s = max(1, lc_sentence_count(textLower));

    ambiguity = lc_clip01(a / max(s * 0.8, 1));
end

function risk = lc_negative_hallucination_proxy(textLower, negativeProbeTerms)
    % Ryzyko jest wysokie, gdy tekst jest bardzo szeroki/abstrakcyjny,
    % ma mało twardych zakotwiczeń i jednocześnie nie zawiera sygnałów
    % formalnych ograniczających interpretację.

    unsupportedCount = lc_contains_count(textLower, negativeProbeTerms);
    formalCount = lc_contains_count(textLower, { ...
        'model', 'metoda', 'analiza', 'struktura', 'dane', 'korpus', 'formaln', 'dowody' ...
    });
    ambiguityCount = lc_contains_count(textLower, { ...
        'moze', 'chyba', 'jakby', 'zobaczymy', '...' ...
    });

    % jeśli tekst sam twierdzi rzeczy z listy negatywnej, ryzyko rośnie
    raw = 0.20 * unsupportedCount + 0.55 * ambiguityCount - 0.35 * formalCount;
    risk = lc_clip01(0.5 + 0.08 * raw);
end

function debt = lc_interpretive_debt(ambiguity, groundedness)
    debt = lc_clip01(0.65 * ambiguity + 0.35 * (1 - groundedness));
end

function score = lc_structure_score(textLower)
    structureTerms = { ...
        'model', 'metoda', 'struktura', 'proces', 'analiza', 'warstwa', ...
        'rdzen', 'korpus', 'heurystyk', 'metacode', 'llm', 'loci', ...
        'poznawcz', 'interfejs', 'formaln', 'ryzyko' ...
    };

    countStruct = lc_contains_count(textLower, structureTerms);
    sentenceCount = max(1, lc_sentence_count(textLower));

    score = lc_clip01(countStruct / max(sentenceCount, 1));
end

function score = lc_maturity_score(coreStability, answerStability, groundedness, structureScore, negRisk, interpDebt)
    score = ...
        0.24 * coreStability + ...
        0.22 * answerStability + ...
        0.22 * groundedness + ...
        0.18 * structureScore + ...
        0.14 * (1 - negRisk) - ...
        0.10 * interpDebt;

    score = lc_clip01(score);
end

% =========================================================================
% TEXT UTILITIES
% =========================================================================

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
    hasPerform = lc_contains_any(textLower, {'teatr','scena','postac','rola','maska','perform'});
    hasReflect = lc_contains_any(textLower, {'mam poczucie','widze','dla mnie','moim zdaniem','wrazenie'});

    c = hasResearch + 2*hasPerform + 4*hasReflect;
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

function s = lc_safe_trim(text, n)
    if nargin < 2
        n = 120;
    end
    if isempty(text)
        s = '';
        return;
    end
    text = strrep(text, sprintf('\n'), ' ');
    if length(text) <= n
        s = text;
    else
        s = [text(1:n) '...'];
    end
end

function v = lc_clip01(v)
    v = max(0, min(1, v));
end

% =========================================================================
% STABILITY
% =========================================================================

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
            scores(i) = double(a == b);
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

function idx = lc_find_first_window(mask)
    idx = NaN;
    if isempty(mask)
        return;
    end
    for i = 3:numel(mask)
        if all(mask(i-2:i))
            idx = i;
            return;
        end
    end
end

% =========================================================================
% LOCI / PCA
% =========================================================================

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

% =========================================================================
% REPORTS
% =========================================================================

function lc_writeTxtSummary(pathOut, out)
    fid = fopen(pathOut, 'w');
    if fid < 0
        warning('Could not write TXT summary: %s', pathOut);
        return;
    end

    fprintf(fid, '=========================================\n');
    fprintf(fid, 'LOCI COGNITIVE READINESS TEST\n');
    fprintf(fid, '=========================================\n\n');

    fprintf(fid, 'sample_id                        : %s\n', out.sample_id);
    fprintf(fid, 'timestamp                        : %s\n', out.timestamp);
    fprintf(fid, 'input_file                       : %s\n', out.input_file);
    fprintf(fid, 'result_dir                       : %s\n', out.result_dir);
    fprintf(fid, 'generations                      : %d\n', out.generations);
    fprintf(fid, 'feature_count                    : %d\n', out.feature_count);
    fprintf(fid, 'loci_onset_generation            : G%04d\n', out.loci_onset_generation);

    if isnan(out.first_cognitive_stable_generation)
        fprintf(fid, 'first_cognitive_stable_generation: unresolved\n');
    else
        fprintf(fid, 'first_cognitive_stable_generation: G%04d\n', out.first_cognitive_stable_generation);
    end

    if isnan(out.first_llm_ready_generation)
        fprintf(fid, 'first_llm_ready_generation       : unresolved\n');
    else
        fprintf(fid, 'first_llm_ready_generation       : G%04d\n', out.first_llm_ready_generation);
    end

    fprintf(fid, 'transition_window                : %s\n', out.transition_window);
    fprintf(fid, 'mean_core_stability              : %.6f\n', out.mean_core_stability);
    fprintf(fid, 'mean_answer_stability            : %.6f\n', out.mean_answer_stability);
    fprintf(fid, 'mean_groundedness                : %.6f\n', out.mean_groundedness);
    fprintf(fid, 'mean_negative_hallucination_risk : %.6f\n', out.mean_negative_hallucination_risk);
    fprintf(fid, 'mean_interpretive_debt           : %.6f\n', out.mean_interpretive_debt);
    fprintf(fid, 'mean_structure_score             : %.6f\n', out.mean_structure_score);
    fprintf(fid, 'mean_maturity_score              : %.6f\n', out.mean_maturity_score);

    fprintf(fid, '\n=== GENERATION ROWS ===\n');
    for i = 1:numel(out.rows)
        r = out.rows(i);
        fprintf(fid, '\nG%04d\n', r.generation);
        fprintf(fid, '  char_len                     : %.0f\n', r.char_len);
        fprintf(fid, '  word_count                   : %.0f\n', r.word_count);
        fprintf(fid, '  core_stability               : %.6f\n', r.core_stability);
        fprintf(fid, '  answer_stability             : %.6f\n', r.answer_stability);
        fprintf(fid, '  groundedness                 : %.6f\n', r.groundedness);
        fprintf(fid, '  negative_hallucination_risk  : %.6f\n', r.negative_hallucination_risk);
        fprintf(fid, '  interpretive_debt            : %.6f\n', r.interpretive_debt);
        fprintf(fid, '  structure_score              : %.6f\n', r.structure_score);
        fprintf(fid, '  maturity_score               : %.6f\n', r.maturity_score);
        fprintf(fid, '  keywords                     : %s\n', strjoin(r.keywords, ', '));
        fprintf(fid, '  snapshot                     : %s\n', r.snapshot_title);
    end

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

    fprintf(fid, '- **Transition window:** `%s`\n', out.transition_window);
    fprintf(fid, '- **Mean groundedness:** `%.6f`\n', out.mean_groundedness);
    fprintf(fid, '- **Mean hallucination risk proxy:** `%.6f`\n', out.mean_negative_hallucination_risk);
    fprintf(fid, '- **Mean interpretive debt:** `%.6f`\n', out.mean_interpretive_debt);
    fprintf(fid, '- **Mean maturity score:** `%.6f`\n\n', out.mean_maturity_score);

    fprintf(fid, '## Figure\n\n');
    fprintf(fid, '![%s](./%s%s)\n\n', out.sample_id, pngName, pngExt);

    fprintf(fid, '## Per-generation rows\n\n');
    for i = 1:numel(out.rows)
        r = out.rows(i);
        fprintf(fid, '### G%04d\n\n', r.generation);
        fprintf(fid, '- **Core stability:** `%.6f`\n', r.core_stability);
        fprintf(fid, '- **Answer stability:** `%.6f`\n', r.answer_stability);
        fprintf(fid, '- **Groundedness:** `%.6f`\n', r.groundedness);
        fprintf(fid, '- **Negative hallucination risk:** `%.6f`\n', r.negative_hallucination_risk);
        fprintf(fid, '- **Interpretive debt:** `%.6f`\n', r.interpretive_debt);
        fprintf(fid, '- **Structure score:** `%.6f`\n', r.structure_score);
        fprintf(fid, '- **Maturity score:** `%.6f`\n', r.maturity_score);
        fprintf(fid, '- **Keywords:** `%s`\n', strjoin(r.keywords, ', '));
        fprintf(fid, '- **Snapshot:** `%s`\n\n', r.snapshot_title);
    end

    fclose(fid);
end

% =========================================================================
% ROOT / PATHS
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

% =========================================================================
% STOPWORDS
% =========================================================================

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