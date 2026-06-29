return {
  -- CSV / TSV を列ごとにレインボーハイライト
  "mechatroner/rainbow_csv",
  ft = { "csv", "tsv", "psv" },
  init = function()
    -- .UKE (レセプト電子請求ファイル) を CSV として扱う
    vim.filetype.add({
      extension = {
        UKE = "csv",
        uke = "csv",
      },
    })
  end,
}
