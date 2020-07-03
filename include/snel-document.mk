# This adds recipes for generating PDF or HTML documents and associated
# resources.

include $(dir $(abspath $(lastword $(MAKEFILE_LIST))))/snel-variables.mk

# All available style files
STYLE_SOURCES = $(patsubst $(ASSET_DIR)/style/%.scss,%,$(wildcard $(ASSET_DIR)/style/*.scss))
STYLE_MODULES = $(filter _%,$(STYLE_SOURCES))
STYLE_TARGETS = $(filter-out _%,$(STYLE_SOURCES))
STYLE_MODULE_FILES = $(patsubst %,$(ASSET_DIR)/style/%.scss,$(STYLE_MODULES))
STYLE_TARGET_FILES = $(patsubst %,$(DEST)/%.css,$(STYLE_TARGETS))

# If `snel` is installed & used globally, the stylesheet and favicon should be
# already available in `$PREFIX/share/snel`; otherwise they should be compiled.
ifeq ($(BASE_DIR),$(INCLUDE_DIR))
$(DEST)/%: $(ASSET_DIR)/%
	@-mkdir -p $(@D)
	cp $< $@

else
# Stylesheet
$(DEST)/%.css: $(ASSET_DIR)/style/%.scss $(STYLE_MODULE_FILES)
	@-mkdir -p $(@D)
	sassc --style compressed $< $@

# Favicon as bitmap
$(DEST)/favicon.ico: $(ASSET_DIR)/favicon.svg
	@-mkdir -p $(@D)
	convert $< -transparent white -resize 16x16 -level '0%,100%,0.6' $@

# Icon for bookmark on Apple devices
$(DEST)/apple-touch-icon.png: $(ASSET_DIR)/favicon.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 140x140 -gravity center -extent 180x180 \
	    	+level-colors '#fff,#711' -colors 16 \
		-compress Zip -define 'png:format=png8' -define 'png:compression-level=9' \
		$< $@
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
		--metadata hide_web_info='$(HIDE_WEB_INFO)' \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST) --canonicalize-missing)' \
		--metadata root='$(shell realpath $(DEST) --relative-to $(@D) --canonicalize-missing)' \
		--metadata favicon='$(shell realpath $(DEST)/favicon.ico --relative-to $(@D) --canonicalize-missing)' \
		--metadata index='$(shell realpath $(DEST)/index.html --relative-to $(@D) --canonicalize-missing)' \
		--metadata default-style='$(STYLE)' \
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
	    --metadata hide_web_info='$(HIDE_WEB_INFO)' \
	    --shift-heading-level-by=1 \
	    --pdf-engine=weasyprint \
	    --template '$(PANDOC_DIR)/page.html' \
	    --metadata default-style='$(STYLE)' \
	    --metadata root='$(DEST)' \
	    --to pdf \
	    $< \
	| ps2pdf \
		-dOptimize=true \
		-dUseFlateCompression=true \
		-dEmbedAllFonts=true \
		-dPrinted=false \
		- $@



##########################################################################$$$$
# Generic recipes

# Optimised SVG
$(DEST)/%.svg: $(SRC)/%.svg
	@-mkdir -p $(@D)
	svgo --input=$< --output=$@

$(DEST)/%.png: $(SRC)/%.jpg
	@-mkdir -p $(@D)
	convert $< \
		-resize '600x' \
		-dither FloydSteinberg \
		-colorspace gray \
		-colors 8 \
		-normalize \
		-define png:color-type=3 \
        -define png:compression-level=9  \
		-define png:format=png8 \
		-strip \
		$@
	optipng $@
	@echo "Original size $$(ls -sh $< | cut -d' ' -f1)."
	@echo "Compressed to $$(ls -sh $@ | cut -d' ' -f1)."


$(DEST)/%.gif: $(SRC)/%.jpg
	@-mkdir -p $(@D)
	convert $< \
		-resize '400x' \
		-colorspace gray \
		-colors 12 \
		-normalize \
		-dither FloydSteinberg \
		-strip \
		$@
	@echo "Original size $$(ls -sh $< | cut -d' ' -f1)."
	@echo "Compressed to $$(ls -sh $@ | cut -d' ' -f1)."


$(DEST)/%.jpg: $(SRC)/%.jpg
	@-mkdir -p $(@D)
	convert  $< \
		-resize '600x' \
		-quality '60%' \
		$@
	@echo "Original size $$(ls -sh $< | cut -d' ' -f1)."
	@echo "Compressed to $$(ls -sh $@ | cut -d' ' -f1)."

# Any file in the source is also available at the destination
$(DEST)/%: $(SRC)/%
	@-mkdir -p $(@D)
	-ln -s --relative $< $@

