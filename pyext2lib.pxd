cdef extern from "ext2fs/ext2fs.h":
	cdef struct struct_io_manager:
		pass

	cdef struct ext2_inode:
		pass

	cdef struct ext2_file:
		pass

	cdef struct ext2_struct_inode_scan:
		pass

	cdef struct ext2fs_block_bitmap:
		pass

	cdef struct struct_ext2_filsys:
		char *device_name
		unsigned int blocksize
		ext2fs_block_bitmap block_map

	ctypedef ext2_file *ext2_file_t
	ctypedef struct_ext2_filsys *ext2_filsys
	ctypedef struct_io_manager *io_manager
	ctypedef ext2_struct_inode_scan *ext2_inode_scan

	ctypedef int ext2_ino_t
	ctypedef unsigned int blk_t

	cdef io_manager unix_io_manager

	int ext2fs_open(char *name, int flags, int superblock,
					unsigned int block_size, io_manager manager,
					ext2_filsys *ret_fs)

	int ext2fs_close(ext2_filsys fs)
	int ext2fs_flush(ext2_filsys fs)
	int ext2fs_read_block_bitmap(ext2_filsys fs)
	int ext2fs_read_inode_bitmap(ext2_filsys fs)
	int ext2fs_read_bitmaps(ext2_filsys fs)

	int ext2fs_read_inode(ext2_filsys fs, ext2_ino_t ino, ext2_inode *inode)

	int ext2fs_open_inode_scan(ext2_filsys fs, int buffer_blocks,
									ext2_inode_scan *ret_scan)
	int ext2fs_get_next_inode(ext2_inode_scan scan, ext2_ino_t *ino,
							ext2_inode *inode)
	void ext2fs_close_inode_scan(ext2_inode_scan scan)
	int ext2fs_inode_scan_flags(ext2_inode_scan scan, int set_flags, int
								clear_flags)

	int ext2fs_get_blocks(ext2_filsys fs, ext2_ino_t ino, blk_t *blocks)
	int ext2fs_inode_has_valid_blocks(ext2_inode *inode)
	int ext2fs_check_directory (ext2_filsys fs, ext2_ino_t ino)

	enum:
		EXT2_NDIR_BLOCKS = 12
		EXT2_IND_BLOCK = EXT2_NDIR_BLOCKS
		EXT2_DIND_BLOCK = EXT2_IND_BLOCK + 1
		EXT2_TIND_BLOCK = EXT2_DIND_BLOCK + 1
		EXT2_N_BLOCKS = EXT2_TIND_BLOCK + 1

	int ext2fs_block_iterate (ext2_filsys fs, ext2_ino_t ino, int flags,
							char *block_buf,
							int (*func)(ext2_filsys fs, blk_t *blocknr,
										int blockcnt, void	*private),
							void *private)

	int ext2fs_get_block_bitmap_range(ext2fs_block_bitmap bmap,
									blk_t start, unsigned int num,
									void *out)
	int ext2fs_test_bit(int bit, void *bmap)

cdef class ExtFS:
	# XXX - Can't be instantiated directly as that leaves self.fs as NULL,
	# making all methods segfault. Instantiate only through open() or fix
	# this later.

	cdef ext2_filsys fs

	cpdef read_block_bitmap(self)
	cpdef read_inode_bitmap(self)
	cpdef read_bitmaps(self)
	cpdef get_block_bitmap_range(self, start, end)
	cpdef flush(self)
	cpdef close(self)
	cpdef iterinodes(self, flags = ?)
	cpdef read_inode(self, ino)

cdef class ExtFSInodeIter:
	cdef ExtFS extfs
	cdef ext2_inode_scan scan

cdef class ExtInode:
	cdef ExtFS extfs
	cdef readonly int number
	cdef ext2_inode inode

	cpdef check_directory(self)
	cpdef get_blocks(self)
	cpdef block_iterate(self, func, flags = ?)

cdef class ExtBlockBitmap(dict):
	cdef char *bmap
	cdef ExtFS extfs
	cdef object start
	cdef object end

	cpdef block_is_used(self, block)
