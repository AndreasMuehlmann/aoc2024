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

fn removeWhenContained(list: *std.ArrayList(i32), value: i32) void {
    for (0..list.items.len) |index| {
        if (list.items[index] == value) {
            _ = list.swapRemove(index);
            break;
        }
    }
}

fn areNodesReachable(adjacencyMatrix: []const []const i32, node: i32, toCheckNodes: *std.ArrayList(i32), visited: *[]bool) bool {
    const nodeUsize: usize = @intCast(node);
    visited.*[nodeUsize] = true;
    for (0..adjacencyMatrix[nodeUsize].len) |index| {
        if (adjacencyMatrix[nodeUsize][index] >= 0) {
            const indexI32: i32 = @intCast(index);

            removeWhenContained(toCheckNodes, indexI32);
            if (toCheckNodes.items.len == 0) {
                return true;
            }
            if (!visited.*[index] and areNodesReachable(adjacencyMatrix, indexI32, toCheckNodes, visited)) {
                return true;
            }
        }
    }
    return false;
}

fn isUpdateCorrect(adjacencyMatrix: []const []const i32, update: *std.ArrayList(i32)) !bool {
    var areAllStepsCorrect = true;
    while (update.items.len > 1) {
        const first = update.orderedRemove(0);
        var updateClone = try update.clone();
        var visited = try allocator.alloc(bool, adjacencyMatrix.len);
        @memset(visited, false);
        if (!areNodesReachable(adjacencyMatrix, first, &updateClone, &visited)) {
            std.debug.print("got false\n", .{});
        }
        areAllStepsCorrect = areAllStepsCorrect and areNodesReachable(adjacencyMatrix, first, &updateClone, &visited);
        allocator.free(visited);
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
            for (update.items) |value| {
                std.debug.print("{d},", .{value});
            }
            std.debug.print("\n", .{});
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
