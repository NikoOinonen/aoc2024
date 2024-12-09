const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var disk = std.ArrayList(i32).init(allocator);
    defer disk.deinit();
    for (0..input.len / 2 + 1) |i| {
        const length = input[2 * i] - '0';
        for (0..length) |_| {
            try disk.append(@intCast(i));
        }
        if (i < input.len / 2) {
            const space = input[2 * i + 1] - '0';
            for (0..space) |_| {
                try disk.append(-1);
            }
        }
    }

    var left_ind: usize = 0;
    var right_ind: usize = disk.items.len - 1;
    while (true) {
        while (disk.items[left_ind] >= 0) {
            left_ind += 1;
        }
        while (disk.items[right_ind] < 0) {
            right_ind -= 1;
        }
        if (left_ind >= right_ind) {
            break;
        }
        disk.items[left_ind] = disk.items[right_ind];
        disk.items[right_ind] = -1;
    }

    var checksum: u64 = 0;
    for (disk.items, 0..) |id, pos| {
        if (id < 0) {
            break;
        }
        checksum += @as(u64, @intCast(id)) * @as(u64, @intCast(pos));
    }

    return checksum;
}

const Block = union(enum) {
    file: struct { len: usize, id: usize },
    space: usize,
};

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var disk = std.ArrayList(Block).init(allocator);
    defer disk.deinit();
    for (0..input.len / 2 + 1) |i| {
        const length = input[2 * i] - '0';
        try disk.append(Block{ .file = .{ .len = length, .id = i } });
        if (i < input.len / 2) {
            const space = input[2 * i + 1] - '0';
            if (space >= 0) {
                try disk.append(Block{ .space = space });
            }
        }
    }

    var right_ind: usize = disk.items.len - 1;
    while (true) {
        while (disk.items[right_ind] == .space) {
            right_ind -= 1;
        }
        const file_to_move = disk.items[right_ind];
        for (0..disk.items.len) |left_ind| {
            if (left_ind == right_ind) {
                break;
            }
            switch (disk.items[left_ind]) {
                .file => continue,
                .space => |*space_len| {
                    const file_len = file_to_move.file.len;
                    if (space_len.* >= file_len) {
                        space_len.* = space_len.* - file_len;
                        if (space_len.* == 0) {
                            disk.items[left_ind] = file_to_move;
                            disk.items[right_ind] = Block{ .space = file_len };
                        } else {
                            try disk.insert(left_ind, file_to_move);
                            disk.items[right_ind + 1] = Block{ .space = file_len };
                        }
                        break;
                    }
                },
            }
        }
        if (right_ind > 0) {
            right_ind -= 1;
        } else {
            break;
        }
    }

    var checksum: u64 = 0;
    var pos: u64 = 0;
    for (disk.items) |block| {
        switch (block) {
            .file => |*f| {
                for (0..f.len) |_| {
                    checksum += @as(u64, @intCast(f.*.id)) * pos;
                    pos += 1;
                }
            },
            .space => |s| {
                pos += @as(u64, @intCast(s));
            },
        }
    }
    return checksum;
}

const test_input = "2333133121414131402";

test "day09_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(1928, answer);
}

test "day09_part2" {
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(2858, answer);
}
