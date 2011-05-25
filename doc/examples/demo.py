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
import collections
import itertools

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

Segment = collections.namedtuple("Segment", "start size")

def iter_group_block_bitmaps(fs):
	""" Generator for the block bitmaps of all groups """

	group = 0
	while group < fs.group_desc_count:
		group_start = fs.group_first_block(group)
		group_end = fs.group_last_block(group)

		bmap = fs.get_block_bitmap_range(group_start, group_end)

		yield bmap
		group += 1

def iter_free_blocks(fs):
	""" Returns an iterator over all free blocks in a filesystem. """

	return itertools.chain.from_iterable(
		itertools.ifilterfalse(b.block_is_used, xrange(b.start, b.end +1))
		for b in iter_group_block_bitmaps(fs))

def find_segments(it):
	""" Finds segments in an iterable. """

	segments = collections.deque()

	try:
		last = first = next(it)
	except StopIteration:
		return segments

	for n in it:
		if n == last + 1:
			last += 1
		else:
			seg = Segment(first, last - first +1)
			segments.append(seg)

			first = last = n

	# Since each segment is added when the next starts,
	# the last segment has to be added explicitly
	segments.append(Segment(first, last - first +1))

	return segments

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

	# Then, read the block bitmap.
	# We have to do this before using bitmaps.
	fs.read_block_bitmap()

	inodes, blocks = count_inodes_blocks(fs)
	print "Seen %d inodes and %d blocks" % (inodes, blocks)

	# Then we generate a list of segments of free blocks.
	# Technically this is a deque of namedtuples, where for each namedtuple t,
	# t.start is the first block of the segment, and t.size is the size of that
	# semgent, so that the segment comprises blocks [t.start, t.start + t.end -1]

	free_seg_list = find_segments(iter_free_blocks(fs))

	# Should match the count in the superblock displayed above in a perfect world.
	print "Total free blocks:", sum(seg.size for seg in free_seg_list)

	fs.close()
