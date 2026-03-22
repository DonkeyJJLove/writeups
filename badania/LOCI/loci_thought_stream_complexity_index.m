function R = loci_thought_stream_complexity_index(sampleFile)
% LOCI_THOUGHT_STREAM_COMPLEXITY_INDEX
% ------------------------------------------------------------
% TSCI = Thought Stream Complexity Index
%
% Cel:
% Policzyć reprodukowalny wskaźnik złożoności strumienia myśli
% dla próbki Human-AI / tekstowej analizowanej przez LOCI.
%
% Wejście:
%   sampleFile - np. 'sample/norm/Sample_0001n.m'
%
% Wyjście:
%   R - struct z pełnym raportem
%
% Reżim naukowy:
%   - brak "IQ claims"
%   - brak psychometrii klinicznej
%   - tylko formalna złożoność trajektorii tekstowej
%
% Autor: ChatGPT / model roboczy dla projektu LOCI
% ------------------------------------------------------------

    clc;

    thisFile = mfilename('fullpath');
    thisDir  = fileparts(thisFile);

    addpath(thisDir);
    if exist(fullfile(thisDir,'sample','norm'),'dir')
        addpath(fullfile(thisDir,'sample','norm'));
    end

    fprintf('============================================================\n');
    fprintf('LOCI THOUGHT STREAM COMPLEXITY INDEX\n');
    fprintf('============================================================\n');
    fprintf('Plik wejściowy : %s\n', sampleFile);
    fprintf('Katalog skryptu: %s\n', thisDir);
    fprintf('============================================================\n\n');

    % --------------------------------------------------------
    % [1] Główna analiza LOCI
    % --------------------------------------------------------
    L = loci_sample_text_all_in_one(sampleFile);

    % Tabela cech
    if isfield(L, 'result_table') && istable(L.result_table)
        T = L.result_table;
    elseif isfield(L, 'features') && istable(L.features)
        T = L.features;
    else
        error('Brak tabeli cech w wyniku LOCI.');
    end

    n = height(T);
    if n < 10
        error('Za mało generacji do liczenia TSCI.');
    end

    % --------------------------------------------------------
    % [2] Ekstrakcja serii
    % --------------------------------------------------------
    score   = i_get_vector(L, 'score_smooth', n);
    dscore  = i_get_vector(L, 'dscore', n);
    d2score = i_get_vector(L, 'd2score', n);

    entropyV    = i_get_table_var(T, 'd_entropy', n);
    noveltyV    = i_get_table_var(T, 'novelty_prev', n);
    driftV      = i_get_table_var(T, 'drift_prev', n);
    vocabV      = i_get_table_var(T, 'new_vocab_ratio', n);
    repeatV     = i_get_table_var(T, 'repetition', n);
    lenWordsV   = i_get_table_var(T, 'd_len_words', n);

    % Tekstowe przyrosty jeśli są dostępne
    textLenV    = i_get_table_var_optional(T, {'text_len','len_chars','chars'}, n);
    tokenLenV   = i_get_table_var_optional(T, {'n_tokens','tokens','len_tokens'}, n);

    % --------------------------------------------------------
    % [3] Komponenty złożoności
    % --------------------------------------------------------
    % Każdy komponent jest w [0,1] po normalizacji robust.
    % Finalny indeks = ważona suma komponentów.
    %
    % Intuicja:
    % - complexity nie jest "chaosem absolutnym"
    % - complexity = ruch + reorganizacja + ekspansja + kontrola
    %
    % Dlatego karzemy skrajne plateau i skrajną przypadkowość.

    % 3.1 Dynamika trajektorii
    c_step = i_robust_sigmoid(mean(abs(dscore)) + std(abs(dscore)));
    c_curv = i_robust_sigmoid(mean(abs(d2score)) + std(abs(d2score)));

    % 3.2 Zmienność semantyczna
    c_entropy = i_robust_sigmoid(mean(abs(entropyV)) + std(abs(entropyV)));
    c_drift   = i_robust_sigmoid(mean(abs(driftV))   + std(abs(driftV)));
    c_novelty = i_robust_sigmoid(mean(abs(noveltyV)) + std(abs(noveltyV)));
    c_vocab   = i_robust_sigmoid(mean(abs(vocabV))   + std(abs(vocabV)));

    % 3.3 Ekspansja tekstu
    if any(~isnan(textLenV))
        growth_chars = max(textLenV) - min(textLenV);
        c_growth_chars = i_robust_sigmoid(growth_chars / max(1, nanmedian(textLenV)));
    else
        c_growth_chars = 0.0;
    end

    if any(~isnan(tokenLenV))
        growth_tokens = max(tokenLenV) - min(tokenLenV);
        c_growth_tokens = i_robust_sigmoid(growth_tokens / max(1, nanmedian(tokenLenV)));
    else
        c_growth_tokens = 0.0;
    end

    c_len_words = i_robust_sigmoid(mean(abs(lenWordsV)) + std(abs(lenWordsV)));

    % 3.4 Plateau / persystencja
    % Złożoność nie może być ani samym plateau, ani samym hałasem.
    plateauMask   = abs(dscore) < max(eps, 0.10 * nanstd(score));
    plateauRatio  = mean(plateauMask);
    longestPlate  = i_longest_run(plateauMask);

    % optimum: umiarkowana persystencja
    c_persistence = exp(-((plateauRatio - 0.35).^2) / (2 * 0.18^2));
    c_plateau_len = exp(-((longestPlate / n - 0.20).^2) / (2 * 0.15^2));

    % 3.5 Antyredundancja
    % duża repetycja obniża complexity
    c_antirepeat = 1 - i_robust_sigmoid(mean(abs(repeatV)) + std(abs(repeatV)));
    c_antirepeat = max(0, min(1, c_antirepeat));

    % 3.6 Punkt przejścia LOCI
    onsetIdx = i_scalar_field(L, 'onset_idx', NaN);
    if numel(onsetIdx) > 1
        onsetIdx = onsetIdx(1);
    end
    if isnan(onsetIdx) || onsetIdx < 3 || onsetIdx > n-2
        c_transition = 0.0;
    else
        w1 = max(1, onsetIdx - 8):max(1, onsetIdx - 1);
        w2 = min(n, onsetIdx + 1):min(n, onsetIdx + 8);

        preVar  = nanstd(score(w1)) + nanstd(dscore(w1)) + nanstd(d2score(w1));
        postVar = nanstd(score(w2)) + nanstd(dscore(w2)) + nanstd(d2score(w2));

        c_transition = i_robust_sigmoid(abs(postVar - preVar));
    end

    % --------------------------------------------------------
    % [4] Finalny indeks TSCI
    % --------------------------------------------------------
    components = [
        c_step
        c_curv
        c_entropy
        c_drift
        c_novelty
        c_vocab
        c_growth_chars
        c_growth_tokens
        c_len_words
        c_persistence
        c_plateau_len
        c_antirepeat
        c_transition
    ];

    weights = [
        0.11
        0.11
        0.08
        0.08
        0.07
        0.07
        0.08
        0.08
        0.06
        0.09
        0.06
        0.07
        0.14
    ];
    
    weights = weights / sum(weights);   % normalizacja do 1
    TSCI = 100 * dot(weights, components);

    % --------------------------------------------------------
    % [5] Klasy jakościowe
    % --------------------------------------------------------
    if TSCI < 25
        cls = 'bardzo niska złożoność strumienia';
    elseif TSCI < 45
        cls = 'niska złożoność strumienia';
    elseif TSCI < 60
        cls = 'umiarkowana złożoność strumienia';
    elseif TSCI < 75
        cls = 'wysoka złożoność strumienia';
    else
        cls = 'bardzo wysoka złożoność strumienia';
    end

    % --------------------------------------------------------
    % [6] Raport
    % --------------------------------------------------------
    fprintf('==================== TSCI SUMMARY ====================\n');
    fprintf('Liczba generacji              : %d\n', n);
    fprintf('LOCI onset                    : %s\n', i_fmt_gen(onsetIdx));
    fprintf('------------------------------------------------------\n');
    fprintf('step dynamics                 : %.4f\n', c_step);
    fprintf('curvature dynamics            : %.4f\n', c_curv);
    fprintf('entropy variability           : %.4f\n', c_entropy);
    fprintf('drift variability             : %.4f\n', c_drift);
    fprintf('novelty variability           : %.4f\n', c_novelty);
    fprintf('lexical expansion             : %.4f\n', c_vocab);
    fprintf('char growth                   : %.4f\n', c_growth_chars);
    fprintf('token growth                  : %.4f\n', c_growth_tokens);
    fprintf('word-length growth            : %.4f\n', c_len_words);
    fprintf('persistence optimum           : %.4f\n', c_persistence);
    fprintf('plateau-length optimum        : %.4f\n', c_plateau_len);
    fprintf('anti-repetition               : %.4f\n', c_antirepeat);
    fprintf('transition strength           : %.4f\n', c_transition);
    fprintf('------------------------------------------------------\n');
    fprintf('plateau ratio                 : %.4f\n', plateauRatio);
    fprintf('longest plateau               : %d\n', longestPlate);
    fprintf('------------------------------------------------------\n');
    fprintf('TSCI                          : %.4f / 100\n', TSCI);
    fprintf('Klasa                         : %s\n', cls);
    fprintf('======================================================\n');

    % --------------------------------------------------------
    % [7] Wyjście
    % --------------------------------------------------------
    R = struct();
    R.sample_file      = sampleFile;
    R.n_generations    = n;
    R.loci_result      = L;
    R.onset_idx        = onsetIdx;
    R.plateau_ratio    = plateauRatio;
    R.longest_plateau  = longestPlate;

    R.components = struct( ...
        'step', c_step, ...
        'curvature', c_curv, ...
        'entropy', c_entropy, ...
        'drift', c_drift, ...
        'novelty', c_novelty, ...
        'vocab', c_vocab, ...
        'growth_chars', c_growth_chars, ...
        'growth_tokens', c_growth_tokens, ...
        'len_words', c_len_words, ...
        'persistence', c_persistence, ...
        'plateau_len', c_plateau_len, ...
        'anti_repetition', c_antirepeat, ...
        'transition', c_transition);

    R.index = struct( ...
        'name', 'TSCI', ...
        'value', TSCI, ...
        'class', cls);

    % opcjonalny wykres
    i_plot_tsci(score, dscore, d2score, onsetIdx, TSCI, cls);

end

% ============================================================
% HELPERS
% ============================================================

function v = i_get_vector(S, fieldName, n)
    if isfield(S, fieldName)
        v = S.(fieldName);
        v = v(:);
        if numel(v) ~= n
            v = i_resize_vector(v, n);
        end
    else
        v = nan(n,1);
    end
end

function v = i_get_table_var(T, varName, n)
    if ismember(varName, T.Properties.VariableNames)
        v = T.(varName);
        v = v(:);
    else
        v = nan(n,1);
    end
end

function v = i_get_table_var_optional(T, names, n)
    v = nan(n,1);
    for k = 1:numel(names)
        if ismember(names{k}, T.Properties.VariableNames)
            v = T.(names{k});
            v = v(:);
            return;
        end
    end
end

function x = i_resize_vector(x, n)
    x = x(:);
    m = numel(x);
    if m == n
        return;
    elseif m == 1
        x = repmat(x, n, 1);
    else
        xi = linspace(1, m, n);
        x  = interp1(1:m, x, xi, 'linear', 'extrap')';
    end
end

function y = i_robust_sigmoid(x)
    % Prosta saturacja do [0,1]
    if isnan(x) || isinf(x)
        y = 0;
        return;
    end
    y = 1 ./ (1 + exp(-x));
    y = max(0, min(1, y));
end

function r = i_longest_run(mask)
    if isempty(mask)
        r = 0;
        return;
    end
    mask = logical(mask(:));
    d = diff([false; mask; false]);
    s = find(d == 1);
    e = find(d == -1) - 1;
    if isempty(s)
        r = 0;
    else
        r = max(e - s + 1);
    end
end

function v = i_scalar_field(S, fieldName, defaultValue)
    if isfield(S, fieldName)
        v = S.(fieldName);
    else
        v = defaultValue;
    end
end

function s = i_fmt_gen(idx)
    if isnan(idx)
        s = 'NA';
    else
        s = sprintf('G%04d', round(idx));
    end
end

function i_plot_tsci(score, dscore, d2score, onsetIdx, TSCI, cls)
    figure('Name','TSCI Report','Color','w');

    tiledlayout(3,1,'Padding','compact','TileSpacing','compact');

    nexttile;
    plot(score, 'LineWidth', 1.4); grid on;
    title(sprintf('Score | TSCI = %.2f | %s', TSCI, cls), 'Interpreter','none');
    ylabel('score');
    if ~isnan(onsetIdx), xline(onsetIdx,'--r','LOCI onset'); end

    nexttile;
    plot(dscore, 'LineWidth', 1.2); grid on;
    ylabel('dscore');
    if ~isnan(onsetIdx), xline(onsetIdx,'--r'); end

    nexttile;
    plot(d2score, 'LineWidth', 1.2); grid on;
    ylabel('d2score');
    xlabel('Generacja');
    if ~isnan(onsetIdx), xline(onsetIdx,'--r'); end
end