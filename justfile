install:
    cd src && uv sync --all-extras

pre-commit-install:
    cd src && uv run pre-commit install

pre-commit:
    cd src && uv run pre-commit run --all-files -v

test:
    cd src && uv run ptw --ext=.py,.yml,.yaml,.ini ../examples .

ci-test:
    cd src && uv run pytest

dump:
    cd src && uv run python ../scripts/dump_schemas.py > ../schemas/v1beta1.json
