const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

fn combo(operand: u8, registers: *[3]u64) u64 {
    if (operand <= 3) {
        return @intCast(operand);
    } else {
        return registers[operand - 4];
    }
}

fn runProgram(allocator: std.mem.Allocator, program: std.ArrayList(u8), registers: *[3]u64) ![]u8 {
    var instruction_pointer: usize = 0;
    var output = std.ArrayList(u8).init(allocator);
    while (instruction_pointer < program.items.len) {
        const opcode = program.items[instruction_pointer];
        const operand = program.items[instruction_pointer + 1];
        switch (opcode) {
            0 => registers[0] = registers[0] >> @intCast(combo(operand, registers)),
            1 => registers[1] ^= @intCast(operand),
            2 => registers[1] = combo(operand, registers) & 0b111,
            3 => instruction_pointer = if (registers[0] != 0) operand else instruction_pointer + 2,
            4 => registers[1] ^= registers[2],
            5 => {
                try output.append(@as(u8, @intCast(combo(operand, registers) & 0b111)) + '0');
                try output.append(',');
            },
            6 => registers[1] = registers[0] >> @intCast(combo(operand, registers)),
            7 => registers[2] = registers[0] >> @intCast(combo(operand, registers)),
            else => unreachable,
        }
        if (opcode != 3) {
            instruction_pointer += 2;
        }
    }

    _ = output.pop();

    return output.toOwnedSlice();
}

// 1. B <- A AND 0b111
// 2. B <- B XOR 0b111
// 3. C <- A >> B
// 4. B <- B XOR C
// 5. B <- B XOR 0b100
// 6. OUT append B AND 0b111
// 7. A <- A >> 3
// 8. If A > 0: goto 1

pub fn part1(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var split = std.mem.splitSequence(u8, input, "\n\n");
    var register_lines = std.mem.splitScalar(u8, split.next().?, '\n');
    const program_line = split.next().?;

    var registers: [3]u64 = undefined;
    for (0..3) |i| {
        var line_split = std.mem.splitScalar(u8, register_lines.next().?, ' ');
        _ = line_split.next();
        _ = line_split.next();
        registers[i] = try std.fmt.parseInt(u64, line_split.next().?, 10);
    }

    var program = std.ArrayList(u8).init(allocator);
    defer program.deinit();
    for (program_line[9..]) |char| {
        if (char == ',') {
            continue;
        }
        const num = char - '0';
        try program.append(num);
    }

    return runProgram(allocator, program, &registers);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var split = std.mem.splitSequence(u8, input, "\n\n");
    _ = split.next();
    const program_line = split.next().?;

    var program = std.ArrayList(u8).init(allocator);
    defer program.deinit();
    for (program_line[9..]) |char| {
        if (char == ',') {
            continue;
        }
        const num = char - '0';
        try program.append(num);
    }

    const State = struct {
        a: u64,
        ind: usize,
    };

    var a_candidates = std.ArrayList(State).init(allocator);
    defer a_candidates.deinit();
    try a_candidates.append(.{ .a = 0, .ind = 0 });
    while (a_candidates.popOrNull()) |state| {
        var found = std.ArrayList(u64).init(allocator);
        defer found.deinit();
        for (0..8) |i| {
            const next_a = (state.a << 3) + (7 - i);
            var registers: [3]u64 = .{ next_a, 0, 0 };
            const output = try runProgram(allocator, program, &registers);
            defer allocator.free(output);
            const offset = 2 * state.ind + 1;
            if (std.mem.eql(u8, program_line[9..], output)) {
                try found.append(next_a);
            } else if (std.mem.eql(u8, program_line[(program_line.len - offset)..], output)) {
                try a_candidates.append(.{ .a = next_a, .ind = state.ind + 1 });
            }
        }
        if (found.items.len > 0) {
            var min: u64 = std.math.maxInt(u64);
            for (found.items) |a| {
                min = @min(min, a);
            }
            return min;
        }
    }

    return 0;
}

const test_input =
    \\Register A: 729
    \\Register B: 0
    \\Register C: 0
    \\
    \\Program: 0,1,5,4,3,0
;

const test_input2 =
    \\Register A: 2024
    \\Register B: 0
    \\Register C: 0
    \\
    \\Program: 0,3,5,4,3,0
;

test "day17_part1" {
    const output = try part1(test_allocator, test_input);
    defer test_allocator.free(output);
    try std.testing.expectEqualSlices(u8, "4,6,3,5,6,3,5,2,1,0", output);
}

test "day17_part2" {
    try std.testing.expectEqual(117440, try part2(test_allocator, test_input2));
}
