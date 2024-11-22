local strict = {}

strict.defined = {}

function global(t)
    for k, v in pairs(t) do
        strict.defined[k] = true
        rawset(_G, k, v)
    end
end

function strict.__newindex(t, k, v)
    error('Cannot set undefined variable: ' .. k, 2)
end

function strict.__index(t, k)
    if not strict.defined[k] then
        error('Cannot get undefined variable: ' .. k, 2)
    end
end

setmetatable(_G, strict)
