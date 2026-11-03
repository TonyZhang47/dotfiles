local lazypath = vim.fn.stdpath("data") .. "lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
vim.opt.clipboard = "unnamedplus"

-- Layout is us(dvorak). In Normal, Visual, and Operator-pending mode, treat each
-- key as the QWERTY key in that position. Insert mode and the command line stay Dvorak.
local dvorak_to_qwerty = {
  ["'"] = "q", [","] = "w", ["."] = "e", p = "r", y = "t",
  f = "y", g = "u", c = "i", r = "o", l = "p",
  ["/"] = "[", ["="] = "]", ["["] = "-", ["]"] = "=",
  o = "s", e = "d", u = "f", i = "g", d = "h",
  h = "j", t = "k", n = "l", s = ";", ["-"] = "'",
  [";"] = "z", q = "x", j = "c", k = "v", x = "b",
  b = "n", w = ",", v = ".", z = "/",
  ['"'] = "Q", ["<"] = "W", [">"] = "E", P = "R", Y = "T",
  F = "Y", G = "U", C = "I", R = "O", L = "P",
  ["?"] = "{", ["+"] = "}", ["{"] = "_", ["}"] = "+",
  O = "S", E = "D", U = "F", I = "G", D = "H",
  H = "J", T = "K", N = "L", S = ":", ["_"] = '"',
  [":"] = "Z", Q = "X", J = "C", K = "V", X = "B",
  B = "N", W = "<", V = ">", Z = "?",
}

local from, to = {}, {}
for src, dst in pairs(dvorak_to_qwerty) do
  table.insert(from, src)
  table.insert(to, dst)
end

local function langmap_escape(text)
  return text:gsub('[;,"\\|]', "\\%0")
end

vim.opt.langmap = langmap_escape(table.concat(from)) .. ";" .. langmap_escape(table.concat(to))
vim.opt.langremap = false

vim.keymap.set('n', '<Esc>', ':noh<CR>', { noremap = true, silent = true })

require("vim-options")
require("lazy").setup("plugins")


