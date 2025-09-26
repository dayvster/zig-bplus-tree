const std = @import("std");
pub fn bufferedPrint() !void {
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try stdout.flush(); // Don't forget to flush!
}

/// B+ Tree API
pub const BPlusTree = @import("bplustree.zig").BPlusTree;

// Example usage:
// const std = @import("std");
// const bpt = @import("root").BPlusTree(i32, 4);
// var tree = bpt.init(std.heap.page_allocator);
// defer tree.deinit();
// try tree.insert(42, 42);
// const found = tree.search(42);
// std.debug.print("Found: {any}\n", .{found});
