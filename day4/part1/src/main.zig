const std = @import("std");
const allocator = std.heap.page_allocator;

fn isWordInDirection(grid: []const []const u8, word: []const u8, x: i32, y: i32, xDirection: i32, yDirection: i32) bool {
    var positionX = x;
    var positionY = y;
    for (word) |char| {
        if (positionX < 0 or positionY < 0 or positionX >= grid[0].len or positionY >= grid.len) {
            return false;
        }
        const xUsize: usize = @intCast(positionX);
        const yUsize: usize = @intCast(positionY);
        if (grid[xUsize][yUsize] != char) {
            return false;
        }
        positionX += xDirection;
        positionY += yDirection;
    }
    return true;
}

fn countWordOriginating(grid: []const []const u8, word: []const u8, x: i32, y: i32) u32 {
    var count: u32 = 0;
    if (isWordInDirection(grid, word, x, y, 1, 0)) {
        count += 1;
    }
    if (isWordInDirection(grid, word, x, y, 1, 1)) {
        count += 1;
    }
    if (isWordInDirection(grid, word, x, y, 0, 1)) {
        count += 1;
    }
    if (isWordInDirection(grid, word, x, y, -1, 1)) {
        count += 1;
    }
    if (isWordInDirection(grid, word, x, y, -1, 0)) {
        count += 1;
    }
    if (isWordInDirection(grid, word, x, y, -1, -1)) {
        count += 1;
    }
    if (isWordInDirection(grid, word, x, y, 0, -1)) {
        count += 1;
    }
    if (isWordInDirection(grid, word, x, y, 1, -1)) {
        count += 1;
    }
    return count;
}

pub fn main() !void {
    const file_path = "part1.txt";

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var bufReader = std.io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var arrayListGrid = std.ArrayList([]u8).init(allocator);

    while (true) {
        const line = reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize)) catch break;
        try arrayListGrid.append(line);
    }

    const grid = try arrayListGrid.toOwnedSlice();
    const word = "XMAS";
    var wordCount: u32 = 0;
    for (0..grid.len) |y| {
        for (0..grid[y].len) |x| {
            const yI32: i32 = @intCast(y);
            const xI32: i32 = @intCast(x);
            wordCount += countWordOriginating(grid, word, yI32, xI32);
        }
    }
    std.debug.print("XMAS count: {d}\n", .{wordCount});
}
