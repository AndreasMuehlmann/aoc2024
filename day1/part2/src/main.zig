const std = @import("std");

fn binarySearch(list: []const u32, value: u32) ?usize {
    var low: usize = 0;
    var high: usize = list.len - 1;
    var mid: usize = 0;

    while (low <= high) {
        mid = low + (high - low) / 2;
        if (value < list[mid]) {
            high = mid - 1;
        } else if (value > list[mid]) {
            low = mid + 1;
        } else {
            return mid;
        }
    }
    return null;
}

fn countOccurences(list: []const u32, value: u32) u32 {
    var occurences: u32 = 0;
    for (list) |val| {
        if (val == value) {
            occurences += 1;
        }
    }
    return occurences;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file_path = "part2.txt";

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    const buffer = reader.reader();

    var list1 = std.ArrayList(u32).init(allocator);
    var list2 = std.ArrayList(u32).init(allocator);

    while (true) {
        const line = buffer.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize)) catch break;
        defer allocator.free(line);

        var tokenizer = std.mem.tokenize(u8, line, &[_]u8{' '});
        const val1 = tokenizer.next().?;
        const value1 = try std.fmt.parseInt(u32, val1, 10);
        const value2 = try std.fmt.parseInt(u32, tokenizer.next().?, 10);
        try list1.append(value1);
        try list2.append(value2);
    }

    const slice1 = try list1.toOwnedSlice();
    const slice2 = try list2.toOwnedSlice();
    std.mem.sort(u32, slice1, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, slice2, {}, comptime std.sort.asc(u32));

    var sum: u32 = 0;
    for (0..slice1.len) |index| {
        sum += slice1[index] * countOccurences(slice2, slice1[index]);
    }
    std.debug.print("{d}\n", .{sum});
}

test "TestBinarySearch" {
    const list: [21]u32 = [_]u32{
        0,  1,  2,  3,  4,  5,  6,  7,  8,  9,
        10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20,
    };
    try std.testing.expect(binarySearch(&list, 4).? == 4);
    try std.testing.expect(binarySearch(&list, 20).? == 20);
    try std.testing.expect(binarySearch(&list, 0).? == 0);
}

test "TestCountOccurences" {
    const list: [21]u32 = [_]u32{
        0,  1,  2,  2,  4,  4,  4,  7,  8,  9,
        10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20,
    };
    try std.testing.expect(countOccurences(&list, 0) == 1);
    try std.testing.expect(countOccurences(&list, 2) == 2);
    try std.testing.expect(countOccurences(&list, 4) == 3);
    try std.testing.expect(countOccurences(&list, 21) == 0);
}
