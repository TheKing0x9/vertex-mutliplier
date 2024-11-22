#! /usr/bin/luajit

local lfs = require 'lfs'

local utils = require 'scripts.modules.utils'

local list_dir = lfs.dir
local insert = table.insert
local attributes = lfs.attributes
local split_path = utils.split_path
local argparse = vbuild.argparse
local config = vbuild.config

local function build_module(name, ref, build_path, compiler, directories)
    if not ref then
        print("Module " .. name .. " does not exists. Exiting ...")
        return
    end

    local tb = name .. '_tb'
    if not vbuild.testbenches[tb] then
        print("No testbench found for module " .. name .. ". Skipping...")
        return
    end

    local output = build_path .. '/' .. name
    local command = compiler .. " -o " .. output .. " " .. ref .. " " .. vbuild.testbenches[tb]

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
            assert(os.remove(build_path .. '/' .. file))
        end
    end
end

local function view_module(module, build_path)
    local output = './' .. build_path .. '/' .. module .. '_tb.vcd'
    os.execute("gtkwave " .. output)
end

local function main(args)
    local parser = argparse("builder", "Build script for the project")
    parser:argument("module", "The module to build")
    parser:option("-j --threads", "Number of threads for compiling", 1)
    parser:flag("-v --view", "Open gtkwave after building")
    parser:flag("-c --clean", "Enables auto cleaning output")

    local args, err = parser:pparse(args)
    build_module(args.module, vbuild.files[args.module], config.Compilation.build_path,
        config.Compilation.compiler,
        vbuild.watched_dirs)
    execute_module(args.module, config.Compilation.build_path)

    if args.view then
        view_module(args.module, config.Compilation.build_path)
    end

    if args.clean then
        cleanup(config.Compilation.build_path)
    end
end

command.register('builder', function(args)
    main(args)
end)

command.register('build', function(args)
    local name = args[1]
    build_module(name, vbuild.files[name], config.Compilation.build_path, config.Compilation.compiler,
        vbuild.watched_dirs)
end)

command.register('execute', function(args)
    local name = args[1]
    execute_module(name, config.Compilation.build_path)
end)

command.register('clean', function()
    cleanup(config.Compilation.build_path)
end)

command.register('view', function(args)
    local name = args[1]
    view_module(name, config.Compilation.build_path)
end)
