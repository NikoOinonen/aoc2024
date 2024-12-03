const std = @import("std");
const Allocator = std.mem.Allocator;

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

pub fn readInput(allocator: std.mem.Allocator, input_file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(input_file_path, .{});
    defer file.close();

    const file_stat = try file.stat();
    const file_contents = try file.readToEndAlloc(allocator, file_stat.size);

    return file_contents;
}

pub fn charIsNumeric(char: u8) bool {
    return char >= 48 and char <= 57;
}

pub fn read_num(seq: []const u8) !struct { usize, ?u32 } {
    if (!charIsNumeric(seq[0])) {
        return .{ 0, null };
    }
    var ind: usize = 1;
    var buf: [100]u8 = undefined;
    buf[0] = seq[0];
    while (ind < seq.len and charIsNumeric(seq[ind])) {
        buf[ind] = seq[ind];
        ind += 1;
    }
    const num = try std.fmt.parseInt(u32, buf[0..ind], 10);
    return .{ ind, num };
}

test "read_num" {
    const seq = "234sd4";
    try std.testing.expectEqual(.{ 3, 234 }, try read_num(seq));
}
