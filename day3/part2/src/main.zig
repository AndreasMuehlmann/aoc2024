const std = @import("std");
const allocator = std.heap.page_allocator;

const Parser = struct {
    buffer: []const u8,
    index: usize,
    peekIndex: usize,

    pub fn init(buffer: []const u8) Parser {
        return Parser{
            .buffer = buffer,
            .index = 0,
            .peekIndex = 0,
        };
    }

    pub fn readChar(self: *Parser) ?u8 {
        if (self.isFinished()) {
            return null;
        }
        self.index += 1;
        self.synchronizeWithIndex();
        return self.buffer[self.index - 1];
    }

    pub fn peekChar(self: *Parser) ?u8 {
        if (self.peekIndex >= self.buffer.len) {
            return null;
        }
        self.peekIndex += 1;
        return self.buffer[self.peekIndex - 1];
    }

    pub fn movePeek(self: *Parser, toMove: i32) void {
        const temp: i32 = @intCast(self.peekIndex);
        self.peekIndex = @intCast(temp + toMove);
    }

    pub fn isFinished(self: Parser) bool {
        return self.index >= self.buffer.len;
    }

    pub fn synchronizeWithPeek(self: *Parser) void {
        self.index = self.peekIndex;
    }

    pub fn synchronizeWithIndex(self: *Parser) void {
        self.peekIndex = self.index;
    }

    pub fn getNumber(self: *Parser) !?u32 {
        var stringNumber = std.ArrayList(u8).init(allocator);
        defer stringNumber.deinit();

        var char = self.peekChar() orelse 'a';
        while (std.ascii.isDigit(char)) {
            try stringNumber.append(char);
            char = self.peekChar() orelse 'a';
        }

        if (stringNumber.items.len == 0) {
            self.synchronizeWithIndex();
            return null;
        }

        self.movePeek(-1);
        self.synchronizeWithPeek();

        const stringNumberSlice = try stringNumber.toOwnedSlice();
        const number = try std.fmt.parseUnsigned(u32, stringNumberSlice, 10);
        return number;
    }
};

pub fn main() !void {
    const file_path = "part2.txt";

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const maxFileSize = 100000;
    const buffer = try file.readToEndAlloc(allocator, maxFileSize);
    defer allocator.free(buffer);

    var parser = Parser.init(buffer);
    var sum: u32 = 0;
    var enabled: bool = true;
    while (!parser.isFinished()) {
        if (enabled and parser.peekChar() == 'm' and parser.peekChar() == 'u' and parser.peekChar() == 'l' and parser.peekChar() == '(') {
            if (try parser.getNumber()) |number1| {
                if (parser.peekChar() == ',') {
                    if (try parser.getNumber()) |number2| {
                        if (parser.peekChar() == ')') {
                            parser.movePeek(-1);
                            parser.synchronizeWithPeek();
                            sum += number1 * number2;
                        }
                    }
                }
            }
        }
        parser.synchronizeWithIndex();
        if (parser.peekChar() == 'd' and
            parser.peekChar() == 'o' and
            parser.peekChar() == '(' and
            parser.peekChar() == ')')
        {
            parser.movePeek(-1);
            parser.synchronizeWithPeek();
            enabled = true;
        }
        parser.synchronizeWithIndex();
        if (parser.peekChar() == 'd' and
            parser.peekChar() == 'o' and
            parser.peekChar() == 'n' and
            parser.peekChar() == '\'' and
            parser.peekChar() == 't' and
            parser.peekChar() == '(' and
            parser.peekChar() == ')')
        {
            parser.movePeek(-1);
            parser.synchronizeWithPeek();
            enabled = false;
        }
        _ = parser.readChar();
    }
    std.debug.print("sum: {d}\n", .{sum});
}
