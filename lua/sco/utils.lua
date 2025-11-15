-- lua/sco/utils.lua
local M = {}

local endpoints = require("sco.lookups.sparql_endpoints") -- ensure spelling
local requests = require("sco.lookups.request_content_types")
local types = require("sco.lookups.mime_types")
local extensions = require("sco.lookups.file_extensions")
local http_methods = require("sco.lookups.http_methods")

-- module state (safe, not bare locals)
M.state = {
  accept_mime_type = "*/*",
  request_content_type = "application/sparql-query",
  http_method = "POST",
  sparql_endpoint_url = nil,
  debug = false,
}

-- build mime -> ext map once
local mime_map = {}
for _, it in ipairs(extensions) do
  if it.mime_type and it.extension then
    mime_map[it.mime_type] = it.extension
  end
end

-- Utility: notify (quiet by default)
local function notify(msg, level)
  level = level or vim.log.levels.INFO
  if M.state.debug or level == vim.log.levels.ERROR then
    vim.notify("[sco] " .. msg, level)
  end
end

-- Setter helpers (store in state)
function M.set_endpoint(url)
  M.state.sparql_endpoint_url = url
  notify("endpoint set", vim.log.levels.DEBUG)
end

function M.set_request_content_type(mime)
  M.state.request_content_type = mime
  notify("request content type set: " .. mime, vim.log.levels.DEBUG)
end

function M.set_accept_mime_type(mime)
  M.state.accept_mime_type = mime
  notify("accept mime set: " .. mime, vim.log.levels.DEBUG)
end

function M.set_http_method(method)
  M.state.http_method = method
  notify("HTTP method set: " .. tostring(method), vim.log.levels.DEBUG)
end

-- interactive selectors (use setters above)
function M.select_request_type()
  vim.ui.select(requests, {
    prompt = "Set request type:",
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then
      M.set_request_content_type(choice.mime_type)
      notify("Request type set to " .. choice.name, vim.log.levels.INFO)
    else
      notify("Request type selection cancelled", vim.log.levels.WARN)
    end
  end)
end

function M.select_mime_type()
  vim.ui.select(types, {
    prompt = "Set accept type:",
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then
      M.set_accept_mime_type(choice.mime_type)
      notify("Accept type set to " .. choice.name, vim.log.levels.INFO)
    else
      notify("Accept type selection cancelled", vim.log.levels.WARN)
    end
  end)
end

function M.select_endpoint_url()
  vim.ui.select(endpoints, {
    prompt = "Set ✨SPARQL✨ endpoint:",
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then
      M.set_endpoint(choice.url)
      notify("Endpoint set to " .. choice.name, vim.log.levels.INFO)
    else
      notify("Endpoint selection cancelled", vim.log.levels.WARN)
    end
  end)
end

function M.select_http_method()
  vim.ui.select(http_methods, {
    prompt = "Set HTTP method:",
  }, function(choice)
    if choice then
      M.set_http_method(choice)
      notify("HTTP method set to " .. tostring(choice), vim.log.levels.INFO)
    else
      notify("HTTP method selection cancelled", vim.log.levels.WARN)
    end
  end)
end

-- helper: create a floating window and return buffer and win id
local function floaty(content_lines, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  if ft then
    vim.api.nvim_buf_set_option(buf, "filetype", ft)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content_lines)

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- keymap to close window (only in this buffer)
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })

  return buf, win
end

-- robust Content-Type extraction from header lines (array)
local function extract_content_type(header_lines)
  for _, line in ipairs(header_lines or {}) do
    local name, value = line:match("^%s*([^:]+):%s*(.+)$")
    if name and value and name:lower() == "content-type" then
      -- return main type (before ;)
      local main = value:match("^[^;]+")
      if main then
        return vim.trim(main)
      else
        return vim.trim(value)
      end
    end
  end
  return nil
end

local function mime_to_ext(mime)
  if not mime then return nil end
  return mime_map[mime]
end

-- safe filename base
local function safe_basename()
  local name_base = vim.fn.fnamemodify(vim.fn.expand("%"), ":t:r")
  if name_base == "" then name_base = "sco" end
  -- remove path-unfriendly chars
  name_base = name_base:gsub("[^%w%-_%.]", "_")
  return name_base
end

-- Use curl as a job (async). Returns job id.
-- opts can include: { on_done = function(success, headers, body, http_code) end }
function M.queryo()
    local filepath = vim.fn.expand("%:p")

    -- Read query contents
    local query = table.concat(vim.fn.readfile(filepath), "\n")

    -- Handle form-encoded case
    if request_content_type == "application/x-www-form-urlencoded" then
        query = "query=" .. query
    end

    local cmd

    if http_method == "POST" then
        -- curl reads the query from STDIN (the '@-' argument)
        cmd = {
            "curl",
            "-i",
            "-s",
            "-X", "POST",
            sparql_endpoint_url,
            "-H", "Content-Type: " .. request_content_type,
            "-H", "Accept: " .. accept_mime_type,
            "--data-binary", "@-",
        }

        -- IMPORTANT:
        -- systemlist(cmd, query) sends `query` as STDIN
        -- curl reads STDIN because of '@-'
        response = vim.fn.systemlist(cmd, query)

    elseif http_method == "GET" then
        -- GET uses URL encoding, so no stdin is involved
        cmd = {
            "curl",
            "-i",
            "-s",
            sparql_endpoint_url .. "?query=" .. url_encode(query),
            "-H", "Accept: " .. accept_mime_type,
        }

        response = vim.fn.systemlist(cmd)
    end

    -- Combine response
    local resp_str = table.concat(response, "\n")

    -- Split headers and body
    local resp_headers, resp_body = resp_str:match("(.-)\r\n\r\n(.*)")
    local resp_headerso = vim.fn.split(resp_headers, "\r\n")
    local resp_bodyo = vim.fn.split(resp_body, "\n")

    -- Construct output file base name
    local name_base = vim.fn.fnamemodify(vim.fn.expand("%"), ":t:r")

    -- Save output
    vim.fn.writefile(resp_bodyo, name_base .. mime2ext(contento(resp_headerso)))
    vim.fn.writefile(resp_headerso, name_base .. ".http")
end

return M
