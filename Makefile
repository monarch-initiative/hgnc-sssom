MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.DEFAULT_GOAL := all
SHELL := bash

WGET = /usr/bin/env wget --timestamping --no-verbose

# https://www.gnu.org/software/make/manual/html_node/Force-Targets.html
FORCE:

.PHONY: all
all: install-requirements format test

install-requirements:
	poetry install

.PHONY: test
test:
	poetry run python -m pytest --ignore=source_template

clean:
	rm -rf `find . -name __pycache__`
	rm -f `find . -type f -name '*.py[co]' `
	rm -rf .pytest_cache
	rm -rf dist

.PHONY: lint
lint:
	poetry run flake8 --exit-zero --max-line-length 120 hgnc.py tests/
	poetry run black --check --diff hgnc.py tests
	poetry run isort --check-only --diff hgnc.py tests

.PHONY: format
format:
	poetry run autoflake \
		--recursive \
		--remove-all-unused-imports \
		--remove-unused-variables \
		--ignore-init-module-imports \
		--in-place hgnc.py tests
	poetry run isort hgnc.py tests
	poetry run black hgnc.py tests

.PHONY: download
download: data/ data/hgnc_complete_set.txt

data/:
	mkdir --parents $@

data/hgnc_complete_set.txt: data/ FORCE
	cd data && $(WGET) http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/tsv/hgnc_complete_set.txt
