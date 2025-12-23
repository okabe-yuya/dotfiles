return {
  "keaising/im-select.nvim",
  config = function()
    require("im_select").setup({
      default_im_select = "com.apple.keylayout.ABC", -- 半角英数
      set_default_events = { "VimEnter", "InsertLeave", "FocusGained" },
      set_previous_events = {},                      -- 必要なら
    })
  end
}
