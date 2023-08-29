local neorg = require('neorg.core')

local module = neorg.modules.create('external.notes')


module.setup = function()
    return {
        success = true,
        requires = {
            -- "core.keybinds",
            -- "core.integrations.treesitter",
            "core.ui",
            -- "core.dirman.utils",
			"core.neorgcmd",
        },
    }
end

module.config.public = {

	dossiers = {
		default = {
			structure = {
				["mod-%d"] = {
					"syllabus",
					"notes",
				},
			},
			grouping = {},
		},
	},



}

module.load = function ()
	-- module.required["core.neorgcmd"].add_commands_from_table({

	-- })

end


module.public = {

	ok = function()

		for key, val in pairs(module.config.public.dossiers.structure)
			do
			print(key)
			print(vim.inspect(module.config.public.dossiers.structure[key]))
		end


	end,

	woor = function()

		local obj = vim.fn.jobstart({"ok.sh"}, {
			on_stdout = function(text, te)
				print(text)
				print(vim.inspect(te))
			end,

			-- rpc = true,
			-- pty = true,

			-- on_stdin = "pipe"

		})

		local ns_id = vim.api.nvim_create_namespace("NOTES")

		local text = { "ls" }

		vim.api.nvim_buf_set_extmark(0, ns_id, 4, 0, {virt_text = { text } })

		-- vim.rpcnotify(0, "hello\n", "hello\n")
		-- :("hai form lhlsd\n")
		-- :write("ok freom \n")
		-- print(type(obj))
		-- obj:write("hai\n")


	end,

	testing = function()

		-- local items = {}

		-- local str = "hai\nhello"

		-- for line in string.gmatch(str, "[^\n]+")
		-- 	do
		-- 	print(line)
		-- 	items[#items + 1] = line
		-- end

		vim.api.nvim_buf_set_lines(0, 2, 5, false, {"1***", "2***", "3***"})
		print(vim.inspect(module.required["core.ui"].begin_selection))

	end,

	hai = function()
		local buffer = module.required["core.ui"]
			.create_norg_buffer("hai", "split")
			-- :listener("delete-buffer", {
			-- 	"<Esc>",
			-- }, function(self)
			-- 		self:destroy()
			-- 	end)

		-- print(vim.inspect(module.required["core.ui"].begin_selection(buffer)))

		local selection = module.required["core.ui"]
			.begin_selection(buffer)
            :listener("go-back", { "l" }, function()
				vim.cmd("set ma")
				vim.api.nvim_buf_set_lines(0, 0, 0, 0, {"hai"})
				print("you cant go back")
				vim.cmd("set noma")
            end)
			:apply({
				warning = function(self, text)
					return self:text("WARNING: " .. text, "@text.warning")
				end,
				desc = function(self, text)
					return self:text(text, "@comment")
				end,
			})

		selection
		:title("This is happening")
		:blank()
		:text("* Something is not is int lk instaerlsing thaljllfkdlfkdh")
		-- :desc("THis is snot j slfjlsjkfksjfj")
		:flag("C", "<-- Click Here !", function()
			print("You just clicked me!!")
		end)
		-- :warning("Don't touch this!!")

	end



}

return module
