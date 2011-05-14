from libc.stdlib cimport *
from pyext2lib cimport *

include "pyext2lib.pxi"

class ExtException(Exception):
	pass

cpdef open(name, iomanager, flags = 0, superblock = 0, block_size = 0):
	cdef ext2_filsys fs
	cdef io_manager iom

	if iomanager == IO_MANAGER_UNIX:
		iom = unix_io_manager
	else:
		# TODO - Fill in other io managers
		raise ExtException("Unrecognized IO manager!")

	if ext2fs_open(name, flags, superblock, block_size, iom, &fs):
		raise ExtException("Can't open filesystem! Are you root?")

	filesystem = ExtFS()
	filesystem.fs = fs

	return filesystem

cdef class ExtFS:
	def __dealloc__(self):
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

	cpdef flush(self):
		if ext2fs_flush(self.fs):
			raise ExtException("Can't flush filesystem!")

	cpdef close(self):
		if ext2fs_close(self.fs):
			raise ExtException("Can't close filesystem!")

	cpdef iterinodes(self, flags = 0):
		return ExtFSInodeIter(self, flags)

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
		ret = ExtInode()

		if ext2fs_get_next_inode(self.scan, &ret.number, &ret.inode):
			raise ExtException("Can't get next inode!")

		if ret.number == 0:
			raise StopIteration

		return ret

cdef class ExtInode:
	pass
