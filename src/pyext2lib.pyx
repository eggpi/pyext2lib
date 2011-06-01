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

from math import ceil
from libc.stdlib cimport *

from pyext2lib cimport *
include "pyext2lib.pxi"

"""
pyext2lib: Thin Python bindings over ext2lib.
Currently provides read-only access to a filesystem and its inodes.
"""

class ExtException(Exception):
	""" Custom exception raised when the underlying Ext2lib functions fail. """
	pass

cdef class ExtFS:
	""" Represents an extended filesystem.

	ExtFS(name, iomanager, flags = 0, superblock = 0, block_size = 0)
	Opens a filesystem.

	Parameters:
	name : str, the location of the filesystem
	iomanager : opaque, the I/O manager to use. One of the IO_MANAGER_*
	flags : opaque, optional, an OR of zero or more EXT2_FLAG_*
	superblock : int, optional, address of the superblock to use
	block_size : int, optional, block size to use

	The filesystem can be closed explicitly with the close() method, but it
	will be automatically closed when being deallocated.

	For more information, please see ext2fs_open() in the e2fsprogs
	documentation.
	"""

	def __init__(self, name, iomanager, flags=0, superblock=0, block_size=0):
		""" Please see the class documentation for signature. """

		cdef io_manager iom

		if iomanager == IO_MANAGER_UNIX:
			iom = unix_io_manager
		else:
			# TODO - Fill in other io managers
			raise ExtException("Unrecognized IO manager!")

		if ext2fs_open(name, flags, superblock, block_size, iom, &self.fs):
			raise ExtException("Can't open filesystem! Are you root?")

	def __dealloc__(self):
		if self.fs:
			self.close()

	cpdef read_block_bitmap(self):
		""" Reads the block bitmap for this filesystem.

		For more information, please see ext2fs_read_block_bitmap() in the
		e2fsprogs documentation.
		"""

		if ext2fs_read_block_bitmap(self.fs):
			raise ExtException("Can't read block bitmap!")

	cpdef read_inode_bitmap(self):
		""" Reads the inode bitmap for this filesystem.

		For more information, please see ext2fs_read_inode_bitmap() in the
		e2fsprogs documentation.
		"""

		if ext2fs_read_inode_bitmap(self.fs):
			raise ExtException("Can't read block bitmap!")

	cpdef read_bitmaps(self):
		""" Reads the block and inode bitmap for this filesystem.

		For more information, please see ext2fs_read_bitmaps() in the
		e2fsprogs documentation.
		"""

		if ext2fs_read_bitmaps(self.fs):
			raise ExtException("Can't read bitmaps!")

	cpdef get_block_bitmap_range(self, start, end):
		""" Returns an ExtBlockBitmap representing the block bitmap for a range
		of blocks.

		Parameters:
		start : int, the first block in the range
		end : int, the last block in the range

		This method requires reading the block bitmap first.
		"""

		# TODO - Require reading the block bitmap first
		return ExtBlockBitmap(self, start, end)

	cpdef flush(self):
		""" Flushes this filesystem.

		For more information, please see ex2fs_flush() in the e2fsprogs
		documentation.
		"""

		if ext2fs_flush(self.fs):
			raise ExtException("Can't flush filesystem!")

	cpdef close(self):
		""" Closes this filesystem.

		For more information, please see ex2fs_close() in the e2fsprogs
		documentation.
		"""

		if self.fs == NULL:
			raise ExtException("Tried to close filesystem that wasn't opened?")

		if ext2fs_close(self.fs):
			raise ExtException("Can't close filesystem!")

		self.fs = NULL

	cpdef iterinodes(self, flags = 0):
		""" Returns and ExtFSInodeIter object, an iterator over all inodes in
		this filesystem.

		flags : opaque, optional, an OR of zero or more of the EXT2_SF_*
		"""

		return ExtFSInodeIter(self, flags)

	cpdef read_inode(self, ino):
		""" Returns an ExtInode representing a specific inode.

		Parameters:
		ino : int, the inode
		"""

		return ExtInode(self, ino)

	cpdef group_first_block(self, group):
		""" Returns the number of the first block in a group.

		Parameters:
		group : int, the group
		"""

		return ext2fs_group_first_block(self.fs, group)

	cpdef group_last_block(self, group):
		""" Returns the number of the last block in a group.

		Parameters:
		group : int, the group
		"""

		return ext2fs_group_last_block(self.fs, group)

	cpdef group_of_block(self, block):
		""" Returns the number of the group that contains a given block.

		Parameters:
		block : int, the block
		"""

		return ext2fs_group_of_blk(self.fs, block)

	cpdef group_of_inode(self, inode):
		""" Returns the number of the group that contains a given inode.

		Parameters:
		inode : int, the inode
		"""

		return ext2fs_group_of_ino(self.fs, inode)

	property device_name:
		""" The name of the device that contains this filesystem. """

		def __get__(self):
			return self.fs.device_name

	property blocksize:
		""" The block size used by this filesystem. """

		def __get__(self):
			return self.fs.blocksize

	property group_desc_count:
		""" Number of groups in this filesystem. """

		def __get__(self):
			return self.fs.group_desc_count

	property s_inodes_count:
		""" Total number of inodes in this filesystem. """

		def __get__(self):
			return self.fs.super.s_inodes_count

	property s_blocks_count:
		""" Total number of blocks in this filesystem. """

		def __get__(self):
			return self.fs.super.s_blocks_count

	property s_r_blocks_count:
		""" Number of reserved blocks in this filesystem. """

		def __get__(self):
			return self.fs.super.s_r_blocks_count

	property s_free_blocks_count:
		""" Total number of free blocks in this filesystem. """

		def __get__(self):
			return self.fs.super.s_free_blocks_count

	property s_free_inodes_count:
		""" Total number of free inodes in this filesystem. """

		def __get__(self):
			return self.fs.super.s_free_inodes_count

	property s_first_data_block:
		""" Number of the first data block in this filesystem. """

		def __get__(self):
			return self.fs.super.s_first_data_block

	property s_blocks_per_group:
		""" Number of blocks per group in this filesystem. """

		def __get__(self):
			return self.fs.super.s_blocks_per_group

cdef class ExtFSInodeIter:
	""" Iterator through all inodes in a filesystem.

	ExtFSInodeIter(extfs, flags)
	Initializes the iterator for a filesystem.

	Parameters:
	extfs : ExtFS, the filesystem
	flags : opaque, optional, an OR of zero or more of the EXT2_SF_*
	"""

	def __cinit__(self, ExtFS extfs, flags=0):
		self.extfs = extfs

		if ext2fs_open_inode_scan(extfs.fs, 0, &self.scan):
			raise ExtException("Can't open inode scan!")

		if flags:
			ext2fs_inode_scan_flags(self.scan, flags, 0)

	def __dealloc__(self):
		ext2fs_close_inode_scan(self.scan)

	def __iter__(self):
		return self

	def __next__(self):
		cdef ext2_ino_t inumber
		cdef ext2_inode inode

		if ext2fs_get_next_inode(self.scan, &inumber, &inode):
			raise ExtException("Can't get next inode!")

		if inumber == 0:
			raise StopIteration

		return ExtInode(self.extfs, inumber)

cdef class ExtInode:
	""" Represents an inode in the filesystem.

	ExtInode(extfs, inumber)
	Reads in the inode and initializes the ExtInode instance.

	Parameters:
	extfs : ExtFS, the filesystem that contains this inode
	inumber : int, the inode number

	Attributes:
	number : int, the inode number
	"""

	def __init__(self, ExtFS extfs, inumber):
		""" Please see the class docstring for signature. """

		self.extfs = extfs
		self.number = inumber

		if ext2fs_read_inode(self.extfs.fs, inumber, &self.inode):
			raise ExtException("Can't get inode!")

	cpdef check_directory(self):
		""" Returns True or False whether or not this inode represents a
		directory.

		For more information, please see ext2fs_check_directory() in the
		e2fsprogs documentation.
		"""

		return ext2fs_check_directory(self.extfs.fs, self.number) == 0

	cpdef get_blocks(self):
		""" Returns a list of the blocks directly referenced in this inode.

		For more information, please see ext2fs_get_blocks() in the e2fsprogs
		documentation. """

		cdef blk_t blks[EXT2_N_BLOCKS]
		cdef char *name

		if not ext2fs_inode_has_valid_blocks(&self.inode):
			return []

		if ext2fs_get_blocks(self.extfs.fs, self.number, blks):
			raise ExtException("Can't get blocks for inode!")

		blocks = []
		for i from 0 <= i < EXT2_N_BLOCKS:
			if blks[i]:
				blocks.append(blks[i])

		return blocks

	cpdef block_iterate(self, func, flags = 0):
		""" Iterates through all blocks referenced (directly or indirectly) by
		this inode, calling a user-provided function on each of them.

		Parameters:
		func : callable, with the signature func(extfs, blknr, blkcnt), where:
			extfs : ExtFS, the filesystem that contains the block
			blknr : int, the number of the block
			blkcnt : int, provides additional information about the block

			func must can either return BLOCK_SUCCESS, so that the iteration
			continues, or BLOCK_ERROR, to signal an error, or BLOCK_ABORT, to
			stop the iteration.
			A return value v such that v is None or bool(v) -> True is taken as
			equivalent to BLOCK_SUCCESS.
			A return value v such that bool(v) -> False is taken as equivalent
			to BLOCK_ABORT.

			It is currently not possible to alter the block and return
			BLOCK_CHANGED.

		flags : opaque, optional, an OR of zero or more of the BLOCK_FLAG_*

		For more information, please see ext2fs_block_iterate() in the e2fsprogs
		documentation.
		"""

		# This is a little tricky.
		# We create a context tuple that will be passed to
		# 'block_iterate_wrapper'.
		# This makes it possible for block_iterate_wrapper to access
		# our ExtFS and the user-provided callback function and to
		# propagate any exceptions that it raises by appending them
		# to context[2]
		context = (self.extfs, func, [])

		ret = ext2fs_block_iterate(self.extfs.fs, self.number, flags, NULL,
									block_iterate_wrapper, <void *>context)

		if context[2]:
			raise context[2].pop()

		return ret == 0

cdef int \
block_iterate_wrapper(ext2_filsys fs, blk_t *blknr, int blkcnt, void *context):
	extfs, func, exc = (<object> context)

	try:
		# TODO - Support altering the block and returning BLOCK_CHANGED
		ret = func(extfs, blknr[0], blkcnt)
		if ret or ret is None:
			ret = 0
		else:
			ret = BLOCK_ABORT
	except Exception as err:
		exc.append(err)
		ret = BLOCK_ERROR

	return ret

cdef class ExtBlockBitmap(dict):
	""" Dict-like representation of a block bitmap.
	For any block blk in the bitmap b, b[blk] == True iff blk is in use.

	ExtBlockBitmap(extfs, start, end)
	Initializes a block bitmap. Requires reading the block bitmap in the
	filesystem first.

	Parameters:
	extfs : ExtFS, the filesystem
	start : int, the first block in the bitmap
	end : int, the last block in the bitmap

	Attributes:
	start : int, the first block in the bitmap
	end : int, the last block in the bitmap
	"""

	def __init__(self, ExtFS extfs, start, end):
		dict.__init__(self)

		self.extfs = extfs
		self.start = start
		self.end = end

		self.bmap = <char *> malloc(ceil(end -start +1) / 8)

		if self.bmap == NULL:
			raise RuntimeError("Can't allocate block bitmap!")

		err = ext2fs_get_block_bitmap_range(extfs.fs.block_map,
											start,
											end -start +1,
											self.bmap);
		if err:
			raise ExtException("Can't get block bitmap!")

	def __dealloc__(self):
		free(self.bmap)
		self.bmap = NULL

	def __missing__(self, key):
		if self.start <= key <= self.end:
			status = bool(ext2fs_test_bit(key -self.start, self.bmap))
			self[key] = status

			return status

		raise IndexError("Requested block outside bitmap!")

	cpdef block_is_used(self, block):
		""" Returns True or False whether a given block is in use.

		Parameters:
		block : int, the block
		"""

		return self[block]
