const std = @import("std");

fn logicalXor(value1: bool, value2: bool) bool {
    return (value1 and !value2) or (!value1 and value2);
}

fn isLevelChangeSafe(previous: u32, value: u32, increasing: bool) bool {
    if (logicalXor(previous < value, increasing)) {
        return false;
    }
    const i32Value: i32 = @bitCast(value);
    const i32Previous: i32 = @bitCast(previous);
    if (@abs(i32Value - i32Previous) > 3 or i32Value - i32Previous == 0) {
        return false;
    }
    return true;
}

fn isSafeHelper(list: std.ArrayList(u32), increasing: bool, dampenerUsed: bool) bool {
    var isDampenerUsed = dampenerUsed;
    var previous: u32 = list.items[0];
    for (list.items[1..]) |value| {
        if (!isLevelChangeSafe(previous, value, increasing)) {
            if (isDampenerUsed) {
                return false;
            }
            isDampenerUsed = true;
        } else {
            previous = value;
        }
    }
    return true;
}

fn isSafe(list: *std.ArrayList(u32)) !bool {
    var isSafeBool: bool = isSafeHelper(list.*, false, false) or isSafeHelper(list.*, true, false);
    const removed = list.items[0];
    _ = list.orderedRemove(0);
    isSafeBool = isSafeBool or isSafeHelper(list.*, false, true) or isSafeHelper(list.*, false, true);
    try list.insert(0, removed);
    return isSafeBool;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file_path = "part2.txt";

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
    for (0..list.items.len) |index| {
        if (try isSafe(&list.items[index])) {
            count += 1;
        } else {
            for (list.items[index].items) |value| {
                std.debug.print("{d}, ", .{value});
            }
            std.debug.print("\n", .{});
        }

        list.items[index].deinit();
    }
    list.deinit();

    std.debug.print("{d}\n", .{count});
}
