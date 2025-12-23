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
};
