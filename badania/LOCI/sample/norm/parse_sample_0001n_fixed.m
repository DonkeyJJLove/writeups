function data = parse_sample_0001n_fixed(filename)
%PARSE_SAMPLE_0001N_FIXED Parse Sample_0001N-like text safely.
%   DATA = PARSE_SAMPLE_0001N_FIXED(FILENAME) reads the file and returns:
%     data.meta    - struct with header metadata
%     data.entries - struct array with fields: id, date, type, text, eot
%
%   The important fix is that the parser DOES NOT cut at the first '('
%   in the whole line. First it extracts the initial quoted block after
%   Gxxxx:, then it handles only a leading parenthetical tail that appears
%   AFTER the closing quote. This avoids premature splitting when the text
%   itself contains parentheses.
%
%   Example supported forms:
%     G0001: "text with (parentheses)"
%     G0002: "text" (dopisek)
%     G0015: "text" (dopisek) dalszy ciąg
%
%   If you want only the cleaned texts:
%     data = parse_sample_0001n_fixed('Sample_0001n.m');
%     texts = string({data.entries.text}).';

    if nargin < 1 || strlength(string(filename)) == 0
        filename = "Sample_0001n.m";
    end

    raw = fileread(filename);
    lines = splitlines(string(raw));

    meta = struct();
    entries = struct('id', {}, 'date', {}, 'type', {}, 'text', {}, 'eot', {});

    currentDate = "";
    currentType = "";

    for i = 1:numel(lines)
        line = strtrim(lines(i));
        if line == ""
            continue;
        end

        if startsWith(line, "DATE:")
            currentDate = strtrim(extractAfter(line, "DATE:"));
            continue;
        end

        if startsWith(line, "TYPE:")
            currentType = strtrim(extractAfter(line, "TYPE:"));
            continue;
        end

        genTok = regexp(char(line), '^(G\d{4}):', 'tokens', 'once');
        if ~isempty(genTok)
            [gid, gtext, geot] = parseGenerationLine(line);
            entries(end+1) = struct( ...
                'id',   gid, ...
                'date', currentDate, ...
                'type', currentType, ...
                'text', gtext, ...
                'eot',  geot); %#ok<AGROW>
            continue;
        end

        % Header metadata: KEY: value
        kv = regexp(char(line), '^(?<key>[A-Z_]+):\s*(?<val>.*)$', 'names', 'once');
        if ~isempty(kv)
            key = matlab.lang.makeValidName(lower(kv.key));
            meta.(key) = string(strtrim(kv.val));
        end
    end

    data = struct('meta', meta, 'entries', entries);
end

function [gid, text, eot] = parseGenerationLine(line)
% Parse a single Gxxxx line.
%
% Strategy:
%   1) Take ONLY the first quoted block after Gxxxx:
%   2) Everything after that quote is a tail.
%   3) If the tail starts with a balanced parenthetical block, convert that
%      first block into ' - ...'.
%   4) Append the remaining tail unchanged.
%
% This prevents the parser from cutting too early when '(' appears inside
% the quoted text or later inside the tail.

    gid = "";
    text = "";
    eot = false;

    line = string(line);

    tok = regexp(char(line), ...
        '^(?<id>G\d{4}):\s*"(?<quoted>[^"]*)"(?<tail>.*)$', ...
        'names', 'once');

    if isempty(tok)
        % Fallback for odd lines without the initial quoted block.
        tok2 = regexp(char(line), '^(?<id>G\d{4}):\s*(?<rest>.*)$', 'names', 'once');
        if isempty(tok2)
            return;
        end
        gid = string(tok2.id);
        text = strtrim(string(tok2.rest));
        [text, eot] = stripEOT(text);
        return;
    end

    gid    = string(tok.id);
    quoted = strtrim(string(tok.quoted));
    tail   = strtrim(string(tok.tail));

    text = quoted;

    if strlength(tail) > 0
        if startsWith(tail, "(")
            [parenText, restTail] = extractLeadingBalancedParen(tail);
            if strlength(parenText) > 0
                if strlength(text) > 0
                    text = strtrim(text + " - " + strtrim(parenText));
                else
                    text = strtrim(parenText);
                end
                if strlength(strtrim(restTail)) > 0
                    text = strtrim(text + " " + strtrim(restTail));
                end
            else
                text = appendWithSpace(text, tail);
            end
        else
            text = appendWithSpace(text, tail);
        end
    end

    [text, eot] = stripEOT(text);
end

function [inside, rest] = extractLeadingBalancedParen(s)
% Extract ONLY the first balanced parenthetical block at the start of S.
% Example:
%   '(abc) def' -> inside='abc', rest='def'
%   '(abc (x)) def' -> inside='abc (x)', rest='def'

    s = char(string(s));
    inside = "";
    rest = string(strtrim(s));

    if isempty(s) || s(1) ~= '('
        return;
    end

    depth = 0;
    stopIdx = 0;

    for k = 1:numel(s)
        ch = s(k);
        if ch == '('
            depth = depth + 1;
        elseif ch == ')'
            depth = depth - 1;
            if depth == 0
                stopIdx = k;
                break;
            end
        end
    end

    if stopIdx == 0
        return;
    end

    if stopIdx > 2
        inside = string(strtrim(s(2:stopIdx-1)));
    else
        inside = "";
    end

    if stopIdx < numel(s)
        rest = string(strtrim(s(stopIdx+1:end)));
    else
        rest = "";
    end
end

function out = appendWithSpace(a, b)
    a = strtrim(string(a));
    b = strtrim(string(b));

    if strlength(a) == 0
        out = b;
    elseif strlength(b) == 0
        out = a;
    else
        out = a + " " + b;
    end
end

function [text, eot] = stripEOT(text)
    text = string(text);
    eot = ~isempty(regexp(char(text), '\[eot\]\s*$', 'once'));
    text = string(regexprep(char(text), '\s*\[eot\]\s*$', ''));
    text = strtrim(text);
end
