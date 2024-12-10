const std = @import("std");
const utils = @import("../utils.zig");

const Coordinate = utils.Point(i32);
const CoordinateList = std.ArrayList(Coordinate);
const CoordinateSet = std.AutoHashMap(Coordinate, void);

const Direction = utils.Direction;
const directions = &.{ Direction.up, Direction.right, Direction.down, Direction.left };

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

fn searchTrail(allocator: std.mem.Allocator, map: utils.Matrix(u8), start: Coordinate) !u32 {
    var visited = CoordinateSet.init(allocator);
    defer visited.deinit();

    var stack = CoordinateList.init(allocator);
    defer stack.deinit();
    try stack.append(start);

    var score: u32 = 0;
    const min_coord = Coordinate{ .x = 0, .y = 0 };
    const max_coord = Coordinate{ .x = @intCast(map.n_cols - 1), .y = @intCast(map.n_rows - 1) };

    while (stack.popOrNull()) |coord| {
        if (visited.contains(coord)) {
            continue;
        }
        try visited.put(coord, {});
        const current_height = map.get(@intCast(coord.y), @intCast(coord.x));
        if (current_height == '9') {
            score += 1;
            continue;
        }
        inline for (directions) |dir| {
            const offset = dir.offset();
            const next_coord = coord.add(offset);
            if (next_coord.isWithin(min_coord, max_coord)) {
                const next_height = map.get(@intCast(next_coord.y), @intCast(next_coord.x));
                const height_offset = @as(i32, @intCast(next_height)) - @as(i32, @intCast(current_height));
                if (height_offset == 1) {
                    try stack.append(next_coord);
                }
            }
        }
    }

    return score;
}

fn searchTrail2(allocator: std.mem.Allocator, map: utils.Matrix(u8), start: Coordinate) !u32 {
    var stack = CoordinateList.init(allocator);
    defer stack.deinit();
    try stack.append(start);

    var score: u32 = 0;
    const min_coord = Coordinate{ .x = 0, .y = 0 };
    const max_coord = Coordinate{ .x = @intCast(map.n_cols - 1), .y = @intCast(map.n_rows - 1) };

    while (stack.popOrNull()) |coord| {
        const current_height = map.get(@intCast(coord.y), @intCast(coord.x));
        if (current_height == '9') {
            score += 1;
            continue;
        }
        inline for (directions) |dir| {
            const offset = dir.offset();
            const next_coord = coord.add(offset);
            if (next_coord.isWithin(min_coord, max_coord)) {
                const next_height = map.get(@intCast(next_coord.y), @intCast(next_coord.x));
                const height_offset = @as(i32, @intCast(next_height)) - @as(i32, @intCast(current_height));
                if (height_offset == 1) {
                    try stack.append(next_coord);
                }
            }
        }
    }

    return score;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const map = try utils.Matrix(u8).initFromString(allocator, input);
    defer map.deinit();

    var total_score: u32 = 0;
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            if (map.get(i, j) == '0') {
                const start = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
                const score = try searchTrail(allocator, map, start);
                total_score += score;
            }
        }
    }

    return total_score;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const map = try utils.Matrix(u8).initFromString(allocator, input);
    defer map.deinit();

    var total_score: u32 = 0;
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            if (map.get(i, j) == '0') {
                const start = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
                const score = try searchTrail2(allocator, map, start);
                total_score += score;
            }
        }
    }

    return total_score;
}

const test_input =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
;

test "day10_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(36, answer);
}

test "day10_part2" {
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(81, answer);
}
