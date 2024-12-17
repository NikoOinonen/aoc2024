const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

const Coordinate = utils.Point(i32);
const Map = utils.Matrix(u8);
const Direction = utils.Direction;
const directions = &.{ Direction.up, Direction.right, Direction.down, Direction.left };

const State = struct {
    pos: Coordinate,
    dir: Direction,
};
const StateSet = std.AutoHashMap(State, void);
const StateList = std.ArrayList(State);
const StateDistances = std.AutoHashMap(State, u64);
const Move = struct {
    state: State,
    cost: u64,
};

fn compareStates(distances: *StateDistances, state1: State, state2: State) std.math.Order {
    const d1 = distances.get(state1) orelse std.math.maxInt(u64);
    const d2 = distances.get(state2) orelse std.math.maxInt(u64);
    if (std.math.order(d1, d2).differ()) |dist_order| {
        return dist_order;
    } else if (std.math.order(state1.pos.x, state2.pos.x).differ()) |x_order| {
        return x_order;
    } else if (std.math.order(state1.pos.y, state2.pos.y).differ()) |y_order| {
        return y_order;
    } else {
        return std.math.order(@intFromEnum(state1.dir), @intFromEnum(state2.dir));
    }
}

fn getMoves(allocator: std.mem.Allocator, state: State, map: Map) !std.ArrayList(Move) {
    const pos, const dir = .{ state.pos, state.dir };
    var moves = std.ArrayList(Move).init(allocator);
    try moves.append(.{ .state = State{ .pos = pos, .dir = dir.turnLeft() }, .cost = 1000 });
    try moves.append(.{ .state = State{ .pos = pos, .dir = dir.turnRight() }, .cost = 1000 });
    var dist: usize = 0;
    var coord = state.pos;
    while (true) {
        const next_coord = coord.add(state.dir.offset());
        if (map.get(@intCast(next_coord.y), @intCast(next_coord.x)) == '#') {
            if (dist > 0) {
                try moves.append(.{ .state = State{ .pos = coord, .dir = dir }, .cost = dist });
            }
            break;
        }
        if (dist > 0) {
            const right_coord = coord.add(dir.turnRight().offset());
            const left_coord = coord.add(dir.turnLeft().offset());
            if (map.get(@intCast(right_coord.y), @intCast(right_coord.x)) != '#' or map.get(@intCast(left_coord.y), @intCast(left_coord.x)) != '#') {
                try moves.append(.{ .state = State{ .pos = coord, .dir = dir }, .cost = dist });
            }
        }
        coord = next_coord;
        dist += 1;
    }
    return moves;
}

fn searchPath(allocator: std.mem.Allocator, map: Map, reindeer: State, target: Coordinate) !u64 {
    var distances = StateDistances.init(allocator);
    defer distances.deinit();
    try distances.put(reindeer, 0);

    var queue = std.PriorityQueue(State, *StateDistances, compareStates).init(allocator, &distances);
    defer queue.deinit();
    try queue.add(reindeer);

    var previous_state = std.AutoHashMap(State, State).init(allocator);
    defer previous_state.deinit();

    var final_state: State = undefined;
    var min_distance: u64 = std.math.maxInt(u64);
    while (queue.removeOrNull()) |state| {
        const state_distance = distances.get(state).?;
        if (state.pos.equal(target)) {
            if (state_distance < min_distance) {
                final_state = state;
                min_distance = state_distance;
            }
        }
        const moves = try getMoves(allocator, state, map);
        defer moves.deinit();
        for (moves.items) |move| {
            const new_distance = state_distance + move.cost;
            const cur_distance = distances.get(move.state) orelse std.math.maxInt(u64);
            if (new_distance < cur_distance) {
                try distances.put(move.state, new_distance);
                try queue.add(move.state);
                try previous_state.put(move.state, state);
            }
        }
    }

    var cur_state = final_state;
    while (previous_state.get(cur_state)) |prev_state| {
        cur_state = prev_state;
    }

    return distances.get(final_state).?;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const map = try Map.initFromString(allocator, input);
    defer map.deinit();

    var reindeer = State{ .pos = Coordinate{ .x = 0, .y = 0 }, .dir = Direction.right };
    var target = Coordinate{ .x = 0, .y = 0 };
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            const c = map.get(i, j);
            if (c == 'S') {
                reindeer.pos = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
            } else if (c == 'E') {
                target = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
            }
        }
    }

    const min_score = try searchPath(allocator, map, reindeer, target);

    return min_score;
}

fn searchPath2(allocator: std.mem.Allocator, map: Map, reindeer: State, target: Coordinate) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var distances = StateDistances.init(arena_allocator);
    try distances.put(reindeer, 0);

    var queue = std.PriorityQueue(State, *StateDistances, compareStates).init(arena_allocator, &distances);
    try queue.add(reindeer);

    var previous_state = std.AutoHashMap(State, *StateList).init(arena_allocator);

    var min_distance: u64 = std.math.maxInt(u64);
    while (queue.removeOrNull()) |state| {
        const state_distance = distances.get(state).?;
        if (state.pos.equal(target)) {
            min_distance = @min(min_distance, state_distance);
        }
        const moves = try getMoves(arena_allocator, state, map);
        for (moves.items) |move| {
            const new_distance = state_distance + move.cost;
            const cur_distance = distances.get(move.state) orelse std.math.maxInt(u64);
            if (new_distance == cur_distance) {
                var state_list = previous_state.get(move.state).?;
                try state_list.append(state);
            } else if (new_distance < cur_distance) {
                try distances.put(move.state, new_distance);
                try queue.add(move.state);

                var state_list = try arena_allocator.create(StateList);
                state_list.* = StateList.init(arena_allocator);
                try state_list.append(state);
                try previous_state.put(move.state, state_list);
            }
        }
    }

    var path_queue = StateList.init(arena_allocator);
    inline for (directions) |dir| {
        const final_state = State{ .pos = target, .dir = dir };
        if (distances.get(final_state)) |dist| {
            if (dist == min_distance) {
                try path_queue.append(final_state);
            }
        }
    }

    var visited_coords = std.AutoHashMap(Coordinate, void).init(arena_allocator);
    try visited_coords.put(target, {});
    var visited_states = StateSet.init(arena_allocator);

    while (path_queue.popOrNull()) |state| {
        try visited_states.put(state, {});
        if (previous_state.get(state)) |prev_states| {
            for (prev_states.items) |prev_state| {
                if (!visited_states.contains(prev_state)) {
                    try path_queue.append(prev_state);
                }
                var coord = prev_state.pos;
                while (!coord.equal(state.pos)) {
                    try visited_coords.put(coord, {});
                    coord = coord.add(prev_state.dir.offset());
                }
            }
        }
    }

    return visited_coords.count();
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const map = try Map.initFromString(allocator, input);
    defer map.deinit();

    var reindeer = State{ .pos = Coordinate{ .x = 0, .y = 0 }, .dir = Direction.right };
    var target = Coordinate{ .x = 0, .y = 0 };
    for (0..map.n_rows) |i| {
        for (0..map.n_cols) |j| {
            const c = map.get(i, j);
            if (c == 'S') {
                reindeer.pos = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
            } else if (c == 'E') {
                target = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
            }
        }
    }

    const num_tiles = try searchPath2(allocator, map, reindeer, target);

    return num_tiles;
}

const test_input1 =
    \\###############
    \\#.......#....E#
    \\#.#.###.#.###.#
    \\#.....#.#...#.#
    \\#.###.#####.#.#
    \\#.#.#.......#.#
    \\#.#.#####.###.#
    \\#...........#.#
    \\###.#.#####.#.#
    \\#...#.....#.#.#
    \\#.#.#.###.#.#.#
    \\#.....#...#.#.#
    \\#.###.#.#.#.#.#
    \\#S..#.....#...#
    \\###############
;

const test_input2 =
    \\#################
    \\#...#...#...#..E#
    \\#.#.#.#.#.#.#.#.#
    \\#.#.#.#...#...#.#
    \\#.#.#.#.###.#.#.#
    \\#...#.#.#.....#.#
    \\#.#.#.#.#.#####.#
    \\#.#...#.#.#.....#
    \\#.#.#####.#.###.#
    \\#.#.#.......#...#
    \\#.#.###.#####.###
    \\#.#.#...#.....#.#
    \\#.#.#.#####.###.#
    \\#.#.#.........#.#
    \\#.#.#.#########.#
    \\#S#.............#
    \\#################
;

test "day16_part1" {
    try std.testing.expectEqual(7036, try part1(test_allocator, test_input1));
    try std.testing.expectEqual(11048, try part1(test_allocator, test_input2));
}

test "day16_part2" {
    try std.testing.expectEqual(45, try part2(test_allocator, test_input1));
    try std.testing.expectEqual(64, try part2(test_allocator, test_input2));
}
