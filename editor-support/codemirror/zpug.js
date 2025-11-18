// CodeMirror mode for zig-pug (.zpug files)
// Based on Pug mode but customized for zig-pug syntax

(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../../lib/codemirror"), require("../javascript/javascript"), require("../css/css"), require("../htmlmixed/htmlmixed"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../../lib/codemirror", "../javascript/javascript", "../css/css", "../htmlmixed/htmlmixed"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
  "use strict";

  CodeMirror.defineMode("zpug", function (config) {
    // Token types
    var KEYWORD = "keyword";
    var TAG = "tag";
    var ATTRIBUTE = "attribute";
    var STRING = "string";
    var COMMENT = "comment";
    var CLASS = "qualifier";
    var ID = "builtin";
    var INTERPOLATION = "variable-2";

    var jsMode = CodeMirror.getMode(config, "javascript");

    function State() {
      this.javaScriptLine = false;
      this.javaScriptLineExcludesColon = false;
      this.javaScriptArguments = false;
      this.javaScriptArgumentsDepth = 0;
      this.isInterpolating = false;
      this.interpolationNesting = 0;
      this.jsState = CodeMirror.startState(jsMode);
      this.restOfLine = "";
      this.isIncludeFiltered = false;
      this.isEach = false;
      this.lastTag = "";
      this.scriptType = "";
      this.indented = 0;
    }

    function copyState(state) {
      var newState = new State();
      newState.javaScriptLine = state.javaScriptLine;
      newState.javaScriptLineExcludesColon = state.javaScriptLineExcludesColon;
      newState.javaScriptArguments = state.javaScriptArguments;
      newState.javaScriptArgumentsDepth = state.javaScriptArgumentsDepth;
      newState.isInterpolating = state.isInterpolating;
      newState.interpolationNesting = state.interpolationNesting;
      newState.jsState = CodeMirror.copyState(jsMode, state.jsState);
      newState.restOfLine = state.restOfLine;
      newState.isIncludeFiltered = state.isIncludeFiltered;
      newState.isEach = state.isEach;
      newState.lastTag = state.lastTag;
      newState.scriptType = state.scriptType;
      newState.indented = state.indented;
      return newState;
    }

    return {
      startState: function () {
        return new State();
      },
      copyState: copyState,
      token: function (stream, state) {
        // Interpolation
        if (state.isInterpolating) {
          if (stream.peek() === "}") {
            state.interpolationNesting--;
            if (state.interpolationNesting < 0) {
              stream.next();
              state.isInterpolating = false;
              return INTERPOLATION;
            }
          } else if (stream.peek() === "{") {
            state.interpolationNesting++;
          }
          return jsMode.token(stream, state.jsState);
        } else if (stream.match(/^#\{/)) {
          state.isInterpolating = true;
          state.interpolationNesting = 0;
          return INTERPOLATION;
        }

        // JavaScript line
        if (state.javaScriptLine) {
          if (state.javaScriptLineExcludesColon && stream.peek() === ":") {
            state.javaScriptLine = false;
            state.javaScriptLineExcludesColon = false;
          }
          var tok = jsMode.token(stream, state.jsState);
          if (stream.eol()) state.javaScriptLine = false;
          return tok || true;
        }

        // JavaScript arguments
        if (state.javaScriptArguments) {
          if (stream.peek() === "(") {
            state.javaScriptArgumentsDepth++;
          } else if (stream.peek() === ")") {
            state.javaScriptArgumentsDepth--;
            if (state.javaScriptArgumentsDepth === 0) {
              stream.next();
              state.javaScriptArguments = false;
              return "punctuation";
            }
          }
          var tok = jsMode.token(stream, state.jsState);
          return tok || true;
        }

        // Start of line
        if (stream.sol()) {
          state.javaScriptLine = false;
          state.javaScriptLineExcludesColon = false;
        }

        // Comments
        if (stream.match(/^\/\/.*/)) {
          return COMMENT;
        }

        // Doctype
        if (stream.match(/^doctype\s+/)) {
          stream.skipToEnd();
          return "meta";
        }

        // Control keywords
        if (stream.match(/^(if|else if|else|unless|each|for|while|case|when|default|block|extends|include|mixin)\b/)) {
          state.javaScriptLine = true;
          return KEYWORD;
        }

        // Unbuffered code (-)
        if (stream.match(/^-\s*/)) {
          state.javaScriptLine = true;
          return "operator";
        }

        // Buffered code (=)
        if (stream.match(/^=\s*/)) {
          state.javaScriptLine = true;
          return "operator";
        }

        // Mixin call
        if (stream.match(/^\+[\w-]+/)) {
          state.javaScriptArguments = true;
          state.javaScriptArgumentsDepth = 0;
          return "variable";
        }

        // Tag
        if (stream.match(/^[\w-]+/)) {
          state.lastTag = stream.current();
          return TAG;
        }

        // Class
        if (stream.match(/^\.[_a-z][\w-]*/i)) {
          return CLASS;
        }

        // ID
        if (stream.match(/^#[_a-z][\w-]*/i)) {
          return ID;
        }

        // Attributes
        if (stream.peek() === "(") {
          stream.next();
          state.javaScriptArguments = true;
          state.javaScriptArgumentsDepth = 1;
          return "punctuation";
        }

        // Piped text
        if (stream.match(/^\|\s*/)) {
          stream.skipToEnd();
          return STRING;
        }

        // Text content
        if (stream.match(/^\s+/)) {
          if (!stream.eol()) {
            stream.skipToEnd();
            return null;
          }
        }

        // Default
        stream.next();
        return null;
      },

      indent: function(state, textAfter) {
        var indent = state.indented;
        if (textAfter && textAfter.match(/^(else|when|default)\b/)) {
          indent -= config.indentUnit;
        }
        return indent;
      },

      electricInput: /^\s*(else|when|default)\b/,
      lineComment: "//",
      fold: "indent"
    };
  });

  CodeMirror.defineMIME("text/x-zpug", "zpug");
  CodeMirror.defineMIME("text/zpug", "zpug");
});
