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


chest_side = findChestPosition()


local function getItemsInChest()
    local items = {}
    local items_count = 0
    for i = 1, components.inventory_controller.getInventorySize(chest_side) do
        local item = components.inventory_controller.getStackInSlot(chest_side, i)
        if item ~= nil then
            if items[item.name] == nil then
                items[item.name] = 0
                items_count = items_count + 1
            end

            items[item.name] = items[item.name] + item.size
        end
    end

    return items, items_count
end


local function getRecipe()
    local recipe_filename = "recipe"
    local recipe_path = shell.getWorkingDirectory() .. "/" .. recipe_filename

    if fs.exists(recipe_path) then
        local file = io.open(recipe_filename, "r")
        local recipe = serialization.unserialize(file:read("*a"))
        file:close()
    else
        print("No recipe file found.\n")
        local recipe = {}

        local chest_side = findChestPosition()
        print("Please insert the input items into the chest")
        print("Press enter when finished")
        io.read()
        local items_in_chest, items_count = getItemsInChest()
        recipe.input = items_in_chest
        recipe.input_count = items_count

        print("Please insert the output items into the chest")
        print("Press enter when finished")
        io.read()
        local items_in_chest, items_count = getItemsInChest()
        recipe.output = items_in_chest
        recipe.output_count = items_count
        
        local file = io.open(recipe_filename, "w")
        file:write(serialization.serialize(recipe))
        file:close()
    end

    return recipe
end


local function waitForCraft(recipe)
    local craftReady = false
    while not craftReady do
        local items, items_count = getItemsInChest()
        if items_count == recipe.input_count then
            craftReady = true
            for name, count in pairs(recipe.input) do
                if items[name] ~= count then
                    craftReady = false
                end
            end
        end

        if items_count > recipe.input_count then
            error("The number of item types in the chest surpasses the number of item types in the recipe")
        end
    end
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

waitForCraft(recipe)
print("Crafting...")