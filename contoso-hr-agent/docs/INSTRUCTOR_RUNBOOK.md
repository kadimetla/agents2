# Instructor Runbook — Contoso HR Agent

**Audience:** the person at the keyboard during a live O'Reilly / Pluralsight / Pearson delivery.
**Goal:** every known failure mode + the exact recovery command. Open this in a second window before you go live.

---

## Pre-flight (run T-30 minutes before the session)

```powershell
# From contoso-hr-agent/
.\scripts\stop.ps1                       # Kill any orphans from prior runs
uv run python smoke_test.py              # ~50s. PASS means rubric + Azure + Brave all green.
.\scripts\start.ps1                      # Spin everything up cleanly
```

Confirm in your head:

- [ ] Smoke test prints **`SMOKE TEST: PASS`** with `Disposition: Strong Match` and `Score >= 80`.
- [ ] Chat tab opens at `http://localhost:8090/chat.html` and Alex greets you.
- [ ] MCP Inspector tab opens at `http://localhost:6374/` **with auth token in URL** (do not paste a bare `:6374` URL — proxy will reject it).
- [ ] Click every nav link: Chat · Candidates · Pipeline Runs · Memory · Responsible AI. All five render.
- [ ] Drop `sample_resumes/RESUME_Alice_Zhang_Azure_Trainer-v1.txt` into the upload panel. Pipeline trace appears on Pipeline Runs within ~50s.

If any pre-flight check fails, work the table below before you start teaching. Don't go live with a yellow light.

---

## Top failure modes (sorted by likelihood)

| # | Symptom | Root cause | Recovery |
|---|---------|-----------|----------|
| 1 | `start.ps1` says "Killing PID … on port 8090" and engine then fails to bind | Stale process from a prior crashed session still holding the port | `.\scripts\stop.ps1` then `.\scripts\start.ps1` again. `stop.ps1` is the nuclear hatch — sweeps **8090, 8091, 5273, 6374**. |
| 2 | Inspector UI loads but says "proxy auth failed" or shows a blank page | You pasted `http://localhost:6374/` manually instead of using the auto-opened tab. The proxy requires `MCP_PROXY_AUTH_TOKEN` in the query string. | Close that tab. Run `.\scripts\show-inspector-url.ps1` to print the tokenized URL, or just bounce with `start.ps1` so the CLI auto-opens it. |
| 3 | MCP Inspector throws `SyntaxError: Unexpected number in JSON at position 2` | Something on the import chain wrote to **stdout** in stdio mode. JSON-RPC owns stdout. | Grep the recent diff for `print(` or `console.print(` calls reachable from `mcp_server/__main__.py:main()` stdio branch. All logging must go to stderr via `Console(stderr=True)`. |
| 4 | Watcher silently does nothing after a file drop | The watcher polls `data/incoming/` every 3 s for `.txt/.md/.pdf/.docx`. File extension or path might be off. | Confirm file is in `contoso-hr-agent/data/incoming/`, not the repo root. Confirm extension is supported. Tail the watcher job output: `Receive-Job -Id <watcher_id> -Keep`. |
| 5 | Pipeline returns `None` or hangs >2 min | Azure throttling on `gpt-5.4-1`, or Brave Search API quota exhausted. | Check engine logs in the terminal — LiteLLM prints the HTTP status. If 429, wait 30s and retry. If Brave is down, the `resume_analyst` falls back to policy-only context but still completes. |
| 6 | Chat says "Alex is thinking…" and never responds | Same as above — Azure call stuck. | Reload page, click **New chat**, retry. If two retries fail, restart engine: Ctrl+C in start.ps1 window, re-run. |
| 7 | Candidate appears on **Candidates** page with `Unknown` disposition | Pipeline crashed mid-run but checkpoint wrote a partial state. | Acceptable to show as a teaching moment. Or refresh — auto-refresh re-fetches. Worst case, delete the row from `data/hr.db` and re-drop the resume. |
| 8 | `smoke_test.py` exits 4 (disposition mismatch) or 5 (score below 80) | Model deployment drifted, prompts changed, or ChromaDB lost its grounding docs. | Run `uv run hr-seed --reset` to rebuild the 146-chunk knowledge index. Re-run smoke test. If still failing, the model deployment changed underneath you — escalate, do not go live. |
| 9 | Pipeline Runs page shows no runs even though Candidates has rows | Checkpoint DB (`data/checkpoints.db`) was deleted or never written. | Drop a fresh resume after restart — the next run will populate it. Older runs are not retroactively traced. |
| 10 | Cannot drag-drop resume onto upload panel in Chrome | Browser permission or stale service worker | Hard reload: **Ctrl+Shift+R**. Or use the "click to browse" path instead of drag-drop — equivalent code path. |

---

## Nuclear-option recovery (90 seconds, total reset)

If multiple things are broken and you have <2 minutes before the session resumes:

```powershell
# From contoso-hr-agent/
.\scripts\stop.ps1                       # Kill all 4 ports, including orphans
Remove-Item data\checkpoints.db -Force -ErrorAction SilentlyContinue
Remove-Item data\hr.db -Force -ErrorAction SilentlyContinue
Remove-Item data\chat_sessions\*.json -Force -ErrorAction SilentlyContinue
# Do NOT delete data/chroma — re-seeding takes ~90 seconds and costs Azure embedding calls
.\scripts\start.ps1
```

This wipes evaluation history and chat history but keeps the ChromaDB knowledge index. You'll greet a clean app.

---

## During the session — what to say if something goes wrong

| You see | Say (out loud, to the audience) |
|---------|-------------------------------|
| The chat hangs | "This is Azure throttling under the new tenant rate limit — let me show you the retry behavior in the engine logs." (alt-tab to terminal, point at the LiteLLM HTTP status line) |
| A run shows `Unknown` disposition | "This is exactly the failure mode the `notify` node is built to surface — a partial state. Note the run still appears on the Pipeline Runs page; nothing is silently dropped." |
| The watcher misses a file | "The watcher polls every 3 seconds — production systems would use inotify or filesystem events. Let me click upload instead and we'll route through the same code path." |
| Inspector won't connect | "MCP stdio has a known gotcha — JSON-RPC owns stdout, so any errant log line breaks the protocol. This is the **#1** thing to know when shipping an MCP server." (then bounce start.ps1) |

Every failure is a teaching moment if you frame it before the audience frames it for you.

---

## Don't do this live

- **Do not `git pull` mid-session.** Whatever's on disk is what was smoke-tested.
- **Do not delete `data/chroma/`** unless you have 2+ minutes — re-seeding costs Azure embedding calls and ~90 seconds.
- **Do not edit `.env`** during the session. If a key is expired, swap to a backup deployment via the engine restart, not by hand-editing the env file with 200 people watching.
- **Do not run `uv sync`** during the session. Dependency changes can break the running engine.
- **Do not show the Azure portal** with your real subscription IDs visible. Stay in the app.

---

## Reference: the four project ports

| Port | Service | If it's busy |
|------|---------|--------------|
| 8090 | FastAPI engine (web UI + REST) | `stop.ps1` then `start.ps1` |
| 8091 | FastMCP 2 SSE server | Only used if `hr-mcp` runs directly. Inspector uses stdio. |
| 5273 | MCP Inspector proxy | `stop.ps1` clears it. |
| 6374 | MCP Inspector browser UI | `stop.ps1` clears it. |

`force_kill_port()` only handles 8090 and 8091. The start/stop scripts handle 5273 and 6374 as belt-and-suspenders.

---

## Reference: the smoke-test exit codes

| Code | Meaning | What to do |
|------|---------|-----------|
| 0 | PASS — Alice scored Strong Match with `>=80` | Green light. Go teach. |
| 2 | `RESUME_Alice_Zhang_Azure_Trainer-v1.txt` not found | You're in the wrong directory. `cd contoso-hr-agent`. |
| 3 | Pipeline returned `None` | Azure or Brave failure. Check engine logs, retry. |
| 4 | Disposition was not "Strong Match" | Rubric / prompts / model deployment drifted. **Do not go live until fixed.** |
| 5 | Disposition was Strong Match but score `<80` | Scoring drifted but still passing. Acceptable to teach with; investigate after. |

---

_Last edited 2026-05-12, T-15h before the O'Reilly *Build Production-Ready AI Agents* delivery._
