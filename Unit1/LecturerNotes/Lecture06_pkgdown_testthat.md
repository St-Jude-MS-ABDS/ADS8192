# Lecture 06 Lecturer Notes

## Pacing

- 20 min: tests as contract protection, not as box-checking
- 60 min: guided work with `testthat`, `pkgdown`, and CI
- 15 min: hidden assumptions, regressions, and refactoring discussion
- 10 min: reflection and milestone check
- If time is tight, prioritize what to test over exhaustive syntax coverage

## Non-Negotiable Points

- The key message is that tests protect user-facing behavior and scientific assumptions.
- CI matters because local success is not the same thing as reproducible success.
- `pkgdown` is not cosmetic; it lowers the cost of understanding and reusing a package.

## Worth Mentioning Briefly

- A short, well-chosen test suite beats a large brittle one.
- Failing tests are useful because they expose drift before reviewers or collaborators do.
- Students should treat docs, tests, and CI as part of one maintainability story.

## Safe Skips If Time Is Tight

- Do not enumerate every expectation helper.
- Compress the GitHub Actions boilerplate if the contract-versus-implementation discussion needs more time.
- Treat badges as optional polish, not core content.

## Common Misconceptions

- "More tests always means better quality." Not if the tests lock down implementation details instead of behavior.
- "If it passes locally, CI is redundant." CI is exactly what catches the hidden local assumptions.
- "pkgdown is only for presentation." It is also for discoverability and onboarding.
