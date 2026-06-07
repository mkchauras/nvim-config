-- mason/mason-lspconfig/nvim-lspconfig

local nproc = vim.fn.systemlist("nproc")[1]

local ensure_installed_servers = {
	"clangd",
	"lua_ls",
	"rust_analyzer",
	"pylsp",
}

local server_opts = {
	["clangd"] = {
		cmd = {
			"clangd",
			"--header-insertion=never",
			"-j=" .. nproc,
			"--completion-style=detailed",
			"--function-arg-placeholders",
			"--rename-file-limit=0",
			"--background-index",
			"--background-index-priority=normal",
		},
		filetypes = {"c", "cpp", "objc", "objcpp", "asm"},
	},

	["lua_ls"] = {
		settings = {
			Lua = {
				runtime = {
					-- Tell the language server which version of Lua you're using
					-- (most likely LuaJIT in the case of Neovim)
					version = 'LuaJIT'
				},
				-- Make the server aware of Neovim runtime files
				workspace = {
					checkThirdParty = false,
					library = {
						vim.env.VIMRUNTIME,
						vim.fn.stdpath("data") .. "/lazy/",
						-- "${3rd}/luv/library"
						-- "${3rd}/busted/library",
					},
					-- or pull in all of 'runtimepath'. NOTE: this is a lot slower
					-- library = vim.api.nvim_get_runtime_file("", true)
				},
			},
		},
	},

	["pylsp"] = {
		cmd = { "pylsp" },
		filetypes = { "python" }
	},

	["rust_analyzer"] = {
		settings = {
			["rust-analyzer"] = {
				cargo = {
					allFeatures = true,
					loadOutDirsFromCheck = true,
					buildScripts = {
						enable = true,
					},
				},
				checkOnSave = {
					enable = true,
					command = "clippy",
					extraArgs = { "--no-deps" },
				},
				procMacro = {
					enable = true,
					ignored = {
						["async-trait"] = { "async_trait" },
						["napi-derive"] = { "napi" },
						["async-recursion"] = { "async_recursion" },
					},
				},
				diagnostics = {
					enable = true,
					disabled = {},
					enableExperimental = true,
				},
				inlayHints = {
					bindingModeHints = {
						enable = false,
					},
					chainingHints = {
						enable = true,
					},
					closingBraceHints = {
						enable = true,
						minLines = 25,
					},
					closureReturnTypeHints = {
						enable = "never",
					},
					lifetimeElisionHints = {
						enable = "never",
						useParameterNames = false,
					},
					maxLength = 25,
					parameterHints = {
						enable = true,
					},
					reborrowHints = {
						enable = "never",
					},
					renderColons = true,
					typeHints = {
						enable = true,
						hideClosureInitialization = false,
						hideNamedConstructor = false,
					},
				},
			},
		},
	},

}

local common_capabilities = vim.tbl_deep_extend(
	"force",
	{},
	vim.lsp.protocol.make_client_capabilities(),
	require('cmp_nvim_lsp').default_capabilities() or {}
)

local server_handlers = {
	function (server_name)
		local opts = vim.tbl_deep_extend("force", {
			capabilities = vim.deepcopy(common_capabilities),
		}, server_opts[server_name] or {})
		require('lspconfig')[server_name].setup(opts)
	end,
}

local mason_opts = {
	ui = {
		border = "rounded",
		icons = {
			package_installed = "◍",
			package_pending = "◍",
			package_uninstalled = "◍",
		},
	},
	log_level = vim.log.levels.INFO,
	max_concurrent_installers = 4,
}

require('mason').setup(mason_opts)
require('mason-lspconfig').setup({
	ensure_installed = ensure_installed_servers,
	automatic_installation = true,
	handlers = server_handlers,
})


vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function()
    local bufmap = function(mode, lhs, rhs)
      local opts = {buffer = true}
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    bufmap('n', '<C-]>', '<cmd>lua vim.lsp.buf.definition()<CR>zz')
    bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
    bufmap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  end
})

-- Diagnostics
vim.diagnostic.config({
  float = { source = "always", border = "rounded" },
  virtual_text = false,
  underline = false,
  signs = true,
})

vim.keymap.set('n', '<C-E>', function()
	-- If we find a floating window, close it.
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(win).relative ~= '' then
			vim.api.nvim_win_close(win, true)
			return
		end
	end

	vim.diagnostic.open_float(nil, { focus = false })
end, { desc = 'Toggle Diagnostics' })

vim.lsp.handlers["textDocument/hover"] = function(...)
	local buf, method, result, client_id, bufnr, config = ...
	config = config or {}
	config.border = "rounded"
	return vim.lsp.handlers.hover(...)
end
