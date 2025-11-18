const std = @import("std");

/// Template Cache - Stores compiled HTML for reuse
/// Avoids re-parsing and re-compiling unchanged templates
pub const TemplateCache = struct {
    allocator: std.mem.Allocator,
    entries: std.StringHashMap(CacheEntry),
    max_size: usize,
    hits: usize,
    misses: usize,

    const Self = @This();

    pub const CacheEntry = struct {
        html: []const u8,
        timestamp: i64,
        source_hash: u64,
    };

    /// Initialize cache with optional max size (0 = unlimited)
    pub fn init(allocator: std.mem.Allocator, max_size: usize) Self {
        return .{
            .allocator = allocator,
            .entries = std.StringHashMap(CacheEntry).init(allocator),
            .max_size = max_size,
            .hits = 0,
            .misses = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        var it = self.entries.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.html);
        }
        self.entries.deinit();
    }

    /// Get cached HTML for a key (file path or template name)
    pub fn get(self: *Self, key: []const u8) ?[]const u8 {
        if (self.entries.get(key)) |entry| {
            self.hits += 1;
            return entry.html;
        }
        self.misses += 1;
        return null;
    }

    /// Get cached HTML only if source hash matches
    pub fn getIfValid(self: *Self, key: []const u8, source_hash: u64) ?[]const u8 {
        if (self.entries.get(key)) |entry| {
            if (entry.source_hash == source_hash) {
                self.hits += 1;
                return entry.html;
            }
        }
        self.misses += 1;
        return null;
    }

    /// Store compiled HTML in cache
    pub fn put(self: *Self, key: []const u8, html: []const u8, source_hash: u64) !void {
        // Check max size
        if (self.max_size > 0 and self.entries.count() >= self.max_size) {
            // Simple eviction: remove oldest entry
            self.evictOldest();
        }

        // Remove existing entry if present
        if (self.entries.fetchRemove(key)) |old| {
            self.allocator.free(old.key);
            self.allocator.free(old.value.html);
        }

        // Copy key and html
        const key_copy = try self.allocator.dupe(u8, key);
        errdefer self.allocator.free(key_copy);

        const html_copy = try self.allocator.dupe(u8, html);
        errdefer self.allocator.free(html_copy);

        try self.entries.put(key_copy, .{
            .html = html_copy,
            .timestamp = std.time.timestamp(),
            .source_hash = source_hash,
        });
    }

    /// Invalidate a specific cache entry
    pub fn invalidate(self: *Self, key: []const u8) void {
        if (self.entries.fetchRemove(key)) |old| {
            self.allocator.free(old.key);
            self.allocator.free(old.value.html);
        }
    }

    /// Clear all cache entries
    pub fn clear(self: *Self) void {
        var it = self.entries.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.html);
        }
        self.entries.clearRetainingCapacity();
        self.hits = 0;
        self.misses = 0;
    }

    /// Get cache statistics
    pub fn stats(self: *const Self) CacheStats {
        const total = self.hits + self.misses;
        return .{
            .entries = self.entries.count(),
            .hits = self.hits,
            .misses = self.misses,
            .hit_rate = if (total > 0) @as(f64, @floatFromInt(self.hits)) / @as(f64, @floatFromInt(total)) else 0.0,
        };
    }

    fn evictOldest(self: *Self) void {
        var oldest_key: ?[]const u8 = null;
        var oldest_time: i64 = std.math.maxInt(i64);

        var it = self.entries.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.timestamp < oldest_time) {
                oldest_time = entry.value_ptr.timestamp;
                oldest_key = entry.key_ptr.*;
            }
        }

        if (oldest_key) |key| {
            self.invalidate(key);
        }
    }

    pub const CacheStats = struct {
        entries: usize,
        hits: usize,
        misses: usize,
        hit_rate: f64,
    };
};

/// Compute hash of template source for cache validation
pub fn hashSource(source: []const u8) u64 {
    return std.hash.Wyhash.hash(0, source);
}

// ============================================================================
// Tests
// ============================================================================

test "cache - basic put and get" {
    var cache = TemplateCache.init(std.testing.allocator, 0);
    defer cache.deinit();

    const key = "test.zpug";
    const html = "<div>Hello</div>";
    const hash = hashSource("div Hello");

    try cache.put(key, html, hash);

    const result = cache.get(key);
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings(html, result.?);
}

test "cache - hash validation" {
    var cache = TemplateCache.init(std.testing.allocator, 0);
    defer cache.deinit();

    const key = "test.zpug";
    const html = "<div>Hello</div>";
    const hash1 = hashSource("div Hello");
    const hash2 = hashSource("div World");

    try cache.put(key, html, hash1);

    // Same hash - should return cached value
    const result1 = cache.getIfValid(key, hash1);
    try std.testing.expect(result1 != null);

    // Different hash - should return null (invalidated)
    const result2 = cache.getIfValid(key, hash2);
    try std.testing.expect(result2 == null);
}

test "cache - max size eviction" {
    var cache = TemplateCache.init(std.testing.allocator, 2);
    defer cache.deinit();

    try cache.put("a.zpug", "<a>", hashSource("a"));
    try cache.put("b.zpug", "<b>", hashSource("b"));
    try cache.put("c.zpug", "<c>", hashSource("c")); // Should evict oldest

    try std.testing.expectEqual(@as(usize, 2), cache.entries.count());
}

test "cache - stats" {
    var cache = TemplateCache.init(std.testing.allocator, 0);
    defer cache.deinit();

    try cache.put("test.zpug", "<div>", hashSource("div"));

    _ = cache.get("test.zpug"); // hit
    _ = cache.get("test.zpug"); // hit
    _ = cache.get("missing.zpug"); // miss

    const s = cache.stats();
    try std.testing.expectEqual(@as(usize, 2), s.hits);
    try std.testing.expectEqual(@as(usize, 1), s.misses);
}
