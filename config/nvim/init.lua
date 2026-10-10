-- ==============================================================================
-- NEOVIM CONFIGURATION (LUA) - BEST PRACTICES FOR GHOSTTY & TERMINAL
-- Location: ~/.config/nvim/init.lua
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. LEADER KEY & BASE OPTIONS
-- ------------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- General UI & Display
opt.number = true             -- Show line numbers
opt.relativenumber = true     -- Relative line numbers for quick Vim movement
opt.mouse = "a"               -- Full mouse support (click to move cursor, scroll, resize)
opt.termguicolors = true      -- True color support in Ghostty
opt.cursorline = true         -- Highlight current line
opt.signcolumn = "yes"        -- Always show sign column for git signs
opt.scrolloff = 8             -- Keep 8 lines above/below cursor when scrolling
opt.sidescrolloff = 8
opt.wrap = false              -- Disable line wrapping by default
opt.showmode = false          -- Hide default -- INSERT -- mode (lualine handles it)

-- System Clipboard Integration (macOS + Ghostty)
opt.clipboard = "unnamedplus"

-- Indentation & Tabs
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true          -- Use spaces instead of tabs
opt.smartindent = true

-- Search & Case Sensitivity
opt.ignorecase = true         -- Ignore case when searching...
opt.smartcase = true          -- ...unless capital letters are used
opt.hlsearch = true           -- Highlight search results
opt.incsearch = true          -- Incremental search

-- History & Performance
opt.undofile = true           -- Save undo history to file
opt.updatetime = 250          -- Faster completion & git sign updates
opt.timeoutlen = 300          -- Faster key sequence timeout for Which-Key

-- Split behavior
opt.splitright = true         -- Vertical splits open to the right
opt.splitbelow = true         -- Horizontal splits open to the bottom

-- ------------------------------------------------------------------------------
-- 2. BOOTSTRAP LAZY.NVIM PLUGIN MANAGER
-- ------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ------------------------------------------------------------------------------
-- 3. PLUGIN SPECIFICATIONS
-- ------------------------------------------------------------------------------
require("lazy").setup({
  -- TokyoNight Theme (Matches Ghostty & Starship)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true, -- Blend with Ghostty transparent background
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })
      vim.cmd([[colorscheme tokyonight]])
    end,
  },

  -- File Icons
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- File Explorer (NvimTree)
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
          relativenumber = true,
        },
        renderer = {
          group_empty = true,
          icons = {
            show = {
              git = true,
              folder = true,
              file = true,
            },
          },
        },
        filters = {
          dotfiles = false,
        },
      })
    end,
  },

  -- Telescope (Fuzzy Finder for Files, Text, Buffers)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git/", "dist", "build" },
          path_display = { "truncate" },
        },
      })
    end,
  },

  -- Status Line (Lualine)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          component_separators = "|",
          section_separators = "",
        },
      })
    end,
  },

  -- Bufferline (Tab bar for open files)
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              text_align = "left",
              separator = true,
            },
          },
        },
      })
    end,
  },

  -- Treesitter (Advanced Syntax Highlighting)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local status, ts = pcall(require, "nvim-treesitter.configs")
      if status then
        ts.setup({
          ensure_installed = { "c", "lua", "vim", "vimdoc", "javascript", "typescript", "html", "css", "json", "bash", "python", "markdown" },
          sync_install = false,
          highlight = { enable = true },
          indent = { enable = true },
        })
      end
    end,
  },

  -- Git Signs in Gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Auto Pairs for brackets & quotes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Commenting (gcc / gc)
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Which-Key (Keybinding Popup Cheat Sheet)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({})
    end,
  },
})

-- ------------------------------------------------------------------------------
-- 4. KEYBINDINGS (Leader = Space)
-- ------------------------------------------------------------------------------
local keymap = vim.keymap.set
local opts = { silent = true, noremap = true }

-- Quick Save & Quit
keymap("n", "<leader>w", ":w<CR>", { desc = "Save file" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit file" })
keymap("n", "<leader>qa", ":qa!<CR>", { desc = "Quit all without saving" })
keymap("n", "<leader>c", ":bdelete<CR>", { desc = "Close buffer" })

-- Clear Search Highlights
keymap("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Toggle File Explorer
keymap("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })

-- Telescope Keymaps
keymap("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
keymap("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep (Search text)" })
keymap("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
keymap("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })

-- Bufferline Navigation (Next / Previous tab)
keymap("n", "<Tab>", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
keymap("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { desc = "Previous buffer" })

-- Easy Window Navigation (Ctrl + h/j/k/l)
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize splits with arrow keys
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Move lines up/down in Visual mode
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Stay in indent mode when indenting text in Visual mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)
