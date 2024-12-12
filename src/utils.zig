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

pub fn parseIntArray(comptime T: type, allocator: std.mem.Allocator, buf: []const u8, sep: u8) !std.ArrayList(T) {
    var array = std.ArrayList(T).init(allocator);
    errdefer array.deinit();
    var items = std.mem.splitScalar(u8, buf, sep);
    while (items.next()) |item| {
        try array.append(try std.fmt.parseInt(u32, item, 10));
    }
    return array;
}

pub fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        const Self = @This();

        pub fn equal(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y;
        }

        pub fn add(self: Self, other: Self) Self {
            return Self{ .x = self.x + other.x, .y = self.y + other.y };
        }

        pub fn isWithin(self: Self, min: Self, max: Self) bool {
            return self.x >= min.x and self.x <= max.x and self.y >= min.y and self.y <= max.y;
        }
    };
}

pub const Direction = enum {
    up,
    down,
    left,
    right,

    const Self = @This();

    pub fn offset(self: Self) Point(i32) {
        return switch (self) {
            Direction.up => .{ .x = 0, .y = -1 },
            Direction.down => .{ .x = 0, .y = 1 },
            Direction.left => .{ .x = -1, .y = 0 },
            Direction.right => .{ .x = 1, .y = 0 },
        };
    }

    pub fn turnRight(self: Self) Self {
        return switch (self) {
            Direction.up => Direction.right,
            Direction.right => Direction.down,
            Direction.down => Direction.left,
            Direction.left => Direction.up,
        };
    }

    pub fn turnLeft(self: Self) Self {
        return switch (self) {
            Direction.up => Direction.left,
            Direction.left => Direction.down,
            Direction.down => Direction.right,
            Direction.right => Direction.up,
        };
    }
};

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
            errdefer items.deinit();
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

pub fn ArrayLinkedList(comptime T: type) type {
    return struct {
        _head: ?usize = null,
        node_array: std.ArrayList(Node),
        allocator: Allocator,

        const Node = struct {
            data: T,
            _next: ?usize = null,
        };

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            const node_array = std.ArrayList(Node).init(allocator);
            return .{ .node_array = node_array, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.node_array.deinit();
            self._head = null;
        }

        pub fn head(self: Self) ?*Node {
            if (self._head) |h| {
                return &self.node_array.items[h];
            } else {
                return null;
            }
        }

        pub fn next(self: Self, node: *Node) ?*Node {
            if (node._next) |n| {
                return &self.node_array.items[n];
            } else {
                return null;
            }
        }

        pub fn prepend(self: *Self, data: T) !*Node {
            var new_node = Node{ .data = data, ._next = self._head };
            self._head = self.node_array.items.len;
            try self.node_array.append(new_node);
            return &new_node;
        }

        pub fn insertAfter(self: *Self, node: *Node, data: T) !*Node {
            var new_node = Node{ .data = data, ._next = node._next };
            node._next = self.node_array.items.len;
            try self.node_array.append(new_node);
            return &new_node;
        }

        pub fn debugPrintData(self: Self) !void {
            var node = self.head();
            while (node) |n| {
                try std.fmt.formatInt(n.data, 10, std.fmt.Case.lower, .{}, stderr);
                _ = try stderr.write(" ");
                node = n.next();
            }
            _ = try stderr.write("\n");
        }

        pub fn len(self: Self) usize {
            return self.node_array.items.len;
        }
    };
}
