# Primes-CPP

Primes-CPP is a small C++ project designed to serve as a practical testbed for a complete CI pipeline.
The codebase itself is intentionally simple: a minimal library with functions such as integer addition and prime number detection, a thin application entrypoint, and unit tests. By keeping the application itself simple, the project emphasizes the end-to-end automation flow from checkout to publish making it ideal for experimenting with toolchains, validating pipeline configurations, and serving as a template for larger C++ projects.

> For details on how this project is integrated into a full CI/CD workflow, including automated builds, tests, and analysis stages, please refer to the [jenkins-pipeline](https://github.com/ManiAm/Jenkins-pipeline) project.

## Project Layout

The project is organized as follows:

    Project Root
    ├── src/                  # Core library source files
    │   ├── calc.h            # Header for calculator functions
    │   └── calc.cpp          # Implementation of calculator logic
    ├── app/                  # Application entry point(s)
    │   └── main.cpp          # Main program source
    ├── tests/                # Unit and integration tests
    │   └── test_calc.cpp     # Tests for calculator module
    ├── Makefile              # Build automation rules
    ├── .clang-format         # Code style configuration
    ├── conanfile.txt         # Conan package dependencies
    └── Jenkinsfile           # CI pipeline definition

### src/

This directory contains the source code and headers for the project. For a small codebase it is acceptable to keep headers alongside `.cpp` files. As the project grows, it is considered best practice to split public headers into an `include/` directory while keeping implementation files in `src/`. This allows usage like `-Iinclude` and `#include <calc/calc.h>`, which cleanly separates public APIs from internal code. Headers should use `#pragma once`, and compilation should enforce strict warning flags.

### app/

This directory contains entrypoints and runnable binaries. The `main.cpp` file is kept intentionally thin. It parses arguments and delegates logic to functions implemented in `src/`. If additional tools or CLIs are added in the future, place them here (e.g., `prime_cli.cpp`) to keep the core library testable and decoupled from input/output concerns.

### tests/

This directory contains unit tests for validating the behavior of code in `src/`. The project uses [Catch2](https://github.com/catchorg/Catch2) test framework, so `test_calc.cpp` both defines test cases and provides the test runner. Tests produce JUnit XML reports, which CI systems can use to visualize pass/fail status and track trends.

### Makefile

The Makefile defines one target per CI pipeline stage: lint, static, build, test, coverage, and package. This design ensures that the local developer workflow matches the pipeline exactly. The compiler can be switched easily (`CXX=clang++` or `CXX=g++`) without modifying the Makefile itself.

## Header File Dependencies

In C++ projects, header file dependencies are a critical aspect of reliable builds. When a header file is modified, every source file that includes it must be recompiled to ensure consistency. If the build system is unaware of these dependencies, it may skip recompilation, leaving behind stale object files. This can result in subtle issues such as mismatched symbols, linker errors, or even runtime crashes caused by outdated code.

For small projects, manually specifying which sources depend on which headers might be manageable, but in larger codebases this quickly becomes error-prone and difficult to maintain. Modern build workflows avoid this by automatically generating dependency files (commonly `.d` files produced by compilers with flags like `-MMD -MP` in GCC/Clang) and including them in the build process. With this approach, any change to a header automatically triggers recompilation of all dependent sources, keeping the build consistent without manual intervention.

While `Make` can handle dependency files effectively, other build systems such as CMake, Meson, or Bazel provide more advanced and integrated dependency tracking. These tools simplify large-scale builds by managing header dependencies transparently, improving correctness and developer productivity.

## C++ Package Managers

C++ lacks a standardized package management system like Python's `pip`, JavaScript's `npm` or Java's `Maven`. Manually managing dependencies often leads to errors, compatibility issues, and duplication. C++ package managers are specialized tools designed to manage C++ libraries and their dependencies in software development projects. They handle source code, prebuilt binaries, versioning, and build configurations, integrating with many build systems.

Among C++ package managers, [Conan](https://conan.io/) and [vcpkg](https://vcpkg.io/en/) are the most powerful and widely used tools. `Conan` is generally considered more powerful due to its customizability, enterprise features, and wider platform support. It is written in Python and is the industry standard for handling complex C++ projects. `vcpkg`, while simpler, is more suitable for smaller projects or Windows-based development where ease of setup and integration with Visual Studio are priorities. We are going to use Conan in our project.

## Getting Started

Start the container in background:

    docker compose up -d --build

Open an interactive shell to the container:

    docker exec -it primes-cpp bash

To run the code formatting and linting checks:

    make lint

If linting does not pass, you can auto-apply formatting:

    make format

Run static code analysis using cppcheck:

    make static

The output is saved into `cppcheck.xml` file.

Compiles the app:

    make -j build

Run the app:

    ./build/bin/demo

Sample output:

    2 + 3 = 5
    Is 17 prime? yes

Run tests:

    make -j test

The test results are stored in `test-results` folder, and you can print it with:

    make test-console

Generate code coverage:

    make coverage

Open the `coverage` folder to view the coverage HTML report.

<img src="pics/coverage.png" alt="segment" width="700">

The `make package` target bundles everything produced by the pipeline into a single distributable artifact. It first ensures the project is built and tested, then collects the application binary, test results (e.g., JUnit XML), and analysis reports (e.g., `cppcheck.xml`). These files are packaged into a versioned tarball (named with the project’s Git tag or commit SHA) under the `dist/` directory, and a SHA-256 checksum file is generated for integrity verification. This provides a reproducible snapshot of the build, complete with binaries, reports, and metadata, suitable for archival or later publication.

    make package

## CI Pipeline

A `Jenkinsfile` is a plain text file, written in Groovy-based syntax, that defines a Jenkins pipeline as code. It specifies the stages, steps, and environment required to build, test, and deploy an application, providing a reproducible and version-controlled automation process directly alongside the source code. By treating the pipeline as code, teams gain consistency, collaboration, and traceability, since changes to the CI process are reviewed, versioned, and managed just like application code. Each branch, tag, or commit can carry its own pipeline definition, making the CI process fully reproducible and context-aware.

### Checkout

The pipeline begins by fetching the exact commit to build and setting up a clean, reproducible workspace. A shallow clone is usually sufficient unless full history is required. Build caches (for example, `ccache`) may be restored to speed up subsequent steps. It is also good practice to record immutable build metadata (commit SHA, branch or PR number, build identifier, and tool versions) so that results are traceable and reproducible.

### Linting

Linting enforces consistent code style early in the process, ensuring quick failure before investing time in compilation. For C++, `clang-format --dry-run --Werror -style=file` can be used to enforce formatting rules defined in `.clang-format`. Style compliance should be non-negotiable across all branches and pull requests. For developers, `make format` provides a convenient way to auto-fix style locally, and pre-commit hooks can catch violations before they reach the pipeline. The CI gate (`make format-check`) ensures the codebase never drifts from the agreed standard.

### Static Code Analysis

Static analysis detects correctness, safety, and performance issues without executing the program. A lightweight, compiler-independent tool such as `cppcheck` can analyze source files directly, providing warnings about memory management, portability, style, and potential runtime errors. Its XML output can be integrated into automated pipelines for trend tracking and machine-readable reporting. For CI, it is good practice to treat serious findings as build-breaking, while allowing style or lower-severity issues to surface as warnings for incremental cleanup. Running static analysis early (before the build stage) saves resources and gives developers fast feedback on potential problems. For projects that require deeper semantic checks, `clang-tidy` can also be added to improve accuracy by leveraging real compiler flags and AST analysis.

### Build

The build stage compiles the project deterministically with strict flags (e.g., `-Wall -Wextra`). The Makefile provides a clear entrypoint and supports switching compilers (`g++` vs. `clang++`). For projects requiring portability, a compiler or OS matrix can be introduced. Build caches like `ccache` help accelerate repeated builds. The output binaries are placed in `build/bin/` and can be archived or passed to later stages (tests, packaging). Explicit dependency versions ensure that builds are reproducible and not subject to "works on my machine" failures.

### Test

Automated testing is an important part of maintaining code quality. Tests can be grouped into the following groups:

- **Unit Testing**:

    Unit testing verifies the smallest components of the codebase (functions, classes, or modules) in isolation. These tests ensure that individual units behave as expected given specific inputs. Unit tests should avoid external dependencies such as databases or networks, making them fast to execute and deterministic in results. They provide developers with immediate feedback during local development and in CI pipelines.

- **Integration Testing**:

    Integration testing validates that multiple components work correctly when combined. While unit tests prove correctness in isolation, integration tests catch issues that only appear when components interact. For example, a parser feeding data into a calculator or application code calling into a database. Integration tests may involve real or simulated dependencies and tend to run slower than unit tests, but they are critical for uncovering systemic issues.

    A popular analogy highlights the difference between unit and integration testing. Imagine a door secured by both a lock and a latch. A unit test checks that the latch closes correctly when tested in isolation, while an integration test verifies that the latch and the door handle together actually keep the door secure. This distinction illustrates why both levels of testing are needed for confidence in a system’s overall behavior.

    <img src="pics/testing.gif" alt="segment" width="350">

- **Regression Testing**:

    Regression testing ensures that previously working functionality continues to work after new changes are introduced. When a bug is fixed, a regression test is typically added to reproduce the original failure and confirm that it does not recur. Over time, the regression suite becomes a safety net, preventing old issues from reappearing and giving developers confidence when making changes to a growing codebase.

These tests can be executed in parallel to shorten feedback loops. Failures should always produce actionable logs that make issues easy to reproduce locally.

In this project, the `Catch2` framework is used for unit testing, with `make test` as the entry point. Test runs generate JUnit XML output, which can be consumed by CI systems to visualize results, track historical trends, and highlight failures early in the development cycle.

### Code Coverage

Code coverage measures how much of the source is exercised by tests, reducing the risk of untested regressions. The project can be built with coverage flag (`--coverage`), after which tests are executed and coverage reports generated using `gcovr`. Reports should include both human-readable HTML and machine-readable formats (e.g., Cobertura XML) for automated enforcement. Coverage gates are best applied pragmatically: enforce no decrease relative to main or set thresholds per change, rather than rigid global minimums that encourage low-value tests.

### Distribution Workflow

- Package → Create artifacts
- Publish → Push artifacts to repositories/registries
- Release → Tag and announce an official version for end users

**Package**

When builds and tests succeed, outputs are bundled into distributable artifacts. These may include compressed archives (e.g., tarballs, ZIPs), operating system packages (DEB/RPM), or container images. Each artifact should be versioned using semantic versioning with optional commit metadata (e.g., `1.2.0+abc123`) to ensure traceability. To guarantee integrity, checksums (e.g., SHA-256) should be generated, and for supply chain security, additional metadata such as SBOMs (via tools like `syft`) and cryptographic signatures (via tools like `cosign`) can be attached. A well-packaged artifact is minimal containing only the files and dependencies required by consumers and should include concise documentation or metadata describing runtime requirements.

**Publish**

Publishing makes validated artifacts available to others by promoting them to their designated destinations under controlled conditions. Targets may include package repositories (e.g., Artifactory, Nexus, PyPI, Maven Central), container registries (e.g., Docker Hub, ECR, GCR), or distribution platforms such as GitHub Releases. Publishing credentials must follow the principle of least privilege and be rotated regularly. Published artifacts should be annotated with changelogs, version tags, and links back to the originating build for full traceability. To strengthen consumer trust, optional metadata such as SLSA provenance attestations, SBOMs, and digital signatures should be attached so downstream systems and users can verify authenticity and integrity before deployment.

**Release**

A release marks the formal distribution of a software version to end users, distinguishing it from internal builds or unpublished artifacts. A release is both a technical milestone and a product event, usually represented by a semantic version tag (e.g., `v1.2.0`) in source control. It should be immutable, reproducible, and traceable to a specific commit and build pipeline. A proper release includes release notes summarizing new features, bug fixes, and breaking changes, ideally auto-generated from commits or pull requests. Distribution is handled through established channels such as GitHub/GitLab Releases, customer portals, or internal delivery pipelines. In mature CI processes, releases are gated by quality controls (security scans, compliance checks, stakeholder approvals) and may trigger downstream workflows such as deployment to production or notifications to customers.

## Ephemeral Docker Build Environment

The Jenkins pipeline is designed so that all build, test, and analysis stages run inside ephemeral Docker containers rather than directly on the Jenkins agent. At the start of the pipeline, Jenkins builds the project’s Docker image (as defined in the Dockerfile) to encapsulate the full toolchain, dependencies, and runtime environment. Subsequent stages in the Jenkinsfile are executed inside disposable containers instantiated from this freshly built image. This workflow ensures several advantages:

- **Clean Separation of Concerns**: The Jenkins agents only need Docker installed; they do not require any compilers, libraries, or runtimes. All dependencies remain confined within the container image.

- **Consistency and Reproducibility**: Because the image is built from a version-controlled Dockerfile, every pipeline run uses the exact same environment. This eliminates "works on my machine" issues and ensures reproducible builds across agents.

- **Polyglot Flexibility**: Different pipelines can provide different Dockerfiles, making it straightforward to support multiple languages or toolchains without cross-contamination.

- **Stateless Execution**: Containers are ephemeral. Once a stage completes, the container is discarded, leaving no residual state behind. Each run starts from a clean, deterministic environment, which improves the reliability of test results, static analysis, and coverage reports.

By adopting this model, the pipeline guarantees that the CI process remains portable, maintainable, and free from dependency drift, while still enabling Jenkins to orchestrate the stages inside containerized environments.
