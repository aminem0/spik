--[[
]]

local cmp = require("cmp")

return {
    {
        label = "mixs:samp_size",
        insertText = "mixs:0000001",
        kind = cmp.lsp.CompletionItemKind.Property,
        description = "mixs:samp_size",
        deprecated = false,
        documentation = {
            kind = "markdown",
            value = [[
+ **Identifier**
- [https://w3id.org/mixs/0000001]

+ **Type**
- [rdf:Property]

+ **Range**
- [xsd:string]

+ **Definition**
- The total amount or size (volume (ml), mass (g) or aread (m2)) of sample collected.

+ **Examples**
- `5 liter`
]],
        },
    },
    {
        label = "mixs:samp_collect_device",
        insertText = "mixs:0000002",
        kind = cmp.lsp.CompletionItemKind.Property,
        description = "mixs:samp_collect_device",
        deprecated = false,
        documentation = {
            kind = "markdown",
            value = [[
+ **Identifier**
- [https://w3id.org/mixs/0000002]

+ **Type**
- [rdf:Property]

+ **Range**
- [xsd:string]

+ **Definition**
- The device used tocollect an environmental sample. This field accepts terms listed under environmental sampling device ([http://purl.obolibrary.org/obo/ENVO]). This field also accepts terms listed under specimen collection device ([http://purl.obolibrary.org/obo/GENEPIO_0002094]).
]],
        },
    },
}
