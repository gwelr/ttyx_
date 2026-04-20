---
title: Automatic Profile Switching
parent: Manual
nav_order: 6
layout: default
---

## Overview

ttyx_ can switch profiles automatically based on context — useful for switching users, connecting to different hosts, or marking sensitive directories. Profile changes can be triggered on any of:

* **username** — extracted from the shell prompt via a trigger
* **hostname** — reported by the shell (local, or OSC 7 from a remote)
* **current directory** — the terminal's cwd

When an automatic profile change is active, the manual profile picker is disabled so you can't accidentally override it.

## Local configuration

Configure profile switching in **Preferences → Profile → Advanced**. Each entry in the match list uses the format:

```
username@hostname:directory
```

Any one of `username`, `hostname`, or `directory` may be omitted, but at least one must be present and at least one delimiter (`@` or `:`) is required to indicate which string is which.

**Username-based switching** requires extracting the username from terminal output via a [trigger]({{ site.baseurl }}/manual/triggers/). See the Triggers page for the `Update State` action with a `username=$1` parameter.

## Remote configuration

To enable profile changes when SSHing into remote systems, the remote shell needs to report the working directory and/or hostname back to ttyx_. Two options:

### 1. Use the bundled integration script (recommended)

ttyx_ ships `/usr/share/ttyx/scripts/ttyx_int.sh`, which reports the current directory back via OSC 7 escape sequences. Copy it to the remote host and source it from your shell rc:

{% highlight bash %}
# On your local system:
scp /usr/share/ttyx/scripts/ttyx_int.sh user@remote:~/

# On the remote system, add to ~/.bashrc or ~/.zshrc:
. ~/ttyx_int.sh
{% endhighlight %}

If you switch users on the remote system, source the script somewhere available to all users (e.g. `/etc/profile.d/`) so it applies to every shell.

### 2. Configure a trigger

Alternatively, a trigger against the shell prompt can extract both username and hostname without a helper script. See the [Triggers example]({{ site.baseurl }}/manual/triggers/#example) — a regex against a `[user@host dir]$` prompt feeds the Update State action.
