# Location of makefile itself
BASE := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Source and destination directories, and FTP credentials. These are
# expected to be changed in the `make` call or before the `include` statement.
ifndef ASSETS
    ASSETS := $(BASE)/assets
endif
ifndef SRC
    SRC := $(BASE)/content
endif
ifndef DEST
    DEST := public
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



##########################################################################$$$$
# Phony targets

all: website resources

resources: \
		$(DEST)/style.css \
		$(DEST)/crimson.woff2 \
		$(DEST)/favicon.ico \
		$(DEST)/logo.svg \
		$(DEST)/logo.png \
		$(DEST)/apple-touch-icon.png 


website: $(patsubst $(SRC)/%.md,$(DEST)/%.html,$(SOURCES)) 
	hugo --minify --source $(BASE) --contentDir $(SRC) --destination $(DEST)


upload:
	read -s -p 'FTP password: ' password && \
	lftp -u $(USER),$$password -e \
	"mirror --reverse --only-newer --verbose --dry-run --exclude .cache/ $(DEST) $(REMOTE)" \
	$(HOST)

.PHONY: all resources website upload



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
$(DEST)/logo.svg: $(ASSETS)/logo.svg
	@-mkdir -p $(@D)
	svgo --input=$< --output=$@

# Fallback logo
$(DEST)/logo.png: $(ASSETS)/logo.svg
	@-mkdir -p $(@D)
	convert $< $@


# Favicon as bitmap
$(DEST)/favicon.ico: $(ASSETS)/logo.svg
	@-mkdir -p $(@D)
	convert $< -transparent white -resize 16x16 -level '0%,100%,0.6' $@


# Icon for bookmark on Apple devices
$(DEST)/apple-touch-icon.png: $(ASSETS)/logo.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 140x140 -gravity center -extent 180x180 \
	    	+level-colors '#fff,#711' -colors 16 \
		-compress Zip -define 'png:format=png8' -define 'png:compression-level=9' \
		$< $@


# ASCII art logo, centred for 79-column text files
$(DEST)/logo.txt: $(DEST)/logo.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 128x128 $< $@.jpg
	jp2a --width=23 --chars=\ -~o0@ -i $@.jpg | sed 's/^/$(shell printf '%-28s')/' > $@
	rm $@.jpg
