# Lecture 10 Lecturer Notes

## Pacing

- 20 min: installation quality, release/readiness mindset, and why clean-room testing matters
- 60 min: guided work on packaged CLI install and validation
- 15 min: output parity and backward-compatibility discussion
- 10 min: reflection and milestone check
- If time is tight, trim release-ceremony details before trimming parity and clean-install checks

## Non-Negotiable Points

- Installation experience is part of the product for automation users.
- Clean-room testing is more informative than another successful run on the developer's machine.
- Students should understand that output file names and flag names can become compatibility commitments.

## Worth Mentioning Briefly

- Small interface changes can have large downstream effects in scheduled workflows.
- It is often better to preserve compatibility temporarily than to make a neat breaking rename.
- Release discipline is boring in the best possible way: it protects users from surprises.

## Safe Skips If Time Is Tight

- Do not spend too long on tag/release mechanics if clean-room testing is not yet understood.
- Compress some documentation repetition between README and pkgdown.
- Treat version bump tooling as secondary to output parity and installability.

## Common Misconceptions

- "If it works in development, shipping is easy." Installation often reveals the real bugs.
- "A nicer file name is always an improvement." Not if it breaks automation users.
- "Compatibility only matters for large projects." It matters as soon as someone else depends on the tool.
