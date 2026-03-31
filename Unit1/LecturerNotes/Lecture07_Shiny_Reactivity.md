# Lecture 07 Lecturer Notes

## Pacing

- 20 min: audience framing, reactive graph, and the thin-interface principle
- 60 min: guided Shiny build around the package core
- 15 min: UI/UX and validation discussion
- 10 min: reflection and milestone check
- If time is tight, prioritize reactive boundaries over widget variety

## Non-Negotiable Points

- The app is not a second implementation of the analysis.
- Expensive computations should live in reusable reactive boundaries, not be copied into multiple render functions.
- Students should understand that reactivity is valuable because it helps manage dependencies and caching cleanly.

## Worth Mentioning Briefly

- A confusing scientific app wastes time even if the core statistics are correct.
- Validation and helpful feedback are part of scientific software quality, not just UI polish.
- It is fine to keep the app small if the package core is strong.

## Safe Skips If Time Is Tight

- Do not spend much time on optional widgets or styling extras.
- Compress some UI details once the reactive graph is clear.
- Treat modules as preview material unless the class is moving quickly.

## Common Misconceptions

- "Every input change should rerun everything." No; that is how apps become slow and confusing.
- "If the app works, duplicated logic is fine." No; duplication creates drift and inconsistent results.
- "UI concerns are secondary." For scientific users, poor feedback and validation create real analysis errors.
