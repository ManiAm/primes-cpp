
# Primes-CPP

Primes-CPP is a small C++ project designed to serve as a practical testbed for a complete CI/CD pipeline.
The codebase itself is intentionally simple: a minimal library with functions such as integer addition and prime number detection, a thin application entrypoint, and unit tests implemented using Catch2. By keeping the application itself simple, the project emphasizes the end-to-end automation flow from checkout to publish making it ideal for experimenting with toolchains, validating pipeline configurations, and serving as a template for larger C++ projects.

## Project Layout

The project is organized as follows:

    ├── src/
    │   ├── calc.h
    │   └── calc.cpp
    ├── app/
    │   └── main.cpp
    ├── tests/
    │   └── test_calc.cpp
    ├── Makefile

### src/

This directory contains the source code and headers for the project. For a small codebase it is acceptable to keep headers alongside `.cpp` files. As the project grows, it is considered best practice to split public headers into an `include/` directory while keeping implementation files in `src/`. This allows usage like `-Iinclude` and `#include <calc/calc.h>`, which cleanly separates public APIs from internal code. Headers should use `#pragma once`, and compilation should enforce strict warning flags.

### app/

This directory contains entrypoints and runnable binaries. The `main.cpp` file is kept intentionally thin. It parses arguments and delegates logic to functions implemented in `src/`. If additional tools or CLIs are added in the future, place them here (e.g., `prime_cli.cpp`) to keep the core library testable and decoupled from input/output concerns.

### tests/

This directory contains unit tests for validating the behavior of code in `src/`. The project uses [Catch2](https://github.com/catchorg/Catch2) test framework, so `test_calc.cpp` both defines test cases and provides the test runner. Tests produce JUnit XML reports, which CI systems can use to visualize pass/fail status and track trends. The Catch2 single-header dependency can be pulled in automatically using the Makefile’s deps target or vendored into `tests/vendor/` to avoid network fetches during CI runs.

### Makefile

The Makefile defines one target per CI/CD pipeline stage: lint, static, build, test, coverage, and release. This design ensures that the local developer workflow matches the pipeline exactly. The compiler can be switched easily (`CXX=clang++` or `CXX=g++`) without modifying the Makefile itself.

## Header File Dependencies

In C++ projects, header file dependencies are a critical aspect of reliable builds. When a header file is modified, every source file that includes it must be recompiled to ensure consistency. If the build system is unaware of these dependencies, it may skip recompilation, leaving behind stale object files. This can result in subtle issues such as mismatched symbols, linker errors, or even runtime crashes caused by outdated code.

For small projects, manually specifying which sources depend on which headers might be manageable, but in larger codebases this quickly becomes error-prone and difficult to maintain. Modern build workflows avoid this by automatically generating dependency files (commonly `.d` files produced by compilers with flags like `-MMD -MP` in GCC/Clang) and including them in the build process. With this approach, any change to a header automatically triggers recompilation of all dependent sources, keeping the build consistent without manual intervention.

While `Make` can handle dependency files effectively, other build systems such as CMake, Meson, or Bazel provide more advanced and integrated dependency tracking. These tools simplify large-scale builds by managing header dependencies transparently, improving correctness and developer productivity.

## C++ Package Managers

C++ lacks a standardized package management system like Python's `pip`, JavaScript's `npm` or Java's `Maven`. Manually managing dependencies often leads to errors, compatibility issues, and duplication. C++ package managers are specialized tools designed to manage C++ libraries and their dependencies in software development projects. They handle source code, prebuilt binaries, versioning, and build configurations, integrating with many build systems.

Among C++ package managers, [Conan](https://conan.io/) and [vcpkg](https://vcpkg.io/en/) are the most powerful and widely used tools. `Conan` is generally considered more powerful due to its customizability, enterprise features, and wider platform support. It is written in Python and is the industry standard for handling complex C++ projects. `vcpkg`, while simpler, is more suitable for smaller projects or Windows-based development where ease of setup and integration with Visual Studio are priorities. We are going to use Conan in our project.

## CI/CD Pipeline

### Checkout

The pipeline begins by fetching the exact commit to build and setting up a clean, reproducible workspace. A shallow clone is usually sufficient unless full history is required. Submodules are initialized, and lightweight setup tasks such as `make deps` can fetch header-only libraries. Build caches (for example, `ccache`) may be restored to speed up subsequent steps. It is also good practice to record immutable build metadata (commit SHA, branch or PR number, build identifier, and tool versions) so that results are traceable and reproducible.

### Linting

Linting enforces consistent code style early in the process, ensuring quick failure before investing time in compilation. For C++, `clang-format --dry-run --Werror -style=file` can be used to enforce formatting rules defined in `.clang-format`. Style compliance should be non-negotiable across all branches and pull requests. For developers, `make format` provides a convenient way to auto-fix style locally, and pre-commit hooks can catch violations before they reach the pipeline. The CI gate (`make format-check`) ensures the codebase never drifts from the agreed standard.

### Static Code Analysis

Static analysis detects correctness, safety, and performance issues without executing the program. A lightweight, compiler-independent tool such as `cppcheck` can analyze source files directly, providing warnings about memory management, portability, style, and potential runtime errors. Its XML output can be integrated into automated pipelines for trend tracking and machine-readable reporting. For CI, it is good practice to treat serious findings as build-breaking, while allowing style or lower-severity issues to surface as warnings for incremental cleanup. Running static analysis early (before the build stage) saves resources and gives developers fast feedback on potential problems. For projects that require deeper semantic checks, `clang-tidy` can also be added to improve accuracy by leveraging real compiler flags and AST analysis.

### Build

The build stage compiles the project deterministically with strict flags (e.g., `-Wall -Wextra`). The Makefile provides a clear entrypoint and supports switching compilers (`g++` vs. `clang++`). For projects requiring portability, a compiler or OS matrix can be introduced. Build caches like `ccache` help accelerate repeated builds. The output binaries are placed in `build/bin/` and can be archived or passed to later stages (tests, packaging). Explicit dependency versions ensure that builds are reproducible and not subject to "works on my machine" failures.

### Test

Unit tests validate the behavior of the code. Tests should be fast, hermetic, and deterministic to avoid flaky results. The project uses `Catch2` as the unit test framework with `make test` as the entrypoint. Test runs generate JUnit XML results, which can be consumed by CI systems to visualize pass/fail outcomes and track trends over time. As test volume grows, they can be grouped into categories (unit, integration, regression) and executed in parallel to shorten feedback cycles. Failures should surface with actionable logs so they can be reproduced locally.

### Code Coverage

Code coverage measures how much of the source is exercised by tests, reducing the risk of untested regressions. The project can be built with coverage flag (`--coverage`), after which tests are executed and coverage reports generated using `gcovr`. Reports should include both human-readable HTML and machine-readable formats (e.g., Cobertura XML) for automated enforcement. Coverage gates are best applied pragmatically: enforce no decrease relative to main or set thresholds per change, rather than rigid global minimums that encourage low-value tests.

### Package

When builds and tests succeed, outputs are bundled into distributable artifacts. These may be compressed archives (tarball/zip), operating system packages (DEB/RPM), or container images. Artifacts should be versioned using semantic versioning and commit metadata (e.g., `1.2.0+abc123`), and accompanied by integrity checks (SHA-256). For supply-chain integrity, additional assets such as SBOMs (via syft) and signatures (via cosign) may be generated. Packages should remain minimal (containing only what consumers require) and include documentation for runtime dependencies.

### Publish

The final stage promotes validated artifacts to their destinations under controlled conditions (typically on protected branches or tags). Destinations might include GitHub Releases, package repositories (e.g., Artifactory, Nexus), or container registries. Credentials used for publishing should follow the principle of least privilege. Releases should be annotated with changelogs and linked back to the build for traceability. Optionally, provenance metadata (SLSA attestations), SBOMs, and cryptographic signatures can be attached so downstream users can verify authenticity and integrity.

## Setting up Conan

You can build and test this project by using Conan as a package manager for a cleaner, virtual-env style workflow. Conan can be used to fetch dependencies without polluting system packages. This also enables an activatable build/run environment, similar to Python’s virtualenv.

Install Conan:

    pip install conan

Initialize configuration:

    conan profile detect --force

This detects and configures the default profile based on your environment

Install dependencies into a local folder:

    conan install . --output-folder=build/conan --build=missing

This generates activation scripts and `pkg-config` files in `build/conan`.

Activate the Conan environment:

    source build/conan/conanbuild.sh

This sets up compilers, include paths, and linker flags from Conan.

Deactivate later with:

    source build/conan/deactivate_conanbuild.sh

## Getting Started

Install the following tools:

    export DEBIAN_FRONTEND=noninteractive
    sudo apt install -y pkg-config clang-format cppcheck gcovr

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

The `make release` target bundles everything produced by the pipeline into a single distributable artifact. It first ensures the project is built and tested, then collects the application binary, test results (JUnit XML), and analysis reports such as `cppcheck.xml`. These files are packaged into a versioned tarball (named with the project’s git tag or commit SHA) under the `dist/` directory, and a SHA-256 checksum file is generated for integrity verification. This makes it easy to archive or publish a reproducible snapshot of the build, complete with binaries, reports, and metadata, so downstream users or CI/CD systems can consume it as a release artifact.

    make release
