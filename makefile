SNEL_DIR := .
include snel.mk


install:
	install -m 644 $(SNEL_DIR)/snel.mk $(INCLUDE_DIR)/snel.mk
	install -m 644 -D -t $(SHARE_DIR)/theme $(wildcard $(SNEL_DIR)/theme/up.svg) 
	install -m 755 -D -t $(SHARE_DIR)/theme/pandoc $(wildcard $(SNEL_DIR)/theme/pandoc/*) 
	install -m 644 -D -t $(SHARE_DIR)/theme/stylesheet $(wildcard $(SNEL_DIR)/theme/stylesheet/*) 
	install -m 644 -D -t $(SHARE_DIR)/index $(wildcard $(SNEL_DIR)/index/*) 


uninstall:
	rm $(INCLUDE_DIR)/snel.mk
	rm -r $(SHARE_DIR)
