#!/usr/bin/env python3
"""
Example: Using zig-pug from Python via ctypes

Requirements:
    - Build the shared library first: zig build lib-shared
    - The library will be in zig-out/lib/

Usage:
    python3 example.py
"""

import ctypes
import os
from pathlib import Path

# Find the shared library
lib_dir = Path(__file__).parent.parent / "zig-out" / "lib"
lib_name = None

for name in ["libzig-pug.so", "libzig-pug.dylib", "zig-pug.dll"]:
    lib_path = lib_dir / name
    if lib_path.exists():
        lib_name = str(lib_path)
        break

if not lib_name:
    print("Error: Could not find zig-pug shared library")
    print(f"Please run: zig build lib-shared")
    print(f"Looking in: {lib_dir}")
    exit(1)

# Load the library
zigpug = ctypes.CDLL(lib_name)

# Define function signatures
zigpug.zigpug_init.restype = ctypes.c_void_p
zigpug.zigpug_init.argtypes = []

zigpug.zigpug_free.restype = None
zigpug.zigpug_free.argtypes = [ctypes.c_void_p]

zigpug.zigpug_compile.restype = ctypes.c_char_p
zigpug.zigpug_compile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]

zigpug.zigpug_set_string.restype = ctypes.c_bool
zigpug.zigpug_set_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]

zigpug.zigpug_set_int.restype = ctypes.c_bool
zigpug.zigpug_set_int.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int64]

zigpug.zigpug_set_bool.restype = ctypes.c_bool
zigpug.zigpug_set_bool.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_bool]

zigpug.zigpug_free_string.restype = None
zigpug.zigpug_free_string.argtypes = [ctypes.c_char_p]

zigpug.zigpug_version.restype = ctypes.c_char_p
zigpug.zigpug_version.argtypes = []


class ZigPug:
    """Python wrapper for zig-pug library"""

    def __init__(self):
        self.ctx = zigpug.zigpug_init()
        if not self.ctx:
            raise RuntimeError("Failed to initialize zig-pug")

    def __del__(self):
        if hasattr(self, 'ctx') and self.ctx:
            zigpug.zigpug_free(self.ctx)

    def compile(self, template: str) -> str:
        """Compile a Pug template to HTML"""
        result = zigpug.zigpug_compile(self.ctx, template.encode('utf-8'))
        if result:
            html = result.decode('utf-8')
            zigpug.zigpug_free_string(result)
            return html
        raise RuntimeError("Failed to compile template")

    def set(self, key: str, value):
        """Set a variable in the context"""
        key_bytes = key.encode('utf-8')

        if isinstance(value, str):
            success = zigpug.zigpug_set_string(self.ctx, key_bytes, value.encode('utf-8'))
        elif isinstance(value, bool):
            success = zigpug.zigpug_set_bool(self.ctx, key_bytes, value)
        elif isinstance(value, int):
            success = zigpug.zigpug_set_int(self.ctx, key_bytes, value)
        else:
            raise TypeError(f"Unsupported type: {type(value)}")

        if not success:
            raise RuntimeError(f"Failed to set variable: {key}")

    @staticmethod
    def version() -> str:
        """Get zig-pug version"""
        return zigpug.zigpug_version().decode('utf-8')


def main():
    print(f"zig-pug version: {ZigPug.version()}\n")

    # Create context
    pug = ZigPug()

    # Example 1: Simple template
    print("=== Example 1: Simple Template ===")
    template1 = "div.container Hello World"
    html1 = pug.compile(template1)
    print(f"Input:  {template1}")
    print(f"Output: {html1}\n")

    # Example 2: Template with interpolation
    print("=== Example 2: Interpolation ===")
    pug.set("name", "Alice")
    pug.set("age", 25)

    template2 = "p Hello #{name}!"
    html2 = pug.compile(template2)
    print(f"Input:  {template2}")
    print(f"Output: {html2}\n")

    # Example 3: Conditional rendering
    print("=== Example 3: Conditionals ===")
    pug.set("loggedIn", True)

    template3 = """if loggedIn
  p Welcome back!
else
  p Please log in"""

    html3 = pug.compile(template3)
    print(f"Input:\n{template3}")
    print(f"Output: {html3}\n")

    # Example 4: Mixin
    print("=== Example 4: Mixins ===")
    template4 = """mixin button
  button.btn Click me!
+button"""

    html4 = pug.compile(template4)
    print(f"Input:\n{template4}")
    print(f"Output: {html4}\n")


if __name__ == "__main__":
    main()
