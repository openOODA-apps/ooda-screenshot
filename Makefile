# ooda-screenshot Makefile

VERSION := 0.1.0
REPO_NAME := ooda-screenshot
unexport OODA_OODAR_ROOT OODA_OOSTD_ROOT
OODA_COMPILER ?= $(HOME)/.openooda/bin/ooda-compiler
OODA_VERIFY ?= $(HOME)/.openooda/bin/ooda-verify
OODA_STANDARD_ROOT ?= $(HOME)/.openooda/ooda-standard
OODA_RUNTIME_ROOT ?= $(HOME)/.openooda/bin
OODA_FS_READDIR := $(HOME)/.openooda:$(CURDIR):/tmp
OODA_FS_WRITEDIR := $(HOME)/.openooda:$(HOME)/.local/share:$(HOME)/Pictures:$(CURDIR):/tmp
OODA_MODCACHE ?= $(CURDIR)/.ooda-cache/modcache
export OODA_COMPILER OODA_STANDARD_ROOT OODA_RUNTIME_ROOT OODA_FS_READDIR OODA_FS_WRITEDIR OODA_MODCACHE
OODA_NO_JAIL := 1
export OODA_NO_JAIL
OO_LIST_AMBIENT_QUOTA ?= 8589934592
export OO_LIST_AMBIENT_QUOTA
BIN := bin/ooda-screenshot
FUNC_BIN := .ooda-cache/test_functional
REFUSE_BIN := .ooda-cache/test_refusal
FIND_OO := find . -name "*.oo" -not -path "./.git/*" -not -path "./.ooda-cache/*" -not -path "./bin/*" -not -path "./dist/*"
ENV := OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODA_COMPILER=$(OODA_COMPILER) OODA_STANDARD_ROOT=$(OODA_STANDARD_ROOT) OODA_RUNTIME_ROOT=$(OODA_RUNTIME_ROOT) OODA_FS_READDIR=$(OODA_FS_READDIR) OODA_FS_WRITEDIR=$(OODA_FS_WRITEDIR) OODA_NO_JAIL=1 OODA_MODCACHE=$(OODA_MODCACHE)

.PHONY: all build verify check line-cap file-law academy density vocab shape link-law det test install clean

all: verify build

build: $(BIN)

$(BIN):
	@mkdir -p bin .ooda-cache
	$(ENV) $(OODA_COMPILER) build cli/main.oo -o $(BIN)
	@chmod +x $(BIN)
	@echo "built $(BIN)"

line-cap:
	@v=0; for f in $$(find . \( -name "*.oo" -o -name "*.oot" \) -not -path "./.git/*" -not -path "./.ooda-cache/*" -not -path "./bin/*" -not -path "./dist/*"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then echo "VIOLATION: $$f $$n > 256"; v=$$((v+1)); continue; fi; \
		c=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$c" != "0" ] && [ $$n -lt 16 ]; then echo "VIOLATION: $$f $$n < 16"; v=$$((v+1)); fi; \
	done; [ $$v -eq 0 ] && echo "PASS: line-cap" || exit 1

file-law:
	@for ext in py rs js ts rb pl json yaml toml sh; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.ooda-cache/*" -not -path "./bin/*" -not -path "./dist/*" | head -1); \
		if [ -n "$$found" ]; then echo "VIOLATION: .$$ext $$found"; exit 1; fi; \
	done; echo "PASS: file-law"

academy:
	@for f in $$($(FIND_OO)); do \
		h=$$(head -7 "$$f"); \
		echo "$$h" | grep -q "^// # " && echo "$$h" | grep -q "^// Logline:" && echo "$$h" | grep -q "^// Setup:" && echo "$$h" | grep -q "^// Beats:" || { echo "VIOLATION: academy $$f"; exit 1; }; \
	done; echo "PASS: academy"

density:
	@for d in $$(find . -type d -not -path "./.git*" -not -path "./.ooda-cache*" -not -path "./bin*" -not -path "./dist*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then echo "VIOLATION: $$d has $$n > 8"; exit 1; fi; \
	done; echo "PASS: density"

vocab:
	@if grep -riE 'todo|fixme|xxx|hack|swarm|sentinel|sovereign|classified|moonshot|dogfight|bootstrap' --include="*.oo" --include="*.oot" . ; then exit 1; fi
	@echo "PASS: vocab"

shape:
	@for f in $$($(FIND_OO)); do \
		n=$$(grep -cE "^[[:space:]]*(pub[[:space:]]+)?fn " "$$f" || true); \
		[ $$n -le 8 ] || { echo "VIOLATION: $$f $$n fns"; exit 1; }; \
	done; echo "PASS: shape"

link-law:
	@[ -z "$$(find . -type l -not -path './.git/*' 2>/dev/null)" ] && [ -z "$$(find . -type f -links +1 -not -path './.git/*' 2>/dev/null)" ] && echo "PASS: link-law" || exit 1

check:
	@for f in $$($(FIND_OO)); do \
		$(ENV) $(OODA_COMPILER) check "$$f" > /dev/null || { echo "FAIL check $$f"; exit 1; }; \
	done; echo "PASS: check"

verify: line-cap file-law academy density vocab shape link-law check
	@$(ENV) $(OODA_VERIFY) cycle $(CURDIR) --json | grep -q '"quorum_mask":255' && echo "PASS: ooda-verify quorum_mask=255"

det: $(BIN)
	@mkdir -p .ooda-cache
	@$(ENV) $(OODA_COMPILER) build cli/main.oo -o .ooda-cache/det_a > /dev/null
	@$(ENV) $(OODA_COMPILER) build cli/main.oo -o .ooda-cache/det_b > /dev/null
	@cmp -s .ooda-cache/det_a .ooda-cache/det_b && sha256sum .ooda-cache/det_a && echo "PASS: det"

test: $(BIN)
	@mkdir -p .ooda-cache
	@$(ENV) $(OODA_COMPILER) build tests/test_functional.oo -o $(FUNC_BIN) > /dev/null
	@$(ENV) $(OODA_COMPILER) build tests/test_refusal.oo -o $(REFUSE_BIN) > /dev/null
	@$(ENV) ./$(FUNC_BIN)
	@$(ENV) ./$(REFUSE_BIN)
	@./$(BIN) --version | grep -q "ooda-screenshot $(VERSION)"
	@./$(BIN) --help | grep -q "ooda-screenshot $(VERSION)"
	@$(ENV) ./$(BIN) capture --mode region --delay 0 --out /tmp/ooda_shot_mk.ppm | grep -q "captured"
	@rm -f /tmp/ooda_shot_mk.ppm
	@./$(BIN) about --json | grep -q '"component":"ooda-screenshot"'
	@./$(BIN) --bogus-flag >/dev/null 2>&1; [ $$? -eq 2 ]
	@echo "ALL TESTS PASSED"

install: $(BIN)
	@mkdir -p $(HOME)/.openooda/bin
	install -m 0755 $(BIN) $(HOME)/.openooda/bin/$(REPO_NAME)
	$(ENV) $(HOME)/.openooda/bin/$(REPO_NAME) --install-desktop
	@echo "installed $(REPO_NAME) to $(HOME)/.openooda/bin"

clean:
	@rm -rf bin dist .ooda-cache
