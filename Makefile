REDO ?= redo
.DEFAULT_GOAL := all
.PHONY: all clean test

warning:
	@echo WARNING: Acting as a proxy for redo commands.

all: warning
	$(REDO) $@

clean: warning
	$(REDO) $@

test: warning
	$(REDO) $@
