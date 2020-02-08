default: build/style.css

include snel.mk

install: default
	install snel.mk $(INCLUDE_DIR)/
	install --mode=644 -D --target-directory $(SHARE_DIR)/ \
	    build/style.css
	install --mode=644 -D --target-directory $(SHARE_DIR)/ \
	    $(addprefix $(RESOURCE_DIR)/,index.jq logo.svg)
	install --mode=644 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(addprefix $(PANDOC_DIR)/,nav.html index.html page.html metadata.json)
	install --mode=755 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(PANDOC_DIR)/extract-references.py

uninstall:
	rm $(INCLUDE_DIR)/snel.mk
	rm -r $(SHARE_DIR)

.PHONY: install uninstall default
