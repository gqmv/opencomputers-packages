local component = require("component")
local requiredComponents = require("required_components")

local required_components = {"waypoint", "me_interface", "inventory_controller"}


local components = requiredComponents.getComponentsTable(required_components)

print(components["waypoint"].address)