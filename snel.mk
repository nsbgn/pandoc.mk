# Location of snel.mk makefile
BASE := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Source and destination directories, and FTP credentials. These are
# expected to be changed in the `make` call or before the `include` statement.
ifndef ASSETS
    ASSETS := $(BASE)/assets
endif
ifndef TEMPLATES
    TEMPLATES := $(BASE)/templates
endif
ifndef SRC
    SRC := .
endif
ifndef DEST
    DEST := build
endif
ifndef CACHE
    CACHE := $(DEST)/cache
endif
ifndef META
    META := $(CACHE)/metadata
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
ifndef REMOTE_DIR
    REMOTE_DIR := /home/user/public_html
endif
ifndef IGNORE
    # .git and files from .gitignore are automatically ignored by fd
    IGNORE=Makefile
endif

# Find source files
SOURCE_FILES = $(addprefix $(SRC)/,\
			$(shell fdfind $(patsubst %,--exclude '%',$(IGNORE)) --extension md . "$(SRC)")\
	       )

# Metadata is collected for each source in a corresponding file
METADATA_FILES = $(patsubst $(SRC)/%,$(META)/%.meta.json,$(SOURCE_FILES))


##########################################################################$$$$
# Phony targets

all: html resources

html: $(patsubst $(SRC)/%.md,$(DEST)/%.html,$(SOURCE_FILES)) 

resources: \
		$(DEST)/index.html \
		$(DEST)/style.css \
		$(DEST)/crimson.woff2 \
		$(DEST)/favicon.ico \
		$(DEST)/apple-touch-icon.png

upload: all
	read -s -p 'FTP password: ' password && \
	lftp -u $(USER),$$password -e \
	"mirror --reverse --only-newer --verbose --dry-run --exclude $(CACHE) $(DEST) $(REMOTE)" \
	$(HOST)

.PHONY: all html resources upload



##########################################################################$$$$
# Theme

# Font (source: https://github.com/skosch/Crimson)
$(DEST)/crimson.woff2: $(ASSETS)/crimson.woff2
	cp $< $@

# Stylesheet
$(DEST)/style.css: $(ASSETS)/style.scss
	@-mkdir -p $(@D)
	sassc --style compressed $< $@

# Optimised SVG logo
$(DEST)/logo.svg: $(ASSETS)/logo-snail.svg
	@-mkdir -p $(@D)
	svgo --input=$< --output=$@

# Fallback logo
$(DEST)/logo.png: $(DEST)/logo.svg
	@-mkdir -p $(@D)
	convert $< $@


# Favicon as bitmap
$(DEST)/favicon.ico: $(DEST)/logo.svg
	@-mkdir -p $(@D)
	convert $< -transparent white -resize 16x16 -level '0%,100%,0.6' $@


# Icon for bookmark on Apple devices
$(DEST)/apple-touch-icon.png: $(DEST)/logo.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 140x140 -gravity center -extent 180x180 \
	    	+level-colors '#fff,#711' -colors 16 \
		-compress Zip -define 'png:format=png8' -define 'png:compression-level=9' \
		$< $@


# ASCII art logo, centred for 79-column text files
$(CACHE)/logo.txt: $(DEST)/logo.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 128x128 $< JPG:- \
	    | jp2a --width=40 --chars=\ -~o0@\  - \
	    | sed 's/^/$(shell printf '%-28s')/' > $@


# Overview of files & directories
$(CACHE)/filetree.json: $(ASSETS)/indexer.jq
	@-mkdir -p $(@D)
	fdfind . "$(SRC)" \
	        $(patsubst %,--exclude '%',$(IGNORE)) \
	        --exec stat --printf='{"path":"%n","size":%s,"modified":%Y,"type":"%F"}\n' \
	    | jq -L$(ASSETS) \
		 --null-input \
		 'include "indexer"; filetree' \
	    > $@

# Overview of files & directories, including metadata, transformed into format
# readable for the index template
$(CACHE)/index.json: $(CACHE)/filetree.json $(METADATA_FILES) $(ASSETS)/indexer.jq
	@-mkdir -p $(@D)
	jq  -L$(ASSETS) \
	    --null-input \
	    --arg prefix "$(META)/" \
	    'include "indexer"; index' \
	     $(filter %.json, $^) \
	    > $@

# Generate static index page 
$(DEST)/index.html: $(TEMPLATES)/index.html $(TEMPLATES)/nav.html $(CACHE)/index.json
	@-mkdir -p $(@D)
	( echo "---"; cat $(CACHE)/index.json; echo "...") \
	    | pandoc \
	    	--template=$(TEMPLATES)/index.html \
		--metadata title="Table of contents" \
		-o $@

##########################################################################$$$$
# Documents

# --filter $(ASSETS)/pandoc-extract-references.py \

# Create HTML documents
$(DEST)/%.html: \
		$(SRC)/%.md \
		$(META)/%.md.meta.json \
		$(TEMPLATES)/page.html \
		$(ASSETS)/pandoc-extract-references.py \
		$(wildcard $(SRC)/*.bib) 
	@echo "Generating $@..."
	@-mkdir -p "$(@D)"
	@-mkdir -p "$(patsubst $(DEST)/%,$(META)/%,$(@D))"
	pandoc  \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST) --canonicalize-missing)' \
		--metadata file='$(@F)' \
		--metadata root='$(shell realpath $(DEST) --relative-to $(@D) --canonicalize-missing)' \
		--from markdown+smart+fenced_divs+inline_notes+table_captions \
		--to html5 \
		--standalone \
		--table-of-contents \
		--toc-depth=3 \
		--template $(TEMPLATES)/page.html \
		$(foreach F,\
			$(filter %.css, $^),\
			--css=$(F) \
		) \
		--filter pandoc-citeproc \
		$(foreach F,\
			$(filter %.bib, $^),\
			--bibliography=$(F) \
		)\
		--base-header-level=2 \
		--ascii \
		--email-obfuscation=references \
		--highlight-style=kate \
		--output=$@ \
		$< \
		$(filter %/metadata.yaml, $^)


# Record metadata for each document
$(META)/%.md.meta.json: $(SRC)/%.md $(TEMPLATES)/metadata.json
	@-mkdir -p "$(@D)"
	pandoc --template='$(TEMPLATES)/metadata.json' \
		--to=plain \
		--output=$@ \
		$<


##########################################################################$$$$
# Generic recipes

# Any image file
$(DEST)/%.jpg: $(SRC)/%.jpg
	@-mkdir -p $(@D)
	convert -resize '600x' -quality '60%' $< $@


# Any file in the source is also available at the destination
$(DEST)/%: $(SRC)/%
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

# Create gzipped archive
$(DEST)/%: $(DEST)/%.gz
	gzip --best --to-stdout < $< > $@
