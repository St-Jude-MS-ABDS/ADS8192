# Lecture 03 Lecturer Notes

## Pacing

- 20 min: inherited-research-code risks, why data modeling is software design, and how to assess an existing Bioconductor container
- 55 min: guided exploration of `SummarizedExperiment` plus the first thin analysis core
- 15 min: discussion of reuse vs custom design and the scientific use case
- 10 min: reflection and after-class framing
- If time is tight, treat the longer code listings as reference after the first working example

## Non-Negotiable Points

- Say explicitly that data structures are not a preprocessing detail; they are a software design decision that determines how easy everything else becomes.
- Emphasize that `SummarizedExperiment` reduces an entire class of mismatch bugs before students even write analysis code.
- Foreshadow that this lecture is setting up the "one core, many interfaces" pattern for the rest of Unit 1.

## Worth Mentioning Briefly

- In real work, most students should start by assessing existing Bioconductor containers before inventing a custom one.
- They do not need to memorize every accessor today; they do need to know how to find class help and judge whether a container fits the problem.
- A custom class is justified only when a real requirement is missing, not because it feels more sophisticated.

## Safe Skips If Time Is Tight

- Do not narrate every line of the gene-class sketch.
- Treat the complete heatmap code as enrichment, not as a core learning objective.
- Keep the focus on contracts, synchronization, and composability rather than S4 syntax trivia.

## Common Misconceptions

- "A plain matrix is simpler." It is only simpler until metadata drifts and downstream code becomes brittle.
- "Returning a matrix is more flexible." It is usually less useful because it throws away context that later functions need.
- "Custom means rigorous." In practice, reused ecosystem types are often safer and more interoperable.
