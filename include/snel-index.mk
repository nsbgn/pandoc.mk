# This adds recipes for collecting all the Markdown files from a particular
# directory that have `publish: true` in the metadata. It also generates an
# index file for them.

include $(dir $(abspath $(lastword $(MAKEFILE_LIST))))/snel-variables.mk

# Find source files
SOURCE_FILES = $(shell \
    find -L "$(SRC)"  $(patsubst %,-name '%' -prune -o,$(IGNORE)) -iname '*.md' -print \
)
# Headers and extra targets are collected for each source in a corresponding file
META_FILES = $(patsubst $(SRC)/%,$(CACHE)/%.meta.json,$(SOURCE_FILES))


html: $(CACHE)/content.mk indirect-targets $(DEST)/favicon.ico $(DEST)/apple-touch-icon.png $(DEST)/index.html

include $(CACHE)/content.mk

$(CACHE)/content.mk: $(CACHE)/targets.html.txt
	@echo "Generating recipes..."
	@jq -R -r '"indirect-targets: " + ([inputs] | join(" ")) + "\n.PHONY: indirect-targets"' < $< > $@


# Optionally, remove all files in $(DEST) that are no longer targeted
clean: $(CACHE)/targets.html.txt
	@bash -i -c 'read -p "Operation might remove files in \"$(DEST)\". Continue? [y/N]" -n 1 -r; \
	    [[ $$REPLY =~ ^[Yy]$$ ]] || exit 1'
	@echo
	find "$(DEST)" -type f -a -not -path '$(CACHE)/*' \
	    | grep --fixed-strings --line-regexp --invert-match --file=$< \
	    | xargs --no-run-if-empty rm --verbose

.PHONY: all html pdf clean

# Record metadata headers for each document
$(CACHE)/%.md.headers.json: $(SRC)/%.md $(PANDOC_DIR)/metadata.json $(JQ_DIR)/index.jq
	@-mkdir -p "$(@D)"
	@pandoc --template='$(PANDOC_DIR)/metadata.json' \
	    --to=plain \
	    $< \
	    | jq '{"meta":.}' \
	    > $@

# Record extra targets for each document
$(CACHE)/%.md.targets.json: $(SRC)/%.md 
	@-mkdir -p "$(@D)"
	@pandoc -f markdown -t json -i $< \
	    | jq -r '{"targets":[ .blocks[] | recurse(.c?[]?) | select(.t? == "Image") | .c[2][0] | select(test("^[a-z]+://") | not) ]}' \
	    > $@

# Combination of headers + targets
$(CACHE)/%.md.meta.json: $(CACHE)/%.md.headers.json $(CACHE)/%.md.targets.json 
	@-mkdir -p "$(@D)"
	@echo "Generating metadata \"$@\"..." 1>&2
	@jq \
	    -L"$(JQ_DIR)" \
	    --arg path "$(patsubst $(CACHE)/%.md.meta.json,%.md,$@)" \
	    --slurp \
	    'include "index"; add | tree(["."] + ($$path | split("/")))' \
	    $^ \
	    > $@

# Overview of files & directories with metadata, readable for index template
$(CACHE)/index.%.json: $(JQ_DIR)/index.jq \
	    $(CACHE)/filetree.json \
	    $(META_FILES) \
	    $(wildcard $(SRC)/index.base.json)
	@-mkdir -p $(@D)
	@echo "Generating index data..." 1>&2
	@jq  -L$(JQ_DIR) --slurp \
	    'include "index"; index("$(patsubst $(CACHE)/index.%.json,%,$@)")' \
	    $(filter %.json, $^) \
	    > $@

# Overview of final targets
$(CACHE)/targets.%.txt: $(CACHE)/index.%.json
	@echo "Aggregating targets..." 1>&2
	@jq \
	    -L"$(JQ_DIR)" \
	    --arg dest "$(DEST)/" \
	    -r 'include "index"; targets | ltrimstr("./") | $$dest + .' \
	    < $< \
	    > $@

# Overview of files & directories, without metadata
$(CACHE)/filetree.json: $(SOURCE_FILES)
	@-mkdir -p $(@D)
	@echo "Generating file tree..." 1>&2
	@tree -JDpi --du --timefmt '%s' --dirsfirst \
	    -I '$(subst $() $(),|,$(IGNORE))' \
	    | jq '.[0]' \
	    > $@

# Generate static index page 
$(DEST)/index.html: $(PANDOC_DIR)/page.html $(PANDOC_DIR)/nav.html $(CACHE)/index.html.json
	@-mkdir -p $(@D)
	@echo "Generating index page..." 1>&2
	@echo | pandoc \
	    --template="$(PANDOC_DIR)/page.html" \
	    --metadata-file "$(CACHE)/index.html.json" \
	    --metadata title="Table of contents" \
		--metadata favicon='$(shell realpath $(DEST)/favicon.ico --relative-to $(@D) --canonicalize-missing)' \
		--metadata style='$(STYLE)' \
	    > $@

