const std = @import("std");
const bpt = @import("bplustree").BPlusTree(i32, 4);

pub fn main() !void {
    var tree = bpt.init(&std.heap.page_allocator);
    defer tree.deinit();

    // Insert enough keys to force multiple splits and balancing
    const N = 100;
    var k: i32 = 0;
    while (k < N) : (k += 1) {
        try tree.insert(k, k * 10);
    }

    // Check all keys are present
    k = 0;
    while (k < N) : (k += 1) {
        const v = tree.search(k);
        if (v == null or v.? != k * 10) {
            std.debug.print("Key {d} not found or incorrect value: {any}\n", .{ k, v });
            return error.SelfBalancingFailed;
        }
    }

    // Check that the tree is balanced: all leaves should be at the same depth
    var leaf_depth: ?usize = null;
    if (tree.root) |r| {
        if (!check_depth(r, 1, &leaf_depth)) {
            std.debug.print("Leaves are not at the same depth!\n", .{});
            return error.SelfBalancingFailed;
        }
    }
}

fn check_depth(node: *bpt.Node, depth: usize, leaf_depth: *?usize) bool {
    if (node.is_leaf) {
        if (leaf_depth.* == null) {
            leaf_depth.* = depth;
        } else if (leaf_depth.*.? != depth) {
            return false;
        }
        return true;
    }
    var i: usize = 0;
    while (i <= node.n) : (i += 1) {
        if (!check_depth(node.children[i], depth + 1, leaf_depth)) return false;
    }
    return true;
}
