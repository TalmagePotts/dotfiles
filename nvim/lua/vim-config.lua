-- Map leader --
vim.g.mapleader = " "

-- Add Line Numbers --
vim.opt.nu = true

-- Tabs --
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- Smartindent --
smartindent = true

-- Remaps --

vim.keymap.set("v", "<D-<M-[>>", ":m '>+1<CR>gv=gv")
vim.keymap.set("n", "¯", ":%s/>,/>,\\r/g<CR>")

-- Copy and Paste --
vim.keymap.set('v', '<leader>c', '"+y')
vim.keymap.set('n', '<leader>p', '"+p')

-- Make this mode do nothing --
vim.keymap.set("n", "Q", "<nop>")

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

-- Get rid of delete adding to register --
vim.keymap.set("n", "dd", '"_dd')
vim.keymap.set("n", "D", '"_D')
vim.keymap.set({"n", "v"}, "s", '_s')
vim.keymap.set({"n", "v"}, "S", '"_S')

-- Notes about shortcuts --
-- <leader> is space
-- <M-[> is alt + [
-- <D-[> is ctrl + [
-- <C-[> is cmd + [
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
