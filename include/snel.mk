# This is the main `snel.mk` module. It sets the variables that all of `snel`
# needs, and it collects the target documents and resources. It also generates
# the index page linking to them.
# However, there are no actual recipes to *make* the targets. You'll need to
# also `include snel-doc.mk`, or instead write your own.

# Location of this Makefile.
BASE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Installation directories.
PREFIX := /usr/local
INCLUDE_DIR := $(PREFIX)/include
SHARE_DIR := $(PREFIX)/share/snel

# If installed globally, then we should be able to find other assets in
# $PREFIX/share/snel. Otherwise, find them relative to the current Makefile.
ifeq ($(BASE_DIR),$(INCLUDE_DIR))
	ASSET_DIR := $(SHARE_DIR)
else
	ASSET_DIR := $(BASE_DIR)/../share
endif
STYLE_DIR := $(ASSET_DIR)/style
JQ_DIR := $(ASSET_DIR)/jq
PANDOC_DIR := $(ASSET_DIR)/pandoc

# Source and destination directories.
ifndef SRC
	SRC := .
endif
ifndef DEST
	DEST := build
endif
ifndef CACHE
	CACHE := $(DEST)/.cache
endif
ifndef IGNORE
	IGNORE=Makefile .git .gitignore
endif
IGNORE:=$(IGNORE) $(CACHE) $(DEST)

# Find potential source Markdown files.
SOURCE_FILES = $(shell \
	find -L "$(SRC)" \
	$(patsubst %,-path '%' -prune -o,$(IGNORE)) \
	-iname '*.md' \
	-exec grep -li --perl-regexp '^\s*make:\s*((?!(false|null|\[\])).*)$$' {} \; \
	-print \
)

EXTRA_HTML_TARGETS = $(addprefix $(DEST)/,\
	index.html \
	$(if $(wildcard $(SRC)/favicon.*),favicon.ico apple-touch-icon.png)\
)

.PHONY: all html pdf
all: html pdf
all html pdf: $(CACHE)/dynamic.mk

include $(CACHE)/dynamic.mk

# Record metadata for each document, including external resources linked inside
$(CACHE)/%.md.meta.json: $(SRC)/%.md $(JQ_DIR)/snel.jq $(PANDOC_DIR)/metadata.json $(PANDOC_DIR)/resources.lua
	@-mkdir -p "$(@D)"
	@echo "Generating metadata for \"$<\"..." 1>&2
	@pandoc --to=plain --template='$(PANDOC_DIR)/metadata.json' \
		$(foreach F,$(filter %.lua, $^), --lua-filter='$(F)') \
		"$<" \
	| jq \
		-L"$(JQ_DIR)" \
		--arg path "$(patsubst $(CACHE)/%.md.meta.json,%.md,$@)" \
		'include "snel"; tree(["."] + ($$path | split("/")))' \
		> "$@"

# Overview of files & directories with metadata, readable for index template.
# Compatible for merging with the output of `tree -JDpi --du --timefmt '%s'` 
$(CACHE)/index.json: $(JQ_DIR)/snel.jq $(wildcard $(SRC)/index.base.json) \
		$(patsubst $(SRC)/%,$(CACHE)/%.meta.json,$(SOURCE_FILES))
	@-mkdir -p $(@D)
	@echo "Generating index data \"$@\"..." 1>&2
	@jq  -L$(JQ_DIR) --slurp \
		'include "snel"; index(["html","pdf"])' \
		$(filter %.json, $^) \
		> "$@"

# Generate a file enumerating the dynamic targets for HTML/PDF documents and
# any external content referred inside
$(CACHE)/targets.json: $(CACHE)/index.json
	@jq -c -L"$(JQ_DIR)" --arg dest "$(DEST)" \
		'include "snel"; targets($$dest)' < "$<" > "$@"
	@($(foreach target,$(EXTRA_HTML_TARGETS),echo "$(target)";)) \
		| jq -R -c '{"target":"html", "dependencies": [.]}' >> "$@"

$(CACHE)/dynamic.mk: $(CACHE)/targets.json
	@jq -r '"\(.target): \(.dependencies | join(" "))"' < "$<" > "$@"

$(CACHE)/targets.txt: $(CACHE)/targets.json
	@jq -r --slurp '.[].dependencies[] | unique | .[]' < "$<" > "$@"

# Optionally, remove all files in $(DEST) that are no longer targeted
.PHONY: clean
clean: $(CACHE)/targets.txt
	@bash -i -c 'read -p "Operation might remove files in \"$(DEST)\". Continue? [y/N]" -n 1 -r; \
		[[ $$REPLY =~ ^[Yy]$$ ]] || exit 1'
	@echo
	find "$(DEST)" -type f -a -not -path '$(CACHE)/*' \
		| grep --fixed-strings --line-regexp --invert-match --file="$<" \
		| xargs --no-run-if-empty rm --verbose

# Generate static index page 
$(DEST)/index.html: $(PANDOC_DIR)/page.html $(PANDOC_DIR)/nav.html $(CACHE)/index.json $(DEST)/web.css
	@-mkdir -p $(@D)
	@echo "Generating index page \"$@\"..." 1>&2
	@echo | pandoc \
		--template="$(PANDOC_DIR)/page.html" \
		--metadata-file "$(CACHE)/index.json" \
		--metadata title="Table of contents" \
		$(if $(wildcard $(SRC)/favicon.*),--metadata favicon='$(shell realpath $(DEST)/favicon.ico --relative-to $(@D) --canonicalize-missing)') \
		--metadata style='web' \
		> $@

