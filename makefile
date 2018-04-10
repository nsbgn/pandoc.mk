# Location of makefile itself
BASE := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Source and destination directories, and FTP or SSH credentials. These are
# expected to be changed in the `make` call or before the `include` statement.
ifndef SRC
    SRC := $(BASE)/example
endif
ifndef DEST
    DEST := build
endif
ifndef CACHE
    CACHE := $(DEST)/.cache
endif
ifndef ASSETS
    ASSETS := $(BASE)/assets
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

# Find source files
SOURCES = $(shell find $(SRC) -mindepth 1 -iname '*.md' -print)

# Metadata is collected for each source file
METADATA = $(patsubst $(SRC)/%,$(CACHE)/%.meta.json,$(SOURCES))

# Files referenced in the source documents are targets themselves
REFERENCED = $(shell [ -d $(CACHE) ] && cat /dev/null $(METADATA) | jq --raw-output '.targets[]?' )


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
		$(REFERENCED)

metadata: $(METADATA)

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
$(DEST)/style.css: $(ASSETS)/style-main.less $(wildcard $(ASSETS)/*.less)
	@-mkdir -p $(@D)
	lessc --clean-css="--s1 --advanced" $< $@


# Optimised SVG logo for inlining
$(CACHE)/logo.svg: $(ASSETS)/logo-snail.svg
	@-mkdir -p $(@D)
	svgo --input=$< --output=$@


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


# Generate static index page 
$(DEST)/index.html: $(ASSETS)/index.py $(CACHE)/dummy.html $(METADATA)
	@-mkdir -p $(@D)
	python3 $< --template $(CACHE)/dummy.html --directory $(CACHE) > $@


# Dummy page for use in static index generation
$(CACHE)/dummy.html: $(ASSETS)/pandoc-template.html
	@-mkdir -p $(@D)
	echo "dummy" | pandoc \
		--template $< \
		--variable root='.' \
		--to html5 \
		--standalone \
		--output=$@


# Dummy page for metadata export
$(CACHE)/metadata-template.txt:
	@-mkdir -p $(@D)
	echo '$$meta-json$$' > $@



##########################################################################$$$$
# Documents

# Create HTML documents
$(DEST)/%.html: \
		$(SRC)/%.md \
                $(CACHE)/logo.svg \
		$(ASSETS)/pandoc-template.html \
		$(ASSETS)/pandoc-extract-references.py \
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
		--from markdown+smart+fenced_divs+footnotes+inline_notes+table_captions \
		--to html5 \
		--standalone \
		--filter $(ASSETS)/pandoc-extract-references.py \
		--include-before-body="$(CACHE)/logo.svg" \
		--template $(ASSETS)/pandoc-template.html \
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
		--highlight-style=monochrome \
		--output=$@ \
		$< \
		$(filter %/metadata.yaml, $^)


# Record metadata for each document
$(CACHE)/%.md.meta.json: $(SRC)/%.md $(CACHE)/metadata-template.txt
	@-mkdir -p "$(@D)"
	pandoc \
		--metadata link='$(patsubst $(CACHE)/%.md.meta.json,%.html,$@)' \
		--metadata original='$(patsubst $(CACHE)/%.md.meta.json,$(SRC)/%.md,$@)' \
		--template='$(CACHE)/metadata-template.txt' \
		--to=plain \
		--output=$@ \
		$<


##########################################################################$$$$
# Generic recipes

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

