const std = @import("std");

pub const Value = struct {
    pub fn set(self: @This(), value: []const u8) !void {
        _ = self;
        _ = value;
    }
};

pub const Embed = struct {
    pub fn template(self: @This(), tpl: Template) !void {
        _ = self;
        _ = tpl;
    }
};

pub const Compound = struct {
};

pub const SlotData = union(enum) {
    Number: u32,
    String: []const u8,
    Embed: *Template,
};

pub const Location = struct {
    start: usize,
    end: usize,
};

pub const Slot = struct {
    Data: ?std.ArrayList(SlotData) = null,
    Loc: Location,
};

pub const Template = struct {
    io: std.Io,
    alloc: std.mem.Allocator,
    slots_map: std.StringHashMap(Slot),
    slots_list: std.ArrayList(*Slot),
    str: []const u8,

    const State = enum {
        normal,
        directive,
    };

    fn isDirectiveCh(ch: u8) bool {
        return (ch >= '0' and ch <= '9') or
               (ch >= 'a' and ch <= 'z') or
               (ch >= 'A' and ch <= 'Z') or
               ch == '-';
    }

    pub fn load(comptime str: []const u8, io: std.Io, alloc: std.mem.Allocator) !Template {
        var tpl = Template {
            .io = io,
            .alloc = alloc,
            .slots_map = .init(alloc),
            .slots_list = try .initCapacity(alloc, 10),
            .str = str,
        };

        var state: State = .normal;
        var d_loc: Location = .{.start = 0, .end = 0};
        for (str, 0..) |ch, i| {
            if (state == .normal) {
                if (ch == '.') {
                    state = .directive;
                    d_loc.start = i;
                }
            }
            else if (state == .directive) {
                if (!isDirectiveCh(ch)) {
                    d_loc.end = i;
                    try tpl.slots_map.put(str[d_loc.start..d_loc.end], Slot {
                        .Data = null,
                        .Loc = d_loc,
                    });
                    try tpl.slots_list.append(alloc, tpl.slots_map.getPtr(str[d_loc.start..d_loc.end]).?);
                    state = .normal;
                }
            }
        }

        return tpl;
    }

    pub fn unload(self: *@This()) void {
        var it = self.slots_map.iterator();
        while (it.next()) |v| {
            if (v.value_ptr.Data) |*v2| v2.deinit(self.alloc);
        }
        self.slots_map.deinit();
        self.slots_list.deinit(self.alloc);
    }

    pub fn set(self: @This(), id: []const u8, slot: SlotData) error{NoSlotWithId, OutOfMemory}!void {
        if (!self.slots_map.contains(id)) return error.NoSlotWithId;
        const v = self.slots_map.getPtr(id).?;
        if (v.Data == null) v.Data = try .initCapacity(self.alloc, 1);

        // if set called, element 0 is main
        try v.Data.?.append(self.alloc, slot);
    }

    pub fn append(self: @This(), id: []const u8, slot: SlotData) !void {
        if (!self.slots_map.contains(id)) return error.NoSlotWithId;
        const v = self.slots_map.getPtr(id).?;
        if (v.Data == null) {
            v.Data = try .initCapacity(self.alloc, 1);
        }

        try v.Data.?.append(self.alloc, slot);
    }

    pub fn generate(self: @This(), writer: *std.Io.Writer) !void {
        var idx: usize = 0;
        for (self.slots_list.items) |slot| {
            for (idx..slot.Loc.start) |i| {
                try writer.printAsciiChar(self.str[i], .{});
            }
            idx = slot.Loc.end;
            if (slot.Data == null) continue;
            for (slot.Data.?.items) |s| {
                switch (s) {
                    .String => |v| {
                        try writer.print("{s}", .{v});
                    },
                    .Number => |n| {
                        try writer.print("{d}", .{n});
                    },
                    .Embed => |template| {
                        try template.generate(writer);
                    }
                }
            }
        }
        for (idx..self.str.len) |i| {
            try writer.printAsciiChar(self.str[i], .{});
        }
    }
};
