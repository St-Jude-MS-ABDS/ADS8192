# Lecture 05 Lecturer Notes

## Pacing

- 20 min: why package boundaries matter and how to decide what belongs in the public API
- 60 min: guided package setup and movement from script code into `R/`
- 15 min: dependency, naming, and internal-helper discussion
- 10 min: reflection and milestone check
- If time is tight, compress the Git/GitHub mechanics and keep the design conversation about exported vs internal functions

## Non-Negotiable Points

- Packaging is the moment where research code becomes a shared product instead of a private notebook of functions.
- Students should leave knowing that `usethis` and `devtools` are infrastructure helpers, not the core lesson.
- Keep returning to the idea that a small public API is a kindness to future users and to future maintainers.

## Worth Mentioning Briefly

- Most package pain later comes from unclear interfaces, not from forgetting one specific setup command.
- Exporting too much creates maintenance burden because every exported function becomes a promise to users.
- Clean package structure saves time when the project later needs tests, documentation, or another interface.

## Safe Skips If Time Is Tight

- Do not read generated file contents line by line.
- Compress the manual Git command examples once students understand the workflow.
- Treat some DESCRIPTION metadata details as reference if the API discussion needs the time more.

## Common Misconceptions

- "If it exists in the package, it should be exported." No; many functions should remain helpers.
- "Package scaffolding is the hard part." The real design work is deciding what the package should expose.
- "Documentation comes later." In package development, docs are part of the interface from the start.
