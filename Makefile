.POSIX:
PREFIX = /usr/local
DIR = $(DESTDIR)$(PREFIX)/bin

all:
install:
	mkdir -pm755 -- "$(DIR)"
	cp -f -- "sed.sh" "$(DIR)/sed"
uninstall:
	rm -f -- "$(DIR)/sed"
