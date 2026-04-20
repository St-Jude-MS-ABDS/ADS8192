# Lecture 11: Unit 1 Review

## Motivation

Unit 1 focused around a singular process - taking an analysis you would
normally stuff into an R script, and turning it into a generic R package
that other people can install, run, trust, and maintain. We also
demonstrated how to build different interfaces on tops of the core
package for different audiences and use cases: a Shiny app for
interactive use, and a CLI for pipeline inclusion and automation.

We covered key concepts of software engineering along the way: data
structures, packaging, documentation, testing, UI design, and version
control. Each lecture introduced concepts and processes that you will
see repeatedly in real scientific software, regardless of the domain or
language.

This review session is a chance to see those ideas next to each other
and understand how they compose.

### Learning Objectives

By the end of this session, you will be able to:

1.  Describe the key concepts and processes from each lecture
2.  Address any issues remaining with homework 1
3.  Recognize these same patterns and processes covered in Unit 1 when
    you encounter them in real scientific software

------------------------------------------------------------------------

## Lecture 4 — Data Structures & R Ecosystems

The unit began with data, because the shape of your inputs and outputs
constrains everything downstream. If your functions accept and return
well-defined objects, they are easier to test, easier to hand off, and
easier to compose.

**Key ideas:**

- **Reuse before you build.** Before inventing a new data structure,
  check whether a well-maintained one already fits. The “wheel
  reinvention” checklist asks about problem fit, data model alignment,
  interoperability, and maintenance burden.
- **Invariants provide safety.** A gene with `start > end` is not a
  valid gene, it is a bug. Validity checks turn that domain rule into
  something the class enforces for you.
- **S4 class system advantages and drawback.** Typed slots,
  [`setValidity()`](https://rdrr.io/r/methods/validObject.html),
  [`setGeneric()`](https://rdrr.io/r/methods/setGeneric.html), and
  [`setMethod()`](https://rdrr.io/r/methods/setMethod.html) give you
  classes that catch contract violations at construction time. Method
  dispatch and verbose syntax can be hurdles.
- **CRAN vs. Bioconductor differences.** Bioconductor enforces shared
  base classes and release cadences so that ecosystems of packages
  interoperate. CRAN is not domain-specific and has looser requirements,
  so it has more diversity but less interoperability.
- **`SummarizedExperiment` & friends are simple and powerful.** Assays
  (the matrices), `rowData` (feature metadata), and `colData` (sample
  metadata) travel together. Subset one, the others follow. Writing your
  functions against this structure is how they become composable with
  the rest of the ecosystem.

------------------------------------------------------------------------

## Lecture 5 — Package Development with devtools

This lecture introduced the core workflow of package development, which
is how you turn working code into a generic package that other people
can install, understand, and trust. The process is not technically hard,
but it is a lot of moving pieces to keep track of. We introduced
`usethis` and `devtools` as ways to handle much of the scaffolding and
busywork.

**Key ideas:**

- **Why packages are useful.** Portability, explicit dependencies,
  formal documentation, and testability. The moment a second person
  needs your code, a package is cheaper than a script.
- **DESCRIPTION - package metadata.** It declares name, version,
  license, authors, and which packages are required vs. suggested.
  Semantic versioning (`MAJOR.MINOR.PATCH`) and licensing overviews
  explained important aspects of package management.
- **roxygen2 is a pipeline.** Docstrings above each function become
  `.Rd` help files and the `NAMESPACE`. One source of truth; the build
  step handles the rest.
- **Namespacing.** `@importFrom pkg fun` or fully-qualified `pkg::fun()`
  calls keep it obvious where every symbol comes from. Loose
  [`library()`](https://rdrr.io/r/base/library.html) calls inside
  package code are a big no-no.
- **`usethis` + `devtools` as muscle memory.** `create_package()`,
  `use_git()`, `use_github()`, `use_package()`, `document()`,
  `load_all()`, `check()`. These are not are not necessary, but they can
  help you get a working package very quickly.
- **The feature ritual.** *Implement → Document → Test → Check →
  Commit.* Doing these in order, every time, can help you avoid many
  issues.

------------------------------------------------------------------------

## Lecture 6 — Documentation & Testing (pkgdown, testthat)

Full documentation and a test suite are huge steps toward making your
package trustworthy. They are also the parts of the process that are
most often skipped, because they are not strictly necessary to get
something working. If somebody else will ever use the code (say, you in
six months), take the time to do these steps.

**Key ideas:**

- **Test public behavior, not implementation.** Tests that pin down
  internal details turn every refactor into a busywork session. Tests
  that pin down what the function *promises* protect users while leaving
  you free to rewrite the insides.
- **Arrange–act–assert.** Each
  [`test_that()`](https://testthat.r-lib.org/reference/test_that.html)
  block sets up inputs, calls the function, and makes expectations.
- **TDD as a design tool.** Writing the failing test first forces you to
  design the interface before you write the implementation. It is worth
  doing even occasionally just for that effect.
- **pkgdown is documentation-as-website.** README, function reference,
  vignettes, and custom articles all assemble automatically into a
  navigable site. A pkgdown site is often the first real thing a
  potential user interacts with.
- **CI gates.** GitHub Actions workflows (`check-standard`, `pkgdown`)
  run the full test suite across operating systems and R versions on
  every push. “It works on my machine” stops being a defense.
- **Vignettes are long-form tutorials.** They show how the pieces of the
  package fit together in a real workflow, which function references
  alone can never do.

------------------------------------------------------------------------

## Lecture 7 — Shiny and Reactivity

We saw how providing an interactive Shiny interface on top of your
package can make it accessible to a wider audience. Shiny’s reactive
programming model is powerful but can be confusing at first, because it
is a different way of thinking about code execution. Understanding the
reactivity graph and the different types of reactive expressions is key
to building Shiny apps that are efficient and bug-free.

**Key ideas:**

- **The reactivity graph.** Inputs are sources,
  [`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html)
  expressions are conductors, and `render*()` / `output$*` are
  endpoints. Shiny walks that graph lazily: nothing recomputes until an
  endpoint asks for it.
- **[`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html)
  vs. [`observe()`](https://rdrr.io/pkg/shiny/man/observe.html).**
  [`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html) caches a
  value and only recomputes when a dependency changes.
  [`observe()`](https://rdrr.io/pkg/shiny/man/observe.html) runs side
  effects. Confusing the two is the most common source of surprising
  Shiny bugs.
- **[`eventReactive()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
  gates computation.** Long or expensive work should wait for an
  explicit trigger (a button press, a file upload), not fire on every
  keystroke.
- **[`isolate()`](https://rdrr.io/pkg/shiny/man/isolate.html) reads
  without subscribing.** Useful when you want a value but do not want
  changes to it to retrigger your code.
- **Validate inputs.**
  [`validate()`](https://rdrr.io/pkg/shiny/man/validate.html) +
  [`need()`](https://rdrr.io/pkg/shiny/man/validate.html) produce
  friendly, inline error messages instead of red-flash stack traces.

------------------------------------------------------------------------

## Lecture 8 — Shiny Packaging & Deployment

An `app.R` sitting in a folder is not reproducible. Packaging the app
*inside* the R package makes it installable, versionable, and testable
alongside the rest of the code. We talked about how to structure the app
code, where to put dependencies, what to test, and how to deploy to
different platforms. The details of deployment will depend on your
organization’s infrastructure, but the general principles of packaging
and testing apply everywhere.

**Key ideas:**

- **The `app_ui()` / `app_server()` /
  [`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
  pattern.** UI and server become package functions in `R/`.
  [`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
  is the user-facing entry point; user need only install the package to
  install the app.
- **Dependencies live in DESCRIPTION.** Shiny, bslib, DT, and any other
  packages the app needs get declared the same way every other
  dependency does. No hidden
  [`library()`](https://rdrr.io/r/base/library.html) calls.
- **What to test.** Test the core analysis functions, not the reactive
  plumbing. Reactive behavior is hard to test and tends to churn;
  analysis behavior is stable and tests pay for themselves. `shinytest2`
  exists for smoke tests when you need them.
- **Deployment is a distribution boundary.** Posit Connect Cloud (free
  tier), Posit Connect (self-hosted), and Shiny Server each want
  slightly different scaffolding, typically `inst/app/app.R` plus a
  `manifest.json` produced by `rsconnect::writeManifest()`.

------------------------------------------------------------------------

## Lecture 9 — CLI Design with Rapp

A CLI allows your package functionality to be easily slotted into
pipelines, batch jobs, and HPC clusters. It allows users to call your
code from different contexts without needing to know R.

**Key ideas:**

- **When a CLI earns its keep.** Automation, batch jobs, HPC,
  reproducible scripts. If a human will always be clicking a button,
  build the Shiny app; if the call site is another program, build the
  CLI.
- **Make the contract explicit.** File-based inputs and outputs (not
  stdin for data). Defaults you can live with. Exit codes that mean
  something: `0` success, `1` runtime error, `2` invalid arguments.
  Machine-readable output formats (TSV/JSON) for downstream consumption.
- **Rapp conventions.** Subcommands come from `switch("")`. Typed
  variable declarations (`n_top <- 500L`) become CLI flags (`--n-top`).
  `#|` annotations provide help text. The CLI script lives in `exec/`
  and ships with the package.
- **Launchers with one command.**
  `Rapp::install_pkg_cli_apps("YourPkg")` places executables on the
  user’s PATH. Install the package, install the launchers, call the tool
  by name.
- **The thin-wrapper rule.** The CLI script parses arguments, reads
  files into objects, calls exported package functions, writes outputs.
  No analysis logic. If you find yourself computing something in the CLI
  script that is not also a package function, extract it.
- **Version your CLI contracts.** Argument names, subcommand shapes, and
  output schemas are public promises. Breaking changes belong in
  `NEWS.md` and bump the MAJOR version.

------------------------------------------------------------------------

## Lecture 10 — GitHub as a Collaboration Platform

Git tracks your project history. GitHub provides a place to discuss what
should change, propose a change, review it, and remember why it
happened. These features are useful even when you work alone, because
future-you is a collaborator.

**Key ideas:**

- **Issues are shared memory.** Bugs, feature ideas, design questions.
  They let you close a browser tab and come back next week without
  losing context. Cross-linking (`#123`, `Fixes #47`) weaves issues,
  PRs, and commits into a single narrative.
- **Branches + PRs are proposals.** A PR is a place for CI to validate
  the change, for you (or a reviewer) to look at the diff with fresh
  eyes, and for the rationale to get recorded. Direct pushes to `main`
  skip all three.
- **Self-review, even solo.** Reading your own PR diff before merging
  catches debug prints, stray files, and changes you did not mean to
  make. It costs a minute and saves hours.
- **Code review is knowledge diffusion.** Catching bugs is the obvious
  benefit. The larger ones are onboarding, durable rationale, and shared
  ownership of the codebase.
- **Calibrate process to stakes.** A typo fix does not need a PR. A
  change to a released interface does. Judgment about which is which is
  itself a skill the unit was trying to build.
- **The supporting cast.** Protected `main`, releases and tags,
  discussions, and projects are all tools for keeping a project legible
  as it grows.

------------------------------------------------------------------------

\#General Themes

Several ideas spanned several lectures and are worth highlighting
together here:

- **One core, many interfaces.** The analysis logic lives in exported
  package functions. Shiny and the CLI are thin layers that call them.
- **Public contracts are promises.** Function signatures, CLI arguments,
  file outputs, and help text are commitments to users. Changing them is
  a versioned event.
- **Tests protect behavior.** Their job is to catch regressions and make
  refactoring safe, not to describe how the code works today.
- **Documentation is essential for adoption.** Given the tooling
  available, there is no excuse for poor documentation.
- **Validation enables trust.** Friendly errors in functions, apps, and
  CLIs are part of the product.
- **Clean-room thinking reveals issues.** If the project only works on
  your machine, it is not done.

------------------------------------------------------------------------

## Session Info

``` r
sessionInfo()
```

    ## R version 4.5.3 (2026-03-11)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.4 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
    ## LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
    ## 
    ## locale:
    ##  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    ##  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    ##  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    ## [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    ## 
    ## time zone: UTC
    ## tzcode source: system (glibc)
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] digest_0.6.39     desc_1.4.3        R6_2.6.1          fastmap_1.2.0    
    ##  [5] xfun_0.57         cachem_1.1.0      knitr_1.51        htmltools_0.5.9  
    ##  [9] rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.6         sass_0.4.10      
    ## [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.2        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.2.0       fs_2.1.0          htmlwidgets_1.6.4
