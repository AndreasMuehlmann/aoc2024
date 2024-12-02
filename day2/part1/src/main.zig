const std = @import("std");

fn logicalXor(value1: bool, value2: bool) bool {
    return (value1 and !value2) or (!value1 and value2);
}

fn isSafe(list: std.ArrayList(u32)) bool {
    var increasing: bool = undefined;
    if (list.items.len == 1) {
        return true;
    }
    if (list.items.len == 2) {
        if (list.items[0] == list.items[1]) {
            return false;
        }
        return true;
    } else {
        increasing = list.items[0] < list.items[1];
    }

    var previous: u32 = list.items[0];
    for (list.items[1..]) |value| {
        if (logicalXor(previous < value, increasing)) {
            return false;
        }
        const i32Value: i32 = @bitCast(value);
        const i32Previous: i32 = @bitCast(previous);
        if (@abs(i32Value - i32Previous) > 3 or i32Value - i32Previous == 0) {
            return false;
        }
        previous = value;
    }
    return true;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file_path = "part1.txt";

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    const buffer = reader.reader();

    var list = std.ArrayList(std.ArrayList(u32)).init(allocator);

    while (true) {
        const line = buffer.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize)) catch break;
        defer allocator.free(line);

        var tokenizer = std.mem.tokenize(u8, line, &[_]u8{' '});
        var stringValue = tokenizer.next();

        var innerList = std.ArrayList(u32).init(allocator);
        while (stringValue != null) {
            try innerList.append(try std.fmt.parseInt(u32, stringValue.?, 10));

            stringValue = tokenizer.next();
        }
        try list.append(innerList);
    }

    var count: u32 = 0;
    for (list.items) |innerList| {
        if (isSafe(innerList)) {
            count += 1;
        }
        innerList.deinit();
    }
    list.deinit();

    std.debug.print("{d}\n", .{count});
}
