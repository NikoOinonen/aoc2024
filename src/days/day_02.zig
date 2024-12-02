const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

fn parse_line(allocator: std.mem.Allocator, line: []const u8) ![]const u32 {
    var row_values = std.ArrayList(u32).init(allocator);
    var items_iter = std.mem.tokenizeScalar(u8, line, ' ');
    while (items_iter.next()) |item| {
        const value = try std.fmt.parseInt(u32, item, 10);
        try row_values.append(value);
    }
    return row_values.toOwnedSlice();
}

fn check_row(row_values: []const u32) bool {
    var current_value: ?u32 = null;
    var ascending: ?bool = null;
    for (row_values) |new_value| {
        if (current_value) |v| {
            const abs_diff = if (v > new_value) v - new_value else new_value - v;
            if (abs_diff == 0 or abs_diff > 3) {
                return false;
            }
            if (ascending == null) {
                ascending = new_value > v;
            } else if ((ascending.? and new_value < v) or (!ascending.? and new_value > v)) {
                return false;
            }
        }
        current_value = new_value;
    }
    return true;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var num_safe: u32 = 0;
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const row_values = try parse_line(allocator, line);
        defer allocator.free(row_values);
        if (check_row(row_values)) {
            num_safe += 1;
        }
    }

    return num_safe;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var num_safe: u32 = 0;
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const row_values = try parse_line(allocator, line);
        defer allocator.free(row_values);

        for (0..row_values.len) |i| {
            var temp = std.ArrayList(u32).init(allocator);
            for (row_values, 0..) |v, j| {
                if (i != j) {
                    try temp.append(v);
                }
            }

            const new_array_values = try temp.toOwnedSlice();
            defer allocator.free(new_array_values);
            if (check_row(new_array_values)) {
                num_safe += 1;
                break;
            }
        }
    }
    return num_safe;
}

const test_input =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;

test "day02_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(2, answer);
}

test "day02_part2" {
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(4, answer);
}
