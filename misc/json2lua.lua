-- local name = "dict.json"
local name = "verb.json"

print("return {")
local json = require("json").decode(io.open(name):read("*a"))
for k, v in pairs(json) do
    print('["' .. k .. '"] = "' .. v:gsub('"', '\\"') .. '",')
end
print("}")
