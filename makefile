SNEL = .
SRC = example/content
THEME = example/theme
DEST = build
CACHE = $(DEST)/.cache

# Credentials
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
	$(DEST)/font.woff2 \
	$(DEST)/style.css \
	$(DEST)/favicon.ico \
	$(DEST)/apple-touch-icon.png 

# Upon a targeting `html`, filenames that are referenced in the source documents are stored.
# When targeting `resources`, the filenames thus collected are targets themselves.
RESOURCES_LOCAL = \
	$(foreach F,\
		$(patsubst \
			$(SRC)/%.md,\
	    		$(CACHE)/%.md.req,\
			$(SOURCES)\
		),\
		$(shell [ -f $(F) ] && cat $(F) )\
	)

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


# Static assets ###############################################################

$(DEST)/%: $(THEME)/%
	cp --dereference $< $@

# Minified stylesheet
$(DEST)/%.css: $(THEME)/%.less
	lessc --clean-css="--s1 --advanced --compatibility=ie8" $< $@

# Minified JavaScript for creating a dynamic navigation menu from the sitemap
$(DEST)/index.js: $(SNEL)/sitemap/index.js $(SNEL)/sitemap/externs.js
	@-mkdir -p $(@D)
	closure-compiler -O ADVANCED --warning_level VERBOSE \
		--externs $(SNEL)/sitemap/externs.js \
		--define='INDEX=/index.html' \
		--js_output_file $@ $<


# Make dummy page for use in static page generation
$(CACHE)/dummy.html: $(THEME)/template.html
	@-mkdir -p $(@D)
	echo "dummy" | pandoc \
		--template $< --variable root='.' \
		--to html5 --standalone --output=$@


# Create a table of contents of the source directory 
$(DEST)/sitemap.json: $(SNEL)/sitemap/sitemap.py $(SOURCES)
	@-mkdir -p $(@D)
	python3 $< $ $(SRC) > $@


# Create a static index page for those cases in which the dynamic one is unavailable
$(DEST)/index.html: \
 		   $(SNEL)/sitemap/index.dump.js \
		   $(CACHE)/dummy.html \
		   $(SNEL)/sitemap/index.js \
		   $(DEST)/sitemap.json
	@-mkdir -p $(@D)
	@echo "Generating index page $@..."
	phantomjs $+ $@


# Create HTML documents
$(DEST)/%.html: \
		$(SRC)/%.md \
		$(SNEL)/pandoc/prerequisites.py \
                $(CACHE)/logo-inline.svg \
		$(wildcard $(THEME)/template.html) \
		$(wildcard $(THEME)/filters/*.py) \
		$(wildcard $(SRC)/references.bib) 
	@echo "Generating $@..."
	@-mkdir -p "$(@D)"
	@-mkdir -p "$(patsubst $(DEST)/%,$(CACHE)/%,$(@D))"
	pandoc --toc --toc-depth=3 \
		--base-header-level=2 \
		--mathml=https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=MML_HTMLorMML \
		--smart --normalize --ascii --email-obfuscation=references \
		--highlight-style=$(word 1, kate monochrome espresso zenburn haddock tango) \
		--variable inline_logo="$$(cat $(CACHE)/logo-inline.svg)" \
		--from markdown+footnotes+inline_notes+table_captions \
		--to html5 --standalone \
		$(foreach F,\
			$(filter $(THEME)/template.html, $^),\
			--template $(F) \
		) \
		$(foreach F,\
			$(filter %.css, $^),\
			--css=$(F) \
		) \
		--filter $(SNEL)/pandoc/prerequisites.py \
		--filter pandoc-citeproc \
		$(foreach F,\
			$(filter %.bib %/references.yaml, $^),\
			--bibliography=$(F) \
		) \
		$(foreach F,\
			$(filter $(THEME)/%.py, $^),\
			--filter=$(F) \
		) \
		--metadata root='$(shell realpath $(DEST) --relative-to $(@D))' \
		--metadata req-dump='$(patsubst $(DEST)/%.html,$(CACHE)/%.md.req,$@)' \
		--metadata req-prefix='$(@D)' \
		--metadata source='$(SRC)' \
		--metadata destination='$(DEST)' \
		--metadata cache='$(CACHE)' \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST))' \
		--metadata file='$(@F)' \
		--output=$@ \
		$< $(filter %/metadata.yaml, $^)



# Logo & covers ###############################################################

# Favicon as bitmap
$(DEST)/favicon.ico: $(THEME)/logo.svg
	@-mkdir -p $(@D)
	convert -transparent white -resize 16x16 $< $@


# Favicon as embedded PNG with boolean transparency
$(DEST)/favicon2.ico: $(THEME)/logo.svg
	@-mkdir -p $(@D)
	convert -background none -resize 16x16 -transparent-color '#fff' \
		-compress Zip -define 'png:format=png8' \
		-define 'png:compression-level=9' -gravity center \
		$< $@


# Icon for bookmark on Apple devices
$(DEST)/apple-touch-icon.png: $(THEME)/logo.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 150x150 -colors 8 \
		-border 26 -bordercolor '#fff' -background '#fff' -negate \
		-define 'png:format=png8' -define 'png:compression-level=9' \
		$< $@


# Generate ASCII art logo
$(CACHE)/logo.txt: $(THEME)/logo.svg
	convert -density 1200 -resize 128x128 $< $@.jpg
	jp2a --width=23 --chars=\ -~o0@ -i $@.jpg | sed 's/^/$(shell printf '%-28s')/' > $@
	rm $@.jpg


# Create a logo suitable for inlining by removing the top <?XML?> declaration
# and stripping any inline styles (GNU sed-specific and non-portable!)
$(CACHE)/logo-inline.svg: $(THEME)/logo.svg
	@-mkdir -p $(@D)
	sed 's/\(^<?[^?]*?>\)\|\(\ style="[^"]*"\)//g' $< > $@


# Cover for EPUB books
$(CACHE)/%/epub-cover.jpg: $(wildcard $(SRC)/%/cover.*)
	@echo 'Generating EPUB cover...'
	convert -resize 600x800 $< $@



# Referenced files #####################################################################

# Create a zipped archive
$(DEST)/%.zip: $(SRC)/%
	zip -r9 $@ $^


# Create a zipped archive
$(DEST)/%.tar.gz: $(SRC)/%
	tar -zcvf $@ $^


# Any file referenced in the source should show up in the destination
$(DEST)/%: $(SRC)/%
	cp --dereference $< $@


# As a last resort, try to find a recipe in the source directory
# Beware of infinite loops?
# Find a way to also monitor changes to prerequisites here? To show all targets:
# make --dry-run --always-make --debug=b <TARGET> | sed -n 's/\s*Must remake target '\(.*\)'\./\1/p"
$(DEST)/%: 
	@echo 'Trying to find recipe for $@...'
	@cd $(patsubst $(DEST)%,$(SRC)%,$(@D)) && \
	$(MAKE) $(@F) && mv $(@F) $(@D)


# Generate a YAML bibliography from a BIB bibliography
%.yaml: %.bib
	pandoc-citeproc --bib2yaml $< > $@


.PHONY: prepare all html resources
