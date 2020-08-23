# This sets the variables that all of `snel` needs; included by every file.

# Location of this makefile
BASE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Installation directories
PREFIX := /usr/local
INCLUDE_DIR := $(PREFIX)/include
SHARE_DIR := $(PREFIX)/share/snel

# If installed globally in $PREFIX/include, then we should be able to find
# other assets in $PREFIX/share/snel. Otherwise, we can find them relative to
# the current makefile.
ifeq ($(BASE_DIR),$(INCLUDE_DIR))
	ASSET_DIR := $(SHARE_DIR)
else
	ASSET_DIR := $(BASE_DIR)/../share
endif
STYLE_DIR := $(ASSET_DIR)/style
JQ_DIR := $(ASSET_DIR)/jq
PANDOC_DIR := $(ASSET_DIR)/pandoc

# Source and destination directories, and FTP credentials. These are
# expected to be changed in the `make` call or before the `include` statement.
ifndef SRC
	SRC := .
endif
ifndef DEST
	DEST := build
endif
ifndef STYLE
	STYLE := web
endif
ifndef CACHE
	CACHE := $(DEST)/.cache
endif
ifndef IGNORE
	IGNORE=Makefile .git .gitignore
endif
IGNORE:=$(IGNORE) $(CACHE) $(DEST)

