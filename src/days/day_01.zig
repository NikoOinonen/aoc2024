const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

pub fn parseLines(allocator: std.mem.Allocator, input: []const u8) !struct { std.ArrayList(u32), std.ArrayList(u32) } {
    var list1 = std.ArrayList(u32).init(allocator);
    var list2 = std.ArrayList(u32).init(allocator);
    errdefer {
        list1.deinit();
        list2.deinit();
    }
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var item_iter = std.mem.tokenizeScalar(u8, line, ' ');
        const num1 = try std.fmt.parseInt(u32, item_iter.next().?, 10);
        const num2 = try std.fmt.parseInt(u32, item_iter.next().?, 10);
        try list1.append(num1);
        try list2.append(num2);
    }
    return .{ list1, list2 };
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var list1, var list2 = try parseLines(allocator, input);
    defer {
        list1.deinit();
        list2.deinit();
    }

    std.mem.sort(u32, list1.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, list2.items, {}, std.sort.asc(u32));

    var sum_of_diffs: u32 = 0;
    for (list1.items, list2.items) |num1, num2| {
        const abs_diff = if (num1 > num2) num1 - num2 else num2 - num1;
        sum_of_diffs += abs_diff;
    }

    return sum_of_diffs;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var list1, var list2 = try parseLines(allocator, input);
    defer {
        list1.deinit();
        list2.deinit();
    }

    var counts = std.AutoHashMap(u32, u32).init(allocator);
    defer counts.deinit();

    for (list2.items) |num| {
        if (counts.get(num)) |v| {
            try counts.put(num, v + 1);
        } else {
            try counts.put(num, 1);
        }
    }

    var sum: u32 = 0;
    for (list1.items) |num| {
        if (counts.get(num)) |v| {
            sum += num * v;
        }
    }

    return sum;
}

test "day01_part1" {
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    try std.testing.expectEqual(11, try part1(test_allocator, input));
}

test "day01_part2" {
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    try std.testing.expectEqual(31, try part2(test_allocator, input));
}
