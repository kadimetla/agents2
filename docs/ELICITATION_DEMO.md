# Elicitation Demo — Contoso HR Agent

**Audience:** O'Reilly Live Learning, Hour 4 (MCP keystone segment).
**Assumption:** `.\scripts\start.ps1` is already running (chat on 8090, MCP Inspector on 6374).
**What you're proving:** MCP Primitive 5 — the server pauses, asks the human "are you sure?", then resumes (or aborts) based on the answer.

---

## Talking points (45 seconds)

> "An AI agent is about to spend Azure tokens and 30-120 seconds on a multi-agent pipeline. Before it commits, MCP's **elicitation** primitive lets the *server* call back to the *human* and require confirmation. That's the line between a chatbot and a production agent — confirmed action, not autonomous spend."

---

## Path A — MCP Inspector (the visual demo)

This is the default. Use this for the live stage demo.

1. The Inspector tab is already open at `http://localhost:6374/?MCP_PROXY_AUTH_TOKEN=...`. **Do not** open `http://localhost:6374/` manually — the token-less URL won't connect.
2. In the left rail, click **Tools**.
3. Click **`confirm_and_evaluate`**.
4. Fill the arguments pane:
   - **`resume_text`** — paste this single-line blob (drop into the textarea, Inspector accepts multiline):
     ```
     Sarah Chen — Senior Microsoft Certified Trainer (MCT), 7 years active. AZ-104, AZ-305, AZ-400, AI-102. 4.8/5.0 learner CSAT across 240+ delivered courses. Curriculum dev for AI-102 and AZ-305.
     ```
   - **`filename`** — `sarah_chen.txt`
5. Click **Run Tool** (top right of the tool panel).
6. **A modal appears.** Read it aloud — it's the `message` your server sent:
   > "Ready to run the full AI evaluation pipeline for `sarah_chen.txt`. Preview: _Sarah Chen — Senior MCT..._ This will call Azure AI Foundry (gpt-5.4-1), ChromaDB, and Brave Search. Estimated time: 30-120 seconds. Confirm to proceed."
7. The modal shows two form fields generated from the server's `EvalConfirmation` dataclass:
   - `confirmed` — checkbox
   - `priority` — text, defaults to `normal`
8. **For the live demo, pick one of these:**
   - **Decline button** — Tool returns `{"status": "decline", "message": "Evaluation cancelled — pipeline was not run."}`. **Fast, safe, no tokens spent.** Use this on stage.
   - **Cancel button** — Same outcome, different `status: "cancel"`. Shows the third protocol outcome.
   - **Accept with `confirmed` unchecked** — Returns `{"status": "declined", ...}`. Proves the server's *inner* check runs after the protocol accept.
   - **Accept with `confirmed` checked** — **Fires the full pipeline (~30-120s, costs Azure tokens).** Only do this if you have time and want the full payoff.

---

## Path B — Terminal fallback (no UI)

Open a **second Windows Terminal tab** (Ctrl+Shift+T) in `C:\github\agents2\contoso-hr-agent\`. Run any of these:

```powershell
uv run python test_elicitation.py --mode decline      # ~1 second, declines
uv run python test_elicitation.py --mode cancel       # ~1 second, cancels
uv run python test_elicitation.py --mode unchecked    # ~1 second, accept-but-unchecked
uv run python test_elicitation.py --mode interactive  # prompts you 1-4
uv run python test_elicitation.py --mode accept       # ~30-120s, fires the full pipeline
```

Each prints the full elicitation request the server sent and the final tool result. **This is your stage safety net** — if the Inspector misbehaves on May 13, drop to this in 10 seconds.

---

## What to point out while demoing

- **The message text comes from the server**, not the client. Look at the f-string in `mcp_server/server.py:189-195` — that's where the talk-track for the modal lives.
- **The form fields are generated from the dataclass schema.** `EvalConfirmation` at `server.py:182-185` has two fields; the Inspector renders them automatically. No UI code on the client side.
- **The server is paused** while the modal is open. Mention this. The `await ctx.elicit(...)` call at `server.py:188` is genuinely awaiting — the LangGraph pipeline never started until the user clicked Accept-with-confirmed-true.
- **Three protocol outcomes exist** (`accept` / `decline` / `cancel`) and the server short-circuits on the first two at `server.py:200-205`. There's a fourth code path — `accept` but `confirmed=False` — at `server.py:208-212`. Total: four termination branches, one pipeline-run branch.

---

## If something goes wrong on stage

| Symptom | Fix |
|---|---|
| Inspector tab shows "disconnected" | Old token. Close the tab. The auto-opened one with `?MCP_PROXY_AUTH_TOKEN=...` in the URL is the live one. |
| `confirm_and_evaluate` not in the tool list | Inspector is connected to the wrong server, or the Inspector failed to start. Check the `start.ps1` console for `[mcp-inspector]` errors. |
| Modal doesn't appear after clicking Run | Inspector version too old. Drop to **Path B** (terminal fallback). |
| Pipeline starts when you wanted to decline | You clicked Accept with `confirmed` already checked. Open the tool again and use Decline. |

---

## File pointers

- Server tool: `src/contoso_hr/mcp_server/server.py:158-221` (`confirm_and_evaluate`)
- Test driver: `test_elicitation.py` (repo root of `contoso-hr-agent/`)
- Start script: `scripts/start.ps1` (launches everything, opens chat + Inspector tabs)
