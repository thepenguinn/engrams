local neorg = require('neorg.core')
local Path = require('plenary.path')

local module = neorg.modules.create('external.notes')


module.setup = function()
    return {
        success = true,
        requires = {
            -- "core.keybinds",
            "core.integrations.treesitter",
            "core.ui",
            -- "core.dirman.utils",
			"core.export",
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
			grouping = {
				[1] = { "<all>" }
			},
		},
	},



}

module.load = function ()
	module.required["core.neorgcmd"].add_commands_from_table({

		dossier = {

			args = 0,
			condition = "norg",
			name = "dossier"

		},


	})

end


module.config.private = {

	grouped = {
		["ssl"] = {
			["ssl Syllabus"] = {
				"mod-1/syllabus.norg",
				"mod-2/syllabus.norg",
			},

			["ssl mod-1 Notes"] = {
				"mod-1/notes.norg",
			},

			["ssl mod-2 Notes"] = {
				"mod-2/notes.norg",
			},
		},
		["hai"] = {
			["hai Syllabus"] = {
				"mod-1/syllabus.norg",
				"mod-2/syllabus.norg",
			},

			["hai mod-1 Notes"] = {
				"mod-1/notes.norg",
			},

			["hai mod-2 Notes"] = {
				"mod-2/notes.norg",
			},
		},
	},

}



module.public = {

	--- @param dossier_root string # path to the directory
	--- @return table? # reads the json inside
	--- dossier_root/exported/export_info.json and returns it as a table if it
	--- doesn't exist returns nil
	get_prev_export_info = function(dossier_root)
		local obj = Path:new(dossier_root .. "/exported/export_info.json")

		if not obj:is_file() then
			return nil
		end

		return vim.json.decode(
			obj:read()
		)
	end,

	gen_markdown = function()


		local file_name = "exported.md"
		local export_path = vim.loop.cwd() .. "/" .. file_name
		local exported_text = module.required["core.export"].export(0, "markdown")


		Path:new(export_path):write(exported_text, "w")

		print("current buf has been exported to " .. export_path)

	end,


	read_config = function()

		-- local tbl = {
		-- 	hai = "haiin",
		-- 	sih = "haiin",
		-- 	lod = "haiin",
		-- 	fdre = "haiin",
		-- 	hal = "haiin",
		-- 	haill = "haiin",
		-- 	haill = {

		-- 		anoth = {
		-- 			"whid",
		-- 			"lo",
		-- 		},

		-- 		ifir = {

		-- 			"ifwhid",
		-- 			"iflo",
		-- 		},

		-- 	},
		-- }

		local config_path = vim.loop.cwd() .. "/thisis.json"
		print(config_path)
		-- Path:new(config_path):write(vim.json.encode(tbl), "w")
		print(vim.inspect(
			vim.json.decode(Path:new(config_path):read())
		))

	end,


	first = function()

		local ts_utils = module.required["core.integrations.treesitter"].get_ts_utils()

		module.config.private.nodes = ts_utils.get_node_at_cursor(0)

	end,

	ok = function()

		local tree = {}

		local ts_utils = module.required["core.integrations.treesitter"].get_ts_utils()

		local node = ts_utils.get_node_at_cursor(0)
		print(vim.inspect(
			ts_utils
			-- vim.treesitter.get_node_text(node, 0)
			-- ts_utils.swap_nodes(module.config.private.nodes, node, 0)
		))

		-- for path in vim.fs.dir(vim.loop.cwd(), {depth = math.huge})
		-- 	do
		-- 	if vim.fn.isdirectory(path) ~= 0 then
		-- 		-- if tree[path]
		-- 		print(path)
		-- 	end

		-- end

		-- Get all the files in the cwd --

		-- local scan = require'plenary.scandir'
		-- print(vim.inspect(scan.scan_dir('.', {
		-- 	hidden = true,
		-- 	add_dirs = true,
		-- 	depth = math.huge
		-- 	}
		-- )))

	end,

	ooo = function()

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

module.on_event = function(event)

	if event.type == "core.neorgcmd.events.dossier" then
		-- print(vim.inspect(event))
		print(vim.inspect(
			module.public.get_prev_export_info(vim.loop.cwd())
		))
	end

end



module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["dossier"] = true,
    },
}


return module
