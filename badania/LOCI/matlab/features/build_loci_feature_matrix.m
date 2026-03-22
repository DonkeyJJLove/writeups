function [X, featureNames, meta] = build_loci_feature_matrix(T)
% BUILD_LOCI_FEATURE_MATRIX
% Builds canonical 27D LOCI feature matrix from normalized sample series.
%
% INPUT:
%   T - struct returned by sample_norm_to_series(...)
%
% OUTPUT:
%   X            - [n x 27] numeric feature matrix
%   featureNames - 1x27 cell array
%   meta         - metadata struct

    if nargin < 1 || isempty(T)
        error('build_loci_feature_matrix:InvalidInput', ...
            'Input T is required.');
    end

    if ~isfield(T, 'count') || ~isfield(T, 'records')
        error('build_loci_feature_matrix:InvalidInput', ...
            'Input T must contain fields: count and records.');
    end

    n = T.count;
    featureNames = lc_feature_names();
    d = numel(featureNames);
    X = zeros(n, d);

    prevTokens = {};
    prevText = '';
    prevCharLen = 0;
    prevWordCount = 0;
    prevUniqueRatio = 0;

    for i = 1:n
        rec = T.records(i);

        text = lc_get_record_text(rec);

        words = regexp(text, '\S+', 'match');
        if isempty(words)
            words = {};
        end

        tokensLower = lower(words);
        charLen = length(text);
        wordCount = numel(words);
        lineCount = lc_count_lines(text);

        if isempty(words)
            avgWordLen = 0;
        else
            avgWordLen = mean(cellfun(@length, words));
        end

        uniqueRatio = lc_safe_div(numel(unique(tokensLower)), max(numel(tokensLower), 1));

        uppercaseRatio = lc_char_ratio(text, @(c) isstrprop(c, 'upper'));
        digitRatio     = lc_char_ratio(text, @(c) isstrprop(c, 'digit'));
        punctRatio     = lc_char_ratio(text, @(c) isstrprop(c, 'punct'));

        ellipsisCount    = numel(strfind(text, '...'));
        questionCount    = sum(text == '?');
        exclamationCount = sum(text == '!');
        commaCount       = sum(text == ',');

        urlCount = numel(regexp(text, 'https?://|www\.', 'match'));

        maskedEntityCount = 0;
        if isfield(rec, 'entities_masked')
            maskedEntityCount = lc_count_masked_entities(rec.entities_masked);
        end

        parentId = lc_get_record_field(rec, 'parent_entry_id', '');
        hasParent = double(~isempty(strtrim(parentId)));
        isRoot = double(~hasParent);

        entryType = lc_get_record_field(rec, 'entry_type', '');
        authorRole = lc_get_record_field(rec, 'author_role', '');

        entryTypeCode  = lc_entry_type_code(entryType);
        authorRoleCode = lc_author_role_code(authorRole);

        simVal = lc_get_record_field(rec, 'similarity_score', NaN);
        if isnumeric(simVal) && isscalar(simVal) && isfinite(simVal)
            similarityScoreSafe = double(simVal);
        else
            similarityScoreSafe = 0;
        end

        newlineDensity = lc_safe_div(sum(text == newline), max(charLen, 1));
        commaDensity   = lc_safe_div(commaCount, max(charLen, 1));

        if i == 1
            deltaCharLen = 0;
            deltaWordCount = 0;
            deltaUniqueWordRatio = 0;
            tokenJaccardPrev = 0;
            prefixOverlapPrev = 0;
            suffixOverlapPrev = 0;
            semanticExpansion = 0;
        else
            deltaCharLen = charLen - prevCharLen;
            deltaWordCount = wordCount - prevWordCount;
            deltaUniqueWordRatio = uniqueRatio - prevUniqueRatio;

            tokenJaccardPrev = lc_jaccard(tokensLower, prevTokens);
            prefixOverlapPrev = lc_prefix_overlap(text, prevText);
            suffixOverlapPrev = lc_suffix_overlap(text, prevText);

            newTokenCount = numel(setdiff(unique(tokensLower), unique(prevTokens)));
            semanticExpansion = lc_safe_div(newTokenCount, max(numel(unique(tokensLower)), 1));
        end

        X(i,:) = [ ...
            charLen, ...                 % 1
            wordCount, ...               % 2
            lineCount, ...               % 3
            avgWordLen, ...              % 4
            uniqueRatio, ...             % 5
            uppercaseRatio, ...          % 6
            digitRatio, ...              % 7
            punctRatio, ...              % 8
            ellipsisCount, ...           % 9
            questionCount, ...           % 10
            exclamationCount, ...        % 11
            urlCount, ...                % 12
            maskedEntityCount, ...       % 13
            hasParent, ...               % 14
            isRoot, ...                  % 15
            entryTypeCode, ...           % 16
            authorRoleCode, ...          % 17
            similarityScoreSafe, ...     % 18
            deltaCharLen, ...            % 19
            deltaWordCount, ...          % 20
            deltaUniqueWordRatio, ...    % 21
            tokenJaccardPrev, ...        % 22
            prefixOverlapPrev, ...       % 23
            suffixOverlapPrev, ...       % 24
            newlineDensity, ...          % 25
            commaDensity, ...            % 26
            semanticExpansion ...        % 27
        ];

        prevTokens = tokensLower;
        prevText = text;
        prevCharLen = charLen;
        prevWordCount = wordCount;
        prevUniqueRatio = uniqueRatio;
    end

    meta = struct();
    meta.sample_id = lc_get_top_field(T, 'sample_id', '');
    meta.n = n;
    meta.d = d;
    meta.feature_names = featureNames;
end

function names = lc_feature_names()
    names = { ...
        'char_len', ...
        'word_count', ...
        'line_count', ...
        'avg_word_len', ...
        'unique_word_ratio', ...
        'uppercase_ratio', ...
        'digit_ratio', ...
        'punct_ratio', ...
        'ellipsis_count', ...
        'question_count', ...
        'exclamation_count', ...
        'url_count', ...
        'masked_entity_count', ...
        'has_parent', ...
        'is_root', ...
        'entry_type_code', ...
        'author_role_code', ...
        'similarity_score_safe', ...
        'delta_char_len', ...
        'delta_word_count', ...
        'delta_unique_word_ratio', ...
        'token_jaccard_prev', ...
        'prefix_overlap_prev', ...
        'suffix_overlap_prev', ...
        'newline_density', ...
        'comma_density', ...
        'semantic_expansion_score' ...
    };
end

function v = lc_get_top_field(S, fieldName, defaultValue)
    if isstruct(S) && isfield(S, fieldName)
        v = S.(fieldName);
        if isempty(v)
            v = defaultValue;
        end
    else
        v = defaultValue;
    end
end

function v = lc_get_record_field(rec, fieldName, defaultValue)
    if isstruct(rec) && isfield(rec, fieldName)
        v = rec.(fieldName);
        if isempty(v)
            v = defaultValue;
        end
    else
        v = defaultValue;
    end

    if isstring(v)
        if isempty(v)
            v = defaultValue;
        else
            v = char(v(1));
        end
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

function n = lc_count_lines(text)
    if isempty(text)
        n = 0;
        return;
    end
    n = numel(regexp(text, '\n', 'split'));
end

function r = lc_safe_div(a, b)
    if isempty(b) || b == 0
        r = 0;
    else
        r = a / b;
    end
end

function ratio = lc_char_ratio(text, fn)
    if isempty(text)
        ratio = 0;
        return;
    end

    mask = false(1, length(text));
    for k = 1:length(text)
        mask(k) = fn(text(k));
    end

    ratio = sum(mask) / max(length(text), 1);
end

function code = lc_entry_type_code(v)
    if ~ischar(v)
        code = 0;
        return;
    end

    v = lower(strtrim(v));
    switch v
        case 'post'
            code = 1;
        case 'comment'
            code = 2;
        case 'mixed'
            code = 3;
        case 'image'
            code = 4;
        case 'link'
            code = 5;
        otherwise
            code = 0;
    end
end

function code = lc_author_role_code(v)
    if ~ischar(v)
        code = 0;
        return;
    end

    v = lower(strtrim(v));
    switch v
        case 'self'
            code = 1;
        case 'other'
            code = 2;
        case 'assistant'
            code = 3;
        otherwise
            code = 0;
    end
end

function n = lc_count_masked_entities(v)
    n = 0;

    if isempty(v)
        return;
    end

    if isstruct(v)
        f = fieldnames(v);
        for i = 1:numel(f)
            item = v.(f{i});
            if iscell(item)
                n = n + numel(item);
            elseif isstruct(item)
                n = n + numel(fieldnames(item));
            elseif ~isempty(item)
                n = n + 1;
            end
        end
    elseif iscell(v)
        n = numel(v);
    else
        n = 1;
    end
end

function j = lc_jaccard(a, b)
    if isempty(a) && isempty(b)
        j = 1;
        return;
    end

    a = unique(a);
    b = unique(b);

    inter = numel(intersect(a, b));
    uni   = numel(union(a, b));

    j = lc_safe_div(inter, max(uni, 1));
end

function r = lc_prefix_overlap(a, b)
    if isempty(a) || isempty(b)
        r = 0;
        return;
    end

    m = min(length(a), length(b));
    k = 0;
    while k < m && a(k+1) == b(k+1)
        k = k + 1;
    end

    r = lc_safe_div(k, max(m, 1));
end

function r = lc_suffix_overlap(a, b)
    if isempty(a) || isempty(b)
        r = 0;
        return;
    end

    a = fliplr(a);
    b = fliplr(b);

    m = min(length(a), length(b));
    k = 0;
    while k < m && a(k+1) == b(k+1)
        k = k + 1;
    end

    r = lc_safe_div(k, max(m, 1));
end