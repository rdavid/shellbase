REDO ?= redo
.DEFAULT_GOAL := all
.PHONY: all clean test

warning:
	@echo WARNING: Just proxying commands to redo command.

all: warning
	$(REDO) $@

clean: warning
	$(REDO) $@

test: warning
	$(REDO) $@
