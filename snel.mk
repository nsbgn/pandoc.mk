# Location of snel.mk makefile
BASE := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Source and destination directories, and FTP credentials. These are
# expected to be changed in the `make` call or before the `include` statement.
ifndef FILTERS
    FILTERS := $(BASE)/filters
endif
ifndef TEMPLATES
    TEMPLATES := $(BASE)/templates
endif
ifndef ASSETS
    ASSETS := $(BASE)/assets
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
			$(shell fdfind --follow $(patsubst %,--exclude '%',$(IGNORE)) --extension md . "$(SRC)")\
	       )

# Metadata is collected for each source in a corresponding file
METADATA_FILES = $(patsubst $(SRC)/%,$(CACHE)/%.meta.json,$(SOURCE_FILES))


##########################################################################$$$$
# Phony targets

all: html resources

html: $(patsubst $(SRC)/%.md,$(DEST)/%.html,$(SOURCE_FILES)) 

resources: \
		$(DEST)/index.html \
		$(DEST)/style.css \
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

# Stylesheet
$(DEST)/style.css: $(ASSETS)/style.scss
	@-mkdir -p $(@D)
	sassc --style compressed $< $@

# Optimised SVG logo
$(DEST)/logo.svg: $(ASSETS)/logo.svg
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


##############################################################################
# Indexing

# Record metadata for each document
$(CACHE)/%.md.meta.json: $(SRC)/%.md $(TEMPLATES)/metadata.json
	@-mkdir -p "$(@D)"
	pandoc --template='$(TEMPLATES)/metadata.json' \
		--to=plain \
		--output=$@ \
		$<

# Overview of files & directories
$(CACHE)/filetree.json: $(SOURCE_FILES) $(METADATA_FILES)
	@-mkdir -p $(@D)
	fdfind . "$(SRC)" $(patsubst %,--exclude '%',$(IGNORE)) --follow \
	        --exec stat --printf='{"path":"%n","size":%s,"modified":%Y,"type":"%F"}\n' \
	    | jq --slurp '.' \
	    > $@

# An alternative way to create the filetree 'immediately'
$(CACHE)/filetree.alt.json: $(SOURCE_FILES)
	@-mkdir -p $(@D)
	tree -JDpi --du --timefmt '%s' --dirsfirst \
	    -I '$(subst $() $(),|,$(IGNORE))' \
	    | jq '.[0]' \
	    > $@

# Overview of files & directories, including metadata, transformed into format
# readable for the index template
$(CACHE)/index.json: $(CACHE)/filetree.json $(METADATA_FILES) $(BASE)/index.jq
	@-mkdir -p $(@D)
	jq  -L$(BASE) --null-input \
	    --arg prefix "$(CACHE)/" \
	    'include "index"; index' \
	     $(filter %.json, $^) \
	    > $@

# Generate static index page 
$(DEST)/index.html: $(TEMPLATES)/index.html $(TEMPLATES)/nav.html $(CACHE)/index.json
	@-mkdir -p $(@D)
	echo | pandoc \
	    --template=$(TEMPLATES)/index.html \
	    --metadata-file $(CACHE)/index.json \
	    --metadata title="Table of contents" \
	    -o $@



##############################################################################
# Documents

# --filter $(FILTERS)/pandoc-extract-references.py \

# Create HTML documents
$(DEST)/%.html: \
		$(SRC)/%.md \
		$(CACHE)/%.md.meta.json \
		$(TEMPLATES)/page.html \
		$(wildcard $(SRC)/*.bib) 
	@echo "Generating $@..."
	@-mkdir -p "$(@D)"
	@-mkdir -p "$(patsubst $(DEST)/%,$(CACHE)/%,$(@D))"
	pandoc  \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST) --canonicalize-missing)' \
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
		$< \
		$(filter %/metadata.yaml, $^) \
		| sed ':a;N;$$!ba;s|>\s*<|><|g' \
		> $@


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

