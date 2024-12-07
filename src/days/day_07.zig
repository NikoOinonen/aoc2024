const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var line_iter = std.mem.splitScalar(u8, input, '\n');
    var total_result: u64 = 0;
    while (line_iter.next()) |line| {
        var line_split = std.mem.splitScalar(u8, line, ':');
        const target = try std.fmt.parseInt(u64, line_split.next().?, 10);
        const values = try utils.parseIntArray(u64, allocator, std.mem.trim(u8, line_split.next().?, " "), ' ');
        defer values.deinit();

        var results = std.ArrayList(u64).init(allocator);
        defer results.deinit();
        var new_results = std.ArrayList(u64).init(allocator);
        defer new_results.deinit();

        var values_left = values.items[1..];
        try results.append(values.items[0]);
        while (values_left.len > 0) {
            new_results.clearRetainingCapacity();
            const next_value = values_left[0];
            values_left = values_left[1..];
            outer: for (results.items) |prev_value| {
                const result_values: [2]u64 = .{
                    prev_value + next_value,
                    prev_value * next_value,
                };
                for (result_values) |val| {
                    if (values_left.len == 0) {
                        if (val == target) {
                            total_result += target;
                            break :outer;
                        }
                    } else if (val <= target) {
                        try new_results.append(val);
                    }
                }
            }
            const temp = results;
            results = new_results;
            new_results = temp;
        }
    }
    return total_result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var line_iter = std.mem.splitScalar(u8, input, '\n');
    var total_result: u64 = 0;
    while (line_iter.next()) |line| {
        var line_split = std.mem.splitScalar(u8, line, ':');
        const target = try std.fmt.parseInt(u64, line_split.next().?, 10);
        const values = try utils.parseIntArray(u64, allocator, std.mem.trim(u8, line_split.next().?, " "), ' ');
        defer values.deinit();

        var results = std.ArrayList(u64).init(allocator);
        defer results.deinit();
        var new_results = std.ArrayList(u64).init(allocator);
        defer new_results.deinit();

        var values_left = values.items[1..];
        try results.append(values.items[0]);
        while (values_left.len > 0) {
            new_results.clearRetainingCapacity();
            const next_value = values_left[0];
            values_left = values_left[1..];
            outer: for (results.items) |prev_value| {
                const result_values: [3]u64 = .{
                    prev_value + next_value,
                    prev_value * next_value,
                    std.math.pow(u64, 10, std.math.log10(next_value) + 1) * prev_value + next_value,
                };
                for (result_values) |val| {
                    if (values_left.len == 0) {
                        if (val == target) {
                            total_result += target;
                            break :outer;
                        }
                    } else if (val <= target) {
                        try new_results.append(val);
                    }
                }
            }
            const temp = results;
            results = new_results;
            new_results = temp;
        }
    }
    return total_result;
}

const test_input =
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
;

test "day07_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(3749, answer);
}

test "day07_part2" {
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(11387, answer);
}
