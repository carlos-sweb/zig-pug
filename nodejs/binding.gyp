{
  "targets": [
    {
      "target_name": "zigpug",
      "sources": [
        "binding.c"
      ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")",
        "../include",
        "../vendor/mujs"
      ],
      "libraries": [
        "../vendor/mujs/libmujs.a"
      ],
      "cflags": [
        "-std=c99",
        "-Wall",
        "-Wextra"
      ],
      "cflags_cc": [
        "-std=c++14",
        "-Wall",
        "-Wextra"
      ],
      "defines": [
        "NAPI_VERSION=8"
      ],
      "conditions": [
        [
          "OS=='mac'",
          {
            "xcode_settings": {
              "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
              "CLANG_CXX_LIBRARY": "libc++",
              "MACOSX_DEPLOYMENT_TARGET": "10.15"
            }
          }
        ],
        [
          "OS=='linux'",
          {
            "libraries": [
              "-lm"
            ]
          }
        ]
      ]
    }
  ]
}
