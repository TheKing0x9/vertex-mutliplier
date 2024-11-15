local core = require 'scripts.core'

local tb_stub =
[[
module %s_tb();
    initial begin
        $dumpfile("%s_tb.vcd");
        $dumpvars(0, %s_tb);
    end
endmodule
]]

local function create_tb(name, parent)
    local tb = string.format(tb_stub, name, name, name)
    parent = parent or core.config.Sources.testbench_dirs[1]
    local file = io.open(parent .. '/' .. name .. "_tb.v", "w")
    if file == nil then
        print("Failed to create testbench file for " .. name)
    end
    file:write(tb)
    io.close(file)
end

local command = require("scripts.command")

command.register("create_tb", create_tb)
