PREFIX=/usr/local
INCLUDE_DIR=$(PREFIX)/include
SHARE_DIR=$(PREFIX)/share/snel

install:
	install snel.mk $(INCLUDE_DIR)/
	install -D --target-directory $(SHARE_DIR)/ \
	    index.jq \
	    filters/pandoc-extract-references.py \
	    $(addprefix assets/,logo.svg style.scss) \
	    $(addprefix templates/,index.html metadata.json nav.html page.html)

.PHONY: install
