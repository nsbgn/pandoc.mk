.PHONY: default
default: 
	@echo "Run 'sudo make install' to install globally. See INSTALL.md."

include include/snel.mk

MAKEFILES := $(patsubst include/%,%,$(wildcard include/*))

.PHONY: install
install:
	install --mode 755 -D --target-directory $(INCLUDE_DIR)/ \
		$(addprefix include/,$(MAKEFILES))
	install --mode=644 -D --target-directory $(SHARE_DIR)/style/ \
		$(wildcard $(STYLE_DIR)/*.scss)
	install --mode=644 -D --target-directory $(SHARE_DIR)/jq/ \
		$(wildcard $(JQ_DIR)/*.jq)
	install --mode=644 -D --target-directory $(SHARE_DIR)/pandoc/ \
		$(wildcard $(PANDOC_DIR)/*)

.PHONY: uninstall
uninstall:
	rm -f $(addprefix $(INCLUDE_DIR)/,$(MAKEFILES))
	rm -r $(SHARE_DIR)
