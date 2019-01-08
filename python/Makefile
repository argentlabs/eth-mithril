PYTHON = PYTHONPATH=.:../ethsnarks/ python3 
COVERAGE = $(PYTHON) -mcoverage run --source=$(NAME) -p

.PHONY: test
test:
	$(COVERAGE) -m unittest discover test/

coverage: coverage-combine coverage-report

coverage-clean:
	rm -rf .coverage .coverage.* htmlcov

coverage-combine:
	$(PYTHON) -m coverage combine

coverage-report:
	$(PYTHON) -m coverage report

coverage-html:
	$(PYTHON) -m coverage html