#!/usr/bin/env python

import sys

def replace_cpdef_def(lines):
	""" Replaces cpdef with defs, so that Doxygen recognizes our functions. """

	for i, l in enumerate(lines):
		fields = l.split(" ")
		tokens = map(str.strip, fields)

		try:
			cpdef = tokens.index("cpdef")
		except ValueError:
			continue

		fields[cpdef] = fields[cpdef].replace("cpdef", "def")
		lines[i] = " ".join(fields)

if __name__ == "__main__":

	filters = [ replace_cpdef_def ]

	with open(sys.argv[1]) as inp:
		lines = inp.readlines()
		for flt in filters:
			flt(lines)

	print "".join(lines)
