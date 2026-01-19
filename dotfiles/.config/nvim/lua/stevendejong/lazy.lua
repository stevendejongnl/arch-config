local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        import = "stevendejong.plugins",
    },
    {
        import = "stevendejong.plugins.lsp-zero",
    },
}, {
    concurrency = 5,
    install = {
        colorscheme = { "embark" },
    },
    checker = {
        enable = true,
        notify = true,
    },
    change_detection = {
        notify = true,
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    }
})
