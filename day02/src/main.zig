const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .retain_metadata = true,
        .never_unmap = true,
        // .verbose_log = true,
    }){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) std.testing.expect(false) catch @panic("TEST FAIL"); //fail test; can't try in defer as defer is executed after we return
    }

    const contents = read_file(allocator, "input.txt");
    defer allocator.free(contents);
    
    const res = get_score_part_2(contents);
    std.debug.print("{d}\n", .{res});
}

// A = Rock
// B = Paper
// C = Scissors
// X = Rock (1 pt)
// Y == Paper (2 pt)
// Z == Scissors (3 pt)
// loss = 0, tie = 3, win = 6
const LOSS: u32 = 0;
const TIE: u32 = 3;
const WIN: u32 = 6;
const ROCK: u32 = 1;
const PAPER: u32 = 2;
const SCISSORS: u32 = 3;
fn get_score_part_1(contents: []const u8) u32 {
    var score: u32 = 0;
    var i: usize = 0;
    while (i < contents.len) : (i += 4) {
        score += switch (contents[i + 2]) {
            'X' => ROCK + switch (contents[i]) {
                'A' => TIE,
                'B' => LOSS,
                'C' => WIN,
                else => unreachable
            },
            'Y' => PAPER + switch (contents[i]) {
                'A' => WIN,
                'B' => TIE,
                'C' => LOSS,
                else => unreachable
            },
            'Z' => SCISSORS + switch (contents[i]) {
                'A' => LOSS,
                'B' => WIN,
                'C' => TIE,
                else => unreachable
            },
            else => unreachable
        };
    }
    return score;
}

// X = LOSE
// Y = TIE
// Z = WIN
fn get_score_part_2(contents: []const u8) u32 {
    var score: u32 = 0;
    var i: usize = 0;
    while (i < contents.len) : (i += 4) {
        score += switch (contents[i + 2]) {
            'X' => LOSS + switch (contents[i]) {
                'A' => SCISSORS,
                'B' => ROCK,
                'C' => PAPER,
                else => unreachable
            },
            'Y' => TIE + switch (contents[i]) {
                'A' => ROCK,
                'B' => PAPER,
                'C' => SCISSORS,
                else => unreachable
            },
            'Z' => WIN + switch (contents[i]) {
                'A' => PAPER,
                'B' => SCISSORS,
                'C' => ROCK,
                else => unreachable
            },
            else => unreachable
        };
    }
    return score;
}

fn read_file(allocator: std.mem.Allocator, path: []const u8) []const u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch {
        std.log.err("Could not open file", .{});
        std.process.exit(74);
    };
    defer file.close();

    const contents = file.reader().readAllAlloc(
        allocator,
        std.math.maxInt(usize),
    ) catch {
        std.log.err("Could not read file", .{});
        std.process.exit(74);
    };

    return contents;
}

test "part1 test" {
    const input = 
    \\A Y
    \\B X
    \\C Z
    ;
    try std.testing.expectEqual(get_score_part_1(input), 15);
}

test "part2 test" {
    const input = 
    \\A Y
    \\B X
    \\C Z
    ;
    try std.testing.expectEqual(get_score_part_2(input), 12);
}
