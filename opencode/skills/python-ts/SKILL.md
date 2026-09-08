---
name: python-ts
description: Python conventions. Use when writing Python - ruff for lint/format, mypy type checking, pytest tests, dependency pinning, type annotations on all signatures.
---

# Python Conventions

## Linting & Formatting
- Use **ruff** for both linting and formatting (`ruff check .` / `ruff format .`)
- Use **mypy** for type checking (`mypy .`)
- max-line-length = 88 (ruff default)

## Testing
- Use **pytest** for all tests (`python -m pytest`)
- Test files go in a `tests/` directory at project root
- Name test files `test_*.py`
- Use `pytest fixtures` for shared state, not `setUp` classes

## Dependencies
- Pin dependencies in `requirements.txt`
- Use Python 3.13+ (managed by mise)
- Prefer `python-dotenv` for env vars, `rich` for CLI output

## Style
- Use type annotations on all function signatures
- Prefer `pathlib.Path` over `os.path`
- Use `dataclasses` for data containers
- Use `enum.StrEnum` for string enums
- Prefer `|` union syntax over `Optional` and `Union`
- Use `type` hints for aliased types

## Project Structure
```
project/
├── src/           # Application code
├── tests/         # Test suite
├── requirements.txt
├── pyproject.toml  # If using modern tooling
└── README.md
```
