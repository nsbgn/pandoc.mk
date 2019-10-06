PREFIX=/usr/local

test: build
	jq '.' < ../website/.build/cache/index.json

build:
	cd ../website && make

install: 
	sudo install snel.mk $(PREFIX)/include/

.PHONY: install test
