# AGENTS.md

This file provides guidance for AI coding agents operating in this repository.

## Project Overview

This is the `fiddler-examples` repository containing:

- **`fiddler_utils/`** -- A Python library (`fiddler-utils`) providing high-level abstractions over the Fiddler Python client for administrative automation tasks.
- **`quickstart/`**, **`cookbooks/`** -- Jupyter notebooks demonstrating Fiddler features, each with isolated `uv`-managed virtual environments.
- **`misc-utils/`** -- Ad-hoc admin utility notebooks and scripts.
- **`integration-examples/`** -- Integration guides (Airflow, BigQuery, SageMaker, Snowflake).

The primary codebase with tests and structured code is under `fiddler_utils/`.

## Build & Install

```bash
# Install package in editable mode (from repo root)
pip install -e .

# Install with dev dependencies (pytest, coverage, mypy, black)
pip install -e ".[dev]"
```

Python >= 3.10 is recommended. The package requires `fiddler-client >= 3.10.0`.

## Test Commands

Tests use **pytest** and live in `fiddler_utils/tests/`.

```bash
# Run all tests
pytest fiddler_utils/tests/ -v

# Run a single test file
pytest fiddler_utils/tests/test_fql.py -v

# Run a single test class
pytest fiddler_utils/tests/test_fql.py::TestExtractColumns -v

# Run a single test method
pytest fiddler_utils/tests/test_fql.py::TestExtractColumns::test_simple_expression -v

# Run tests with coverage
pytest fiddler_utils/tests/ --cov=fiddler_utils --cov-report=html
```

There is no CI pipeline -- tests are run manually. Aim for 80%+ coverage when adding new code.

## Lint & Format

```bash
# Format code with Black
black fiddler_utils/

# Type check with mypy
mypy fiddler_utils/
```

No pre-commit hooks are configured. Black and mypy are the expected tools (declared as dev dependencies in `setup.py`).

## Code Style Guidelines

### Formatting

- **Formatter:** Black (default settings -- 88 char line length)
- **Quotes:** Single quotes for Python strings (`'string'`), double quotes for docstrings
- **f-strings:** Always use f-strings for string interpolation (not `%` or `.format()`)

### Imports

Follow PEP 8 import ordering:
1. Standard library
2. Third-party packages
3. Local/package imports

```python
import logging
from typing import Optional, List, Dict

import fiddler as fdl      # canonical alias for fiddler
from tqdm import tqdm

from .connection import get_or_init
from .exceptions import ValidationError
```

- Use `from __future__ import annotations` when needed for forward references
- Guard the fiddler import with `try/except ImportError` in modules that use it directly:
  ```python
  try:
      import fiddler as fdl
  except ImportError:
      raise ImportError('fiddler-client is required. Install it with: pip install fiddler-client')
  ```

### Type Annotations

- Add type hints to **all public method signatures** (parameters and return types)
- Use `typing` module types: `Optional`, `Dict`, `List`, `Set`, `Tuple`, `Any`
- The package includes `py.typed` -- type information is part of the public API
- Pyright is configured at `basic` type checking mode (see `.vscode/settings.json`)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Modules | `snake_case` | `connection.py`, `fql.py` |
| Classes | `PascalCase` | `SchemaValidator`, `ModelComparator` |
| Functions/methods | `snake_case` | `get_or_init`, `extract_columns` |
| Private members | `_leading_underscore` | `_get_asset_key`, `_initialized` |
| Constants | `UPPER_SNAKE_CASE` | `URL`, `AUTH_TOKEN` |

### Docstrings

Use **Google-style** docstrings on all public classes, methods, and modules:

```python
def validate_columns(
    columns: set[str],
    model: 'fdl.Model',
) -> tuple[bool, Optional[str]]:
    """Validate that columns exist in the model schema.

    Args:
        columns: Set of column names to validate.
        model: Target Fiddler model to validate against.

    Returns:
        Tuple of (is_valid, error_message). error_message is None if valid.

    Raises:
        SchemaValidationError: If validation encounters an unexpected error.

    Example:
        ```python
        is_valid, msg = SchemaValidator.validate_columns({'age'}, model)
        ```
    """
```

Every module file must have a module-level docstring.

### Error Handling

- Use the custom exception hierarchy rooted at `FiddlerUtilsError` (see `fiddler_utils/exceptions.py`)
- Specific exceptions: `ConnectionError`, `ValidationError`, `SchemaValidationError`, `FQLError`, `AssetNotFoundError`, `AssetImportError`, `BulkOperationError`
- Exceptions should carry context attributes (e.g., `url`, `expression`, `missing_columns`)
- For bulk/iteration operations, use the `on_error` pattern with `'warn'` / `'skip'` / `'raise'` options for graceful degradation
- Log errors/warnings with `logger.warning()` or `logger.error()` before re-raising or skipping

### Logging

- Create module-level loggers: `logger = logging.getLogger(__name__)`
- Package root uses `NullHandler` pattern (users configure their own logging)
- Prefix log messages with class/module context: `[ModelComparator] ...`

### Data Classes

- Use `@dataclass` for structured data (not plain dicts)
- Use `field(default_factory=...)` for mutable defaults
- Add `__post_init__` for validation when needed
- Use `@property` for computed values

### Design Patterns in Use

- **ABC + Generics:** `BaseAssetManager(ABC, Generic[T])` for asset managers
- **Context managers:** `connection_context()` for scoped connections
- **Factory methods:** `ComparisonConfig.all()`, `.schema_only()` for presets
- **Facade pattern:** `EnvironmentReporter` wrapping `ProjectManager`

## Testing Patterns

- **Framework:** pytest with `unittest.mock` (Mock, MagicMock, patch)
- **Organization:** Class-based grouping (e.g., `class TestExtractColumns:`)
- **Naming:** Descriptive method names (`test_simple_expression`, `test_missing_columns`)
- **Docstrings:** Every test method should have a docstring explaining what it tests
- **Assertions:** Use plain `assert` statements (not unittest-style `self.assertEqual`)
- **Fixtures:** Use `@pytest.fixture` for shared setup
- **TDD encouraged:** Write tests before implementation when adding new utilities

## Git & Repository Notes

- **Git LFS is required.** Tracked extensions: `.csv`, `.json`, `.jsonl`, `.png`, `.jpg`, `.jpeg`, `.pkl`, `.pth`, `.h5`, `.joblib`, `.onnx`, `.pb`, `.npz`, `.npy`
- **Do not commit:** `.env` files, API tokens, `pyproject.toml`, `uv.lock`, or `.csv` files (all gitignored)
- **Notebooks:** Each notebook in `quickstart/latest/` and `cookbooks/` has a corresponding requirements file under `requirements/` and an isolated venv under `.venvs/`
- **VS Code** is the assumed editor (settings and extensions configured in `.vscode/`)
