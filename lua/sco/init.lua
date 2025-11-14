local M = {}

function M.setup(opts)
    -- Config is always required, so make it a local variable
    local config = require("sco.config")
    config.setup(opts or {})

    require("sco.core").setup(opts)

    -- Make autocommands and keymaps optional
    -- At its core we want a completion source
    if config.enable_autocmds then
        require("sco.autocmds").setup()
    end

    if config.enable_keymaps then
        require("sco.keymaps").setup()
    end
end

return M
