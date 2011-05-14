from distutils.core import setup
from distutils.extension import Extension

try:
	from Cython.Distutils import build_ext
except ImportError:
	files = ["precompiled/pyext2lib.c"]
	cmdclass = {}
else:
	files = ["pyext2lib.pyx"]
	cmdclass = {"build_ext" : build_ext}

ext_modules=[
	Extension("pyext2lib",
			files,
			libraries=["ext2fs"])
]

setup(
	name = "deviceinfo_ext2",
	cmdclass = cmdclass,
	ext_modules = ext_modules
)
