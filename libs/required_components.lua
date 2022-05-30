local requiredComponents = {}

local component = require("component")

function requiredComponents.getComponentsTable(required_components)
    local components = {}
    for i, component_name in pairs(required_components) do
        local current_component = nil
        local current_component_count = 0
        for address, name in component.list(component_name, true) do
            current_component = component.proxy(address)
            current_component_count = current_component_count + 1
        end
        
        if current_component_count ~= 1 then
            error("Expected exactly one " .. component_name .. " component, found " .. current_component_count)
        end

        components[component_name] = current_component
    end

    return components
end

return requiredComponents
