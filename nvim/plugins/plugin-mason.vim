lua << EOF
    local mason = require('mason')
    local lspconfig = require('lspconfig')
    local mason_lspconfig = require('mason-lspconfig')

    mason.setup()
    mason_lspconfig.setup {
        ensure_installed = {
            "lua_ls",
			"bashls",
			"clangd",
			"cmake",
			"cssls",
			"gopls",
			"html",
			"jsonls",
			"marksman",
            "kotlin_language_server",
            "ruby_lsp",
            "hls",
            "elmls",
            "elixirls",
            "vimls",
            "sqls",
            "markdown_oxide",
            "jsonls",
        }
    }
    mason_lspconfig.setup_handlers({
        function(server_name)
            server_name = server_name == 'tsserver' and 'ts_ls' or server_name
            lspconfig[server_name].setup({})
        end
    })
EOF

