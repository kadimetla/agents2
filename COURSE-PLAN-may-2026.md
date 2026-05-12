# Build Production-Ready AI Agents — Course Plan

**O'Reilly Live Learning | 4 × 50-minute segments + 10-minute breaks**
**Delivery: 2026-05-13 / 2026-05-14 | Instructor: Tim Warner**
**Source of truth deck: `warner-github-agents-may-2026.pptx` (repo root, 98 slides)**

---

## Hour 1 — Understanding Agents (50 min)

**Theme:** What makes an agent an *agent*? Concepts, prompting, and tooling choices.

**Deck slides:** 10-21

- [ ] **Concepts:** agent loop (perception → reasoning → memory → action)
- [ ] **Concepts:** token limits, context windows, why they constrain design
- [ ] **Concepts:** memory types — in-context, external (vector/SQL), episodic, semantic
- [ ] **Concepts:** tool use and function calling — how agents reach outside the LLM
- [ ] **Prompting:** structured prompts, system vs. user roles, role-play framing
- [ ] **Choice:** when to use a single LLM call vs. an agent vs. a multi-agent system
- [ ] **Demo:** Claude Code custom agents — dispatch a subagent live
- [ ] **Demo:** Claude Code skills — invoke a skill, show prompt expansion
- [ ] **Choice:** Claude Code vs. GitHub Copilot vs. Copilot Studio — pick your tool
- [ ] **Antipatterns:** common agent design mistakes (over-orchestration, no memory boundary, mocked tools)
- [ ] **Hour 1 recap** + Q&A / break

---

## Hour 2 — Low-Code Agents with Copilot Studio (50 min)

**Theme:** Ship the Contoso HR Agent live, no code, end-to-end to Microsoft Teams.

**Deck slides:** 23-39 (17 slides, newly authored)

- [ ] **Why low-code first:** adoption arc, opinionated runtime, M365 connectors
- [ ] **Copilot Studio anatomy:** topics, knowledge, actions, variables, entities
- [ ] **The agent we are building:** Contoso HR Agent (same use case as Hours 3/4)
- [ ] **Live build · knowledge source:** Microsoft Learn public URL (Wi-Fi-resilient, no auth)
- [ ] **Live build · global variable:** `Global.LastCandidate` (cross-topic state demo)
- [ ] **Live build · Topic 1 (Evaluate Resume):** slot-fill + SearchAndSummarizeContent + Adaptive Card + Outlook
- [ ] **Live build · Adaptive Card:** FactSet + reasoning + Action.Submit
- [ ] **Live build · Topic 2 (Ask HR Policy):** grounded Q&A with citations
- [ ] **Live build · Topic 3 (Show Last Candidate):** ConditionGroup on global, state persistence demo
- [ ] **Live build · connector action:** Office 365 Outlook · Send email v2 (pre-authorized)
- [ ] **Orchestration gotcha:** `modelDescription` tuning for clean topic routing
- [ ] **Publish to Teams:** channel install + end-to-end run (resume → card → email)
- [ ] **Debug:** test pane, connector run history, knowledge indexing lag
- [ ] **Low-code vs. code-first:** when each is the right answer
- [ ] **What we built in Copilot Studio:** recap
- [ ] **The bridge:** same agent, two runtimes — preview Hour 3
- [ ] **Hour 2 recap** + Q&A / break

**Pre-flight (night before May 13):** knowledge source pre-indexed in demo tenant, Outlook connection authorized, dry-run end-to-end, 30-second "break glass" screen capture recorded as fallback.

---

## Hour 3 — Code-First Agent: LangGraph + CrewAI Walkthrough (50 min)

**Theme:** Same Contoso HR Agent, opened up in Python. Parallel pipeline, state, persistence.

**Deck slides:** 40-57 (existing LangGraph block, kickers retitled to HOUR 3)

- [ ] **Meet the code:** `contoso-hr-agent/` repo tour, `uv` workflow, `.env`, what's in the repo
- [ ] **System architecture:** browser → FastAPI → LangGraph → 4 CrewAI agents → SQLite + ChromaDB → Azure AI Foundry
- [ ] **The stack:** LangGraph · CrewAI · ChromaDB + Azure embeddings · Azure AI Foundry · FastMCP 2
- [ ] **Code walkthrough · CrewAI agent:** `PolicyExpertAgent` — ROLE, GOAL, BACKSTORY, tools, no delegation
- [ ] **Code walkthrough · @tool decorator:** `query_hr_policy` — auto-schema, docstring as prompt, citation grounding
- [ ] **The four CrewAI agents:** ChatConcierge (Alex), PolicyExpert, ResumeAnalyst, DecisionMaker
- [ ] **Key concept · parallel fan-out / fan-in:** `policy_expert` ‖ `resume_analyst` concurrent, fan in to `decision_maker`
- [ ] **Code walkthrough · graph wiring:** `add_edge()` fan-out pattern in `pipeline/graph.py`
- [ ] **Pipeline timing:** what runs when (gantt-style: watcher → intake → parallel → decision → notify)
- [ ] **State · HRState TypedDict:** `total=False` for partial updates, partial node returns merge cleanly
- [ ] **State · Pydantic v2 data chain:** ResumeSubmission → PolicyContext → CandidateEval → HRDecision → EvaluationResult
- [ ] **Outputs:** four dispositions (Strong / Possible / Needs Review / Not Qualified)
- [ ] **Live demo:** drop a resume, watch the pipeline run, terminal Rich output
- [ ] **Worked example:** Sarah Chen resume → Strong Match (JSON output walkthrough)
- [ ] **Memory:** chat memory two-layer pattern (localStorage + JSON file + past-session context injector)
- [ ] **Debug:** VS Code launch configs, breakpoints in pipeline nodes, hot keys
- [ ] **Testing:** pytest patterns — model validation, tool unit tests, end-to-end with sample resumes
- [ ] **Hour 3 recap** + Q&A / break

---

## Hour 4 — MCP + Production Deployment (50 min)

**Theme:** Expose the Contoso HR Agent as an MCP server (the keystone demo), then deploy it to Azure.

**Deck slides:** 59-97 (existing MCP block + production block, kickers retitled to HOUR 4)

### Part 1 — MCP (first ~30 min)

- [ ] **Why MCP:** the integration problem (N×M → N+M), the lingua franca for agents and tools
- [ ] **MCP concepts:** client / server / transport, the five primitives
- [ ] **The primitives:** tools, resources, resource templates, prompts, sampling + elicitation
- [ ] **Code walkthrough · FastMCP 2 server:** `mcp_server/server.py` — tool registration, stdio + SSE transports
- [ ] **Code walkthrough · MCP tools:** `get_candidate`, `list_candidates`, `query_policy`, `trigger_resume_evaluation`
- [ ] **Code walkthrough · sampling primitive:** `generate_eval_summary` (`ctx.sample()` — server asks the client's LLM)
- [ ] **Code walkthrough · elicitation primitive:** `confirm_and_evaluate` (`ctx.elicit()` — pause for user confirmation)
- [ ] **Resources + templates:** `candidate://{id}`, `policy://{topic}` dynamic resources
- [ ] **RAG · vectorizer:** ChromaDB ingestion (147 chunks, 8 docs)
- [ ] **RAG · retriever:** `query_policy_knowledge()` end-to-end
- [ ] **KEYSTONE DEMO (NON-NEGOTIABLE):** `uv run hr-mcp` + MCP Inspector against the live Contoso HR app — hit all 5 primitives, every one green
- [ ] **Wiring MCP into clients:** Claude Code (`claude_desktop_config.json`), GitHub Copilot in VS Code
- [ ] **Vibe coding:** how to keep momentum when the LLM is your pair programmer
- [ ] **MCP recap**

### Part 2 — Production deployment on Azure (last ~20 min)

- [ ] **Pivot from MCP to deployment**
- [ ] **Azure AI Foundry:** model deployment, endpoints, API versioning, deployment names
- [ ] **Reference architecture** for a production agent on Azure
- [ ] **Compute:** Azure Container Apps vs. App Service vs. AKS — pick your runtime
- [ ] **Deploy:** push the Contoso HR Agent to Azure Container Apps
- [ ] **Gateway:** APIM in front of agent endpoints — auth, throttling, versioning
- [ ] **Guardrails:** Azure AI Content Safety, prompt shielding, jailbreak detection
- [ ] **Security:** Key Vault for secrets, managed identity, PII handling, input validation
- [ ] **Observability:** Application Insights, LangSmith tracing, structured logging
- [ ] **Cost:** model routing, prompt caching, token budgets
- [ ] **Testing:** eval and regression testing for agent outputs
- [ ] **Wisdom:** common failure modes, retry patterns, graceful degradation
- [ ] **What you built today** — recap
- [ ] **Resources + next steps**
- [ ] **Final Q&A**

---

## Deck-to-plan slide map

| Plan section | Deck slides | Status |
|---|---|---|
| Course intro | 1-9 | Aligned |
| Hour 1 — Concepts | 10-21 | Aligned |
| Section divider (Hour 2) | 22 | Rewritten in place |
| Hour 2 — Copilot Studio | 23-39 | **New block, 17 slides** |
| Hour 3 — LangGraph code | 40-57 | Retitled from "HOUR 2" to "HOUR 3" |
| Section divider (Hour 4) | 58 | Retitled "03" → "04", subtitle rewritten |
| Hour 4 part 1 — MCP | 59-73 | Retitled from "HOUR 3" to "HOUR 4" |
| Hour 4 pivot card | 74 | Retitled "04" → "Pivot", subtitle rewritten |
| Hour 4 part 2 — deployment | 75-95 | Already labeled HOUR 4, aligned |
| Close | 96-98 | Aligned |

## Open items before delivery

- [ ] Pre-stage the Copilot Studio Contoso HR Agent: knowledge source indexed, Outlook connection authorized, dry-run on a fresh tenant
- [ ] Record 30-second "break glass" screen capture of the working Copilot Studio agent (Hour 2 fallback)
- [ ] Smoke-test `hr-mcp` + MCP Inspector against the live Contoso HR app — all 5 primitives green — within 48 hours of delivery
- [ ] Time the Hour 3 LangGraph walkthrough end-to-end against the 50-minute clock (18 slides + live demo is a lot to cover; identify slides to compress)
- [ ] Time Hour 4 split (30 min MCP + 20 min deployment) — confirm the keystone demo gets the time it needs without starving deployment
