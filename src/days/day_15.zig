const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();
const test_allocator = std.testing.allocator;

const Direction = utils.Direction;
const Coordinate = utils.Point(i32);
const WallSet = std.AutoHashMap(Coordinate, void);
const BoxSet = std.AutoHashMap(Coordinate, void);

fn parseMap(allocator: std.mem.Allocator, map: []const u8) !struct { WallSet, BoxSet, Coordinate, usize, usize } {
    var robot_pos = Coordinate{ .x = 0, .y = 0 };
    var boxes = BoxSet.init(allocator);
    var walls = WallSet.init(allocator);
    var i: i32 = 0;
    var j: i32 = 0;
    var max_j: i32 = 0;
    for (map) |char| {
        switch (char) {
            '\n' => {
                i += 1;
                j = 0;
            },
            '#' => try walls.put(Coordinate{ .x = j, .y = i }, {}),
            'O' => try boxes.put(Coordinate{ .x = j, .y = i }, {}),
            '@' => robot_pos = Coordinate{ .x = j, .y = i },
            else => {},
        }
        if (char != '\n') {
            j += 1;
        }
        max_j = @max(max_j, j);
    }
    const map_size_x: usize = @intCast(max_j);
    const map_size_y: usize = @intCast(i + 1);

    return .{ walls, boxes, robot_pos, map_size_x, map_size_y };
}

fn debugPrintMap(boxes: BoxSet, walls: WallSet, robot: Coordinate, map_size_x: usize, map_size_y: usize) !void {
    for (0..map_size_y) |i| {
        for (0..map_size_x) |j| {
            const coord = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
            if (boxes.contains(coord)) {
                _ = try stderr.write("O");
            } else if (walls.contains(coord)) {
                _ = try stderr.write("#");
            } else if (robot.equal(coord)) {
                _ = try stderr.write("@");
            } else {
                _ = try stderr.write(".");
            }
        }
        _ = try stderr.write("\n");
    }
}

fn getDirection(char: u8) ?Direction {
    return switch (char) {
        '^' => Direction.up,
        '>' => Direction.right,
        'v' => Direction.down,
        '<' => Direction.left,
        else => null,
    };
}

fn moveRobot(boxes: *BoxSet, walls: WallSet, robot: *Coordinate, dir: Direction) !void {
    const offset = dir.offset();
    const new_robot = robot.add(offset);
    if (walls.contains(new_robot)) {
        return;
    } else if (boxes.contains(new_robot)) {
        var distance_to_empty_space: ?usize = 1;
        while (true) {
            const test_coord = Coordinate{
                .x = new_robot.x + @as(i32, @intCast(distance_to_empty_space.?)) * offset.x,
                .y = new_robot.y + @as(i32, @intCast(distance_to_empty_space.?)) * offset.y,
            };
            if (boxes.contains(test_coord)) {
                distance_to_empty_space.? += 1;
            } else if (walls.contains(test_coord)) {
                distance_to_empty_space = null;
                break;
            } else {
                distance_to_empty_space.? += 1;
                break;
            }
        }
        if (distance_to_empty_space) |d| {
            const new_box = Coordinate{
                .x = robot.x + @as(i32, @intCast(d)) * offset.x,
                .y = robot.y + @as(i32, @intCast(d)) * offset.y,
            };
            _ = boxes.remove(new_robot);
            try boxes.put(new_box, {});
            robot.* = new_robot;
        }
    } else {
        robot.* = new_robot;
    }
}

fn getGPSSum(boxes: BoxSet) usize {
    var sum_gps: usize = 0;
    var box_iter = boxes.keyIterator();
    while (box_iter.next()) |box| {
        sum_gps += 100 * @as(usize, @intCast(box.y)) + @as(usize, @intCast(box.x));
    }
    return sum_gps;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var split = std.mem.splitSequence(u8, input, "\n\n");
    const map = split.next().?;
    const instructions = split.next().?;

    var walls, var boxes, var robot, const map_size_x, const map_size_y = try parseMap(allocator, map);
    defer {
        boxes.deinit();
        walls.deinit();
    }
    _ = map_size_x;
    _ = map_size_y;

    for (instructions) |char| {
        if (getDirection(char)) |dir| {
            try moveRobot(&boxes, walls, &robot, dir);
        }
    }

    return getGPSSum(boxes);
}

fn parseMap2(allocator: std.mem.Allocator, map: []const u8) !struct { WallSet, BoxSet, Coordinate, usize, usize } {
    var robot_pos = Coordinate{ .x = 0, .y = 0 };
    var boxes = BoxSet.init(allocator);
    var walls = WallSet.init(allocator);
    var i: i32 = 0;
    var j: i32 = 0;
    var max_j: i32 = 0;
    for (map) |char| {
        switch (char) {
            '\n' => {
                i += 1;
                j = 0;
            },
            '#' => {
                try walls.put(Coordinate{ .x = j, .y = i }, {});
                try walls.put(Coordinate{ .x = j + 1, .y = i }, {});
            },
            'O' => try boxes.put(Coordinate{ .x = j, .y = i }, {}),
            '@' => robot_pos = Coordinate{ .x = j, .y = i },
            else => {},
        }
        if (char != '\n') {
            j += 2;
        }
        max_j = @max(max_j, j);
    }
    const map_size_x: usize = @intCast(max_j);
    const map_size_y: usize = @intCast(i + 1);

    return .{ walls, boxes, robot_pos, map_size_x, map_size_y };
}

fn debugPrintMap2(boxes: BoxSet, walls: WallSet, robot: Coordinate, map_size_x: usize, map_size_y: usize) !void {
    for (0..map_size_y) |i| {
        for (0..map_size_x) |j| {
            const coord = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
            const prev_coord = Coordinate{ .x = @as(i32, @intCast(j)) - 1, .y = @intCast(i) };
            if (boxes.contains(coord)) {
                _ = try stderr.write("[");
            } else if (boxes.contains(prev_coord)) {
                _ = try stderr.write("]");
            } else if (walls.contains(coord)) {
                _ = try stderr.write("#");
            } else if (robot.equal(coord)) {
                _ = try stderr.write("@");
            } else {
                _ = try stderr.write(".");
            }
        }
        _ = try stderr.write("\n");
    }
}

fn moveRobot2(allocator: std.mem.Allocator, boxes: *BoxSet, walls: WallSet, robot: *Coordinate, dir: Direction) !void {
    const offset = dir.offset();
    const new_robot = robot.add(offset);
    const new_robot_left = new_robot.add(Direction.left.offset());
    if (walls.contains(new_robot)) {
        return;
    } else if (boxes.contains(new_robot) or boxes.contains(new_robot_left)) {
        var moved_boxes = std.ArrayList(Coordinate).init(allocator);
        defer moved_boxes.deinit();
        const init_box_coord = if (boxes.contains(new_robot)) new_robot else new_robot_left;
        try moved_boxes.append(init_box_coord);
        var hit_wall = false;
        if (dir == Direction.right or dir == Direction.left) {
            var last_box_coord = init_box_coord;
            while (true) {
                const test_coord = last_box_coord.add(offset).add(offset);
                const test_coord_right = test_coord.add(Direction.right.offset());
                if (boxes.contains(test_coord)) {
                    last_box_coord = test_coord;
                    try moved_boxes.append(test_coord);
                } else if (dir == Direction.right and walls.contains(test_coord)) {
                    hit_wall = true;
                    break;
                } else if (dir == Direction.left and walls.contains(test_coord_right)) {
                    hit_wall = true;
                    break;
                } else {
                    break;
                }
            }
        } else {
            var last_box_count: usize = 0;
            outer: while (true) {
                const current_box_count = moved_boxes.items.len;
                if (current_box_count == last_box_count) {
                    break;
                }
                for (last_box_count..current_box_count) |i_box| {
                    const box = moved_boxes.items[i_box];
                    const test_coord = box.add(offset);
                    const test_coord_left = test_coord.add(Direction.left.offset());
                    const test_coord_right = test_coord.add(Direction.right.offset());
                    if (walls.contains(test_coord) or walls.contains(test_coord_right)) {
                        hit_wall = true;
                        break :outer;
                    } else if (boxes.contains(test_coord)) {
                        try moved_boxes.append(test_coord);
                    } else {
                        if (boxes.contains(test_coord_left)) {
                            try moved_boxes.append(test_coord_left);
                        }
                        if (boxes.contains(test_coord_right)) {
                            try moved_boxes.append(test_coord_right);
                        }
                    }
                }
                last_box_count = current_box_count;
            }
        }
        if (!hit_wall) {
            const num_boxes = moved_boxes.items.len;
            for (0..num_boxes) |i_box| {
                const box = moved_boxes.items[num_boxes - i_box - 1];
                const new_box = box.add(offset);
                _ = boxes.remove(box);
                try boxes.put(new_box, {});
            }
            robot.* = new_robot;
        }
    } else {
        robot.* = new_robot;
    }
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var split = std.mem.splitSequence(u8, input, "\n\n");
    const map = split.next().?;
    const instructions = split.next().?;

    var walls, var boxes, var robot, const map_size_x, const map_size_y = try parseMap2(allocator, map);
    defer {
        boxes.deinit();
        walls.deinit();
    }
    _ = map_size_x;
    _ = map_size_y;

    for (instructions) |char| {
        if (getDirection(char)) |dir| {
            try moveRobot2(allocator, &boxes, walls, &robot, dir);
        }
    }

    return getGPSSum(boxes);
}

const test_input1 =
    \\########
    \\#..O.O.#
    \\##@.O..#
    \\#...O..#
    \\#.#.O..#
    \\#...O..#
    \\#......#
    \\########
    \\
    \\<^^>>>vv<v>>v<<
;

const test_input2 =
    \\##########
    \\#..O..O.O#
    \\#......O.#
    \\#.OO..O.O#
    \\#..O@..O.#
    \\#O#..O...#
    \\#O..O..O.#
    \\#.OO.O.OO#
    \\#....O...#
    \\##########
    \\
    \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
;

test "day15_part1" {
    try std.testing.expectEqual(2028, try part1(test_allocator, test_input1));
    try std.testing.expectEqual(10092, try part1(test_allocator, test_input2));
}

test "day15_part2" {
    try std.testing.expectEqual(9021, try part2(test_allocator, test_input2));
}
