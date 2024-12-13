const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

const Game = struct {
    ax: i64,
    ay: i64,
    bx: i64,
    by: i64,
    px: i64,
    py: i64,
};

fn getGame(game: []const u8) !Game {
    var line_iter = std.mem.tokenizeScalar(u8, game, '\n');
    var a_iter = std.mem.tokenizeScalar(u8, line_iter.next().?, ' ');
    _ = a_iter.next();
    _ = a_iter.next();
    const ax_s = a_iter.next().?;
    const ax = try std.fmt.parseInt(i64, ax_s[2 .. ax_s.len - 1], 10);
    const ay = try std.fmt.parseInt(i64, a_iter.next().?[2..], 10);
    var b_iter = std.mem.tokenizeScalar(u8, line_iter.next().?, ' ');
    _ = b_iter.next();
    _ = b_iter.next();
    const bx_s = b_iter.next().?;
    const bx = try std.fmt.parseInt(i64, bx_s[2 .. bx_s.len - 1], 10);
    const by = try std.fmt.parseInt(i64, b_iter.next().?[2..], 10);
    var p_iter = std.mem.tokenizeScalar(u8, line_iter.next().?, ' ');
    _ = p_iter.next();
    const px_s = p_iter.next().?;
    const px = try std.fmt.parseInt(i64, px_s[2 .. px_s.len - 1], 10);
    const py = try std.fmt.parseInt(i64, p_iter.next().?[2..], 10);
    return .{ .ax = ax, .ay = ay, .bx = bx, .by = by, .px = px, .py = py };
}

fn findNumTokens(game: Game) u64 {
    const prefac_inv = game.ax * game.by - game.bx * game.ay;
    const a_fac = (game.by * game.px - game.bx * game.py);
    const b_fac = (game.ax * game.py - game.ay * game.px);
    if (@rem(a_fac, prefac_inv) != 0 or @rem(b_fac, prefac_inv) != 0) {
        return 0;
    }
    const a_presses = @divExact(a_fac, prefac_inv);
    const b_presses = @divExact(b_fac, prefac_inv);

    return 3 * @as(u64, @intCast(a_presses)) + @as(u64, @intCast(b_presses));
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    _ = allocator;

    var game_iter = std.mem.tokenizeSequence(u8, input, "\n\n");
    var num_tokens: u64 = 0;
    while (game_iter.next()) |game_str| {
        const game = try getGame(game_str);
        num_tokens += findNumTokens(game);
    }

    return num_tokens;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    _ = allocator;

    var game_iter = std.mem.tokenizeSequence(u8, input, "\n\n");
    var num_tokens: u64 = 0;
    while (game_iter.next()) |game_str| {
        var game = try getGame(game_str);
        game.px += 10000000000000;
        game.py += 10000000000000;
        num_tokens += findNumTokens(game);
    }

    return num_tokens;
}

const test_input =
    \\Button A: X+94, Y+34
    \\Button B: X+22, Y+67
    \\Prize: X=8400, Y=5400
    \\
    \\Button A: X+26, Y+66
    \\Button B: X+67, Y+21
    \\Prize: X=12748, Y=12176
    \\
    \\Button A: X+17, Y+86
    \\Button B: X+84, Y+37
    \\Prize: X=7870, Y=6450
    \\
    \\Button A: X+69, Y+23
    \\Button B: X+27, Y+71
    \\Prize: X=18641, Y=10279
;

test "day13_part1" {
    try std.testing.expectEqual(480, try part1(test_allocator, test_input));
}
