function [X, featureNames, meta] = build_loci_feature_matrix(T)
% BUILD_LOCI_FEATURE_MATRIX
% Canonical 27D feature builder for LOCI textual samples.
%
% INPUT:
%   T : struct returned by sample_norm_to_series()
%
% OUTPUT:
%   X            : [N x 27] numeric feature matrix
%   featureNames : 1x27 cell array
%   meta         : struct with metadata
%
% NOTES:
% - avoids MATLAB count() conflicts
% - robust to empty/missing fields
% - works on normalized text stream entries
%
% 27 FEATURES:
%   01 char_len
%   02 word_count
%   03 line_count
%   04 avg_word_len
%   05 unique_word_ratio
%   06 uppercase_ratio
%   07 digit_ratio
%   08 punct_ratio
%   09 ellipsis_count
%   10 question_count
%   11 exclamation_count
%   12 url_count
%   13 masked_entity_count
%   14 has_parent
%   15 is_root
%   16 entry_type_code
%   17 author_role_code
%   18 similarity_score_safe
%   19 delta_char_len
%   20 delta_word_count
%   21 delta_unique_word_ratio
%   22 token_jaccard_prev
%   23 prefix_overlap_prev
%   24 suffix_overlap_prev
%   25 newline_density
%   26 comma_density
%   27 semantic_expansion_score

    if nargin < 1 || isempty(T)
        error('build_loci_feature_matrix:InvalidInput', ...
            'Input T is required.');
    end

    if ~isfield(T, 'count') || ~isfield(T, 'records')
        error('build_loci_feature_matrix:InvalidInput', ...
            'Input T must contain fields: count, records.');
    end

    n = double(T.count);
    if n <= 0
        X = zeros(0, 27);
        featureNames = lc_feature_names();
        meta = struct( ...
            'sample_id', '', ...
            'n', 0, ...
            'd', 27, ...
            'feature_names', {featureNames});
        return;
    end

    featureNames = lc_feature_names();
    d = numel(featureNames);
    X = zeros(n, d);

    prevTokens = {};
    prevCharLen = 0;
    prevWordCount = 0;
    prevUniqueRatio = 0;

    for i = 1:n
        rec = T.records(i);

        text = lc_get_text(rec);
        textLen = length(text);

        tokens = lc_tokenize(text);
        wordCount = numel(tokens);
        lineCount = lc_count_lines(text);
        avgWordLen = lc_avg_word_len(tokens);
        uniqueWordRatio = lc_unique_word_ratio(tokens);

        uppercaseRatio = lc_uppercase_ratio(text);
        digitRatio = lc_digit_ratio(text);
        punctRatio = lc_punct_ratio(text);

        ellipsisCount = lc_substr_count(text, '...');
        questionCount = lc_char_count(text, '?');
        exclamationCount = lc_char_count(text, '!');

        urlCount = lc_url_count(text);
        maskedEntityCount = lc_masked_entity_count(rec);

        parentEntryId = lc_get_field(rec, 'parent_entry_id', '');
        hasParent = double(~isempty(strtrim(parentEntryId)));
        isRoot = double(hasParent == 0);

        entryType = lc_get_field(rec, 'entry_type', '');
        entryTypeCode = lc_entry_type_code(entryType);

        authorRole = lc_get_field(rec, 'author_role', '');
        authorRoleCode = lc_author_role_code(authorRole);

        simVal = lc_get_field(rec, 'similarity_score', NaN);
        similarityScoreSafe = lc_safe_similarity(simVal);

        deltaCharLen = textLen - prevCharLen;
        deltaWordCount = wordCount - prevWordCount;
        deltaUniqueWordRatio = uniqueWordRatio - prevUniqueRatio;

        tokenJaccardPrev = lc_token_jaccard(prevTokens, tokens);
        prefixOverlapPrev = lc_prefix_overlap(prevTokens, tokens);
        suffixOverlapPrev = lc_suffix_overlap(prevTokens, tokens);

        newlineDensity = lc_density(text, sprintf('\n'));
        commaDensity = lc_density(text, ',');

        semanticExpansionScore = ...
            0.40 * max(deltaUniqueWordRatio, 0) + ...
            0.30 * tokenJaccardPrev + ...
            0.20 * min(wordCount / 100, 1) + ...
            0.10 * min(urlCount, 3) / 3;

        X(i, :) = [ ...
            textLen, ...
            wordCount, ...
            lineCount, ...
            avgWordLen, ...
            uniqueWordRatio, ...
            uppercaseRatio, ...
            digitRatio, ...
            punctRatio, ...
            ellipsisCount, ...
            questionCount, ...
            exclamationCount, ...
            urlCount, ...
            maskedEntityCount, ...
            hasParent, ...
            isRoot, ...
            entryTypeCode, ...
            authorRoleCode, ...
            similarityScoreSafe, ...
            deltaCharLen, ...
            deltaWordCount, ...
            deltaUniqueWordRatio, ...
            tokenJaccardPrev, ...
            prefixOverlapPrev, ...
            suffixOverlapPrev, ...
            newlineDensity, ...
            commaDensity, ...
            semanticExpansionScore ...
        ];

        prevTokens = tokens;
        prevCharLen = textLen;
        prevWordCount = wordCount;
        prevUniqueRatio = uniqueWordRatio;
    end

    sampleId = '';
    if isfield(T, 'sample_id')
        sampleId = T.sample_id;
    end

    meta = struct();
    meta.sample_id = sampleId;
    meta.n = n;
    meta.d = d;
    meta.feature_names = featureNames;
end

% =========================================================================
% FEATURE NAMES
% =========================================================================
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

% =========================================================================
% RECORD / FIELD HELPERS
% =========================================================================
function value = lc_get_field(s, fieldName, defaultValue)
    if isstruct(s) && isfield(s, fieldName)
        value = s.(fieldName);
        if isempty(value)
            value = defaultValue;
        end
    else
        value = defaultValue;
    end
end

function text = lc_get_text(rec)
    if isfield(rec, 'content_norm') && ~isempty(rec.content_norm)
        text = rec.content_norm;
    elseif isfield(rec, 'content_display') && ~isempty(rec.content_display)
        text = rec.content_display;
    else
        text = '';
    end

    if isstring(text)
        text = char(text);
    end
    if ~ischar(text)
        text = '';
    end
end

% =========================================================================
% TEXT BASICS
% =========================================================================
function tokens = lc_tokenize(text)
    if isempty(text)
        tokens = {};
        return;
    end

    text = lower(text);
    tokens = regexp(text, '[\p{L}\p{N}_\-]+', 'match');

    if isempty(tokens)
        tokens = {};
    end
end

function n = lc_count_lines(text)
    if isempty(text)
        n = 0;
        return;
    end
    parts = regexp(text, '\n', 'split');
    n = numel(parts);
end

function v = lc_avg_word_len(tokens)
    if isempty(tokens)
        v = 0;
        return;
    end
    lens = cellfun(@length, tokens);
    v = mean(lens);
end

function v = lc_unique_word_ratio(tokens)
    if isempty(tokens)
        v = 0;
        return;
    end
    v = numel(unique(tokens)) / numel(tokens);
end

function v = lc_uppercase_ratio(text)
    if isempty(text)
        v = 0;
        return;
    end

    letters = regexp(text, '[A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]', 'match');
    if isempty(letters)
        v = 0;
        return;
    end

    uppers = regexp(text, '[A-ZĄĆĘŁŃÓŚŹŻ]', 'match');
    v = numel(uppers) / numel(letters);
end

function v = lc_digit_ratio(text)
    if isempty(text)
        v = 0;
        return;
    end
    digits = regexp(text, '\d', 'match');
    v = numel(digits) / max(length(text), 1);
end

function v = lc_punct_ratio(text)
    if isempty(text)
        v = 0;
        return;
    end
    punct = regexp(text, '[[:punct:]]', 'match');
    v = numel(punct) / max(length(text), 1);
end

function n = lc_substr_count(text, pattern)
    if isempty(text)
        n = 0;
        return;
    end
    matches = strfind(text, pattern); %#ok<STRIFCND>
    n = numel(matches);
end

function n = lc_char_count(text, ch)
    if isempty(text)
        n = 0;
        return;
    end
    n = sum(text == ch);
end

function n = lc_url_count(text)
    if isempty(text)
        n = 0;
        return;
    end
    urls = regexp(text, 'https?://\S+|www\.\S+|github\.com/\S+', 'match');
    n = numel(urls);
end

function n = lc_masked_entity_count(rec)
    n = 0;

    if ~isfield(rec, 'entities_masked')
        return;
    end

    em = rec.entities_masked;

    if isstruct(em)
        fn = fieldnames(em);
        for k = 1:numel(fn)
            val = em.(fn{k});
            if ischar(val) || isstring(val)
                if ~isempty(val)
                    n = n + 1;
                end
            elseif iscell(val)
                n = n + numel(val);
            elseif isnumeric(val) || islogical(val)
                n = n + numel(val);
            elseif isstruct(val)
                n = n + numel(fieldnames(val));
            end
        end
    elseif iscell(em)
        n = numel(em);
    end
end

% =========================================================================
% CODEC FEATURES
% =========================================================================
function code = lc_entry_type_code(s)
    s = lc_to_lower_char(s);

    switch s
        case {'text'}
            code = 1;
        case {'link'}
            code = 2;
        case {'mixed'}
            code = 3;
        case {'image'}
            code = 4;
        case {'video'}
            code = 5;
        otherwise
            code = 0;
    end
end

function code = lc_author_role_code(s)
    s = lc_to_lower_char(s);

    switch s
        case {'self'}
            code = 1;
        case {'assistant'}
            code = 2;
        case {'other'}
            code = 3;
        otherwise
            code = 0;
    end
end

function out = lc_safe_similarity(v)
    if isempty(v)
        out = 0;
        return;
    end

    if ischar(v) || isstring(v)
        vv = str2double(v);
    else
        vv = double(v);
    end

    if isempty(vv) || ~isfinite(vv)
        out = 0;
    else
        out = vv;
    end
end

function s = lc_to_lower_char(v)
    if isstring(v)
        if isempty(v)
            s = '';
            return;
        end
        s = lower(char(v(1)));
        return;
    end

    if ischar(v)
        s = lower(v);
        return;
    end

    s = '';
end

% =========================================================================
% RELATIONAL / DELTA FEATURES
% =========================================================================
function v = lc_token_jaccard(a, b)
    if isempty(a) && isempty(b)
        v = 0;
        return;
    end

    ua = unique(a);
    ub = unique(b);

    inter = intersect(ua, ub);
    uni = union(ua, ub);

    if isempty(uni)
        v = 0;
    else
        v = numel(inter) / numel(uni);
    end
end

function v = lc_prefix_overlap(a, b)
    if isempty(a) || isempty(b)
        v = 0;
        return;
    end

    m = min(numel(a), numel(b));
    k = 0;
    for i = 1:m
        if strcmp(a{i}, b{i})
            k = k + 1;
        else
            break;
        end
    end
    v = k / m;
end

function v = lc_suffix_overlap(a, b)
    if isempty(a) || isempty(b)
        v = 0;
        return;
    end

    ar = a(end:-1:1);
    br = b(end:-1:1);

    m = min(numel(ar), numel(br));
    k = 0;
    for i = 1:m
        if strcmp(ar{i}, br{i})
            k = k + 1;
        else
            break;
        end
    end
    v = k / m;
end

function v = lc_density(text, token)
    if isempty(text)
        v = 0;
        return;
    end

    if strcmp(token, sprintf('\n'))
        c = sum(text == sprintf('\n'));
    else
        c = sum(text == token);
    end

    v = c / max(length(text), 1);
end