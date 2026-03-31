# Lecture 08 Lecturer Notes

## Pacing

- 20 min: why packaging and deployment are part of reproducibility
- 60 min: guided work on packaged app structure, documentation, and deployment
- 15 min: optional dependencies and graceful fallback discussion
- 10 min: reflection and milestone check
- If time is tight, compress platform-specific deployment details before cutting the packaging rationale

## Non-Negotiable Points

- An app that only runs from the repo root on the author's machine is not yet robust software.
- Packaging choices affect different audiences differently; not every user should have to install every interface dependency.
- `run_app()`, `system.file()`, and optional dependencies are design decisions that reduce future support cost.

## Worth Mentioning Briefly

- Deployment is not the same as maintainability, but deployment failures often expose maintainability problems.
- Students should think of the app as one interface among several, not as the package's identity.
- Keeping the app thin makes future changes cheaper and testing easier.

## Safe Skips If Time Is Tight

- Do not walk through every hosting-platform click path.
- Compress some download-handler extras if the core packaging story needs the time.
- Treat screenshots and polish items as optional if the class is behind.

## Common Misconceptions

- "If the app launches locally, deployment will be easy." Hidden path assumptions often break that.
- "All dependencies should just be Imports." Optional dependencies can be an important design choice.
- "The app is the product." In this course, the product is the shared core plus multiple interfaces.
