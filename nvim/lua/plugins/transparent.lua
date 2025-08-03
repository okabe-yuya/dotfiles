return {
  'xiyaowong/transparent.nvim',
  lazy = false,
  opts = {
    groups = {
      -- デフォルトで透明にしたいグループ
      'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
      'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
      'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
      'SignColumn', 'CursorLine', 'CursorLineNr', 'StatusLine', 'StatusLineNC',
      'EndOfBuffer', 'VertSplit'
    },
    extra_groups = {
      -- Diagnostic
      'DiagnosticSignWarn',
      'DiagnosticSignError',
      'DiagnosticSignInfo',
      'DiagnosticSignHint',
      'FloatTitle',
      'NormalFloat',
      'FloatBorder',
      'SagaNormal',
      'LspSagaBorderTitle',
      'LspFloatWinBorder',

      -- GitSigns
      'GitSignsAdd',
      'GitSignsChange',
      'GitSignsDelete',

      -- Telescope
      'TelescopeNormal',
      'TelescopeBorder',
      'TelescopePromptBorder',
      'TelescopeResultsBorder',
      'TelescopePreviewBorder',

      -- nvim-tree
      'NvimTreeNormal',
      'NvimTreeNormalNC',
      'NvimTreeEndOfBuffer',
      'NvimTreeWinSeparator',

      -- Tabline
      'BufferTabpageFill',
      'TabLineFill',
    },
    exclude_groups = {},
    on_clear = function() end,
  },
}
