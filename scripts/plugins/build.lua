#! /usr/bin/luajit

local lfs = require 'lfs'

local core = require "scripts.core"
local utils = require 'scripts.modules.utils'
local globals = require 'scripts.modules.globals'
local argparse = require 'scripts.modules.argparse'

local list_dir = lfs.dir
local insert = table.insert
local attributes = lfs.attributes
local split_path = utils.split_path

local directories = {}
local files = {}
local is_main = utils.is_main()

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

local function build_module(name, ref, build_path, compiler, directories)
    if not ref then
        print("Module " .. name .. " does not exists. Exiting ...")
        -- os.exit(1)
        return
    end

    if not ref.testbench then
        print("No testbench found for module " .. name .. ". Skipping...")
        return
    end

    local output = build_path .. '/' .. name
    local command = compiler .. " -o " .. output .. " " .. ref.file .. " " .. ref.testbench

    for i = 1, #directories do
        command = command .. " -y" .. directories[i]
    end

    print("Building module " .. name .. " ...")
    print(command)

    local code = os.execute(command)
    if code ~= 0 then
        print("Error building module " .. name)
        -- os.exit(1)
    end
end

local function execute_module(module, build_path)
    local current = lfs.currentdir()
    lfs.chdir(build_path)
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

local function cleanup(build_path)
    print("Cleaning up...")
    for file in list_dir(build_path) do
        if file ~= "." and file ~= ".." then
            print("Removing " .. file)
            assert(os.remove(build_path .. file))
        end
    end
end

local function view_module(module, build_path)
    local output = './' .. build_path .. '/' .. module .. '_tb.vcd'
    os.execute("gtkwave " .. output)
end

local function main()
    scan(globals.src_path)

    local parser = argparse("builder", "Build script for the project")
    parser:argument("module", "The module to build")
    parser:option("-j --threads", "Number of threads for compiling", 1)
    parser:flag("-v --view", "Open gtkwave after building")
    parser:flag("-c --clean", "Enables auto cleaning output")

    local args = parser:parse()

    local ref = files[args.module]
    build_module(args.module, ref, globals.build_path, globals.compiler, directories)
    execute_module(args.module, globals.build_path)

    if args.view then
        view_module(args.module, globals.build_path)
    end

    if args.clean then
        cleanup(globals.build_path)
    end
end

if is_main then
    main()
else
    local command = require 'scripts.command'

    command.register('build', function(name)
        build_module(name, core.files[name], core.config.Compilation.build_path, core.config.Compilation.compiler,
            core.watched_directories)
    end)

    command.register('execute', function(name)
        execute_module(name, core.config.Compilation.build_path)
    end)

    command.register('clean', function()
        cleanup(core.config.Compilation.build_path)
    end)

    command.register('view', function(name)
        view_module(name, core.config.Compilation.build_path)
    end)
end
