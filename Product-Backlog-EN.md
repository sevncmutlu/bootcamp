# Product Backlog — Maki Finance Coach

**Team:** Team 120 · **Product Owner:** Emir Hüseyin İnci · **Scrum Master:** Sevinç Mutlu
**Product Backlog Tool:** [Miro Backlog Board](https://miro.com/welcomeonboard/NXRRV0ovYXp6emtKV0lKWFdyUEZQSjhoNkVVMW5GdTRoVDRXZlNlci9VTXZvUzRwSDRBS2RWWEtRbVFCUE85ak9iQ09xYUhRUXpOR2hyaGdNdHA3a2tXRVlmR2hqbGFXcFp6RWVZemVzeU1iM09aNHA4S2hodllURlBFSEV6Si9nbHpza3F6REdEcmNpNEFOMmJXWXBBPT0hdjE=?share_link_id=239367518026)

> The backlog is divided into epics, and under epics, user stories. Each story has a **priority** (High / Medium / Low), a **story point (SP)**, and a **target sprint**.
>
> **What is a Story Point (SP)?** It is a relative unit of measure representing the effort, complexity, and uncertainty of a task (it is not hours). A Fibonacci scale is used: 1, 2, 3, 5, 8, 13. E.g., a 13 SP task is significantly larger/riskier than a 5 SP task.

---

## Scoring & Distribution Logic

- **Total project points:** ~300 SP (3 sprints × ~100 SP)
- Story points were given relatively via planning poker (effort + uncertainty + complexity).
- Risky tasks (Turkish receipt OCR accuracy, RAG sourcing) were pulled to earlier sprints.
- Distribution was made to ensure a demoable output at the end of each sprint.

| Sprint | Theme | Target Points |
|--------|------|-----------|
| Sprint 1 | Planning & Project Definition | ~100 SP |
| Sprint 2 | Infrastructure + Receipt OCR + AI Coaching (Beginning) | ~100 SP |
| Sprint 3 | Inflation + Gamification + Notifications + Premium | ~100 SP |

---

## Epics

| Epic | Description |
|------|----------|
| **E0 — Planning & Architecture** | Vision, technology, identity, and privacy decisions |
| **E1 — Infrastructure & Core** | Flutter skeleton, theme, on-device DB, onboarding |
| **E2 — Expense Management** | Manual entry, listing, category taxonomy |
| **E3 — Receipt OCR** | Camera/gallery, Gemini Multimodal, field extraction |
| **E4 — AI Coaching (MakiCoach) & RAG** | LLM coach, bilingual prompt, source-backed advice |
| **E5 — Personal Inflation & Forecasting** | Personal inflation, TÜİK comparison, Prophet |
| **E6 — Gamification & Forest** | Challenges, XP/level, badges, leaderboard, forest |
| **E7 — Notification Optimization** | LinTS simulation with anonymous, personalized notifications |
| **E8 — Premium & Debt Simulator** | LightGBM debt simulation, paywall |
| **E9 — Privacy & Security** | Data on-device, anonymous signals, encryption |

---

## Detailed Backlog (User Stories)

### E0 — Planning & Architecture · _Sprint 1_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-01 | As a team, we want to clarify the problem, target audience, and value proposition so that we build the right product. | High | 8 | S1 |
| US-02 | As a team, we want to decide on the product identity and metaphor (MakiCoach character + forest) so that we design a consistent experience. | High | 8 | S1 |
| US-03 | As a team, we want to select the technology stack so that we begin development on a clear foundation. | High | 13 | S1 |
| US-04 | As a team, we want to determine the privacy architecture (data on-device / anonymous signal) so that we technically guarantee our privacy promise. | High | 13 | S1 |
| US-05 | As a team, we want to draft the category taxonomy so that expenses are categorized consistently. | Medium | 5 | S1 |
| US-06 | As a team, we want to define the 3-sprint timeline and scope so that we manage time correctly. | High | 8 | S1 |
| US-07 | As a team, we want to identify risks so that we can take early precautions. | Medium | 5 | S1 |

### E1 — Infrastructure & Core · _Sprint 2_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-08 | As a developer, I want to set up the Flutter skeleton and folder structure so that we can start development. | High | 5 | S2 |
| US-09 | As a developer, I want to create the theme + design system so that we achieve a consistent user interface. | Medium | 5 | S2 |
| US-10 | As a developer, I want to establish the database schema (Drift + sqlite3mc) so that data is stored encrypted and offline. | High | 8 | S2 |
| US-11 | As a user, I want to see the onboarding flow asking "What do you want to do with money?" so that my experience starts personalized. | Medium | 5 | S2 |

### E2 — Expense Management · _Sprint 2_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-12 | As a user, I want to manually add and list expenses so that I can track my spending. | High | 8 | S2 |
| US-13 | As a user, I want to see my expenses categorized so that I can understand where my money is going. | Medium | 5 | S2 |

### E3 — Receipt OCR · _Sprint 2_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-14 | As a user, I want to photograph receipts to automatically create expenses (Gemini Multimodal for direct field extraction) so that I do not have to enter them manually. | High | 13 | S2 |
| US-15 | As a user, I want to edit and approve the information extracted from OCR so that any errors can be corrected. | Medium | 5 | S2 |

### E4 — AI Coaching (MakiCoach) & RAG · _Sprint 2–3_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-16 | As a user, I want to chat with a TR/EN bilingual financial coach so that I receive personalized financial advice. | High | 8 | S2 |
| US-17 | As a user, I want the coach to show advice backed by TÜİK/Central Bank sources so that it is reliable. | High | 13 | S2→S3 |
| US-18 | As a user, I want to see short daily/weekly coaching sessions so that I receive regular guidance. | Medium | 5 | S3 |

### E5 — Personal Inflation & Forecasting · _Sprint 3_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-19 | As a user, I want to see a chart comparing my personal inflation to TÜİK figures so that I can understand my real situation. | High | 8 | S3 |
| US-20 | As a user, I want to see my future spending forecast (Prophet) so that I can plan my budget. | Medium | 5 | S3 |

### E6 — Gamification & Forest · _Sprint 3_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-21 | As a user, I want to receive gentle daily challenges so that I stay motivated. | Medium | 5 | S3 |
| US-22 | As a user, I want to earn XP/levels and badges so that I feel my progress. | Medium | 5 | S3 |
| US-23 | As a user, I want to see forest/sapling progress as I complete challenges so that I get visual feedback. | Low | 5 | S3 |
| US-24 | As a user, I want to see a percentage-based anonymous leaderboard so that I can compete while protecting my privacy. | Low | 5 | S3 |

### E7 — Notification Optimization · _Sprint 3_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-25 | As a user, I want to receive notifications at the most optimal times so that I am reminded without being disturbed. (LinTS simulation, anonymous features only) | Low | 5 | S3 |

### E8 — Premium & Debt Simulator · _Sprint 3_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-26 | As a user, I want to see a debt-free plan using a virtual debt simulator so that I can set targets. (LightGBM, Premium) | Medium | 8 | S3 |
| US-27 | As a user, I want to access premium features through a paywall so that the application is sustainable. | Low | 5 | S3 |

### E9 — Privacy & Security · _Continuous_

| ID | User Story | Priority | SP | Sprint |
|----|-----------|---------|----|--------|
| US-28 | As a user, I want to be sure that all my financial data remains on my device so that my privacy is protected. | High | 8 | S2–S3 |
| US-29 | As a user, I want to know that only anonymous signals are sent to the server so that I can build trust. | High | 5 | S3 |

---

## Priority Ranking (Top 10 — MVP Critical)

1. US-01, US-03, US-04 — Vision, technology, privacy (S1)
2. US-08, US-10 — Skeleton + device DB (S2)
3. US-12 — Manual expense (S2)
4. US-14 — Receipt OCR (S2)
5. US-16, US-17 — AI coach + source attribution (S2→S3)
6. US-19 — Personal inflation (S3)
7. US-28 — On-device data guarantee (S2–S3)
