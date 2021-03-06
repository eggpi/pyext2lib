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

	cdef struct ext2_super_block:
		int s_inodes_count
		int s_blocks_count
		int s_r_blocks_count
		int s_free_blocks_count
		int s_free_inodes_count
		int s_first_data_block
		int s_blocks_per_group

	cdef struct struct_ext2_filsys:
		char *device_name
		ext2_super_block *super
		unsigned int blocksize
		unsigned int group_desc_count
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

	int ext2fs_group_first_block(ext2_filsys fs, int group)
	int ext2fs_group_last_block(ext2_filsys fs, int group)

	int ext2fs_group_of_blk(ext2_filsys fs, int blk)
	int ext2fs_group_of_ino(ext2_filsys fs, int ino)

cdef class ExtFS:
	cdef ext2_filsys fs

	cpdef read_block_bitmap(self)
	cpdef read_inode_bitmap(self)
	cpdef read_bitmaps(self)
	cpdef get_block_bitmap_range(self, start, end)
	cpdef flush(self)
	cpdef close(self)
	cpdef iterinodes(self, flags = ?)
	cpdef read_inode(self, ino)
	cpdef group_first_block(self, group)
	cpdef group_last_block(self, group)
	cpdef group_of_block(self, block)
	cpdef group_of_inode(self, inode)

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
	cdef readonly object start
	cdef readonly object end

	cpdef block_is_used(self, block)
