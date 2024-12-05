const std = @import("std");
const utils = @import("../utils.zig");

const stdout = std.io.getStdOut().writer();
const test_allocator = std.testing.allocator;

const Rule = struct { first: u32, second: u32 };

fn parseRules(allocator: std.mem.Allocator, rule_list: []const u8) !std.ArrayList(Rule) {
    var rules = std.ArrayList(Rule).init(allocator);
    var rule_list_lines = std.mem.splitScalar(u8, rule_list, '\n');
    while (rule_list_lines.next()) |line| {
        var line_split = std.mem.splitScalar(u8, line, '|');
        const rule = Rule{
            .first = try std.fmt.parseInt(u32, line_split.next().?, 10),
            .second = try std.fmt.parseInt(u32, line_split.next().?, 10),
        };
        try rules.append(rule);
    }
    return rules;
}

fn pagesAreSorted(pages: []const u32, rules: []const Rule) bool {
    for (pages, 0..) |page, first_ind| {
        for (rules) |rule| {
            if (rule.first == page) {
                const second_ind = std.mem.indexOf(u32, pages, &.{rule.second});
                if (second_ind != null and second_ind.? < first_ind) {
                    return false;
                }
            }
        }
    }
    return true;
}

fn sortPages(pages: []u32, rules: []const Rule) void {
    for (0..pages.len - 1) |iter| {
        var swapped = false;
        outer: for (0..pages.len - (iter + 1)) |ind| {
            const first_value = pages[ind];
            const second_value = pages[ind + 1];
            for (rules) |rule| {
                if (rule.first == first_value and rule.second == second_value) {
                    continue :outer;
                } else if (rule.second == first_value and rule.first == second_value) {
                    pages[ind] = second_value;
                    pages[ind + 1] = first_value;
                    swapped = true;
                }
            }
        }
        if (!swapped) {
            break;
        }
    }
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var split = std.mem.splitSequence(u8, input, "\n\n");
    const rule_list = split.next().?;
    const page_list = split.next().?;

    var rules = try parseRules(allocator, rule_list);
    defer rules.deinit();

    var page_lines = std.mem.splitScalar(u8, page_list, '\n');
    var page_sum: u32 = 0;
    while (page_lines.next()) |line| {
        var pages = try utils.parseIntArray(u32, allocator, line, ',');
        defer pages.deinit();
        if (pagesAreSorted(pages.items, rules.items)) {
            const middle_page = pages.items[(pages.items.len - 1) / 2];
            page_sum += middle_page;
        }
    }

    return page_sum;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var split = std.mem.splitSequence(u8, input, "\n\n");
    const rule_list = split.next().?;
    const page_list = split.next().?;

    var rules = try parseRules(allocator, rule_list);
    defer rules.deinit();

    var page_lines = std.mem.splitScalar(u8, page_list, '\n');
    var page_sum: u32 = 0;
    while (page_lines.next()) |line| {
        var pages = try utils.parseIntArray(u32, allocator, line, ',');
        defer pages.deinit();
        if (pagesAreSorted(pages.items, rules.items)) {
            continue;
        }
        sortPages(pages.items, rules.items);
        const middle_page = pages.items[(pages.items.len - 1) / 2];
        page_sum += middle_page;
    }
    return page_sum;
}

const test_input =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

test "day05_part1" {
    const answer = try part1(test_allocator, test_input);
    try std.testing.expectEqual(143, answer);
}

test "day05_part2" {
    const answer = try part2(test_allocator, test_input);
    try std.testing.expectEqual(123, answer);
}
