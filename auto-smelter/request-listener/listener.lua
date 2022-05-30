local component = require("component")
local fs = require("filesystem")
local serialization = require("serialization")
local shell = require("shell")
local sides = require("sides")

local requiredComponents = require("required_components")

local required_components = { "waypoint", "inventory_controller", "redstone" }
local redstone_all_sides_on = { 1, 1, 1, 1, 1 }
local redstone_all_sides_off = { 0, 0, 0, 0, 0 }


local components = requiredComponents.getComponentsTable(required_components)


local function allowItemInput()
    components.redstone.setOutput(redstone_all_sides_on)
end


local function denyItemInput()
    components.redstone.setOutput(redstone_all_sides_off)
end


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

local chest_side = findChestPosition()


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
    local recipe = {}
    local recipe_filename = "recipe"
    local recipe_path = shell.getWorkingDirectory() .. "/" .. recipe_filename

    if fs.exists(recipe_path) then
        local file = io.open(recipe_filename, "r")
        recipe = serialization.unserialize(file:read("*a"))
        file:close()
    else
        print("No recipe file found.\n")

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
    local craftAmount = nil
    while not craftReady do
        allowItemInput()
        os.sleep(5)
        denyItemInput()
        local items_in_chest, items_count = getItemsInChest()
        
        craftReady = true
        craftAmount = nil
        for item_name, item_count in pairs(recipe.input) do
            if items_in_chest[item_name] % recipe.input[item_name] ~= 0 then
                craftReady = false
                break
            end

            if craftAmount == nil then
                craftAmount = items_in_chest[item_name] / recipe.input[item_name]
            end

            if craftAmount ~= items_in_chest[item_name] / recipe.input[item_name] then
                craftReady = false
                break
            end
        end

        if items_count > recipe.input_count then
            error("The chest contains more types of items than the recipe requires")
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
