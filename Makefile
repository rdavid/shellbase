# SPDX-FileCopyrightText: 2023-2025 David Rabkin
# SPDX-License-Identifier: 0BSD
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
