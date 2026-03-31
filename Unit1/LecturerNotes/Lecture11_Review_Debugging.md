# Lecture 11 Lecturer Notes

## Pacing

- 20 min: synthesize the Unit 1 design heuristics before troubleshooting starts
- 50 min: readiness checklist, triage, and debugging workflow
- 20 min: peer review and bug-report practice
- 10 min: reflection and next-step framing
- If time is tight, keep the discussion focused on highest-risk failures, not cosmetic cleanup

## Non-Negotiable Points

- Frame the session around what a real user experiences: installability, documentation, validation, and interface consistency.
- Peer review should prioritize bugs, risks, regressions, and missing tests before style comments.
- Reconnect students to the course-wide design ideas so the review session feels like synthesis, not just triage.

## Worth Mentioning Briefly

- The course examples were deliberately simple, but the transferable lesson is how to assess and structure scientific software well.
- A project that only works in one developer's current session is not done.
- The fastest way to fix a messy project is often to identify the real contract boundary first.

## Safe Skips If Time Is Tight

- Do not let the session turn into a long live-debugging clinic for one student's edge case.
- Compress some show-and-tell if multiple students still have install or interface failures.
- Treat optional enhancements as optional; keep the focus on core robustness.

## Common Misconceptions

- "Passing locally means the package is ready." Not without clean-install validation.
- "Peer review is mostly style feedback." The most useful review surfaces behavioral risk.
- "Debugging means trying random fixes." The unit's workflow is reproduce, isolate, fix, test, document.
