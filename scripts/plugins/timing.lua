#! /usr/bin/luajit

local globals = require 'scripts.modules.globals'
local argparse = require 'scripts.modules.argparse'

-- luajit standard library
local bit = require 'bit'
local ffi = require 'ffi'

local command = require 'scripts.command'

local function main()
    local parser = argparse("timing", "Timing analysis tool for Verilog modules")
    parser:argument("-t --top", "Top level module. Required if there are more than one modules")
    parser:argument("--cell-lib", "Path to std cell lib")
    parser:argument("--sources", "Path to module(s) to be analyzed")
    parser:flag("--show-path", "Print longest path")
    parser:flag("--show-count", "Show count of each cell type")

    parser:parse()
end
-- main()
--

command.register('hello', function()
    print("Hello, world!")
end)
