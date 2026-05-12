# Hour 2 deck outline — Low-Code Agents with Copilot Studio

**Replaces slides 22-40 of `_archive/warner-github-agents-REIMAGINED.pptx`** (19 slides currently dedicated to LangGraph; those move to Hour 3).

**Slot:** 50 minutes — ~5 min orientation, ~30 min live build, ~10 min publish/debug/recap, ~5 min Q&A.

**Live-build target:** Contoso HR Agent in Copilot Studio with HR Policy knowledge source, 3 topics, 1 Outlook connector action, 1 Adaptive Card, 1 global variable, published to Microsoft Teams.

**Demo tenant pre-flight (night before May 13):** knowledge source pre-indexed, Outlook connection authorized, one end-to-end dry pass complete, 30-second "break glass" screen capture recorded.

---

## Slide 22 — Section divider: "02 · LOW-CODE"

- Visual: large "02" matching the deck's existing section divider style (see slides 10, 22, 41, 57)
- Subtitle: "Ship a real agent today. No code required."
- **Speaker notes:** Transition from Hour 1's concepts. "You now know what an agent is. In the next 50 minutes, you're going to build one — with me, live — and publish it to Teams. No code. Then in Hour 3 we'll open the hood on the exact same agent in Python."

---

## Slide 23 — HOUR 2 · WHY LOW-CODE FIRST

- **Bullets:**
  - Most enterprise agents start in low-code; production rewrites come later
  - Copilot Studio = opinionated runtime + visual designer + built-in M365 connectors
  - You can ship to Teams in one afternoon
  - You'll outgrow it — and that's fine. Hour 3 shows what's underneath.
- **Speaker notes:** Hit the adoption arc honestly. Most teams ship a Copilot Studio agent before they ship a LangGraph one. That's not a compromise — it's how the funnel works. Set up the Hour 3 reveal: "Same agent, code version, next hour."

---

## Slide 24 — HOUR 2 · COPILOT STUDIO ANATOMY

- **Bullets:**
  - **Topics** — conversation flows triggered by phrases or events
  - **Knowledge** — grounded sources (SharePoint, websites, Dataverse, uploaded files)
  - **Actions** — connectors that call out (Outlook, Teams, Power Automate, custom)
  - **Variables** — topic-scope and global-scope state
  - **Entities** — slot-fill extractors (prebuilt + custom)
- **Speaker notes:** Quick orientation. Don't dwell. Most of the audience has seen this; the build is where the value is.

---

## Slide 25 — HOUR 2 · THE AGENT WE'RE BUILDING

- **Bullets:**
  - **Contoso HR Agent** — same name, same job as the code version in Hour 3
  - **Knowledge:** Microsoft Learn HR-shaped policy content (live, public, no auth)
  - **Topics:** Evaluate Resume · Ask HR Policy · Show Last Candidate
  - **Action:** Outlook send email on decision
  - **Output:** Adaptive Card with structured evaluation
  - **Publish target:** Microsoft Teams
- **Speaker notes:** Set expectations. Show the finished agent first (screen capture or pre-built tenant) so they know what success looks like. Then we build it together.

---

## Slide 26 — HOUR 2 · LIVE BUILD · KNOWLEDGE SOURCE

- **Bullets:**
  - Add public-website knowledge source
  - URL: `https://learn.microsoft.com/en-us/training/paths/m365-copilot-administrator/`
  - Why Microsoft Learn over SharePoint: rock-solid, no auth, deterministic, indexed
  - Verify with one test query in the test pane
- **Speaker notes:** Conference Wi-Fi is hostile. SharePoint introduces tenant scoping and conditional access risk. Microsoft Learn just works. State this — learners will ask why not SharePoint.

---

## Slide 27 — HOUR 2 · LIVE BUILD · GLOBAL VARIABLE

- **Bullets:**
  - Create `Global.LastCandidate` (String, `UseInAIContext` on)
  - Set in Topic 1 step 4
  - Read in Topic 3 and surfaced to the orchestrator
  - Demonstrates cross-topic state — the question I get every time
- **Speaker notes:** Pause here. Global variables vs. topic variables is the most-asked question in every Copilot Studio session I've taught. Make the distinction explicit: topic-scope dies at end of topic; global-scope lives the whole conversation.

---

## Slide 28 — HOUR 2 · LIVE BUILD · TOPIC 1 (EVALUATE RESUME)

- **Bullets:**
  - Trigger phrases: "evaluate this resume", "score this candidate", "is this candidate a fit"
  - Sequence: 3 Question nodes → SetVariable → SearchAndSummarizeContent → Adaptive Card → Outlook action
  - Entities: StringPrebuilt × 2, NumberPrebuilt × 1
  - Grounded answer uses the HR Policy Library knowledge source
- **Speaker notes:** This is the longest build step (~10 minutes). Slot-fill rhythm: trigger → ask name → ask role → ask years → set global → generate → render card → email. Narrate each click.

---

## Slide 29 — HOUR 2 · LIVE BUILD · ADAPTIVE CARD

- **Bullets:**
  - JSON skeleton with FactSet for candidate / role / years / disposition
  - TextBlock for reasoning
  - Action.Submit for "Email HR"
  - Why cards beat plain text: structured, scannable, accessible, reusable
- **Speaker notes:** Show the JSON, then show the rendered card side by side. Learners' lightbulb moment is usually here — "oh, this is just JSON, I can do this." Reinforce: cards are reusable across Teams, Outlook actionable messages, and Power Apps.

---

## Slide 30 — HOUR 2 · LIVE BUILD · TOPIC 2 (ASK HR POLICY)

- **Bullets:**
  - Trigger phrases: "what is our policy on", "hr policy", "company guideline"
  - Single `SearchAndSummarizeContent` node, grounded
  - `responseCaptureType: FullResponse` for citations
  - Demonstrates knowledge reuse across topics
- **Speaker notes:** Fastest topic to build (~4 minutes). Point out that you're reusing the same knowledge source from Topic 1. Knowledge is agent-scoped, not topic-scoped.

---

## Slide 31 — HOUR 2 · LIVE BUILD · TOPIC 3 (SHOW LAST CANDIDATE)

- **Bullets:**
  - Trigger phrases: "who was the last candidate", "recap last applicant", "show previous evaluation"
  - `ConditionGroup` on `=IsBlank(Global.LastCandidate)`
  - Empty branch: friendly fallback message
  - Set branch: surface the global variable
- **Speaker notes:** This is the topic that earns the global-variable slide its keep. Run it before Topic 1 (should say "no candidate yet"), then run Topic 1, then run Topic 3 again (should recall the name). Live demo of state persistence.

---

## Slide 32 — HOUR 2 · LIVE BUILD · CONNECTOR ACTION

- **Bullets:**
  - Office 365 Outlook · `SendEmailV2` (GA, not preview)
  - Fires at end of Topic 1, after Adaptive Card renders
  - Connection authorized in advance — no live OAuth dance
  - Why not Teams "Post message": bot framework channel registration is a stage trap
- **Speaker notes:** Call out the pre-authorization explicitly. Tell learners: when you build this on your own, the first time you wire an Outlook action, the OAuth popup can hide behind the browser and stall the topic. Authorize it once before you demo.

---

## Slide 33 — HOUR 2 · ORCHESTRATION GOTCHA

- **Bullets:**
  - Generative orchestration picks topics by similarity to phrases + `modelDescription`
  - Overlapping phrases ("review this") can route to the wrong topic
  - Fix: tight `modelDescription` per topic
  - Test routing in the test pane BEFORE you publish
- **Speaker notes:** This is the #1 thing learners trip on in week 2 of their own builds. Spend 30 seconds on `modelDescription`. Show a good one vs. a bad one if time allows.

---

## Slide 34 — HOUR 2 · PUBLISH TO TEAMS

- **Bullets:**
  - Channels → Microsoft Teams → Turn on → Availability options
  - Approval flow if your tenant requires admin consent
  - Publish → Get sharing link → Install in a channel
  - End-to-end demo: resume eval in the Teams channel, with the card, with the email landing in inbox
- **Speaker notes:** This is the payoff. Have the Teams window pre-pinned to a second monitor or window. Run the full flow: trigger Topic 1 in Teams, complete the slot-fill, see the card, switch to Outlook, show the email. ~3 minutes if everything is warm.

---

## Slide 35 — HOUR 2 · DEBUG · WHEN IT DOESN'T WORK

- **Bullets:**
  - Test pane = your friend. Watch the conversation transcript and variable values live.
  - Topic didn't trigger → check trigger phrases + `modelDescription`
  - Generative answer empty → knowledge source not indexed yet (wait, or re-add)
  - Action failed → check the connector's run history in Power Automate
  - Adaptive Card blank → JSON syntax (use Adaptive Cards Designer to validate)
- **Speaker notes:** Spend a full 3-4 minutes here. Debug is where learners get stuck on their own. Show the test pane explicitly. Show one intentional failure (e.g., comment out the SetVariable, ask Topic 3, get the empty-state message).

---

## Slide 36 — HOUR 2 · LOW-CODE VS. CODE-FIRST

- **Two columns:**
  - **Stay in Copilot Studio when:** M365-first audience, business-user authors, standard connectors, conversational UI, fast iteration matters more than custom logic
  - **Move to code-first when:** custom orchestration (parallel fan-out, complex graphs), non-M365 ecosystems, custom RAG with embedded ranking, deep observability needs, version control + CI/CD for the agent itself
- **Speaker notes:** This is the bridge to Hour 3. Both sides are valid — most production landscapes have both. The wrong question is "which one." The right question is "which one for this agent."

---

## Slide 37 — HOUR 2 · WHAT WE BUILT

- **Recap card:**
  - Contoso HR Agent · 3 topics · 1 connector action · 1 Adaptive Card · 1 global variable
  - Knowledge-grounded · State-aware · Published to Teams · Email on decision
  - Build time: ~30 minutes
- **Speaker notes:** Quick proud-moment slide. Then transition: "Now let's see the same agent in code, exposed as an MCP server."

---

## Slide 38 — Hour 2 — what we covered

- **Bullets (deck's existing recap style, matches slide 21 + 40 + 56):**
  - Copilot Studio anatomy
  - Built Contoso HR Agent live (3 topics, knowledge source, connector, card)
  - Global variables and cross-topic state
  - Adaptive Cards for structured output
  - Published to Microsoft Teams end-to-end
  - When low-code is the right answer, and when to move to code
- **Speaker notes:** Match the recap pattern from the other hours. Keep it tight. Q&A follows. Break after.

---

## Slides 39-40 — Reserved for Q&A overflow + break transition

- **Slide 39:** "Questions?" (matches existing deck pattern)
- **Slide 40:** 10-minute break card

---

## What moves OUT of Hour 2

The current deck slides 22-40 (LangGraph code walkthrough) relocate to Hour 3, slotted between the MCP primitives section and the live pipeline run. Specifically the existing slides:

- 23 (HOUR 2 · THE APP) → Hour 3, before code walkthrough
- 24-25 (HOUR 2 · ARCHITECTURE x2) → Hour 3, repurpose as code-version architecture
- 26-27, 30 (HOUR 2 · CODE WALKTHROUGH x3) → Hour 3 code walkthrough block
- 28 (HOUR 2 · AGENTS) → Hour 3 CrewAI section
- 29 (HOUR 2 · KEY CONCEPT) → Hour 3 parallel fan-out slide
- 31 (HOUR 2 · TIMING) → Hour 3 live run
- 32-33 (HOUR 2 · STATE x2) → Hour 3 LangGraph state section
- 34 (HOUR 2 · OUTPUTS) → Hour 3
- 35 (HOUR 2 · DEMO) → Hour 3 live run
- 36 (HOUR 2 · WORKED EXAMPLE) → Hour 3
- 37 (HOUR 2 · MEMORY) → Hour 3 checkpointing
- 38 (HOUR 2 · DEBUG) → Hour 3 Pipeline Runs page (`runs.html`)
- 39 (HOUR 2 · TESTING) → Hour 3 or drop (Hour 4 covers eval already)

---

## Top 3 stage risks for Hour 2 (and the mitigation)

1. **Knowledge source indexing lag.** New URLs take 1-5 min to index. **Pre-mitigate:** add the knowledge source in the prep tenant the night before. Verify with a test query.
2. **Outlook connector consent prompt.** First use triggers an OAuth popup that can stall behind the browser. **Pre-mitigate:** create the connection reference in advance, run one test email, leave it authorized.
3. **Generative orchestration picking wrong topic.** Overlapping trigger phrases route incorrectly. **Pre-mitigate:** tight `modelDescription` per topic. Test routing in the test pane before publish.

---

## Next steps

- Sign off on this outline
- Then we rebuild slides 22-40 in `_archive/warner-github-agents-REIMAGINED.pptx` via `ps-pptx-deck-builder` using this outline as the source spec
- Hour 3 slot 47-49 reserved for the relocated LangGraph code-walkthrough slides
