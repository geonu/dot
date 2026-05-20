-- Neovim configuration - managed in ~/.dotfiles
-- Rewritten from the old vim-plug init.vim during the 2026 modernization.

-- Leader must be set before lazy.nvim loads.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ── Options ────────────────────────────────────────────────────────────────
local opt = vim.opt

opt.number = true
opt.ruler = true
opt.cursorline = true
opt.mouse = "a"
opt.hidden = true
opt.hlsearch = true
opt.colorcolumn = "80"
opt.signcolumn = "yes"
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.fileformat = "unix"
opt.modeline = true
opt.undofile = true

-- Indentation: 4-space soft tabs by default.
opt.expandtab = true
opt.autoindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4

-- ── Keymaps ────────────────────────────────────────────────────────────────
local map = vim.keymap.set

-- buffers
map("n", "<leader>T", "<cmd>enew<cr>", { desc = "New buffer" })
map("n", "<leader>l", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>h", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<leader>bq", "<cmd>bp <bar> bd #<cr>", { desc = "Close buffer" })

-- window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- clear search highlight
map("n", "<leader><space>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- ── Filetype tweaks ────────────────────────────────────────────────────────
local ft = vim.api.nvim_create_augroup("UserFiletype", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = ft,
  pattern = { "html", "css", "scss", "javascript", "javascriptreact",
    "typescript", "typescriptreact", "json", "yaml", "lua" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = ft,
  pattern = "gitcommit",
  callback = function()
    vim.bo.textwidth = 72
    vim.wo.spell = true
  end,
})

-- ── LSP keymaps (set per buffer when a server attaches) ────────────────────
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLsp", { clear = true }),
  callback = function(args)
    local function bmap(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    bmap("gd", vim.lsp.buf.definition, "Go to definition")
    bmap("gr", vim.lsp.buf.references, "References")
    bmap("K", vim.lsp.buf.hover, "Hover")
    bmap("<F2>", vim.lsp.buf.rename, "Rename symbol")
    bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})

-- ── Plugins (lazy.nvim) ────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(require("plugins"), {
  change_detection = { notify = false },
})
