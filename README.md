# zeq

> The below has yet to be fully implemented but is well on it's way.

Given an equation string, `zeq` creates a function that allows the equation to be evaluated at runtime for any inputs.
For instance, say that we have a frequently iterated equation i.e. $x=x_0+v_0t+\frac{1}{2}at^2$.
We would like to have it easily accessible in our codebase but don't want to maintain the headache
of continually translating between our maths and implementation. With `zeq` we can simply do the
following:

```zig
const position: fn (f32, f32, f32, f32) f32 = eq(f32, "x", "x = x_0 + v_0t + (1/2)at^2");

// =

fn position(x_0: f32, v_0: f32, a: f32, t: f32) f32 {
    return x_0 + (v_0 * t) + (0.5 * a * t * t);
}
```

While the above wasn't particularly useful, the `"x"` can be any variable present in the equation
and `zeq` will handle the algebra for us: 

```zig
const initial_position: fn (f32, f32, f32, f32) f32 = eq(f32, "x_0", "x = x_0 + v_0t + (1/2)at^2");

// =

fn initial_position(x: f32, v_0: f32, a: f32, t: f32) f32 {
    return x - (v_0 * t) - (0.5 * a * t * t);
}
```

What if we then have a new equation that we are in the process of refining and some bits just
don't compute correctly: enter _partial solutions + verbosity_. When using the `veq` function
instead, the generated function will then return an array of partial solutions corresponding
to their grouping in the equation:

```zig
const position: fn (f32, f32, f32, f32) f32 = veq(f32, "x", "x = x_0 + v_0t + (1/2)at^2");

// =

fn position(x_0: f32, v_0: f32, a: f32, t: f32) struct {
    solution: f32,
    partials: []struct { []const u8, f32 },
} {
    @"x_0" = x_0;
    @"v_0t" = (v_0 * t);
    @"0.5at^2" = (0.5 * a * t * t); // Constant-folding changes the string representation.

    return .{
        .solution = @"x_0" + @"v_0t" + @"0.5at^2",
        .partials = .{
            .{ "x_0", @"x_0" },
            .{ "v_0t", @"v_0t" },
            .{ "0.5at^2", @"0.5at^2" },
        };
    };
}
```