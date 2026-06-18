local AETHER_MENU_API_URL = ""

local function fetchText(url)
	if not url or url == "" then return nil end

	local ok, body = pcall(function()
		if game and game.HttpGet then
			return game:HttpGet(url, true)
		end
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end

	ok, body = pcall(function()
		if http_request then
			return http_request({ Url = url, Method = "GET" })
		elseif request then
			return request({ Url = url, Method = "GET" })
		elseif syn and syn.request then
			return syn.request({ Url = url, Method = "GET" })
		elseif http and http.request then
			return http.request({ Url = url, Method = "GET" })
		end
	end)

	if ok and type(body) == "table" then
		body = body.Body or body.body
	end

	if type(body) == "string" and #body > 0 then
		return body
	end

	return nil
end

local function readLocal(path)
	local ok, body = pcall(function()
		if readfile then
			return readfile(path)
		end
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end
	return nil
end

local source = fetchText(AETHER_MENU_API_URL) or readLocal("D:\\it\\Lua\\menu_api.lua") or readLocal("D:/it/Lua/menu_api.lua")
assert(source, "menu_api.lua not found. Upload menu_api.lua to Catbox and paste the raw URL into AETHER_MENU_API_URL")
assert(loadstring, "loadstring is disabled")

local loader, loadErr = loadstring(source)
assert(loader, "menu_api.lua loadstring failed: " .. tostring(loadErr))

local ok, Aether = pcall(loader)
assert(ok, "menu_api.lua runtime error: " .. tostring(Aether))

Aether = Aether or (shared and (shared.Aether or shared.AetherMenuApi)) or (_G and (_G.Aether or _G.AetherMenuApi))
assert(type(Aether) == "table" and type(Aether.CreateWindow) == "function", "menu_api.lua did not return Aether API")

local state = {
	Enabled = false,
	Speed = 16,
	Mode = "Legit",
	Preset = "Default",
	Accent = Color3.fromRGB(87, 209, 190),
	Name = "default",
	UIBinds = {},
}

local menu = Aether:CreateWindow({
	title = "Example",
	subtitle = "clean test file for Aether menu_api.lua",
	toggleKey = "Insert",
	watermarkText = "Example / Aether",
	keybindList = true,
	configFolder = "AetherExampleConfigs",
	cfg = state,
	notify = function(text)
		print("[Aether]", text)
	end,
})

local main = menu:Tab("main", "Main")
local combat = main:SubTab("combat", "Combat")
local visual = main:SubTab("visual", "Visual")

combat:Section("Basic controls")

combat:Toggle({
	id = "Enabled",
	label = "Enabled",
	get = function() return state.Enabled end,
	set = function(v) state.Enabled = v end,
})

combat:Slider({
	id = "Speed",
	label = "Speed",
	min = 1,
	max = 100,
	step = 1,
	get = function() return state.Speed end,
	set = function(v) state.Speed = v end,
})

combat:Dropdown({
	id = "Mode",
	label = "Mode",
	options = {"Legit", "Rage", "Fun"},
	get = function() return state.Mode end,
	set = function(v) state.Mode = v end,
})

combat:List({
	id = "Preset",
	label = "Preset list",
	mode = "dropdown",
	options = {"Default", "Aggressive", "Quiet", "Scout", "Custom"},
	get = function() return state.Preset end,
	set = function(v) state.Preset = v end,
})

combat:List({
	id = "OpenPreset",
	label = "Open preset list",
	mode = "open",
	options = {"Default", "Aggressive", "Quiet", "Scout", "Custom"},
	get = function() return state.Preset end,
	set = function(v) state.Preset = v end,
})

visual:Section("Visual controls")

visual:Color({
	id = "Accent",
	label = "Accent",
	rainbowSpeed = 0.12,
	rainbowSaturation = 0.82,
	rainbowBrightness = 1,
	get = function() return state.Accent end,
	set = function(v) state.Accent = v end,
})

visual:TextBox({
	id = "Name",
	label = "Profile name",
	get = function() return state.Name end,
	set = function(v) state.Name = v end,
})

visual:Button({
	id = "PrintState",
	label = "Print state",
	text = "PRINT",
	fire = function()
		print(state.Enabled, state.Speed, state.Mode, state.Preset, state.Name)
	end,
})

local _playerAddedConnection = menu.Events:On("PlayerAdded", function(player)
	print("[Aether event] player added:", player.Name)
end)

menu.Events:On("CharacterAdded", function(player, character)
	print("[Aether event] character added:", player.Name, character:GetFullName())
end)

menu.Events:On("ControlChanged", function(id, value)
	print("[Aether event] control changed:", id, value)
end)

-- _playerAddedConnection:Disconnect()
