# Sprint 1 — Planning & Project Definition

**Project:** Maki Finance Coach · **Team:** Team 120
**Date:** June 19 – July 5 · **Status:** [Completed]

> **Sprint Theme:** Clarify the project, make technology and identity decisions, output a development-ready plan and architecture. *(No code was written in this sprint—fully a planning sprint.)*

---

## Sprint Goal

To clarify the product idea, target audience, and value proposition; determine the technology stack and product identity (MakiCoach character + privacy architecture); and define a 3-sprint roadmap and risks to make the team ready for development.

---

## Sprint Planning

**Sprint Duration:** June 19 – July 5 (2 weeks)

### Participants
*   **Product Owner:** Emir Hüseyin İnci
*   **Scrum Master:** Sevinç Mutlu
*   **Developer:** Emir Hüseyin İnci, Sevinç Mutlu

### Capacity & Commitment
*   **Sprint capacity (target):** ~100 SP
*   **Committed story points:** 60 SP (US-01 → US-07)
*   **Sprint length:** 2 weeks

> Note: Since Sprint 1 is planning-heavy, the committed items are decision/documentation-oriented; remaining capacity was allocated to Sprint 2 preparation.

---

## Sprint Backlog & Board

### Sprint Points Summary
*   **Sprint capacity:** ~100 SP
*   **Commitment:** 60 SP
*   **Completed:** 60 SP (100%)

### Backlog Distribution Logic
*   The project was divided into 3 sprints, balanced to carry approximately ~100 SP per sprint.
*   Sprint 1 consists of planning & decision-making tasks; its output is a development-ready plan + architecture + decisions rather than code.
*   Risky tasks (Turkish receipt OCR, RAG sourcing) were pulled to earlier sprints.
*   Each item was associated with a DoD (Definition of Done).

### Sprint Board

| To-Do | In Progress | Done |
|-------|-------------|------|
| — | — | US-01, US-02, US-03, US-04, US-05, US-06, US-07 |

> _Board screenshot will be added here._

### Task Details & Status

| ID | Task | SP | Status |
|----|------|----|--------|
| US-01 | Clarification of problem, target audience, and value proposition | 8 | Done |
| US-02 | Identity & metaphor decision (MakiCoach + light forest layer) | 8 | Done |
| US-03 | Technology stack selection (Flutter, Drift + sqlite3mc, FastAPI, PaddleOCR + Claude, Prophet, RAG, LLM) | 13 | Done |
| US-04 | Privacy architecture decision (data on-device / anonymous signal) | 13 | Done |
| US-05 | Category taxonomy draft | 5 | Done |
| US-06 | 3-sprint schedule + scope definition | 8 | Done |
| US-07 | Risk identification | 5 | Done |

**Total:** 60 / 60 SP completed.

### Sprint Burndown (Summary)

| Day Range | Remaining SP |
|-----------|--------------|
| Start | 60 |
| End of Week 1 | ~30 |
| End of Week 2 | 0 |

> _Detailed burndown chart will be added here._

---

## Daily Scrum Notes

> Since the team is small, Daily Scrums were conducted via short sync meetings + Slack messaging.

### Week 1

**Days 1–2 — Vision & Problem**
*   **Done:** Problem definition, target audience, and value proposition were discussed (US-01).
*   **To-Do:** Move on to product identity and metaphor decision.
*   **Blockers:** None.

**Days 3–4 — Identity & Metaphor**
*   **Done:** MakiCoach was chosen as the main identity; the forest metaphor was positioned as a secondary, supporting layer (US-02).
*   **To-Do:** Technology stack research.
*   **Blockers:** Discussion on finding the right balance so that the forest metaphor does not overshadow the coaching message -> resolved.

**Day 5 — Technology Research (Beginning)**
*   **Done:** Technology research began. The research process for this project was quite intensive — mobile framework (Flutter vs. native), local DB (Isar vs. Drift), and backend (FastAPI) alternatives were compared one by one (US-03).
*   **To-Do:** Clarify OCR, time-series forecasting, and LLM implementation.
*   **Blockers:** Many options; selecting the right tool for each layer took time.

### Week 2

**Days 6–7 — Technology Decision (Completed)**
*   **Done:** The technology stack was carefully designed. Each layer was selected with justification: Turkish receipt support and Claude integration for OCR, Prophet for forecasting, FAISS/Chroma for RAG, and Claude for bilingual coaching. The stack was finalized -> Flutter + Drift (sqlite3mc) + FastAPI + PaddleOCR (Claude API parser) + Prophet + RAG + Claude (US-03) [Completed].
*   **To-Do:** Privacy architecture decision.
*   **Blockers:** None — the intensity of the research ensured the decision was based on solid ground.

**Days 8–9 — Privacy Architecture**
*   **Done:** Privacy was discussed in detail and accepted as the project's most critical differentiator. The "data on-device / only anonymous signals to server" architecture was decided (US-04) [Completed]. Specifically, what data remains on-device and what goes anonymously was clarified.
*   **To-Do:** Category taxonomy draft.
*   **Blockers:** Detailed discussion on how to technically guarantee that the anonymous signal remains truly identity-free; design note added.

**Day 10 — Taxonomy, Schedule & Risks**
*   **Done:** Category taxonomy draft (US-05) [Completed], 3-sprint schedule (US-06) [Completed], risk list (US-07) [Completed].
*   **To-Do:** Prepare for Sprint Review & Retrospective.
*   **Blockers:** None — sprint goals achieved.

---

## Product Status

Since Sprint 1 is a planning sprint, there are no working application screens yet. Sprint outputs:

*   [Completed] Clarified product vision and value proposition
*   [Completed] Technology stack and architectural decisions
*   [Completed] Product identity (MakiCoach) and privacy architecture decision
*   [Completed] 3-sprint roadmap and risk list

---

## Sprint Review

*   Product idea, target audience, and value proposition were clearly established.
*   Technology stack and architecture were defined in sufficient detail to start development.
*   The privacy-first architecture decision (data on-device) was approved as the key differentiator of the project.
*   All prerequisites are ready to begin development in Sprint 2.

**Sprint Review Decision:** Sprint 1 is approved.

---

## Sprint Retrospective

### What Went Well (Keep)
*   Scope was clarified early; technology and identity decisions were made quickly through discussion.
*   Designing the privacy architecture early will reduce surprises in subsequent sprints.
*   Communication was fluid despite being a small team; decisions were approved quickly.
*   The 3-sprint roadmap turned out realistic and balanced.

### What Can Be Improved (Improve)
*   Turkish receipt OCR accuracy should be tested as soon as possible (at the beginning of Sprint 2) — uncertainty is high.
*   The "first simple working version, then improve" approach for models should be applied disciplinedly.
*   Daily Scrums can be made more structured (fixed time).

### What to Stop (Stop)
*   Scope creep tendencies (bank integration, etc.) — must be kept out of the MVP.
*   Entering long discussions without reaching a decision — timeboxing should be applied.

### Action Items (for Sprint 2)

| # | Action | Owner |
|---|--------|-------|
| 1 | Validate Turkish receipt accuracy at the beginning of Sprint 2 with a pilot test of the PaddleOCR + Claude API integration | Sevinç Mutlu |
| 2 | Set up the Flutter skeleton + Drift encrypted device DB schema at the start of the sprint | Emir Hüseyin İnci |
| 3 | Set a fixed time for Daily Scrums | Sevinç Mutlu (Scrum Master) |
| 4 | Define a "simple version" DoD for each model | Emir Hüseyin İnci (PO) |

### Team Morale
During the sprint, communication setbacks occurred within the team from time to time; there were some disconnects in task distribution and decision-making processes. Despite this, the team is generally progressing well: sprint goals were achieved, and a clear roadmap was produced. Communication issues are planned to be resolved in the next sprint through more structured Daily Scrums (fixed hour, regular Slack updates).

---

## Sprint 1 Definition of Done (DoD)

The application's purpose, the technologies to be used, and the order of development are written; identity and privacy decisions are made; the team is ready to begin development. **→ Met**

---

## Next Sprint

**Sprint 2 (July 6 – 19):** Infrastructure & Core + Receipt OCR + AI Coaching (Beginning).
Goal: Working skeleton, secure on-device data, automated entry via receipt scanning, and initial source-backed coaching.
