# SPDX-FileCopyrightText: 2023-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
REDO ?= redo
.DEFAULT_GOAL := all
.PHONY: all clean lint test test-container warning

warning:
	@echo WARNING: Acting as a proxy for redo commands.

all: warning
	$(REDO) $@

clean: warning
	$(REDO) $@

lint: warning
	$(REDO) $@

test: warning
	$(REDO) $@

test-container: warning
	$(REDO) $@
