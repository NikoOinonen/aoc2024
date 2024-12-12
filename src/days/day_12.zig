const std = @import("std");
const utils = @import("../utils.zig");

const Coordinate = utils.Point(i32);
const CoordinateSet = std.AutoHashMap(Coordinate, void);

const Direction = utils.Direction;
const directions = &.{ Direction.up, Direction.right, Direction.down, Direction.left };

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

fn searchRegion(allocator: std.mem.Allocator, map: utils.Matrix(u8), start: Coordinate, visited: *CoordinateSet) !u32 {
    var stack = std.ArrayList(Coordinate).init(allocator);
    defer stack.deinit();
    try stack.append(start);

    const min_coord = Coordinate{ .x = 0, .y = 0 };
    const max_coord = Coordinate{ .x = @intCast(map.n_cols - 1), .y = @intCast(map.n_rows - 1) };

    var region_size: u32 = 0;
    var perimeter: u32 = 0;

    const region_type = map.get(@intCast(start.y), @intCast(start.x));

    while (stack.popOrNull()) |coord| {
        if (visited.contains(coord)) {
            continue;
        }
        try visited.put(coord, {});
        region_size += 1;
        inline for (directions) |dir| {
            const offset = dir.offset();
            const next_coord = coord.add(offset);
            if (next_coord.isWithin(min_coord, max_coord)) {
                const next_region_type = map.get(@intCast(next_coord.y), @intCast(next_coord.x));
                if (next_region_type == region_type) {
                    if (!visited.contains(next_coord)) {
                        try stack.append(next_coord);
                    }
                } else {
                    perimeter += 1;
                }
            } else {
                perimeter += 1;
            }
        }
    }

    return region_size * perimeter;
}

const Fence = struct {
    coord: Coordinate,
    dir: Direction,
};
const FenceSet = std.AutoHashMap(Fence, void);

fn searchRegion2(allocator: std.mem.Allocator, map: utils.Matrix(u8), start: Coordinate, visited: *CoordinateSet) !u32 {
    var stack = std.ArrayList(Coordinate).init(allocator);
    defer stack.deinit();
    try stack.append(start);

    const min_coord = Coordinate{ .x = 0, .y = 0 };
    const max_coord = Coordinate{ .x = @intCast(map.n_cols - 1), .y = @intCast(map.n_rows - 1) };

    var region_size: u32 = 0;

    const region_type = map.get(@intCast(start.y), @intCast(start.x));
    var region = CoordinateSet.init(allocator);
    defer region.deinit();

    var fences = FenceSet.init(allocator);
    defer fences.deinit();

    while (stack.popOrNull()) |coord| {
        if (region.contains(coord)) {
            continue;
        }
        try region.put(coord, {});
        region_size += 1;
        inline for (directions) |dir| {
            const offset = dir.offset();
            const next_coord = coord.add(offset);
            if (next_coord.isWithin(min_coord, max_coord)) {
                const next_region_type = map.get(@intCast(next_coord.y), @intCast(next_coord.x));
                if (next_region_type == region_type) {
                    if (!region.contains(next_coord)) {
                        try stack.append(next_coord);
                    }
                } else {
                    try fences.put(.{ .coord = coord, .dir = dir }, {});
                }
            } else {
                try fences.put(.{ .coord = coord, .dir = dir }, {});
            }
        }
    }

    var region_iter = region.keyIterator();
    while (region_iter.next()) |r| {
        try visited.put(r.*, {});
    }

    var fence_visited = FenceSet.init(allocator);
    defer fence_visited.deinit();

    var num_sides: u32 = 0;
    while (true) {
        var fence_iter = fences.keyIterator();
        var fence_start: ?Fence = null;
        while (fence_iter.next()) |fence| {
            if (!fence_visited.contains(fence.*)) {
                fence_start = fence.*;
                break;
            }
        }

        if (fence_start == null) {
            break;
        }

        var fence_stack = std.ArrayList(Fence).init(allocator);
        defer fence_stack.deinit();
        try fence_stack.append(fence_start.?);

        var iter: usize = 0;
        while (fence_stack.popOrNull()) |fence| {
            iter += 1;
            if (iter == 3) {
                _ = fence_visited.remove(fence_start.?);
            }
            if (fence_visited.contains(fence)) {
                continue;
            }
            try fence_visited.put(fence, {});

            const right_dir = fence.dir.turnRight();
            const left_dir = fence.dir.turnLeft();
            const right_coord = fence.coord.add(right_dir.offset());
            const left_coord = fence.coord.add(left_dir.offset());
            const next_fences: [6]?Fence = .{
                Fence{ .coord = right_coord, .dir = fence.dir },
                Fence{ .coord = left_coord, .dir = fence.dir },
                Fence{ .coord = fence.coord, .dir = right_dir },
                Fence{ .coord = fence.coord, .dir = left_dir },
                if (region.contains(right_coord)) Fence{ .coord = right_coord.add(fence.dir.offset()), .dir = left_dir } else null,
                if (region.contains(left_coord)) Fence{ .coord = left_coord.add(fence.dir.offset()), .dir = right_dir } else null,
            };

            inline for (next_fences, 0..) |next_fence, i| {
                if (next_fence != null and fences.contains(next_fence.?) and !fence_visited.contains(next_fence.?)) {
                    if (i >= 2) {
                        num_sides += 1;
                    }
                    try fence_stack.append(next_fence.?);
                    break;
                }
            }
        }
    }

    return region_size * num_sides;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const map = try utils.Matrix(u8).initFromString(allocator, input);
    defer map.deinit();

    var visited = CoordinateSet.init(allocator);
    defer visited.deinit();
    var total_price: u32 = 0;
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            const start = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
            if (!visited.contains(start)) {
                total_price += try searchRegion(allocator, map, start, &visited);
            }
        }
    }

    return total_price;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const map = try utils.Matrix(u8).initFromString(allocator, input);
    defer map.deinit();

    var visited = CoordinateSet.init(allocator);
    defer visited.deinit();
    var total_price: u32 = 0;
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            const start = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
            if (!visited.contains(start)) {
                total_price += try searchRegion2(allocator, map, start, &visited);
            }
        }
    }

    return total_price;
}

const test_input1 =
    \\AAAA
    \\BBCD
    \\BBCC
    \\EEEC
;

const test_input2 =
    \\RRRRIICCFF
    \\RRRRIICCCF
    \\VVRRRCCFFF
    \\VVRCCCJFFF
    \\VVVVCJJCFE
    \\VVIVCCJJEE
    \\VVIIICJJEE
    \\MIIIIIJJEE
    \\MIIISIJEEE
    \\MMMISSJEEE
;

const test_input3 =
    \\EEEEE
    \\EXXXX
    \\EEEEE
    \\EXXXX
    \\EEEEE
;

const test_input4 =
    \\AAAAAA
    \\AAABBA
    \\AAABBA
    \\ABBAAA
    \\ABBAAA
    \\AAAAAA
;

test "day12_part1" {
    try std.testing.expectEqual(140, try part1(test_allocator, test_input1));
    try std.testing.expectEqual(1930, try part1(test_allocator, test_input2));
}

test "day12_part2" {
    try std.testing.expectEqual(80, try part2(test_allocator, test_input1));
    try std.testing.expectEqual(1206, try part2(test_allocator, test_input2));
    try std.testing.expectEqual(236, try part2(test_allocator, test_input3));
    try std.testing.expectEqual(368, try part2(test_allocator, test_input4));
}
