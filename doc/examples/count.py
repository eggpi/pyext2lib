# -*- coding: utf-8 -*-
#	Copyright 2011, Guilherme Gonçalves (guilherme.p.gonc@gmail.com)
#	This file is part of PyExt2lib.
#
#	PyExt2lib is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	PyExt2lib is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with PyExt2lib.  If not, see <http://www.gnu.org/licenses/>.

import sys
import pyext2lib

def count_inodes_blocks(fs):
	""" Iterates through all inodes and their blocks.
	Returns a tuple (inode count, block count).
	"""

	block_flags = pyext2lib.BLOCK_FLAG_READ_ONLY | pyext2lib.BLOCK_FLAG_DATA_ONLY

	inodes = 0
	blocks = [0]
	count_block = lambda fs, blk, blkc: blocks.append(blocks.pop() +1)

	for inode in fs.iterinodes():
		inode.block_iterate(count_block, block_flags)
		inodes += 1

	return (inodes, blocks.pop())

if __name__ == "__main__":
	if len(sys.argv) < 2:
		print "Need a device to work!"
		sys.exit(1)

	# We start by extracting some information from
	# the filesystem and its superblock.

	fs = pyext2lib.ExtFS(sys.argv[1], pyext2lib.IO_MANAGER_UNIX)

	print "Filesystem information:"
	print "Device name:", fs.device_name
	print "Block size:", fs.blocksize
	print "Number of groups:", fs.group_desc_count
	print
	print "Superblock information:"
	print "Inode count:", fs.s_inodes_count
	print "Block count:", fs.s_blocks_count
	print "Reserved block count:", fs.s_r_blocks_count
	print "Free blocks count:", fs.s_free_blocks_count
	print "Free inodes count:", fs.s_free_inodes_count
	print "First data block:", fs.s_first_data_block
	print "Blocks per group:", fs.s_blocks_per_group
	print

	# Count the number of inodes and blocks int the filesystem
	inodes, blocks = count_inodes_blocks(fs)
	print "Seen %d inodes and %d blocks" % (inodes, blocks)

	fs.close()
