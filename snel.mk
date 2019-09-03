# Location of snel.mk makefile
BASE := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Source and destination directories, and FTP credentials. These are
# expected to be changed in the `make` call or before the `include` statement.
ifndef ASSETS
    ASSETS := $(BASE)/assets
endif
ifndef SRC
    SRC := $(abspath .)
endif
ifndef DEST
    DEST := build
endif
ifndef CACHE
    CACHE := $(DEST)/.cache
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
ifndef EXCLUDE
    EXCLUDE=Makefile wip
endif

# Find source files
SOURCES = $(addprefix $(SRC)/,$(shell fdfind --exclude wip --extension md . "$(SRC)"))

METADATA_DIR=$(CACHE)/metadata

# Metadata is collected for each source in a corresponding file
METADATA = $(patsubst $(SRC)/%,$(METADATA_DIR)/%.meta.json,$(SOURCES))

# Files referenced in the source documents are targets themselves
REFERENCED = $(shell \
	cat /dev/null $(METADATA) 2> /dev/null \
	| jq --raw-output '.builddir + "/" + .targets[]?' \
	| uniq )



##########################################################################$$$$
# Phony targets

all: html resources

html: $(patsubst $(SRC)/%.md,$(DEST)/%.html,$(SOURCES)) 

resources: \
		$(DEST)/index.html \
		$(DEST)/style.css \
		$(DEST)/crimson.woff2 \
		$(DEST)/favicon.ico \
		$(DEST)/apple-touch-icon.png \
		$(REFERENCED)

upload:
	read -s -p 'FTP password: ' password && \
	lftp -u $(USER),$$password -e \
	"mirror --reverse --only-newer --verbose --dry-run --exclude .cache/ $(DEST) $(REMOTE)" \
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
	convert -density 1200 -resize 128x128 $< $@.jpg
	jp2a --width=23 --chars=\ -~o0@ -i $@.jpg | sed 's/^/$(shell printf '%-28s')/' > $@
	rm $@.jpg


$(CACHE)/filetree.json:
	fdfind . "$(SRC)" $(patsubst %,--exclude '%',$(EXCLUDE)) --exec stat --printf='{"path":"%n","size":%s,"modified":%Y,"type":"%F"}\n' \
	    | jq --null-input 'reduce inputs as $$i ({}; ($$i.path | split("/") ) as $$p | setpath($$p; getpath($$p) + ($$i | .name |= $$p[-1:][0])))' \
	    > $@


# Overview of files & directories including metadata
$(CACHE)/metadata.json: $(CACHE)/filetree.json $(METADATA)
	jq --arg prefix "$(METADATA_DIR)/" \
	    'if (input_filename | endswith(".meta.json")) then . as $$i | (input_filename | ltrimstr($$prefix) | rtrimstr(".meta.json") | split("/")) as $$p | {} | setpath($$p + ["meta"]; $$i) else . end' $^ \
	    > $@


# In format that can be used for generating the index
$(CACHE)/index.json: $(CACHE)/metadata.json
	jq --slurp 'def pred: .key != "meta" and (.value | type == "object"); def arr: if type == "object" then (to_entries | map(select(pred) | .value | arr)) as $$sub | with_entries(select(pred | not)) | .contents = $$sub else . end; reduce .[] as $$i ({}; $$i * .) | arr | .contents' $< \
	> $@


# Overview of directories
#$(CACHE)/index.json: $(ASSETS)/index.py $(METADATA)
#	$< $(SRC) --metadata $(METADATA_DIR) --ignore $(IGNORE) > $@


# Generate static index page 
#$(DEST)/index.html: $(ASSETS)/pandoc-template.html $(CACHE)/index.json
#	@-mkdir -p $(@D)
#	jq -r 'def list: "<a href=\"" + .path + "\">" + (.meta.title // "untitled") + "</a>" + if .contents then .contents | map(list | "<li>"+.+"</li>") | join("") | "<ul>"+.+"</ul>" else "" end; . | list | "<nav id=\"index\"><div><header><div></div></header><div>" + . + "</div><footer></footer></nav>"' \
#	    < $(CACHE)/index.json \
#	    | pandoc --template=$(ASSETS)/pandoc-template.html -o $@


# Dummy page for metadata export
$(CACHE)/metadata-template.txt:
	@-mkdir -p $(@D)
	echo '$$meta-json$$' > $@



##########################################################################$$$$
# Documents

# Create HTML documents
$(DEST)/%.html: \
		$(SRC)/%.md \
		$(CACHE)/%.md.meta.json \
		$(ASSETS)/pandoc-template.html \
		$(ASSETS)/pandoc-extract-references.py \
		$(wildcard $(SRC)/*.bib) 
	@echo "Generating $@..."
	@-mkdir -p "$(@D)"
	@-mkdir -p "$(patsubst $(DEST)/%,$(CACHE)/%,$(@D))"
	pandoc  \
		--metadata source='$(SRC)' \
		--metadata destination='$(DEST)' \
		--metadata cache='$(CACHE)' \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST) --canonicalize-missing)' \
		--metadata file='$(@F)' \
		--metadata root='$(shell realpath $(DEST) --relative-to $(@D) --canonicalize-missing)' \
		--filter $(ASSETS)/pandoc-extract-references.py \
		--from markdown+smart+fenced_divs+inline_notes+table_captions \
		--to html5 \
		--standalone \
		--table-of-contents \
		--toc-depth=3 \
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
		--highlight-style=kate \
		--output=$@ \
		$< \
		$(filter %/metadata.yaml, $^)


# Record metadata for each document
$(METADATA_DIR)/%.md.meta.json: $(SRC)/%.md $(CACHE)/metadata-template.txt $(ASSETS)/pandoc-target-images.py
	@-mkdir -p "$(@D)"
	pandoc \
		--metadata link='$(patsubst $(METADATA_DIR)/%.md.meta.json,%.html,$@)' \
		--metadata original='$(patsubst $(METADATA_DIR)/%.md.meta.json,$(SRC)/%.md,$@)' \
		--metadata builddir='$(DEST)/$(shell realpath $(@D) --relative-to $(CACHE) --canonicalize-missing)' \
		--template='$(CACHE)/metadata-template.txt' \
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
