local cmp = require("cmp")

return {
    {
        label = "miqe:annealingTemp",
        kind = cmp.lsp.CompletionItemKind.Property,
        description = "miqe:annealingTemp",
        documentation = {
            kind = "markdown",
            value = [[
+ **Identifier**
- [http://rs.gbif.org/terms/miqe/annealingTemp]

+ **Type**
- [owl:DatatypeProperty]
- [rdf:Property]

+ **Domain**
- [dwc:MolecularProtocol]

+ **Range**
- [xsd:decimal]

+ **Definition**
- The reaction temperature during the annealing phase of PCR.

+ **Examples**
- `60`
]],
        },
    },
    {
        label = "miqe:annealingTempUnit",
        kind = cmp.lsp.CompletionItemKind.Property,
        description = "miqe:annealingTempUnit",
        documentation = {
            kind = "markdown",
            value = [[
+ **Identifier**
- [http://rs.gbif.org/terms/miqe/annealingTempUnit]

+ **Type**
- [owl:DatatypeProperty]
- [rdf:Property]

+ **Domain**
- [dwc:MolecularProtocol]

+ **Range**
- [xsd:string]

+ **Definition**
- Measurement unit of the reaction temperature during the annealing phase of PCR.

+ **Examples**
- `Degrees celsius`
]],
        },
    },


}
