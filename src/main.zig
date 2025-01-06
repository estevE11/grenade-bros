const std = @import("std");

const Question = struct {
    question: []const u8,
    answer: []const u8,
};

const Questions = [_]Question{
    Question{ .question = "What is your name?", .answer = "John" },
    Question{ .question = "What is your age?", .answer = "25" },
    Question{ .question = "What is your favorite color?", .answer = "Blue" },
};

pub fn main() !void {
    try askQuestion();
}

pub fn askQuestion() !void {
    // create allocator
    const allocator = std.heap.page_allocator;


    for (Questions) |question| {
        std.debug.print("{s}\n", .{question.question});
        const answer = try readLine(&allocator);
        if (std.mem.eql(u8, answer, question.answer)) {
            std.debug.print("Correct!\n", .{});
        } else {
            std.debug.print("Incorrect! The correct answer is {s}.\n", .{question.answer});
        }
        allocator.free(answer);
    }
}

pub fn readLine(allocator: *const std.mem.Allocator) ![]const u8 {
    var stdin_file = std.io.getStdIn();
    var stdin = stdin_file.reader();

    // Read until newline (up to 1024 bytes):
    var buff: []u8 = try allocator.alloc(u8, 1024);
    if(try stdin.readUntilDelimiterOrEof(buff[0..], '\n')) |err| {
        return err;
    }

    return buff;
}
