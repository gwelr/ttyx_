/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

module gx.util.string;

import std.string;

/**
 * Escape a string to include a CSV according to the rules expected
 * by std.csv.
 */
string escapeCSV(string value) {
    if (value.length == 0) return value;
    value = value.replace("\"", "\"\"");
    if (value.indexOf('\n') >= 0 || value.indexOf(',')  >= 0 || value.indexOf("\"\"") >= 0) {
        value = "\"" ~ value ~ "\"";
    }
    return value;
}

unittest {
    assert(escapeCSV("test") == "test");
    assert(escapeCSV("gedit \"test\"") == "\"gedit \"\"test\"\"\"");
    assert(escapeCSV("test,this is") == "\"test,this is\"");
}

/// Test: escapeCSV with empty string
unittest {
    assert(escapeCSV("") == "");
}

/// Test: escapeCSV with newline — should be quoted
unittest {
    assert(escapeCSV("line1\nline2") == "\"line1\nline2\"");
}

/// Test: escapeCSV with no special characters — no quoting needed
unittest {
    assert(escapeCSV("simple text") == "simple text");
    assert(escapeCSV("12345") == "12345");
}

/// Test: escapeCSV with only quotes — doubles them and wraps
unittest {
    // Input: " (1 char). Step 1: " → "" (2 chars). Step 2: has "" → wrap: """" (4 chars).
    // In D string literals: each \" is one quote char, so 4 quotes = "\"\"\"\""
    assert(escapeCSV("\"") == "\"\"\"\"");
}

/// Test: escapeCSV with comma and quotes combined
unittest {
    string result = escapeCSV("a,\"b\"");
    // First: " → "" gives: a,""b""
    // Then: has comma and "" → wrapped: "a,""b"""
    assert(result == "\"a,\"\"b\"\"\"");
}

/**
 * Parse a `pairSep`-delimited string of `kvSep`-separated key=value
 * pairs into a map. Whitespace around keys and values is trimmed.
 * Chunks without a `kvSep` are silently skipped. Duplicate keys: the
 * last occurrence wins.
 *
 * Example: `parsePairs("a=1;b=2")` → `["a": "1", "b": "2"]`.
 */
string[string] parsePairs(string input, string pairSep = ";", string kvSep = "=") {
    string[string] result;
    if (input.length == 0) return result;
    foreach (chunk; input.split(pairSep)) {
        ptrdiff_t idx = chunk.indexOf(kvSep);
        if (idx < 0) continue;
        string key = chunk[0 .. idx].strip();
        string value = chunk[idx + kvSep.length .. $].strip();
        result[key] = value;
    }
    return result;
}

/// Test: single and multiple pairs, default separators.
unittest {
    string[string] m = parsePairs("a=1");
    assert(m.length == 1 && m["a"] == "1");

    m = parsePairs("a=1;b=2;c=3");
    assert(m.length == 3);
    assert(m["a"] == "1" && m["b"] == "2" && m["c"] == "3");
}

/// Test: whitespace around keys and values is trimmed.
unittest {
    string[string] m = parsePairs("  a  = 1 ; b=  foo bar  ");
    assert(m["a"] == "1");
    assert(m["b"] == "foo bar"); // internal whitespace preserved
}

/// Test: chunks without a kvSep are skipped silently.
unittest {
    string[string] m = parsePairs("a=1;broken;b=2");
    assert(m.length == 2);
    assert(m["a"] == "1" && m["b"] == "2");
}

/// Test: empty input and degenerate shapes.
unittest {
    assert(parsePairs("").length == 0);
    assert(parsePairs(";;;").length == 0);
    string[string] m = parsePairs("=value");  // empty key retained
    assert(m.length == 1 && m[""] == "value");
    m = parsePairs("key=");         // empty value retained
    assert(m.length == 1 && m["key"] == "");
}

/// Test: trailing/leading separator is tolerated.
unittest {
    string[string] m = parsePairs(";a=1;b=2;");
    assert(m.length == 2);
    assert(m["a"] == "1" && m["b"] == "2");
}

/// Test: duplicate keys — last wins.
unittest {
    string[string] m = parsePairs("a=1;a=2;a=3");
    assert(m["a"] == "3");
}

/// Test: the value may itself contain `=`; only the first separator splits.
unittest {
    string[string] m = parsePairs("url=http://x.example/?q=1&r=2");
    assert(m["url"] == "http://x.example/?q=1&r=2");
}

/// Test: custom separators (non-default).
unittest {
    string[string] m = parsePairs("a:1,b:2,c:3", ",", ":");
    assert(m.length == 3);
    assert(m["a"] == "1" && m["b"] == "2" && m["c"] == "3");
}

/// Test: multi-character separators (verifies kvSep.length is used, not +1).
unittest {
    string[string] m = parsePairs("a => 1 || b => 2", "||", "=>");
    assert(m.length == 2);
    assert(m["a"] == "1" && m["b"] == "2");
}

/// Test: regression anchor — the old nested getParameters used
/// `pair.length == 2` after split("="), which dropped any input
/// containing two or more `=` characters. parsePairs preserves such
/// inputs by splitting at the first kvSep only.
unittest {
    string[string] m = parsePairs("a==b");
    assert(m.length == 1);
    assert(m["a"] == "=b");
}

/**
 * URI schemes ttyx_ is willing to hand to the desktop URI handler when a link
 * is opened. Covers the schemes the built-in link regexes produce
 * (`gx.ttyx.terminal.regex`) plus `mailto` and `file`. Anything outside this
 * set — e.g. a scriptable custom scheme delivered via an OSC 8 hyperlink — is
 * refused rather than opened blindly.
 */
immutable string[] ALLOWED_URI_SCHEMES = [
    "http", "https", "ftp", "ftps", "sftp", "file", "mailto",
    "news", "nntp", "telnet", "webcal", "sip", "sips", "h323",
];

/**
 * True if `uri`'s scheme (the text before the first `:`) is in
 * `ALLOWED_URI_SCHEMES`. Matching is case-insensitive. A URI with no scheme
 * (no `:`, or a leading `:`) is rejected.
 */
bool isAllowedUriScheme(string uri) {
    ptrdiff_t colon = uri.indexOf(':');
    if (colon <= 0) return false;
    string scheme = uri[0 .. colon].toLower;
    foreach (allowed; ALLOWED_URI_SCHEMES) {
        if (scheme == allowed) return true;
    }
    return false;
}

/// Test: allowed schemes pass, case-insensitively.
unittest {
    assert(isAllowedUriScheme("https://example.com/"));
    assert(isAllowedUriScheme("HTTP://example.com/"));
    assert(isAllowedUriScheme("mailto:user@example.com"));
    assert(isAllowedUriScheme("file:///etc/hostname"));
    assert(isAllowedUriScheme("ftp://host/f"));
    assert(isAllowedUriScheme("sips:bob@example.com"));
}

/// Test: disallowed / dangerous / scheme-less URIs are rejected.
unittest {
    assert(!isAllowedUriScheme("javascript:alert(1)"));
    assert(!isAllowedUriScheme("data:text/html,<script>"));
    assert(!isAllowedUriScheme("customhandler:do-something"));
    assert(!isAllowedUriScheme("no-scheme-here"));
    assert(!isAllowedUriScheme(":leading-colon"));
    assert(!isAllowedUriScheme(""));
}

/**
 * Return the last `maxBytes` bytes of `text`, adjusted forward to the next
 * UTF-8 lead byte so the result never begins mid-code-point. If `text` is
 * already `<= maxBytes`, it is returned unchanged.
 *
 * Used to bound the amount of terminal output fed to a user-configured
 * trigger regex: `std.regex` has no step/time limit and cannot be interrupted,
 * so a catastrophic-backtracking pattern over a very large input would hang
 * the UI thread. Keeping the tail preserves the most recent output, which is
 * what triggers care about.
 */
string boundedTail(string text, size_t maxBytes) {
    if (text.length <= maxBytes) return text;
    size_t start = text.length - maxBytes;
    // Skip UTF-8 continuation bytes (0b10xxxxxx) so we start on a code point.
    while (start < text.length && (text[start] & 0xC0) == 0x80) {
        start++;
    }
    return text[start .. $];
}

/// Test: short input is returned unchanged; long input is tailed to <= maxBytes.
unittest {
    assert(boundedTail("hello", 100) == "hello");
    assert(boundedTail("hello", 5) == "hello");
    assert(boundedTail("abcdef", 3) == "def");
}

/// Test: the tail never begins mid-code-point (valid UTF-8 out).
unittest {
    import std.utf : validate;
    // "é" is 2 bytes (0xC3 0xA9). A raw 1-byte tail would split it; boundedTail
    // must skip the continuation byte and yield valid UTF-8.
    string s = "aé";            // bytes: 'a', 0xC3, 0xA9  (length 3)
    string t = boundedTail(s, 1);
    validate(t);                // throws if invalid UTF-8
    assert(t == "");            // continuation byte skipped past end
    string u = boundedTail(s, 2);
    validate(u);
    assert(u == "é");
}