# This adds recipes for collecting all the Markdown files from a particular
# directory that have `make: [html,pdf]` in the metadata. It also generates an
# index file for them.

include $(dir $(abspath $(lastword $(MAKEFILE_LIST))))/snel-variables.mk

# Find potential source Markdown files
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
	@jq -c -L"$(JQ_DIR)" --arg dest "$(DEST)" --arg style "$(STYLE)" \
		'include "snel"; targets($$dest; $$style)' < "$<" > "$@"
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
		| grep --fixed-strings --line-regexp --invert-match --file=$< \
		| xargs --no-run-if-empty rm --verbose

# Generate static index page 
$(DEST)/index.html: $(PANDOC_DIR)/page.html $(PANDOC_DIR)/nav.html $(CACHE)/index.json $(DEST)/$(STYLE).css
	@-mkdir -p $(@D)
	@echo "Generating index page \"$@\"..." 1>&2
	@echo | pandoc \
		--template="$(PANDOC_DIR)/page.html" \
		--metadata-file "$(CACHE)/index.json" \
		--metadata title="Table of contents" \
		$(if $(wildcard $(SRC)/favicon.*),--metadata favicon='$(shell realpath $(DEST)/favicon.ico --relative-to $(@D) --canonicalize-missing)') \
		--metadata style='$(STYLE)' \
		> $@

