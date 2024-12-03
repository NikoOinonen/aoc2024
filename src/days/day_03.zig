const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    _ = allocator;

    var seq_iter = std.mem.tokenizeSequence(u8, input, "mul(");
    var sum_result: u32 = 0;
    while (seq_iter.next()) |seq| {
        var num1: ?u32 = null;
        var num2: ?u32 = null;
        var found_comma = false;
        var ind: usize = 0;
        while (ind < seq.len) {
            if (num1 == null) {
                const offset, num1 = try utils.read_num(seq[ind..]);
                if (num1 != null) {
                    ind += offset;
                    continue;
                } else {
                    break;
                }
            } else if (!found_comma and seq[ind] == ',') {
                found_comma = true;
                ind += 1;
                continue;
            } else if (found_comma) {
                const offset, num2 = try utils.read_num(seq[ind..]);
                ind += offset;
                if (num2 != null and seq[ind] == ')') {
                    ind += offset;
                    sum_result += num1.? * num2.?;
                }
                break;
            } else {
                break;
            }
        }
    }
    return sum_result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    _ = allocator;

    var seq_iter = std.mem.tokenizeSequence(u8, input, "mul(");
    var sum_result: u32 = 0;
    var mul_enabled = true;
    while (seq_iter.next()) |seq| {
        if (mul_enabled) {
            var num1: ?u32 = null;
            var num2: ?u32 = null;
            var found_comma = false;
            var ind: usize = 0;
            while (ind < seq.len) {
                if (num1 == null) {
                    const offset, num1 = try utils.read_num(seq[ind..]);
                    if (num1 != null) {
                        ind += offset;
                        continue;
                    } else {
                        break;
                    }
                } else if (!found_comma and seq[ind] == ',') {
                    found_comma = true;
                    ind += 1;
                    continue;
                } else if (found_comma) {
                    const offset, num2 = try utils.read_num(seq[ind..]);
                    ind += offset;
                    if (num2 != null and seq[ind] == ')') {
                        ind += offset;
                        sum_result += num1.? * num2.?;
                    }
                    break;
                } else {
                    break;
                }
            }
        }
        var ind: usize = 0;
        var do_ind: ?usize = null;
        var dont_ind: ?usize = null;
        while (ind < seq.len) {
            const do_ind_ = std.mem.indexOf(u8, seq[ind..], "do()");
            const dont_ind_ = std.mem.indexOf(u8, seq[ind..], "don't()");
            if (do_ind_ == null and dont_ind_ == null) {
                break;
            }
            if (do_ind_ != null) {
                do_ind = do_ind_;
                ind = @max(ind, do_ind.? + 4);
            }
            if (dont_ind_ != null) {
                dont_ind = dont_ind_;
                ind = @max(ind, dont_ind.? + 7);
            }
        }
        if (do_ind != null and dont_ind != null) {
            mul_enabled = do_ind.? > dont_ind.?;
        } else if (do_ind != null) {
            mul_enabled = true;
        } else if (dont_ind != null) {
            mul_enabled = false;
        }
    }
    return sum_result;
}

test "day03_part1" {
    const test_input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(161, answer);
}

test "day03_part2" {
    const test_input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(48, answer);
}
