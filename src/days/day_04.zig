const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

const Position = struct { i: i32, j: i32 };

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const table = try utils.Matrix(u8).initFromString(allocator, input);
    defer table.deinit();

    var num_xmas: u32 = 0;
    for (0..table.n_rows) |i| {
        for (0..table.n_cols) |j| {
            if (table.get(i, j) != 'X') {
                continue;
            }
            var neighbours: []const Position = &.{
                .{ .i = -1, .j = 0 },
                .{ .i = 0, .j = -1 },
                .{ .i = 1, .j = 0 },
                .{ .i = 0, .j = 1 },
                .{ .i = -1, .j = -1 },
                .{ .i = 1, .j = -1 },
                .{ .i = -1, .j = 1 },
                .{ .i = 1, .j = 1 },
            };
            var ind: usize = 1;
            while (neighbours.len > 0 and ind < 4) {
                var new_neighbours = std.ArrayList(Position).init(allocator);
                defer new_neighbours.deinit();
                for (neighbours) |offset| {
                    const i_new: i32 = @as(i32, @intCast(i)) + @as(i32, @intCast(ind)) * offset.i;
                    const j_new: i32 = @as(i32, @intCast(j)) + @as(i32, @intCast(ind)) * offset.j;
                    if (i_new < 0 or i_new >= table.n_rows or j_new < 0 or j_new >= table.n_cols) {
                        continue;
                    }
                    if (table.get(@as(usize, @intCast(i_new)), @as(usize, @intCast(j_new))) == "XMAS"[ind]) {
                        try new_neighbours.append(offset);
                    }
                }
                if (ind > 1) {
                    allocator.free(neighbours);
                }
                neighbours = try new_neighbours.toOwnedSlice();
                ind += 1;
            }
            num_xmas += @truncate(neighbours.len);
            allocator.free(neighbours);
        }
    }

    return num_xmas;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const table = try utils.Matrix(u8).initFromString(allocator, input);
    defer table.deinit();

    var mas_list = std.ArrayList(Position).init(allocator);
    defer mas_list.deinit();
    for (0..table.n_rows) |i| {
        for (0..table.n_cols) |j| {
            if (table.get(i, j) != 'M') {
                continue;
            }
            var neighbours: []const Position = &.{
                .{ .i = -1, .j = -1 },
                .{ .i = 1, .j = -1 },
                .{ .i = -1, .j = 1 },
                .{ .i = 1, .j = 1 },
            };
            var ind: usize = 1;
            while (neighbours.len > 0 and ind < 3) {
                var new_neighbours = std.ArrayList(Position).init(allocator);
                defer new_neighbours.deinit();
                for (neighbours) |offset| {
                    const i_new: i32 = @as(i32, @intCast(i)) + @as(i32, @intCast(ind)) * offset.i;
                    const j_new: i32 = @as(i32, @intCast(j)) + @as(i32, @intCast(ind)) * offset.j;
                    if (i_new < 0 or i_new >= table.n_rows or j_new < 0 or j_new >= table.n_cols) {
                        continue;
                    }
                    if (table.get(@as(usize, @intCast(i_new)), @as(usize, @intCast(j_new))) == "MAS"[ind]) {
                        try new_neighbours.append(offset);
                    }
                }
                if (ind > 1) {
                    allocator.free(neighbours);
                }
                neighbours = try new_neighbours.toOwnedSlice();
                ind += 1;
            }
            for (neighbours) |offset| {
                const i_middle: usize = @intCast(@as(i32, @intCast(i)) + offset.i);
                const j_middle: usize = @intCast(@as(i32, @intCast(j)) + offset.j);
                try mas_list.append(.{ .i = @intCast(@as(i32, @intCast(i_middle))), .j = @intCast(@as(i32, @intCast(j_middle))) });
            }
            allocator.free(neighbours);
        }
    }

    var num_xmas: u32 = 0;
    for (0..mas_list.items.len - 1) |i| {
        for (i + 1..mas_list.items.len) |j| {
            const mas1 = mas_list.items[i];
            const mas2 = mas_list.items[j];
            if (mas1.i == mas2.i and mas1.j == mas2.j) {
                num_xmas += 1;
            }
        }
    }

    return num_xmas;
}

const test_input =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;

test "day04_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(18, answer);
}

test "day04_part2" {
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(9, answer);
}
