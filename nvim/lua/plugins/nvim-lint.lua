local lint = require("lint")

lint.linters_by_ft = {
	lua = { "luac" },
	python = { "ruff" },
	sh = { "shellcheck" },
	bash = { "shellcheck" },
	c = { "cppcheck" },
	rust = { "clippy" },
	css = { "stylelint" },
	html = { "htmlhint" },
}
