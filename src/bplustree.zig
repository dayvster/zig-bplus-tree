const std = @import("std");

/// Returns a B+ tree node type for the given key/value type and degree.
pub fn Node(comptime T: type, comptime DEGREE: usize) type {
    return struct {
        is_leaf: bool,
        keys: [2 * DEGREE - 1]T,
        children: [2 * DEGREE]*Node(T, DEGREE),
        /// Only used for leaves: stores values for each key.
        values: [2 * DEGREE - 1]?T,
        /// Number of keys in this node.
        n: usize,
        /// For leaf chaining (linked list of leaves).
        next: ?*Node(T, DEGREE),
    };
}

/// Returns a robust, generic B+ tree type for the given key/value type and degree.
/// Usage: var tree = BPlusTree(i32, 4).init(allocator);
pub fn BPlusTree(comptime T: type, comptime DEGREE: usize) type {
    const Allocator = std.mem.Allocator;

    const Error = error{
        OutOfMemory,
        NotFound,
        DuplicateKey,
    };

    const NodePtr = *Node(T, DEGREE);

    const Tree = struct {
        root: ?NodePtr,
        allocator: *const Allocator,

        /// Initialize a new B+ tree with the given allocator.
        pub fn init(allocator: *const Allocator) @This() {
            return @This(){
                .root = null,
                .allocator = allocator,
            };
        }

        /// Free all memory used by the tree and its nodes.
        pub fn deinit(self: *@This()) void {
            if (self.root) |r| {
                self.freeNode(r);
            }
        }
        pub const ErrorSet = Error;

        /// Recursively free a node and its children.
        fn freeNode(self: *@This(), node: NodePtr) void {
            if (!node.is_leaf) {
                for (node.children[0 .. node.n + 1]) |child| {
                    self.freeNode(child);
                }
            }
            self.allocator.destroy(node);
        }

        /// Search for a key in the tree. Returns the value if found, else null.
        pub fn search(self: *@This(), key: T) ?T {
            if (self.root) |r| {
                return self.searchNode(r, key);
            }
            return null;
        }

        /// Internal recursive search helper.
        fn searchNode(self: *@This(), node: NodePtr, key: T) ?T {
            var i: usize = 0;
            while (i < node.n and key > node.keys[i]) : (i += 1) {}
            if (node.is_leaf) {
                if (i < node.n and node.keys[i] == key) {
                    return node.values[i];
                }
                return null;
            } else {
                // For B+ tree: if key == node.keys[i], go right (i+1)
                if (i < node.n and key == node.keys[i]) {
                    return self.searchNode(node.children[i + 1], key);
                } else {
                    return self.searchNode(node.children[i], key);
                }
            }
        }

        /// Insert a key-value pair into the tree. Returns error on duplicate key or OOM.
        pub fn insert(self: *@This(), key: T, value: T) Error!void {
            if (self.root == null) {
                self.root = try self.createNode(true);
                self.root.?.keys[0] = key;
                self.root.?.values[0] = value;
                self.root.?.n = 1;
                return;
            }
            if (self.root.?.n == 2 * DEGREE - 1) {
                var s = try self.createNode(false);
                s.children[0] = self.root.?;
                try self.splitChild(s, 0, self.root.?);
                self.root = s;
            }
            try self.insertNonFull(self.root.?, key, value);
        }

        /// Insert a key-value pair into a node that is not full.
        fn insertNonFull(self: *@This(), node: NodePtr, key: T, value: T) Error!void {
            var i = node.n;
            if (node.is_leaf) {
                while (i > 0 and key < node.keys[i - 1]) : (i -= 1) {
                    node.keys[i] = node.keys[i - 1];
                    node.values[i] = node.values[i - 1];
                }
                if (i > 0 and node.keys[i - 1] == key) return Error.DuplicateKey;
                node.keys[i] = key;
                node.values[i] = value;
                node.n += 1;
            } else {
                while (i > 0 and key < node.keys[i - 1]) : (i -= 1) {}
                if (node.children[i].n == 2 * DEGREE - 1) {
                    try self.splitChild(node, i, node.children[i]);
                    // For B+ tree: if key >= promoted key, go right
                    if (key >= node.keys[i]) i += 1;
                }
                try self.insertNonFull(node.children[i], key, value);
            }
        }

        /// Split a full child node and update the parent.
        /// Parent must never be a leaf in a B+ tree.
        fn splitChild(self: *@This(), parent: NodePtr, i: usize, y: NodePtr) Error!void {
            std.debug.assert(!parent.is_leaf);
            var z = try self.createNode(y.is_leaf);
            var j: usize = 0;
            if (y.is_leaf) {
                // Move upper half of keys/values to new right node (z)
                z.n = DEGREE;
                while (j < DEGREE) : (j += 1) {
                    z.keys[j] = y.keys[j + DEGREE - 1];
                    z.values[j] = y.values[j + DEGREE - 1];
                }
                // Adjust left node (y) to keep only first DEGREE-1 keys/values
                y.n = DEGREE - 1;
                // Shift parent's children and keys to make room
                j = parent.n;
                while (j > i) : (j -= 1) {
                    parent.children[j + 1] = parent.children[j];
                    parent.keys[j] = parent.keys[j - 1];
                }
                parent.children[i + 1] = z;
                // Promote first key of new right node (z) to parent
                parent.keys[i] = z.keys[0];
                parent.n += 1;
                // Link leaves
                z.next = y.next;
                y.next = z;
            } else {
                // Internal node split: move upper half of keys/children to z
                z.n = DEGREE - 1;
                while (j < DEGREE - 1) : (j += 1) {
                    z.keys[j] = y.keys[j + DEGREE];
                }
                j = 0;
                while (j < DEGREE) : (j += 1) {
                    z.children[j] = y.children[j + DEGREE];
                }
                y.n = DEGREE - 1;
                // Shift parent's children and keys to make room
                j = parent.n;
                while (j > i) : (j -= 1) {
                    parent.children[j + 1] = parent.children[j];
                    parent.keys[j] = parent.keys[j - 1];
                }
                parent.children[i + 1] = z;
                // Promote middle key to parent
                parent.keys[i] = y.keys[DEGREE - 1];
                parent.n += 1;
            }
        }

        /// Allocate and initialize a new node (leaf or internal).
        fn createNode(self: *@This(), is_leaf: bool) !NodePtr {
            const node = try self.allocator.create(Node(T, DEGREE));
            node.* = Node(T, DEGREE){
                .is_leaf = is_leaf,
                .keys = undefined,
                .children = undefined,
                .values = undefined,
                .n = 0,
                .next = null,
            };
            return node;
        }

        // TODO: Implement remove, iter, and more robust error handling.
    };

    return Tree;
}
