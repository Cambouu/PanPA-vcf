# Dev Log

## 2026-02-26 10:43:13 +0100
- Ran: `pip install -e .`
- Result: build isolation failed while installing build deps (no network), error: `No matching distribution found for setuptools>=64`.
- Changes made earlier in this session:
  - Added `pyproject.toml` with build-system requirements (setuptools, wheel, Cython).
  - Updated `setup.py`:
    - Read version from `PanPA/version.py` without importing the package.
    - Fixed Python version message and `python_requires`.
    - Use `requirements.txt` for `install_requires`.
    - Use repo-root paths for README/requirements.

## 2026-02-26 10:43:31 +0100
- Ran: `PIP_NO_BUILD_ISOLATION=1 pip install -e .`
- Result: still attempted build dependency install and failed (no network), error: `No matching distribution found for setuptools>=64`.

## 2026-02-26 10:45:18 +0100
- Ran: `pip install -e . --no-build-isolation`
- Result: metadata generation failed; `read_version()` regex didn’t match.
- Change: fixed version regex in `setup.py` to allow whitespace (single-escaped `\s`).

## 2026-02-26 10:45:56 +0100
- Ran: `pip install -e . --no-build-isolation`
- Result: Cython compile error in `PanPA/_main.pyx` (`no suitable method found` for `a.replace`).
- Change: cast C++ `string` to Python `bytes` before `.replace()` in two loops.

## 2026-02-26 10:46:19 +0100
- Ran: `pip install -e . --no-build-isolation`
- Result: build succeeded, install failed due to sandbox permissions: `Operation not permitted: '/Users/fawaz/.local/lib'`.

## 2026-02-26 10:47:19 +0100
- Ran (escalated): `pip install -e . --no-build-isolation`
- Result: success. Editable install completed.

## 2026-02-26 10:53:36 +0100
- Start: implement shipping generated C++ sources and optional Cython build; add `--version` CLI flag.

## 2026-02-26 10:54:19 +0100
- Ran: `cython -3 --cplus` over `PanPA/*.pyx`
- Result: Cython errors in `graph_edit_distance.pyx` and `graph_smith_waterman.pyx` (int vs double due to `/`).
- Change: replaced `/` with `//` for integer division at those lines.

## 2026-02-26 10:54:51 +0100
- Ran: `cython -3 --cplus -o ...` over `PanPA/*.pyx` after fixes.
- Result: generated `.cpp` files (one warning about const qualifier in `reverse_complement_fast.pyx`).
- Changes:
  - `setup.py`: optional Cython build; fall back to pre-generated `.cpp` sources when Cython isn't available.
  - `MANIFEST.in`: include `.pyx`/`.cpp` sources in sdist.
  - `PanPA/main.py`: add `--version` flag.

## 2026-02-26 10:55:10 +0100
- Change: `pyproject.toml` build-system no longer requires Cython (since we ship generated `.cpp`).

## 2026-02-26 10:59:16 +0100
- Fix for build error in `reverse_complement_fast`:
  - `PanPA/reverse_complement_fast.pyx`: make `seq_pointer` `const char *`.
  - Regenerated `PanPA/reverse_complement_fast.cpp` with Cython.

## 2026-02-26 10:59:34 +0100
- Ran: `pip install -e .`
- Result: build isolation failed (offline) while trying to install `setuptools>=64`.

## 2026-02-26 11:00:28 +0100
- Fix: `setup.py` now passes relative source paths to `Extension(...)` to avoid absolute-path error during build.

## 2026-02-26 11:02:23 +0100
- Ran (escalated): `pip install -e . --no-build-isolation`
- Result: success.

## 2026-02-26 11:04:13 +0100
- Added `scripts/regen_cython.sh` to regenerate `.cpp` from `.pyx` using Cython.
- Set executable bit on `scripts/regen_cython.sh`.

## 2026-02-26 11:51:25 +0100
- Updated docs in `README.md` to reflect Python 3.6–3.11 support, no Cython required for install, offline build-isolation note, and `--version` usage.
- Updated `environment.yml` to current toolchain (python<=3.11, setuptools, wheel, pip, cython).

## 2026-02-26 11:53:46 +0100
- Updated `.gitignore` to stop ignoring generated `PanPA/*.cpp` so they can be committed.

## 2026-02-26 11:57:19 +0100
- Removed legacy `PanPA/reverse_complement_fast.c` to avoid confusion (we ship C++ now).
- Updated `.gitignore` to ignore `PanPA/reverse_complement_fast.c` going forward.

## 2026-02-26 12:16:29 +0100
- Updated Python upper bound to <3.14:
  - `setup.py`: version guard + `python_requires`.
  - `README.md`: support statement updated to 3.6–3.13.
  - `environment.yml`: python constraint to `<3.14`.

## 2026-02-26 12:19:27 +0100
- `setup.py`: default to pre-generated `.cpp` sources; only use Cython when `PANPA_USE_CYTHON=1`.
- This avoids Cython-generated absolute source paths breaking wheel builds.

## 2026-02-26 12:23:10 +0100
- `setup.py`: resolve ROOT, use `os.path.relpath` for extension sources to guarantee relative paths in wheel builds.
- Removed legacy `tests_require` to avoid setuptools warning.
