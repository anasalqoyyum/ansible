local autocmd = vim.api.nvim_create_autocmd

local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- change to the directory
	vim.cmd.cd(data.file)

	-- open the tree
	require("nvim-tree.api").tree.open()
end

autocmd("VimEnter", {
	callback = open_nvim_tree,
})

-- auto resize panes when resizing nvim window
-- autocmd("vimresized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
