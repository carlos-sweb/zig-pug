//! Cache module - Template Caching
//!
//! This module provides a template cache to store compiled HTML and avoid
//! re-parsing and re-compiling unchanged templates. Improves performance for
//! applications that repeatedly render the same templates.
//!
//! Features:
//! - LRU (Least Recently Used) eviction when max size reached
//! - Source hash validation to detect template changes
//! - Cache statistics (hits, misses, hit rate)
//! - Per-entry invalidation
//!
//! Example:
//! ```zig
//! var cache = TemplateCache.init(allocator, 100); // Max 100 entries
//! defer cache.deinit();
//!
//! // Check if template is cached
//! const hash = hashSource(source_code);
//! if (cache.getIfValid("template.pug", hash)) |html| {
//!     // Use cached HTML
//! } else {
//!     // Compile template
//!     const html = try compile(source_code);
//!     try cache.put("template.pug", html, hash);
//! }
//!
//! // View cache statistics
//! const stats = cache.stats();
//! std.debug.print("Hit rate: {d:.2}%\n", .{stats.hit_rate * 100});
//! ```

const std = @import("std");

/// Template Cache - Stores compiled HTML for reuse
///
/// In-memory cache using file paths as keys. Each entry stores:
/// - Compiled HTML
/// - Timestamp (for LRU eviction)
/// - Source hash (for change detection)
///
/// Thread-safety: Not thread-safe. Caller must synchronize access.
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

    /// Initialize cache with optional max size
    ///
    /// Parameters:
    /// - allocator: Memory allocator for cache entries
    /// - max_size: Maximum number of entries (0 = unlimited)
    ///
    /// Returns: Initialized cache
    ///
    /// Example:
    /// ```zig
    /// var cache = TemplateCache.init(allocator, 100);
    /// defer cache.deinit();
    /// ```
    pub fn init(allocator: std.mem.Allocator, max_size: usize) Self {
        return .{
            .allocator = allocator,
            .entries = std.StringHashMap(CacheEntry).init(allocator),
            .max_size = max_size,
            .hits = 0,
            .misses = 0,
        };
    }

    /// Free cache and all stored entries
    ///
    /// Frees all HTML strings and keys. Cache cannot be used after this.
    pub fn deinit(self: *Self) void {
        var it = self.entries.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.html);
        }
        self.entries.deinit();
    }

    /// Get cached HTML for a key without hash validation
    ///
    /// Returns cached HTML regardless of whether source changed.
    /// Use getIfValid() for safer cache lookups with change detection.
    ///
    /// Parameters:
    /// - key: Template identifier (usually file path)
    ///
    /// Returns: Cached HTML or null if not found
    pub fn get(self: *Self, key: []const u8) ?[]const u8 {
        if (self.entries.get(key)) |entry| {
            self.hits += 1;
            return entry.html;
        }
        self.misses += 1;
        return null;
    }

    /// Get cached HTML only if source hash matches (safe cache lookup)
    ///
    /// Recommended method for cache lookups. Returns cached HTML only if
    /// the source hash matches, ensuring template hasn't changed.
    ///
    /// Parameters:
    /// - key: Template identifier
    /// - source_hash: Hash of current template source (from hashSource())
    ///
    /// Returns: Cached HTML if found and valid, null otherwise
    ///
    /// Example:
    /// ```zig
    /// const hash = hashSource(source);
    /// if (cache.getIfValid("template.pug", hash)) |html| {
    ///     return html; // Template unchanged, use cache
    /// } else {
    ///     // Template changed or not cached, recompile
    /// }
    /// ```
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
    ///
    /// Adds or updates cache entry. If max_size is reached, evicts
    /// the oldest entry (LRU). Copies both key and HTML to cache.
    ///
    /// Parameters:
    /// - key: Template identifier
    /// - html: Compiled HTML to cache
    /// - source_hash: Hash of source code (for validation)
    ///
    /// Example:
    /// ```zig
    /// const html = try compiler.compile(ast);
    /// const hash = hashSource(source_code);
    /// try cache.put("template.pug", html, hash);
    /// ```
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
    ///
    /// Removes entry from cache and frees its memory.
    /// Safe to call with non-existent keys (no-op).
    ///
    /// Parameters:
    /// - key: Template identifier to invalidate
    pub fn invalidate(self: *Self, key: []const u8) void {
        if (self.entries.fetchRemove(key)) |old| {
            self.allocator.free(old.key);
            self.allocator.free(old.value.html);
        }
    }

    /// Clear all cache entries and reset statistics
    ///
    /// Removes all entries and resets hit/miss counters.
    /// Does not free the cache itself (use deinit() for that).
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

    /// Get cache performance statistics
    ///
    /// Returns current cache metrics including hit rate.
    ///
    /// Returns: CacheStats struct with metrics
    ///
    /// Example:
    /// ```zig
    /// const s = cache.stats();
    /// std.debug.print("Entries: {d}, Hit rate: {d:.1}%\n",
    ///     .{s.entries, s.hit_rate * 100});
    /// ```
    pub fn stats(self: *const Self) CacheStats {
        const total = self.hits + self.misses;
        return .{
            .entries = self.entries.count(),
            .hits = self.hits,
            .misses = self.misses,
            .hit_rate = if (total > 0) @as(f64, @floatFromInt(self.hits)) / @as(f64, @floatFromInt(total)) else 0.0,
        };
    }

    /// Evict oldest cache entry (LRU eviction)
    ///
    /// Called automatically when cache reaches max_size.
    /// Finds and removes the entry with oldest timestamp.
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

    /// Cache statistics structure
    ///
    /// Fields:
    /// - entries: Current number of cached templates
    /// - hits: Number of successful cache lookups
    /// - misses: Number of cache misses
    /// - hit_rate: Percentage of hits (0.0 to 1.0)
    pub const CacheStats = struct {
        entries: usize,
        hits: usize,
        misses: usize,
        hit_rate: f64,
    };
};

/// Compute hash of template source for cache validation
///
/// Uses Wyhash algorithm for fast, high-quality hashing.
/// Used to detect template changes between cache lookups.
///
/// Parameters:
/// - source: Template source code
///
/// Returns: 64-bit hash value
///
/// Example:
/// ```zig
/// const hash1 = hashSource("div Hello");
/// const hash2 = hashSource("div World");
/// // hash1 != hash2 (different source)
/// ```
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
