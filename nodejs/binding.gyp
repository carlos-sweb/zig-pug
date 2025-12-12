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
        ["OS=='android'", {
          "libraries": [
            "-lm",
            "<(module_root_dir)/prebuilts/linux-<(target_arch)/libzig-pug.a"
          ],
          "cflags": [
            "-std=c99"
          ]
        }],
        ["OS!='win' and OS!='android'", {
          "libraries": [
            "-lm",
            "<(module_root_dir)/prebuilts/<(OS)-<(target_arch)/libzig-pug.a"
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
