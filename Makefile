automatic: assets

include include/snel.mk

assets: $(STATIC_ASSET_FILES)

install: assets
	install include/snel.mk $(INCLUDE_DIR)/
	install --mode=644 -D --target-directory $(SHARE_DIR)/ \
	    $(STATIC_ASSET_FILES)
	install --mode=644 -D --target-directory $(SHARE_DIR)/ \
	    $(addprefix $(ASSET_DIR)/,index.jq)
	install --mode=644 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(addprefix $(PANDOC_DIR)/,nav.html index.html page.html metadata.json)
	install --mode=755 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(PANDOC_DIR)/extract-references.py

uninstall:
	rm $(INCLUDE_DIR)/snel.mk
	rm -r $(SHARE_DIR)

.PHONY: install uninstall automatic
