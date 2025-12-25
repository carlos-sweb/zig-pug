pub const TokenizerState = enum {
    Root,
    Indent,
    TagStart,
    TagId,
    TagClass,
    AttrStart,
    AttrName,
    AttrEquals,
    AttrValue,
    AttrString,
    AttrJS,
    Text,
    Code,  // JavaScript expression context (after =, !=, -)
    Loop,  // Loop context (after each/while) - prevents identifiers from being treated as tags
};
