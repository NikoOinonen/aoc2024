const std = @import("std");
const utils = @import("../utils.zig");

const StonesList = utils.ArrayLinkedList(u64);

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const stones_array = try utils.parseIntArray(u64, allocator, input, ' ');
    defer stones_array.deinit();

    var stones = StonesList.init(allocator);
    defer stones.deinit();
    for (0..stones_array.items.len) |i| {
        _ = try stones.prepend(stones_array.items[stones_array.items.len - i - 1]);
    }

    const num_blinks = 25;
    for (0..num_blinks) |_| {
        var current_stone = stones.head().?;
        while (true) {
            const stone_num = current_stone.data;
            if (stone_num == 0) {
                current_stone.data = 1;
            } else {
                const num_digits = std.math.log10(stone_num) + 1;
                if (num_digits % 2 == 0) {
                    const half_pow = std.math.pow(u64, 10, num_digits / 2);
                    const left_num = stone_num / half_pow;
                    const right_num = stone_num % half_pow;
                    current_stone.data = left_num;
                    current_stone = try stones.insertAfter(current_stone, right_num);
                } else {
                    current_stone.data *= 2024;
                }
            }
            current_stone = stones.next(current_stone) orelse break;
        }
    }

    return stones.len();
}

const StoneCounts = std.AutoHashMap(u64, u64);

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const stones_array = try utils.parseIntArray(u64, allocator, input, ' ');
    defer stones_array.deinit();

    var stone_counts = StoneCounts.init(allocator);
    defer stone_counts.deinit();
    for (stones_array.items) |stone| {
        try stone_counts.put(stone, 1);
    }

    const num_blinks = 75;
    for (0..num_blinks) |_| {
        var new_stone_counts = StoneCounts.init(allocator);
        var stone_count_iter = stone_counts.iterator();
        while (stone_count_iter.next()) |entry| {
            const stone_num, const count = .{ entry.key_ptr.*, entry.value_ptr.* };
            if (stone_num == 0) {
                const new_stone_num = 1;
                try new_stone_counts.put(new_stone_num, count + (new_stone_counts.get(new_stone_num) orelse 0));
            } else {
                const num_digits = std.math.log10(stone_num) + 1;
                if (num_digits % 2 == 0) {
                    const half_pow = std.math.pow(u64, 10, num_digits / 2);
                    const left_num = stone_num / half_pow;
                    const right_num = stone_num % half_pow;
                    try new_stone_counts.put(left_num, count + (new_stone_counts.get(left_num) orelse 0));
                    try new_stone_counts.put(right_num, count + (new_stone_counts.get(right_num) orelse 0));
                } else {
                    const new_stone_num = stone_num * 2024;
                    try new_stone_counts.put(new_stone_num, count + (new_stone_counts.get(new_stone_num) orelse 0));
                }
            }
        }
        stone_counts.deinit();
        stone_counts = new_stone_counts;
    }

    var total_count: u64 = 0;
    var stone_count_iter = stone_counts.valueIterator();
    while (stone_count_iter.next()) |count| {
        total_count += count.*;
    }

    return total_count;
}

const test_input = "125 17";

test "day11_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(55312, answer);
}
