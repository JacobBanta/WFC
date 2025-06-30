const std = @import("std");
pub fn create(comptime tileSet: type, comptime SIZE_X: comptime_int, comptime SIZE_Y: comptime_int) type {
    return struct {
        pub const Tile = union(enum) {
            collapsed: tileSet,
            uncollapsed: T,
            pub const T = @Type(std.builtin.Type{ .int = .{ .signedness = .unsigned, .bits = @typeInfo(tileSet).@"enum".fields.len } });
        };

        pub fn computeWFC(board: *[SIZE_Y][SIZE_X]Tile, rand: std.Random) void {
            for (0..SIZE_X) |x| {
                for (0..SIZE_Y) |y| {
                    collapse(board, x, y);
                }
            }
            while (true) {
                const p = getLowestEntropy(board.*, rand) catch break;
                choose(board, p[0], p[1], rand);
                collapse(board, p[0], p[1]);
            }
        }

        pub fn collapse(board: *[SIZE_Y][SIZE_X]Tile, x: usize, y: usize) void {
            switch (board[y][x]) {
                .collapsed => |val| {
                    for (0..@typeInfo(tileSet).@"enum".fields.len) |n| {
                        if (@intFromEnum(val) == n) continue;
                        if (@intFromEnum(val) > n) {
                            collapseDistance(board, x, y, @enumFromInt(n), @intFromEnum(val) - n);
                        } else {
                            collapseDistance(board, x, y, @enumFromInt(n), n - @intFromEnum(val));
                        }
                    }
                },
                .uncollapsed => |val| {
                    if (val == 0) unreachable;
                    if (std.math.isPowerOfTwo(val)) {
                        board[y][x] = Tile{ .collapsed = @enumFromInt(std.math.log2_int(Tile.T, val)) };
                        return collapse(board, x, y);
                    }
                },
            }
        }

        pub fn collapseDistance(board: *[SIZE_Y][SIZE_X]Tile, x: usize, y: usize, not: tileSet, within: usize) void {
            for (0..within) |xOffset| {
                for (0..within - xOffset) |yOffset| {
                    if (y + yOffset < SIZE_Y and x + xOffset < SIZE_X) {
                        if (board[y + yOffset][x + xOffset] == .uncollapsed) {
                            if (board[y + yOffset][x + xOffset].uncollapsed & @as(@TypeOf(board[y + yOffset][x + xOffset].uncollapsed), 1) << @intFromEnum(not) > 0) {
                                board[y + yOffset][x + xOffset].uncollapsed &= (~(@as(@TypeOf(board[y + yOffset][x + xOffset].uncollapsed), 1) << @intFromEnum(not)));
                                collapse(board, x + xOffset, y + yOffset);
                            }
                        }
                    }
                    if (x >= xOffset and y >= yOffset) {
                        if (board[y - yOffset][x - xOffset] == .uncollapsed) {
                            if (board[y - yOffset][x - xOffset].uncollapsed & @as(@TypeOf(board[y - yOffset][x - xOffset].uncollapsed), 1) << @intFromEnum(not) > 0) {
                                board[y - yOffset][x - xOffset].uncollapsed &= (~(@as(@TypeOf(board[y - yOffset][x - xOffset].uncollapsed), 1) << @intFromEnum(not)));
                                collapse(board, x - xOffset, y - yOffset);
                            }
                        }
                    }
                    if (x >= xOffset and y + yOffset < SIZE_Y) {
                        if (board[y + yOffset][x - xOffset] == .uncollapsed) {
                            if (board[y + yOffset][x - xOffset].uncollapsed & @as(@TypeOf(board[y + yOffset][x - xOffset].uncollapsed), 1) << @intFromEnum(not) > 0) {
                                board[y + yOffset][x - xOffset].uncollapsed &= (~(@as(@TypeOf(board[y + yOffset][x - xOffset].uncollapsed), 1) << @intFromEnum(not)));
                                collapse(board, x - xOffset, y + yOffset);
                            }
                        }
                    }
                    if (x + xOffset < SIZE_X and y >= yOffset) {
                        if (board[y - yOffset][x + xOffset] == .uncollapsed) {
                            if (board[y - yOffset][x + xOffset].uncollapsed & @as(@TypeOf(board[y - yOffset][x + xOffset].uncollapsed), 1) << @intFromEnum(not) > 0) {
                                board[y - yOffset][x + xOffset].uncollapsed &= (~(@as(@TypeOf(board[y - yOffset][x + xOffset].uncollapsed), 1) << @intFromEnum(not)));
                                collapse(board, x + xOffset, y - yOffset);
                            }
                        }
                    }
                }
            }
        }
        pub fn getLowestEntropy(board: [SIZE_Y][SIZE_X]Tile, rand: std.Random) ![2]usize {
            var lowestEntropy: usize = std.math.maxInt(usize);
            var counter: usize = 0;
            for (board) |row| {
                for (row) |tile| {
                    if (tile == .collapsed) continue;
                    const e = getEntropy(tile.uncollapsed);
                    if (e < lowestEntropy) {
                        lowestEntropy = e;
                        counter = 0;
                    }
                    if (e == lowestEntropy) {
                        counter += 1;
                    }
                }
            }
            counter = if (counter > 0) rand.uintLessThan(usize, counter) else 0;
            for (board, 0..) |row, yIndex| {
                for (row, 0..) |tile, xIndex| {
                    if (tile == .collapsed) continue;
                    const e = getEntropy(tile.uncollapsed);
                    if (e == lowestEntropy) {
                        if (counter == 0) {
                            return [2]usize{ xIndex, yIndex };
                        }
                        counter -= 1;
                    }
                }
            }
            if (lowestEntropy != std.math.maxInt(usize)) unreachable;
            return error.Done;
        }
        pub fn getEntropy(tile: Tile.T) usize {
            var bits: usize = 0;
            for (0..@typeInfo(tileSet).@"enum".fields.len) |i| {
                if ((tile >> @intCast(i)) & 1 == 1) {
                    bits += 1;
                }
            }
            return bits;
        }

        pub fn choose(board: *[SIZE_Y][SIZE_X]Tile, x: usize, y: usize, rand: std.Random) void {
            if (board[y][x] == .collapsed) unreachable;
            var bits: usize = 0;
            for (0..@typeInfo(tileSet).@"enum".fields.len) |i| {
                if ((board[y][x].uncollapsed >> @intCast(i)) & 1 == 1) {
                    bits += 1;
                }
            }
            const r = rand.uintLessThan(usize, bits);
            bits = r;
            for (0..@typeInfo(tileSet).@"enum".fields.len) |i| {
                if ((board[y][x].uncollapsed >> @intCast(i)) & 1 == 1) {
                    if (bits == 0) {
                        board[y][x] = Tile{ .collapsed = @enumFromInt(i) };
                        break;
                    }
                    bits -= 1;
                }
            }
        }
    };
}
