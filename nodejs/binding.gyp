{
  "targets": [
    {
      "target_name": "zigpug",
      "sources": [
        "binding.c"
      ],
      "include_dirs": [
        "include",
        "vendor/mujs"
      ],
      "libraries": [
        "<(module_root_dir)/vendor/mujs/libmujs.a",
        "-lm"
      ],
      "cflags": [
        "-std=c99"
      ],
      "defines": [
        "NAPI_VERSION=8"
      ]
    }
  ]
}
