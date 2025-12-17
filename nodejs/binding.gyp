{
  "targets": [
    {
      "target_name": "zigpug",
      "sources": [
        "binding.c"
      ],
      "include_dirs": [
        "include"
      ],
      "conditions": [
        ["OS=='win'", {
          "libraries": [
            "<(module_root_dir)/prebuilts/win32-<(target_arch)/zig-pug.lib"
          ]
        }],
        ["OS=='mac'", {
          "libraries": [
            "-lm",
            "../prebuilts/darwin-<(target_arch)/libzig-pug.a"
          ],
          "cflags": [
            "-std=c99"
          ]
        }],
        ["OS=='android'", {
          "libraries": [
            "-lm",
            "../prebuilts/linux-<(target_arch)/libzig-pug.a"
          ],
          "cflags": [
            "-std=c99"
          ]
        }],
        ["OS=='linux'", {
          "libraries": [
            "-lm",
            "../prebuilts/linux-<(target_arch)/libzig-pug.a"
          ],
          "cflags": [
            "-std=c99"
          ]
        }]
      ],
      "defines": [
        "NAPI_VERSION=8"
      ]
    }
  ]
}
