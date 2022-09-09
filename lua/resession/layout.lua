local util = require("resession.util")
local M = {}

---@param tabnr integer
---@param winid integer
---@return table|false
M.get_win_info = function(tabnr, winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  if not util.should_save_buffer(bufnr) then
    return false
  end
  local win = {
    bufname = vim.api.nvim_buf_get_name(bufnr),
    current = vim.api.nvim_get_current_win() == winid,
    cursor = vim.api.nvim_win_get_cursor(winid),
  }
  local winnr = vim.api.nvim_win_get_number(winid)
  if vim.fn.haslocaldir(winnr, tabnr) == 1 then
    win.cwd = vim.fn.getcwd(winnr, tabnr)
  end
  return win
end

---@param tabnr integer
---@param layout table
M.add_win_info_to_layout = function(tabnr, layout)
  local type = layout[1]
  if type == "leaf" then
    layout[2] = M.get_win_info(tabnr, layout[2])
    if not layout[2] then
      return false
    end
  else
    local last_slot = 1
    local items = layout[2]
    for _, v in ipairs(items) do
      local ret = M.add_win_info_to_layout(tabnr, v)
      if ret then
        items[last_slot] = ret
        last_slot = last_slot + 1
      end
    end
    while #items >= last_slot do
      table.remove(items)
    end
    if #items == 1 then
      return items[1]
    elseif #items == 0 then
      return false
    end
  end
  return layout
end

M.set_winlayout = function(layout)
  local type = layout[1]
  local ret
  if type == "leaf" then
    local win = layout[2]
    local bufnr = vim.fn.bufadd(win.bufname)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.api.nvim_win_set_cursor(0, win.cursor)
    if win.cwd then
      vim.cmd(string.format("lcd %s", win.cwd))
    end
    if win.current then
      ret = {
        winid = vim.api.nvim_get_current_win(),
        cursor = win.cursor,
      }
    end
  else
    for i, v in ipairs(layout[2]) do
      if i > 1 then
        if type == "row" then
          vim.cmd("vsplit")
        else
          vim.cmd("split")
        end
      end
      local result = M.set_winlayout(v)
      if result then
        ret = result
      end
    end
  end
  return ret
end

return M
