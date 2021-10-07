local M = {}

local a = vim.api
local f = vim.fn
local uv = vim.loop

local json = require("eiwa_dic.json")

local pwd = (function()
  return debug.getinfo(1).source:sub(2):match("^(.*/).*$")
end)()

local verb = {
  path = pwd .. "verb.json",
  json = "",
}
local dict = {
  path = pwd .. "dict.json",
  json = "",
}

for _, datas in pairs({ verb, dict }) do
  uv.fs_open(datas.path, "r", 438, function(err1, fd)
    assert(not err1, err1)
    uv.fs_fstat(fd, function(err2, stat)
      assert(not err2, err2)
      uv.fs_read(fd, stat.size, 0, function(err3, data)
        assert(not err3, err3)
        uv.fs_close(fd, function(err4)
          assert(not err4, err4)
          datas.json = json.decode(data)
        end)
      end)
    end)
  end)
end

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
  word = verb.json[word] or word
  local meaning = dict.json[word]
  if meaning then
    local max = math.floor(a.nvim_win_get_width(0) * 0.6)
    local lines, width = cut(meaning, max)
    M.create_window(lines, width)
  end
end

return M
