# This adds recipes for generating PDF or HTML documents and associated
# resources.

include $(dir $(abspath $(lastword $(MAKEFILE_LIST))))/snel-variables.mk

# All available style files
STYLE_SOURCES = $(patsubst $(ASSET_DIR)/style/%.scss,%,$(wildcard $(ASSET_DIR)/style/*.scss))
STYLE_MODULES = $(filter _%,$(STYLE_SOURCES))
STYLE_TARGETS = $(filter-out _%,$(STYLE_SOURCES))
STYLE_MODULE_FILES = $(patsubst %,$(ASSET_DIR)/style/%.scss,$(STYLE_MODULES))
STYLE_TARGET_FILES = $(patsubst %,$(DEST)/%.css,$(STYLE_TARGETS))

# If `snel` is installed & used globally, the stylesheets should be already
# available in `$PREFIX/share/snel`; otherwise they should be compiled.
ifeq ($(BASE_DIR),$(INCLUDE_DIR))
$(DEST)/%: $(ASSET_DIR)/%
	@-mkdir -p $(@D)
	cp $< $@
else
$(DEST)/%.css: $(ASSET_DIR)/style/%.scss $(STYLE_MODULE_FILES)
	@-mkdir -p $(@D)
	sassc --style compressed $< $@
endif

# Create HTML documents
# The following targets are required once but do not influence the build of this
# target: $(DEST)/$(STYLE).css $(DEST)/favicon.ico
$(DEST)/%.html: \
		$(SRC)/%.md \
		$(PANDOC_DIR)/page.html \
		$(wildcard $(SRC)/*.bib)
	@echo "Generating document \"$@\"..." 1>&2
	@-mkdir -p "$(@D)"
	@-mkdir -p "$(patsubst $(DEST)/%,$(CACHE)/%,$(@D))"
	@pandoc  \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST) --canonicalize-missing)' \
		--metadata root='$(shell realpath $(DEST) --relative-to $(@D) --canonicalize-missing)' \
		--metadata index='$(shell realpath $(DEST)/index.html --relative-to $(@D) --canonicalize-missing)' \
		--metadata default-style='$(STYLE_HTML)' \
		--metadata last-modified='$(shell date -r "$<" '+%Y-%m-%d')' \
		$(if $(wildcard $(SRC)/favicon.*),--metadata favicon='$(shell realpath $(DEST)/favicon.ico --relative-to $(@D) --canonicalize-missing)') \
		--from markdown+smart+fenced_divs+inline_notes+table_captions \
		--to html5 \
		--standalone \
		--template '$(PANDOC_DIR)/page.html' \
		--filter pandoc-citeproc \
		$(foreach F,\
			$(filter %.bib, $^),\
			--bibliography='$(F)' \
		)\
		--shift-heading-level-by=1 \
		--ascii \
		--strip-comments \
		--email-obfuscation=references \
		--highlight-style=kate \
		$< \
		$(filter %/metadata.yaml, $^) \
		| sed ':a;N;$$!ba;s|>\s*<|><|g' \
		> $@

# No table of contents for now since it's not yet used
#--table-of-contents
#--toc-depth=3

# Create PDF documents
$(DEST)/%.pdf: $(SRC)/%.md $(PANDOC_DIR)/page.html $(STYLE_TARGET_FILES)
	@echo "Generating document \"$@\"..." 1>&2
	@-mkdir -p "$(@D)"
	pandoc \
	    --shift-heading-level-by=1 \
	    --pdf-engine=weasyprint \
	    --template '$(PANDOC_DIR)/page.html' \
	    --metadata default-style='$(STYLE_PDF)' \
	    --metadata root='$(DEST)' \
	    --to pdf \
	    $< \
	| ps2pdf \
		-dOptimize=true \
		-dUseFlateCompression=true \
		-dEmbedAllFonts=true \
		-dPrinted=false \
		- $@

