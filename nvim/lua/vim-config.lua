-- Map leader --
vim.g.mapleader = " "

-- Add Line Numbers --
vim.opt.nu = true

-- Colors --

-- Tabs --
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- Smartindent --
vim.opt.smartindent = true

-- Remaps --
vim.keymap.set("v", "<D-<M-[>>", ":m '>+1<CR>gv=gv")
vim.keymap.set("n", "¯", ":%s/>,/>,\\r/g<CR>")

-- Copy and Paste --
vim.keymap.set('v', '<leader>c', '"+y')
vim.keymap.set('n', '<leader>p', '"+p')

-- Make this mode do nothing --
vim.keymap.set("n", "Q", "<nop>")

-- Relative Line Numbers --
vim.wo.relativenumber = true

-- Save --
vim.keymap.set({"n", "v"}, "<leader>s", ":w<CR>")

-- Quit --
vim.keymap.set({"n", "v"} , "<leader>q", ":qa<CR>")
vim.keymap.set({"n", "v"} , "<leader>c", ":q<CR>")
vim.keymap.set("n", "<leader>Q", ":qa!<CR>")
vim.keymap.set("v", "<leader>Q", "<Esc>:qa!<CR>")
vim.keymap.set("n", "<leader>w", ":wqa<CR>")
vim.keymap.set("v", "<leader>w", "<Esc>:wqa<CR>")

-- End of file --
vim.opt.fillchars = { eob = " " }

-- Don't yank when I paste inside of quotes --
vim.keymap.set("x", "p", "\"_dP")

-- System Copy --
vim.keymap.set({"n", "v"}, "<leader>y", "\"+y")

-- Command + s to save --

vim.keymap.set({"n", "v"}, "<D-s>", ':w<CR>')

-- Wrap Lines --
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.showbreak = '↪'

-- GitHub Copilot --
-- Not sure if this is working...
vim.g.copilot_settings = { selectedCompletionModel = 'claude-3.7-sonnet' }

-- Notes about shortcuts --
-- <leader> is space
-- <M-[> is alt + [
-- <A-[> is alt + [
-- <D-[> is cmd + [
-- <C-[> is ctrl + [
--
-- <CR> is enter
-- <Esc> is escape
-- <Tab> is tab
-- <BS> is backspace
-- <Del> is delete
-- <Space> is space
-- <Up> is up arrow
-- <Down> is down arrow
-- <Left> is left arrow
-- <Right> is right arrow
--
-- <C-a> is ctrl + a (etc)

-- Notes about neovim shortcuts --
-- gcc to comment line
-- gc to comment selection
