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

    print("Chest found on side " .. chest_side)
    return chest_side
end


local function getItemsInChest()
    local chest_side = findChestPosition()
    items = {}
    for i = 1, components.inventory_controller.getInventorySize(chest_side) do
        local item = components.inventory_controller.getStackInSlot(chest_side, i)
        if item ~= nil then
            if items[item.name] == nil then
                items[item.name] = 0
            end

            items[item.name] = items[item.name] + item.size
        end
    end

    return items
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
        table.insert(recipe.input, getItemsInChest())

        print("Please insert the output items into the chest")
        print("Press enter when finished")
        io.read()
        table.insert(recipe.output, getItemsInChest())
        
        local file = io.open(recipe_filename, "w")
        file:write(serialization.serialize(recipe))
        file:close()
    end

    return recipe
end

local recipe = getRecipe()

print("Successfully loaded the following recipe:")

print("Inputs:")
for name, count in pairs(recipe.input) do
    print(name .. ": " .. count)
end

local output_string = ""
print("Outputs:")
for name, count in pairs(recipe.output) do
    output_string = output_string .. name
    print(name .. ": " .. count)
end

components.waypoint.setLabel(output_string)
