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

	cpdef flush(self):
		if ext2fs_flush(self.fs):
			raise ExtException("Can't flush filesystem!")

	cpdef close(self):
		if self.fs == NULL:
			raise ExtException("Trying to close filesystem that wasn't opened?")

		if ext2fs_close(self.fs):
			raise ExtException("Can't close filesystem!")

		self.fs = NULL

	cpdef iterinodes(self, flags = 0):
		return ExtFSInodeIter(self, flags)

	cpdef read_inode(self, ino):
		inode = ExtInode(self)

		inode.number = ino
		if ext2fs_read_inode(self.fs, ino, &inode.inode):
			raise ExtException("Can't get inode!")

		return inode

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
		ret = ExtInode(self.extfs)

		if ext2fs_get_next_inode(self.scan, &ret.number, &ret.inode):
			raise ExtException("Can't get next inode!")

		if ret.number == 0:
			raise StopIteration

		return ret

cdef class ExtInode:
	def __cinit__(self, ExtFS extfs):
		self.fs = extfs.fs

	cpdef get_blocks(self):
		cdef blk_t blks[EXT2_N_BLOCKS]
		cdef char *name

		if not ext2fs_inode_has_valid_blocks(&self.inode):
			return []

		if ext2fs_get_blocks(self.fs, self.number, blks):
			raise ExtException("Can't get blocks for inode!")

		blocks = []
		for i from 0 <= i < EXT2_N_BLOCKS:
			# Skip holes (blocks whose number is zero)
			if blks[i]:
				blocks.append(blks[i])

		return blocks

	cpdef block_iterate(self, func, flags = 0):
		# This is a little tricky.
		# We create a context list that will be passed to
		# 'block_iterate_wrapper'.
		# This makes it possible for block_iterate_wrapper to access
		# the user-provided callback function and propagate any exceptions
		# that it raises by appending them to this list.
		context = [func]

		ret = ext2fs_block_iterate(self.fs, self.number, flags, NULL,
									block_iterate_wrapper, <void *>context)

		if len(context) == 2:
			raise context[1]

		return ret == 0

cdef int \
block_iterate_wrapper(ext2_filsys fs, blk_t *blknr, int blkcnt, void *context):
	# XXX Ugly! Should make ExtInodes have a reference to their ExtFS and
	# block_iterate pass this reference to block_iterate_wrapper as part of the
	# context!
	filesystem = ExtFS()
	filesystem.fs = fs

	func = (<object> context)[0]
	try:
		# TODO - Support altering the block and returning BLOCK_CHANGED
		ret = func(filesystem, blknr[0], blkcnt)
		if ret or ret is None:
			ret = BLOCK_SUCCESS
		else:
			ret = BLOCK_ABORT
	except Exception as err:
		(<object> context).append(err)
		ret = BLOCK_ERROR

	# XXX Uglier! Set the dummy filesystem's fs handle to NULL so that its
	# close() method doesn't get called in its __dealloc__.
	filesystem.fs = NULL

	return ret
