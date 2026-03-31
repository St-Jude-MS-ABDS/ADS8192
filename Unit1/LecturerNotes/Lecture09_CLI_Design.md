# Lecture 09 Lecturer Notes

## Pacing

- 20 min: who the CLI is for and what contract it should expose
- 60 min: guided implementation with `Rapp`
- 15 min: DRY, explicit I/O, and automation discussion
- 10 min: reflection and milestone check
- If time is tight, cut syntax repetition before cutting the audience/contract conversation

## Non-Negotiable Points

- Not every project needs a CLI; the point is to recognize when automation users actually benefit from one.
- The CLI must stay a thin wrapper over package logic.
- Inputs, outputs, help text, and exit codes are part of the user contract.

## Worth Mentioning Briefly

- Implicit working-directory assumptions are a common source of fragile CLI behavior.
- Stable file formats are often more important than clever command structure.
- A CLI should feel boring and predictable to automation users.

## Safe Skips If Time Is Tight

- Do not over-explain every flag once one command is working end to end.
- Compress terminal syntax examples after the contract pattern is clear.
- Treat some validate-command enhancements as optional if the main `pca` command is solid.

## Common Misconceptions

- "A CLI is just another way to run the same code." Only if it stays DRY and thin.
- "Help text is documentation fluff." For CLI users, it is the interface.
- "Renaming flags later is harmless." Pipeline users often depend on those names.
