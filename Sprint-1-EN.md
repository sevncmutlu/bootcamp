# Sprint 1 — Planning & Project Definition

**Project:** Maki Finance Coach · **Team:** Team 120
**Date:** June 19 – July 5 · **Status:** [Completed]

> **Sprint Theme:** Clarify the project, make technology and identity decisions, output a development-ready plan and architecture. *(No code was written in this sprint—fully a planning sprint.)*

---

## Sprint Goal

To clarify the product idea, target audience, and value proposition; determine the technology stack and product identity (MakiCoach character + privacy architecture); and define a 3-sprint roadmap and risks to make the team ready for development.

---

## Points Expected to Complete in Sprint (Sprint Capacity)

- **Total project points:** 300 points (3 sprints)
- **Sprint 1 target points:** ~100 points

> Since this planning-heavy sprint forms the foundation of all three sprints, it was evaluated as 1/3 of the total points.

---

## Backlog Distribution Logic (Points Logic)

- The project was divided into 3 sprints, balanced to carry approximately equal points (~100) per sprint.
- Sprint 1 consists of planning and decision-making tasks; as its output is a development-ready plan + architecture + decisions rather than code, it was scored in accordance with the "tangible progress in every sprint" principle.
- Backlog items were prioritized from largest to smallest, and each item was associated with a Definition of Done (DoD).
- Risky tasks that need early validation (e.g., Turkish receipt OCR accuracy) were pulled forward and placed at the beginning of Sprint 2.

---

## Sprint 1 Backlog (To-Do List)

| # | Task | Status |
|---|-------|-------|
| 1 | Clarification of problem, target audience, and value proposition | [Completed] |
| 2 | Identity & metaphor decision (MakiCoach character + light forest layer) | [Completed] |
| 3 | Technology stack selection (Flutter, Drift + sqlite3mc, FastAPI, PaddleOCR + Claude, Prophet, RAG, LLM) | [Completed] |
| 4 | Privacy architecture decision (what stays on-device, what goes anonymously) | [Completed] |
| 5 | Category taxonomy draft | [Completed] |
| 6 | 3-sprint schedule + scope definition | [Completed] |
| 7 | Risk identification | [Completed] |

---

## Daily Scrum Notes

> Since the team is small, Daily Scrums were conducted via short sync meetings + chat.

- **Backlog Distribution:** The project was divided into 3 sprints; themes and points were set.
- **Identity & Metaphor:** The MakiCoach character was chosen as the main identity; the forest metaphor was positioned as a secondary, supporting layer.
- **Privacy Decision:** It was decided that all personal data remains on the device, and only anonymous signals go to the server.
- **Technology Decision:** The Flutter + Drift (sqlite3mc) + FastAPI + PaddleOCR (Claude API parser) + Prophet + RAG + Claude stack was finalized.
- **Risk Assessment:** Time constraints, privacy proof, and Turkish OCR accuracy were noted as key risks.

> _Daily Scrum screenshots/meeting notes will be added here._

---

## Sprint Board Updates

- **To-Do → In Progress → Done** flow was established.
- At the end of Sprint 1, all planning items were moved to the Done column.
- The Sprint 2 backlog (Infrastructure & Core, Receipt OCR, AI Coaching beginning) was prepared as To-Do.

> _Sprint board screenshots will be added here._

---

## Product Status

Since Sprint 1 is a planning sprint, there are no working application screens yet. Sprint outputs:

- [Completed] Clarified product vision and value proposition
- [Completed] Technology stack and architectural decisions
- [Completed] Product identity (MakiCoach) and privacy architecture decision
- [Completed] 3-sprint roadmap and risk list

> _Product concept visuals / architecture diagrams will be added here._

---

## Sprint Review

- Product idea, target audience, and value proposition were clearly established.
- Technology stack and architecture were defined in sufficient detail to start development.
- The privacy-first architecture decision (data on-device) was approved as the key differentiator of the project.
- All prerequisites are ready to begin development in Sprint 2.

**Sprint Review Decision:** Sprint 1 goals were 100% achieved; no scope creep occurred.

---

## Sprint Retrospective

**What Went Well**
- Scope was clarified early; technology and identity decisions were made quickly.
- Designing the privacy architecture early will reduce surprises in subsequent sprints.

**What Can Be Improved**
- Turkish receipt OCR accuracy should be tested as soon as possible (at the beginning of Sprint 2).
- The "first simple working version, then improve" approach for models should be applied disciplinedly.

**Action Items (for Sprint 2)**
- Validate Turkish receipt accuracy at the beginning of Sprint 2 with a pilot test of the PaddleOCR + Claude API integration.
- Set up the Flutter skeleton + Drift encrypted device DB schema at the start of the sprint so that development can begin early.

---

## Sprint 1 Definition of Done (DoD)

The application's purpose, the technologies to be used, and the order of development are written; identity and privacy decisions are made; the team is ready to begin development. **→ Met**

---

## Next Sprint

**Sprint 2 (July 6 – 19):** Infrastructure & Core + Receipt OCR + AI Coaching (Beginning).
Goal: Working skeleton, secure on-device data, automated entry via receipt scanning, and initial source-backed coaching.
