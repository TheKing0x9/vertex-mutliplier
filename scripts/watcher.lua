#! /usr/bin/luajit

-- todo: add a watcher on testbench directories: done
-- todo: add create and delete files in testbech directories: done
-- todo: modify the scan function to accept a target table and a depth
-- todo: handle file renaming
-- code cleanup and error handling

-- luajit standard library
local bit = require 'bit'
local ffi = require 'ffi'

local lfs = require 'lfs'
local readline = require 'readline'
local argparse = require 'argparse'
local signal = require 'posix.signal'
local poll = require 'posix.poll'.poll

-- local libraries
local toml = require 'scripts.modules.toml'
local utils = require 'scripts.modules.utils'
local inspect = require 'scripts.modules.inspect'

local command = require 'scripts.command'

require 'scripts.strict'

local C = ffi.C

local list_dir = lfs.dir
local attributes = lfs.attributes
local is_file_readable = utils.is_file_readable

ffi.cdef([[
struct inotify_event {
    int wd;
    uint32_t mask;
    uint32_t cookie;
    uint32_t len;
    char name[0];
};

int fd, wd;

int inotify_init(void);
int inotify_add_watch(int fd, const char *pathname, uint32_t mask);
int inotify_rm_watch(int fd, int wd);
int read(int fd, void *buf, size_t count);
int close(int fd);
]])

local IN_ACCESS           = 0x00000001
local IN_MODIFY           = 0x00000002
local IN_ATTRIB           = 0x00000004
local IN_CLOSE_WRITE      = 0x00000008
local IN_CLOSE_NOWRITE    = 0x00000010
local IN_CLOSE            = bit.bor(IN_CLOSE_WRITE, IN_CLOSE_NOWRITE)
local IN_OPEN             = 0x00000020
local IN_MOVED_FROM       = 0x00000040
local IN_MOVED_TO         = 0x00000080
local IN_MOVE             = bit.bor(IN_MOVED_FROM, IN_MOVED_TO)
local IN_CREATE           = 0x00000100
local IN_DELETE           = 0x00000200
local IN_DELETE_SELF      = 0x00000400
local IN_MOVE_SELF        = 0x00000800
local IN_IGNORED          = 0x00008000
local IN_ISDIR            = 0x40000000

local print_queue         = {}
local testbench_wd        = {}

local exit_loop           = false
local watched_testbenches = {}
local watched_dirs        = {}
local files               = {}
local testbenches         = {}

toml.strict               = true
local config              = nil

do
    local file = io.open('./vbuild.config', 'r')
    if not file then
        print('Error reading vbuild.config, Does the file exists?')
        os.exit()
    end
    config = toml.parse(file:read('*a'))
    file:close()
end

print(inspect(config))

global({
    vbuild = {
        argparse = argparse,
        inspect = inspect,
        config = config,
        files = files,
        testbenches = testbenches,
        watched_testbenches = watched_testbenches,
        watched_dirs = watched_dirs,
    },
    command = command,
})

local function get_testbench(name)
    local testbench = nil
    local exists = false

    for _, v in pairs(config.Sources.testbench_dirs) do
        testbench = './' .. v .. '/' .. name .. "_tb.v"
        exists = is_file_readable(testbench)

        if exists then
            break
        end
    end

    return exists and testbench or nil
end

local function scan(directory, watched, files, max_depth, depth)
    print("Adding watch to " .. directory)
    if max_depth and
        depth > max_depth then
        return
    end

    local wd = ffi.C.inotify_add_watch(ffi.fd, directory, bit.bor(IN_CREATE, IN_DELETE, IN_MODIFY))
    assert(wd > 0, "inotify_add_watch failed")
    watched[wd] = directory

    for file in list_dir(directory) do
        if file ~= "." and file ~= ".." then
            local path = directory .. file
            local mode = attributes(path, "mode")
            if mode == "directory" then
                scan(path .. "/", watched, files, max_depth, depth and depth + 1)
            else
                local _, name, _ = utils.split_path(path)
                files[name] = path
            end
        end
    end
end

local function printd(...)
    for k, v in ipairs({ ... }) do
        table.insert(print_queue, v)
    end
    table.insert(print_queue, '\n')
end

readline.set_options({ histfile = lfs.currentdir() .. '/.vbuild_history' })
readline.set_readline_name("watcher")

command.register('clear', function()
    io.stdout:write('\27[2J', '\27[H')
    io.stdout:flush()
end)

command.register('exit', function()
    exit_loop = true
    readline.handler_remove()
end)

-- import plugins
if config.Plugins.autoload then
    for file in list_dir(config.Plugins.path) do
        if file ~= "." and file ~= ".." then
            local _, stem, _ = utils.split_path(file)
            local path = string.gsub(config.Plugins.path, '[/]+', '.') .. '.' .. stem
            local ok, err = pcall(require, path)
            if not ok then
                print("Error loading plugin: " .. path)
                print(err)
            end
        end
    end
end

local reserved_words = command.get_keys()

print(inspect(reserved_words))
readline.set_complete_list(reserved_words)

-- stop SIGINT from killing the process
signal.signal(signal.SIGINT, function()
    printd("Ctrl-C (SIGINT) quit is disabled. Use Ctrl-D to exit.")
end)

ffi.fd = C.inotify_init()
assert(ffi.fd > 0, "inotify_init failed")

local buffer_size = 1024 * (ffi.sizeof("struct inotify_event") + 16)
local buffer = ffi.new("char[?]", buffer_size)

local line = nil
local fds = {
    [0] = { events = { IN = true } },
    [ffi.fd] = { events = { IN = true } }
}

local function dump(queue)
    if next(queue) == nil then return end

    if queue[#print_queue] == '\n' then queue[#print_queue] = nil end
    print(unpack(queue))
    for i = 1, #queue do queue[i] = nil end
end

local linehandler = function(str)
    dump(print_queue)
    if str == nil or str == '' then
        return
    end

    readline.add_history(str)

    local commands = utils.split(str, '&&')
    for _, v in ipairs(commands) do
        v = v:gsub("^%s*(.-)%s*$", "%1")
        local s = utils.split(v)
        local cmd = s[1]
        cmd = cmd:lower()

        table.remove(s, 1)
        local err = command.execute(cmd, s)
        if err then
            print(err); break;
        end
    end
end

for _, v in ipairs(config.Sources.source_dirs) do
    scan("./" .. v .. "/", watched_dirs, files)
end

for _, v in ipairs(config.Sources.testbench_dirs) do
    scan("./" .. v .. '/', watched_testbenches, testbenches)
end

readline.handler_install("> ", linehandler)
while exit_loop == false do
    poll(fds, -1)
    if fds[0].revents and fds[0].revents.IN then
        readline.read_char() -- only if there's something to be read
    elseif fds[ffi.fd].revents and fds[ffi.fd].revents.IN then
        local len = C.read(ffi.fd, buffer, buffer_size)
        local i = 0
        while i < len do
            local event = ffi.cast("struct inotify_event *", buffer + i)
            printd(event.wd, string.format("0x%x", event.mask), event.cookie, ffi.string(event.name))
            i = i + ffi.sizeof("struct inotify_event") + event.len

            local from_tb = watched_dirs[event.wd] == nil
            local watched = from_tb and watched_testbenches or watched_dirs
            local files = from_tb and testbenches or files

            local filename = ffi.string(event.name)
            local path = watched[event.wd] .. filename
            local _, stem, ext = utils.split_path(filename)
            local is_directory = bit.band(event.mask, IN_ISDIR) == IN_ISDIR

            print(path, stem, ext)

            if bit.band(event.mask, IN_CREATE) == IN_CREATE then
                printd("File created " .. filename)

                if is_directory then
                    scan(path .. "/")
                elseif ext == ".v" then
                    files[stem] = path
                end
            elseif bit.band(event.mask, IN_DELETE) == IN_DELETE then
                print('File Deleted ' .. filename)

                if is_directory then
                    -- watch already removed as the directory is deleted
                elseif ext == ".v" then
                    files[stem] = nil
                end
            elseif bit.band(event.mask, IN_IGNORED) == IN_IGNORED then
                printd("Watch removed " .. filename)
                watched[event.wd] = nil
            end
        end
    else
        -- do some useful background task
        print('Herrre')
    end
end

readline.save_history()

for k, _ in pairs(watched_dirs) do
    C.inotify_rm_watch(ffi.fd, k)
end

for k, _ in pairs(watched_testbenches) do
    C.inotify_rm_watch(ffi.fd, k)
end

C.close(ffi.fd)

-- no silly % symbol at the end of the prompt
io.stdout:write()
