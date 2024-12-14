const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();
const stdin = std.io.getStdIn().reader();
const test_allocator = std.testing.allocator;

const Robot = struct {
    pos: utils.Point(i32),
    velocity: utils.Point(i32),
};

fn parseRobots(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Robot) {
    var robots = std.ArrayList(Robot).init(allocator);
    errdefer robots.deinit();

    var line_iter = std.mem.splitScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var split = std.mem.splitScalar(u8, line, ' ');
        var p_split = std.mem.splitScalar(u8, split.next().?[2..], ',');
        const px = try std.fmt.parseInt(i32, p_split.next().?, 10);
        const py = try std.fmt.parseInt(i32, p_split.next().?, 10);
        const pos = utils.Point(i32){ .x = px, .y = py };
        var v_split = std.mem.splitScalar(u8, split.next().?[2..], ',');
        const vx = try std.fmt.parseInt(i32, v_split.next().?, 10);
        const vy = try std.fmt.parseInt(i32, v_split.next().?, 10);
        const velocity = utils.Point(i32){ .x = vx, .y = vy };
        try robots.append(Robot{ .pos = pos, .velocity = velocity });
    }
    return robots;
}

fn run_part1(allocator: std.mem.Allocator, input: []const u8, map_size_x: i32, map_size_y: i32) !u32 {
    const robots = try parseRobots(allocator, input);
    defer robots.deinit();

    const num_iter = 100;
    for (0..num_iter) |_| {
        for (robots.items) |*robot| {
            var new_pos_x = robot.pos.x + robot.velocity.x;
            if (new_pos_x >= map_size_x) {
                new_pos_x -= map_size_x;
            } else if (new_pos_x < 0) {
                new_pos_x += map_size_x;
            }
            var new_pos_y = robot.pos.y + robot.velocity.y;
            if (new_pos_y >= map_size_y) {
                new_pos_y -= map_size_y;
            } else if (new_pos_y < 0) {
                new_pos_y += map_size_y;
            }
            robot.pos.x = new_pos_x;
            robot.pos.y = new_pos_y;
        }
    }

    var quadrant_counts: [4]u32 = .{ 0, 0, 0, 0 };
    const half_x = @divFloor(map_size_x, 2);
    const half_y = @divFloor(map_size_y, 2);
    for (robots.items) |robot| {
        if (robot.pos.x < half_x) {
            if (robot.pos.y < half_y) {
                quadrant_counts[0] += 1;
            } else if (robot.pos.y > half_y) {
                quadrant_counts[1] += 1;
            }
        } else if (robot.pos.x > half_x) {
            if (robot.pos.y < half_y) {
                quadrant_counts[2] += 1;
            } else if (robot.pos.y > half_y) {
                quadrant_counts[3] += 1;
            }
        }
    }

    const total_safety = quadrant_counts[0] * quadrant_counts[1] * quadrant_counts[2] * quadrant_counts[3];

    return total_safety;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    return try run_part1(allocator, input, 101, 103);
}

fn robotAt(robots: []Robot, pos: utils.Point(i32)) bool {
    for (robots) |robot| {
        if (robot.pos.equal(pos)) {
            return true;
        }
    }
    return false;
}

fn printRobots(robots: []Robot, map_size_x: usize, map_size_y: usize) !void {
    for (0..map_size_y) |i| {
        for (0..map_size_x) |j| {
            if (robotAt(robots, utils.Point(i32){ .x = @intCast(j), .y = @intCast(i) })) {
                _ = try stderr.write("#");
            } else {
                _ = try stderr.write(".");
            }
        }
        _ = try stderr.write("\n");
    }
}

fn waitForInput() !void {
    try stdout.print("Press enter to continue", .{});
    var buf: [10]u8 = undefined;
    _ = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');
    return;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const robots = try parseRobots(allocator, input);
    defer robots.deinit();

    const num_iter = 10000;
    const map_size_x = 101;
    const map_size_y = 103;
    for (0..num_iter) |iter| {
        if (iter >= 47) {
            if ((iter - 47) % 103 == 0) {
                try waitForInput();
                try printRobots(robots.items, @intCast(map_size_x), @intCast(map_size_y));
                std.debug.print("{d}\n", .{iter});
            }
        }
        for (robots.items) |*robot| {
            var new_pos_x = robot.pos.x + robot.velocity.x;
            if (new_pos_x >= map_size_x) {
                new_pos_x -= map_size_x;
            } else if (new_pos_x < 0) {
                new_pos_x += map_size_x;
            }
            var new_pos_y = robot.pos.y + robot.velocity.y;
            if (new_pos_y >= map_size_y) {
                new_pos_y -= map_size_y;
            } else if (new_pos_y < 0) {
                new_pos_y += map_size_y;
            }
            robot.pos.x = new_pos_x;
            robot.pos.y = new_pos_y;
        }
    }

    return 0;
}

const test_input =
    \\p=0,4 v=3,-3
    \\p=6,3 v=-1,-3
    \\p=10,3 v=-1,2
    \\p=2,0 v=2,-1
    \\p=0,0 v=1,3
    \\p=3,0 v=-2,-2
    \\p=7,6 v=-1,-3
    \\p=3,0 v=-1,-2
    \\p=9,3 v=2,3
    \\p=7,3 v=-1,2
    \\p=2,4 v=2,-3
    \\p=9,5 v=-3,-3
;

test "day14_part1" {
    try std.testing.expectEqual(12, try run_part1(test_allocator, test_input, 11, 7));
}
