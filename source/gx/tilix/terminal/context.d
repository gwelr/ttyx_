/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module gx.tilix.terminal.context;

private:

import gio.Settings : GSettings = Settings;

import gtk.Widget;

import gx.tilix.terminal.exvte;
import gx.tilix.terminal.state;
import gx.tilix.terminal.types;

package:

/**
 * Interface providing access to shared terminal state.
 *
 * Components extracted from the Terminal god class use this interface
 * to access the VTE widget, settings, and terminal identity without
 * depending on the Terminal class directly. This enables:
 * - Independent testing of components with mock contexts
 * - Clear contracts for what state each component needs
 * - Easier migration to gid bindings (each component ports independently)
 */
interface ITerminalContext {

    /// The VTE terminal widget
    @property ExtendedVTE contextVte();

    /// Global application settings (com.gexperts.Tilix)
    @property GSettings contextGsSettings();

    /// Per-profile settings
    @property GSettings contextGsProfile();

    /// Keyboard shortcut settings
    @property GSettings contextGsShortcuts();

    /// Terminal state tracker (hostname, directory, local vs remote)
    @property GlobalTerminalState terminalState();

    /// Unique identifier for this terminal instance
    @property string terminalUUID();

    /// The toplevel GTK window containing this terminal.
    @property Widget toplevelWidget();
}

/**
 * Interface for broadcasting synchronized input across terminal panes.
 *
 * When synchronized input is active, actions in one terminal (keypress,
 * paste, text insertion) are replicated to all other terminals in the
 * same session. Components that produce input use this interface to
 * broadcast their events without depending on Terminal directly.
 */
interface ISyncInputEmitter {

    /// Whether synchronized input is currently active for this terminal.
    @property bool isSynchronizedInput();

    /// Broadcast a sync input event to all other synchronized terminals.
    void emitSyncInput(SyncInputEvent event);
}
