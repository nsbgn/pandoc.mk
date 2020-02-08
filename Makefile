default: build/style.css

include snel.mk

install: default
	install snel.mk $(INCLUDE_DIR)/
	install --mode=644 -D --target-directory $(SHARE_DIR)/ \
	    build/style.css
	install --mode=644 -D --target-directory $(SHARE_DIR)/ \
	    $(addprefix share/,index.jq logo.svg style.scss)
	install --mode=644 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(addprefix share/pandoc/,nav.html index.html page.html metadata.json)
	install --mode=755 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    share/pandoc/extract-references.py


uninstall:
	rm $(INCLUDE_DIR)/snel.mk
	rm -rf $(SHARE_DIR)

.PHONY: install
