const std = @import("std");
const lib = @import("comptime_string_parsing_lib");

pub fn main() !void {
    const res = comptime_parse("1 + 2");

    if (res.err) |err| {
        std.debug.print("Failed parse with error: {any}\n", .{err});
    } else {
        for (res.parsed[0..res.tokens], 0..) |tok, i| {
            std.debug.print("Token #{d}: {any}\n", .{ i, tok });
        }
    }
}

const Token = union(enum) {
    Number: u32,
    Op_Plus,
};

pub fn Parser(max_len: comptime_int) type {
    return struct {
        // Variables

        input: []const u8,
        output: [max_len]Token,
        input_pos: usize = 0,
        output_pos: usize = 0,

        err: ?Error = null,

        // Types

        const Self = @This();
        const Result = struct {
            err: ?Error,
            tokens: usize,
            parsed: [max_len]Token,
        };
        const Error = union(enum) {
            UnrecognizedToken: u8,
        };

        // Initialization

        pub fn init(input: []const u8) Self {
            return Self{
                .input = input,
                .output = undefined,
            };
        }

        // Parsing

        fn eat(self: *Self) bool {
            const eaten = if (self.input_pos == self.input.len) null else self.input[self.input_pos];
            if (eaten) |char| {
                self.input_pos += 1;

                // Ignore whitespace entirely.
                if (std.ascii.isWhitespace(char)) {
                    return true;
                }

                self.output[self.output_pos] = switch (char) {
                    '0'...'9' => .{ .Number = char - '0' },
                    '+' => .Op_Plus,
                    else => {
                        self.err = .{ .UnrecognizedToken = char };
                        return false;
                    },
                };

                std.debug.print("'{c}' -> {any}\n", .{ char, self.output[self.output_pos] });

                // Increment the output position if we successfully parsed a token.
                // Output position is implicitly bounded by the input position.
                self.output_pos += 1;
            }

            return eaten != null;
        }

        pub fn parse_to_end(self: *Self) Result {
            while (eat(self) and self.err == null) {}

            std.debug.print("Parsed: {any}\n", .{self.output[0..self.output_pos]});

            return .{ .err = self.err, .tokens = self.output_pos, .parsed = self.output };
        }
    };
}

pub fn comptime_parse(comptime string: []const u8) Parser(string.len).Result {
    // Pass the comptime-known string length to the parsing method.
    return parse(string, string.len);
}

pub fn parse(string: []const u8, max_len: comptime_int) Parser(max_len).Result {
    // Create a parser and parse the string.
    var parser = Parser(max_len).init(string);
    return parser.parse_to_end();
}
