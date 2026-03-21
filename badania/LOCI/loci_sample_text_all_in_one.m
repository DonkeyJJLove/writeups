function R = loci_sample_text_all_in_one(sampleFile)
% LOCI_SAMPLE_TEXT_ALL_IN_ONE
% Analiza LOCI dla pliku będącego sekwencją kolejnych generacji tekstu.
%
% Użycie:
%   R = loci_sample_text_all_in_one('Sample_0001.m');
%
% Założenie:
% - plik NIE jest poprawnym skryptem MATLAB ani tabelą liczbową,
% - plik zawiera kolejne wersje / generacje tekstu,
% - każda generacja jest traktowana jako kolejny stan procesu.
%
% Wynik:
% - segmentacja generacji,
% - ekstrakcja cech tekstowych,
% - konstrukcja wskaźnika złożoności / dryfu,
% - analiza LOCI po indeksie generacji,
% - raport dowodowy i wykresy.

    clc;

    if nargin < 1 || ~(ischar(sampleFile) || isstring(sampleFile))
        error('Podaj nazwę pliku, np. R = loci_sample_text_all_in_one(''Sample_0001.m'');');
    end

    sampleFile = char(sampleFile);

    if ~exist(sampleFile, 'file')
        error('Nie znaleziono pliku: %s', sampleFile);
    end

    fprintf('============================================================\n');
    fprintf('LOCI SAMPLE TEXT ALL IN ONE\n');
    fprintf('Plik wejściowy: %s\n', sampleFile);
    fprintf('============================================================\n\n');

    txt = fileread(sampleFile);

    G = i_parse_generations(txt);

    if numel(G) < 8
        error(['W pliku wykryto zbyt mało generacji (%d). ' ...
               'To za mało do sensownej analizy LOCI.'], numel(G));
    end

    fprintf('Wykryto generacji: %d\n', numel(G));

    F = i_extract_generation_features(G);
    R = i_run_loci_text_analysis(sampleFile, G, F);

    fprintf('\n==================== PODSUMOWANIE ====================\n');
    fprintf('Liczba generacji: %d\n', R.n_generations);
    fprintf('ONSET LOCI         = G%04d\n', R.onset_idx);
    fprintf('MAX SLOPE          = G%04d\n', R.max_slope_idx);
    fprintf('MAX CURVATURE      = G%04d\n', R.max_curv_idx);
    fprintf('Werdykt            = %s\n', R.evidence.verdict);
    fprintf('=====================================================\n');

    fprintf('\n==================== RAPORT DOWODOWY ====================\n');
    i_print_report(R);
    fprintf('=========================================================\n');
end

% ========================================================================
function G = i_parse_generations(txt)
% Segmentacja kolejnych generacji tekstu.
%
% Heurystyka:
% - plik zawiera bardzo wiele powtarzanych bloków,
% - każda generacja zwykle zawiera:
%   [cytat angielski] + [dopisany komentarz PL] + data "18 grudnia 2018"
% - używamy daty jako naturalnego separatora końca generacji.

    txt = strrep(txt, sprintf('\r\n'), sprintf('\n'));
    txt = strrep(txt, sprintf('\r'), sprintf('\n'));

    lines = regexp(txt, '\n', 'split');
    lines = lines(:);

    % normalizacja pustych linii
    for i = 1:numel(lines)
        lines{i} = strtrim(lines{i});
    end

    datePattern = '^\s*18\s+grudnia\s+2018\s*$';

    blocks = {};
    cur = {};

    for i = 1:numel(lines)
        line = lines{i};

        if isempty(line)
            continue;
        end

        cur{end+1,1} = line; %#ok<AGROW>

        if ~isempty(regexp(line, datePattern, 'once'))
            blockText = strjoin(cur, newline);
            blocks{end+1,1} = strtrim(blockText); %#ok<AGROW>
            cur = {};
        end
    end

    if ~isempty(cur)
        blockText = strjoin(cur, newline);
        if strlength(string(strtrim(blockText))) > 0
            blocks{end+1,1} = strtrim(blockText); %#ok<AGROW>
        end
    end

    % fallback: jeśli segmentacja po dacie da bardzo mało bloków,
    % użyj bardziej brutalnego podziału po pojawieniu się "Shamoon attacks"
    if numel(blocks) < 5
        seedPattern = 'Shamoon attacks';
        idx = strfind(txt, seedPattern);
        blocks = {};
        if numel(idx) >= 2
            for k = 1:numel(idx)
                s = idx(k);
                if k < numel(idx)
                    e = idx(k+1)-1;
                else
                    e = length(txt);
                end
                b = strtrim(txt(s:e));
                if strlength(string(b)) > 20
                    blocks{end+1,1} = b; %#ok<AGROW>
                end
            end
        end
    end

    % czyszczenie duplikatów pustych / mikroskopijnych
    G = struct('id', {}, 'text', {}, 'nChars', {}, 'nWords', {});
    c = 0;

    for i = 1:numel(blocks)
        b = strtrim(blocks{i});
        if strlength(string(b)) < 30
            continue;
        end

        c = c + 1;
        G(c).id = c; %#ok<AGROW>
        G(c).text = b; %#ok<AGROW>
        G(c).nChars = strlength(string(b)); %#ok<AGROW>
        G(c).nWords = numel(regexp(lower(b), '\S+', 'match')); %#ok<AGROW>
    end
end

% ========================================================================
function F = i_extract_generation_features(G)
% Ekstrakcja cech dla każdej generacji.
%
% Cechy:
% - długość
% - liczba słów
% - liczba zdań
% - bogactwo leksykalne
% - udział nowych tokenów względem poprzedniej generacji
% - podobieństwo Jaccarda do poprzedniej generacji
% - przyrost długości
% - gęstość znaków specjalnych
% - gęstość pytań
% - liczba fraz geopolitycznych / operacyjnych (neutralnie jako cecha tekstu)

    n = numel(G);

    len_chars      = zeros(n,1);
    len_words      = zeros(n,1);
    n_sent         = zeros(n,1);
    lex_div        = zeros(n,1);
    delta_words    = zeros(n,1);
    jacc_prev      = zeros(n,1);
    novelty_prev   = zeros(n,1);
    punct_density  = zeros(n,1);
    qmark_density  = zeros(n,1);
    keyword_score  = zeros(n,1);

    keys = lower({ ...
        'iran','saud','opec','francja','ropa','paliwa','terror', ...
        'hezbollah','ajatollah','shamoon','apt33','apt34','apt35', ...
        'france','oil','market','prices','nuclear','anti-terror'});

    prevTokens = string.empty;

    for i = 1:n
        txt = G(i).text;
        txl = lower(txt);

        tokens = regexp(txl, '[\p{L}\p{N}_-]+', 'match');
        tokens = string(tokens(:));

        len_chars(i) = strlength(string(txt));
        len_words(i) = numel(tokens);

        sents = regexp(txt, '[^.!?]+[.!?]?', 'match');
        sents = sents(~cellfun(@isempty, strtrim(sents)));
        n_sent(i) = numel(sents);

        if ~isempty(tokens)
            lex_div(i) = numel(unique(tokens)) / numel(tokens);
        else
            lex_div(i) = 0;
        end

        punct_density(i) = numel(regexp(txt, '[,;:()\-\?!"'']', 'match')) / max(1, len_chars(i));
        qmark_density(i) = count(string(txt), '?') / max(1, len_words(i));

        ksum = 0;
        for k = 1:numel(keys)
            ksum = ksum + count(string(txl), keys{k});
        end
        keyword_score(i) = ksum;

        if i == 1
            delta_words(i)  = 0;
            jacc_prev(i)    = 1;
            novelty_prev(i) = 0;
        else
            delta_words(i) = len_words(i) - len_words(i-1);

            A = unique(prevTokens);
            B = unique(tokens);

            interAB = numel(intersect(A,B));
            unionAB = numel(union(A,B));

            if unionAB == 0
                jacc_prev(i) = 1;
            else
                jacc_prev(i) = interAB / unionAB;
            end

            if isempty(B)
                novelty_prev(i) = 0;
            else
                novelty_prev(i) = numel(setdiff(B,A)) / numel(B);
            end
        end

        prevTokens = tokens;
    end

    % normalizacja robust
    z_len_words     = i_robust_z(len_words);
    z_n_sent        = i_robust_z(n_sent);
    z_lex_div       = i_robust_z(lex_div);
    z_delta_words   = i_robust_z(delta_words);
    z_novelty_prev  = i_robust_z(novelty_prev);
    z_jacc_change   = i_robust_z(1 - jacc_prev);
    z_punct_density = i_robust_z(punct_density);
    z_qmark_density = i_robust_z(qmark_density);
    z_keyword_score = i_robust_z(keyword_score);

    % Indeks dynamiki generacyjnej: im większy, tym większa zmiana strukturalna.
    dynamic_score = ...
        0.20 * z_len_words + ...
        0.10 * z_n_sent + ...
        0.10 * z_lex_div + ...
        0.15 * z_delta_words + ...
        0.15 * z_novelty_prev + ...
        0.15 * z_jacc_change + ...
        0.05 * z_punct_density + ...
        0.05 * z_qmark_density + ...
        0.05 * z_keyword_score;

    % przesunięcie do nieujemnych
    dynamic_score = dynamic_score - min(dynamic_score);
    dynamic_score = max(dynamic_score, 0);

    F = table( ...
        (1:n)', len_chars, len_words, n_sent, lex_div, delta_words, ...
        jacc_prev, novelty_prev, punct_density, qmark_density, keyword_score, ...
        dynamic_score, ...
        'VariableNames', { ...
        'gen','len_chars','len_words','n_sent','lex_div','delta_words', ...
        'jacc_prev','novelty_prev','punct_density','qmark_density', ...
        'keyword_score','dynamic_score'});
end

% ========================================================================
function z = i_robust_z(x)
    x = x(:);
    medx = median(x, 'omitnan');
    madx = mad(x, 1);

    if madx <= 0
        sx = std(x, 'omitnan');
        if sx <= 0
            z = zeros(size(x));
        else
            z = (x - mean(x, 'omitnan')) ./ sx;
        end
    else
        z = (x - medx) ./ madx;
    end

    z(~isfinite(z)) = 0;
end

% ========================================================================
function R = i_run_loci_text_analysis(sampleFile, G, F)

    x = F.gen;
    y = F.dynamic_score;

    n = numel(x);
    if n < 8
        error('Za mało generacji do analizy LOCI.');
    end

    y_s = i_smooth_signal(y, min(11,n), 3);
    dy  = gradient(y_s, x);
    d2y = gradient(dy, x);

    kEdge = max(1, floor(0.05*n));
    interior = false(n,1);
    interior((kEdge+1):(n-kEdge)) = true;

    if sum(interior) < 3
        interior(:) = true;
    end

    thr_slope = median(abs(dy(interior)))  + 2.5 * mad(abs(dy(interior)), 1);
    thr_curv  = median(abs(d2y(interior))) + 2.5 * mad(abs(d2y(interior)), 1);
    thr_level = median(y_s(interior)) + 0.5 * mad(y_s(interior), 1);

    onset_mask = interior & ...
                 (abs(dy)  >= thr_slope) & ...
                 (abs(d2y) >= thr_curv)  & ...
                 (y_s      >= thr_level);

    onset_idx = i_first_sustained_run(onset_mask, max(2, floor(0.03*n)));
    if isnan(onset_idx)
        onset_idx = i_first_sustained_run(interior & (abs(dy) >= thr_slope) & (y_s >= thr_level), 2);
    end
    if isnan(onset_idx)
        [~, onset_idx] = max(abs(dy) .* interior);
    end

    [~, max_slope_idx] = max(abs(dy) .* interior);
    [~, max_curv_idx]  = max(abs(d2y) .* interior);

    % bootstrap na resztach
    rng(42, 'twister');
    resid = y - y_s;
    sigma = mad(resid(interior), 1);
    if sigma <= 0, sigma = std(resid(interior)); end
    if sigma <= 0, sigma = 1e-6; end

    nBoot = 1000;
    onset_boot = nan(nBoot,1);
    slope_boot = nan(nBoot,1);
    curv_boot  = nan(nBoot,1);

    for b = 1:nBoot
        yb = max(0, y_s + sigma .* randn(size(y_s)));
        ybs = i_smooth_signal(yb, min(11,n), 3);
        dyb = gradient(ybs, x);
        d2b = gradient(dyb, x);

        thr_sb = median(abs(dyb(interior))) + 2.5 * mad(abs(dyb(interior)), 1);
        thr_cb = median(abs(d2b(interior))) + 2.5 * mad(abs(d2b(interior)), 1);
        thr_lb = median(ybs(interior)) + 0.5 * mad(ybs(interior), 1);

        maskb = interior & (abs(dyb) >= thr_sb) & (abs(d2b) >= thr_cb) & (ybs >= thr_lb);
        idxb = i_first_sustained_run(maskb, 2);

        if isnan(idxb)
            idxb = i_first_sustained_run(interior & (abs(dyb) >= thr_sb) & (ybs >= thr_lb), 2);
        end
        if isnan(idxb)
            [~, idxb] = max(abs(dyb) .* interior);
        end

        [~, isb] = max(abs(dyb) .* interior);
        [~, icb] = max(abs(d2b) .* interior);

        onset_boot(b) = idxb;
        slope_boot(b) = isb;
        curv_boot(b)  = icb;
    end

    evidence = i_classify_text_evidence(onset_idx, max_slope_idx, max_curv_idx, n, y_s, dy, d2y, interior);

    result_table = table( ...
        x, y, y_s, dy, d2y, F.len_words, F.delta_words, F.jacc_prev, F.novelty_prev, ...
        'VariableNames', {'gen','score_raw','score_smooth','dscore','d2score', ...
        'len_words','delta_words','jacc_prev','novelty_prev'});

    R = struct();
    R.sample_file     = sampleFile;
    R.generations     = G;
    R.features        = F;
    R.result_table    = result_table;
    R.n_generations   = n;

    R.onset_idx       = onset_idx;
    R.max_slope_idx   = max_slope_idx;
    R.max_curv_idx    = max_curv_idx;

    R.score_raw       = y;
    R.score_smooth    = y_s;
    R.dscore          = dy;
    R.d2score         = d2y;
    R.interior_mask   = interior;
    R.onset_mask      = onset_mask;

    R.bootstrap = struct( ...
        'n', nBoot, ...
        'onset_ci95', prctile(onset_boot, [2.5 97.5]), ...
        'onset_median', median(onset_boot), ...
        'slope_ci95', prctile(slope_boot, [2.5 97.5]), ...
        'slope_median', median(slope_boot), ...
        'curv_ci95', prctile(curv_boot, [2.5 97.5]), ...
        'curv_median', median(curv_boot));

    R.thresholds = struct( ...
        'thr_slope', thr_slope, ...
        'thr_curv', thr_curv, ...
        'thr_level', thr_level);

    R.evidence = evidence;

    i_plot_report(R);
end

% ========================================================================
function y = i_smooth_signal(x, win, poly)
    x = x(:);
    n = numel(x);

    if n < 5
        y = x;
        return;
    end

    if mod(win,2) == 0
        win = win + 1;
    end

    if win >= n
        win = n - 1;
        if mod(win,2) == 0
            win = win - 1;
        end
    end

    if win < 5
        win = 5;
        if win >= n
            y = movmean(x, min(3,n), 'Endpoints','shrink');
            return;
        end
    end

    if poly >= win
        poly = max(1, win-2);
    end

    try
        y = sgolayfilt(x, poly, win);
    catch
        y = movmean(x, win, 'Endpoints', 'shrink');
    end
end

% ========================================================================
function idx = i_first_sustained_run(mask, minRun)
    idx = NaN;
    mask = logical(mask(:));

    d = diff([false; mask; false]);
    starts = find(d == 1);
    stops  = find(d == -1) - 1;

    if isempty(starts)
        return;
    end

    lens = stops - starts + 1;
    k = find(lens >= minRun, 1, 'first');

    if ~isempty(k)
        idx = starts(k);
    end
end

% ========================================================================
function E = i_classify_text_evidence(onset_idx, slope_idx, curv_idx, n, y, dy, d2y, interior)

    edgeTol = max(2, round(0.05*n));
    onset_edge = (onset_idx <= edgeTol) || (onset_idx >= n-edgeTol+1);

    spanSlope = abs(slope_idx - onset_idx);
    spanCurv  = abs(curv_idx  - onset_idx);

    coherent = (spanSlope <= max(3, round(0.15*n))) || ...
               (spanCurv  <= max(3, round(0.15*n)));

    amp = max(y(interior)) - min(y(interior));
    dynStrong = max(abs(dy(interior))) > (median(abs(dy(interior))) + mad(abs(dy(interior)),1));
    curvStrong = max(abs(d2y(interior))) > (median(abs(d2y(interior))) + mad(abs(d2y(interior)),1));

    if coherent && dynStrong && curvStrong && ~onset_edge
        verdict = 'P1 — silne przejście LOCI w sekwencji generacji';
    elseif (dynStrong || curvStrong) && coherent
        verdict = 'P2 — umiarkowanie silne przejście LOCI';
    elseif dynStrong || curvStrong
        verdict = 'P2/P3 — sygnał częściowy, słabszy dowodowo';
    else
        verdict = 'P3 — brak mocnego przejścia LOCI';
    end

    E = struct();
    E.verdict = verdict;
    E.onset_edge = onset_edge;
    E.coherent = coherent;
    E.amp = amp;
    E.spanSlope = spanSlope;
    E.spanCurv = spanCurv;
    E.dynStrong = dynStrong;
    E.curvStrong = curvStrong;
end

% ========================================================================
function i_plot_report(R)

    x = (1:R.n_generations)';

    figure('Name','LOCI text generations audit','Color','w', ...
           'Position',[80 80 1400 900]);

    tiledlayout(4,1,'Padding','compact','TileSpacing','compact');

    nexttile;
    plot(x, R.features.len_words, '-', 'LineWidth', 1.2); hold on;
    xline(R.onset_idx, '--', sprintf('onset G%d', R.onset_idx));
    xline(R.max_slope_idx, '--', sprintf('slope G%d', R.max_slope_idx));
    xline(R.max_curv_idx, '--', sprintf('curv G%d', R.max_curv_idx));
    ylabel('len\_words');
    title('Długość generacji');
    grid on; box on;

    nexttile;
    plot(x, R.features.novelty_prev, '-', 'LineWidth', 1.2); hold on;
    plot(x, 1 - R.features.jacc_prev, '-', 'LineWidth', 1.2);
    xline(R.onset_idx, '--');
    ylabel('change');
    title('Nowość i dryf względem poprzedniej generacji');
    legend({'novelty\_prev','1 - jacc\_prev'}, 'Location','best');
    grid on; box on;

    nexttile;
    plot(x, R.score_raw, '-', 'LineWidth', 0.9); hold on;
    plot(x, R.score_smooth, '-', 'LineWidth', 2.0);
    xline(R.onset_idx, '--');
    xline(R.max_slope_idx, '--');
    xline(R.max_curv_idx, '--');
    ylabel('score');
    title('Wskaźnik dynamiki generacyjnej');
    legend({'raw','smooth'}, 'Location','best');
    grid on; box on;

    nexttile;
    plot(x, R.dscore, '-', 'LineWidth', 1.2); hold on;
    plot(x, R.d2score, '-', 'LineWidth', 1.2);
    xline(R.onset_idx, '--');
    xline(R.max_slope_idx, '--');
    xline(R.max_curv_idx, '--');
    xlabel('Generacja');
    ylabel('pochodne');
    title('Pochodne wskaźnika i punkt przejścia LOCI');
    legend({'dscore','d2score'}, 'Location','best');
    grid on; box on;
end

% ========================================================================
function i_print_report(R)

    fprintf('Plik: %s\n', R.sample_file);
    fprintf('Liczba generacji: %d\n', R.n_generations);

    fprintf('\n[1] Interpretacja wejścia\n');
    fprintf('  Plik został potraktowany jako sekwencja kolejnych generacji tekstu.\n');
    fprintf('  Nie analizowano go jako skryptu MATLAB ani tabeli liczbowej.\n');

    fprintf('\n[2] Punkty charakterystyczne LOCI\n');
    fprintf('  onset_idx      = %d\n', R.onset_idx);
    fprintf('  max_slope_idx  = %d\n', R.max_slope_idx);
    fprintf('  max_curv_idx   = %d\n', R.max_curv_idx);

    fprintf('\n[3] Bootstrap 95%% CI\n');
    fprintf('  onset CI95     = [%.2f, %.2f], mediana=%.2f\n', ...
        R.bootstrap.onset_ci95(1), R.bootstrap.onset_ci95(2), R.bootstrap.onset_median);
    fprintf('  slope CI95     = [%.2f, %.2f], mediana=%.2f\n', ...
        R.bootstrap.slope_ci95(1), R.bootstrap.slope_ci95(2), R.bootstrap.slope_median);
    fprintf('  curv  CI95     = [%.2f, %.2f], mediana=%.2f\n', ...
        R.bootstrap.curv_ci95(1), R.bootstrap.curv_ci95(2), R.bootstrap.curv_median);

    fprintf('\n[4] Werdykt epistemiczny\n');
    fprintf('  %s\n', R.evidence.verdict);
    fprintf('  onset brzegowy?  %d\n', R.evidence.onset_edge);
    fprintf('  spójność fazowa? %d\n', R.evidence.coherent);
    fprintf('  amplituda score  %.6f\n', R.evidence.amp);
    fprintf('  |slope-onset|    %d\n', R.evidence.spanSlope);
    fprintf('  |curv-onset|     %d\n', R.evidence.spanCurv);

    fprintf('\n[5] Najsilniejsze generacje\n');
    idxs = unique([R.onset_idx; R.max_slope_idx; R.max_curv_idx]);
    for k = 1:numel(idxs)
        i = idxs(k);
        snippet = R.generations(i).text;
        snippet = regexprep(snippet, '\s+', ' ');
        snippet = strtrim(snippet);
        if strlength(string(snippet)) > 180
            snippet = extractBefore(string(snippet), 181) + "...";
        end
        fprintf('  G%04d: %s\n', i, snippet);
    end
end