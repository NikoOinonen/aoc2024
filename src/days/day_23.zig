const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    _ = allocator;
    _ = input;
    return 0;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    _ = allocator;
    _ = input;
    return 0;
}

test "day23_part1" {}

test "day23_part2" {}
