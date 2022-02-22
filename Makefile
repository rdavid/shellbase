REDO ?= redo

.DEFAULT_GOAL := all

warning:
	@echo WARNING: Just proxying commands to redo command.

all: warning
	$(REDO) $@

clean: warning
	$(REDO) $@

test: warning
	$(REDO) $@
