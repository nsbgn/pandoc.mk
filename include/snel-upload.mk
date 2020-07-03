include snel-variables.mk

ifndef PROTOCOL
    PROTOCOL := ssh
endif
ifndef USER
    USER := user
endif
ifndef HOST
    HOST := host
endif
ifndef REMOTE_DIR
    REMOTE_DIR := /home/$(USER)/public_html
endif
ifndef PORT
ifeq ($(PROTOCOL),ssh)
    PORT := 22
else
    PORT := 20
endif
endif

upload: upload-$(PROTOCOL)

upload-ftp: 
	read -s -p 'FTP password: ' password && \
	lftp -u "$(USER),$$password" -p "$(PORT)" \
	-e "mirror --reverse --only-newer --verbose --dry-run --exclude $(CACHE) $(DEST) $(REMOTE_DIR)" \
	$(HOST)

upload-ssh:
	rsync -e "ssh -p $(PORT)" \
		--recursive --times --copy-links --verbose --progress \
		--exclude="$(CACHE)" \
		 $(HOST) $(USER)@$(HOST):'$(REMOTE_DIR)'
