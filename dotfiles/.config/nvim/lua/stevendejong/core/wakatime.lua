--[[local notify = require("notify")
vim.notify = notify

local function printWakaTime()
    local command = os.getenv("HOME") .. "/.wakatime/wakatime-cli --today"
    local command_output = io.popen(command):read("*a")

    notify(command_output, "info", {
        title = "WakaTime"
    })
end



local function periodicPrintWakaTime()
    printWakaTime()
    vim.defer_fn(periodicPrintWakaTime, 1800000)  -- 300000 ms = 5 minuten
end

periodicPrintWakaTime()
]]--
