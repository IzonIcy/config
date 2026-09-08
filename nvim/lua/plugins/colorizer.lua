local function with_tbl_flatten_compat(callback)
	if not vim.iter then
		return callback()
	end

	local original = vim.tbl_flatten
	vim.tbl_flatten = function(tbl)
		return vim.iter(tbl):flatten():totable()
	end

	local ok, err = pcall(callback)
	vim.tbl_flatten = original

	if not ok then
		error(err)
	end
end

with_tbl_flatten_compat(function()
	require("colorizer").setup({ "*" }, {
		RGB = true, -- #RGB hex codes
		RRGGBB = true, -- #RRGGBB hex codes
		names = false, -- "Name" codes like Blue
		RRGGBBAA = true, -- #RRGGBBAA hex codes
		rgb_fn = true, -- CSS rgb() and rgba() functions
		hsl_fn = true, -- CSS hsl() and hsla() functions
		css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
		css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
	})
end)
