const std = @import("std");
const allocator = std.heap.page_allocator;

fn max(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}

fn print2DArray(array: []const []const i32) void {
    for (array) |innerArray| {
        for (innerArray) |value| {
            std.debug.print("{d},", .{value});
        }
        std.debug.print("\n", .{});
    }
}

fn contains(list: std.ArrayList(i32), value: i32) ?usize {
    for (0..list.items.len) |index| {
        if (list.items[index] == value) {
            return index;
        }
    }
    return null;
}

fn removeWhenContained(list: *std.ArrayList(i32), value: i32) void {
    if (contains(list.*, value)) |index| {
        _ = list.swapRemove(index);
    }
}

fn dfs(adjacencyMatrix: []const []const i32, node: i32, allowedNodes: std.ArrayList(i32), visited: *std.ArrayList(i32)) !void {
    try visited.append(node);
    const nodeUsize: usize = @intCast(node);
    for (0..adjacencyMatrix[nodeUsize].len) |index| {
        if (adjacencyMatrix[nodeUsize][index] >= 0) {
            const indexI32: i32 = @intCast(index);
            if (contains(allowedNodes, indexI32) != null and contains(visited.*, indexI32) == null) {
                try dfs(adjacencyMatrix, indexI32, allowedNodes, visited);
            }
        }
    }
}

fn areNodesReachable(adjacencyMatrix: []const []const i32, node: i32, allowedNodes: std.ArrayList(i32), toCheckNodes: *std.ArrayList(i32)) !bool {
    var visited = std.ArrayList(i32).init(allocator);
    try dfs(adjacencyMatrix, node, allowedNodes, &visited);
    for (toCheckNodes.items) |toCheckNode| {
        if (contains(visited, toCheckNode) == null) {
            visited.deinit();
            return false;
        }
    }
    visited.deinit();
    return true;
}

fn isUpdateCorrect(adjacencyMatrix: []const []const i32, update: *std.ArrayList(i32)) !bool {
    var areAllStepsCorrect = true;
    const otherUpdateClone = try update.clone();
    while (update.items.len > 1) {
        const first = update.orderedRemove(0);
        var updateClone = try update.clone();
        areAllStepsCorrect = areAllStepsCorrect and try areNodesReachable(adjacencyMatrix, first, otherUpdateClone, &updateClone);
    }
    return areAllStepsCorrect;
}

pub fn main() !void {
    const file_path = "part1.txt";

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var bufReader = std.io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var edges = std.ArrayList([]i32).init(allocator);
    defer edges.deinit();
    var updates = std.ArrayList(std.ArrayList(i32)).init(allocator);
    defer updates.deinit();

    var readingEdges = true;

    var maxNode: i32 = -1;

    while (true) {
        const line = reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize)) catch break;

        if (line.len == 0) {
            readingEdges = false;
            continue;
        }

        if (readingEdges) {
            var tokenizer = std.mem.tokenize(u8, line, &[_]u8{'|'});
            const outgoingNode = try std.fmt.parseInt(i32, tokenizer.next().?, 10);
            const ingoingNode = try std.fmt.parseInt(i32, tokenizer.next().?, 10);

            maxNode = max(max(maxNode, outgoingNode), ingoingNode);

            const edge = try allocator.alloc(i32, 2);
            edge[0] = outgoingNode;
            edge[1] = ingoingNode;
            try edges.append(edge);
        } else {
            var tokenizer = std.mem.tokenize(u8, line, &[_]u8{','});
            var update = std.ArrayList(i32).init(allocator);
            while (tokenizer.next()) |stringNode| {
                const node = try std.fmt.parseInt(i32, stringNode, 10);
                try update.append(node);
            }
            try updates.append(update);
        }
    }

    var lengthAdjacencyMatrix: usize = @intCast(maxNode);
    lengthAdjacencyMatrix += 1;

    var adjacencyMatrix = try allocator.alloc([]i32, lengthAdjacencyMatrix);
    for (0..adjacencyMatrix.len) |index| {
        adjacencyMatrix[index] = try allocator.alloc(i32, lengthAdjacencyMatrix);
        @memset(adjacencyMatrix[index], -1);
    }

    for (edges.items) |edge| {
        const outgoingNode: usize = @intCast(edge[0]);
        const ingoingNode: usize = @intCast(edge[1]);
        adjacencyMatrix[outgoingNode][ingoingNode] = 1;
    }

    var result: i32 = 0;
    for (updates.items) |update| {
        var clonedUpdate = try update.clone();
        if (try isUpdateCorrect(adjacencyMatrix, &clonedUpdate)) {
            result += update.items[update.items.len / 2];
        }
    }

    for (0..edges.items.len) |edgesIndex| {
        allocator.free(edges.items[edgesIndex]);
    }

    for (0..updates.items.len) |updateIndex| {
        updates.items[updateIndex].deinit();
    }

    std.debug.print("result: {d}\n", .{result});
}
