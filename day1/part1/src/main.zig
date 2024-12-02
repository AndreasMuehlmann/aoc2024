const std = @import("std");

fn cmpByValue(context: void, a: i32, b: i32) bool {
    return std.sort.asc(i32)(context, a, b);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file_path = "part1.txt";

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
        const integer1: i32 = @bitCast(slice1[index]);
        const integer2: i32 = @bitCast(slice2[index]);
        sum += @abs(integer1 - integer2);
    }
    std.debug.print("{d}\n", .{sum});
}
