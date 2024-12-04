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

pub fn Matrix(comptime T: type) type {
    return struct {
        items: []T,
        n_rows: usize,
        n_cols: usize,
        allocator: Allocator,

        const Self = @This();
        const InitError = error{
            UnevenColumns,
        };

        pub fn init(allocator: Allocator, n_rows: usize, n_cols: usize) !Self {
            return .{
                .items = try allocator.alloc(T, n_rows * n_cols),
                .n_rows = n_rows,
                .n_cols = n_cols,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.items);
        }

        pub fn initFromString(allocator: Allocator, string: []const u8) !Self {
            var n_rows: usize = 0;
            var n_cols: usize = 0;
            var items = std.ArrayList(T).init(allocator);
            var line_iter = std.mem.tokenizeScalar(u8, string, '\n');
            while (line_iter.next()) |line| {
                if (line.len > n_cols) {
                    if (n_cols == 0) {
                        n_cols = line.len;
                    } else {
                        return InitError.UnevenColumns;
                    }
                }
                try items.appendSlice(line);
                n_rows += 1;
            }
            return .{
                .items = try items.toOwnedSlice(),
                .n_rows = n_rows,
                .n_cols = n_cols,
                .allocator = allocator,
            };
        }

        pub fn get(self: Self, row: usize, col: usize) T {
            return self.items[row * self.n_cols + col];
        }

        pub fn debugPrint(self: Self) !void {
            for (0..self.n_rows) |i| {
                for (0..self.n_cols) |j| {
                    const value = self.get(i, j);
                    try std.fmt.formatInt(value, 10, std.fmt.Case.lower, .{}, stderr);
                    _ = try stderr.write(" ");
                }
                _ = try stderr.write("\n");
            }
        }
    };
}

test "read_num" {
    const seq = "234sd4";
    try std.testing.expectEqual(.{ 3, 234 }, try read_num(seq));
}
