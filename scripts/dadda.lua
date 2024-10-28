local globals = require 'scripts.modules.globals'
local argparse = require 'scripts.modules.argparse'

local format = string.format
local insert = table.insert
local floor = math.floor
local remove = table.remove

local function create_dadda_sequence(bits)
    local sequence = {}
    local i = 2
    insert(sequence, i)

    while true do
        i = floor(1.5 * i)
        if i > bits then break end
        insert(sequence, i)
    end

    return sequence
end

local function get_target_height(bits, sequence)
    for i = #sequence, 1, -1 do
        if sequence[i] < bits then
            return sequence[i]
        end
    end
    return 2
end

local function generate_verilog(args)
    local lines = {}
    local sequence = create_dadda_sequence(args.num)

    insert(lines, format("module %s%d(%s, %s, %s);", args.output, args.num, args.a, args.b, args.y))
    insert(lines, format("input wire [%d:0] %s, %s;", args.num - 1, args.a, args.b))
    insert(lines, format("output wire [%d:0] %s;", 2 * args.num - 1, args.y))

    local partials = {}

    for i = 0, args.num - 1 do
        for j = 0, args.num - 1 do
            --    if i + j < 2 * args.num then
            partials[i + j + 1] = partials[i + j + 1] or {}
            insert(partials[i + j + 1], format("(%s[%d] & %s[%d])", args.a, i, args.b, j))
            --  end
        end
    end

    local wires = {}
    local assigns = {}
    local wire_index = 1

    local function get_max_height(partials)
        local max = #partials[1]
        for i = 2, #partials do
            if #partials[i] > max then max = #partials[i] end
        end
        return max
    end

    while true do
        local height = get_max_height(partials)
        if height == 2 then break end
        local target = get_target_height(height, sequence)
        -- print(height, target)

        for i = 2, #partials do
            print(i, #partials[i], target)
            while #partials[i] > target do
                local carry = format("wire_%d", wire_index)
                local sum = format("wire_%d", wire_index + 1)
                wire_index = wire_index + 2
                insert(wires, format("wire %s, %s;", carry, sum))


                if #partials[i] - target == 1 then
                    -- use a half adder to consume two partials
                    insert(assigns, format('assign {{ %s, %s }} = %s + %s;', carry, sum, partials[i][1], partials[i][2]))
                    insert(partials[i + 1], carry)
                    insert(partials[i], sum)

                    print('HA')
                    remove(partials[i], 1)
                    remove(partials[i], 1)
                else
                    -- use a full adder to consume three partials
                    print('FA')

                    insert(assigns,
                        format('assign {{ %s, %s }} = %s + %s + %s;', carry, sum, partials[i][1], partials[i][2],
                            partials[i][3]))
                    insert(partials[i + 1], carry)
                    insert(partials[i], sum)
                    print(#partials[i])

                    remove(partials[i], 1)
                    remove(partials[i], 1)
                    remove(partials[i], 1)
                end
                print(i, #partials[i], target)
            end
        end
    end

    insert(wires, format("wire [%d:0] t1, t2;", 2 * args.num - 2))
    -- multiplier ends here
    for _, v in ipairs(wires) do insert(lines, v) end
    for _, v in ipairs(assigns) do insert(lines, v) end

    local term_one = '{'
    for i = #partials, 1, -1 do
        term_one = term_one .. partials[i][1] .. (i ~= 1 and ',' or '')
    end
    term_one = term_one .. '}'

    local term_two = '{'
    for i = #partials, 2, -1 do
        term_two = term_two .. partials[i][2] .. ','
    end
    term_two = term_two .. "1'b0}"

    insert(lines, format('assign t1 = %s;', term_one))
    insert(lines, format('assign t2 = %s;', term_two))

    insert(lines,
        format('ksa #(.BITS(%d)) adder (.a(%s), .b(%s), .cin(1\'b0), .sum(%s));', 2 * args.num - 1, 't1', 't2', args.y))
    -- send the terms to an 21 bit KSA
    insert(lines, "endmodule")

    return lines
end

local function write_verilog(args, lines)
    local filename = format("%s/%s%d.v", args.dir, args.output, args.num)
    local file = io.open(filename, "w")

    if file == nil then
        print(format("Error: Could not open file %s for writing", filename))
        return
    end

    for _, line in ipairs(lines) do
        file:write(line, "\n")
    end

    file:close()
end

local function main()
    local parser = argparse("dadda", "Verilog generator for dadda multiplier")
    parser:option("-n --num", "Number of bits in the multiplier and multiplicand", 11)
    parser:option("-o --output", "Output filename", "dadda")
    parser:option("-d --dir", "Output directory", globals.src_path)
    parser:option("-a", "Multiplier input A", "a")
    parser:option("-b", "Multiplier input B", "b")
    parser:option("-y", "Multiplier output", "y")

    local args = parser:parse()
    args.num = tonumber(args.num)

    local lines = generate_verilog(args)
    write_verilog(args, lines)
end

main()
