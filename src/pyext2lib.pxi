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

# FLAGS AND CONSTANTS

# Flags for iterating through the inodes
EXT2_SF_CHK_BADBLOCKS = 0x0001
EXT2_SF_BAD_INODE_BLK = 0x0002
EXT2_SF_BAD_EXTRA_BYTES = 0x0004
EXT2_SF_SKIP_MISSING_ITABLE = 0x0008
EXT2_SF_DO_LAZY = 0x0010

# IO managers
IO_MANAGER_UNIX = 1

# Flags for open()
EXT2_FLAG_RW = 0x01
EXT2_FLAG_CHANGED = 0x02
EXT2_FLAG_DIRTY = 0x04
EXT2_FLAG_VALID = 0x08
EXT2_FLAG_IB_DIRTY = 0x10
EXT2_FLAG_BB_DIRTY = 0x20
EXT2_FLAG_SWAP_BYTES = 0x40
EXT2_FLAG_SWAP_BYTES_READ = 0x80
EXT2_FLAG_SWAP_BYTES_WRITE = 0x100
EXT2_FLAG_MASTER_SB_ONLY = 0x200
EXT2_FLAG_FORCE = 0x400
EXT2_FLAG_SUPER_ONLY = 0x800
EXT2_FLAG_JOURNAL_DEV_OK = 0x1000
EXT2_FLAG_IMAGE_FILE = 0x2000
EXT2_FLAG_EXCLUSIVE = 0x4000
EXT2_FLAG_SOFTSUPP_FEATURES = 0x8000
EXT2_FLAG_NOFREE_ON_ERROR = 0x10000
EXT2_FLAG_64BITS = 0x20000
EXT2_FLAG_PRINT_PROGRESS = 0x40000
EXT2_FLAG_DIRECT_IO = 0x80000

# Flags for the block iterator
BLOCK_FLAG_APPEND = 1
BLOCK_FLAG_HOLE = 1
BLOCK_FLAG_DEPTH_TRAVERSE = 2
BLOCK_FLAG_DATA_ONLY = 4
BLOCK_FLAG_READ_ONLY = 8

# Return flags for the block iterator functions
BLOCK_CHANGED = 1
BLOCK_ABORT	= 2
BLOCK_ERROR	= 4
BLOCK_SUCCESS = 5

# Magic "block count" return values for the block iterator function.
BLOCK_COUNT_IND = -1
BLOCK_COUNT_DIND = -2
BLOCK_COUNT_TIND = -3
BLOCK_COUNT_TRANSLATOR = -4
