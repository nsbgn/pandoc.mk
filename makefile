MAKEDIR = .
SRC = manual
THEME = $(SRC)/theme
DEST = dist
CACHE = $(DEST)/.cache

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



# Static assets ###############################################################

# Crimson Text font
URL_CRIMSON := 'https://fonts.gstatic.com/s/crimsontext/v6/3IFMwfRa07i-auYR-B-zNegdm0LZdjqr5-oayXSOefg.woff2'
$(DEST)/font.woff2:
	@-mkdir -p $(@D)
	wget -O $@ $(URL_CRIMSON)


# Minified stylesheet
$(DEST)/style.css: $(THEME)/style.less $(wildcard $(THEME)/*.less)
	@-mkdir -p $(@D)
	lessc --clean-css="--s1 --advanced --compatibility=ie8" $< $@


# Minified JavaScript for creating a dynamic navigation menu from the sitemap
$(DEST)/index.js: $(MAKEDIR)/sitemap/index.js $(MAKEDIR)/sitemap/externs.js
	@-mkdir -p $(@D)
	closure-compiler -O ADVANCED --warning_level VERBOSE \
		--externs $(MAKEDIR)/sitemap/externs.js \
		--define='INDEX=/index.html' \
		--js_output_file $@ $<


# Make dummy page for use in static page generation
$(CACHE)/dummy.html: $(THEME)/template.html
	@-mkdir -p $(@D)
	echo "dummy" | pandoc \
		--template $< --variable root='.' \
		--to html5 --standalone --output=$@


# Pages & dynamic assets ######################################################

# Create a table of contents of the source directory 
$(DEST)/sitemap.json: $(MAKEDIR)/sitemap/sitemap.py $(SOURCES)
	@-mkdir -p $(@D)
	python3 $< $(SRC) > $@


# Create a static index page for those cases in which the dynamic one is unavailable
$(DEST)/index.html: \
 		   $(MAKEDIR)/sitemap/index.dump.js \
		   $(CACHE)/dummy.html \
		   $(MAKEDIR)/sitemap/index.js \
		   $(DEST)/sitemap.json
	@-mkdir -p $(@D)
	@echo "Generating index page $@..."
	phantomjs $+ $@


# Create HTML documents
$(DEST)/%.html: \
		$(SRC)/%.md \
		$(THEME)/template.html \
		$(wildcard $(THEME)/*.py) \
		$(MAKEDIR)/pandoc/filters/prerequisites.py \
                $(CACHE)/logo-inline.svg \
		$(SRC)/references.bib
	@echo "Generating $@..."
	@-mkdir -p "$(@D)"
	@-mkdir -p "$(patsubst $(DEST)/%,$(CACHE)/%,$(@D))"
	pandoc --toc --toc-depth=3 \
		--base-header-level=2 \
		--mathml=https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=MML_HTMLorMML \
		--smart --normalize --ascii --email-obfuscation=references \
		--highlight-style=$(word 1, kate monochrome espresso zenburn haddock tango) \
		--to html5 --standalone --template $(THEME)/template.html \
		--variable inline_logo="$$(cat $(CACHE)/logo-inline.svg)" \
		--from markdown+footnotes+inline_notes+table_captions \
		--filter pandoc-citeproc $(foreach F,\
			$(filter %.bib %/references.yaml, $^), --bibliography=$(F)\
		) \
		$(foreach F,\
			$(filter $(THEME)/%.py, $^), --filter=$(F)\
		)\
		--filter $(MAKEDIR)/pandoc/filters/rearrange_main.py \
		--metadata root='$(shell realpath $(DEST) --relative-to $(@D))' \
		--metadata req-dump='$(patsubst $(DEST)/%.html,$(CACHE)/%.md.req,$@)' \
		--metadata req-prefix='$(@D)' \
		--metadata source='$(SRC)' \
		--metadata destination='$(DEST)' \
		--metadata cache='$(CACHE)' \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST))' \
		--metadata file='$(@F)' \
		--filter $(MAKEDIR)/pandoc/filters/prerequisites.py \
		$(foreach F,\
			$(filter %.css, $^), --css=$(F)\
		)\
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
