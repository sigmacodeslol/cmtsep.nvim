local M = {}

local comment_patterns = {
	lua = { start = "--", line = "--", finish = "--" },
	python = { start = "#", line = "#", finish = "#" },
	javascript = { start = "/*", line = "//", finish = "*/" },
	typescript = { start = "/*", line = "//", finish = "*/" },
	c = { start = "/*", line = "//", finish = "*/" },
	cpp = { start = "/*", line = "//", finish = "*/" },
	java = { start = "/*", line = "//", finish = "*/" },
	vim = { start = '"', line = '"', finish = '"' },
	sh = { start = "#", line = "#", finish = "#" },
	go = { start = "/*", line = "//", finish = "*/" },
	rust = { start = "/*", line = "//", finish = "*/" },
	html = { start = "<!--", line = "<!--", finish = "-->" },
	css = { start = "/*", line = "/*", finish = "*/" },
	php = { start = "/*", line = "//", finish = "*/" },
	ruby = { start = "#", line = "#", finish = "#" },
}

local function get_filetype_completion(arg_lead, _, _)
	local filetypes = vim.fn.getcompletion(arg_lead, "filetype")
	return filetypes
end

function M.add_language(lang)
	if lang == "" then
		vim.notify("No language specified for :Cmtsep add", vim.log.levels.ERROR)
		return
	end
	local pattern = comment_patterns[lang] or {}
	local default_start = pattern.start or ""
	local default_line = pattern.line or ""
	local default_finish = pattern.finish or ""
	local start = vim.fn.input("Enter the start comment string: ", default_start)
	if start == "" then
		vim.notify(
			"Cancelled: No start comment string provided",
			vim.log.levels.WARN
		)
		return
	end
	local line = vim.fn.input("Enter the line comment string: ", default_line)
	if line == "" then
		vim.notify(
			"Cancelled: No line comment string provided",
			vim.log.levels.WARN
		)
		return
	end
	local finish =
		vim.fn.input("Enter the finish comment string: ", default_finish)
	if finish == "" then
		vim.notify(
			"Cancelled: No finish comment string provided",
			vim.log.levels.WARN
		)
		return
	end
	comment_patterns[lang] =
		{ start = start, line = line, finish = finish, use = true }
	vim.notify(
		"Added/updated '"
			.. lang
			.. "' with use = true. Update comment_patterns in the script to persist changes.",
		vim.log.levels.INFO
	)
end

function M.remove_language(lang)
	if lang == "" then
		vim.notify("No language specified for :Cmtsep remove", vim.log.levels.ERROR)
		return
	end
	if comment_patterns[lang] then
		comment_patterns[lang].use = false
		vim.notify(
			"'"
				.. lang
				.. "' marked as unusable. Update comment_patterns in the script to persist changes.",
			vim.log.levels.INFO
		)
	else
		vim.notify(
			"'" .. lang .. "' not found in comment_patterns database.",
			vim.log.levels.WARN
		)
	end
end

function M.insert_comment_block()
	local filetype = vim.bo.filetype
	local pattern_candidate = comment_patterns[filetype]
	local usable = pattern_candidate and pattern_candidate.use == true
	local pattern
	if not usable then
		local message
		if not pattern_candidate then
			message = "The language '" .. filetype .. "' is not in comment_patterns."
		else
			local use_status = pattern_candidate.use == true and "true"
				or pattern_candidate.use == false and "false"
				or "not set"
			message = "The language '"
				.. filetype
				.. "' is in comment_patterns with use = "
				.. use_status
				.. " and is unusable."
		end
		vim.notify(message, vim.log.levels.WARN)
		local response =
			vim.fn.input("Do you want to make this language usable? (y/n): ")
		if response:lower() ~= "y" then
			return
		end
		local default_start = pattern_candidate and pattern_candidate.start or ""
		local default_line = pattern_candidate and pattern_candidate.line or ""
		local default_finish = pattern_candidate and pattern_candidate.finish or ""
		local start =
			vim.fn.input("Enter the start comment string: ", default_start)
		if start == "" then
			vim.notify(
				"Cancelled: No start comment string provided",
				vim.log.levels.WARN
			)
			return
		end
		local line = vim.fn.input("Enter the line comment string: ", default_line)
		if line == "" then
			vim.notify(
				"Cancelled: No line comment string provided",
				vim.log.levels.WARN
			)
			return
		end
		local finish =
			vim.fn.input("Enter the finish comment string: ", default_finish)
		if finish == "" then
			vim.notify(
				"Cancelled: No finish comment string provided",
				vim.log.levels.WARN
			)
			return
		end
		comment_patterns[filetype] =
			{ start = start, line = line, finish = finish, use = true }
		vim.notify(
			"Added/updated '"
				.. filetype
				.. "' with use = true. Update comment_patterns in the script to persist changes.",
			vim.log.levels.INFO
		)
		pattern = comment_patterns[filetype]
	else
		pattern = pattern_candidate
	end
	local width = 80
	local title = " SECTION SEPARATOR "
	local border_char = "═"
	local corner_char = "╬"
	local side_char = "║"
	local padding_char = " "
	local border_line = corner_char
		.. string.rep(border_char, width - #pattern.line - 4)
		.. corner_char
	local padded_line = side_char
		.. string.rep(padding_char, width - #pattern.line - 4)
		.. side_char
	local title_padding = math.floor((width - #pattern.line - #title - 4) / 2)
	local title_line = side_char
		.. string.rep(padding_char, title_padding)
		.. title
		.. string.rep(
			padding_char,
			width - #pattern.line - #title - title_padding - 4
		)
		.. side_char
	local comment_block = {
		pattern.start .. border_line,
		pattern.line .. padded_line,
		pattern.line .. title_line,
		pattern.line .. padded_line,
		pattern.finish .. border_line,
		"",
	}
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line = cursor_pos[1] - 1
	vim.api.nvim_buf_set_lines(0, line, line, false, comment_block)
	vim.api.nvim_win_set_cursor(0, { line + #comment_block + 1, 0 })
end

function M.setup(opts)
	opts = opts or {}
	if opts.preset == "sigmacodeslol" then
		for _, lang in ipairs({ "lua", "python", "c", "cpp" }) do
			if comment_patterns[lang] then
				comment_patterns[lang].use = true
			end
		end
	end
	vim.keymap.set("n", "<Leader>cb", M.insert_comment_block, {
		noremap = true,
		silent = true,
		desc = "Insert beautified comment block separator",
	})
	vim.api.nvim_create_user_command("Cmtsep", function(cmd_opts)
		local args = vim.split(cmd_opts.args, " ")
		local action = args[1]
		local lang = args[2] or ""
		if action == "add" then
			M.add_language(lang)
		elseif action == "remove" then
			M.remove_language(lang)
		else
			vim.notify("Invalid action: use 'add' or 'remove'", vim.log.levels.ERROR)
		end
	end, {
		nargs = "+",
		complete = function(arg_lead, cmd_line, _)
			local args = vim.split(cmd_line, " ")
			if #args <= 2 then
				return { "add", "remove" }
			elseif #args == 3 then
				return get_filetype_completion(arg_lead)
			end
			return {}
		end,
	})
end

return M
