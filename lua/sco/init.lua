print("skiminouna")

local M = {}

function M.setup(opts)
    require("sco.config").setup(opts or {})
    require("sco.autocmds").setup()
    require("sco.keymaps").setup()
    require("sco.core").setup(opts)
end

return M
