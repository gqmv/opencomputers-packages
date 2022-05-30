local component = require("component")
local fs = require("filesystem")
local serialization = require("serialization")
local shell = require("shell")
local sides = require("sides")

local requiredComponents = require("required_components")

local required_components = {"waypoint", "inventory_controller"}


local components = requiredComponents.getComponentsTable(required_components)

local function findChestPosition()
    local sides_count = 5
    local max_size = 0
    local chest_side = nil
    for i = 0, sides_count do
        local size = components.inventory_controller.getInventorySize(i)
        if size ~= nil and size > max_size then
            max_size = components.inventory_controller.getInventorySize(i)
            chest_side = i
        end
    end

    if chest_side == nil then
        error("No chest found")
    end

    return chest_side
end


local function getRecipe()
    recipe = nil
    local recipe_filename = "recipe"
    local recipe_path = shell.getWorkingDirectory() .. "/" .. recipe_filename

    if fs.exists(recipe_path) then
        local file = io.open(recipe_filename, "r")
        recipe = serialization.unserialize(file:read("*a"))
        file:close()
    else
        print("No recipe file found.\n")
        local recipe = {input = {}, output = {}}

        local chest_side = findChestPosition()
        print("Please insert the input items into the chest")
        print("Press enter when finished")
        io.read()
        for i = 1, components.inventory_controller.getInventorySize(chest_side) do
            local item = components.inventory_controller.getStackInSlot(chest_side, i)
            local item_name = item.name
            local item_count = item.size
            if item ~= nil then
                table.insert(recipe.input, {name = item_name, count = item_count})
            end
        end

        print("Please insert the output items into the chest")
        print("Press enter when finished")
        io.read()
        for i = 1, components.inventory_controller.getInventorySize(chest_side) do
            local item = components.inventory_controller.getStackInSlot(chest_side, i)
            local item_name = item.name
            local item_count = item.size
            if item ~= nil then
                table.insert(recipe.output, {name = item_name, count = item_count})
            end
        end
        
        local file = io.open(recipe_filename, "w")
        file:write(serialization.serialize(recipe))
        file:close()
    end

    return recipe
end

local recipe = getRecipe()

print("Successfully loaded the following recipe:")

print("Inputs:")
for i, input in pairs(recipe.input) do
    print(input.name .. ": " .. input.count)
end

local output_string = ""
print("Outputs:")
for i, output in pairs(recipe.output) do
    output_string = output_string .. output.name
    print(output.name .. ": " .. output.count)
end

components.waypoint.setLabel(output_string)
