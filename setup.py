import os
import sys
import pathlib
import re
from setuptools import setup, find_packages, Extension

USE_CYTHON = os.environ.get("PANPA_USE_CYTHON") == "1"
if USE_CYTHON:
    try:
        from Cython.Build import cythonize
    except Exception as exc:
        raise RuntimeError("PANPA_USE_CYTHON=1 but Cython is not available") from exc

'''
I can also check for cython's version using
from Cython.Compiler.Version import version

now version is a string, e.g. 0.29.21
'''

'''
It is better to ship this without the need to have Cython
I should do what is described here
https://cython.readthedocs.io/en/latest/src/userguide/source_files_and_compilation.html
at section Distributing Cython Modules

The idea is that I use extensions and have a check whether I am requiring cython or not
'''

CURRENT_PYTHON = sys.version_info[:2]
REQUIRED_PYTHON_LOWER = (3, 6)
REQUIRED_PYTHON_UPPER = (3, 13)

if CURRENT_PYTHON < REQUIRED_PYTHON_LOWER or CURRENT_PYTHON > REQUIRED_PYTHON_UPPER:
    sys.stderr.write("PanPA requires Python between 3.6 and 3.13 "
                     "your current version is {}".format(CURRENT_PYTHON))
    sys.exit(1)

ROOT = pathlib.Path(__file__).resolve().parent

with open(ROOT / "README.md", "r") as readme:
    long_description = readme.read()

reqs = []
with open(ROOT / "requirements.txt", "r") as infile:
    for line in infile:
        l = line.strip()
        if not l.startswith("#"):
            reqs.append(l)

def read_version():
    version_file = ROOT / "PanPA" / "version.py"
    content = version_file.read_text()
    match = re.search(r"^\s*__version__\s*=\s*[\"']([^\"']+)[\"']\s*$", content, re.M)
    if not match:
        raise RuntimeError("Unable to find __version__ in PanPA/version.py")
    return match.group(1)

def _relpath(path):
    rel = os.path.relpath(path, ROOT)
    return rel.replace(os.sep, "/")

def build_extensions():
    pyx_files = sorted((ROOT / "PanPA").glob("*.pyx"))
    extensions = []
    for pyx in pyx_files:
        module = f"PanPA.{pyx.stem}"
        if USE_CYTHON:
            src = _relpath(pyx)
        else:
            cpp = pyx.with_suffix(".cpp")
            if not cpp.exists():
                raise RuntimeError(
                    f"Missing generated source {cpp}. Run scripts/regen_cython.sh to generate it."
                )
            src = _relpath(cpp)
        extensions.append(Extension(module, [src], language="c++"))

    if USE_CYTHON:
        return cythonize(
            extensions,
            compiler_directives={
                "boundscheck": False,
                "cdivision": True,
                "nonecheck": False,
                "initializedcheck": False,
                "language_level": "3",
            },
        )
    return extensions


setup(
    name="PanPA",
    version=read_version(),
    license="MIT",
    author="Fawaz Dabbaghie",
    url='https://fawaz-dabbaghieh.github.io/',
    description="Building and aligning to protein graphs",
    long_description=long_description,
    long_description_content_type="text/markdown",
    # keywords="proteins alignment graphs pangenome bioinformatics software",
    classifiers=[
        "Development Status :: 3 - Alpha",
        # "License :: OSI Approved :: GNU General Public License v2 or later (GPLv2+)",
        "Programming Language :: Python :: 3.6",
        "Operating System :: POSIX :: Linux",
        "Natural Language :: English",
        "Intended Audience :: Science/Research",
        "Topic :: Scientific/Engineering :: Bioinformatics",
    ],
    setup_requires=[],
    include_package_data=True,
    python_requires=">=3.6,<3.14",
    packages=find_packages(),
    install_requires=reqs,
    ext_modules=build_extensions(),
    entry_points={
        "console_scripts": ["PanPA = PanPA.main:main"],
    },
)
