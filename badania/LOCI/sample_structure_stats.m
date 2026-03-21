function S = sample_structure_stats(sampleFile)
% SAMPLE_STRUCTURE_STATS
% Analiza rozwoju, stabilności i metawarstw dla próbki Gxxxx.

    raw = fileread(sampleFile);

    % --- Parsowanie generacji ---
    expr = 'G(\d{4}):\s*"(.*?)"';
    tokens = regexp(raw, expr, 'tokens');

    n = numel(tokens);
    gen_id = zeros(n,1);
    texts  = cell(n,1);

    for i = 1:n
        gen_id(i) = str2double(tokens{i}{1});
        texts{i}  = tokens{i}{2};
    end

    % --- Miary podstawowe ---
    chars = zeros(n,1);
    ntoks = zeros(n,1);
    uniq  = zeros(n,1);

    for i = 1:n
        chars(i) = strlength(texts{i});
        toks = local_tokenize(texts{i});
        ntoks(i) = numel(toks);
        uniq(i)  = numel(unique(toks));
    end

    d_chars = [NaN; diff(chars)];
    d_toks  = [NaN; diff(ntoks)];

    % --- Similarity Jaccard względem poprzedniej generacji ---
    jacc = NaN(n,1);
    added = NaN(n,1);
    removed = NaN(n,1);

    for i = 2:n
        a = unique(local_tokenize(texts{i-1}));
        b = unique(local_tokenize(texts{i}));

        inter = numel(intersect(a,b));
        uni   = numel(union(a,b));

        jacc(i) = inter / max(uni,1);
        added(i) = numel(setdiff(b,a));
        removed(i) = numel(setdiff(a,b));
    end

    % --- Plateau ---
    no_change = [false; d_chars(2:end)==0];
    plateau_ratio = mean(no_change);

    % Najdłuższy odcinek bez zmian
    longest_plateau = local_longest_run(no_change);

    % --- Pochodne do detekcji metawarstw ---
    slope = [NaN; diff(chars)];
    curvature = [NaN; diff(slope(2:end))];
    curvature = [NaN; NaN; curvature];

    [~, idx_max_slope] = max(slope);
    [~, idx_max_curv]  = max(curvature(3:end));
    idx_max_curv = idx_max_curv + 2;

    % --- Heurystyczne granice faz ---
    % Tu można podmienić na własną segmentację.
    phase = strings(n,1);
    for i = 1:n
        if gen_id(i) <= 8
            phase(i) = "M1_seed";
        elseif gen_id(i) <= 27
            phase(i) = "M2_accel";
        elseif gen_id(i) <= 47
            phase(i) = "M3_expand";
        elseif gen_id(i) <= 91
            phase(i) = "M4_plateau_preLOCI";
        else
            phase(i) = "M5_plateau_postLOCI";
        end
    end

    % --- Statystyki zbiorcze ---
    S = struct();
    S.n_generations = n;
    S.start_chars = chars(1);
    S.end_chars = chars(end);
    S.start_tokens = ntoks(1);
    S.end_tokens = ntoks(end);
    S.char_growth_pct = 100 * (chars(end)/chars(1) - 1);
    S.token_growth_pct = 100 * (ntoks(end)/ntoks(1) - 1);

    S.mean_dchars = mean(d_chars(2:end), 'omitnan');
    S.median_dchars = median(d_chars(2:end), 'omitnan');
    S.std_dchars = std(d_chars(2:end), 'omitnan');

    S.mean_jacc = mean(jacc(2:end), 'omitnan');
    S.median_jacc = median(jacc(2:end), 'omitnan');
    S.min_jacc = min(jacc(2:end));

    S.plateau_ratio = plateau_ratio;
    S.longest_plateau = longest_plateau;
    S.idx_max_slope = gen_id(idx_max_slope);
    S.idx_max_curvature = gen_id(idx_max_curv);

    T = table(gen_id, chars, ntoks, uniq, d_chars, d_toks, jacc, added, removed, phase);
    S.table = T;

    % --- Prosty raport ---
    fprintf('\n=== SAMPLE STRUCTURE STATS ===\n');
    fprintf('Liczba generacji: %d\n', S.n_generations);
    fprintf('Znaki: %d -> %d (%.2f%%)\n', S.start_chars, S.end_chars, S.char_growth_pct);
    fprintf('Tokeny: %d -> %d (%.2f%%)\n', S.start_tokens, S.end_tokens, S.token_growth_pct);
    fprintf('Śr. delta znaków: %.2f\n', S.mean_dchars);
    fprintf('Śr. Jaccard: %.4f\n', S.mean_jacc);
    fprintf('Plateau ratio: %.4f\n', S.plateau_ratio);
    fprintf('Najdłuższe plateau: %d generacji\n', S.longest_plateau);
    fprintf('Max slope: G%04d\n', S.idx_max_slope);
    fprintf('Max curvature: G%04d\n', S.idx_max_curvature);
end

function toks = local_tokenize(txt)
    txt = lower(string(txt));
    toks = regexp(txt, "\w+", "match");
    toks = string(toks);
end

function L = local_longest_run(mask)
    L = 0; cur = 0;
    for i = 1:numel(mask)
        if mask(i)
            cur = cur + 1;
            L = max(L, cur);
        else
            cur = 0;
        end
    end
end