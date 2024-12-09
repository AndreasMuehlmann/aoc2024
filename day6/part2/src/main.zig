const std = @import("std");
const allocator = std.heap.page_allocator;

const Grid = struct {
    grid: [][]u8,
    height: i32,
    width: i32,

    pub fn at(self: Grid, position: Vec2D) u8 {
        const xUsize: usize = @intCast(position.x);
        const yUsize: usize = @intCast(position.y);
        return self.grid[yUsize][xUsize];
    }
};

const Vec2D = struct {
    x: i32,
    y: i32,

    pub fn equal(self: Vec2D, position: Vec2D) bool {
        return position.x == self.x and position.y == self.y;
    }

    pub fn add(self: Vec2D, vec: Vec2D) Vec2D {
        return .{
            .x = self.x + vec.x,
            .y = self.y + vec.y,
        };
    }

    pub fn print(self: Vec2D) void {
        std.debug.print("{d}, {d}\n", .{ self.x, self.y });
    }
};

const PositionDirection = struct {
    position: Vec2D,
    direction: Vec2D,
};

fn containsPD(pds: std.ArrayList(PositionDirection), otherpd: PositionDirection) bool {
    for (pds.items) |pd| {
        if (pd.position.equal(otherpd.position) and pd.direction.equal(otherpd.direction)) {
            return true;
        }
    }
    return false;
}

fn contains(vecs: std.ArrayList(Vec2D), vector: Vec2D) bool {
    for (vecs.items) |vec| {
        if (vec.equal(vector)) {
            return true;
        }
    }
    return false;
}

fn turnRight(direction: Vec2D) Vec2D {
    if (direction.x > 0) {
        return .{
            .x = 0,
            .y = 1,
        };
    }
    if (direction.y > 0) {
        return .{
            .x = -1,
            .y = 0,
        };
    }
    if (direction.x < 0) {
        return .{
            .x = 0,
            .y = -1,
        };
    }
    return .{
        .x = 1,
        .y = 0,
    };
}

fn move(grid: Grid, position: Vec2D, direction: Vec2D) ?PositionDirection {
    var newDirection = direction;
    var newPosition = position.add(direction);

    if (newPosition.x >= grid.width or newPosition.x < 0 or newPosition.y >= grid.height or newPosition.y < 0) {
        return null;
    }

    while (grid.at(newPosition) == '#') {
        newDirection = turnRight(newDirection);

        newPosition = position.add(newDirection);

        if (newPosition.x >= grid.width or newPosition.x < 0 or newPosition.y >= grid.height or newPosition.y < 0) {
            return null;
        }
    }

    return .{
        .position = newPosition,
        .direction = newDirection,
    };
}

fn isLoop(grid: Grid, guardStartingPosition: Vec2D) !bool {
    var guardPosition = guardStartingPosition;
    var direction: Vec2D = .{ .x = 0, .y = -1 };

    var previousPDs = std.ArrayList(PositionDirection).init(allocator);
    defer previousPDs.deinit();
    try previousPDs.append(.{ .position = guardStartingPosition, .direction = direction });

    while (move(grid, guardPosition, direction)) |tuplePositionDirection| {
        guardPosition = tuplePositionDirection.position;
        direction = tuplePositionDirection.direction;

        if (containsPD(previousPDs, .{ .position = guardPosition, .direction = direction })) {
            return true;
        }
        try previousPDs.append(.{ .position = guardPosition, .direction = direction });
    }
    return false;
}

pub fn main() !void {
    const file_path = "part2.txt";

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var bufReader = std.io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var arrayListGrid = std.ArrayList([]u8).init(allocator);

    var guardStartingPosition: Vec2D = undefined;

    var lineNumber: usize = 0;
    while (true) {
        const line = reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize)) catch break;
        for (0..line.len) |index| {
            if (line[index] == '^') {
                const indexI32: i32 = @intCast(index);
                const lineNumberI32: i32 = @intCast(lineNumber);
                guardStartingPosition = .{ .x = indexI32, .y = lineNumberI32 };
                line[index] = '.';
            }
        }
        try arrayListGrid.append(line);
        lineNumber += 1;
    }

    const width: i32 = @intCast(arrayListGrid.items[0].len);
    const height: i32 = @intCast(arrayListGrid.items.len);
    const slice = try arrayListGrid.toOwnedSlice();
    const grid: Grid = .{ .grid = slice, .width = width, .height = height };
    defer allocator.free(grid.grid);

    var direction: Vec2D = .{ .x = 0, .y = -1 };
    var uniqueGuardPositions = std.ArrayList(Vec2D).init(allocator);
    try uniqueGuardPositions.append(guardStartingPosition);

    var guardPosition = guardStartingPosition;
    while (move(grid, guardPosition, direction)) |tuplePositionDirection| {
        guardPosition = tuplePositionDirection.position;
        direction = tuplePositionDirection.direction;
        if (!contains(uniqueGuardPositions, guardPosition)) {
            try uniqueGuardPositions.append(guardPosition);
        }
    }

    var obstaclePositionsForLoop: u32 = 0;
    for (uniqueGuardPositions.items) |position| {
        const xUsize: usize = @intCast(position.x);
        const yUsize: usize = @intCast(position.y);
        grid.grid[yUsize][xUsize] = '#';
        if (try isLoop(grid, guardStartingPosition)) {
            obstaclePositionsForLoop += 1;
        }
        grid.grid[yUsize][xUsize] = '.';
    }
    std.debug.print("result: {d}\n", .{obstaclePositionsForLoop});
}
