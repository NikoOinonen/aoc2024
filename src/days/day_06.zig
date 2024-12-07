const std = @import("std");
const utils = @import("../utils.zig");

const Map = utils.Matrix(u8);
const Direction = utils.Direction;
const Coordinate = utils.Point(i32);
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
    errdefer locations.deinit();
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            if (map.get(i, j) == needle) {
                try locations.put(.{ .x = @intCast(j), .y = @intCast(i) }, {});
            }
        }
    }
    return locations;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const map = try Map.initFromString(arena_allocator, input);
    var obstacles = try findLocations(arena_allocator, map, '#');

    var guards = try findLocations(arena_allocator, map, '^');
    var iter = guards.keyIterator();
    var guard_location = iter.next().?.*;

    var guard_direction = Direction.up;
    var location_list = CoordinateSet.init(arena_allocator);
    defer location_list.deinit();
    try location_list.put(guard_location, {});
    while (true) {
        const direction_offset = guard_direction.offset();
        const next_x = guard_location.x + direction_offset.x;
        const next_y = guard_location.y + direction_offset.y;
        if (next_x < 0 or next_x >= map.n_cols or next_y < 0 or next_y >= map.n_rows) {
            break;
        }
        const next_location = Coordinate{
            .x = next_x,
            .y = next_y,
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
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const map = try Map.initFromString(arena_allocator, input);
    var obstacles = try findLocations(arena_allocator, map, '#');

    var guards = try findLocations(arena_allocator, map, '^');
    var iter = guards.keyIterator();
    var guard_location = iter.next().?.*;

    var loop_count: u32 = 0;
    var position_list = PositionSet.init(arena_allocator);
    var position_list2 = PositionSet.init(arena_allocator);
    var location_list = CoordinateSet.init(arena_allocator);
    var guard_direction = Direction.up;
    try position_list.put(.{ .coord = guard_location, .dir = guard_direction }, {});
    try location_list.put(guard_location, {});
    while (true) {
        const direction_offset = guard_direction.offset();
        const next_location = Coordinate{
            .x = guard_location.x + direction_offset.x,
            .y = guard_location.y + direction_offset.y,
        };
        if (next_location.x < 0 or next_location.x >= map.n_cols or next_location.y < 0 or next_location.y >= map.n_rows) {
            break;
        }

        if (!location_list.contains(next_location) and !obstacles.contains(next_location)) {
            position_list2.clearRetainingCapacity();
            var guard_location2 = guard_location;
            var guard_direction2 = guard_direction;

            while (true) {
                const direction_offset2 = guard_direction2.offset();
                const next_location2 = Coordinate{
                    .x = guard_location2.x + direction_offset2.x,
                    .y = guard_location2.y + direction_offset2.y,
                };
                if (next_location2.x < 0 or next_location2.x >= map.n_cols or next_location2.y < 0 or next_location2.y >= map.n_rows) {
                    break;
                }
                if (obstacles.contains(next_location2) or next_location.equal(next_location2)) {
                    guard_direction2 = guard_direction2.turnRight();
                } else {
                    guard_location2 = next_location2;
                    const next_position = Position{ .coord = guard_location2, .dir = guard_direction2 };
                    if (position_list.contains(next_position) or position_list2.contains(next_position)) {
                        loop_count += 1;
                        break;
                    }
                    try position_list2.put(next_position, {});
                }
            }
        }

        if (obstacles.contains(next_location)) {
            guard_direction = guard_direction.turnRight();
        } else {
            guard_location = next_location;
            const next_position = Position{ .coord = guard_location, .dir = guard_direction };
            try position_list.put(next_position, {});
            try location_list.put(next_location, {});
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
