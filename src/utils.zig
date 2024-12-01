const std = @import("std");

pub fn readInput(allocator: std.mem.Allocator, input_file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(input_file_path, .{});
    defer file.close();

    const file_stat = try file.stat();
    const file_contents = try file.readToEndAlloc(allocator, file_stat.size);

    return file_contents;
}
