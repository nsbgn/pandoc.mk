# This combines the `snel` recipes for "index" and "documents".

include $(addprefix $(dir $(abspath $(lastword $(MAKEFILE_LIST))))/, \
	snel-index.mk snel-document.mk \
)

