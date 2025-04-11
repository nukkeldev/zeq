const std = @import("std");
const lib = @import("comptime_string_parsing_lib");

pub fn main() !void {
    var tokenizer = Tokenizer.init("123");

    std.debug.print("{any}", .{tokenizer.next_token()});
}

const Tokenizer = struct {
    const Self = @This();

    // State

    buffer: [:0]const u8,
    index: usize = 0,

    const Token = union(enum) {
        @"#": f32,
        @"+",
        @"-",
        @"*",
        @"/",
        @"^",
        @"(",
        @")",
    };

    // Errors

    const Error = error{
        UnrecognizedToken,
    };

    // Initialization

    pub fn init(input: [:0]const u8) Self {
        return Self{ .buffer = input };
    }

    // Tokenizing

    pub fn next_token(self: *Self) Error!?Token {
        switch (self.buffer[self.index]) {
            0 => { // EOF
                return null;
            },
            else => |_| {
                return Error.UnrecognizedToken;
            },
        }
    }

    // pub fn parse(self: *Self) Result {
    //     tokenize: switch (self.consume().?) {
    //         null => {
    //             // We have consumed the entire input.
    //         },
    //         '0'...'9' => {
    //             self.eat();
    //         },
    //         else => {},
    //     }

    //     std.debug.print("Parsed: {any}\n", .{self.output[0..self.output_pos]});

    //     return .{ .err = self.err, .tokens = self.output_pos, .parsed = self.output };
    // }
};

pub fn comptime_parse(comptime string: []const u8) Tokenizer(string.len).Result {
    // Pass the comptime-known string length to the parsing method.
    return parse(string, string.len);
}

pub fn parse(string: []const u8, max_len: comptime_int) Tokenizer(max_len).Result {
    // Create a parser and parse the string.
    var parser = Tokenizer(max_len).init(string);
    return parser.parse();
}
