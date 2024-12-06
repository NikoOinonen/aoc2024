const std = @import("std");
const utils = @import("../utils.zig");

const Map = utils.Matrix(u8);
const Direction = utils.Direction;
const Coordinate = utils.Point(usize);
const CoordinateSet = std.AutoHashMap(Coordinate, void);

const Position = struct {
    coord: Coordinate,
    dir: Direction,
};
const PositionSet = std.AutoHashMap(Position, void);

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

fn findLocations(allocator: std.mem.Allocator, map: Map, needle: u8) !CoordinateSet {
    var locations = CoordinateSet.init(allocator);
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            if (map.get(i, j) == needle) {
                try locations.put(.{ .x = j, .y = i }, {});
            }
        }
    }
    return locations;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var map = try Map.initFromString(allocator, input);
    defer map.deinit();

    var obstacles = try findLocations(allocator, map, '#');
    defer obstacles.deinit();

    var guards = try findLocations(allocator, map, '^');
    var iter = guards.keyIterator();
    var guard_location = iter.next().?.*;
    guards.deinit();

    var guard_direction = Direction.up;
    var location_list = CoordinateSet.init(allocator);
    defer location_list.deinit();
    try location_list.put(guard_location, {});
    while (true) {
        const direction_offset = guard_direction.offset();
        const next_x = @as(i32, @intCast(guard_location.x)) + direction_offset.x;
        const next_y = @as(i32, @intCast(guard_location.y)) + direction_offset.y;
        if (next_x < 0 or next_x >= map.n_cols or next_y < 0 or next_y >= map.n_rows) {
            break;
        }
        const next_location = Coordinate{
            .x = @intCast(next_x),
            .y = @intCast(next_y),
        };
        if (obstacles.contains(next_location)) {
            guard_direction = guard_direction.turnRight();
        } else {
            guard_location = next_location;
            try location_list.put(guard_location, {});
        }
    }

    return location_list.count();
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var map = try Map.initFromString(allocator, input);
    defer map.deinit();

    var obstacles_init = try findLocations(allocator, map, '#');
    defer obstacles_init.deinit();

    var guards = try findLocations(allocator, map, '^');
    var iter = guards.keyIterator();
    const guard_init_location = iter.next().?.*;
    guards.deinit();

    var loop_count: u32 = 0;
    for (0..map.n_rows) |i| {
        std.debug.print("{}\n", .{i});
        for (0..map.n_cols) |j| {
            const coord = Coordinate{ .x = j, .y = i };
            if (obstacles_init.contains(coord) or coord.x == guard_init_location.x and coord.y == guard_init_location.y) {
                continue;
            }

            var obstacles = try obstacles_init.clone();
            defer obstacles.deinit();
            try obstacles.put(coord, {});

            var position_list = PositionSet.init(allocator);
            defer position_list.deinit();
            var guard_direction = Direction.up;
            var guard_location = guard_init_location;
            try position_list.put(.{ .coord = guard_location, .dir = guard_direction }, {});
            while (true) {
                const direction_offset = guard_direction.offset();
                const next_x = @as(i32, @intCast(guard_location.x)) + direction_offset.x;
                const next_y = @as(i32, @intCast(guard_location.y)) + direction_offset.y;
                if (next_x < 0 or next_x >= map.n_cols or next_y < 0 or next_y >= map.n_rows) {
                    break;
                }
                const next_location = Coordinate{
                    .x = @intCast(next_x),
                    .y = @intCast(next_y),
                };
                if (obstacles.contains(next_location)) {
                    guard_direction = guard_direction.turnRight();
                } else {
                    guard_location = next_location;
                    const next_position = Position{ .coord = guard_location, .dir = guard_direction };
                    if (position_list.contains(next_position)) {
                        loop_count += 1;
                        break;
                    }
                    try position_list.put(next_position, {});
                }
            }
        }
    }

    return loop_count;
}

const test_input =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;

test "day06_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(41, answer);
}

test "day06_part2" {
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(6, answer);
}
