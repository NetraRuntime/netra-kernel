PYTHON ?= python3
REPO_ROOT := $(CURDIR)
export PYTHONPATH := $(REPO_ROOT)/compiler$(if $(PYTHONPATH),:$(PYTHONPATH))

.PHONY: check examples package python-check repository-check shell-check test validate

python-check:
	$(PYTHON) -m compileall -q compiler/netra_compiler tools/compiler tools/ci tests/compiler

test:
	$(PYTHON) -m unittest discover -s tests/compiler -v

repository-check:
	$(PYTHON) tools/ci/check_repository.py

validate:
	$(PYTHON) tools/compiler/validate_gfx950_tactic_catalog.py

examples:
	$(PYTHON) tools/ci/compile_examples.py

shell-check:
	git ls-files -z '*.sh' | xargs -0 -r -n1 bash -n
	git diff --check

check: python-check test repository-check validate examples shell-check

package:
	PYTHON=$(PYTHON) bash tools/ci/build_package.sh
