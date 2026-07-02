-- Branch-wide diff review: the primary tool for reviewing agent output.
return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff view (working tree)" },
    { "<leader>gD", "<cmd>DiffviewOpen main...HEAD<cr>", desc = "Diff view (branch vs main)" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
  },
}
