// Zixir Runtime Library (Phase 1)
// Core runtime support for compiled Zixir programs

const std = @import("std");

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

// Print utilities
pub fn print(msg: []const u8) void {
    std.debug.print("{s}", .{msg});
}

pub fn println(msg: []const u8) void {
    std.debug.print("{s}\n", .{msg});
}

pub fn print_int(n: i64) void {
    std.debug.print("{d}", .{n});
}

pub fn print_float(n: f64) void {
    std.debug.print("{d}", .{n});
}

// Array/List operations
pub fn list_sum(arr: []const f64) f64 {
    var sum: f64 = 0.0;
    for (arr) |item| {
        sum += item;
    }
    return sum;
}

pub fn list_product(arr: []const f64) f64 {
    var prod: f64 = 1.0;
    for (arr) |item| {
        prod *= item;
    }
    return prod;
}

pub fn dot_product(a: []const f64, b: []const f64) f64 {
    if (a.len != b.len) return 0.0;
    var sum: f64 = 0.0;
    for (a, b) |x, y| {
        sum += x * y;
    }
    return sum;
}

pub fn string_length(s: []const u8) i64 {
    return @intCast(s.len);
}

// Memory management helpers
pub fn alloc_array(comptime T: type, n: usize) ![]T {
    return try allocator.alloc(T, n);
}

pub fn free_array(arr: anytype) void {
    allocator.free(arr);
}

// Panic handler
pub fn panic(msg: []const u8, _error_return_trace: ?*std.builtin.StackTrace, _ret_addr: ?usize) noreturn {
    std.debug.print("Zixir panic: {s}\n", .{msg});
    std.process.exit(1);
}
