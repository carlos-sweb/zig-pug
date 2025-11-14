const std = @import("std");

// QuickJS C bindings
// Based on quickjs.h from QuickJS 2024-01-13

// Opaque types
pub const JSRuntime = opaque {};
pub const JSContext = opaque {};
pub const JSValue = extern struct {
    u: extern union {
        int32: i32,
        float64: f64,
        ptr: ?*anyopaque,
    },
    tag: i64,
};

// Constants
pub const JS_TAG_INT: i64 = 0;
pub const JS_TAG_BOOL: i64 = 1;
pub const JS_TAG_NULL: i64 = 2;
pub const JS_TAG_UNDEFINED: i64 = 3;
pub const JS_TAG_EXCEPTION: i64 = 6;
pub const JS_TAG_STRING: i64 = 7;
pub const JS_TAG_OBJECT: i64 = 8;

pub const JS_PROP_CONFIGURABLE: u32 = (1 << 0);
pub const JS_PROP_WRITABLE: u32 = (1 << 1);
pub const JS_PROP_ENUMERABLE: u32 = (1 << 2);

// Core runtime functions
extern fn JS_NewRuntime() ?*JSRuntime;
extern fn JS_FreeRuntime(rt: *JSRuntime) void;
extern fn JS_SetMemoryLimit(rt: *JSRuntime, limit: usize) void;
extern fn JS_SetMaxStackSize(rt: *JSRuntime, stack_size: usize) void;

// Core context functions
extern fn JS_NewContext(rt: *JSRuntime) ?*JSContext;
extern fn JS_FreeContext(ctx: *JSContext) void;
extern fn JS_GetRuntime(ctx: *JSContext) *JSRuntime;

// Evaluation
extern fn JS_Eval(ctx: *JSContext, input: [*:0]const u8, input_len: usize, filename: [*:0]const u8, eval_flags: c_int) JSValue;
pub const JS_EVAL_TYPE_GLOBAL: c_int = 0 << 0;
pub const JS_EVAL_FLAG_STRICT: c_int = 1 << 3;
pub const JS_EVAL_FLAG_STRIP: c_int = 1 << 4;

// Value management
extern fn JS_FreeValue(ctx: *JSContext, v: JSValue) void;
extern fn JS_DupValue(ctx: *JSContext, v: JSValue) JSValue;

// Type checking
extern fn JS_IsException(v: JSValue) c_int;
extern fn JS_IsUndefined(v: JSValue) c_int;
extern fn JS_IsNull(v: JSValue) c_int;
extern fn JS_IsBool(v: JSValue) c_int;
extern fn JS_IsNumber(v: JSValue) c_int;
extern fn JS_IsString(v: JSValue) c_int;
extern fn JS_IsObject(v: JSValue) c_int;

// Value creation
extern fn JS_NewInt32(ctx: *JSContext, val: i32) JSValue;
extern fn JS_NewInt64(ctx: *JSContext, val: i64) JSValue;
extern fn JS_NewFloat64(ctx: *JSContext, val: f64) JSValue;
extern fn JS_NewBool(ctx: *JSContext, val: c_int) JSValue;
extern fn JS_NewString(ctx: *JSContext, str: [*:0]const u8) JSValue;
extern fn JS_NewStringLen(ctx: *JSContext, str: [*]const u8, len: usize) JSValue;
extern fn JS_NewObject(ctx: *JSContext) JSValue;
extern fn JS_NewArray(ctx: *JSContext) JSValue;

// Value conversion
extern fn JS_ToInt32(ctx: *JSContext, pres: *i32, val: JSValue) c_int;
extern fn JS_ToInt64(ctx: *JSContext, pres: *i64, val: JSValue) c_int;
extern fn JS_ToFloat64(ctx: *JSContext, pres: *f64, val: JSValue) c_int;
extern fn JS_ToBool(ctx: *JSContext, val: JSValue) c_int;
extern fn JS_ToCStringLen2(ctx: *JSContext, plen: ?*usize, val: JSValue, cesu8: c_int) ?[*:0]const u8;
extern fn JS_FreeCString(ctx: *JSContext, ptr: [*:0]const u8) void;

// Global object
extern fn JS_GetGlobalObject(ctx: *JSContext) JSValue;

// Property access
extern fn JS_GetPropertyStr(ctx: *JSContext, this_obj: JSValue, prop: [*:0]const u8) JSValue;
extern fn JS_SetPropertyStr(ctx: *JSContext, this_obj: JSValue, prop: [*:0]const u8, val: JSValue) c_int;
extern fn JS_DefinePropertyValueStr(ctx: *JSContext, this_obj: JSValue, prop: [*:0]const u8, val: JSValue, flags: u32) c_int;

// Array operations
extern fn JS_GetPropertyUint32(ctx: *JSContext, this_obj: JSValue, idx: u32) JSValue;
extern fn JS_SetPropertyUint32(ctx: *JSContext, this_obj: JSValue, idx: u32, val: JSValue) c_int;

// Exception handling
extern fn JS_GetException(ctx: *JSContext) JSValue;
extern fn JS_Throw(ctx: *JSContext, obj: JSValue) JSValue;

// Wrapped functions for Zig
pub fn newRuntime() !*JSRuntime {
    return JS_NewRuntime() orelse error.OutOfMemory;
}

pub fn freeRuntime(rt: *JSRuntime) void {
    JS_FreeRuntime(rt);
}

pub fn setMemoryLimit(rt: *JSRuntime, limit: usize) void {
    JS_SetMemoryLimit(rt, limit);
}

pub fn setMaxStackSize(rt: *JSRuntime, stack_size: usize) void {
    JS_SetMaxStackSize(rt, stack_size);
}

pub fn newContext(rt: *JSRuntime) !*JSContext {
    return JS_NewContext(rt) orelse error.OutOfMemory;
}

pub fn freeContext(ctx: *JSContext) void {
    JS_FreeContext(ctx);
}

pub fn eval(ctx: *JSContext, input: []const u8, filename: []const u8) !JSValue {
    var input_z = try std.heap.c_allocator.dupeZ(u8, input);
    defer std.heap.c_allocator.free(input_z);

    var filename_z = try std.heap.c_allocator.dupeZ(u8, filename);
    defer std.heap.c_allocator.free(filename_z);

    const result = JS_Eval(
        ctx,
        input_z.ptr,
        input.len,
        filename_z.ptr,
        JS_EVAL_TYPE_GLOBAL,
    );

    if (JS_IsException(result) != 0) {
        return error.EvalException;
    }

    return result;
}

pub fn freeValue(ctx: *JSContext, v: JSValue) void {
    JS_FreeValue(ctx, v);
}

pub fn isException(v: JSValue) bool {
    return JS_IsException(v) != 0;
}

pub fn isUndefined(v: JSValue) bool {
    return JS_IsUndefined(v) != 0;
}

pub fn isNull(v: JSValue) bool {
    return JS_IsNull(v) != 0;
}

pub fn isBool(v: JSValue) bool {
    return JS_IsBool(v) != 0;
}

pub fn isNumber(v: JSValue) bool {
    return JS_IsNumber(v) != 0;
}

pub fn isString(v: JSValue) bool {
    return JS_IsString(v) != 0;
}

pub fn isObject(v: JSValue) bool {
    return JS_IsObject(v) != 0;
}

pub fn newInt32(ctx: *JSContext, val: i32) JSValue {
    return JS_NewInt32(ctx, val);
}

pub fn newFloat64(ctx: *JSContext, val: f64) JSValue {
    return JS_NewFloat64(ctx, val);
}

pub fn newBool(ctx: *JSContext, val: bool) JSValue {
    return JS_NewBool(ctx, if (val) 1 else 0);
}

pub fn newString(ctx: *JSContext, str: []const u8) !JSValue {
    return JS_NewStringLen(ctx, str.ptr, str.len);
}

pub fn newObject(ctx: *JSContext) JSValue {
    return JS_NewObject(ctx);
}

pub fn newArray(ctx: *JSContext) JSValue {
    return JS_NewArray(ctx);
}

pub fn toInt32(ctx: *JSContext, val: JSValue) !i32 {
    var result: i32 = 0;
    if (JS_ToInt32(ctx, &result, val) < 0) {
        return error.ConversionFailed;
    }
    return result;
}

pub fn toFloat64(ctx: *JSContext, val: JSValue) !f64 {
    var result: f64 = 0;
    if (JS_ToFloat64(ctx, &result, val) < 0) {
        return error.ConversionFailed;
    }
    return result;
}

pub fn toBool(ctx: *JSContext, val: JSValue) bool {
    return JS_ToBool(ctx, val) != 0;
}

pub fn toString(ctx: *JSContext, val: JSValue, allocator: std.mem.Allocator) ![]const u8 {
    var len: usize = 0;
    const c_str = JS_ToCStringLen2(ctx, &len, val, 0) orelse return error.ConversionFailed;
    defer JS_FreeCString(ctx, c_str);

    return allocator.dupe(u8, c_str[0..len]);
}

pub fn getGlobalObject(ctx: *JSContext) JSValue {
    return JS_GetGlobalObject(ctx);
}

pub fn getPropertyStr(ctx: *JSContext, obj: JSValue, prop: []const u8) !JSValue {
    var prop_z = try std.heap.c_allocator.dupeZ(u8, prop);
    defer std.heap.c_allocator.free(prop_z);

    return JS_GetPropertyStr(ctx, obj, prop_z.ptr);
}

pub fn setPropertyStr(ctx: *JSContext, obj: JSValue, prop: []const u8, val: JSValue) !void {
    var prop_z = try std.heap.c_allocator.dupeZ(u8, prop);
    defer std.heap.c_allocator.free(prop_z);

    if (JS_SetPropertyStr(ctx, obj, prop_z.ptr, val) < 0) {
        return error.PropertySetFailed;
    }
}

pub fn definePropertyValueStr(ctx: *JSContext, obj: JSValue, prop: []const u8, val: JSValue, flags: u32) !void {
    var prop_z = try std.heap.c_allocator.dupeZ(u8, prop);
    defer std.heap.c_allocator.free(prop_z);

    if (JS_DefinePropertyValueStr(ctx, obj, prop_z.ptr, val, flags) < 0) {
        return error.PropertyDefineFailed;
    }
}

pub fn getPropertyUint32(ctx: *JSContext, obj: JSValue, idx: u32) JSValue {
    return JS_GetPropertyUint32(ctx, obj, idx);
}

pub fn setPropertyUint32(ctx: *JSContext, obj: JSValue, idx: u32, val: JSValue) !void {
    if (JS_SetPropertyUint32(ctx, obj, idx, val) < 0) {
        return error.PropertySetFailed;
    }
}

pub fn getException(ctx: *JSContext) JSValue {
    return JS_GetException(ctx);
}
