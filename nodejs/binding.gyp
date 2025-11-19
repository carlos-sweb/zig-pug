{
  "targets": [
    {
      "target_name": "zigpug",
      "sources": [
        "binding.c",
        "vendor/mujs/one.c"
      ],
      "include_dirs": [
        "include",
        "vendor/mujs"
      ],
      "libraries": [
        "-lm"
      ],
      "cflags": [
        "-std=c99",
        "-DHAVE_STRLCPY=0"
      ],
      "defines": [
        "NAPI_VERSION=8"
      ]
    }
  ]
}
