/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

module gx.util.redact;

import std.regex : regex, replaceAll;
import std.string : indexOf, toLower;

enum string REDACTED = "[redacted]";

private immutable string[] SENSITIVE_KEY_FRAGMENTS = [
    "password", "passwd", "token", "secret", "api_key", "apikey",
    "auth", "credential",
];

private immutable string[] PROXY_KEY_FRAGMENTS = [
    "proxy",
];

/**
 * Redact sensitive portions of an environment variable value for logging.
 *
 * - Keys containing a password/token/secret/auth fragment have the whole
 *   value replaced with a placeholder.
 * - Keys containing "proxy" have the userinfo segment of any URL-shaped
 *   value stripped, keeping `scheme://host[:port]/...` so the log remains
 *   useful for debugging connectivity.
 * - Other keys pass through unchanged.
 *
 * Matching is case-insensitive and fragment-based: both `HTTP_PROXY` and
 * `http_proxy`, both `API_TOKEN` and `apikey`, are recognized.
 */
string redactSensitive(string key, string value) {
    if (value.length == 0) return value;

    string lowerKey = key.toLower;

    foreach (fragment; SENSITIVE_KEY_FRAGMENTS) {
        if (lowerKey.indexOf(fragment) >= 0) return REDACTED;
    }

    foreach (fragment; PROXY_KEY_FRAGMENTS) {
        if (lowerKey.indexOf(fragment) >= 0) return stripUrlUserinfo(value);
    }

    return value;
}

/**
 * Remove the userinfo segment (user:password@) from any URL-shaped
 * substring. The regex is unanchored so strings containing embedded URLs
 * (e.g. command lines like `psql postgresql://u:p@h/d`) are sanitized
 * too, not only strings that are URLs themselves. Inputs with no URL
 * match are returned verbatim.
 */
string stripUrlUserinfo(string input) {
    // `[^/\s]+@` with greedy backtracking captures up to the last `@`
    // that precedes `/` or whitespace, so unescaped `@` inside a password
    // (e.g. http://user:p@ss@host/) doesn't leak past the stripping.
    static auto re = regex(r"([a-zA-Z][a-zA-Z0-9+.-]*://)[^/\s]+@");
    return input.replaceAll(re, "$1");
}

// -- tests --------------------------------------------------------------

unittest {
    assert(redactSensitive("PATH", "/usr/bin:/bin") == "/usr/bin:/bin");
    assert(redactSensitive("HOME", "/home/user") == "/home/user");
    assert(redactSensitive("SHELL", "/bin/bash") == "/bin/bash");
}

unittest {
    assert(redactSensitive("PASSWORD", "hunter2") == REDACTED);
    assert(redactSensitive("MY_PASSWD", "x") == REDACTED);
    assert(redactSensitive("API_TOKEN", "abcd") == REDACTED);
    assert(redactSensitive("github_token", "ghp_...") == REDACTED);
    assert(redactSensitive("CLIENT_SECRET", "shh") == REDACTED);
    assert(redactSensitive("API_KEY", "k") == REDACTED);
    assert(redactSensitive("BASIC_AUTH", "dXNlcjpwdw==") == REDACTED);
}

unittest {
    // Empty value: no-op even for sensitive keys.
    assert(redactSensitive("PASSWORD", "") == "");
}

unittest {
    // Proxy URL with credentials: userinfo is stripped, host/port retained.
    assert(redactSensitive("http_proxy", "http://user:pw@proxy.local:8080/")
        == "http://proxy.local:8080/");
    assert(redactSensitive("HTTPS_PROXY", "https://alice:secret@proxy.corp:3128/")
        == "https://proxy.corp:3128/");
    assert(redactSensitive("all_proxy", "socks://u:p@s.example:1080/")
        == "socks://s.example:1080/");
}

unittest {
    // Proxy URL without credentials is preserved as-is.
    assert(redactSensitive("http_proxy", "http://proxy.local:8080/")
        == "http://proxy.local:8080/");
    // no_proxy is a comma list, not a URL — must not be mangled.
    assert(redactSensitive("no_proxy", "localhost,127.0.0.1,.corp")
        == "localhost,127.0.0.1,.corp");
}

unittest {
    // Non-URL value with a proxy-shaped key is returned untouched by the
    // strip (no regex match), so the fragment policy degrades safely.
    assert(stripUrlUserinfo("not-a-url") == "not-a-url");
    assert(stripUrlUserinfo("") == "");
    assert(stripUrlUserinfo("http://host/path") == "http://host/path");
}

unittest {
    // URL embedded in a larger string — e.g. an argv with a command.
    assert(stripUrlUserinfo("psql postgresql://alice:secret@db.corp/app")
        == "psql postgresql://db.corp/app");
    assert(stripUrlUserinfo("curl -u x https://u:p@api.example.com/path things after")
        == "curl -u x https://api.example.com/path things after");
}

unittest {
    // Multiple URLs in the same string: every occurrence is sanitized.
    assert(stripUrlUserinfo("from http://a:b@h1/ to https://c:d@h2/")
        == "from http://h1/ to https://h2/");
}

unittest {
    // Unescaped `@` inside the password: greedy backtracking strips
    // up to the last `@` before the host boundary, not the first.
    assert(stripUrlUserinfo("http://user:p@ss@host.example/path")
        == "http://host.example/path");
    assert(stripUrlUserinfo("https://a@b@c@host/")
        == "https://host/");
}

unittest {
    // An email-like token near a URL must not be confused with userinfo.
    // The `@` is separated by whitespace, so the regex cannot span it.
    assert(stripUrlUserinfo("URL http://site/ contact admin@co.com")
        == "URL http://site/ contact admin@co.com");
    assert(stripUrlUserinfo("admin@co.com") == "admin@co.com");
}

unittest {
    // Non-http(s) schemes with userinfo are sanitized too.
    assert(stripUrlUserinfo("ftp://u:p@ftp.example.com/file")
        == "ftp://ftp.example.com/file");
    assert(stripUrlUserinfo("git://dev:token@git.internal/repo.git")
        == "git://git.internal/repo.git");
}
