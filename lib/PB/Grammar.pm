
grammar PB::Grammar {
    token TOP           { ^ <.ws> <proto> <.ws> $ <.ws> }
    token proto         { [<message> | <pkg> | <import> | <option> | <enum> | <extend> | <service> | ';']* }

    # comments and whitespace
    proto token comment { * }
    token comment:sym<single-line> { '//' .*? $$ } # todo test \N*
    token comment:sym<multi-line>  { '/*' .*? '*/' }
    token ws            { <!ww> [\s | <.comment>]* }

    # import
    rule import         { 'import' <public>? <str-lit> ';' }
    rule public         { 'public' }

    # package
    rule pkg            { 'package' <dotted-ident> ';' }

    # option
    rule option         { 'option' <opt-body> ';' }

    # enum
    rule enum           { 'enum' <ident> '{' [<option> | <enum-field> | ';']* '}' } # todo: translate into  '{' ~ '}'
    rule enum-field     { <ident> '=' <int-lit> <field-opts>? ';' }

    # service/rpc
    rule service        { 'service' <ident> '{' [<option> | <rpc> | ';']* '}' }
    rule rpc            { 'rpc' <ident> '(' <user-type> ')' 'returns' '(' <user-type> ')' [<rpc-body>? | ';'] }
    rule rpc-body       { '{' ~ '}' [<option>*] }

    # extend
    rule extend         { 'extend' <user-type> '{' [<field> | <group> | ';']* '}' }

    # message
    rule message        { 'message' <ident> <message-body> }
    rule message-body   { '{' [<message> | <field> | <extensions> | <option> | <group> | <enum> | <extend> | ';']* '}' }
    rule field          { <label> <type> <ident> '=' <field-num> <field-opts>? ';' }
    rule field-opts     { '[' [<opt-body> ','?]* ']' } # todo: make this turn into a prettier ast, also disallow trailing comma
    # token field-opt     { [<default-opt> | <opt-body>] }
    # rule default-opt    { 'default' <.ws> '=' <constant> }
    rule extensions     { 'extensions' <extension> (',' <extension>)* ';' }
    rule extension      { $<start>=<int-lit> ['to' $<end>=[<int-lit> | 'max']]? }
    rule group          { <label> 'group' <camel-ident> '=' <int-lit> <message-body> }

    # commonly used tokens

    # option
    rule opt-body       { <opt-name> '=' [<constant> | <submsg>] }
    token opt-name      { '.'? <opt-name-tok> ('.' <opt-name-tok>)* }
    token opt-name-tok  { [<cust-opt-name> | <dotted-ident>] }
    token cust-opt-name { '(' ~ ')' ['.'? <dotted-ident>] }

    rule submsg         { '{' ~ '}' [<pairlist> | <block>]* }
    rule pair           { <ident> ':' <constant>}
    rule pairlist       { <pair> (',' <pair>)* }
    rule block          { [<ident> | <block-ident>] '{' ~ '}' [<pairlist> | <block>]* }
    rule block-ident    { '[' ~ ']' [<dotted-ident>] }

    token type          { 'double' | 'float' | 'int32' | 'int64' | 'uint32' 
                        | 'uint64' | 'sint32' | 'sint64' | 'fixed32' 
                        | 'fixed64' | 'sfixed32' | 'sfixed64' | 'bool' 
                        | 'string' | 'bytes' | <user-type> }

    token user-type     { '.'? <dotted-ident> }

    token label         { 'required' | 'optional' | 'repeated' }

    token ident         { <[a..zA..Z]>\w* }

    token dotted-ident  { <ident> ('.' <ident>)* }

    token camel-ident   { <[A..Z]>\w* }

    token field-num     { <int-lit> }

    proto token constant { * }

    # numbers
    token sign                  { ['-' | '+']? }
    token constant:sym<bool>    { 'true' | 'false' }
    token constant:sym<nan>     { 'nan' }
    token constant:sym<inf>     { <sign> 'inf' }

    # int
    token constant:sym<int> { <int-lit> }
    proto token int-lit     { * }
    token int-lit:sym<dec>  { <sign> <[1..9]>\d* }
    token int-lit:sym<hex>  { <sign> '0' <[xX]> <xdigit>+ }
    token int-lit:sym<oct>  { <sign> '0' $<digit>=<[0..7]>* }

    # float
    token exponent              { [<[eE]> ['+'|'-']? \d+] }
    token constant:sym<float>   { <sign> [<float-leading> | <float-no-leading>] }
    token float-no-leading      { '.' \d+ <exponent>? }
    token float-leading         { \d+ '.'? \d* <exponent>? }

    # string
    token constant:sym<str>             { <str-lit> }
    proto token str-lit                 { * }
    token str-lit:sym<single-quoted>    { \' ~ \' <str-contents-single>* } #'
    token str-lit:sym<double-quoted>    { \" ~ \" <str-contents-double>* } #"

    token str-contents-single           { <-[\\\x00\n']>+ | <str-escape> } #'
    token str-contents-double           { <-[\\\x00\n"]>+ | <str-escape> } #"

    proto token str-escape              { * }

    token str-escape:sym<hex>           { '\\' <[xX]> <xdigit> ** 1..2 }
    token str-escape:sym<oct>           { '\\' $<digit>=<[0..7]> ** 1..3 }
    token str-escape:sym<char>          { '\\' $<char>=<[abfnrtv\\?'"]> }       # ' <- stupid syntax highlighting

    # symbol constant - match last so true/false/nan/inf whatever can be picked up
    token constant:sym<symbol>   { <ident> }
}
