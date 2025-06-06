---@class D2Options
---@field theme_id? number
---@field dark_theme_id? number
---@field scale? number
---@field layout? string
---@field sketch? boolean

---@type table<string, string>

---@class Renderer<D2Options>
local M = {
	id = "d2",
}

-- fs cache
local cache_dir = vim.fn.resolve(vim.fn.stdpath("cache") .. "/diagram-cache/d2")
vim.fn.mkdir(cache_dir, "p")

---@param source string
---@param options D2Options
---@return table|nil
M.render = function(source, options)
	local hash = vim.fn.sha256(M.id .. ":" .. source)

	local path = vim.fn.resolve(cache_dir .. "/" .. hash .. ".png")
	if vim.fn.filereadable(path) == 1 then
		return { file_path = path }
	end

	if not vim.fn.executable("d2") then
		error("diagram/d2: d2 not found in PATH")
	end

	local tmpsource = vim.fn.tempname()
	vim.fn.writefile(vim.split(source, "\n"), tmpsource)

	local command_parts = {
		"d2",
		tmpsource,
		path,
	}
	if options.theme_id then
		table.insert(command_parts, "-t")
		table.insert(command_parts, options.theme_id)
	end
	if options.dark_theme_id then
		table.insert(command_parts, "--dark-theme")
		table.insert(command_parts, options.dark_theme_id)
	end
	if options.scale then
		table.insert(command_parts, "--scale")
		table.insert(command_parts, options.scale)
	end
	if options.layout then
		table.insert(command_parts, "--layout")
		table.insert(command_parts, options.layout)
	end
	if options.sketch then
		table.insert(command_parts, "-s")
	end

	local on_exit = function(obj)
		if obj.code ~= 0 then
			vim.schedule(function()
				vim.notify("diagram/d2: d2 failed to render diagram: " .. obj.stderr, vim.log.levels.ERROR)
			end)
		end
	end
	vim.system(command_parts, { text = true, timeout = 10000 }, on_exit)

	return { file_path = path }
end

return M
