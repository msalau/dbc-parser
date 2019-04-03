# This is a parser/scanner of DBC files

The application is useless on its own, but may be tweaked or embedded into any app to do real stuff.
Originally the project was started to implement dbc parser that will become part of a [wireshark](https://www.wireshark.org/) plugin to dissect CAN traffic.

# About DBC file format

DBC is a proprietary file format developed by Vector Informatik GmbH (c).
Specification of the file format is not available to general public and thus reverse engineering is used to reconstruct its specification to some extent.
CANdb++ Editor is used to verify a file to match specification.

# DBC file format specification

## Lexer rules

1. Tokens are separated by delimiters: space, tab or new line;
2. Delimiters are not enforced by the parser and thus are ignored;
3. Text strings are enclosed into double quotes and may contain any other characters except for double quotes (e.g. text string may span several lines; side note: CANdb++ Editor is able to open dbc files with escaped double quotes `\"` but don't allow to edit or enter such strings in GUI);
4. There are reserved keywords: `VERSION`, `NS_`, `BS_`, `BO_`, `SG_`, `CM_`, and etc.;
5. Identifier names are composed of Latin letters, digits and/or underscores; Names should not start with a digit and may not match a reserved keyword;
6. Some symbols are passed to the parser as-is: `(`, `)`, `[`, `]`, `,`, `:`, `;`, `|`, `@`;
7. There are cases in which symbols `+` and `-` are used as separate tokens (not a prefix of a number);
8. Standalone letter `M` or `m` and following digits with optional `M` are passed as a separate token type, such sequence may appear as a special token or as an identifier;
9. Comments start with double slash and span until end of line and are ignored;

## Parser rules
