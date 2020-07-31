.PHONY: default
default: assets

include include/snel.mk

MAKEFILES := $(patsubst include/%,%,$(wildcard include/*))

.PHONY: assets
assets: $(STYLE_TARGET_FILES)

.PHONY: install
install: assets
	install --mode 755 -D --target-directory $(INCLUDE_DIR)/ \
		$(addprefix include/,$(MAKEFILES))
	install --mode=644 -D --target-directory $(SHARE_DIR)/ \
	    $(STYLE_TARGET_FILES)
	install --mode=644 -D --target-directory $(SHARE_DIR)/jq/ \
	    $(addprefix $(ASSET_DIR)/jq/,snel.jq)
	install --mode=644 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(addprefix $(PANDOC_DIR)/,nav.html page.html metadata.json)
	install --mode=755 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(PANDOC_DIR)/extract-references.py

.PHONY: uninstall
uninstall:
	rm -f $(addprefix $(INCLUDE_DIR)/,$(MAKEFILES))
	rm -r $(SHARE_DIR)
