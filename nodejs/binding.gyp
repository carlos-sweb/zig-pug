{
  "targets": [
    {
      "target_name": "zigpug",
      "sources": [
        "binding.c"
      ],
      "include_dirs": [
        "include",
        "../vendor/mujs"
      ],
      "libraries": [
        "-L<(module_root_dir)/../zig-out/nodejs",
        "-lzigpug",
        "-lm"
      ],
      "cflags": [
        "-std=c99"
      ],
      "defines": [
        "NAPI_VERSION=8"
      ],
      "conditions": [
        ["OS=='linux'", {
          "ldflags": [
            "-Wl,-rpath,'$$ORIGIN/../zig-out/nodejs'"
          ]
        }],
        ["OS=='mac'", {
          "xcode_settings": {
            "OTHER_LDFLAGS": [
              "-Wl,-rpath,@loader_path/../zig-out/nodejs"
            ]
          }
        }]
      ]
    }
  ]
}
