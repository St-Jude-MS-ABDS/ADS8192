# Lecture 10 Lecturer Notes

## Pacing

Target: one hour, including reflection.

- 8 min: installation quality mindset, "Where We Are" recap (entry point already packaged from Lecture 9)
- 20 min: launcher install, verification, README + Getting Started CLI blurb (Part 1)
- 15 min: clean-room install-from-GitHub test end to end (Part 2)
- 8 min: manual output parity check (Part 3) — emphasize that automated tests are not required here
- 5 min: release checklist as a guided read-through (Part 4)
- 4 min: reflection and Package Milestone
- If time is tight, trim release-ceremony details before trimming parity and clean-install checks.

## Non-Negotiable Points

- Installation experience is part of the product for automation users.
- Clean-room testing (restart R, `remove.packages()`, `install_github()`, run) is more informative than another successful run on the developer's machine.
- Output file names, flag names, and output column names are compatibility commitments the moment anyone depends on them.
- The CLI was built inside the package in Lecture 9; this lecture is about **verifying the installed path**, not about moving code into the package.

## Worth Mentioning Briefly

- Small interface changes can have large downstream effects in scheduled workflows.
- It is often better to preserve compatibility temporarily than to make a neat breaking rename.
- Release discipline is boring in the best possible way: it protects users from surprises.

## Safe Skips If Time Is Tight

- Do not spend too long on tag/release mechanics if clean-room testing is not yet understood.
- The pkgdown article template and peer-review exercise have been removed from the lecture; do not re-introduce them live.
- The automated CLI parity test has been moved to illustrative-only status — do not walk through it line by line.
- Treat version-bump tooling as secondary to output parity and installability.

## Common Misconceptions

- "If it works in development, shipping is easy." Installation often reveals the real bugs.
- "A nicer file name is always an improvement." Not if it breaks automation users.
- "Compatibility only matters for large projects." It matters as soon as someone else depends on the tool.
