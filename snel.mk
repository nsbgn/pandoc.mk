# Installation directories
PREFIX := /usr/local
INCLUDE_DIR := $(PREFIX)/include
SHARE_DIR := $(PREFIX)/share/snel

# Unless specified otherwise, we're assuming that the resources snel needs are
# installed here
ifndef SNEL_DIR
    SNEL_DIR := $(SHARE_DIR)
endif

INDEX_DIR := $(SNEL_DIR)/index
THEME_DIR := $(SNEL_DIR)/theme
STYLE_DIR := $(THEME_DIR)/stylesheet
PANDOC_DIR := $(THEME_DIR)/pandoc


# Source and destination directories and FTP or SSH credentials. These are
# expected to be changed in the `make` call or before the `include` statement
# that refers to this file.
ifndef SRC
    SRC := example
endif
ifndef DEST
    DEST := build
endif
ifndef GPG_ID
    GPG_ID := user@domain.com
endif
ifndef USER
    USER := user
endif
ifndef HOST
    HOST := host
endif
ifndef REMOTE
    REMOTE := /home/user/public_html
endif
ifndef LOGO
    LOGO := $(THEME_DIR)/up.svg
endif
ifndef CACHE
    CACHE := $(DEST)/.cache
endif


# Find source files
SOURCES = $(shell find $(SRC) -mindepth 1 -iname '*.md' -print)

# On the first run, files referenced in the source documents are stored
# somewhere using a filter. Upon a second run, those filenames are collected 
# here and will be targets themselves.
RESOURCES = $(shell \
	[ -d $(CACHE) ] && \
	cat /dev/null `find $(CACHE) -mindepth 1 -iname '*.targets' -print` \
)


##########################################################################$$$$
# Phony targets

all: | html resources

html: $(patsubst $(SRC)/%.md,$(DEST)/%.html,$(SOURCES)) 

resources: \
		$(DEST)/sitemap.json \
		$(DEST)/index.html \
		$(DEST)/index.js \
		$(DEST)/style.css \
		$(DEST)/favicon.ico \
		$(DEST)/apple-touch-icon.png \
		$(RESOURCES)


upload-ssh:
	rsync -e ssh \
		--recursive --exclude=.cache/ --times --copy-links \
		--verbose --progress \
		$(DEST)/ $(USER)@$(HOST):$(REMOTE)/

upload-ftp:
	read -s -p 'FTP password: ' password && \
	lftp -u $(USER),$$password -e \
	"mirror --reverse --only-newer --verbose --dry-run --exclude .cache/ $(DEST) $(REMOTE)" \
	$(HOST)


upload: upload-ftp


.PHONY: prepare all html resources upload upload-ssh upload-ftp



##########################################################################$$$$
# Theme

# Stylesheet
$(DEST)/style.css: $(STYLE_DIR)/main.less $(wildcard $(STYLE_DIR)/*.less)
	@-mkdir -p $(@D)
	lessc --clean-css="--s1 --advanced --compatibility=ie8" $< $@


# Optimised SVG logo for inlining
# Note that svgo doesn't use the proper exit code upon failure
$(CACHE)/logo.svg: $(LOGO)
	@-mkdir -p $(@D)
	svgo $< $@


# Favicon as bitmap
$(DEST)/favicon.ico: $(CACHE)/logo.svg
	@-mkdir -p $(@D)
	convert $< -transparent white -resize 16x16 -level '0%,100%,0.6' $@


# Icon for bookmark on Apple devices
$(DEST)/apple-touch-icon.png: $(CACHE)/logo.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 140x140 -gravity center -extent 180x180 \
	    	+level-colors '#fff,#711' -colors 16 \
		-compress Zip -define 'png:format=png8' -define 'png:compression-level=9' \
		$< $@


# ASCII art logo, centred for 79-column text files
$(CACHE)/logo.txt: $(CACHE)/logo.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 128x128 $< $@.jpg
	jp2a --width=23 --chars=\ -~o0@ -i $@.jpg | sed 's/^/$(shell printf '%-28s')/' > $@
	rm $@.jpg


# Cover for EPUB books
$(CACHE)/%/epub-cover.jpg: $(wildcard $(SRC)/%/cover.*)
	@echo 'Generating EPUB cover...'
	convert -resize 600x800 $< $@



##########################################################################$$$$
# Index

# JSON table of contents of the source directory 
$(DEST)/sitemap.json: $(INDEX_DIR)/sitemap.py $(SOURCES)
	@-mkdir -p $(@D)
	python3 $< $ $(SRC) > $@


# Client-side script to generate a dynamic index from the sitemap
$(DEST)/index.js: $(INDEX_DIR)/view.js $(INDEX_DIR)/view.externs.js
	@-mkdir -p $(@D)
	closure-compiler -O ADVANCED --warning_level VERBOSE \
		--externs $(INDEX_DIR)/view.externs.js \
		--define='INDEX=/index.html' \
		--js_output_file $@ $<


# Static index page for when the client is unable to view the dynamic one
$(DEST)/index.html: \
 		   $(INDEX_DIR)/dump.js \
		   $(CACHE)/dummy.html \
		   $(INDEX_DIR)/view.js \
		   $(DEST)/sitemap.json
	@-mkdir -p $(@D)
	@echo "Generating index page $@..."
	phantomjs $+ $@


# Make dummy page for use in static index generation
$(CACHE)/dummy.html: $(PANDOC_DIR)/template.html
	@-mkdir -p $(@D)
	echo "dummy" | pandoc \
		--template $< --variable root='.' \
		--to html5 --standalone --output=$@



##########################################################################$$$$
# Documents

# Create HTML documents
$(DEST)/%.html: \
		$(SRC)/%.md \
                $(CACHE)/logo.svg \
		$(PANDOC_DIR)/template.html \
		$(wildcard $(PANDOC_DIR)/*.py) \
		$(wildcard $(SRC)/references.bib) 
	@echo "Generating $@..."
	@-mkdir -p "$(@D)"
	@-mkdir -p "$(patsubst $(DEST)/%,$(CACHE)/%,$(@D))"
	pandoc  \
		--metadata source='$(SRC)' \
		--metadata destination='$(DEST)' \
		--metadata cache='$(CACHE)' \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST))' \
		--metadata file='$(@F)' \
		--metadata root='$(shell realpath $(DEST) --relative-to $(@D))/' \
		--metadata target-dump='$(patsubst $(DEST)/%.html,$(CACHE)/%.md.targets,$@)' \
		--from markdown+footnotes+inline_notes+table_captions \
		--to html5 --standalone \
		--template $(PANDOC_DIR)/template.html \
		$(foreach F,\
			$(filter %.css, $^),\
			--css=$(F) \
		) \
		--filter pandoc-citeproc \
		$(foreach F,\
			$(filter %.bib %/references.yaml, $^),\
			--bibliography=$(F) \
		)\
		$(foreach F,\
			$(filter %.py, $^),\
			--filter=$(F) \
		)\
		--base-header-level=2 \
		--mathml=https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=MML_HTMLorMML \
		--smart --normalize --ascii --email-obfuscation=references \
		--highlight-style=$(word 1, kate monochrome espresso zenburn haddock tango) \
		--include-before-body="$(CACHE)/logo.svg" \
		--output=$@ \
		$< $(filter %/metadata.yaml, $^)



##########################################################################$$$$
# Generic recipes

# Any file in the source is also available at the destination
$(DEST)/%: $(SRC)/%
	@-mkdir -p $(@D)
	-ln -s --relative $< $@


# Any file in the cache is also available at the destination
$(DEST)/%: $(CACHE)/%
	@-mkdir -p $(@D)
	-cp $< $@


# Any file in the theme is also available at the destination
$(DEST)/%: $(THEME_DIR)/%
	@-mkdir -p $(@D)
	-ln -s --relative $< $@


# Public GPG key
$(DEST)/public.gpg:
	gpg --export $(GPG_ID) > $@


# Create a zipped archive
$(DEST)/%.zip: $(SRC)/%
	@-mkdir -p $(@D)
	zip -r9 $@ $^


# Create a zipped archive
$(DEST)/%.tar.gz: $(SRC)/%
	@-mkdir -p $(@D)
	tar -zcvf $@ $^


# Generate a YAML bibliography from a BIB bibliography
%.yaml: %.bib
	pandoc-citeproc --bib2yaml $< > $@