.PHONY: default
default: 
	@echo "Run 'make install' to install globally. See README for other options."

include include/snel.mk

MAKEFILES := $(patsubst include/%,%,$(wildcard include/*))

.PHONY: install
install:
	install --mode 755 -D --target-directory $(INCLUDE_DIR)/ \
		$(addprefix include/,$(MAKEFILES))
	install --mode=644 -D --target-directory $(SHARE_DIR)/style/ \
	    $(wildcard $(STYLE_DIR)/*.scss)
	install --mode=644 -D --target-directory $(SHARE_DIR)/jq/ \
	    $(addprefix $(JQ_DIR)/,snel.jq)
	install --mode=644 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(addprefix $(PANDOC_DIR)/,nav.html page.html metadata.json)
	install --mode=755 -D --target-directory $(SHARE_DIR)/pandoc/ \
	    $(PANDOC_DIR)/extract-references.py

.PHONY: uninstall
uninstall:
	rm -f $(addprefix $(INCLUDE_DIR)/,$(MAKEFILES))
	rm -r $(SHARE_DIR)
