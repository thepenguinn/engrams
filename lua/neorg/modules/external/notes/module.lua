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

	metadata_fields = {
		"title",
		"description",
		"authors",
		"categories",
		"created",
		"updated",
		"version",
	},

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

	compiled_queries = {},

	loaded_files = {},

	grouped = {
		["ssl"] = {
			{
				-- if any of these values are nil then we will try to
				-- reads it from the first file's meta, if that is also nil,
				-- it will be the string "nil"
				metadata = {
					title = { "ssl", },
					description = { "something stupid", },
					authors = { "Daniel" },
					categories = { "cat", "dog", },
					created = nil,
					updated = nil,
				},
				output_path = "ssl/expt.md",
				files = {
					"ssl/mod-1/syllabus.norg",
					"ssl/mod-2/syllabus.norg",
				},
			},
			{
				files = {
					"ssl/mod-1/notes.norg",
				},
			},
			{
				files = {
					"ssl/mod-2/notes.norg",
				},
			},
		},

		["hai"] = {
			{
				files = {
					"hai/mod-1/syllabus.norg",
					"hai/mod-2/syllabus.norg",
				},
			},
			{
				files = {
					"hai/mod-1/notes.norg",
				},
			},
			{
				files = {
					"hai/mod-2/notes.norg",
				},
			},
		},
	},

}


module.private = {

	--- @param file # path of the file
	--- @return number? # bufnr of the loaded file
	get_buf = function(file)

		if module.config.private.loaded_files[file] then
			return module.config.private.loaded_files[file]
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

		module.config.private.loaded_files[file] = bufnr

		return bufnr

	end,

	--- @param files # array of file paths, if its nil disposes every entry
	--- in the module.config.private.loaded_files
	del_buf = function(files)
		if files then
			for _, file in pairs(files) do
				module.config.private.loaded_files[file] = nil
			end
		else
			module.config.private.loaded_files = nil
		end
	end,

	--- @param query_str # key for the which we will be querying inside
	--- document.meta
	--- @return Query? returns the Query object
	get_query = function(query_str)
		if module.config.private.compiled_queries[query_str] then
			return module.config.private.compiled_queries[query_str]
		end

		local query = vim.treesitter.query.parse(
			"norg_meta",
			[[
				(pair
				(key) @_key
				(#eq? @_key ]] .. query_str .. [[ )
			(string) @]] .. query_str .. [[
				)
				(pair
				(key) @_key
				(#eq? @_key ]] .. query_str .. [[ )
				(array
			(string) @]] .. query_str .. [[
				)
				)
			]]
		)

		module.config.private.compiled_queries[query_str] = query

		return query

	end,

	--- @param bufnr # buffer number of the buffer that wants to be parsed
	--- @return LanguageTree? # read :h LanguageTree for more info about
	--- the object
	-- get_parser = function(bufnr)
	-- 	local ltree = vim.treesitter.
	-- end,

}

module.public = {

	--- After filling metadata from the user's config, we need to
	--- fill the rest of them from the first norg file. If we can't find
	--- any field we will fill it with the string 'nil'
	--- @param bufnr # buffer number of the loaded norg file.
	--- @param dossier_info # table to which we will be appeding meta info
	--- @param meta_fields # array of meta fields as strings
	fill_missing_meta = function(bufnr, dossier_info, meta_fields)

		local ltree = vim.treesitter.get_parser(bufnr, "norg")

		local ltree_meta = nil
		ltree:for_each_child(
			function(tree)
				if not ltree_meta and tree:lang() == "norg_meta" then
					ltree_meta = tree
				end
			end
		)

		-- if we don't find any metadata, we will simply assign
		-- { "nil" } to every empty tables having fields from meta_fields
		-- in dossier_info
		if not ltree_meta then
			for _, field in pairs(meta_fields) do

			-- if field is a table and not empty, we will skip it
			if type(field) == "table" and not vim.tbl_isempty(field) then
				goto continue
			end

			dossier_info[field] = { "nil" }

				::continue::
			end

			return nil

		end

		local tstree = ltree_meta:parse()[1]
		local meta_root = tstree:root()
		local query
		local result = {}

		for _, field in pairs(meta_fields) do

			-- if field is a table and not empty, we will skip it
			if type(field) == "table" and not vim.tbl_isempty(field) then
				goto continue
			end

			local query = module.private.get_query(field)

			for idx, node in query:iter_captures(meta_root, bufnr) do

				if query.captures[idx] == field then
					result[#result + 1] = vim.treesitter.get_node_text(node, bufnr)
				end

			end

			if vim.tbl_isempty(result) then
				result = { "nil" }
			end

			dossier_info[field] = result
			result = {}

			::continue::

		end

	end,

	--- compiles a buffer from the info in the export_group table
	--- and returns the bufnr to the that buffer
	--- @param export_idx # export_id of the export_group
	--- @param export_group # table of every export info to generate
	--- the buffer to export
	--- @return number? # bufnr of the compiled buffer
	compile_export_buffer = function(export_id, export_group)

		if type(export_group) ~= "table"
			or type(export_group.files) ~= "table"
			or vim.tbl_isempty(export_group.files) then
			return nil
		end

		local scratch_bufnr = vim.api.nvim_create_buf(false, true)
		local output_bufnr = vim.api.nvim_create_buf(false, true)

		local meta_bufnr = module.private.get_buf(export_group.files[1])

		module.public.fill_missing_meta(
			meta_bufnr,
			export_group.metadata,
			module.config.public.metadata_fields
		)

		if not export_group.output_path then
			local dir = vim.fs.dirname(export_group.files[1])
			local export_file = vim.fs.basename(export_group.files[1])
			export_file = export_file:gsub("(.*)(%..*)"
				, "%1-export-" .. export_id .. ".md")
			print(export_file)
			export_group.output_path = dir .. "/" .. export_file
		end

		print("-------------------------------")
		print(vim.inspect(
			export_group
		))
		print("-------------------------------")

	end,

	--- @param dossier_tree # a table containing each dossier's info
	--- @return table? # compiles all the info for each dossier into a
	--- buffer and attaches it to compiled_buffer at each dossier's table,
	--- it will be in the norg format.
	compile_dossiers = function(dossier_tree)

		local srch_buf = vim.api.nvim_create_buf(false, true)

		for _, dossier in pairs(dossier_tree) do

			for idx, export_group in ipairs(dossier) do

				if not export_group.metadata then
					export_group.metadata = {}
				end

				module.public.compile_export_buffer(idx, export_group)

				-- print("--------------------------")
				-- print(vim.inspect(
				-- 	export_group
				-- ))
				-- print("--------------------------")

			end
		end



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

	foooo = function()

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

	gen_markdwn = function()


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

		module.public.compile_dossiers(module.config.private.grouped)
		-- local bufnr1 = vim.api.nvim_create_buf(false, true)
		-- local hai = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		-- vim.api.nvim_buf_set_lines(bufnr1, 0, 1, false, hai)
		-- local tbl = {}

		-- module.public.fill_missing_meta(bufnr1, tbl, module.config.public.metadata_fields)

		-- tbl = {}
		-- local bufnr2 = vim.api.nvim_create_buf(false, true)
		-- vim.api.nvim_buf_set_lines(bufnr2, 0, 1, false, hai)

		-- module.public.fill_missing_meta(bufnr2, tbl, module.config.public.metadata_fields)

		-- print(vim.inspect(
		-- 	tbl
		-- ))

	end

end


module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["dossier"] = true,
    },
}


return module
