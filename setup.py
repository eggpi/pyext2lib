from distutils.core import setup
from distutils.extension import Extension

try:
	from Cython.Distutils import build_ext
except ImportError:
	files = ["src/precompiled/pyext2lib.c"]
	cmdclass = {}
else:
	files = ["src/pyext2lib.pyx"]
	cmdclass = {"build_ext" : build_ext}

ext_modules=[
	Extension("pyext2lib",
			files,
			libraries=["ext2fs"])
]

setup(
	name = "pyext2lib",
	cmdclass = cmdclass,
	ext_modules = ext_modules
)
