//! Toy chess engine
//! Caleb Barger -- 09/10/23

const std = @import("std");
const ascii = std.ascii;

const board_width = 2;
const board_height = 2;

const PieceType = enum(u8) {
    pawn,
    night,
    bishop,
    rook,
    queen,
    king,
};

const SetColor = enum(u8) {
    white = 0,
    black = 1,
    none = 2,
};

const Piece = struct {
    type: PieceType,
    pos: @Vector(2, u8),
};

const PieceSet = struct {
    pieces: [2]Piece, // 16
    piece_count: u8 = 2, // 16
};

const PieceHandle = struct {
    set_color: SetColor,
    piece_index: ?u8,
};

fn memToBoardCoords(row_index: u8, col_index: u8) @Vector(2, u8) {
    if (col_index > 7 or row_index > 8) {
        std.debug.print("Bad pos ({d},{d})\n", .{ row_index, col_index });
        unreachable;
    }
    return @Vector(2, u8){ 'a' + col_index, 8 - row_index };
}

fn boardToMemCoords(col_chr: u8, row: u8) @Vector(2, u8) {
    const col_index: i8 = @intCast(ascii.toLower(col_chr) - 'a');
    if (col_index < 0 or col_index > board_width - 1 or row < 1 or row > board_height) {
        std.debug.print("Bad pos ({c},{d})\n", .{ col_chr, row });
        unreachable;
    }
    return @Vector(2, u8){ board_height - row, @intCast(col_index) };
}

fn initPieceSets(piece_sets: []PieceSet) !void {
    for (0..8) |col_index|
        piece_sets[@intFromEnum(SetColor.white)].pieces[col_index] =
            Piece{ .type = .pawn, .pos = boardToMemCoords(@intCast('a' + col_index), 2) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[8] = Piece{ .type = .rook, .pos = boardToMemCoords('a', 1) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[9] = Piece{ .type = .night, .pos = boardToMemCoords('b', 1) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[10] = Piece{ .type = .bishop, .pos = boardToMemCoords('c', 1) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[11] = Piece{ .type = .queen, .pos = boardToMemCoords('d', 1) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[12] = Piece{ .type = .king, .pos = boardToMemCoords('e', 1) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[13] = Piece{ .type = .bishop, .pos = boardToMemCoords('f', 1) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[14] = Piece{ .type = .night, .pos = boardToMemCoords('g', 1) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[15] = Piece{ .type = .rook, .pos = boardToMemCoords('h', 1) };

    for (0..8) |col_index|
        piece_sets[@intFromEnum(SetColor.black)].pieces[col_index] =
            Piece{ .type = .pawn, .pos = boardToMemCoords(@intCast('a' + col_index), 7) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[8] = Piece{ .type = .rook, .pos = boardToMemCoords('a', 8) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[9] = Piece{ .type = .night, .pos = boardToMemCoords('b', 8) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[10] = Piece{ .type = .bishop, .pos = boardToMemCoords('c', 8) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[12] = Piece{ .type = .king, .pos = boardToMemCoords('d', 8) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[11] = Piece{ .type = .queen, .pos = boardToMemCoords('e', 8) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[13] = Piece{ .type = .bishop, .pos = boardToMemCoords('f', 8) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[14] = Piece{ .type = .night, .pos = boardToMemCoords('g', 8) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[15] = Piece{ .type = .rook, .pos = boardToMemCoords('h', 8) };
}

/// Setup piece sets for 2x2 board
fn initPieceSetsSmol(piece_sets: []PieceSet) !void {
    piece_sets[@intFromEnum(SetColor.white)].pieces[0] =
        Piece{ .type = .pawn, .pos = boardToMemCoords('a', 1) };
    piece_sets[@intFromEnum(SetColor.white)].pieces[1] =
        Piece{ .type = .pawn, .pos = boardToMemCoords('b', 1) };

    piece_sets[@intFromEnum(SetColor.black)].pieces[0] =
        Piece{ .type = .pawn, .pos = boardToMemCoords('a', 2) };
    piece_sets[@intFromEnum(SetColor.black)].pieces[1] =
        Piece{ .type = .pawn, .pos = boardToMemCoords('b', 2) };
}

fn initBoard(board: []PieceHandle, piece_sets: []PieceSet) void {
    for (board) |*piece_handle|
        piece_handle.* = PieceHandle{ .set_color = SetColor.none, .piece_index = null };

    for (0..2) |set_color_index| {
        for (piece_sets[set_color_index].pieces, 0..) |piece, piece_index| {
            board[piece.pos[0] * board_width + piece.pos[1]] = PieceHandle{
                .set_color = @enumFromInt(set_color_index),
                .piece_index = @intCast(piece_index),
            };
        }
    }
}

fn pieceHandleFromCoords(board: []PieceHandle, coords: @Vector(2, u8)) *PieceHandle {
    if (coords[0] < board_height and coords[1] < board_width)
        return @ptrCast(board.ptr + coords[0] * board_width + coords[1]);
    unreachable;
}

fn pieceFromHandle(piece_handle: PieceHandle, piece_sets: []PieceSet) ?*Piece {
    var result: ?*Piece = null;
    if (piece_handle.piece_index != null)
        result = &piece_sets[@intFromEnum(piece_handle.set_color)].pieces[piece_handle.piece_index.?];
    return result;
}

fn validMoves(stdout: anytype, board: []PieceHandle, piece_sets: []PieceSet, mem_coords: @Vector(2, u8)) !void {
    const piece_handle = pieceHandleFromCoords(board, mem_coords).*;
    const piece = pieceFromHandle(piece_handle, piece_sets) orelse unreachable;
    const board_coords = memToBoardCoords(piece.pos[0], piece.pos[1]);

    switch (piece.type) {
        .pawn => { // TODO(caleb): En passant
            switch (piece_handle.set_color) { // TODO(caleb): Don't switch on color, do this with some math...
                .white => {
                    if (board[(piece.pos[0] - 1) * 8 + piece.pos[1]].piece_index == null) { // There isn't a piece at row + 1 {
                        try stdout.print("{c},{d}\n", .{ board_coords[0], board_coords[1] + 1 });
                    }
                    if (board_coords[1] == 2) { // Pawn is on the second rank
                        if (board[(piece.pos[0] - 2) * 8 + piece.pos[1]].piece_index == null) // There isn't a piece at row + 2
                            try stdout.print("{c},{d}\n", .{ board_coords[0], board_coords[1] + 2 });
                    }
                },
                .black => {
                    if (board[(piece.pos[0] + 1) * 8 + piece.pos[1]].piece_index == null) { // There isn't a piece at row + 1 {
                        try stdout.print("{c},{d}\n", .{ board_coords[0], board_coords[1] - 1 });
                    }

                    if (board_coords[1] == 7) { // Pawn is on the seventh rank
                        if (board[(piece.pos[0] + 2) * 8 + piece.pos[1]].piece_index == null) // There isn't a piece at row + 2
                            try stdout.print("{c},{d}\n", .{ board_coords[0], board_coords[1] - 2 });
                    }
                },
                else => unreachable,
            }
        },
        .night => {
            for ([_]@Vector(2, i8){
                @Vector(2, i8){ -2, 1 }, @Vector(2, i8){ -2, -1 }, // Up
                @Vector(2, i8){ 1, 2 }, @Vector(2, i8){ -1, 2 }, // Right
                @Vector(2, i8){ 2, 1 }, @Vector(2, i8){ 2, -1 }, // Down
                @Vector(2, i8){ 1, -2 }, @Vector(2, i8){ -1, -2 }, // Left
            }) |d_pos| {
                const row_index: i8 = @intCast(piece.pos[0]);
                const col_index: i8 = @intCast(piece.pos[1]);
                if (row_index + d_pos[0] < 8 and row_index + d_pos[0] >= 0 and
                    col_index + d_pos[1] < 8 and col_index + d_pos[1] >= 0 and
                    board[@intCast((row_index + d_pos[0]) * 8 + col_index + d_pos[1])].set_color != piece_handle.set_color)
                {
                    const new_board_coords = memToBoardCoords(@intCast(row_index + d_pos[0]), @intCast(col_index + d_pos[1]));
                    try stdout.print("{c},{d}\n", .{ new_board_coords[0], new_board_coords[1] });
                }
            }
        },
        .bishop => {
            for ([_]@Vector(2, i8){
                @Vector(2, i8){ -1, -1 }, // Top left
                @Vector(2, i8){ -1, 1 }, // Top right
                @Vector(2, i8){ 1, -1 }, // Bottom left
                @Vector(2, i8){ 1, 1 }, // Bottom right
            }) |d_pos| {
                var row_index: i8 = @intCast(piece.pos[0]);
                var col_index: i8 = @intCast(piece.pos[1]);
                while ((row_index + d_pos[0] < 8 and row_index + d_pos[0] >= 0) and
                    (col_index + d_pos[1] < 8 and col_index + d_pos[1] >= 0) and
                    (board[@intCast((row_index + d_pos[0]) * 8 + col_index + d_pos[1])].set_color != piece_handle.set_color))
                {
                    const new_board_coords = memToBoardCoords(@intCast(row_index + d_pos[0]), @intCast(col_index + d_pos[1]));
                    try stdout.print("{c},{d}\n", .{ new_board_coords[0], new_board_coords[1] });

                    if (board[@intCast((row_index + d_pos[0]) * 8 + col_index + d_pos[1])].set_color != .none)
                        break;

                    row_index += d_pos[0];
                    col_index += d_pos[1];
                }
            }
        },
        else => unreachable,
    }
}

fn movePiece(
    board: []PieceHandle,
    piece_sets: []PieceSet,
    from_pos: @Vector(2, u8),
    to_pos: @Vector(2, u8),
) void {
    // TODO(caleb): Validate from coords
    var piece_handle = pieceHandleFromCoords(board, from_pos);
    var piece = pieceFromHandle(piece_handle.*, piece_sets);
    if (piece == null) {
        const board_coords = memToBoardCoords(from_pos[0], from_pos[1]);
        std.debug.print("No piece at ({c},{d})\n", .{ board_coords[0], board_coords[1] });
        unreachable;
    }

    // TODO(caleb): logistics of moving a piece and all that nonsense

    // Update piece pos
    piece.?.pos = to_pos;

    // Update piece handle(s) at start and end
    board[to_pos[0] * 8 + to_pos[1]] = piece_handle.*;

    // Clear piece handle
    piece_handle.* = PieceHandle{ .piece_index = null, .set_color = .none };
}

fn drawBoard(stdout: anytype, board: []PieceHandle, piece_sets: []PieceSet) !void {
    try stdout.writeAll("  +");
    for (0..board_width * 3) |_|
        try stdout.writeByte('-');
    try stdout.writeAll("+\n");

    for (0..board_height) |row_index| {
        try stdout.print("{d} |", .{board_height - row_index});
        for (0..board_width) |col_index| {
            const piece_handle = pieceHandleFromCoords(board, @Vector(2, u8){ @intCast(row_index), @intCast(col_index) });
            const piece = pieceFromHandle(piece_handle.*, piece_sets);
            try stdout.writeByte(' ');
            if (piece == null) {
                try stdout.writeByte('.');
            } else {
                switch (piece_handle.set_color) {
                    .white => try stdout.writeByte(ascii.toUpper(@tagName(piece.?.type)[0])),
                    .black => try stdout.writeByte(@tagName(piece.?.type)[0]),
                    .none => unreachable,
                }
            }
            try stdout.writeByte(' ');
        }
        try stdout.writeAll("|\n");
    }

    try stdout.writeAll("  +");
    for (0..board_width * 3) |_|
        try stdout.writeByte('-');
    try stdout.writeAll("+\n");

    try stdout.writeAll("   ");
    for (0..board_width) |col_index|
        try stdout.print(" {c} ", .{'a' + @as(u8, @intCast(col_index))});
    try stdout.writeByte('\n');
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var board: [board_width * board_height]PieceHandle = undefined;
    var piece_sets: [2]PieceSet = undefined;
    try initPieceSetsSmol(&piece_sets);
    initBoard(&board, &piece_sets);

    // movePiece(&board, &piece_sets, boardToMemCoords('e', 2), boardToMemCoords('e', 3));
    // movePiece(&board, &piece_sets, boardToMemCoords('g', 2), boardToMemCoords('g', 3));
    // movePiece(&board, &piece_sets, boardToMemCoords('f', 1), boardToMemCoords('c', 4));

    // movePiece(&board, &piece_sets, boardToMemCoords(, ));

    // try validMoves(stdout, &board, &piece_sets, boardToMemCoords('c', 4));
    try drawBoard(stdout, &board, &piece_sets);
}
