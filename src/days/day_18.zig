const std = @import("std");
const utils = @import("../utils.zig");

const Coordinate = utils.Point(i32);
const CoordinateSet = std.AutoHashMap(Coordinate, void);
const CoordinateDistances = std.AutoHashMap(Coordinate, usize);

const QueueContext = struct {
    distances: CoordinateDistances,
    goal_coord: Coordinate,
};

const Direction = utils.Direction;
const directions = &.{ Direction.up, Direction.right, Direction.down, Direction.left };

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

fn minRemainingDistance(coord: Coordinate, goal: Coordinate) usize {
    return @abs(goal.x - coord.x) + @abs(goal.y - coord.y);
}

fn compareCoordinates(scores: *CoordinateDistances, coord1: Coordinate, coord2: Coordinate) std.math.Order {
    const f1 = scores.get(coord1) orelse std.math.maxInt(usize);
    const f2 = scores.get(coord2) orelse std.math.maxInt(usize);
    return std.math.order(f1, f2);
}

fn searchPath(allocator: std.mem.Allocator, corrupted_coordinates: CoordinateSet, max_coord: Coordinate) !usize {
    const min_coord = Coordinate{ .x = 0, .y = 0 };

    var distances = CoordinateDistances.init(allocator);
    defer distances.deinit();
    try distances.put(min_coord, 0);

    var scores = CoordinateDistances.init(allocator);
    defer scores.deinit();
    try scores.put(min_coord, minRemainingDistance(min_coord, max_coord));

    var queue = std.PriorityQueue(Coordinate, *CoordinateDistances, compareCoordinates).init(allocator, &distances);
    defer queue.deinit();
    try queue.add(min_coord);

    var visited = CoordinateSet.init(allocator);
    defer visited.deinit();

    while (queue.removeOrNull()) |coord| {
        if (coord.equal(max_coord)) {
            return distances.get(max_coord).?;
        }
        inline for (directions) |dir| {
            const next_coord = coord.add(dir.offset());
            if (next_coord.isWithin(min_coord, max_coord) and !corrupted_coordinates.contains(next_coord)) {
                const dist = distances.get(coord).? + 1;
                const prev_dist = distances.get(next_coord) orelse std.math.maxInt(usize);
                if (dist < prev_dist) {
                    try distances.put(next_coord, dist);
                    try scores.put(next_coord, dist + minRemainingDistance(next_coord, max_coord));
                    try queue.add(next_coord);
                }
            }
        }
    }
    return std.math.maxInt(usize);
}

fn runPart1(allocator: std.mem.Allocator, input: []const u8, max_bytes: usize, max_coordinate: Coordinate) !usize {
    var corrupted_coordinates = CoordinateSet.init(allocator);
    defer corrupted_coordinates.deinit();

    var line_iter = std.mem.splitScalar(u8, input, '\n');
    var byte: usize = 0;
    while (line_iter.next()) |line| {
        var split = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i32, split.next().?, 10);
        const y = try std.fmt.parseInt(i32, split.next().?, 10);
        try corrupted_coordinates.put(.{ .x = x, .y = y }, {});
        byte += 1;
        if (byte == max_bytes) {
            break;
        }
    }

    const min_dist = try searchPath(allocator, corrupted_coordinates, max_coordinate);

    return min_dist;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    return runPart1(allocator, input, 1024, Coordinate{ .x = 70, .y = 70 });
}

fn runPart2(allocator: std.mem.Allocator, input: []const u8, max_coordinate: Coordinate) ![]u8 {
    var corrupted_coordinates = CoordinateSet.init(allocator);
    defer corrupted_coordinates.deinit();

    var line_iter = std.mem.splitScalar(u8, input, '\n');
    var byte: usize = 0;
    while (line_iter.next()) |line| {
        var split = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i32, split.next().?, 10);
        const y = try std.fmt.parseInt(i32, split.next().?, 10);
        try corrupted_coordinates.put(.{ .x = x, .y = y }, {});
        const min_dist = try searchPath(allocator, corrupted_coordinates, max_coordinate);
        if (min_dist == std.math.maxInt(usize)) {
            return std.fmt.allocPrint(allocator, "{d},{d}", .{ x, y });
        }
        byte += 1;
    }

    return std.fmt.allocPrint(allocator, "not found", .{});
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    return runPart2(allocator, input, Coordinate{ .x = 70, .y = 70 });
}

const test_input =
    \\5,4
    \\4,2
    \\4,5
    \\3,0
    \\2,1
    \\6,3
    \\2,4
    \\1,5
    \\0,6
    \\3,3
    \\2,6
    \\5,1
    \\1,2
    \\5,5
    \\2,5
    \\6,5
    \\1,4
    \\0,4
    \\6,4
    \\1,1
    \\6,1
    \\1,0
    \\0,5
    \\1,6
    \\2,0
;

test "day18_part1" {
    try std.testing.expectEqual(22, try runPart1(test_allocator, test_input, 12, Coordinate{ .x = 6, .y = 6 }));
}

test "day18_part2" {
    const answer = try runPart2(test_allocator, test_input, Coordinate{ .x = 6, .y = 6 });
    defer test_allocator.free(answer);
    try std.testing.expectEqualSlices(u8, "6,1", answer);
}
