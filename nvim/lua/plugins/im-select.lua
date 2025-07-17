local M = {}

function M.setup()
  require("im-select").setup({
    default_im_select = "com.apple.keylayout.ABC", -- macOSの英語キーボード
    set_default_events = {"InsertLeave"}, -- インサートモードを抜けたときに入力メソッドを設定
  })
end

return M