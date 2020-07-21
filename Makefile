automatic: assets

include include/snel.mk

MAKEFILES := $(patsubst include/%,%,$(wildcard include/*))

assets: $(STYLE_TARGET_FILES)

install: assets
	install --mode 755 -D --target-directory $(INCLUDE_DIR)/ \
		$(addprefix include/,$(MAKEFILES))
	install --mode=644 -D --target-directory $(SHARE_DIR)/ \
	    $(addprefix $(ASSET_DIR)/,index.jq) $(STYLE_TARGET_FILES)
	install --mode=644 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(addprefix $(PANDOC_DIR)/,nav.html page.html metadata.json)
	install --mode=755 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(PANDOC_DIR)/extract-references.py

uninstall:
	rm -f $(addprefix $(INCLUDE_DIR)/,$(MAKEFILES))
	rm -r $(SHARE_DIR)

.PHONY: install uninstall automatic
