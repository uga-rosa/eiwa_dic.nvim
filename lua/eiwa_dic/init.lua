local M = {}

local a = vim.api
local f = vim.fn

local json = require("eiwa_dic.json")

local pwd = (function()
  return debug.getinfo(1).source:sub(2):match("^(.*/).*$")
end)()

local verb = (function()
  local data = io.open(pwd .. "verb.json"):read("a")
  return json.decode(data)
end)()

local dict = (function()
  local data = io.open(pwd .. "dict.json"):read("a")
  return json.decode(data)
end)()

local function code_decision(num)
  if num < 127 then
    return true
  elseif num < 161 then
    return false
  elseif num < 224 then
    return true
  end
  return false
end

local function head(str)
  if str == "" then
    return "", nil, 0
  elseif #str == 1 then
    return str, nil, 1
  elseif code_decision(str:byte()) then
    return str:sub(1, 1), str:sub(2), 1
  end
  return str:sub(1, 3), str:sub(4), 2
end

local function cut(str, num)
  local res = { {} }
  local init, len = "", 0
  local c = 1
  repeat
    local width
    init, str, width = head(str)
    len = len + width
    if len > num then
      c = c + 1
      len = width
      res[c] = {}
    end
    table.insert(res[c], init)
  until str == nil
  for i = 1, #res do
    res[i] = table.concat(res[i], "")
  end
  return res, (c == 1 and len or num)
end

local current_win

function M.close()
  if current_win then
    a.nvim_win_close(current_win.win, true)
    a.nvim_buf_delete(current_win.buf, { force = true })
    current_win = nil
  end
end

function M.create_window(lines, width)
  local buf = a.nvim_create_buf(false, true)
  a.nvim_buf_set_lines(buf, 0, -1, true, lines)
  local win = a.nvim_open_win(buf, false, {
    relative = "cursor",
    width = width,
    height = #lines,
    style = "minimal",
    row = 1,
    col = 1,
    border = "single",
  })
  current_win = { win = win, buf = buf }
end

function M.popup()
  M.close()
  local word = f.expand("<cword>")
  if word == "" then
    return
  end
  word = verb[word] or word
  local meaning = dict[word]
  if meaning then
    local max = math.floor(a.nvim_win_get_width(0) * 0.6)
    local lines, width = cut(meaning, max)
    M.create_window(lines, width)
  end
end

return M
