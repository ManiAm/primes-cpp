# ---------------------------
# Toolchain & Flags
# ---------------------------
BASE_CXXFLAGS := -std=c++17 -Wall -Wextra -Wpedantic
OPT_CXXFLAGS  := -O2
COV_ONLY      := -O0 -g --coverage
DEPFLAGS      := -MMD -MP

CXX       ?= g++
CXXFLAGS  ?= $(BASE_CXXFLAGS) $(OPT_CXXFLAGS)
LDFLAGS   ?=
INCLUDES  := -Isrc

# Conan / pkg-config integration
PKGCONF_DIR := $(abspath build/conan)
PKG_MODULES := catch2-with-main fmt

ifneq ("$(wildcard $(PKGCONF_DIR))","")
  CONAN_CFLAGS  := $(shell PKG_CONFIG_PATH=$(PKGCONF_DIR) pkg-config --cflags $(PKG_MODULES) 2>/dev/null)
  CONAN_LDFLAGS := $(shell PKG_CONFIG_PATH=$(PKGCONF_DIR) pkg-config --libs   $(PKG_MODULES) 2>/dev/null)
  INCLUDES += $(CONAN_CFLAGS)
  LDFLAGS  += $(CONAN_LDFLAGS)
endif

# ---------------------------
# Directories
# ---------------------------
BUILD_DIR := build
BIN_DIR   := $(BUILD_DIR)/bin
OBJ_DIR   := $(BUILD_DIR)/obj
TEST_OUT  := test-results
DIST_DIR  := dist

COV_BUILD := build-cov
COV_BIN   := $(COV_BUILD)/bin
COV_OBJ   := $(COV_BUILD)/obj
COV_OUT   := coverage

# ---------------------------
# Sources / Targets
# ---------------------------
APP_SRC   := app/main.cpp src/calc.cpp
APP_OBJS  := $(APP_SRC:%=$(OBJ_DIR)/%.o)
APP_BIN   := $(BIN_DIR)/demo

TEST_SRC  := tests/test_calc.cpp src/calc.cpp
TEST_OBJS := $(TEST_SRC:%=$(OBJ_DIR)/%.o)
TEST_BIN  := $(BIN_DIR)/run_tests

# ---------------------------
# Phony targets
# ---------------------------
.PHONY: lint format-check format static cppcheck \
        build test test-console \
        coverage coverage-build-internal \
        package \
        clean distclean

# ---------------------------
# Lint (clang-format)
# ---------------------------
lint: format-check
	@echo "Linting passed."

format-check:
	@FILES=$$(git ls-files "*.h" "*.hpp" "*.c" "*.cc" "*.cpp"); \
	if [ -n "$$FILES" ]; then \
	  clang-format --dry-run --Werror -style=file $$FILES; \
	else \
	  echo "No C/C++ files."; \
	fi

format:
	@FILES=$$(git ls-files "*.h" "*.hpp" "*.c" "*.cc" "*.cpp"); \
	[ -z "$$FILES" ] || clang-format -i -style=file $$FILES

# ---------------------------
# Static analysis (no compile): cppcheck -> cppcheck.xml
# ---------------------------
static: cppcheck
	@echo "Static analysis complete."

cppcheck:
	@echo "Running cppcheck..."
	@cppcheck --std=c++17 \
	  --enable=warning,style,performance,portability \
	  -Isrc --inline-suppr \
	  --xml --xml-version=2 . 2> cppcheck.xml || true

# ---------------------------
# Build / Link
# ---------------------------
build: $(APP_BIN)
	@file $(APP_BIN) >/dev/null 2>&1 || true
	@echo "Build complete: $(APP_BIN)"

$(APP_BIN): $(APP_OBJS)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)

test: $(TEST_BIN)
	@mkdir -p $(TEST_OUT)
	$(TEST_BIN) --reporter junit --out $(TEST_OUT)/junit.xml

test-console: $(TEST_BIN)
	$(TEST_BIN) -r console -s

$(TEST_BIN): $(TEST_OBJS)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)

# Compile rules with auto dep generation (.d files)
$(OBJ_DIR)/%.cpp.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(DEPFLAGS) -MF $(@:.o=.d) -c $< -o $@

# ---------------------------
# Coverage build & report
# ---------------------------
coverage:
	@echo "Building with coverage flags..."
	@mkdir -p $(COV_OBJ) $(COV_BIN) $(COV_OUT)
	$(MAKE) \
	  CXXFLAGS="$(BASE_CXXFLAGS) $(COV_ONLY)" \
	  LDFLAGS="$(LDFLAGS) --coverage" \
	  APP_OBJS="$(APP_SRC:%=$(COV_OBJ)/%.o)" \
	  TEST_OBJS="$(TEST_SRC:%=$(COV_OBJ)/%.o)" \
	  APP_BIN="$(COV_BIN)/demo" \
	  TEST_BIN="$(COV_BIN)/run_tests" \
	  coverage-build-internal

	@echo "Running tests (coverage build)..."
	$(COV_BIN)/run_tests --reporter junit --out $(COV_OUT)/junit.xml || true

	@echo "Generating coverage report (gcovr)..."
	@if command -v gcovr >/dev/null 2>&1; then \
	  if gcovr --help 2>/dev/null | grep -q -- '--html-details .*OUTPUT'; then \
	    gcovr -r . \
	      --filter 'src/.*' \
	      --xml-pretty --output $(COV_OUT)/coverage.xml \
	      --html-details $(COV_OUT)/index.html; \
	  else \
	    gcovr -r . \
	      --filter 'src/.*' --filter 'app/.*' \
	      --xml -o $(COV_OUT)/coverage.xml \
	      --html-details -o $(COV_OUT)/index.html; \
	  fi; \
	  echo "Coverage reports in $(COV_OUT)/ (open index.html)"; \
	else \
	  echo "gcovr not found; install it to generate reports."; \
	fi

coverage-build-internal: $(COV_BIN)/demo $(COV_BIN)/run_tests

$(COV_BIN)/demo: $(APP_SRC:%=$(COV_OBJ)/%.o)
	@mkdir -p $(COV_BIN)
	$(CXX) $(BASE_CXXFLAGS) $(COV_ONLY) $^ -o $@ $(LDFLAGS) --coverage

$(COV_BIN)/run_tests: $(TEST_SRC:%=$(COV_OBJ)/%.o)
	@mkdir -p $(COV_BIN)
	$(CXX) $(BASE_CXXFLAGS) $(COV_ONLY) $^ -o $@ $(LDFLAGS) --coverage

# Coverage compile rule with deps
$(COV_OBJ)/%.cpp.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(BASE_CXXFLAGS) $(COV_ONLY) $(INCLUDES) $(DEPFLAGS) -MF $(@:.o=.d) -c $< -o $@

# ---------------------------
# Package
# ---------------------------
package: lint static build test package
	@mkdir -p $(DIST_DIR)
	@VER=$$(git describe --tags --always --dirty 2>/dev/null || echo "0.0.0"); \
	SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo "dev"); \
	NAME=demo-$$VER+$$SHA; \
	TARBALL=$(DIST_DIR)/$$NAME.tar.gz; \
	echo "Packaging $$TARBALL"; \
	FILES="$(APP_BIN)"; \
	[ -f "$(TEST_OUT)/junit.xml" ] && FILES="$$FILES $(TEST_OUT)/junit.xml"; \
	[ -f "cppcheck.xml" ] && FILES="$$FILES cppcheck.xml"; \
	[ -f "clang-tidy.log" ] && FILES="$$FILES clang-tidy.log"; \
	[ -d "$(COV_OUT)" ] && FILES="$$FILES $(COV_OUT)"; \
	echo "Built on: $$(date -u)" > MANIFEST.txt; \
	echo "Commit:  $$(git rev-parse HEAD 2>/dev/null || echo dev)" >> MANIFEST.txt; \
	echo "Compiler: $$($(CXX) --version | head -1)" >> MANIFEST.txt; \
	FILES="$$FILES MANIFEST.txt"; \
	tar -czf $$TARBALL --transform "s,^,$$NAME/," $$FILES; \
	rm -f MANIFEST.txt; \
	if command -v sha256sum >/dev/null 2>&1; then sha256sum $$TARBALL > $$TARBALL.sha256; fi; \
	echo "Saved artifacts in $(DIST_DIR)/"

# ---------------------------
# Clean
# ---------------------------
clean:
	@rm -rf $(BUILD_DIR) $(COV_BUILD) $(TEST_OUT) $(COV_OUT) \
	        clang-tidy.log cppcheck.xml

distclean: clean
	@rm -rf $(DIST_DIR)

# ---------------------------
# Auto-include dependency files (.d)
# ---------------------------
DEPS := $(APP_OBJS:.o=.d) $(TEST_OBJS:.o=.d)
COV_APP_OBJS  := $(APP_SRC:%=$(COV_OBJ)/%.o)
COV_TEST_OBJS := $(TEST_SRC:%=$(COV_OBJ)/%.o)
COV_DEPS      := $(COV_APP_OBJS:.o=.d) $(COV_TEST_OBJS:.o=.d)

-include $(DEPS) $(COV_DEPS)
