const std = @import("std");
const lib = @import("comptime_string_parsing_lib");

pub fn main() !void {
    var tokenizer = Tokenizer.init("16.756");

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

    const Error = error{ UnrecognizedToken, TooManyDecimalPoints };

    // Initialization

    pub fn init(input: [:0]const u8) Self {
        return Self{ .buffer = input };
    }

    // Tokenizing

    pub fn next_token(self: *Self) Error!?Token {
        const inc = struct {
            pub fn f(i: *usize) usize {
                i.* += 1;
                return i.*;
            }
        }.f;

        switch (self.buffer[self.index]) {
            0 => { // EOF
                return null;
            },
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
                    '.' | ',' => {
                        if (fractional) {
                            return error.TooManyDecimalPoints;
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

                self.index += 1;
                return token;
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

// Tests

const testing = struct {
    // Aliases

    const expect = std.testing.expect;
    const expectEqual = std.testing.expectEqual;
    const expectApproxEqAbs = std.testing.expectApproxEqAbs;

    // Helpers

    pub fn expectApproxEqAbsNullable(comptime T: type, expected: ?T, actual: ?T) !void {
        if (expected == null or actual == null) try expectEqual(expected, actual);
        try expectApproxEqAbs(expected.?, actual.?, std.math.floatEps(T));
    }
};

test "numbers" {
    const e = std.testing.expectEqual;
    const ef = struct {
        pub fn f(a: ?f32, b: ?f32) !void {
            if (a == null or b == null) {
                try std.testing.expect(a == b);
            }

            try std.testing.expectApproxEqAbs(a.?, b.?, std.math.floatEps(f32));
        }
    }.f;

    const t = struct {
        pub fn f(input: [:0]const u8) anyerror!?f32 {
            var tokenizer = Tokenizer.init(input);
            const result = try tokenizer.next_token();

            if (result) |token| {
                if (!std.mem.eql(u8, @tagName(token), "#")) {
                    return error.NaN;
                }

                return token.@"#";
            }

            return null;
        }
    }.f;

    try e(t(""), null);

    try ef(t("0") catch null, 0.0);
    try ef(t("0.") catch null, 0.0);
    try ef(t("0.0") catch null, 0.0);

    try ef(t("1") catch null, 1.0);
    try ef(t("123") catch null, 123.0);
    try ef(t("123.") catch null, 123.0);
    try ef(t("123.456") catch null, 123.456);
}
