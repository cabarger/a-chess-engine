//! Toy chess engine
//! Caleb Barger -- 09/10/23

const std = @import("std");
const ascii = std.ascii;

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
};

const Piece = struct {
    type: PieceType,
    pos: @Vector(2, u8),
};

const PieceSet = struct {
    pieces: [16]Piece,
    piece_count: u8,
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
    if (col_index < 0 or col_index > 7 or row < 1 or row > 8) {
        std.debug.print("Bad pos ({c},{d})\n", .{ col_chr, row });
        unreachable;
    }
    return @Vector(2, u8){ 8 - row, @intCast(col_index) };
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

fn initBoard(board: []PieceHandle, piece_sets: []PieceSet) void {
    for (board) |*piece_handle|
        piece_handle.* = PieceHandle{ .set_color = SetColor.white, .piece_index = null };

    for (0..2) |set_color_index| {
        for (piece_sets[set_color_index].pieces, 0..) |piece, piece_index| {
            board[piece.pos[0] * 8 + piece.pos[1]] = PieceHandle{
                .set_color = @enumFromInt(set_color_index),
                .piece_index = @intCast(piece_index),
            };
        }
    }
}

fn pieceHandleFromCoords(board: []PieceHandle, coords: @Vector(2, u8)) *PieceHandle {
    if (coords[0] < 8 and coords[1] < 8)
        return @ptrCast(board.ptr + coords[0] * 8 + coords[1]);
    unreachable;
}

fn pieceFromHandle(piece_handle: PieceHandle, piece_sets: []PieceSet) ?*Piece {
    var result: ?*Piece = null;
    if (piece_handle.piece_index != null)
        result = &piece_sets[@intFromEnum(piece_handle.set_color)].pieces[piece_handle.piece_index.?];
    return result;
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

    piece_handle.piece_index = null; // Invalidate piece_index (piece handle)
}

fn drawBoard(stdout: anytype, board: []PieceHandle, piece_sets: []PieceSet) !void {
    // Horizontal border
    try stdout.writeAll("  +");
    for (0..8 * 3) |_|
        try stdout.writeByte('-');
    try stdout.writeAll("+\n");

    for (0..8) |row_index| {
        try stdout.print("{d} |", .{8 - row_index}); // Vertical border item
        for (0..8) |col_index| {
            const piece_handle = pieceHandleFromCoords(board, @Vector(2, u8){ @intCast(row_index), @intCast(col_index) });
            const piece = pieceFromHandle(piece_handle.*, piece_sets);
            try stdout.writeByte(' ');
            if (piece == null) {
                try stdout.writeByte('.');
            } else {
                switch (piece_handle.set_color) {
                    .white => try stdout.writeByte(ascii.toUpper(@tagName(piece.?.type)[0])),
                    .black => try stdout.writeByte(@tagName(piece.?.type)[0]),
                }
            }
            try stdout.writeByte(' ');
        }
        try stdout.writeAll("|\n");
    }

    // Another horizontal border
    try stdout.writeAll("  +");
    for (0..8 * 3) |_|
        try stdout.writeByte('-');
    try stdout.writeAll("+\n");

    try stdout.writeAll("   ");
    for (0..8) |col_index|
        try stdout.print(" {c} ", .{'a' + @as(u8, @intCast(col_index))});
    try stdout.writeByte('\n');
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var board: [64]PieceHandle = undefined;
    var piece_sets: [2]PieceSet = undefined;
    try initPieceSets(&piece_sets);
    initBoard(&board, &piece_sets);

    // std.debug.assert(@reduce(.And, piece_sets[0].pieces[8].pos == @Vector(2, u8){ 7, 0 }));
    movePiece(&board, &piece_sets, boardToMemCoords('a', 2), boardToMemCoords('a', 4));

    try drawBoard(stdout, &board, &piece_sets);
}
