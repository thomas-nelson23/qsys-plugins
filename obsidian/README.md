# Obsidian Notes plugin for Q-SYS

`Obsidian.qplug` lets a Q-SYS Core or touch panel browse, read, search and edit the notes in an Obsidian vault. It can also append lines to a note, create new notes, and keep a log note that a control script or UCI button writes to.

## How it reaches your notes (read this first)

Obsidian Sync has no public API, and its remote vaults are end-to-end encrypted by default, so nothing outside the Obsidian apps can read them ([Obsidian Sync](https://help.obsidian.md/sync), [Security and privacy](https://help.obsidian.md/sync/security)). The Core can't open a vault folder either.

So the plugin talks to a computer instead:

```
Q-SYS Core ──HTTP(S), port 27124──> Obsidian desktop app with "Local REST API with MCP" ──Obsidian Sync──> your phone, laptop, ...
```

1. A computer on your network runs the **Obsidian desktop app** with your vault open and **Obsidian Sync** turned on, as it would on any of your devices.
2. In that copy of Obsidian you install the community plugin **Local REST API with MCP** by Adam Coddington. It serves the open vault over HTTPS on the local network.
3. The Q-SYS plugin reads and writes notes through it. Obsidian then syncs every save to your other devices, and the plugin picks up changes you make elsewhere.

### What the host computer needs
- **Obsidian desktop app**, running and signed in to Sync, with the vault open. The REST API plugin is desktop only (`isDesktopOnly` in its manifest), so a phone or tablet can't be the host. The Q-SYS plugin is offline whenever Obsidian is closed or the computer is asleep, so use a machine that stays on (a home server, a mini PC, or an always-on desktop) and turn off sleep.
- **Obsidian Sync on that computer through the app**, not Obsidian Headless. Headless Sync syncs files without the app, so the REST API isn't running, and Obsidian says not to use both sync methods on one device ([Headless Sync](https://help.obsidian.md/sync/headless)).
- **Local REST API with MCP** (tested against the API of version 5.5.2; it needs Obsidian 1.13.1 or later). Install it from **Settings > Community plugins > Browse**, then enable it.
- **Binding host set to the computer's LAN address** (for example `192.168.1.20`, or `0.0.0.0` for every network interface) under **Settings > Local REST API with MCP > Advanced settings**. The default is `127.0.0.1`, which only the computer itself can reach.
- **A fixed IP address** (DHCP reservation) for the computer, and its firewall open on TCP 27124 (HTTPS) or 27123 (HTTP) for the Core's address.
- If you use HTTPS (the default): the certificate has to name the address the Core uses. The REST API's certificate authority covers `127.0.0.1`, `localhost`, the binding host and any extra names you list. If you bound to `0.0.0.0`, add the computer's IP address under **Settings > Local REST API with MCP > Certificates > Certificate hostnames**. After changing the binding host or hostnames, press **Re-generate certificates** there. The certificate authority is one the REST API creates for itself, which no device trusts by default (see "Check these on site").

**Security.** The API key gives full read and write access to the vault (everything except Obsidian's own `.obsidian` settings folder, which the REST API refuses to touch). The REST API's author says not to expose it to the internet. Keep the host and the Core on a trusted LAN or VLAN, and don't put the Setup page on a UCI that guests can reach.

## Install
1. Copy `Obsidian.qplug` to `Documents\QSC\Q-Sys Designer\Plugins`.
2. Restart Q-SYS Designer. The plugin appears under **Plugins > Productivity > Obsidian Notes**.
3. Drag it into the design. Use one instance per vault.

## Set up
1. On the host, set up the REST API as described above, then copy the **API key** from **Settings > Local REST API with MCP**.
2. On the plugin's **Setup** page, enter the computer's IP address in **Host**, leave **Mode** on **HTTPS** and **Port** on 27124, and paste the API key.
3. The status turns OK, the Online LED lights, and the **Server** panel shows the REST API and Obsidian versions and "Accepted".
4. **Save the settings in the design.** Enter Host and API Key in Designer (not while emulating) and save, so a redeploy keeps them.

If the Core can't connect over HTTPS (see below), turn on **Enable non-encrypted (HTTP) server** in the REST API settings and set **Mode** to **HTTP**. The port moves to 27123. Over HTTP the API key and your notes cross the network unencrypted.

## Pages
| Page | What it does |
|---|---|
| **Notes** | Vault browser on the left: the current folder, Up, Root and Refresh, and a list of sub-folders (ending in `/`) and notes. Pick a note to read it on the right, wrapped to the panel width, with a scroll bar. Shows the path, last modified time and line count. **Reload** reads it again. **Show on PC** opens it in Obsidian on the host. An amber LED lights when the note changed on another device while you have unsaved edits. |
| **Edit** | The open note as a numbered line list. Pick a line, change it in the box and press Enter. **Insert Above / Below**, **Duplicate**, **Delete Line**, **Move Up / Down**, **Task [ ]** (makes the line a task, or ticks and unticks it) and **Bullet -** (adds or removes the `- `). **Undo** steps back through up to 30 edits; **Revert** drops them all. **SAVE** writes the note. **Quick Append** adds a line to the end of the note at once, with an optional time stamp. |
| **Search** | Full-text search of the vault (up to 100 notes, best match first). Pick a result to open it, with the matching text shown under the list. **New Note** creates a note in a folder (the folder you're browsing by default) and opens it. It never replaces an existing note. |
| **Setup** | Host, port, HTTPS or HTTP, API key, Connect, last error, and the server's service name, plugin and Obsidian versions, key status and certificate lifetime. **Log Note** sets the note that the `LogAppend` pin writes to. |

The header on every page shows the host, the Q-SYS status (OK / Fault / Not Present / Initializing) and a cyan Online LED. Each page ends with a one-line hint bar.

**Properties:** Poll Interval (default 5 s), Note Refresh (how often the open note is checked for changes from other devices, default 10 s, 0 = off), Reader Wrap (characters per reader row, default 52), Max Note Size (larger notes open read only, default 256 KB) and Debug Print (None / Errors / All).

**Pins:** every control has a pin. Useful ones for scripts and UCIs:
- `NoteOpen` (input): a vault path such as `Home/AV system` opens that note (`.md` is added if missing).
- `NotePath` (output): the path of the open note.
- `LogAppend` (input): each string sent here is added to the Log Note as `- 2026-10-25 18:42 <text>`. For example, wire a control script that sends "Room 1 powered on".
- `Unsaved`, `RemoteChanged`, `Online` (LED outputs).

## How it works
- **Requests:** every call goes to `https://<host>:27124/...` (or `http://<host>:27123/...`) with `Authorization: Bearer <API key>`. One request is in flight at a time.
- **Status:** `GET /` every Poll Interval. It needs no key, but with the key it reports `authenticated: true` plus `versions.self`, `versions.obsidian` and `certificateInfo.validityDays`. A false `authenticated` means the key was refused.
- **Browsing:** `GET /vault/` and `GET /vault/<folder>/` return `{"files": [...]}` with sub-folders ending in `/`. The plugin shows folders and `.md` notes and hides attachments.
- **Reading:** `GET /vault/<path>` with `Accept: application/vnd.olrapi.note+json` returns the note's `content`, `stat.mtime` and `version`. The response's `ETag` is the same version token.
- **Saving:** `PUT /vault/<path>` with `Content-Type: text/markdown` and the whole note, plus `If-Match: <ETag>`. If the note changed somewhere else since it was read (for example Sync brought in an edit from your phone), the REST API answers 412 and writes nothing. The plugin then says so, and you choose **Revert** (load theirs) or **Overwrite Theirs** (press twice; saves without `If-Match`). Line endings (LF or CRLF) and the final newline are kept as they were.
- **Changes from other devices:** every Note Refresh seconds the open note is read again. If its version changed and you have no unsaved edits, the reader and line list update. If you do have unsaved edits, they are kept and the amber LED lights.
- **Appending:** `POST /vault/<path>` with the text. The REST API adds a newline first if the note doesn't end with one, and creates the note if it doesn't exist (the Log Note works this way).
- **New notes:** `PUT /vault/<folder>/<name>.md` with `If-None-Match: *`, so an existing note is never replaced (412). The new note starts with `# <name>`. Names with `\ / : * ? " < > | # ^ [ ]` are refused, as in Obsidian.
- **Search:** `POST /search/simple/?query=...&contextLength=60&maxResults=100&maxMatchesPerFile=1`. Each result has `filename` and the first match's `context`. The `Total-Results` header gives the count.
- **Show on PC:** `POST /open/<path>` opens the note in the Obsidian window on the host.
- **Paths:** each path segment is percent-encoded on its own and the `/` separators are kept, as the REST API requires (`/vault/Home/AV%20system.md`).
- **Unsaved edits are guarded:** opening another note, Reload, Revert or Create with unsaved edits asks for a second press within 5 s.

## Limitations / not tested on hardware
**This plugin has not been run on a real Q-SYS Core or against a real Obsidian install.** The logic was tested in a Lua 5.3 harness with mocked Q-SYS controls, `HttpClient`, `Timer` and `rapidjson`, against a simulated REST API built from the plugin's OpenAPI description (`docs/openapi.yaml`, version 5.5.2). The tests covered:
- missing settings, a wrong key, connecting, going offline and coming back, and switching to HTTP
- folder listing, Up, Root, notes with spaces and non-ASCII names, and the reader's wrapping and scrolling
- line edits, task and bullet toggles, insert, duplicate, delete, move, undo and revert
- saving with `If-Match`, a 412 conflict, Overwrite Theirs, and keeping CRLF line endings
- automatic refresh when the note changes elsewhere, with and without unsaved edits
- the unsaved-edits guard, Quick Append, the LogAppend pin, search, opening a result, Show on PC, and creating notes (including refusing a bad name and an existing note)

The layout previews (`preview_*.png`) are a close rendering, not a Designer screenshot.

Check these on site:
- **HTTPS certificate:** the REST API serves a certificate signed by its own certificate authority. Q-SYS's HttpClient documentation covers `https://` and TLS 1.0 to 1.3 but says nothing about certificate checks. If the Core refuses the certificate, Last Error shows the HttpClient error on every poll. Then use HTTP mode on a trusted network.
- **Editing text on a touch panel:** the line box is a Q-SYS text field, which edits one line at a time. Notes are edited line by line on purpose.
- **ListBox:** check that long notes scroll smoothly in the line list on your panel model.
- **Layout styling:** the layout uses the shared Deep Ocean theme (see [design/README.md](../design/README.md)). Check fonts, the SVG cube and the transparent LED off color in Designer.

Not included:
- **Deleting, renaming or moving notes.** Q-SYS's HttpClient documents only POST, PUT and PATCH for uploads, not DELETE, and deleting from a touch panel is risky anyway. Do it in Obsidian.
- Rendered Markdown (bold, links, images, embeds). Notes are shown as their plain Markdown text.
- Attachments, canvases, frontmatter editing, heading-targeted PATCH edits, tags, Dataview and other plugins' views.
- The REST API's event streams (server-sent events), because HttpClient can't hold a streaming connection. Polling is used instead.
- A custom **Authorization header** name in the REST API's advanced settings. Leave it at the default.

## Changelog
- 1.0: first release.

## Sources
- Local REST API with MCP, OpenAPI description (version 5.5.2): servers (HTTPS 27124, HTTP 27123), bearer authentication, `GET /`, `GET /vault/`, `GET/PUT/POST /vault/{filename}`, the note JSON format, `If-Match` and `If-None-Match`, `POST /search/simple/`, `POST /open/{filename}`, the 429 throttle for wrong keys. https://github.com/coddingtonbear/obsidian-local-rest-api/blob/main/docs/openapi.yaml (interactive version: https://coddingtonbear.github.io/obsidian-local-rest-api/)
- Local REST API with MCP, README and source (settings tab `src/main.ts`, `src/constants.ts`): the default binding host `127.0.0.1`, the Binding host, Certificate hostnames, Re-generate certificates and HTTP server settings, the name-constrained certificate authority, the `.obsidian` folder block, and how append adds a newline. https://github.com/coddingtonbear/obsidian-local-rest-api
- Obsidian Help, Obsidian Sync: what Sync is and how it syncs across devices. https://help.obsidian.md/sync
- Obsidian Help, Sync security and privacy: remote vaults are end-to-end encrypted by default. https://help.obsidian.md/sync/security
- Obsidian Help, Headless Sync: don't use desktop Sync and Headless Sync on the same device. https://help.obsidian.md/sync/headless
- Q-SYS Help, HttpClient: `Download` and `Upload` (POST, PUT, PATCH), headers, timeout, the event handler, HTTPS and TLS 1.0 to 1.3. https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/HttpClient.htm
- Q-SYS Help, plugin reserved functions: the ListBox, ComboBox and Text styles, WordWrap and VTextAlign. https://help.qsys.com/DeveloperHelp/Content/Standards_Definitions/Reserved_Functions.htm
