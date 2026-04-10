/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module gx.tilix.terminal.types;

import gdk.Event;

/**
 * When dragging over VTE, specifies which quadrant new terminal
 * should snap to
 */
enum DragQuadrant {
    LEFT,
    TOP,
    RIGHT,
    BOTTOM
}

/**
 * The window state of the terminal
 */
enum TerminalWindowState {
    NORMAL,
    MAXIMIZED
}

enum SyncInputEventType {
    INSERT_TERMINAL_NUMBER,
    INSERT_TEXT,
    KEY_PRESS,
    RESET,
    RESET_AND_CLEAR
}

struct SyncInputEvent {
    string senderUUID;
    SyncInputEventType eventType;
    Event event;
    string text;
}

/**
 * Constants used in Event.key.sendEvent to flag particular situations
 */
enum SendEvent {
    NONE = 0,
    SYNC = 1,
    NATURAL_COPY = 2
}

/************************************************************************
 * Drag and Drop types
 ***********************************************************************/

/**
 * Constant used to identify terminal drag and drop
 */
enum VTE_DND = "vte";

/**
 * List of available Drop Targets for VTE
 */
enum DropTargets {
    URILIST,
    STRING,
    UTF8_TEXT,
    TEXT,
    COLOR,
    /**
     * Used when one VTE is dropped on another
     */
    VTE,
    /**
     * Used when session is dropped on terminal
     */
    SESSION
}

struct DragInfo {
    bool isDragActive;
    DragQuadrant dq;
}

/************************************************************************
 * Trigger types
 ***********************************************************************/

import std.regex;
import gx.tilix.preferences;

enum TriggerAction {
    UPDATE_STATE,
    EXECUTE_COMMAND,
    SEND_NOTIFICATION,
    UPDATE_TITLE,
    PLAY_BELL,
    SEND_TEXT,
    INSERT_PASSWORD,
    UPDATE_BADGE,
    RUN_PROCESS
}

/**
 * Class that holds definition of trigger including compiled regex
 */
class TerminalTrigger {

public:

    string pattern;
    TriggerAction action;
    string parameters;
    Regex!char compiledRegex;

    this(string pattern, string actionName, string parameters) {
        this.pattern = pattern;
        this.parameters = parameters;
        switch (actionName) {
            case SETTINGS_PROFILE_TRIGGER_UPDATE_STATE_VALUE:
                action = TriggerAction.UPDATE_STATE;
                break;
            case SETTINGS_PROFILE_TRIGGER_EXECUTE_COMMAND_VALUE:
                action = TriggerAction.EXECUTE_COMMAND;
                break;
            case SETTINGS_PROFILE_TRIGGER_SEND_NOTIFICATION_VALUE:
                action = TriggerAction.SEND_NOTIFICATION;
                break;
            case SETTINGS_PROFILE_TRIGGER_UPDATE_BADGE_VALUE:
                action = TriggerAction.UPDATE_BADGE;
                break;
            case SETTINGS_PROFILE_TRIGGER_UPDATE_TITLE_VALUE:
                action = TriggerAction.UPDATE_TITLE;
                break;
            case SETTINGS_PROFILE_TRIGGER_PLAY_BELL_VALUE:
                action = TriggerAction.PLAY_BELL;
                break;
            case SETTINGS_PROFILE_TRIGGER_SEND_TEXT_VALUE:
                action = TriggerAction.SEND_TEXT;
                break;
            case SETTINGS_PROFILE_TRIGGER_INSERT_PASSWORD_VALUE:
                action = TriggerAction.INSERT_PASSWORD;
                break;
            case SETTINGS_PROFILE_TRIGGER_RUN_PROCESS_VALUE:
                action = TriggerAction.RUN_PROCESS;
                break;
            default:
                break;
        }

        //Triggers always use multi-line mode since we are getting a buffer from VTE
        compiledRegex = regex(pattern, "m");
    }
}

struct TerminalTriggerMatch {
    TerminalTrigger trigger;
    string[] groups;
    size_t index;
}

/************************************************************************
 * Terminal serialization constants
 ***********************************************************************/

enum NODE_OVERRIDE_CMD = "overrideCommand";
enum NODE_BADGE = "badge";
enum NODE_TITLE = "title";
enum NODE_READONLY = "readOnly";
enum NODE_SYNCHRONIZED_INPUT = "synchronizedInput";
