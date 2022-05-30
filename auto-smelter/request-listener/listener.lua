local component = require("component")
local fs = require("filesystem")
local serialization = require("serialization")

local requiredComponents = require("required_components")

local required_components = {"waypoint", "me_interface", "inventory_controller"}


local components = requiredComponents.getComponentsTable(required_components)

local function getRecipe()
    local recipe = nil
    local recipe_path = "recipe"

    if fs.exists(recipe_path) then
        local file = io.open(recipe_path, "r")
        recipe = serialization.unserialize(file:read("*a"))
        file:close()
    else
        io.stdout.write("No recipe file found.\n")
        local recipe = {input = {}, output = {}}

        io.stdout.write("How many items are necessary for this recipe?\n")
        local recipe_input_size = tonumber(io.stdin.read())
        for i = 1, recipe_input_size do
             io.stdout.write("What is the name of the item?\n")
             local item_name = io.stdin.read()
             io.stdout.write("How many " .. item_name .. " are necessary?\n")
             local item_count = tonumber(io.stdin.read())   
             table.insert(recipe.input, {name = item_name, count = item_count})
        end

        io.stdout.write("How many items are produced?\n")
        local recipe_output_size = tonumber(io.stdin.read())
        for i = 1, recipe_output_size do
             io.stdout.write("What is the name of the item?\n")
             local item_name = io.stdin.read()
             io.stdout.write("How many " .. item_name .. " are produced?\n")
             local item_count = tonumber(io.stdin.read())   
             table.insert(recipe.output, {name = item_name, count = item_count})
        end
        
        local file = io.open(recipe_path, "w")
        file:write(serialization.serialize(recipe))
        file:close()
    end

    return recipe
end

local recipe = getRecipe()
print(recipe)
       
    






