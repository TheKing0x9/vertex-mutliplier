#! /usr/bin/luajit

local lfs = require 'lfs'
local globals = require 'scripts.modules.globals'
local argparse = require 'scripts.modules.argparse'

local list_dir = lfs.dir
local insert = table.insert
local attributes = lfs.attributes

local directories = {}
local files = {}

local function split_path(path)
    return string.match(path, "^(.-)([^\\/]-)(%.[^\\/%.]-)%.?$")
end

local function is_file_readable(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function scan(directory)
    insert(directories, directory)
    for file in list_dir(directory) do
        if file ~= "." and file ~= ".." then
            local path = directory .. file
            local mode = attributes(path, "mode")
            if mode == "directory" then
                scan(path .. "/")
            else
                local _, name, _ = split_path(path)
                local testbench = globals.test_path .. name .. "_tb.v"

                local exists = is_file_readable(testbench)
                files[name] = { file = path, testbench = exists and testbench or nil }
            end
        end
    end
end

local function build_module(name)
    local ref = files[name]
    if not ref.testbench then
        print("No testbench found for module " .. name .. ". Skipping...")
        return
    end

    local output = globals.build_path .. name
    local command = globals.compiler .. " -o " .. output .. " " .. ref.file .. " " .. ref.testbench

    for i = 1, #directories do
        command = command .. " -y" .. directories[i]
    end

    print("Building module " .. name .. " ...")
    print(command)
    os.execute(command)
end

local function execute_module(module)
    local current = lfs.currentdir()
    lfs.chdir(globals.build_path)
    local process = io.popen("./" .. module)

    if process == nil then
        print("Error executing module " .. module)
        return
    end

    local output = process:read("*a")
    process:close()
    print(output)

    lfs.chdir(current)
end

local function cleanup()
    print("Cleaning up...")
    for file in list_dir(globals.build_path) do
        if file ~= "." and file ~= ".." then
            print("Removing " .. file)
            assert(os.remove(globals.build_path .. file))
        end
    end
end

local function main()
    scan(globals.src_path)

    local parser = argparse("builder", "Build script for the project")
    parser:argument("module", "The module to build")
    parser:option("-j --threads", "Number of threads for compiling", 1)
    parser:flag("-v --view", "Open gtkwave after building")
    parser:flag("-c --clean", "Enables auto cleaning output")

    local args = parser:parse()

    build_module(args.module)
    execute_module(args.module)

    if args.view then
        os.execute("gtkwave " .. globals.build_path .. args.module .. "_tb.vcd")
    end

    if args.clean then
        cleanup()
    end
end

main()
