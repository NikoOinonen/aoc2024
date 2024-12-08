const std = @import("std");
const utils = @import("../utils.zig");

const Coordinate = utils.Point(i32);
const CoordinateSet = std.AutoHashMap(Coordinate, void);
const CoordinateList = std.ArrayList(Coordinate);

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const map = try utils.Matrix(u8).initFromString(arena_allocator, input);

    var antennas = std.AutoHashMap(u8, *CoordinateList).init(arena_allocator);
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            const freq = map.get(i, j);
            const coord = Coordinate{ .x = @as(i32, @intCast(j)), .y = @as(i32, @intCast(i)) };
            if (freq != '.') {
                if (antennas.contains(freq)) {
                    var coord_list = antennas.get(freq).?;
                    try coord_list.append(coord);
                } else {
                    var coord_list = try arena_allocator.create(CoordinateList);
                    coord_list.* = CoordinateList.init(arena_allocator);
                    try coord_list.append(coord);
                    try antennas.put(freq, coord_list);
                }
            }
        }
    }

    var freq_iter = antennas.keyIterator();
    var antinode_coords = CoordinateSet.init(arena_allocator);
    while (freq_iter.next()) |freq| {
        const coords = antennas.get(freq.*).?.*;
        // std.debug.print("freq {c}\n", .{freq.*});
        for (0..coords.items.len - 1) |ind1| {
            for (ind1 + 1..coords.items.len) |ind2| {
                const coord1 = coords.items[ind1];
                const coord2 = coords.items[ind2];
                const delta_x: i32 = coord2.x - coord1.x;
                const delta_y: i32 = coord2.y - coord1.y;
                const antinodes = .{
                    Coordinate{ .x = coord2.x + delta_x, .y = coord2.y + delta_y },
                    Coordinate{ .x = coord1.x - delta_x, .y = coord1.y - delta_y },
                };
                // std.debug.print("{any} {any} {d} {d}\n", .{ coord1, coord2, delta_x, delta_y });
                inline for (antinodes) |antinode| {
                    if (antinode.x >= 0 and antinode.x < map.n_cols and antinode.y >= 0 and antinode.y < map.n_rows) {
                        // std.debug.print("antinode {d} {d}\n", .{ antinode.x, antinode.y });
                        try antinode_coords.put(antinode, {});
                    }
                }
            }
        }
    }

    return antinode_coords.count();
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const map = try utils.Matrix(u8).initFromString(arena_allocator, input);

    var antennas = std.AutoHashMap(u8, *CoordinateList).init(arena_allocator);
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            const freq = map.get(i, j);
            const coord = Coordinate{ .x = @as(i32, @intCast(j)), .y = @as(i32, @intCast(i)) };
            if (freq != '.') {
                if (antennas.contains(freq)) {
                    var coord_list = antennas.get(freq).?;
                    try coord_list.append(coord);
                } else {
                    var coord_list = try arena_allocator.create(CoordinateList);
                    coord_list.* = CoordinateList.init(arena_allocator);
                    try coord_list.append(coord);
                    try antennas.put(freq, coord_list);
                }
            }
        }
    }

    var freq_iter = antennas.keyIterator();
    var antinode_coords = CoordinateSet.init(arena_allocator);
    while (freq_iter.next()) |freq| {
        const coords = antennas.get(freq.*).?.*;
        // std.debug.print("freq {c}\n", .{freq.*});
        for (0..coords.items.len - 1) |ind1| {
            for (ind1 + 1..coords.items.len) |ind2| {
                const coord1 = coords.items[ind1];
                const coord2 = coords.items[ind2];
                var delta_x: i32 = coord2.x - coord1.x;
                var delta_y: i32 = coord2.y - coord1.y;
                const gcd: i32 = @intCast(std.math.gcd(@abs(delta_x), @abs(delta_y)));
                delta_x = @divExact(delta_x, gcd);
                delta_y = @divExact(delta_y, gcd);
                var factor: i32 = 0;
                while (true) {
                    const antinode_x = coord1.x + factor * delta_x;
                    const antinode_y = coord1.y + factor * delta_y;
                    if (antinode_x < 0 or antinode_x >= map.n_cols or antinode_y < 0 or antinode_y >= map.n_rows) {
                        break;
                    }
                    const antinode = Coordinate{ .x = antinode_x, .y = antinode_y };
                    try antinode_coords.put(antinode, {});
                    factor += 1;
                }
                factor = -1;
                while (true) {
                    const antinode_x = coord1.x + factor * delta_x;
                    const antinode_y = coord1.y + factor * delta_y;
                    if (antinode_x < 0 or antinode_x >= map.n_cols or antinode_y < 0 or antinode_y >= map.n_rows) {
                        break;
                    }
                    const antinode = Coordinate{ .x = antinode_x, .y = antinode_y };
                    try antinode_coords.put(antinode, {});
                    factor -= 1;
                }
            }
        }
    }

    return antinode_coords.count();
}

const test_input =
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
;

test "day08_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(14, answer);
}

test "day08_part2" {
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(34, answer);
}
