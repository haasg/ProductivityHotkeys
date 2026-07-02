-- Tune rust-analyzer for a large multi-crate workspace.
return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = false },
            check = { command = "clippy" },
          },
        },
      },
    },
  },
}
