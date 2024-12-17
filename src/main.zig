const std = @import("std");
const utils = @import("utils.zig");

const day_modules = [25]type{
    @import("days/day_01.zig"),
    @import("days/day_02.zig"),
    @import("days/day_03.zig"),
    @import("days/day_04.zig"),
    @import("days/day_05.zig"),
    @import("days/day_06.zig"),
    @import("days/day_07.zig"),
    @import("days/day_08.zig"),
    @import("days/day_09.zig"),
    @import("days/day_10.zig"),
    @import("days/day_11.zig"),
    @import("days/day_12.zig"),
    @import("days/day_13.zig"),
    @import("days/day_14.zig"),
    @import("days/day_15.zig"),
    @import("days/day_16.zig"),
    @import("days/day_17.zig"),
    @import("days/day_18.zig"),
    @import("days/day_19.zig"),
    @import("days/day_20.zig"),
    @import("days/day_21.zig"),
    @import("days/day_22.zig"),
    @import("days/day_23.zig"),
    @import("days/day_24.zig"),
    @import("days/day_25.zig"),
};

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try stdout.print("Give day number as an argument\n", .{});
        return;
    }

    const day = try std.fmt.parseInt(i32, args[1], 10);
    if (day <= 0 or day > 25) {
        try stdout.print("Day should be between 1 and 25.\n", .{});
        return;
    }

    const input_path = try std.fmt.allocPrint(allocator, "inputs/day_{:0>2}.txt", .{@as(usize, @intCast(day))});
    defer allocator.free(input_path);
    const input = utils.readInput(allocator, input_path) catch |err| switch (err) {
        error.FileNotFound => {
            try stdout.print("No input file for day {d}\n", .{day});
            return;
        },
        else => |other_error| return other_error,
    };
    defer allocator.free(input);

    inline for (0..25) |d| {
        if ((day - 1) == d) {
            const day_module = day_modules[d];
            const answer1 = try day_module.part1(allocator, input);
            if (@TypeOf(answer1) == []u8) {
                try stdout.print("Answer to day {d} part 1 is {s}\n", .{ day, answer1 });
            } else {
                try stdout.print("Answer to day {d} part 1 is {any}\n", .{ day, answer1 });
            }
            const answer2 = try day_module.part2(allocator, input);
            if (@TypeOf(answer2) == []u8) {
                try stdout.print("Answer to day {d} part 2 is {s}\n", .{ day, answer2 });
            } else {
                try stdout.print("Answer to day {d} part 2 is {any}\n", .{ day, answer2 });
            }
        }
    }
}
