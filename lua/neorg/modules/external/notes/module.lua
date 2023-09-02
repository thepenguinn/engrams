local neorg = require('neorg.core')
local Path = require('plenary.path')

local module = neorg.modules.create('external.notes')
local utils = neorg.utils


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
				["mod-<%d>"] = {
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
			-- condition = "norg",
			name = "dossier"

		},


	})

end


module.config.private = {

	loaded_files = {},

	grouped = {
		["ssl"] = {
			{
				-- if any of these values are nil then we will try to
				-- reads it from the first file's meta, if that is also nil,
				-- it will be the string "nil"
				title = nil,
				description = nil,
				authors = {},
				categories = {},
				created = nil,
				updated = nil,
				file_name = nil,
				files = {
					"mod-1/syllabus.norg",
					"mod-2/syllabus.norg",
				},
			},
			{
				title = nil,
				files = {
					"mod-1/notes.norg",
				},
			},
			{
				title = nil,
				files = {
					"mod-2/notes.norg",
				},
			},
		},

		["hai"] = {
			{
				title = nil,
				files = {
					"mod-1/syllabus.norg",
					"mod-2/syllabus.norg",
				},
			},
			{
				title = nil,
				files = {
					"mod-1/notes.norg",
				},
			},
			{
				title = nil,
				files = {
					"mod-2/notes.norg",
				},
			},
		},
	},

}


module.private = {

	--- @param file # path of the file
	--- @return number? # bufnr of the loaded file
	get_buf = function(file)

		if module.config.private.loaded_files[file].bufnr then
			return module.config.private.loaded_files[file].bufnr
		end

		local file_obj = Path:new(file)

		if not file_obj:is_file() then
			return nil
		end

		local bufnr = vim.api.nvim_create_buf(false, true)

		local str = file_obj:read()
		local tbl = {}

		for line in str:gmatch("[^\n]+") do
			tbl[#tbl + 1] = line
		end

		vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, tbl)

		module.config.private.loaded_files[file].bufnr = bufnr

		return bufnr

	end,

	--- @param files # array of file paths, if its nil disposes every entry in the
	--- module.config.private.loaded_files
	del_buf = function(files)
		if files then
			for _, file in pairs(files) do
				module.config.private.loaded_files[file] = nil
			end
		else
			module.config.private.loaded_files = nil
		end
	end,

}

module.public = {

	get_hai = function()

		local buf1 = module.private.get_buf("exported.md")
		local buf2 = module.private.get_buf("hai.html")
		print(vim.fs.normalize(
			"$PWD" .. "/exported.md"
		))
		print("     ", buf1, buf2)
		local tbl = vim.api.nvim_buf_get_lines(buf2, 0, -1, false)

		vim.api.nvim_buf_set_lines(0, 0, 1, false, tbl)
		print(vim.inspect(
			tbl
		))



		-- local bufnr

		-- local str = Path:new("index.norg"):read()

		-- local tbl = {}

		-- for line in str:gmatch("[^\n]+")
		-- 	do
		-- 	tbl[#tbl + 1] = line
		-- end

		-- vim.api.nvim_buf_set_text(0, 0, 0, 0, 0, tbl)


		-- vim.cmd("read index.norg")
		-- when reading `read index.norg` it will leave an empty line
		-- at the top, if we leave it there it will cause the exporter
		-- to mess up the metadata part of the document
		-- Probably a parser issue ?
		--
		-- vim.api.nvim_buf_set_text(0, 0, 0, 1, 0, { "" })

		-- str = module.required["core.export"].export(0, "markdown")

		-- local ano_tbl = {}

		-- for line in str:gmatch("[^\n]+")
		-- 	do
		-- 	ano_tbl[#ano_tbl + 1] = line
		-- end

		-- vim.api.nvim_buf_set_text(0, 0, 0, -1, 0, ano_tbl)

		-- -- local lTree = vim.treesitter.get_parser(0, "norg")


		-- -- local root = lTree:()

		-- for dossier, dossier_content in pairs(module.config.private.grouped)
		-- do
		-- 	print("----------------------------------------")
		-- 	print (dossier)
		-- 	print(vim.inspect(
		-- 		dossier_content
		-- 	))
		-- 	print("----------------------------------------")
		-- end

	end,

	get_bye = function()

		-- local query = utils.ts_parse_query(
		-- 	"norg_meta",
		-- 	[[
		-- 	(pairs
		-- 	(key) @k
		-- 	(#eq? @k "title")
		-- 	(value) @tit
		-- 	)
		-- 	]]
		-- )

		local LTree = vim.treesitter.get_parser(0, "norg")

		LTree:for_each_child(
			function(tree)

				if tree:lang() == "norg_meta" then
					local tstree = tree:parse()[1]
					local root_node = tstree:root()

					local query = vim.treesitter.query.parse(
						"norg_meta",
						[[
						(pair
						(key) @k
						(#eq? @k "title")
						(value) @tit
						)
						]]
					)

					for idx, node in query:iter_captures(root_node, 0)
						do
						print("-----------------------------------------------")
						print(query.captures[idx])
						print(vim.inspect(
							vim.treesitter.get_node_text(node, 0)
						))
						print("-----------------------------------------------")
					end




					-- print(vim.inspect(
					-- ))
				else
					print("-----------------------------------------------")
					print(tree:lang())
					print("-----------------------------------------------")
				end

				-- print(vim.inspect(
				-- 	tree
				-- ))
				-- print("-----------------------------------------------")
			end
		)

		-- for id, node in query:iter_captures()
		-- 	do
		-- end

	end,

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
		-- print(vim.inspect(
		-- 	module.public.get_prev_export_info(vim.loop.cwd())
		-- ))
		module.public.get_hai()
	end

end


module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["dossier"] = true,
    },
}


return module
