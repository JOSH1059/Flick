# Security Fixes Log

This document tracks each security vulnerability found during the April 2026 audit,
the exploit scenario, why it matters, and exactly what was changed to fix it.

---

## HIGH-1: Hook Script Installed Without Integrity Verification

**File:** `buddi/Buddi/Services/Hooks/HookInstaller.swift`

**Exploit:** An attacker (or malicious process) with write access to `~/.claude/hooks/buddi-hook.py`
could replace the hook script with a malicious version. Because Buddi never verifies the
script's contents, the tampered script would execute on every Claude Code hook event with
Claude's process privileges. The attacker could:
- Silently auto-approve all tool permissions (allowing arbitrary file writes, code execution)
- Exfiltrate conversation content, file paths, and tool inputs to an external server
- Inject commands into Claude's workflow by manipulating hook responses

**Why it matters:** The hook script is the bridge between Claude Code and Buddi. It runs
in Claude's security context and can control permission decisions. A compromised hook is
equivalent to a compromised Claude Code session.

**Fix:** Added SHA-256 hash verification of the bundled `buddi-hook.py` before installation.
On every launch, the installed script's hash is compared against the bundle's hash. If they
don't match (indicating tampering or corruption), the script is replaced with the known-good
bundle copy and a warning is logged. The installed script permissions were tightened from
`0o755` (world-executable) to `0o700` (owner-only).

---

## HIGH-2: Unix Domain Socket Has No Authentication

**File:** `buddi/Buddi/Services/Hooks/HookSocketServer.swift`

**Exploit:** The socket at `/tmp/buddi.sock` accepts any connection from the same user.
A malicious process running as the same user could:
- Send crafted `PermissionRequest` events with `status: "waiting_for_approval"` to spoof
  permission dialogs
- Send fake `SessionEnd` events to clear session state
- Connect and send a fake permission response to auto-approve dangerous tool calls
- Inject false session data into the Buddi UI

**Why it matters:** The socket is the sole communication channel between Claude Code hooks
and the Buddi app. Without authentication, any same-user process can impersonate the hook
script and manipulate permission decisions.

**Fix:** Added peer credential verification using `getpeereid()` on each incoming connection
to verify the connecting process runs as the same UID. Additionally, moved the socket from
the world-writable `/tmp` directory to `~/Library/Application Support/Buddi/buddi.sock`,
which is inside a user-owned, non-world-writable directory. This provides defense in depth:
the directory restricts who can even see the socket, and `getpeereid()` validates the caller.

---

## HIGH-3: Hook Timeout of 86400 Seconds (24 Hours)

**File:** `buddi/Buddi/Services/Hooks/HookInstaller.swift`

**Exploit:** The `PermissionRequest` hook is configured with `"timeout": 86400` (24 hours).
If the hook script hangs, crashes without closing the socket, or is replaced with a malicious
version that intentionally stalls, Claude Code will be blocked for up to 24 hours waiting
for a response. This is a denial-of-service vector against the developer's workflow.

**Why it matters:** A 24-hour timeout means a single misbehaving hook can silently block
all Claude Code operations for a full workday. The user may not realize Claude is stuck
waiting on a hook response rather than processing normally.

**Fix:** Reduced the timeout from `86400` (24 hours) to `300` (5 minutes). This matches
the `TIMEOUT_SECONDS = 300` already set in the Python hook script, creating consistency.
Five minutes is long enough for a user to review and approve a permission request, but
short enough that a hung hook won't block work indefinitely.

---

## HIGH-4: Socket in World-Writable /tmp Directory

**File:** `buddi/Buddi/Services/Hooks/HookSocketServer.swift`, `buddi/Buddi/Resources/buddi-hook.py`, `buddi/Buddi/Settings/ClaudeCodeSettings.swift`

**Exploit:** `/tmp` is a world-writable directory. While the socket itself is `chmod 0o600`,
the `/tmp` directory allows any user to create files. An attacker could:
- Race condition: delete the real socket and create a fake one before Buddi starts
- Symlink attacks: create a symlink at `/tmp/buddi.sock` pointing elsewhere
- On shared systems, enumerate what sockets exist to fingerprint running applications

**Why it matters:** Placing security-sensitive IPC endpoints in world-writable directories
is a well-known anti-pattern. macOS does not namespace `/tmp` per-user.

**Fix:** Moved the socket path from `/tmp/buddi.sock` to
`~/Library/Application Support/Buddi/buddi.sock`. Updated all three references:
the server, the Python hook script, and the settings UI status check. The Application
Support directory is owned by the user and not world-writable, eliminating the
symlink/race-condition attack surface.

---

## MEDIUM-1: cmux Password Passed as CLI Argument

**File:** `buddi/Buddi/Services/Tmux/ToolApprovalHandler.swift`

**Exploit:** The cmux socket control password is passed via `--password <value>` as a
command-line argument to the `cmux` process. On macOS, any process running as the same
user can enumerate command-line arguments of all processes using `ps aux` or
`sysctl KERN_PROCARGS2`. This means:
- Any co-resident process can read the cmux password in real time
- The password may be captured in process accounting logs
- Shell history or crash reporters may capture the full command line

**Why it matters:** The cmux password controls access to terminal multiplexer sessions.
With this password, an attacker could send arbitrary keystrokes to any cmux session,
including approving dangerous tool operations or injecting commands.

**Fix:** Changed to pass the password via the `CMUX_PASSWORD` environment variable instead
of CLI arguments. Environment variables are not visible to other processes via `ps` (they
require root or same-process access to read from `/proc`). The ProcessExecutor was extended
to support an `environment` parameter for passing env vars to child processes.

---

## MEDIUM-2: NSAllowsArbitraryLoads Disables All Transport Security

**File:** `buddi/Info.plist`

**Exploit:** Setting `NSAllowsArbitraryLoads: true` disables App Transport Security (ATS)
globally, allowing the app to make unencrypted HTTP connections to any server. An attacker
on the same network could:
- Perform man-in-the-middle attacks on any HTTP connection
- Intercept data sent over unencrypted channels
- Inject malicious responses

The only legitimate HTTP use is the YouTube Music controller connecting to `localhost:26538`.

**Why it matters:** ATS exists specifically to prevent accidental unencrypted connections.
A blanket exception removes this protection entirely, even for connections that should be
encrypted (like Sparkle update checks or API calls).

**Fix:** Replaced the blanket `NSAllowsArbitraryLoads: true` with a targeted exception
for `localhost` only using `NSExceptionDomains`. All other connections will now require
HTTPS as Apple intended.

---

## MEDIUM-3: Raw Socket Data Logged Without Sanitization

**File:** `buddi/Buddi/Services/Hooks/HookSocketServer.swift`

**Exploit:** When a malformed event arrives on the socket, the raw bytes are logged with
`privacy: .public`:
```swift
logger.warning("Failed to parse event: \(String(data: data, encoding: .utf8) ?? "?", privacy: .public)")
```
This means:
- The full raw payload appears in macOS unified logs readable by other apps with log access
- If the malformed data contains sensitive content (API keys, code snippets, file paths
  from a real but malformed Claude event), it's written to persistent system logs
- An attacker could intentionally send crafted data to the socket to inject content into logs

**Why it matters:** System logs are a common target for information gathering. Logging
unsanitized external input creates an information disclosure channel.

**Fix:** Changed to log only the byte count and first 100 characters of the raw data,
with `privacy: .private` so the content is redacted in production logs. The truncation
prevents large payloads from flooding logs, and the privacy annotation ensures sensitive
content isn't exposed.

---

## MEDIUM-4: Sparkle Appcast Missing EdDSA Signature

**File:** `Updates/appcast.xml`

**Exploit:** The appcast `<enclosure>` element has no `sparkle:edSignature` attribute.
While the app has `SUPublicEDKey` configured in Info.plist, without a signature on the
enclosure, Sparkle cannot verify that the downloaded DMG is authentic. An attacker who
compromises the GitHub release or performs a CDN-level MITM could:
- Replace the DMG with a malicious version
- Sparkle would install it without signature verification

**Why it matters:** Auto-update is one of the highest-value attack vectors for desktop
apps. A compromised update silently replaces the entire application binary.

**Fix:** Added a placeholder `sparkle:edSignature` attribute to the appcast enclosure.
**IMPORTANT:** The actual signature value must be generated using Sparkle's `sign_update`
tool against the real DMG file. The placeholder serves as a reminder and structural fix.
The release process should be updated to always generate and include the EdDSA signature.

---

## LOW-1: Debug print() Statements Leak Information

**Files:** Multiple (60+ occurrences across the codebase)

**Exploit:** Bare `print()` statements output to stdout/stderr, which on macOS appears in
Console.app and the unified logging system in debug builds. These prints include:
- File paths and directory structures
- Battery and power source status
- Calendar authorization states
- WebSocket connection details
- Error messages with internal implementation details

**Why it matters:** While primarily a debug-build concern, `print()` offers no privacy
controls. In release builds distributed via DMG, some print output may still be visible
depending on how the app is launched. Using `os.Logger` with privacy annotations ensures
sensitive data is automatically redacted in production.

**Fix:** Replaced all bare `print()` calls with `os.Logger` using appropriate privacy
levels: `.public` for non-sensitive status indicators, `.private` for file paths and
error details that could reveal system structure. Each file that previously used `print()`
now has a module-level logger instance.
