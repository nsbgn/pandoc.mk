SNEL = .
SRC = $(SNEL)/example
DEST = build
CACHE = $(DEST)/.cache

INDEXER = $(SNEL)/index
THEME = $(SNEL)/theme
STYLES = $(THEME)/styles
TEMPLATES = $(THEME)/templates
FILTERS = $(THEME)/filters


# Credentials
EMAIL=user@domain.com
USER=user
HOST=host
REMOTE=/home/user/public_html


# Source documents
SOURCES = $(shell find $(SRC) -mindepth 1 -iname '*.md')


# Files that should always be present at the destination
RESOURCES_GLOBAL = \
	$(DEST)/sitemap.json \
	$(DEST)/index.html \
	$(DEST)/index.js \
	$(DEST)/style.css \
	$(DEST)/favicon.ico \
	$(DEST)/apple-touch-icon.png 


# On the first run, files referenced in the source documents are stored
# somewhere. Upon a second run, those filenames are collected here and thereby
# become targets themselves.
RESOURCES_LOCAL = \
	$(foreach F,\
		$(patsubst \
			$(SRC)/%.md,\
	    		$(CACHE)/%.md.targets,\
			$(SOURCES)\
		),\
		$(shell [ -f $(F) ] && cat $(F) )\
	)



##########
# Recipes

all: | html resources

html: $(patsubst $(SRC)/%.md,$(DEST)/%.html,$(SOURCES)) 

resources: $(RESOURCES_LOCAL) $(RESOURCES_GLOBAL)

upload-ssh: all
	rsync -e ssh \
		--recursive --exclude=.cache/ --times --copy-links \
		--verbose --progress \
		$(DEST)/ $(USER)@$(HOST):$(REMOTE)/

upload-ftp: all
	read -s -p 'FTP password: ' password && \
	lftp -u $(USER),$$password -e \
	"mirror --reverse --only-newer --verbose --dry-run --exclude .cache/ $(DEST) $(REMOTE)" \
	$(HOST)


# Public GPG key
$(DEST)/public.gpg:
	gpg --export $(EMAIL) > $@


##################
# Styling & fonts

$(DEST)/style.css: $(STYLES)/main.less $(wildcard $(STYLE)/*.less)
	lessc --clean-css="--s1 --advanced --compatibility=ie8" $< $@


#################
# Logos & covers

# Select appropriate logo
$(CACHE)/logo.svg: $(wildcard $(SRC)/logo.svg) $(THEME)/up.svg
	@-mkdir -p $(@D)
	ln -s --relative --force $< $@


# Favicon as bitmap
$(DEST)/favicon.ico: $(CACHE)/logo.svg
	@-mkdir -p $(@D)
	convert -transparent white -resize 16x16 $< $@


# Favicon as embedded PNG with boolean transparency
$(DEST)/favicon2.ico: $(CACHE)/logo.svg
	@-mkdir -p $(@D)
	convert -background none -resize 16x16 -transparent-color '#fff' \
		-compress Zip -define 'png:format=png8' \
		-define 'png:compression-level=9' -gravity center \
		$< $@


# Icon for bookmark on Apple devices
$(DEST)/apple-touch-icon.png: $(CACHE)/logo.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 150x150 -colors 8 \
		-border 26 -bordercolor '#fff' -background '#fff' -negate \
		-define 'png:format=png8' -define 'png:compression-level=9' \
		$< $@


# ASCII art logo, centred for 79-column text files
$(CACHE)/logo.txt: $(CACHE)/logo.svg
	convert -density 1200 -resize 128x128 $< $@.jpg
	jp2a --width=23 --chars=\ -~o0@ -i $@.jpg | sed 's/^/$(shell printf '%-28s')/' > $@
	rm $@.jpg


# Create a logo suitable for inlining by removing the top <?XML?> declaration
# and stripping any inline styles (GNU sed-specific and non-portable!)
$(CACHE)/logo-inline.svg: $(CACHE)/logo.svg
	@-mkdir -p $(@D)
	sed 's/\(^<?[^?]*?>\)\|\(\ style="[^"]*"\)//g' $< > $@


# Cover for EPUB books
$(CACHE)/%/epub-cover.jpg: $(wildcard $(SRC)/%/cover.*)
	@echo 'Generating EPUB cover...'
	convert -resize 600x800 $< $@



###############################
# Dynamic & static index pages

# JSON table of contents of the source directory 
$(DEST)/sitemap.json: $(INDEXER)/sitemap.py $(SOURCES)
	@-mkdir -p $(@D)
	python3 $< $ $(SRC) > $@


# Client-side script to generate a dynamic index from the sitemap
$(DEST)/index.js: $(INDEXER)/view.js $(INDEXER)/view.externs.js
	@-mkdir -p $(@D)
	closure-compiler -O ADVANCED --warning_level VERBOSE \
		--externs $(SNEL)/index/view.externs.js \
		--define='INDEX=/index.html' \
		--js_output_file $@ $<


# Static index page for when the client is unable to view the dynamic one
$(DEST)/index.html: \
 		   $(INDEXER)/dump.js \
		   $(CACHE)/dummy.html \
		   $(INDEXER)/view.js \
		   $(DEST)/sitemap.json
	@-mkdir -p $(@D)
	@echo "Generating index page $@..."
	phantomjs $+ $@


# Make dummy page for use in static index generation
$(CACHE)/dummy.html: $(TEMPLATES)/template.html
	@-mkdir -p $(@D)
	echo "dummy" | pandoc \
		--template $< --variable root='.' \
		--to html5 --standalone --output=$@



########
# Pages

# Create HTML documents
$(DEST)/%.html: \
		$(SRC)/%.md \
		$(SNEL)/makefile_targets.py \
                $(CACHE)/logo-inline.svg \
		$(TEMPLATES)/template.html \
		$(wildcard $(THEME)/filters/*.py) \
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
		--template $(TEMPLATES)/template.html \
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
		--toc --toc-depth=3 \
		--base-header-level=2 \
		--mathml=https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=MML_HTMLorMML \
		--smart --normalize --ascii --email-obfuscation=references \
		--highlight-style=$(word 1, kate monochrome espresso zenburn haddock tango) \
		--variable inline_logo="$$(cat $(CACHE)/logo-inline.svg)" \
		--output=$@ \
		$< $(filter %/metadata.yaml, $^)



##########
# Generic

# Any file in the source is also available at the destination
$(DEST)/%: $(SRC)/%
	@-mkdir -p $(@D)
	-ln -s --relative $< $@


# Any file in the cache is also available at the destination
$(DEST)/%: $(CACHE)/%
	@-mkdir -p $(@D)
	ln -s --relative $< $@


# Any file in the theme is also available at the destination
$(DEST)/%: $(THEME)/%
	@-mkdir -p $(@D)
	ln -s --relative $< $@


# Create a zipped archive
$(DEST)/%.zip: $(SRC)/%
	@-mkdir -p $(@D)
	zip -r9 $@ $^


# Create a zipped archive
$(DEST)/%.tar.gz: $(SRC)/%
	@-mkdir -p $(@D)
	tar -zcvf $@ $^


# As a last resort, try to find a recipe for the file in the source directory
# Beware of infinite loops?
# Find a way to also monitor changes to prerequisites here? To show all targets:
# make --dry-run --always-make --debug=b <TARGET> | sed -n 's/\s*Must remake target '\(.*\)'\./\1/p"
# Note: these targets should not be remade here, that's what the make call is
# for. We should only note that they have changed. (e.g. one of the files is
# newer than the destination file)
$(DEST)/%: 
	@echo 'Trying to find recipe for $@...'
	@cd $(patsubst $(DEST)%,$(SRC)%,$(@D)) && \
	$(MAKE) $(@F) && mv $(@F) $(@D)/


# Generate a YAML bibliography from a BIB bibliography
%.yaml: %.bib
	pandoc-citeproc --bib2yaml $< > $@


.PHONY: prepare all html resources
