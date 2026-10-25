# Hermes Agent plugin for Q-SYS

`Hermes.qplug` connects Q-SYS to a **Hermes Agent** (the open-source agent from Nous Research) running on a computer on the
same network. Type a prompt or press a preset on a touch panel, and the plugin sends it to the agent and shows the answer in a
scrolling conversation view. Hermes can run tools before it answers, so the plugin follows each turn as it works. You can stop
it, add guidance while it is still working, and approve or deny tool calls that Hermes asks permission for.

## Which Hermes this is for
This plugin targets **Hermes Agent** by Nous Research (https://hermes-agent.nousresearch.com), through its built-in
**API server**. The agent can use any model Hermes is set up with: Nous Portal, OpenRouter, or a local model served by Ollama,
llama.cpp, vLLM and so on, including the Hermes models. The plugin always talks to the agent, never to the model server
directly, so the agent's tools, memory and skills stay in use.

It does not talk to a bare model server (an Ollama or llama.cpp OpenAI endpoint with no agent). Those have no Runs API, so the
Setup page shows "No API" or a 404. Run Hermes Agent in front of the model server instead.

## Install
1. Copy `Hermes.qplug` to `Documents\QSC\Q-Sys Designer\Plugins`.
2. Restart Q-SYS Designer. The plugin appears under **Plugins > AI > Hermes Agent**.
3. Drag it into the design. Use one instance per Hermes agent (or per Hermes profile).

## Set up the agent
On the computer running Hermes Agent, add these lines to `~/.hermes/.env` (from the Hermes API Server docs):

```bash
API_SERVER_ENABLED=true
API_SERVER_KEY=<a long random string>
API_SERVER_HOST=0.0.0.0        # or the computer's LAN IP; the default 127.0.0.1 can't be reached from the Core
# API_SERVER_PORT=8642         # default
```

Then start the gateway with `hermes gateway` and leave it running (as a service, or in tmux or screen). It prints
`API server listening on http://...:8642`. Allow TCP 8642 through the computer's firewall from the Core's IP only.

**Security:** the API server gives full access to the agent's tools, including terminal commands, and anything that reaches
the port with the key can use them. When the server is reachable from the network and the terminal backend is the local,
unsandboxed one, Hermes logs a warning that suggests a sandboxed backend (`terminal.backend: docker`) and firewalling the port
to trusted networks. Do both before you put a prompt field on a touch panel. Commands that Hermes flags for approval come back
to the panel's **Tool Approval** box for a decision.

## Set up the plugin
1. On the **Setup** page, enter the agent computer's IP (or host name) as **Host**, and the `API_SERVER_KEY` as **API Key**.
   Type them in Designer and save the design, so a re-deploy doesn't clear them.
2. Leave **Profile** blank for the default Hermes profile. If Hermes runs several profiles on one gateway
   (`gateway.multiplex_profiles`), type the profile name. The plugin then uses `/p/<profile>/` and needs that profile's own key.
3. Leave **Model** and **Provider** blank to use the agent's configured model. Fill them to pick another model for turns
   sent from this plugin, for example Model `hermes-4-70b` and Provider `ollama`. Hermes always honors these on the Runs API.
4. Press **Connect / Refresh**. The header shows **Ready** and the Online LED lights. **Features** should read
   `Runs yes  Stop yes  Steer yes  Approvals yes`.
5. Optional: on the **Prompts** page, set up to 8 preset buttons and the **Instructions** line (for example "You are the AV
   assistant for the Boardroom. Keep answers under 80 words.").

## Pages
| Page | What it does |
|---|---|
| **Chat** | The conversation: your prompts (`>`), Hermes' answers, guidance you added while it worked (`+`), questions Hermes asks (`?`), approval requests (`!`) and notes (`*`). 16 lines with a scroll bar, newest at the bottom. The state line shows Queued, Working (with what it is doing: using a tool, writing the answer, delegating), Waiting for approval, Done, Stopped or the error, plus the turn time. **SEND** sends the prompt. **Stop** interrupts the turn. **New Chat** starts a new conversation. **Tool Approval** shows what Hermes wants to run, with **Approve Once**, **Approve for Session** (only when Hermes offers it) and **Deny**. |
| **Prompts** | 8 preset buttons, each with a label (its legend) and a prompt. A preset sends into the current conversation. **Instructions** is added on top of Hermes' own system prompt for every turn from this plugin. |
| **Setup** | Host, API key, profile, model, provider, Last Error, the agent's advertised name, the features this Hermes version offers, the health check, the session ID, and the last turn's run ID, the provider and model that served it, and its token use. |

Pressing **SEND** while Hermes is still working adds the text to the running turn as guidance (Hermes calls this "steer").
When Hermes asks a clarifying question, type the answer and press **SEND**.

**Properties:** Port (default 8642), Use HTTPS (default No; for a reverse proxy in front of Hermes), Health Poll (default
10 s), Max Turn Time (default 900 s; after that the plugin stops waiting, Hermes may still finish), Debug Print (None / Errors / All).

**Pins:** `Prompt` (text in) with `Send`, `Stop` and `NewChat` triggers, so a control script or another plugin can ask
questions. `Response` (text out) holds the raw text of the last answer, Markdown included. `Busy`, `RunState`,
`ApprovalPending` and `ApprovalText` are outputs, and `ApproveOnce`, `ApproveSession` and `Deny` are input triggers. Each
preset has `PresetSend` (trigger), `PresetLabel` and `PresetPrompt`. `SessionId`, `Host`, `ApiKey`, `Model` and
`Provider` are text pins.

## How it works
Everything goes to `http://<host>:8642` (plus `/p/<profile>` if set) with the header `Authorization: Bearer <API key>`.

- **Health:** `GET /health` (no key) every Health Poll. Two misses in a row show Offline. When it comes back,
  `GET /v1/models` checks the key and gives the agent's name, and `GET /v1/capabilities` gives the feature flags.
- **A turn:** `POST /v1/runs` with `input`, `session_id`, and `instructions`, `model` and `provider` when set, plus an
  `Idempotency-Key` header so a retried request can't start the turn twice. Hermes answers `202` with a `run_id`.
- **Following it:** `GET /v1/runs/{run_id}` once a second. `status` goes `queued`, `running`, and maybe
  `waiting_for_approval`, then ends `completed`, `failed`, `cancelled` or `interrupted`. `last_event` gives the working
  detail. A completed run carries `output` (the answer), `usage` and `runtime` (the provider and model that served it).
- **Approvals:** with the gateway's session authority (current Hermes), pending approvals and questions arrive in
  `pending_controls` with a `prompt_id` and `execution_generation`. The plugin answers with
  `POST /v1/runs/{id}/approval` `{"request_id", "execution_generation", "choice"}`, where choice is `once`, `session` or
  `deny`. In the older single-process mode the request is under `approval`, and the plugin sends `{"choice"}`.
- **Questions:** `POST /v1/runs/{id}/clarify` with `request_id`, `execution_generation` and `answer`.
- **Stop:** `POST /v1/runs/{id}/stop`. The run ends as `cancelled`. **Steer:** `POST /v1/runs/{id}/steer` `{"input"}`.
- **Lost turns:** if the gateway restarted mid-turn, the run reports `unknown`. The plugin acknowledges it with
  `POST /v1/runs/{id}/resolve-unknown` (the run's `admission_id` and `execution_generation`), so later turns in the
  conversation aren't held behind it, and asks you to send the prompt again.
- **Conversation memory:** each conversation has a session ID (`qsys_<date>_<random>`). Hermes keeps the transcript under
  it, so follow-up prompts have context. **New Chat** makes a new ID. The plugin's view starts empty after a restart, but
  Hermes still remembers the session.

Why the Runs API: Q-SYS `HttpClient` returns a response only when it is complete, so it can't read the streamed
`/v1/chat/completions` or `/v1/responses` answers as they arrive. An agent turn can also run for minutes. Polling a run keeps
every request short and gives the plugin stop, steer and approvals.

The transcript is plain text: bold and code marks, headings and code fences are dropped, and lines are wrapped at 84
characters. It uses Roboto Mono, the theme's monospace face, because the plugin wraps the text itself and needs a fixed
character width. The full answer, Markdown included, is on the `Response` pin. The pages use the shared Deep Ocean theme
([design/README.md](../design/README.md)).

## Limitations / not tested on hardware
**This plugin has not been run against a real Hermes Agent or a real Q-SYS Core.** The logic was tested in a Lua 5.3 harness
with mocked Q-SYS controls, `HttpClient`, `Timer` and `rapidjson`, against a simulated Hermes API server that follows the
request and response shapes in the Hermes docs and source. The tests covered: connecting, a wrong key, the agent going offline
and coming back, a normal turn, instructions/model/provider and presets, steer, both approval formats (including when
"session" isn't offered), a clarifying question, stop, a failed turn, a lost (`unknown`) turn, Max Turn Time, New Chat,
profiles, a missing host or key, wrapping and scrolling.

The layout previews (`preview_*.png`) are a close rendering of the layout with test data, not a Designer screenshot.

Check these on site:
- **Reaching the agent:** `API_SERVER_HOST` must not be `127.0.0.1`, and the firewall must allow the Core. From a PC on the
  Core's network, `curl http://<host>:8642/health` should return `{"status": "ok"}`.
- **Approvals:** confirm what your Hermes version puts in `pending_controls` or `approval` for a real tool approval, and that
  **Approve Once** lets the tool run.
- **Long answers:** the transcript keeps the last 400 lines. Q-SYS text fields aren't multi-line, so very long prompts are
  easier to send from a preset or the `Prompt` pin.
- **API key:** Q-SYS text fields aren't masked, so anyone with the design file can read the key.

Not included: streaming text as it is written, images, file upload, the Jobs (scheduled work) and Sessions APIs, and
browsing past sessions.

## Sources
- Hermes Agent docs, API Server (endpoints, headers, Runs API, approvals, `.env` settings, security notes):
  https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server
- Hermes Agent docs, Programmatic integration (run statuses and terminal states):
  https://hermes-agent.nousresearch.com/docs/developer-guide/programmatic-integration
- Hermes Agent source, commit `b66ab2b` (2026-10-24): https://github.com/NousResearch/hermes-agent. The request bodies and
  fields that the docs don't spell out were read from the API server code: `gateway/platforms/api_server_runs.py` (runs,
  approval, steer, stop), `api_server_authority_runs.py` (`pending_controls`, run status projection, clarify),
  `gateway/session_pending_controls.py` (approval and clarify prompt fields), and `api_server.py` (`/v1/models`,
  `/v1/capabilities`, the network bind warning).
- Open WebUI docs, "Hermes Agent" (the same API server setup from the client side):
  https://docs.openwebui.com/getting-started/quick-start/connect-an-agent/hermes-agent
- Q-SYS HttpClient reference (Download/Upload, Headers, Timeout, EventHandler):
  https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/HttpClient.htm

## Changelog
- 1.0: first release.
