return {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" }, -- SchemaStore.nvim supplies schemas
      schemas = require("schemastore").yaml.schemas(),
      keyOrdering = false,
    },
  },
}
