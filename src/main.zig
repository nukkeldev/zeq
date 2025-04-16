const std = @import("std");
const lib = @import("comptime_string_parsing_lib");

pub fn main() !void {
    var tokenizer = Tokenizer.init("16.756");

    std.debug.print("{any}", .{tokenizer.nextToken()});
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

    const Result = struct {
        err: ?Error = null,
        err_index: ?usize = null,
        count: usize = 0,
    };
    const Error = error{ UnrecognizedToken, Number_TooManyDecimalPoints };

    // Initialization

    pub fn init(input: [:0]const u8) Self {
        return Self{ .buffer = input };
    }

    // Tokenizing

    pub fn nextToken(self: *Self) Error!?Token {
        const inc = struct {
            pub fn f(i: *usize) usize {
                i.* += 1;
                return i.*;
            }
        }.f;

        out: switch (self.buffer[self.index]) {
            // EOF
            0 => {
                return null;
            },
            // Whitespace
            ' ', '\t', '\n' => {
                continue :out self.buffer[inc(&self.index)];
            },
            // Numbers
            '0'...'9' => |c| {
                var token = Token{ .@"#" = @floatFromInt(c - '0') };
                self.index += 1;

                var fractional = false;
                var decimal_index: ?usize = null;

                s: switch (self.buffer[self.index]) {
                    '0'...'9' => |n| {
                        token.@"#" = token.@"#" * 10 + @as(f32, @floatFromInt(n - '0'));
                        continue :s self.buffer[inc(&self.index)];
                    },
                    '.' => {
                        if (fractional) {
                            return error.Number_TooManyDecimalPoints;
                        }

                        fractional = true;
                        decimal_index = self.index;

                        continue :s self.buffer[inc(&self.index)];
                    },
                    else => {
                        break :s;
                    },
                }

                if (decimal_index) |i| {
                    token.@"#" = token.@"#" / std.math.pow(f32, 10, @as(f32, @floatFromInt(self.index - i)) - 1);
                }

                return token;
            },
            // Plus
            '+' => {
                self.index += 1;
                return .@"+";
            },
            // Minus
            '-' => {
                self.index += 1;
                return .@"-";
            },
            // Times
            '*' => {
                self.index += 1;
                return .@"*";
            },
            // Divide
            '/' => {
                self.index += 1;
                return .@"/";
            },
            // Exponent
            '^' => {
                self.index += 1;
                return .@"^";
            },
            // Left Parenthese
            '(' => {
                self.index += 1;
                return .@"(";
            },
            // Right Parenthese
            ')' => {
                self.index += 1;
                return .@")";
            },
            else => |_| {
                return Error.UnrecognizedToken;
            },
        }
    }

    pub fn parse(input: [:0]const u8, output: *[]Token) Result {
        var self = init(input);
        var result: Result = .{};

        while (result.count < output.len) {
            const @"token?" = self.nextToken() catch |e| {
                result.err = e;
                result.err_index = self.index;
                return result;
            };

            if (@"token?") |token| {
                output.*[result.count] = token;
                result.count += 1;
            } else {
                break;
            }
        }

        return result;
    }

    pub fn parseToArray(comptime MAX_TOKENS: comptime_int, input: [:0]const u8) struct { Result, [MAX_TOKENS]Token } {
        var out: [MAX_TOKENS]Token = undefined;
        var slice: []Token = out[0..];

        return .{ Self.parse(input, &slice), out };
    }
};

pub fn comptimeParse(comptime string: []const u8) Tokenizer(string.len).Result {
    // Pass the comptime-known string length to the parsing method.
    return parse(string, string.len);
}

pub fn parse(string: []const u8, max_len: comptime_int) Tokenizer(max_len).Result {
    // Create a parser and parse the string.
    var parser = Tokenizer(max_len).init(string);
    return parser.parse();
}

// Tests

fn testTokenization(comptime input: [:0]const u8, expected: anytype) !void {
    try std.testing.expectEqual(Tokenizer.parseToArray(expected[0].count, input), expected);
}

test "tokenizing" {
    try testTokenization("", .{
        Tokenizer.Result{ .count = 0 },
        [_]Tokenizer.Token{},
    });

    // Numbers

    try testTokenization("1", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.{ .@"#" = 1.0 }},
    });
    try testTokenization("1.", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.{ .@"#" = 1.0 }},
    });
    try testTokenization("12", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.{ .@"#" = 12.0 }},
    });
    try testTokenization("12.3", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.{ .@"#" = 12.3 }},
    });

    // Operators

    try testTokenization("+", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.@"+"},
    });
    try testTokenization("-", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.@"-"},
    });
    try testTokenization("*", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.@"*"},
    });
    try testTokenization("/", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.@"/"},
    });
    try testTokenization("^", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.@"^"},
    });

    // Parentheses

    try testTokenization("(", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.@"("},
    });
    try testTokenization(")", .{
        Tokenizer.Result{ .count = 1 },
        [_]Tokenizer.Token{.@")"},
    });

    // Multiple

    try testTokenization("(1 + 1 / 2)", .{
        Tokenizer.Result{ .count = 7 },
        [_]Tokenizer.Token{ .@"(", .{ .@"#" = 1.0 }, .@"+", .{ .@"#" = 1.0 }, .@"/", .{ .@"#" = 2.0 }, .@")" },
    });
}
