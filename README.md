# Zig B+ Tree

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Zig](https://img.shields.io/badge/zig-0.15%2B-f7a41d?logo=zig)](https://ziglang.org/)
[![Lines of Code](https://tokei.rs/b1/github.com/dayvster/zig-bplus-tree?category=code)](https://github.com/dayvster/zig-bplus-tree)
[![Last Commit](https://img.shields.io/github/last-commit/dayvster/zig-bplus-tree)](https://github.com/dayvster/zig-bplus-tree)
[![Repo Size](https://img.shields.io/github/repo-size/dayvster/zig-bplus-tree)](https://github.com/dayvster/zig-bplus-tree)
[![Issues](https://img.shields.io/github/issues/dayvster/zig-bplus-tree)](https://github.com/dayvster/zig-bplus-tree/issues)

---

A robust, generic, and idiomatic B+ tree implementation in Zig (0.15+). This package is designed for high performance, reliability, and ease of use—perfect for use as a dependency or as a learning resource for advanced data structures in Zig.

---

## What is a B+ Tree?
A B+ tree is a self-balancing tree data structure that maintains sorted data and allows fast insertions, deletions, and lookups. It is widely used in databases and filesystems.

```
Example (order 4):

        [ 10 | 20 ]
       /    |    \
   [1 5 7] [12 15] [22 25 30]
```
- All values are stored in the leaves.
- Internal nodes only store keys for navigation.
- All leaves are linked for fast range/iteration queries.

---

## Features
- **Generic**: Works with any comparable key/value type.
- **Self-balancing**: Maintains optimal height for fast operations.
- **Fast**: O(log n) insert, search, and (future) remove.
- **Range iteration**: (Planned) Efficient in-order traversal.
- **Memory safe**: Uses Zig's allocator model.
- **Tested**: Includes edge cases and stress tests.
- **MIT licensed**: Free for any use.

---

## Installation

### With `zig fetch` (recommended)
Add this repo to your `build.zig.zon` dependencies:
```jsonc
// build.zig.zon
{
    // ...
    .dependencies = .{
        .bplustree = .{
            .url = "https://github.com/dayvster/zig-bplus-tree/archive/refs/heads/main.zip",
        },
    },
}
```
Then in your `build.zig`:
```zig
const bplustree_mod = b.dependency("bplustree", .{}).module("bplustree");
// ...
.imports = &.{ .{ .name = "bplustree", .module = bplustree_mod } },
```
And in your code:
```zig
const BPlusTree = @import("bplustree").BPlusTree(i32, 4);
```

### Manual install
1. Download or clone this repository.
2. Copy `src/bplustree.zig` into your project (e.g. `lib/bplustree.zig`).
3. Import it directly:
```zig
const BPlusTree = @import("lib/bplustree.zig").BPlusTree(i32, 4);
```

---

## Usage Example
```zig
const std = @import("std");
const BPlusTree = @import("bplustree").BPlusTree(i32, 4);

pub fn main() !void {
    var tree = BPlusTree.init(&std.heap.page_allocator);
    defer tree.deinit();
    try tree.insert(42, 100);
    const found = tree.search(42);
    std.debug.print("Found: {any}\n", .{found});
}
```

---

## Examples
See the `examples/` directory for more usage patterns, including:
- Basic usage
- Iteration
- Self-balancing stress test

---

## Tests
Run all tests:
```sh
zig build test
```

---

## Contributing
Pull requests, bug reports, and feature requests are welcome! Please open an issue or PR on GitHub.

---

## Support
If you have questions or need help, open an issue or start a discussion on the repo.

---

## License
MIT. See [LICENSE](./LICENSE).
