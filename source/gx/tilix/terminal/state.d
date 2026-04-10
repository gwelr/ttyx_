/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module gx.tilix.terminal.state;

private:

import std.conv;
import std.experimental.logger;

import core.sys.posix.unistd : gethostname;

package:

/// Struct for remembering terminal state, used to track local and remote (i.e. SSH) states.
struct TerminalState {
    /// Current hostname (local machine or SSH remote).
    string hostname;
    /// Current working directory.
    string directory;
    /// Current username.
    string username;

    /// Reset all fields to empty.
    void clear() {
        hostname.length = 0;
        directory.length = 0;
        username.length = 0;
    }

    /// Returns true if any field has been set.
    bool hasState() {
        return (hostname.length > 0 || directory.length > 0 || username.length > 0);
    }
}

/// Distinguishes local vs remote terminal state.
enum TerminalStateType {LOCAL, REMOTE}

/// Tracks local and remote hostname/directory/username for a terminal.
class GlobalTerminalState {
private:
    TerminalState local;
    TerminalState remote;
    string _localHostname;
    string _initialCWD;
    bool _initialized = false;

    void updateHostname(string hostname) {
        if (hostname.length > 0 && hostname != _localHostname) {
            if (remote.hostname != hostname) {
                remote.hostname = hostname;
                remote.username.length = 0;
                remote.directory.length = 0;
            }
        } else {
            local.hostname = hostname;
            remote.clear();
        }
        if (!_initialized) updateState();
    }

    void updateDirectory(string directory) {
        if (remote.hasState()) {
            remote.directory = directory;
        } else {
            local.directory = directory;
        }
        if (directory.length > 0 && !_initialized) updateState();
    }

    void updateUsername(string username) {
        if (remote.hasState()) {
            remote.username = username;
        } else {
            local.username = username;
        }
        if (username.length > 0 && !_initialized) updateState();
    }

public:

    enum StateVariable {
        HOSTNAME = "hostname",
        USERNAME = "username",
        DIRECTORY = "directory"
    }

    this() {
        //Get local hostname to detect difference between remote and local
        char[1024] systemHostname;
        if (gethostname(cast(char*)&systemHostname, 1024) == 0) {
            _localHostname = to!string(cast(char*)&systemHostname);
            trace("Local Hostname: " ~ _localHostname);
        }
    }

    void clear() {
        local.clear();
        remote.clear();
    }

    TerminalState getState(TerminalStateType type) {
        final switch (type) {
            case TerminalStateType.LOCAL: return local;
            case TerminalStateType.REMOTE: return remote;
        }
    }

    bool hasState(TerminalStateType type) {
        final switch (type) {
            case TerminalStateType.LOCAL: return local.hasState();
            case TerminalStateType.REMOTE: return remote.hasState();
        }
    }

    void updateState() {
        if (!_initialized) {
            _initialized = true;
            trace("Terminal in initialized state");
        }
    }

    void updateState(StateVariable variable, string value) {
        final switch (variable) {
            case StateVariable.HOSTNAME:
                updateHostname(value);
                break;
            case StateVariable.USERNAME:
                updateUsername(value);
                break;
            case StateVariable.DIRECTORY:
                updateDirectory(value);
                break;
        }
    }

    void updateState(string hostname, string directory) {
        //Is this a remote host?
        if (hostname.length > 0 && hostname != localHostname) {
            remote.hostname = hostname;
            remote.directory = directory;
        } else {
            local.hostname = hostname;
            local.directory = directory;
            remote.clear();
        }
        if (directory.length > 0) {
            updateState();
        }
        tracef("Current directory changed, hostname '%s', directory '%s'", currentHostname, currentDirectory);
    }

    /**
     * if Remote is set returns that otherwise returns local
     */
    @property string currentHostname() {
        if (remote.hasState()) return remote.hostname;
        return local.hostname;
    }

    /**
     * if Remote is set returns that otherwise returns local
     */
    @property string currentDirectory() {
        if (remote.hasState()) return remote.directory;
        return local.directory;
    }

    @property string currentUsername() {
        if (remote.hasState()) return remote.username;
        return local.username;
    }

    @property string currentLocalDirectory() {
        return local.directory;
    }

    @property string initialCWD() {
        return _initialCWD;
    }

    @property void initialCWD(string value) {
        _initialCWD = value;
    }

    @property bool initialized() {
        return _initialized;
    }

    @property string localHostname() {
        return _localHostname;
    }
}
