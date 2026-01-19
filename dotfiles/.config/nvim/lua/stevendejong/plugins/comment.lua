return {
  "numToStr/Comment.nvim",
  enabled = true,
  event = "InsertEnter",
  config = function()
    require('Comment').setup()
  end
}
