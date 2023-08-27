local neorg = require('neorg.core')

local module = neorg.modules.create('external.notes')

module.load = function ()
	print('Hello world!')
end

return module
