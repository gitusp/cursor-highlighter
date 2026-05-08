PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
BIN := $(BIN_DIR)/curpop
SRC := curpop.swift

KARABINER_DIR := $(HOME)/.config/karabiner/assets/complex_modifications
KARABINER_SRC := karabiner/curpop.json
KARABINER_DST := $(KARABINER_DIR)/curpop.json

.PHONY: all build install install-karabiner install-all uninstall clean run

all: build

build: curpop

curpop: $(SRC)
	swiftc -O $(SRC) -o curpop

install: build
	install -d $(BIN_DIR)
	install -m 0755 curpop $(BIN)
	@echo "Installed: $(BIN)"

install-karabiner:
	install -d $(KARABINER_DIR)
	sed 's|~/.local/bin/curpop|$(BIN)|g' $(KARABINER_SRC) > $(KARABINER_DST)
	chmod 0644 $(KARABINER_DST)
	@echo "Installed: $(KARABINER_DST) (shell_command -> $(BIN))"
	@echo "Open Karabiner-Elements -> Complex Modifications -> Add rule to enable."

install-all: install install-karabiner

uninstall:
	rm -f $(BIN)
	rm -f $(KARABINER_DST)

run: build
	./curpop

clean:
	rm -f curpop
