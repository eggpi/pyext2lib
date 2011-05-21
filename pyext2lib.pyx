from math import ceil
from libc.stdlib cimport *

from pyext2lib cimport *
include "pyext2lib.pxi"

class ExtException(Exception):
	pass

cdef class ExtFS:
	def __init__(self, name, iomanager, flags=0, superblock=0, block_size=0):
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
		if ext2fs_read_block_bitmap(self.fs):
			raise ExtException("Can't read block bitmap!")

	cpdef read_inode_bitmap(self):
		if ext2fs_read_inode_bitmap(self.fs):
			raise ExtException("Can't read block bitmap!")

	cpdef read_bitmaps(self):
		if ext2fs_read_bitmaps(self.fs):
			raise ExtException("Can't read bitmaps!")

	cpdef get_block_bitmap_range(self, start, end):
		# TODO - Require reading the block bitmap first
		return ExtBlockBitmap(self, start, end)

	cpdef flush(self):
		if ext2fs_flush(self.fs):
			raise ExtException("Can't flush filesystem!")

	cpdef close(self):
		if self.fs == NULL:
			raise ExtException("Tried to close filesystem that wasn't opened?")

		if ext2fs_close(self.fs):
			raise ExtException("Can't close filesystem!")

		self.fs = NULL

	cpdef iterinodes(self, flags = 0):
		return ExtFSInodeIter(self, flags)

	cpdef read_inode(self, ino):
		return ExtInode(self, ino)

	cpdef group_first_block(self, group):
		return ext2fs_group_first_block(self.fs, group)

	cpdef group_last_block(self, group):
		return ext2fs_group_last_block(self.fs, group)

	cpdef group_of_block(self, block):
		return ext2fs_group_of_blk(self.fs, block)

	cpdef group_of_inode(self, inode):
		return ext2fs_group_of_ino(self.fs, inode)

	property device_name:
		def __get__(self):
			return self.fs.device_name

	property blocksize:
		def __get__(self):
			return self.fs.blocksize

	property group_desc_count:
		def __get__(self):
			return self.fs.group_desc_count

	property s_inodes_count:
		def __get__(self):
			return self.fs.super.s_inodes_count

	property s_blocks_count:
		def __get__(self):
			return self.fs.super.s_blocks_count

	property s_r_blocks_count:
		def __get__(self):
			return self.fs.super.s_r_blocks_count

	property s_free_blocks_count:
		def __get__(self):
			return self.fs.super.s_free_blocks_count

	property s_free_inodes_count:
		def __get__(self):
			return self.fs.super.s_free_inodes_count

	property s_first_data_block:
		def __get__(self):
			return self.fs.super.s_first_data_block

	property s_blocks_per_group:
		def __get__(self):
			return self.fs.super.s_blocks_per_group

cdef class ExtFSInodeIter:
	def __cinit__(self, ExtFS extfs, flags):
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
	def __init__(self, ExtFS extfs, inumber):
		self.extfs = extfs
		self.number = inumber

		if ext2fs_read_inode(self.extfs.fs, inumber, &self.inode):
			raise ExtException("Can't get inode!")

	cpdef check_directory(self):
		return ext2fs_check_directory(self.extfs.fs, self.number) == 0

	cpdef get_blocks(self):
		cdef blk_t blks[EXT2_N_BLOCKS]
		cdef char *name

		if not ext2fs_inode_has_valid_blocks(&self.inode):
			return []

		if ext2fs_get_blocks(self.extfs.fs, self.number, blks):
			raise ExtException("Can't get blocks for inode!")

		blocks = []
		for i from 0 <= i < EXT2_N_BLOCKS:
			# Skip holes (blocks whose number is zero)
			if blks[i]:
				blocks.append(blks[i])

		return blocks

	cpdef block_iterate(self, func, flags = 0):
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
			ret = BLOCK_SUCCESS
		else:
			ret = BLOCK_ABORT
	except Exception as err:
		exc.append(err)
		ret = BLOCK_ERROR

	return ret

cdef class ExtBlockBitmap(dict):
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
		return self[block]
