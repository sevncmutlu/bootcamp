# Sprint 1 — Daily Scrum Notes

**Project:** Maki Finance Coach · **Team:** Team 120
**Format:** Since the team is small, Daily Scrums were conducted via short sync meetings + Slack messaging.

> Each note format: **What was done yesterday? / What will be done today? / Are there any blockers?**

Meetings were organized by the Scrum Master (Sevinç Mutlu). An example meeting invitation for the team is shown below:

![Daily Scrum Meeting Invitation](../assets/sprint-1-daily-invite.png)

---

## Week 1

**Days 1–2 — Vision & Problem**
- Done: Problem definition, target audience, and value proposition were discussed (US-01).
- To-Do: Move on to product identity and metaphor decision.
- Blockers: None.

**Days 3–4 — Identity & Metaphor**
- Done: MakiCoach was chosen as the main identity; the forest metaphor was positioned as a secondary, supporting layer (US-02).
- To-Do: Technology stack research.
- Blockers: Discussion on finding the right balance so that the forest metaphor does not overshadow the coaching message -> resolved.

**Day 5 — Technology Research (Beginning)**
- Done: Technology research began. The research process for this project was quite intensive — mobile framework (Flutter vs. native), local DB (Isar vs. Drift), and backend (FastAPI) alternatives were compared one by one (US-03).
- To-Do: Clarify OCR, time-series forecasting, and LLM implementation.
- Blockers: Many options; selecting the right tool for each layer took time.

---

## Week 2

**Days 6–7 — Technology Decision (Completed)**
- Done: The technology stack was carefully designed. Each layer was selected with justification: Turkish receipt support and Claude integration for OCR, Prophet for forecasting, FAISS/Chroma for RAG, and Claude for bilingual coaching. The stack was finalized -> Flutter + Drift (sqlite3mc) + FastAPI + PaddleOCR (Claude API parser) + Prophet + RAG + Claude (US-03) [Completed].
- To-Do: Privacy architecture decision.
- Blockers: None — the intensity of the research ensured the decision was based on solid ground.

**Days 8–9 — Privacy Architecture**
- Done: Privacy was discussed in detail and accepted as the project's most critical differentiator. The "data on-device / only anonymous signals to server" architecture was decided (US-04) [Completed]. Specifically, what data remains on-device and what goes anonymously was clarified.
- To-Do: Category taxonomy draft.
- Blockers: Detailed discussion on how to technically guarantee that the anonymous signal remains truly identity-free; design note added.

**Day 10 — Taxonomy, Schedule & Risks**
- Done: Category taxonomy draft (US-05) [Completed], 3-sprint schedule (US-06) [Completed], risk list (US-07) [Completed].
- To-Do: Prepare for Sprint Review & Retrospective.
- Blockers: None — sprint goals achieved.

---
