local component = require("component")

local required_components = {"waypoint", "me_interface", "inventory_controller"}

local function getComponentsTable(required_components)
    local components = {}
    for component_name in required_components do
        local current_component = []
        for address, name in component.list(component_name, true) do
            current_component.push(component.proxy(address))
        end
        
        if current_component.length ~= 0 then
            error("No " .. component_name .. " components found")
        end

        components[component_name] = current_component
    end

    return components


local components = getComponentsTable(required_components)

print(components["waypoint"].address)