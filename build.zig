const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("WFC", .{ .root_source_file = b.path("src/WFC.zig") });
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    _ = optimize;
    _ = target;
}
