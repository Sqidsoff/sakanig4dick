local Library = {}
Library.Name = "Aether"
Library.Version = "8.1.1"

function Library:CreateWindow(env)
	env = env or {}
	local Players = env.Players or game:GetService("Players")
	local UserInputService = env.UserInputService or game:GetService("UserInputService")
	local TweenService = env.TweenService or game:GetService("TweenService")
	local RunService = env.RunService or game:GetService("RunService")
	local HttpService = env.HttpService or game:GetService("HttpService")
	local TextService = env.TextService or game:GetService("TextService")
	local LocalPlayer = env.LocalPlayer or Players.LocalPlayer
	local PlayerGui = env.PlayerGui or LocalPlayer:WaitForChild("PlayerGui")
	local cfg = env.cfg or {}
	local notify = env.notify or function() end

	local api = {}
	local controls = {}
	local tabs = {}
	local activeTab = nil
	local captureBind = nil
	local holdActive = {}
	local bindActiveUntil = {}
	local refreshers = {}
	local ensureSettingsTab = nil
	local runtimeConnections = {}
	local inputChangedHandlers = {}
	local inputEndedHandlers = {}

	local function trackConnection(connection)
		table.insert(runtimeConnections, connection)
		return connection
	end

	local function onInputChanged(handler)
		table.insert(inputChangedHandlers, handler)
	end

	local function onInputEnded(handler)
		table.insert(inputEndedHandlers, handler)
	end

	trackConnection(UserInputService.InputChanged:Connect(function(input)
		for _, handler in ipairs(inputChangedHandlers) do pcall(handler, input) end
	end))
	trackConnection(UserInputService.InputEnded:Connect(function(input)
		for _, handler in ipairs(inputEndedHandlers) do pcall(handler, input) end
	end))

	local eventSubscribers = {}
	local eventSources = {}
	local activeEventSources = {}
	local Events = {}

	local function emitEvent(name, ...)
		local subscribers = eventSubscribers[name]
		if not subscribers then return end
		for token, callback in pairs(subscribers) do
			if token.Connected then
				local ok, err = pcall(callback, ...)
				if not ok then warn("[Aether.Events:" .. tostring(name) .. "] " .. tostring(err)) end
			end
		end
	end

	local function stopEventSource(name)
		local stop = activeEventSources[name]
		activeEventSources[name] = nil
		if stop then pcall(stop) end
	end

	function Events:Define(name, starter)
		eventSources[name] = starter
	end

	function Events:Emit(name, ...)
		emitEvent(name, ...)
	end

	function Events:On(name, callback)
		assert(type(name) == "string" and name ~= "", "event name is required")
		assert(type(callback) == "function", "event callback must be a function")
		local subscribers = eventSubscribers[name]
		if not subscribers then
			subscribers = {}
			eventSubscribers[name] = subscribers
		end
		local token = {Connected = true}
		function token:Disconnect()
			if not self.Connected then return end
			self.Connected = false
			subscribers[self] = nil
			if next(subscribers) == nil then stopEventSource(name) end
		end
		subscribers[token] = callback
		if not activeEventSources[name] and eventSources[name] then
			local ok, stop = pcall(eventSources[name], function(...)
				emitEvent(name, ...)
			end)
			if ok then
				activeEventSources[name] = type(stop) == "function" and stop or function() end
			else
				subscribers[token] = nil
				token.Connected = false
				error(stop)
			end
		end
		return token
	end

	function Events:Once(name, callback)
		local connection
		connection = self:On(name, function(...)
			connection:Disconnect()
			callback(...)
		end)
		return connection
	end

	function Events:SubscriberCount(name)
		local count = 0
		for token in pairs(eventSubscribers[name] or {}) do
			if token.Connected then count = count + 1 end
		end
		return count
	end

	function Events:Destroy()
		for name in pairs(activeEventSources) do stopEventSource(name) end
		for _, subscribers in pairs(eventSubscribers) do
			for token in pairs(subscribers) do token.Connected = false end
			table.clear(subscribers)
		end
		table.clear(eventSubscribers)
	end

	local function simpleSource(signal, mapper)
		return function(fire)
			local connection = signal:Connect(function(...)
				if mapper then
					fire(mapper(...))
				else
					fire(...)
				end
			end)
			return function() connection:Disconnect() end
		end
	end

	Events:Define("PlayerAdded", simpleSource(Players.PlayerAdded))
	Events:Define("PlayerRemoving", simpleSource(Players.PlayerRemoving))
	Events:Define("LocalCharacterAdded", simpleSource(LocalPlayer.CharacterAdded))
	Events:Define("LocalCharacterRemoving", simpleSource(LocalPlayer.CharacterRemoving))
	Events:Define("Heartbeat", simpleSource(RunService.Heartbeat))
	Events:Define("RenderStepped", simpleSource(RunService.RenderStepped))
	Events:Define("WorkspaceDescendantAdded", simpleSource(workspace.DescendantAdded))
	Events:Define("WorkspaceDescendantRemoving", simpleSource(workspace.DescendantRemoving))
	Events:Define("CameraChanged", function(fire)
		local connection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			fire(workspace.CurrentCamera)
		end)
		return function() connection:Disconnect() end
	end)

	local function characterLifecycleSource(signalName)
		return function(fire)
			local connections = {}
			local playerConnections = {}
			local function detach(player)
				local connection = playerConnections[player]
				if connection then connection:Disconnect(); playerConnections[player] = nil end
			end
			local function attach(player)
				detach(player)
				playerConnections[player] = player[signalName]:Connect(function(character)
					fire(player, character)
				end)
			end
			for _, player in ipairs(Players:GetPlayers()) do attach(player) end
			table.insert(connections, Players.PlayerAdded:Connect(attach))
			table.insert(connections, Players.PlayerRemoving:Connect(detach))
			return function()
				for _, connection in ipairs(connections) do connection:Disconnect() end
				for player in pairs(playerConnections) do detach(player) end
			end
		end
	end

	Events:Define("CharacterAdded", characterLifecycleSource("CharacterAdded"))
	Events:Define("CharacterRemoving", characterLifecycleSource("CharacterRemoving"))
	Events:Define("PlayerTeamChanged", function(fire)
		local connections = {}
		local playerConnections = {}
		local function detach(player)
			local connection = playerConnections[player]
			if connection then connection:Disconnect(); playerConnections[player] = nil end
		end
		local function attach(player)
			detach(player)
			playerConnections[player] = player:GetPropertyChangedSignal("Team"):Connect(function()
				fire(player, player.Team)
			end)
		end
		for _, player in ipairs(Players:GetPlayers()) do attach(player) end
		table.insert(connections, Players.PlayerAdded:Connect(attach))
		table.insert(connections, Players.PlayerRemoving:Connect(detach))
		return function()
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for player in pairs(playerConnections) do detach(player) end
		end
	end)

	local function characterModelSource(removing)
		return function(fire)
			local signal = removing and workspace.DescendantRemoving or workspace.DescendantAdded
			local connection = signal:Connect(function(instance)
				if not instance:IsA("Model") then return end
				local userId = instance:GetAttribute("UserId") or instance:GetAttribute("PlayerUserId")
				local player = Players:GetPlayerFromCharacter(instance)
				if not player and userId == nil and not instance:FindFirstChildOfClass("Humanoid") then return end
				fire(player, instance, instance.Parent)
			end)
			return function() connection:Disconnect() end
		end
	end

	Events:Define("CharacterModelAdded", characterModelSource(false))
	Events:Define("CharacterModelRemoving", characterModelSource(true))

	cfg.UIBinds = cfg.UIBinds or env.bindStore or {}
    cfg.ColorPresets = cfg.ColorPresets or env.colorPresets or {
		"#95C021",
		"#45AAF2",
		"#FC5C65",
		"#FED330",
		"#FFFFFF",
	}
	cfg.ColorRainbow = cfg.ColorRainbow or env.colorRainbow or {}
	local rainbowControls = {}
	local rainbowConnection = nil
	local rainbowElapsed = 0

	local function hasActiveRainbow()
		for id, enabled in pairs(cfg.ColorRainbow) do
			if enabled and rainbowControls[id] then return true end
		end
		return false
	end

	local function refreshRainbowDriver()
		if hasActiveRainbow() then
			if rainbowConnection then return end
			rainbowConnection = RunService.Heartbeat:Connect(function(dt)
				rainbowElapsed = rainbowElapsed + dt
				if rainbowElapsed < 0.04 then return end
				rainbowElapsed = 0
				local now = os.clock()
				for id, enabled in pairs(cfg.ColorRainbow) do
					local control = enabled and rainbowControls[id] or nil
					if control and control.setRainbowColor then
						local speed = control.rainbowSpeed or 0.12
						local saturation = control.rainbowSaturation or 0.82
						local brightness = control.rainbowBrightness or 1
						control.setRainbowColor(Color3.fromHSV((now * speed) % 1, saturation, brightness))
					end
				end
			end)
		elseif rainbowConnection then
			rainbowConnection:Disconnect()
			rainbowConnection = nil
			rainbowElapsed = 0
		end
	end

    -- Watermark options and script name configuration
    -- Allow external env override or persistent cfg values
    cfg.WatermarkOptions = cfg.WatermarkOptions or env.watermarkOptions or {
        fps = false,
        fps01 = false,
        nick = false,
        mode = false,
        config = false,
        serverIP = false,
        speed = false,
        time = false,
    }
    cfg.ScriptName = cfg.ScriptName or env.scriptName or env.luaName or env.title or Library.Name
    -- Store initial config name for watermark display; will be updated on Save/Load
    cfg.ConfigName = cfg.ConfigName or env.configName or "default"

	local theme = {
		root = Color3.fromRGB(10, 10, 10),
		panel = Color3.fromRGB(17, 17, 17),
		panel2 = Color3.fromRGB(12, 12, 12),
		soft = Color3.fromRGB(31, 31, 31),
		line = Color3.fromRGB(50, 48, 52),
		text = Color3.fromRGB(235, 235, 235),
		muted = Color3.fromRGB(105, 105, 105),
		accent = Color3.fromRGB(149, 192, 33),
		accent2 = Color3.fromRGB(200, 200, 200),
		active = Color3.fromRGB(18, 18, 18),
		active2 = Color3.fromRGB(23, 23, 23),
		bad = Color3.fromRGB(245, 96, 114),
		good = Color3.fromRGB(149, 192, 33),
	}
	if type(env.theme) == "table" then
		for k, v in pairs(env.theme) do
			theme[k] = v
		end
	end

	local uiFont = Enum.Font.Arial
	local uiFontBold = Enum.Font.ArialBold
	local monoFont = Enum.Font.Code

	local textBoost = env.textBoost or 2
	local function textSize(n)
		return n + textBoost
	end

	local function round(n, step)
		step = step or 1
		return math.floor((n / step) + 0.5) * step
	end

	local function clampRound(n, minV, maxV, step)
		return math.clamp(round(n, step), minV, maxV)
	end

	local function keyName(input)
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			return tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then return "MouseButton1" end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then return "MouseButton2" end
		if input.UserInputType == Enum.UserInputType.MouseButton3 then return "MouseButton3" end
		return nil
	end

	local function mk(parent, className, props)
		local obj = Instance.new(className)
		for k, v in pairs(props or {}) do
			obj[k] = v
		end
		obj.Parent = parent
		return obj
	end

	local function stroke(parent, color, transparency)
		local s = Instance.new("UIStroke")
		s.Color = color or theme.line
		s.Transparency = transparency or 0.35
		s.Thickness = 1
		s.Parent = parent
		return s
	end

	local function corner(parent, px)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, px or 8)
		c.Parent = parent
		return c
	end

	local function button(parent, text, size)
		local b = mk(parent, "TextButton", {
			Size = size or UDim2.fromOffset(86, 28),
			BackgroundColor3 = theme.root,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = uiFont,
			Text = text,
			TextSize = textSize(11),
			TextColor3 = theme.text,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		corner(b, 0)
		local bs = stroke(b, theme.line, 0.35)
		b.MouseEnter:Connect(function()
			local active = b:GetAttribute("AetherActive")
			local target = active and (b:GetAttribute("AetherHoverColor") or theme.active2) or Color3.fromRGB(24, 24, 24)
			TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = target}):Play()
			TweenService:Create(bs, TweenInfo.new(0.12), {Color = active and theme.accent or theme.accent2, Transparency = 0.18}):Play()
		end)
		b.MouseLeave:Connect(function()
			local active = b:GetAttribute("AetherActive")
			local target = active and (b:GetAttribute("AetherActiveColor") or theme.active) or theme.root
			TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = target}):Play()
			TweenService:Create(bs, TweenInfo.new(0.12), {Color = active and theme.accent or theme.line, Transparency = active and 0.1 or 0.35}):Play()
		end)
		return b
	end

	local function clampToScreen(frame)
		if not frame or not frame.Parent then return end
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		local pos = frame.AbsolutePosition
		local size = frame.AbsoluteSize
		local dx = 0
		local dy = 0
		if pos.X < 4 then
			dx = 4 - pos.X
		elseif pos.X + size.X > viewport.X - 4 then
			dx = (viewport.X - 4) - (pos.X + size.X)
		end
		if pos.Y < 4 then
			dy = 4 - pos.Y
		elseif pos.Y + size.Y > viewport.Y - 4 then
			dy = (viewport.Y - 4) - (pos.Y + size.Y)
		end
		if dx ~= 0 or dy ~= 0 then
			frame.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset + dx, frame.Position.Y.Scale, frame.Position.Y.Offset + dy)
		end
	end

	local function makeDraggable(frame, handle)
		handle = handle or frame
		local dragging = false
		local dragStart = nil
		local frameStart = nil
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				frameStart = frame.Position
			end
		end)
		onInputChanged(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
				clampToScreen(frame)
			end
		end)
		onInputEnded(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				clampToScreen(frame)
			end
		end)
	end

	local function addShadow(frame, transparency)
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.Position = UDim2.fromScale(0.5, 0.5)
		shadow.Size = UDim2.new(1, 44, 1, 44)
		shadow.BackgroundTransparency = 1
		shadow.Image = "rbxassetid://5028857084"
		shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		shadow.ImageTransparency = transparency or 0.42
		shadow.ScaleType = Enum.ScaleType.Slice
		shadow.SliceCenter = Rect.new(24, 24, 276, 276)
		shadow.ZIndex = 0
		shadow.Parent = frame
		return shadow
	end

	local guiName = env.guiName or "AetherMenuUI"
	local rootGui = env.rootGui
	if not rootGui then
		rootGui = PlayerGui:FindFirstChild(guiName)
	end
	if not rootGui then
		rootGui = mk(PlayerGui, "ScreenGui", {
			Name = guiName,
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
		})
	end

	for _, name in ipairs({"AetherMenuRoot", "AetherWatermark", "AetherKeybindList"}) do
		local previous = rootGui:FindFirstChild(name)
		if previous then previous:Destroy() end
	end

	local windowWidth = env.width or 660
	local windowHeight = env.height or 545
	local menuVisibleState = cfg.MenuVisible == true
	local root = mk(rootGui, "Frame", {
		Name = "AetherMenuRoot",
		Size = UDim2.fromOffset(windowWidth, windowHeight),
		Position = UDim2.new(0.5, -math.floor(windowWidth / 2), 0.5, -math.floor(windowHeight / 2)),
		BackgroundColor3 = theme.root,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		Visible = menuVisibleState,
		ClipsDescendants = false,
	})
	corner(root, 0)
	stroke(root, Color3.fromRGB(61, 65, 76), 0).Thickness = 5
	addShadow(root, 0.5)

	local topAccent = mk(root, "Frame", {
		Name = "TopAccent",
		Size = UDim2.new(1, -10, 0, 2),
		Position = UDim2.fromOffset(5, 5),
		BackgroundColor3 = theme.accent,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	corner(topAccent, 2)
	mk(topAccent, "UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.accent),
			ColorSequenceKeypoint.new(0.5, theme.bad),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(254, 211, 48)),
		})
	})

	local watermark = mk(rootGui, "Frame", {
		Name = "AetherWatermark",
		Size = UDim2.fromOffset(210, 32),
		AnchorPoint = env.watermarkPosition and Vector2.new(0, 0) or Vector2.new(1, 0),
		Position = env.watermarkPosition or UDim2.new(1, -18, 0, 18),
		BackgroundColor3 = theme.panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Visible = env.watermark ~= false,
	})
	corner(watermark, 0)
	stroke(watermark, Color3.fromRGB(61, 65, 76), 0).Thickness = 3
	addShadow(watermark, 0.58)
	local watermarkText = mk(watermark, "TextLabel", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
		Font = uiFont,
		Text = env.watermarkText or ((env.title or "AETHER V7") .. " / ready"),
		TextSize = textSize(12),
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
    makeDraggable(watermark)

    -- Watermark dynamic update setup
    local fpsSamples = {}
    local fpsSampleIndex = 0
    local fpsSampleCount = 0
    local fpsCurrent = 0
    local fpsLow = 0
    local watermarkRefreshElapsed = 0
    local watermarkWidth = 0
    local function resizeWatermark()
        local width = TextService:GetTextSize(
            watermarkText.Text,
            watermarkText.TextSize,
            watermarkText.Font,
            Vector2.new(10000, watermark.AbsoluteSize.Y)
        ).X
        width = math.clamp(math.ceil(width) + 16, 72, 900)
        if width ~= watermarkWidth then
            watermarkWidth = width
            watermark.Size = UDim2.fromOffset(width, 32)
        end
    end
    -- function to refresh the watermark text based on selected options
    local function updateWatermarkText()
        if not watermark.Visible then return end
        local comps = {}
        table.insert(comps, tostring(cfg.ScriptName or ""))
        if cfg.WatermarkOptions.fps then
            table.insert(comps, string.format("FPS: %.0f", fpsCurrent))
        end
        if cfg.WatermarkOptions.fps01 then
            table.insert(comps, string.format("FPS0.1: %.0f", fpsLow))
        end
        if cfg.WatermarkOptions.nick then
            local name = ""
            pcall(function()
                local plr = LocalPlayer
                if plr then
                    name = plr.DisplayName or plr.Name or ""
                end
            end)
            if name and name ~= "" then
                table.insert(comps, tostring(name))
            end
        end
        if cfg.WatermarkOptions.mode then
            local modeName = env.modeName or cfg.ModeName
            if modeName and tostring(modeName) ~= "" then
                table.insert(comps, tostring(modeName))
            end
        end
        if cfg.WatermarkOptions.config then
            local cn = cfg.ConfigName or configName
            if cn and tostring(cn) ~= "" then
                table.insert(comps, "cfg:" .. tostring(cn))
            end
        end
        if cfg.WatermarkOptions.serverIP then
            local ip = ""
            pcall(function()
                local NetworkClient = game:GetService("NetworkClient")
                if NetworkClient and NetworkClient.ServerConnection and NetworkClient.ServerConnection.Address then
                    ip = tostring(NetworkClient.ServerConnection.Address)
                end
            end)
            if ip and ip ~= "" then
                table.insert(comps, tostring(ip))
            end
        end
        if cfg.WatermarkOptions.speed then
            local speed = 0
            pcall(function()
                local plr = LocalPlayer
                local char = plr and plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local v = hrp.Velocity
                    speed = math.sqrt((v.X * v.X) + (v.Z * v.Z))
                end
            end)
            table.insert(comps, string.format("SPD: %.1f", speed))
        end
        if cfg.WatermarkOptions.time then
            local t = os.date("%H:%M:%S")
            table.insert(comps, tostring(t))
        end
        watermarkText.Text = table.concat(comps, " | ")
        resizeWatermark()
    end
    resizeWatermark()
    -- update fps samples and refresh watermark each frame
    trackConnection(RunService.RenderStepped:Connect(function(dt)
        local fps = 0
        if dt > 0 then fps = 1 / dt end
        fpsCurrent = fps
        fpsSampleIndex = (fpsSampleIndex % 100) + 1
        fpsSamples[fpsSampleIndex] = fps
        fpsSampleCount = math.min(100, fpsSampleCount + 1)
        watermarkRefreshElapsed = watermarkRefreshElapsed + dt
        if watermarkRefreshElapsed < 0.2 then return end
        watermarkRefreshElapsed = 0
        local minFps = math.huge
        for i = 1, fpsSampleCount do
            local f = fpsSamples[i]
            if f < minFps then minFps = f end
        end
        fpsLow = minFps == math.huge and 0 or minFps
        updateWatermarkText()
    end))

	local keybindFrame = mk(rootGui, "Frame", {
		Name = "AetherKeybindList",
		Size = UDim2.fromOffset(260, 42),
		Position = env.keybindListPosition or UDim2.fromOffset(18, 210),
		BackgroundColor3 = theme.panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Visible = env.keybindList ~= false,
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	corner(keybindFrame, 0)
	stroke(keybindFrame, Color3.fromRGB(61, 65, 76), 0).Thickness = 3
	addShadow(keybindFrame, 0.58)
	local keybindTitle = mk(keybindFrame, "TextLabel", {
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
		Font = uiFontBold,
		Text = "Keybinds",
		TextSize = textSize(12),
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local keybindContent = mk(keybindFrame, "Frame", {
		Size = UDim2.new(1, -12, 0, 0),
		Position = UDim2.fromOffset(6, 30),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	mk(keybindContent, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)})
	makeDraggable(keybindFrame, keybindTitle)

	local scale = mk(root, "UIScale", {Scale = cfg.UIScaleValue or 1})
	local grad = mk(root, "UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new(theme.panel, theme.panel),
	})

	local titleBar = mk(root, "Frame", {
		Size = UDim2.new(1, -26, 0, 42),
		Position = UDim2.fromOffset(13, 12),
		BackgroundTransparency = 1,
	})

	mk(titleBar, "TextLabel", {
		Size = UDim2.new(0, 260, 0, 20),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Font = uiFontBold,
		Text = env.title or "AETHER V7",
		TextSize = textSize(16),
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	mk(titleBar, "TextLabel", {
		Size = UDim2.new(0, 390, 0, 17),
		Position = UDim2.fromOffset(1, 17),
		BackgroundTransparency = 1,
		Font = uiFont,
		Text = env.subtitle or "modular lua ui api / universal bind matrix",
		TextSize = textSize(9),
		TextColor3 = Color3.fromRGB(145, 145, 145),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local apiPill = mk(titleBar, "TextLabel", {
		Size = UDim2.fromOffset(48, 18),
		Position = UDim2.fromOffset(276, 1),
		BackgroundColor3 = theme.soft,
		BorderSizePixel = 0,
		Font = uiFontBold,
		Text = "API",
		TextSize = textSize(11),
		TextColor3 = theme.accent,
	})
	corner(apiPill, 0)
	stroke(apiPill, theme.accent, 0.55)

	local bindStatus = mk(titleBar, "TextLabel", {
		Size = UDim2.new(1, -460, 0, 22),
		Position = UDim2.new(0, 335, 0, 7),
		BackgroundTransparency = 1,
		Font = uiFont,
		Text = "",
		TextSize = textSize(12),
		TextColor3 = theme.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local minimize = button(titleBar, "-", UDim2.fromOffset(24, 20))
	minimize.Position = UDim2.new(1, -58, 0, 2)
	local close = button(titleBar, "x", UDim2.fromOffset(24, 20))
	close.Position = UDim2.new(1, -28, 0, 2)

	local nav = mk(root, "ScrollingFrame", {
		Size = UDim2.new(0, 76, 1, -68),
		Position = UDim2.fromOffset(5, 48),
		BackgroundColor3 = theme.root,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = theme.accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	corner(nav, 0)
	stroke(nav, theme.line, 0.1)
	mk(nav, "UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.root),
			ColorSequenceKeypoint.new(1, theme.root),
		})
	})
	mk(nav, "UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
	mk(nav, "UIPadding", {PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), PaddingTop = UDim.new(0, 0)})

	local body = mk(root, "Frame", {
		Size = UDim2.new(1, -88, 1, -68),
		Position = UDim2.fromOffset(82, 48),
		BackgroundTransparency = 1,
	})

	local content = mk(body, "ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = theme.panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = theme.accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
	})
	corner(content, 0)
	stroke(content, theme.line, 0.25)
	mk(content, "UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.panel),
			ColorSequenceKeypoint.new(1, theme.panel),
		})
	})
	mk(content, "UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	mk(content, "UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
	})

	local bindPopup = mk(root, "Frame", {
		Name = "AetherBindPopup",
		Size = UDim2.fromOffset(306, 282),
		Position = UDim2.fromOffset(24, 150),
		BackgroundColor3 = theme.panel,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 40,
	})
	corner(bindPopup, 0)
	stroke(bindPopup, Color3.fromRGB(61, 65, 76), 0).Thickness = 3
	addShadow(bindPopup, 0.54)
	mk(bindPopup, "UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.panel),
			ColorSequenceKeypoint.new(1, theme.panel),
		})
	})

	local bindPopupTitle = mk(bindPopup, "TextLabel", {
		Size = UDim2.new(1, -54, 0, 26),
		Position = UDim2.fromOffset(12, 9),
		BackgroundTransparency = 1,
		Font = uiFontBold,
		Text = "Bind editor",
		TextSize = textSize(13),
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 42,
	})

	local bindPopupClose = button(bindPopup, "x", UDim2.fromOffset(26, 24))
	bindPopupClose.Position = UDim2.new(1, -36, 0, 9)
	bindPopupClose.ZIndex = 42

	mk(bindPopup, "TextLabel", {
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.fromOffset(12, 35),
		BackgroundTransparency = 1,
		Font = uiFont,
		Text = "Pick a key, value, and mode for this control.",
		TextSize = textSize(11),
		TextColor3 = theme.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 42,
	})

	local bindKeyBtn = button(bindPopup, "PICK KEY", UDim2.new(0.48, -8, 0, 30))
	bindKeyBtn.Position = UDim2.fromOffset(12, 64)
	bindKeyBtn.ZIndex = 42

	local bindModeBtn = button(bindPopup, "TOGGLE", UDim2.new(0.52, -16, 0, 30))
	bindModeBtn.Position = UDim2.new(0.48, 4, 0, 64)
	bindModeBtn.ZIndex = 42

	local bindValueBox = mk(bindPopup, "TextBox", {
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.fromOffset(12, 102),
		BackgroundColor3 = theme.root,
		BorderSizePixel = 0,
		Font = uiFont,
		Text = "",
		PlaceholderText = "bind value",
		TextSize = textSize(12),
		TextColor3 = theme.text,
		ClearTextOnFocus = false,
		ZIndex = 42,
	})
    corner(bindValueBox, 0)
    stroke(bindValueBox, theme.line, 0.55)
    
    local bindValueClickBtn = mk(bindPopup, "TextButton", {
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.fromOffset(12, 102),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        ZIndex = 43,
    })
    
    local bindValuePopup = mk(root, "Frame", {
        Size = UDim2.fromOffset(150, 100),
        BackgroundColor3 = theme.root,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 55,
    })
    corner(bindValuePopup, 0)
    stroke(bindValuePopup, Color3.fromRGB(61, 65, 76), 0.05).Thickness = 2
    addShadow(bindValuePopup, 0.62)
    mk(bindValuePopup, "UIPadding", {PaddingLeft = UDim.new(0,3), PaddingRight = UDim.new(0,3), PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3)})
    local bindValueList = mk(bindValuePopup, "ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 56,
    })
    mk(bindValueList, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0)})
    

	local bindList = mk(bindPopup, "ScrollingFrame", {
		Size = UDim2.new(1, -24, 0, 96),
		Position = UDim2.fromOffset(12, 140),
		BackgroundColor3 = theme.root,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 42,
	})
	corner(bindList, 0)
	mk(bindList, "UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)})
	mk(bindList, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})

	local bindAddBtn = button(bindPopup, "ADD", UDim2.new(0.5, -16, 0, 30))
	bindAddBtn.Position = UDim2.new(0, 12, 1, -38)
	bindAddBtn.ZIndex = 42
	local bindClearBtn = button(bindPopup, "CLEAR", UDim2.new(0.5, -16, 0, 30))
	bindClearBtn.Position = UDim2.new(0.5, 4, 1, -38)
	bindClearBtn.ZIndex = 42

local selectedControl = nil
	local pendingKey = nil
	local pendingMode = "Toggle"
    local dropdownPopups = {}
    local dropdownAnchors = {}

    
    table.insert(dropdownPopups, bindValuePopup)
    dropdownAnchors[bindValuePopup] = bindValueClickBtn

	local function controlValueText(control)
		if control.kind == "toggle" then
			return "toggle"
		elseif control.kind == "slider" then
			return tostring(control.get())
		elseif control.kind == "dropdown" then
			return "next"
		elseif control.kind == "color" then
			return colorToHex(control.get())
		elseif control.kind == "button" then
			return "press"
		end
		return ""
	end

	local function parseColor(text)
		text = tostring(text or "")
		local r1, g1, b1, a1 = text:match("rgba?%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,?%s*([%d%.]*)%s*%)")
		if r1 and g1 and b1 then
			local r = math.clamp(tonumber(r1) or 0, 0, 255)
			local g = math.clamp(tonumber(g1) or 0, 0, 255)
			local b = math.clamp(tonumber(b1) or 0, 0, 255)
			local a = tonumber(a1)
			return Color3.fromRGB(r, g, b), a
		end
		local r2, g2, b2, a2 = text:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,?%s*([%d%.]*)%s*$")
		if r2 and g2 and b2 then
			local r = math.clamp(tonumber(r2) or 0, 0, 255)
			local g = math.clamp(tonumber(g2) or 0, 0, 255)
			local b = math.clamp(tonumber(b2) or 0, 0, 255)
			local a = tonumber(a2)
			return Color3.fromRGB(r, g, b), a
		end
		local hex = text:match("#?([%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F])")
		if hex then
			local r = tonumber(hex:sub(1, 2), 16)
			local g = tonumber(hex:sub(3, 4), 16)
			local b = tonumber(hex:sub(5, 6), 16)
			if r and g and b then return Color3.fromRGB(r, g, b) end
		end
		return nil
	end

	function colorToHex(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end

	local function colorToRgbText(c)
		return string.format("%d, %d, %d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end

	local function colorToRgbaText(c, a)
		return string.format("%d, %d, %d, %.2f", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5), a or 1)
	end

	local function savedColorAt(i)
		local raw = cfg.ColorPresets and cfg.ColorPresets[i]
		if typeof(raw) == "Color3" then return raw end
		local c = parseColor(raw)
		return c
	end

	local function addSavedColor(color)
		cfg.ColorPresets = cfg.ColorPresets or {}
		local hex = colorToHex(color)
		for i, saved in ipairs(cfg.ColorPresets) do
			if tostring(saved):upper() == hex then return false end
			local c = savedColorAt(i)
			if c and colorToHex(c) == hex then return false end
		end
		table.insert(cfg.ColorPresets, 1, hex)
		while #cfg.ColorPresets > 18 do
			table.remove(cfg.ColorPresets)
		end
		return true
	end

	local function normalizeBindValue(control, text)
		local value = tostring(text or "")
		if control.kind == "toggle" then
			local v = value:lower()
			if v == "" or v == "toggle" or v == "next" then return "toggle" end
			if v == "on" or v == "true" or v == "1" then return "on" end
			if v == "off" or v == "false" or v == "0" then return "off" end
			return "toggle"
		elseif control.kind == "slider" then
			local n = tonumber(value)
			if not n then
				local ok, current = pcall(control.get)
				n = ok and tonumber(current) or control.min
			end
			return tostring(clampRound(n or control.min, control.min, control.max, control.step))
		elseif control.kind == "dropdown" then
			if value == "" then return "next" end
			for _, opt in ipairs(control.options or {}) do
				if tostring(opt):lower() == value:lower() then return tostring(opt) end
			end
			return value
		elseif control.kind == "color" then
			local c, a = parseColor(value)
			if c and a then return colorToRgbaText(c, a) end
			if c then return colorToHex(c) end
			return controlValueText(control)
		elseif control.kind == "button" then
			return "press"
		elseif control.kind == "textbox" then
			return value
		end
		return value
	end

	local function refreshBindList()
		for _, child in ipairs(bindList:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
		end
		if not selectedControl then
			bindPopupTitle.Text = "Bind editor"
			bindKeyBtn.Text = "PICK KEY"
			bindValueBox.Text = ""
			return
		end
		bindPopupTitle.Text = selectedControl.label
		bindKeyBtn.Text = pendingKey and ("KEY: " .. pendingKey) or "PICK KEY"
		bindValueBox.Text = controlValueText(selectedControl)
		local list = cfg.UIBinds[selectedControl.id] or {}
		if #list == 0 then
			mk(bindList, "TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Font = uiFont,
				Text = "No binds yet",
				TextSize = textSize(11),
				TextColor3 = theme.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 43,
			})
			return
		end
		for i, bind in ipairs(list) do
			local row = button(bindList, tostring(bind.key) .. " -> " .. tostring(bind.value), UDim2.new(1, 0, 0, 32))
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Text = "  " .. tostring(bind.key) .. "   " .. tostring(bind.mode or "Toggle") .. "   " .. tostring(bind.value)
			row.ZIndex = 43
			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					for idx = #list, 1, -1 do
						if list[idx] == bind then
							table.remove(list, idx)
							break
						end
					end
					refreshBindList()
					notify("Bind removed")
				end
			end)
		end
	end

	local function closeDropdownPopups(except)
		for _, popup in ipairs(dropdownPopups) do
			if popup ~= except then
				popup.Visible = false
			end
		end
	end

    
    local function getBindValueOptions(control)
        if not control then return nil end
        local opts = {}
        if control.kind == "toggle" then
            opts = {"toggle", "on", "off"}
        elseif control.kind == "button" then
            opts = {"press"}
        elseif control.kind == "dropdown" then
            table.insert(opts, "next")
            local options = {}
            if type(control.options) == "function" then
                local ok, res = pcall(control.options)
                if ok and type(res) == "table" then options = res end
            else
                options = control.options or {}
            end
            for _, v in ipairs(options) do
                table.insert(opts, tostring(v))
            end
        elseif control.kind == "list" then
            table.insert(opts, "next")
            local items = {}
            if type(control.getItems) == "function" then
                local ok, res = pcall(control.getItems)
                if ok and type(res) == "table" then items = res end
            elseif type(control.options) == "function" then
                local ok, res = pcall(control.options)
                if ok and type(res) == "table" then items = res end
            else
                items = control.options or {}
            end
            for _, v in ipairs(items) do
                table.insert(opts, tostring(v))
            end
        else
            return nil
        end
        return opts
    end

    
    local function updateBindValueUI()
        
        bindValueClickBtn.Visible = false
        bindValuePopup.Visible = false
        
        for _, child in ipairs(bindValueList:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
        
        if not selectedControl then
            return
        end
        local opts = getBindValueOptions(selectedControl)
        if not opts or #opts == 0 then
            return
        end
        
        bindValueClickBtn.Visible = true
        
        local currentText = tostring(bindValueBox.Text or "")
        
        local function createItem(item)
            local btn = mk(bindValueList, "TextButton", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = theme.root,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = uiFont,
                Text = tostring(item),
                TextSize = textSize(11),
                TextColor3 = tostring(item) == currentText and theme.accent or theme.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 57,
            })
            mk(btn, "UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
            btn.MouseEnter:Connect(function()
                btn.BackgroundTransparency = 0.08
                btn.BackgroundColor3 = theme.soft
                btn.TextColor3 = theme.accent2
            end)
            btn.MouseLeave:Connect(function()
                local on = tostring(bindValueBox.Text) == tostring(item)
                btn.BackgroundTransparency = 1
                btn.BackgroundColor3 = theme.root
                btn.TextColor3 = on and theme.accent or theme.text
            end)
            btn.MouseButton1Click:Connect(function()
                bindValueBox.Text = tostring(item)
                bindValuePopup.Visible = false
            end)
        end
        for _, item in ipairs(opts) do
            createItem(item)
        end
        
        local height = math.min(168, math.max(30, #opts * 22 + 6))
        bindValuePopup.Size = UDim2.fromOffset(bindValuePopup.Size.X.Offset, height)
    end

    
    bindValueClickBtn.MouseButton1Click:Connect(function()
        if not selectedControl then return end
        local opts = getBindValueOptions(selectedControl)
        if not opts or #opts == 0 then return end
        -- close any other dropdown popups
        closeDropdownPopups(bindValuePopup)
        -- rebuild the list entries before showing
        updateBindValueUI()
        -- position the popup relative to the overlay
        local anchor = bindValueClickBtn
        local x = anchor.AbsolutePosition.X - root.AbsolutePosition.X
        local y = anchor.AbsolutePosition.Y - root.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 2
        local maxX = math.max(8, root.AbsoluteSize.X - bindValuePopup.AbsoluteSize.X - 8)
        local maxY = math.max(8, root.AbsoluteSize.Y - bindValuePopup.AbsoluteSize.Y - 8)
        bindValuePopup.Position = UDim2.fromOffset(math.clamp(x, 8, maxX), math.clamp(y, 8, maxY))
        bindValuePopup.Visible = not bindValuePopup.Visible
    end)

	local function pointInside(gui, pos)
		if not gui or not gui.Visible then return false end
		local p = gui.AbsolutePosition
		local s = gui.AbsoluteSize
		return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
	end

	local function placeBindPopup(screenPosition)
		local x = 24
		local y = 150
		if screenPosition then
			x = screenPosition.X - root.AbsolutePosition.X + 12
			y = screenPosition.Y - root.AbsolutePosition.Y + 8
		end
		local maxX = math.max(8, root.AbsoluteSize.X - bindPopup.AbsoluteSize.X - 8)
		local maxY = math.max(8, root.AbsoluteSize.Y - bindPopup.AbsoluteSize.Y - 8)
		bindPopup.Position = UDim2.fromOffset(math.clamp(x, 8, maxX), math.clamp(y, 8, maxY))
	end

local function selectControl(control, screenPosition)
    selectedControl = control
    pendingKey = nil
    bindStatus.Text = "binding: " .. control.label
    bindPopup.Visible = true
    placeBindPopup(screenPosition)
    refreshBindList()
    updateBindValueUI()
end

	local function setControlValue(control, rawValue, isDown, mode, restoreValue)
		mode = mode or "Toggle"
		if mode == "Hold" and (not isDown) and control.kind ~= "button" then
			if control.kind == "toggle" then
				control.set(false)
			elseif restoreValue ~= nil then
				control.set(restoreValue)
			end
			if control.refresh then control.refresh() end
			return
		end
		if control.kind == "toggle" then
			local defaultValue = (mode == "Hold") and "on" or "toggle"
			local v = tostring(rawValue or defaultValue):lower()
			if mode == "Hold" then
				control.set(v == "off" and false or true)
			elseif isDown then
				if v == "on" or v == "true" or v == "1" then
					control.set(true)
				elseif v == "off" or v == "false" or v == "0" then
					control.set(false)
				else
					control.set(not control.get())
				end
			end
		elseif isDown and control.kind == "slider" then
			local n = tonumber(rawValue)
			if n then control.set(clampRound(n, control.min, control.max, control.step)) end
        elseif isDown and control.kind == "dropdown" then
			local value = tostring(rawValue or "next")
			if value:lower() == "next" then
				local options = control.options
				local cur = control.get()
				local idx = 1
				for i, opt in ipairs(options) do
					if opt == cur then idx = i + 1 break end
				end
				if idx > #options then idx = 1 end
				control.set(options[idx])
			else
				control.set(value)
			end
        elseif isDown and control.kind == "list" then
            -- handle list controls: cycle or set specific item
            local value = tostring(rawValue or "next")
            local items = {}
            if type(control.getItems) == "function" then
                local ok, res = pcall(control.getItems)
                if ok and type(res) == "table" then items = res end
            elseif type(control.options) == "function" then
                local ok, res = pcall(control.options)
                if ok and type(res) == "table" then items = res end
            else
                items = control.options or {}
            end
            if value:lower() == "next" then
                local cur = control.get()
                local idx = 1
                for i, item in ipairs(items) do
                    if tostring(item) == tostring(cur) then idx = i + 1 break end
                end
                if idx > #items then idx = 1 end
                if items[idx] ~= nil then control.set(items[idx]) end
            else
                control.set(value)
            end
        elseif isDown and control.kind == "color" then
			local value = tostring(rawValue or "next")
			if value:lower() == "next" then
				control.presets = cfg.ColorPresets
				local count = #(cfg.ColorPresets or {})
				if count > 0 then
					control.colorIndex = ((control.colorIndex or 0) % count) + 1
					local c = savedColorAt(control.colorIndex)
					if c then control.set(c) end
				end
			else
				local c, a = parseColor(value)
				if c then
					control.set(c)
					if a and control.setAlpha then
						control.setAlpha(math.clamp(a, 0, 1))
						if control.afterAlpha then control.afterAlpha() end
					end
				end
			end
		elseif isDown and control.kind == "button" then
			control.fire()
		elseif (not isDown) and mode == "Hold" and control.kind == "button" and control.release then
			control.release()
		elseif isDown and control.kind == "textbox" then
			control.set(tostring(rawValue or ""))
		end
		if control.refresh then control.refresh() end
	end

	local function serializeValue(value)
		if typeof and typeof(value) == "Color3" then
			return {__type = "Color3", value = colorToHex(value)}
		end
		return value
	end

	local function deserializeValue(value)
		if type(value) == "table" and value.__type == "Color3" then
			return parseColor(value.value)
		end
		return value
	end

	local configFolder = env.configFolder or "AetherConfigs"
	local configName = env.configName or "default"
	local configApi = {}

	local function configPath(name)
		name = tostring(name or configName):gsub("[^%w%._%- ]", "_")
		return configFolder .. "/" .. name .. ".json"
	end

	local function ensureConfigFolder()
		pcall(function()
			if makefolder and not isfolder(configFolder) then
				makefolder(configFolder)
			end
		end)
	end

	function configApi:Snapshot()
		local data = {
			values = {},
			binds = cfg.UIBinds or {},
			colorPresets = cfg.ColorPresets or {},
			colorRainbow = cfg.ColorRainbow or {},
		}
		for id, control in pairs(controls) do
			if control.get and not tostring(id):match("^__aether_") then
				local ok, value = pcall(control.get)
				if ok then data.values[id] = serializeValue(value) end
			end
		end
		return data
	end

	function configApi:Apply(data)
		if type(data) ~= "table" then return false, "bad config" end
		if type(data.binds) == "table" then
			cfg.UIBinds = data.binds
		end
		if type(data.colorPresets) == "table" then
			cfg.ColorPresets = data.colorPresets
			for _, control in pairs(controls) do
				if control.kind == "color" then
					control.presets = cfg.ColorPresets
				end
			end
		end
		if type(data.colorRainbow) == "table" then
			cfg.ColorRainbow = data.colorRainbow
			refreshRainbowDriver()
		end
		if type(data.values) == "table" then
			for id, value in pairs(data.values) do
				local control = controls[id]
				if control and control.set then
					local decoded = deserializeValue(value)
					if decoded ~= nil then
						pcall(function() control.set(decoded) end)
					end
					if control.refresh then pcall(control.refresh) end
				end
			end
		end
		refreshBindList()
		return true
	end

	function configApi:Export()
		return HttpService:JSONEncode(self:Snapshot())
	end

	function configApi:Import(text)
		local ok, data = pcall(function()
			return HttpService:JSONDecode(text)
		end)
		if not ok then return false, "json decode failed" end
		return self:Apply(data)
	end

	function configApi:Save(name)
		ensureConfigFolder()
		if not writefile then return false, "writefile unavailable" end
        local ok, text = pcall(function() return self:Export() end)
		if not ok then return false, tostring(text) end
		local path = configPath(name)
		local writeOk, err = pcall(function() writefile(path, text) end)
		if not writeOk then return false, tostring(err) end
        -- update current config name for watermark display
        cfg.ConfigName = name
		Events:Emit("ConfigSaved", name, path)
        return true, path
	end

	function configApi:Load(name)
		if not readfile then return false, "readfile unavailable" end
		local path = configPath(name)
        local ok, text = pcall(function() return readfile(path) end)
        if not ok then return false, "config not found" end
        -- update current config name for watermark display
        cfg.ConfigName = name
        local imported, message = self:Import(text)
		if imported then Events:Emit("ConfigLoaded", name, path) end
		return imported, message
	end

	function configApi:Delete(name)
		if not delfile then return false, "delfile unavailable" end
		local path = configPath(name)
		local ok, err = pcall(function() delfile(path) end)
		if not ok then return false, tostring(err) end
		return true
	end

	function configApi:List()
		if not listfiles then return {} end
		ensureConfigFolder()
		local out = {}
		local ok, files = pcall(function() return listfiles(configFolder) end)
		if not ok or type(files) ~= "table" then return out end
		for _, path in ipairs(files) do
			local name = tostring(path):match("([^/\\]+)%.json$")
			if name then table.insert(out, name) end
		end
		table.sort(out)
		return out
	end

	local function registerControl(control, row)
		if control.set and not control._eventWrapped then
			local originalSet = control.set
			control.set = function(...)
				originalSet(...)
				local value = nil
				if control.get then pcall(function() value = control.get() end) end
				Events:Emit("ControlChanged", control.id, value, control)
			end
			control._eventWrapped = true
		end
		controls[control.id] = control
		local function openBind(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				selectControl(control, input.Position)
			end
		end
		local bindOpen = row:FindFirstChild("BindOpen")
		if bindOpen then
			bindOpen.MouseButton1Click:Connect(function()
				selectControl(control, UserInputService:GetMouseLocation())
			end)
		end
		row.InputBegan:Connect(openBind)
        -- Connect openBind to all current descendant GUI objects (including BindOpen) to allow right-click binding anywhere
        for _, child in ipairs(row:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.InputBegan:Connect(openBind)
            end
        end
        -- Ensure any future descendants also respect right‑click bind opening
        row.DescendantAdded:Connect(function(child)
            if child:IsA("GuiObject") then
                child.InputBegan:Connect(openBind)
            end
        end)
        return control
	end

	local function valueToText(value)
		if typeof and typeof(value) == "Color3" then
			return colorToHex(value)
		end
		return tostring(value)
	end

	local function bindIsActive(control, bind)
		local key = tostring(bind.key)
		local mode = bind.mode or "Toggle"
		local holdKey = control.id .. ":" .. key .. ":" .. tostring(bind.value) .. ":" .. mode
		if holdActive[holdKey] then return true end
		if (bindActiveUntil[holdKey] or 0) > os.clock() then return true end
		if mode == "Hold" then return false end
		if not control.get then return false end
		local ok, current = pcall(control.get)
		if not ok then return false end
		if control.kind == "toggle" then
			return current == true
		elseif control.kind == "slider" then
			local n = tonumber(bind.value)
			return n ~= nil and math.abs(tonumber(current) - n) <= ((control.step or 1) * 0.5)
		elseif control.kind == "dropdown" then
			return tostring(bind.value):lower() ~= "next" and tostring(current) == tostring(bind.value)
		elseif control.kind == "color" then
			local c = parseColor(bind.value)
			return c ~= nil and valueToText(current) == colorToHex(c)
		elseif control.kind == "textbox" then
			return tostring(current) == tostring(bind.value)
		end
		return false
	end

	local keybindRenderSignature = ""
	local function refreshKeybindList()
		local rows = {}
		for id, list in pairs(cfg.UIBinds or {}) do
			local control = controls[id]
			if control and type(list) == "table" then
				for _, bind in ipairs(list) do
					if bindIsActive(control, bind) then
						local value = bind.value
						if control.get then
							local ok, current = pcall(control.get)
							if ok then value = valueToText(current) end
						end
						table.insert(rows, tostring(bind.key) .. "  " .. tostring(control.label) .. " = " .. tostring(value))
					end
				end
			end
		end
		table.sort(rows)
		local signature = table.concat(rows, "\n")
		if signature == keybindRenderSignature then return end
		keybindRenderSignature = signature
		for _, child in ipairs(keybindContent:GetChildren()) do
			if child:IsA("TextLabel") or child:IsA("Frame") then child:Destroy() end
		end
		if #rows == 0 then
			keybindFrame.Size = UDim2.fromOffset(260, 42)
			return
		end
		for _, text in ipairs(rows) do
			local row = mk(keybindContent, "Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundColor3 = theme.root,
				BackgroundTransparency = 0.18,
				BorderSizePixel = 0,
			})
			corner(row, 5)
			local dot = mk(row, "Frame", {
				Size = UDim2.fromOffset(3, 12),
				Position = UDim2.fromOffset(6, 5),
				BackgroundColor3 = theme.accent2,
				BorderSizePixel = 0,
			})
			corner(dot, 2)
			mk(row, "TextLabel", {
				Size = UDim2.new(1, 0, 0, 19),
				Position = UDim2.fromOffset(14, 1),
				BackgroundTransparency = 1,
				Font = uiFont,
				Text = text,
				TextSize = textSize(11),
				TextColor3 = theme.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
		end
	end

	local function createRow(tab, label, height)
		label = tostring(label or "Control")
		local row = mk(tab.page, "Frame", {
			Size = UDim2.new(1, 0, 0, height or 34),
			BackgroundColor3 = theme.panel,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		})
		corner(row, 0)
		local rowStroke = stroke(row, theme.line, 1)
		local accentBar = mk(row, "Frame", {
			Size = UDim2.fromOffset(1, height and math.max(18, height - 10) or 24),
			Position = UDim2.fromOffset(0, 5),
			BackgroundColor3 = theme.accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		})
		corner(accentBar, 0)
		local labelObj = mk(row, "TextLabel", {
			Size = UDim2.new(1, -230, 0, 24),
			Position = UDim2.fromOffset(26, 4),
			BackgroundTransparency = 1,
			Font = uiFont,
			Text = label,
			TextSize = textSize(12),
			TextColor3 = theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local bindGlyph = mk(row, "TextButton", {
			Name = "BindOpen",
			Size = UDim2.fromOffset(28, 14),
			Position = UDim2.fromOffset(22, 23),
			BackgroundColor3 = theme.root,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = uiFont,
			Text = "key",
			TextSize = textSize(9),
			TextColor3 = theme.accent2,
			Visible = false,
		})
		corner(bindGlyph, 0)
		stroke(bindGlyph, theme.line, 0.75)
		row.MouseEnter:Connect(function()
			bindGlyph.Visible = true
			TweenService:Create(rowStroke, TweenInfo.new(0.12), {Color = theme.line, Transparency = 0.78}):Play()
			TweenService:Create(accentBar, TweenInfo.new(0.12), {BackgroundTransparency = 0.15}):Play()
		end)
		row.MouseLeave:Connect(function()
			bindGlyph.Visible = false
			TweenService:Create(rowStroke, TweenInfo.new(0.12), {Color = theme.line, Transparency = 1}):Play()
			TweenService:Create(accentBar, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
		end)
		return row, labelObj, bindGlyph
	end

	local window = {}
	local function refreshTabLayout()
		local count = #tabs
		if count <= 0 then return end
		local available = math.max(1, windowHeight - 68)
		local height = math.clamp(math.floor(available / count), 38, 62)
		local overflow = height * count > available
		nav.ScrollBarThickness = overflow and 3 or 0
		for _, item in ipairs(tabs) do
			item.button.Size = UDim2.new(1, overflow and -3 or 0, 0, height)
			item.button.Text = count <= 6 and string.upper(item.name) or string.upper(item.name:sub(1, 3))
			item.button.TextSize = textSize(count <= 6 and 12 or 11)
		end
	end

	function window:Tab(id, name, internal)
		local tab = {id = id, name = tostring(name or id), controls = {}}
		local navBtn = button(nav, string.upper(tab.name), UDim2.fromOffset(76, 62))
		navBtn.LayoutOrder = #tabs + 1
		navBtn.Font = uiFontBold
		navBtn.TextSize = textSize(12)
		navBtn.TextColor3 = theme.muted
		local page = mk(content, "Frame", {
			Size = UDim2.new(1, -4, 0, 0),
			BackgroundTransparency = 1,
			Visible = false,
			AutomaticSize = Enum.AutomaticSize.Y,
		})
		mk(page, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
		tab.button = navBtn
		tab.page = page
		tab.subtabs = {}
		tabs[id] = tab
		table.insert(tabs, tab)
		refreshTabLayout()
		navBtn.MouseButton1Click:Connect(function()
			api:SetTab(id)
		end)
		if not activeTab then api:SetTab(id) end
		function tab:SubTab(subId, subName)
			if not tab.subNav then
				tab.subNav = mk(tab.page, "Frame", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = theme.panel,
					BorderSizePixel = 0,
					LayoutOrder = -1000,
				})
				corner(tab.subNav, 0)
				stroke(tab.subNav, theme.line, 0.72)
				mk(tab.subNav, "UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
				mk(tab.subNav, "UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				})
				tab.subBody = mk(tab.page, "Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = -999,
				})
				mk(tab.subBody, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
			end
			local sub = {id = subId, name = subName, page = mk(tab.subBody, "Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false,
			})}
			mk(sub.page, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
			local subBtn = button(tab.subNav, tostring(subName), UDim2.fromOffset(104, 22))
			sub.button = subBtn
			table.insert(tab.subtabs, sub)
			local function setSubActive()
				for _, item in ipairs(tab.subtabs) do
					local on = item == sub
					item.page.Visible = on
					item.page.AutomaticSize = on and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
					item.page.Size = UDim2.new(1, 0, 0, 0)
					item.button:SetAttribute("AetherActive", on)
					item.button:SetAttribute("AetherActiveColor", theme.root)
					item.button:SetAttribute("AetherHoverColor", theme.soft)
					item.button.BackgroundColor3 = on and theme.root or theme.panel
					item.button.TextColor3 = on and theme.text or theme.muted
				end
			end
			subBtn.MouseButton1Click:Connect(setSubActive)
			if #tab.subtabs == 1 then setSubActive() end
			function sub:Toggle(options) return window:AddToggle(sub, options) end
			function sub:Button(options) return window:AddButton(sub, options) end
			function sub:Slider(options) return window:AddSlider(sub, options) end
			function sub:Dropdown(options) return window:AddDropdown(sub, options) end
			function sub:List(options) return window:AddList(sub, options) end
			function sub:TextBox(options) return window:AddTextBox(sub, options) end
			function sub:Color(options) return window:AddColor(sub, options) end
			function sub:ConfigManager(options) return window:AddConfigManager(sub, options) end
			function sub:Section(text) return window:AddSection(sub, text) end
			return sub
		end
		function tab:Toggle(options) return window:AddToggle(tab, options) end
		function tab:Button(options) return window:AddButton(tab, options) end
		function tab:Slider(options) return window:AddSlider(tab, options) end
		function tab:Dropdown(options) return window:AddDropdown(tab, options) end
		function tab:List(options) return window:AddList(tab, options) end
		function tab:TextBox(options) return window:AddTextBox(tab, options) end
		function tab:Color(options) return window:AddColor(tab, options) end
		function tab:ConfigManager(options) return window:AddConfigManager(tab, options) end
		function tab:Section(text) return window:AddSection(tab, text) end
		if not internal and ensureSettingsTab then
			ensureSettingsTab()
		end
		return tab
	end

	function api:SetTab(id)
		activeTab = id
		for _, tab in ipairs(tabs) do
			local on = tab.id == id
			tab.page.Visible = on
			tab.button:SetAttribute("AetherActive", on)
			tab.button:SetAttribute("AetherActiveColor", theme.panel)
			tab.button:SetAttribute("AetherHoverColor", theme.panel)
			tab.button.BackgroundColor3 = on and theme.panel or theme.root
			tab.button.TextColor3 = on and theme.text or theme.muted
		end
	end

	function api:RefreshAll()
		for _, fn in ipairs(refreshers) do
			pcall(fn)
		end
	end

	function api:SetVisible(v)
		menuVisibleState = v == true
		cfg.MenuVisible = menuVisibleState
		if v then
			root.Visible = true
			local targetScale = cfg.UIScaleValue or scale.Scale or 1
			scale.Scale = targetScale * 0.985
			root.BackgroundTransparency = 0.08
			TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = targetScale}):Play()
			TweenService:Create(root, TweenInfo.new(0.16), {BackgroundTransparency = 0.02}):Play()
		else
			root.Visible = false
			bindPopup.Visible = false
			captureBind = nil
			closeDropdownPopups(nil)
		end
		Events:Emit("MenuVisibilityChanged", menuVisibleState)
	end

	function api:IsVisible()
		return menuVisibleState
	end

	function api:SetScale(v)
		cfg.UIScaleValue = v
		scale.Scale = v
	end

	function api:SetWatermark(text, visible)
		watermarkText.Text = tostring(text or "")
		resizeWatermark()
		if visible ~= nil then
			watermark.Visible = visible
		end
	end

	function api:SetKeybindListVisible(v)
		keybindFrame.Visible = v
	end

	function api:DisableAllControls()
		for id, control in pairs(controls) do
			if not tostring(id):match("^__aether_") and control.set then
				if control.kind == "toggle" then
					pcall(function() control.set(false) end)
				elseif control.kind == "slider" and control.min ~= nil then
					pcall(function() control.set(control.default or control.min) end)
				elseif control.kind == "dropdown" then
					local items = control.getItems and control.getItems() or control.options or {}
					if type(items) == "table" and items[1] ~= nil then
						pcall(function() control.set(control.default or items[1]) end)
					end
				elseif control.kind == "list" then
					pcall(function() control.set(control.default or "") end)
				elseif control.kind == "textbox" then
					pcall(function() control.set(control.default or "") end)
				elseif control.kind == "color" and control.default then
					pcall(function() control.set(control.default) end)
				end
				if control.refresh then pcall(control.refresh) end
			end
		end
		holdActive = {}
		bindActiveUntil = {}
		refreshKeybindList()
	end

	function api:Destroy()
		pcall(function() api:DisableAllControls() end)
		Events:Emit("Destroying", api)
		Events:Destroy()
		if rainbowConnection then rainbowConnection:Disconnect(); rainbowConnection = nil end
		table.clear(rainbowControls)
		for _, connection in ipairs(runtimeConnections) do
			pcall(function() connection:Disconnect() end)
		end
		table.clear(runtimeConnections)
		table.clear(inputChangedHandlers)
		table.clear(inputEndedHandlers)
		root:Destroy()
		watermark:Destroy()
		keybindFrame:Destroy()
	end

	function window:AddToggle(tab, options)
		local label = options.label or options.id
		local row, labelObj = createRow(tab, label)
		local sw = button(row, "", UDim2.fromOffset(10, 10))
		sw.Position = UDim2.fromOffset(8, 12)
		sw.Text = ""
		sw.TextTransparency = 1
		sw.ZIndex = row.ZIndex + 1
		local swStroke = sw:FindFirstChildOfClass("UIStroke")
		local value = options.default or false
		local getter = options.get or function() return value end
		local setter = options.set or function(v) value = v end
		local control = {
			id = options.id,
			label = label,
			kind = "toggle",
			default = options.default or false,
			get = getter,
			set = function(v)
				setter(v)
				if options.after then options.after(v) end
			end,
		}
		function control.refresh()
			local v = control.get()
			sw.Text = ""
			sw:SetAttribute("AetherActive", v)
			sw:SetAttribute("AetherActiveColor", theme.good)
			sw:SetAttribute("AetherHoverColor", theme.accent)
			sw.BackgroundColor3 = v and theme.good or Color3.fromRGB(28, 28, 28)
			if swStroke then
				swStroke.Color = v and theme.good or Color3.fromRGB(71, 71, 71)
				swStroke.Transparency = v and 0.05 or 0.25
			end
			labelObj.TextColor3 = v and theme.good or theme.text
		end
		sw.MouseButton1Click:Connect(function()
			control.set(not control.get())
			control.refresh()
		end)
		table.insert(refreshers, control.refresh)
		control.refresh()
		return registerControl(control, row)
	end

	function window:AddButton(tab, options)
		local label = options.label or options.id
		local row = createRow(tab, label)
		local run = button(row, options.text or "RUN", UDim2.fromOffset(86, 30))
		run.Position = UDim2.new(1, -106, 0.5, -15)
		local control = {
			id = options.id,
			label = label,
			kind = "button",
			fire = options.fire or function() end,
			release = options.release,
			refresh = function() end,
		}
		run.MouseButton1Click:Connect(control.fire)
		return registerControl(control, row)
	end

	function window:AddSlider(tab, options)
		local label = options.label or options.id
		local row, _, _ = createRow(tab, label, 54)
		local valueBox = mk(row, "TextBox", {
			Size = UDim2.fromOffset(86, 18),
			Position = UDim2.new(1, -98, 0, 5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = uiFont,
			TextSize = textSize(11),
			TextColor3 = theme.accent,
			TextXAlignment = Enum.TextXAlignment.Right,
			ClearTextOnFocus = false,
			Visible = true,
		})
		corner(valueBox, 0)
		mk(row, "TextLabel", {
			Size = UDim2.fromOffset(70, 14),
			Position = UDim2.fromOffset(26, 39),
			BackgroundTransparency = 1,
			Font = uiFont,
			TextSize = textSize(9),
			TextColor3 = theme.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = tostring(options.min),
		})
		mk(row, "TextLabel", {
			Size = UDim2.fromOffset(70, 14),
			Position = UDim2.new(1, -84, 0, 39),
			BackgroundTransparency = 1,
			Font = uiFont,
			TextSize = textSize(9),
			TextColor3 = theme.muted,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = tostring(options.max),
		})
        -- slider track: use menu soft color and line stroke to better match the overall theme
        local track = mk(row, "Frame", {
            Size = UDim2.new(1, -52, 0, 5),
            Position = UDim2.fromOffset(26, 32),
            BackgroundColor3 = theme.soft,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        })
        corner(track, 0)
        -- use theme.line for the stroke with a subtle transparency
        stroke(track, theme.line, 0.35)
		local fill = mk(track, "Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = theme.accent,
			BorderSizePixel = 0,
		})
		corner(fill, 0)
		local thumb = mk(track, "Frame", {
			Size = UDim2.fromOffset(5, 5),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = theme.accent2,
			BorderSizePixel = 0,
			ZIndex = 3,
		})
		corner(thumb, 0)
		local drag = false
		local value = options.default or options.min or 0
		local getter = options.get or function() return value end
		local setter = options.set or function(v) value = v end
		local control = {
			id = options.id,
			label = label,
			kind = "slider",
			min = options.min,
			max = options.max,
			step = options.step or 1,
			default = value,
			get = getter,
			set = function(v)
				setter(v)
				if options.after then options.after(v) end
			end,
		}
		local function setFromX(x)
			local pct = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
			local value = clampRound(control.min + (control.max - control.min) * pct, control.min, control.max, control.step)
			control.set(value)
			control.refresh()
		end
		function control.refresh()
			local v = control.get()
			local pct = math.clamp((v - control.min) / (control.max - control.min), 0, 1)
			fill.Size = UDim2.fromScale(pct, 1)
			thumb.Position = UDim2.new(pct, pct >= 1 and -5 or 0, 0, 0)
			valueBox.Text = tostring(v)
		end
		valueBox.Focused:Connect(function()
			valueBox.Visible = true
		end)
		valueBox.FocusLost:Connect(function()
			local n = tonumber(valueBox.Text)
			if n then
				control.set(clampRound(n, control.min, control.max, control.step))
			end
			control.refresh()
		end)
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				drag = true
				setFromX(input.Position.X)
			end
		end)
		onInputChanged(function(input)
			if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
				setFromX(input.Position.X)
			end
		end)
		onInputEnded(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
		end)
		table.insert(refreshers, control.refresh)
		control.refresh()
		return registerControl(control, row)
	end

	function window:AddDropdown(tab, options)
		options = options or {}
		local label = options.label or options.id
		local function getItems()
			if type(options.options) == "function" then
				local ok, result = pcall(options.options)
				return ok and type(result) == "table" and result or {}
			end
			return options.options or {}
		end
		local initialItems = getItems()
		local row = createRow(tab, label)
		local pick = button(row, "", UDim2.fromOffset(150, 24))
		pick.Position = UDim2.new(1, -160, 0.5, -12)
		pick.TextXAlignment = Enum.TextXAlignment.Left
		pick.TextColor3 = theme.text
		local arrow = mk(pick, "TextLabel", {
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.new(1, -24, 0.5, -10),
			BackgroundTransparency = 1,
			Font = uiFontBold,
			Text = "v",
			TextSize = textSize(11),
			TextColor3 = theme.accent2,
			ZIndex = 3,
		})
		local popup = mk(root, "Frame", {
			Size = UDim2.fromOffset(150, math.min(168, math.max(30, #initialItems * 22 + 6))),
			BackgroundColor3 = theme.root,
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 55,
		})
		corner(popup, 0)
		stroke(popup, Color3.fromRGB(61, 65, 76), 0.05).Thickness = 2
		addShadow(popup, 0.62)
		mk(popup, "UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3)})
		local popupList = mk(popup, "ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 56,
		})
		mk(popupList, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)})
		table.insert(dropdownPopups, popup)
		dropdownAnchors[popup] = pick
		local value = options.default or initialItems[1] or ""
		local getter = options.get or function() return value end
		local setter = options.set or function(v) value = v end
		local optionButtons = {}
		local optionSignature = nil
		local control = {
			id = options.id,
			label = label,
			kind = "dropdown",
			options = options.options,
			default = value,
			get = getter,
			getItems = getItems,
			set = function(v)
				setter(v)
				if options.after then options.after(v) end
			end,
		}
		local function renderOptions(force)
			local items = getItems()
			local parts = table.create(#items)
			for i, item in ipairs(items) do parts[i] = tostring(item) end
			local signature = table.concat(parts, "\0")
			if not force and signature == optionSignature then return end
			optionSignature = signature
			for _, child in ipairs(popupList:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
			end
			optionButtons = {}
			popup.Size = UDim2.fromOffset(150, math.min(168, math.max(30, #items * 22 + 6)))
			if #items == 0 then
				mk(popupList, "TextLabel", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					Font = uiFont,
					Text = options.emptyText or "empty",
					TextSize = textSize(11),
					TextColor3 = theme.muted,
					ZIndex = 57,
				})
				return
			end
			for _, opt in ipairs(items) do
				local optBtn = mk(popupList, "TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = theme.root,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Font = uiFont,
					Text = tostring(opt),
					TextSize = textSize(11),
					TextColor3 = theme.text,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 57,
				})
				mk(optBtn, "UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
				optionButtons[tostring(opt)] = optBtn
				optBtn.MouseEnter:Connect(function()
					optBtn.BackgroundTransparency = 0.08
					optBtn.BackgroundColor3 = theme.soft
					optBtn.TextColor3 = theme.accent2
				end)
				optBtn.MouseLeave:Connect(function()
					control.refresh()
				end)
				optBtn.MouseButton1Click:Connect(function()
					control.set(opt)
					control.refresh()
					popup.Visible = false
				end)
			end
		end
		function control.refresh()
			renderOptions(false)
			local current = tostring(control.get() or "")
			pick.Text = current ~= "" and current or (options.placeholder or "select")
			for opt, btn in pairs(optionButtons) do
				local on = opt == current
				btn.BackgroundTransparency = on and 0.08 or 1
				btn.BackgroundColor3 = on and Color3.fromRGB(18, 18, 18) or theme.root
				btn.TextColor3 = on and theme.accent or theme.text
			end
		end
		pick.MouseButton1Click:Connect(function()
			closeDropdownPopups(popup)
			renderOptions(true)
			local x = pick.AbsolutePosition.X - root.AbsolutePosition.X
			local y = pick.AbsolutePosition.Y - root.AbsolutePosition.Y + pick.AbsoluteSize.Y + 6
			local maxX = math.max(8, root.AbsoluteSize.X - popup.AbsoluteSize.X - 8)
			local maxY = math.max(8, root.AbsoluteSize.Y - popup.AbsoluteSize.Y - 8)
			popup.Position = UDim2.fromOffset(math.clamp(x, 8, maxX), math.clamp(y, 8, maxY))
			popup.Visible = not popup.Visible
			arrow.Text = popup.Visible and "^" or "v"
		end)
		popup:GetPropertyChangedSignal("Visible"):Connect(function()
			arrow.Text = popup.Visible and "^" or "v"
		end)
		table.insert(refreshers, control.refresh)
		control.refresh()
		return registerControl(control, row)
	end

	function window:AddList(tab, options)
		options = options or {}
		local mode = tostring(options.mode or (options.dropdown and "dropdown" or "open")):lower()
		if mode == "dropdown" or mode == "closed" then
			assert(not options.multi, "dropdown List mode does not support multi-select")
			return window:AddDropdown(tab, options)
		end
		local label = options.label or options.id or "List"
		local rowHeight = options.height or 118
		local row = createRow(tab, label, rowHeight)
		local listFrame = mk(row, "Frame", {
			Size = options.size or UDim2.new(0, 190, 1, -16),
			Position = options.position or UDim2.new(1, -204, 0, 8),
			BackgroundColor3 = theme.root,
			BorderSizePixel = 0,
			ZIndex = 2,
		})
		corner(listFrame, 0)
		stroke(listFrame, theme.line, 0.45)
		mk(listFrame, "UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)})
		local list = mk(listFrame, "ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 3,
		})
		mk(list, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1)})
        -- support multi-select lists
        local multi = options.multi or false
        -- internal storage for selected values (for multi) or single value
        local value = options.default or (multi and {} or "")
        local selectedMap = {}
        local selectedOrder = {}
        -- initialize selection for multi-select based on default
        if multi then
            local function initSelections(def)
                selectedMap = {}
                selectedOrder = {}
                if type(def) == "table" then
                    for _, val in ipairs(def) do
                        local s = tostring(val)
                        if not selectedMap[s] then
                            selectedMap[s] = true
                            table.insert(selectedOrder, s)
                        end
                    end
                elseif def ~= nil and tostring(def) ~= "" then
                    local s = tostring(def)
                    selectedMap[s] = true
                    selectedOrder = {s}
                end
            end
            initSelections(value)
        end
        -- getter returns the current value or selection
        local getter
        -- setter provided by user or internal
        local setter = options.set or function(v)
            value = v
        end
        if multi then
            getter = options.get or function()
                -- return a copy of the current selection
                local out = {}
                for i, val in ipairs(selectedOrder) do
                    out[i] = val
                end
                return out
            end
        else
            getter = options.get or function() return value end
        end
        local function updateSelections(v)
            -- helper to update selectedMap/selectedOrder from provided value
            selectedMap = {}
            selectedOrder = {}
            if type(v) == "table" then
                for _, val in ipairs(v) do
                    local s = tostring(val)
                    if not selectedMap[s] then
                        selectedMap[s] = true
                        table.insert(selectedOrder, s)
                    end
                end
            elseif v ~= nil and tostring(v) ~= "" then
                local s = tostring(v)
                selectedMap[s] = true
                selectedOrder = {s}
            end
        end
        local itemButtons = {}
        local control = {
            id = options.id,
            label = label,
            kind = "list",
            default = value,
            options = options.options,
            multi = multi,
            -- maxSelections can be a number or function
            maxSelections = options.maxSelections,
            get = getter,
            set = function(v)
                if multi then
                    updateSelections(v)
                else
                    value = v
                end
                setter(v)
                if options.after then options.after(v) end
            end,
        }
        local function getItems()
			if type(options.options) == "function" then
				local ok, result = pcall(options.options)
				return ok and type(result) == "table" and result or {}
			end
			return options.options or {}
		end
        -- expose getItems for binding logic
        control.getItems = getItems
        function control.refresh()
			for _, child in ipairs(list:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
			end
			itemButtons = {}
			local items = getItems()
			if #items == 0 then
				mk(list, "TextLabel", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					Font = uiFont,
					Text = options.emptyText or "empty",
					TextSize = textSize(11),
					TextColor3 = theme.muted,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 4,
				})
				return
			end
            for _, item in ipairs(items) do
                local itemText = tostring(item)
                local on
                if control.multi then
                    on = selectedMap[itemText] and true or false
                else
                    on = tostring(control.get()) == itemText
                end
                local btn = mk(list, "TextButton", {
                    Size = UDim2.new(1, 0, 0, options.itemHeight or 22),
                    BackgroundColor3 = theme.soft,
                    BackgroundTransparency = on and 0.1 or 1,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Font = uiFont,
                    Text = itemText,
                    TextSize = textSize(11),
                    TextColor3 = on and theme.accent or theme.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 4,
                })
                mk(btn, "UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
                itemButtons[itemText] = btn
                btn.MouseEnter:Connect(function()
                    btn.BackgroundTransparency = 0.08
                    btn.BackgroundColor3 = theme.soft
                    btn.TextColor3 = theme.accent2
                end)
                btn.MouseLeave:Connect(function()
                    local active
                    if control.multi then
                        active = selectedMap[itemText] and true or false
                    else
                        active = tostring(control.get()) == itemText
                    end
                    btn.BackgroundTransparency = active and 0.1 or 1
                    btn.BackgroundColor3 = theme.soft
                    btn.TextColor3 = active and theme.accent or theme.text
                end)
                btn.MouseButton1Click:Connect(function()
                    if control.multi then
                        -- toggle selection
                        if selectedMap[itemText] then
                            selectedMap[itemText] = nil
                            for i, v in ipairs(selectedOrder) do
                                if v == itemText then table.remove(selectedOrder, i) break end
                            end
                        else
                            -- determine current max
                            local maxSel = control.maxSelections
                            if type(maxSel) == "function" then
                                local ok, res = pcall(maxSel)
                                if ok then maxSel = res end
                            end
                            -- treat nil or <=0 as unlimited
                            if maxSel and tonumber(maxSel) and maxSel > 0 then
                                while #selectedOrder >= maxSel do
                                    local oldest = table.remove(selectedOrder, 1)
                                    if oldest then selectedMap[oldest] = nil end
                                end
                            end
                            table.insert(selectedOrder, itemText)
                            selectedMap[itemText] = true
                        end
                        -- call setter with a copy of selections
                        local out = {}
                        for i, val in ipairs(selectedOrder) do out[i] = val end
                        control.set(out)
                        control.refresh()
                    else
                        control.set(itemText)
                        control.refresh()
                    end
                end)
            end
		end
		table.insert(refreshers, control.refresh)
		control.refresh()
		return registerControl(control, row)
	end

	function window:AddTextBox(tab, options)
		local label = options.label or options.id
		local row = createRow(tab, label)
		local value = options.default or ""
		local getter = options.get or function() return value end
		local setter = options.set or function(v) value = v end
		local box = mk(row, "TextBox", {
			Size = UDim2.fromOffset(160, 30),
			Position = UDim2.new(1, -180, 0.5, -15),
			BackgroundColor3 = theme.root,
			BorderSizePixel = 0,
			Font = uiFont,
			TextSize = textSize(12),
			TextColor3 = theme.text,
			Text = tostring(getter()),
			ClearTextOnFocus = false,
		})
		corner(box, 0)
		stroke(box, theme.line, 0.58)
		box.FocusLost:Connect(function()
			setter(box.Text)
			if options.after then options.after(box.Text) end
		end)
		local control = {
			id = options.id,
			label = label,
			kind = "textbox",
			default = value,
			get = getter,
			set = function(v)
				setter(v)
				if options.after then options.after(v) end
			end,
			refresh = function() box.Text = tostring(getter()) end,
		}
		table.insert(refreshers, control.refresh)
		return registerControl(control, row)
	end

	function window:AddColor(tab, options)
		local label = options.label or options.id
		local row = createRow(tab, label, 34)
		if type(options.presets) == "table" then
			for _, preset in ipairs(options.presets) do
				local c = typeof(preset) == "Color3" and preset or parseColor(preset)
				if c then addSavedColor(c) end
			end
		end
		local value = options.default or savedColorAt(1) or theme.accent
		local getter = options.get or function() return value end
		local setter = options.set or function(v) value = v end
		local alphaGetter = options.getAlpha or function() return options.defaultAlpha or 1 end
		local alphaSetter = options.setAlpha
		local control = {
			id = options.id,
			label = label,
			kind = "color",
			presets = cfg.ColorPresets,
			default = value,
			get = getter,
			getAlpha = alphaGetter,
			setAlpha = alphaSetter,
			afterAlpha = options.after,
			set = function(v)
				setter(v)
				if options.after then options.after(v) end
			end,
			rainbowSpeed = options.rainbowSpeed or 0.12,
			rainbowSaturation = options.rainbowSaturation or 0.82,
			rainbowBrightness = options.rainbowBrightness or 1,
		}
		control.setRainbowColor = function(color)
			setter(color)
			if options.after then options.after(color) end
			if control.refresh then control.refresh() end
		end
		control.isRainbow = function()
			return cfg.ColorRainbow[control.id] == true
		end
		control.setRainbow = function(enabled)
			cfg.ColorRainbow[control.id] = enabled == true
			refreshRainbowDriver()
			if control.refresh then control.refresh() end
			Events:Emit("ColorRainbowChanged", control.id, enabled == true, control)
		end
		rainbowControls[control.id] = control
		local preview = button(row, "PICK", UDim2.fromOffset(104, 22))
		preview.Position = UDim2.new(1, -114, 0.5, -11)
		preview.Text = ""
		local previewSwatch = mk(preview, "Frame", {
			Size = UDim2.fromOffset(28, 14),
			Position = UDim2.fromOffset(4, 4),
			BackgroundColor3 = value,
			BorderSizePixel = 0,
			ZIndex = preview.ZIndex + 1,
		})
		corner(previewSwatch, 0)
		stroke(previewSwatch, theme.line, 0.25)
		local previewText = mk(preview, "TextLabel", {
			Size = UDim2.new(1, -36, 1, 0),
			Position = UDim2.fromOffset(36, 0),
			BackgroundTransparency = 1,
			Font = monoFont,
			Text = "",
			TextSize = textSize(10),
			TextColor3 = theme.accent2,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = preview.ZIndex + 1,
		})
        local picker = mk(root, "Frame", {
            Size = UDim2.fromOffset(560, 430),
            BackgroundColor3 = theme.panel,
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 60,
        })
        -- Shrink the entire color picker slightly to reduce wasted space
        do
            local cpScale = Instance.new("UIScale")
            cpScale.Scale = 0.72
            cpScale.Parent = picker
        end
		corner(picker, 0)
		stroke(picker, Color3.fromRGB(61, 65, 76), 0).Thickness = 3
		addShadow(picker, 0.58)
		mk(picker, "TextLabel", {
			Size = UDim2.new(1, -24, 0, 24),
			Position = UDim2.fromOffset(12, 9),
			BackgroundTransparency = 1,
			Font = uiFontBold,
			Text = "Palette / " .. tostring(label),
			TextSize = textSize(13),
			TextColor3 = theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 61,
		})
		local closePicker = button(picker, "x", UDim2.fromOffset(22, 20))
		closePicker.Position = UDim2.new(1, -34, 0, 8)
		closePicker.ZIndex = 62

		local h, s, v = Color3.toHSV(value)
		local a = alphaGetter()
		local dragTarget = nil
		local visualColor = value

		local spectrum = mk(picker, "Frame", {
			Size = UDim2.fromOffset(368, 170),
			Position = UDim2.fromOffset(180, 50),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 62,
		})
		corner(spectrum, 0)
		stroke(spectrum, theme.line, 0.28)
		local whiteOverlay = mk(spectrum, "Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = 63,
		})
		mk(whiteOverlay, "UIGradient", {
			Rotation = 0,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		local blackOverlay = mk(spectrum, "Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 64,
		})
		mk(blackOverlay, "UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		})
		local spectrumCursor = mk(spectrum, "Frame", {
			Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.65,
			BorderSizePixel = 0,
			ZIndex = 66,
		})
		stroke(spectrumCursor, Color3.fromRGB(0, 0, 0), 0).Thickness = 1

		local hueBar = mk(picker, "Frame", {
			Size = UDim2.fromOffset(514, 10),
			Position = UDim2.fromOffset(24, 238),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = 62,
		})
		corner(hueBar, 0)
		stroke(hueBar, theme.line, 0.28)
		mk(hueBar, "UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
			}),
		})
		local hueCursor = mk(hueBar, "Frame", {
			Size = UDim2.fromOffset(4, 14),
			Position = UDim2.fromOffset(0, -2),
			BackgroundColor3 = theme.text,
			BorderSizePixel = 0,
			ZIndex = 66,
		})
		corner(hueCursor, 0)

		local alphaBar = mk(picker, "Frame", {
			Size = UDim2.fromOffset(514, 10),
			Position = UDim2.fromOffset(24, 258),
			BackgroundColor3 = visualColor,
			BorderSizePixel = 0,
			ZIndex = 62,
		})
		corner(alphaBar, 0)
		stroke(alphaBar, theme.line, 0.28)
		mk(alphaBar, "UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.9),
				NumberSequenceKeypoint.new(1, 0),
			}),
		})
		local alphaCursor = mk(alphaBar, "Frame", {
			Size = UDim2.fromOffset(4, 14),
			Position = UDim2.fromOffset(0, -2),
			BackgroundColor3 = theme.text,
			BorderSizePixel = 0,
			ZIndex = 66,
		})
		corner(alphaCursor, 0)

		local previewLarge = mk(picker, "Frame", {
			Size = UDim2.fromOffset(150, 170),
			Position = UDim2.fromOffset(18, 50),
			BackgroundColor3 = value,
			BorderSizePixel = 0,
			ZIndex = 62,
		})
		corner(previewLarge, 0)
		stroke(previewLarge, theme.line, 0.35)

		local colorBox = mk(picker, "TextBox", {
			Size = UDim2.fromOffset(514, 24),
			Position = UDim2.fromOffset(24, 282),
			BackgroundColor3 = theme.root,
			BorderSizePixel = 0,
			Font = monoFont,
			TextSize = textSize(11),
			TextColor3 = theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			ZIndex = 62,
		})
		corner(colorBox, 0)
		stroke(colorBox, theme.line, 0.55)
		local channels = {}
		local fieldData = {
			{name = "RGB", x = 24, w = 100},
			{name = "CMYK", x = 132, w = 100},
			{name = "HSV", x = 240, w = 100},
			{name = "HSL", x = 348, w = 100},
			{name = "A", x = 456, w = 82},
		}
		for _, field in ipairs(fieldData) do
			local name = field.name
			local fieldX = field.x
			local fieldW = field.w
			mk(picker, "TextLabel", {
				Size = UDim2.fromOffset(fieldW, 12),
				Position = UDim2.fromOffset(fieldX, 306),
				BackgroundTransparency = 1,
				Font = uiFont,
				Text = name,
				TextSize = textSize(9),
				TextColor3 = theme.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 62,
			})
			local box = mk(picker, "TextBox", {
				Size = UDim2.fromOffset(fieldW, 22),
				Position = UDim2.fromOffset(fieldX, 320),
				BackgroundColor3 = theme.root,
				BorderSizePixel = 0,
				Font = monoFont,
				TextSize = textSize(9),
				TextColor3 = theme.text,
				PlaceholderText = name,
				TextXAlignment = Enum.TextXAlignment.Center,
				ClearTextOnFocus = false,
				TextEditable = name == "RGB" or name == "A",
				ZIndex = 62,
			})
			corner(box, 0)
			stroke(box, theme.line, 0.55)
			channels[name] = box
		end
		local swatchFrame = mk(picker, "Frame", {
			Size = UDim2.new(1, -24, 0, 46),
			Position = UDim2.fromOffset(12, 344),
			BackgroundColor3 = theme.root,
			BorderSizePixel = 0,
			ZIndex = 62,
		})
		corner(swatchFrame, 0)
		stroke(swatchFrame, theme.line, 0.45)
		mk(swatchFrame, "UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)})
		mk(swatchFrame, "UIGridLayout", {
			CellSize = UDim2.fromOffset(22, 14),
			CellPadding = UDim2.fromOffset(6, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		local applyBtn = button(picker, "APPLY", UDim2.new(0.25, -12, 0, 24))
		applyBtn.Position = UDim2.new(0, 12, 1, -34)
		applyBtn.ZIndex = 62
		local saveBtn = button(picker, "SAVE", UDim2.new(0.25, -12, 0, 24))
		saveBtn.Position = UDim2.new(0.25, 6, 1, -34)
		saveBtn.ZIndex = 62
		local rainbowBtn = button(picker, "RAINBOW", UDim2.new(0.25, -12, 0, 24))
		rainbowBtn.Position = UDim2.new(0.50, 0, 1, -34)
		rainbowBtn.ZIndex = 62
		local copyBtn = button(picker, "COPY", UDim2.new(0.25, -12, 0, 24))
		copyBtn.Position = UDim2.new(0.75, -6, 1, -34)
		copyBtn.ZIndex = 62
		table.insert(dropdownPopups, picker)
		dropdownAnchors[picker] = preview

		local function currentColor()
			return Color3.fromHSV(h, s, v)
		end

		local function setAlpha(nextAlpha)
			a = math.clamp(nextAlpha, 0, 1)
			if control.setAlpha then
				control.setAlpha(a)
				if options.after then options.after(control.get()) end
			end
		end

		local function colorToHsvText(c)
			local hh, ss, vv = Color3.toHSV(c)
			return string.format("%d°  %d%%  %d%%", math.floor(hh * 360 + 0.5), math.floor(ss * 100 + 0.5), math.floor(vv * 100 + 0.5))
		end

		local function colorToCmykText(c)
			local k = 1 - math.max(c.R, c.G, c.B)
			if k >= 0.999 then
				return "0%  0%  0%  100%"
			end
			local cyan = (1 - c.R - k) / (1 - k)
			local magenta = (1 - c.G - k) / (1 - k)
			local yellow = (1 - c.B - k) / (1 - k)
			return string.format("%d%%  %d%%  %d%%  %d%%", math.floor(cyan * 100 + 0.5), math.floor(magenta * 100 + 0.5), math.floor(yellow * 100 + 0.5), math.floor(k * 100 + 0.5))
		end

		local function colorToHslText(c)
			local r, g, b = c.R, c.G, c.B
			local maxV = math.max(r, g, b)
			local minV = math.min(r, g, b)
			local l = (maxV + minV) / 2
			local hh = 0
			local ss = 0
			if maxV ~= minV then
				local d = maxV - minV
				ss = l > 0.5 and d / (2 - maxV - minV) or d / (maxV + minV)
				if maxV == r then
					hh = ((g - b) / d + (g < b and 6 or 0)) / 6
				elseif maxV == g then
					hh = ((b - r) / d + 2) / 6
				else
					hh = ((r - g) / d + 4) / 6
				end
			end
			return string.format("%d°  %d%%  %d%%", math.floor(hh * 360 + 0.5), math.floor(ss * 100 + 0.5), math.floor(l * 100 + 0.5))
		end

		local function syncPickerText()
			local c = control.get()
			a = control.getAlpha and control.getAlpha() or a or 1
			channels.RGB.Text = colorToRgbText(c)
			channels.CMYK.Text = colorToCmykText(c)
			channels.HSV.Text = colorToHsvText(c)
			channels.HSL.Text = colorToHslText(c)
			channels.A.Text = tostring(a or 1)
			colorBox.Text = colorToHex(c)
			h, s, v = Color3.toHSV(c)
			visualColor = c
			spectrum.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			previewLarge.BackgroundColor3 = c
			alphaBar.BackgroundColor3 = c
			spectrumCursor.Position = UDim2.new(s, -4, 1 - v, -4)
			hueCursor.Position = UDim2.new(h, -2, 0, -2)
			alphaCursor.Position = UDim2.new(math.clamp(a or 1, 0, 1), -2, 0, -2)
		end
		local function applyPickerText()
			local c, a = parseColor(colorBox.Text)
			if c then
				control.set(c)
				if a then setAlpha(a) end
				control.refresh()
				syncPickerText()
			end
		end
		local function applyChannelText()
			local r, g, b = tostring(channels.RGB.Text):match("(%d+)%D+(%d+)%D+(%d+)")
			r, g, b = tonumber(r), tonumber(g), tonumber(b)
			local nextAlpha = tonumber(channels.A.Text)
			if r and g and b then
				local c = Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
				control.set(c)
				if nextAlpha then setAlpha(nextAlpha) end
				control.refresh()
				syncPickerText()
			end
		end
		local function applyVisualColor()
			local c = currentColor()
			control.set(c)
			control.refresh()
			syncPickerText()
		end
		local function setSpectrumFromXy(x, y)
			s = math.clamp((x - spectrum.AbsolutePosition.X) / math.max(1, spectrum.AbsoluteSize.X), 0, 1)
			v = 1 - math.clamp((y - spectrum.AbsolutePosition.Y) / math.max(1, spectrum.AbsoluteSize.Y), 0, 1)
			applyVisualColor()
		end
		local function setHueFromX(x)
			h = math.clamp((x - hueBar.AbsolutePosition.X) / math.max(1, hueBar.AbsoluteSize.X), 0, 1)
			applyVisualColor()
		end
		local function setAlphaFromX(x)
			setAlpha((x - alphaBar.AbsolutePosition.X) / math.max(1, alphaBar.AbsoluteSize.X))
			control.refresh()
			syncPickerText()
		end
		local function renderSavedColors()
			for _, child in ipairs(swatchFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			for i = 1, math.min(#(cfg.ColorPresets or {}), 22) do
				local color = savedColorAt(i)
				if color then
					local s = mk(swatchFrame, "TextButton", {
						Size = UDim2.fromOffset(24, 18),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Font = uiFontBold,
						Text = "",
						TextSize = textSize(10),
						TextColor3 = Color3.fromRGB(10, 10, 10),
						ZIndex = 63,
					})
					corner(s, 0)
					stroke(s, theme.line, 0.25)
                    s.MouseButton1Click:Connect(function()
                        control.set(color)
                        control.refresh()
                        syncPickerText()
                    end)
                    
                    s.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton2 then
                            -- remove the color from saved presets
                            local targetHex = colorToHex(color)
                            for idx = #(cfg.ColorPresets or {}), 1, -1 do
                                local c = savedColorAt(idx)
                                if c and colorToHex(c) == targetHex then
                                    table.remove(cfg.ColorPresets, idx)
                                    break
                                end
                            end
                            renderSavedColors()
                        end
                    end)
				end
			end
		end

		spectrum.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragTarget = "spectrum"
				setSpectrumFromXy(input.Position.X, input.Position.Y)
			end
		end)
		hueBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragTarget = "hue"
				setHueFromX(input.Position.X)
			end
		end)
		alphaBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragTarget = "alpha"
				setAlphaFromX(input.Position.X)
			end
		end)
		onInputChanged(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			if dragTarget == "spectrum" then
				setSpectrumFromXy(input.Position.X, input.Position.Y)
			elseif dragTarget == "hue" then
				setHueFromX(input.Position.X)
			elseif dragTarget == "alpha" then
				setAlphaFromX(input.Position.X)
			end
		end)
		onInputEnded(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragTarget = nil
			end
		end)
		colorBox.FocusLost:Connect(applyPickerText)
		for _, box in pairs(channels) do
			box.FocusLost:Connect(applyChannelText)
		end
		applyBtn.MouseButton1Click:Connect(applyPickerText)
		saveBtn.MouseButton1Click:Connect(function()
			applyPickerText()
			addSavedColor(control.get())
			renderSavedColors()
		end)
		rainbowBtn.MouseButton1Click:Connect(function()
			control.setRainbow(not control.isRainbow())
		end)
		copyBtn.MouseButton1Click:Connect(function()
			syncPickerText()
			pcall(function() if setclipboard then setclipboard(colorBox.Text .. " / " .. colorToRgbaText(control.get(), a)) end end)
		end)
		closePicker.MouseButton1Click:Connect(function() picker.Visible = false end)
        preview.MouseButton1Click:Connect(function()
			closeDropdownPopups(picker)
			syncPickerText()
			renderSavedColors()
			local x = preview.AbsolutePosition.X - root.AbsolutePosition.X - 220
			local y = preview.AbsolutePosition.Y - root.AbsolutePosition.Y + preview.AbsoluteSize.Y + 6
			local maxX = math.max(8, root.AbsoluteSize.X - picker.AbsoluteSize.X - 8)
			local maxY = math.max(8, root.AbsoluteSize.Y - picker.AbsoluteSize.Y - 8)
			picker.Position = UDim2.fromOffset(math.clamp(x, 8, maxX), math.clamp(y, 8, maxY))
			picker.Visible = not picker.Visible
		end)
        
        preview.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                
                control.set(control.default)
                if control.setAlpha then control.setAlpha(alphaGetter() or 1) end
                control.refresh()
            end
        end)
		function control.refresh()
			local c = control.get()
			local rainbow = control.isRainbow()
			preview:SetAttribute("AetherActive", false)
			preview.BackgroundColor3 = theme.root
			preview.Text = ""
			previewSwatch.BackgroundColor3 = c
			previewText.Text = (rainbow and "R " or "") .. colorToHex(c)
			rainbowBtn:SetAttribute("AetherActive", rainbow)
			rainbowBtn:SetAttribute("AetherActiveColor", theme.good)
			rainbowBtn.BackgroundColor3 = rainbow and theme.good or theme.root
			rainbowBtn.TextColor3 = rainbow and theme.root or theme.text
			bindValueBox.Text = selectedControl == control and colorToHex(c) or bindValueBox.Text
		end
		table.insert(refreshers, control.refresh)
		control.refresh()
		refreshRainbowDriver()
		return registerControl(control, row)
	end

	function window:AddSection(tab, text)
		local row = mk(tab.page, "TextLabel", {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			Font = uiFontBold,
			Text = tostring(text or "Section"),
			TextSize = textSize(13),
			TextColor3 = theme.accent,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		return row
	end

	function window:AddConfigManager(tab, options)
		options = options or {}
		local row = mk(tab.page, "Frame", {
			Size = UDim2.new(1, 0, 0, 172),
			BackgroundColor3 = theme.panel2,
			BorderSizePixel = 0,
		})
		corner(row, 0)
		stroke(row, theme.line, 0.72)
		mk(row, "TextLabel", {
			Size = UDim2.new(1, -24, 0, 22),
			Position = UDim2.fromOffset(12, 8),
			BackgroundTransparency = 1,
			Font = uiFontBold,
			Text = options.label or "Config manager",
			TextSize = textSize(13),
			TextColor3 = theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local nameBox = mk(row, "TextBox", {
			Size = UDim2.new(0.30, -16, 0, 30),
			Position = UDim2.fromOffset(12, 38),
			BackgroundColor3 = theme.root,
			BorderSizePixel = 0,
			Font = uiFont,
			Text = options.defaultName or configName,
			PlaceholderText = "config name",
			TextSize = textSize(12),
			TextColor3 = theme.text,
			ClearTextOnFocus = false,
		})
		corner(nameBox, 0)
		stroke(nameBox, theme.line, 0.55)
		local refreshBtn = button(row, "REFRESH", UDim2.new(0.15, -10, 0, 30))
		refreshBtn.Position = UDim2.new(0.30, 4, 0, 38)
		local configPanel = mk(row, "Frame", {
			Size = UDim2.new(0.55, -20, 0, 102),
			Position = UDim2.new(0.45, 4, 0, 38),
			BackgroundColor3 = theme.root,
			BorderSizePixel = 0,
			ZIndex = 2,
		})
		corner(configPanel, 0)
		stroke(configPanel, theme.line, 0.45)
		mk(configPanel, "UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5)})
		local configList = mk(configPanel, "ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.accent,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ZIndex = 3,
		})
		mk(configList, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1)})
		local save = button(row, "SAVE", UDim2.new(0.225, -14, 0, 28))
		save.Position = UDim2.fromOffset(12, 76)
		local load = button(row, "LOAD", UDim2.new(0.225, -14, 0, 28))
		load.Position = UDim2.new(0.225, 4, 0, 76)
		local deleteBtn = button(row, "DELETE", UDim2.new(0.225, -14, 0, 28))
		deleteBtn.Position = UDim2.fromOffset(12, 112)
		local clearBtn = button(row, "CLEAR", UDim2.new(0.225, -14, 0, 28))
		clearBtn.Position = UDim2.new(0.225, 4, 0, 112)
		local status = mk(row, "TextLabel", {
			Size = UDim2.new(1, -24, 0, 18),
			Position = UDim2.fromOffset(12, 146),
			BackgroundTransparency = 1,
			Font = uiFont,
			Text = "",
			TextSize = textSize(11),
			TextColor3 = theme.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local function setStatus(text)
			status.Text = tostring(text or "")
			notify(status.Text)
		end
		local function renderConfigList()
			for _, child in ipairs(configList:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
			end
			local names = configApi:List()
			if #names == 0 then
				mk(configList, "TextLabel", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					Font = uiFont,
					Text = "no configs",
					TextSize = textSize(11),
					TextColor3 = theme.muted,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 4,
				})
				return
			end
			for _, name in ipairs(names) do
				local selected = name == nameBox.Text
				local item = mk(configList, "TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = theme.soft,
					BackgroundTransparency = selected and 0.1 or 1,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Font = uiFont,
					Text = name,
					TextSize = textSize(11),
					TextColor3 = selected and theme.accent or theme.text,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 4,
				})
				mk(item, "UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
				item.TextXAlignment = Enum.TextXAlignment.Left
				item.MouseEnter:Connect(function()
					item.BackgroundTransparency = 0.08
					item.BackgroundColor3 = theme.soft
					item.TextColor3 = theme.accent2
				end)
				item.MouseLeave:Connect(function()
					local on = name == nameBox.Text
					item.BackgroundTransparency = on and 0.1 or 1
					item.BackgroundColor3 = theme.soft
					item.TextColor3 = on and theme.accent or theme.text
				end)
				item.MouseButton1Click:Connect(function()
					nameBox.Text = name
					renderConfigList()
					setStatus("selected: " .. name)
				end)
			end
		end
		refreshBtn.MouseButton1Click:Connect(function()
			renderConfigList()
			setStatus("list refreshed")
		end)
		save.MouseButton1Click:Connect(function()
			local ok, msg = configApi:Save(nameBox.Text)
			renderConfigList()
			setStatus(ok and ("saved: " .. tostring(msg)) or ("save failed: " .. tostring(msg)))
		end)
		load.MouseButton1Click:Connect(function()
			local ok, msg = configApi:Load(nameBox.Text)
			api:RefreshAll()
			setStatus(ok and "loaded" or ("load failed: " .. tostring(msg)))
		end)
		deleteBtn.MouseButton1Click:Connect(function()
			local ok, msg = configApi:Delete(nameBox.Text)
			renderConfigList()
			setStatus(ok and "deleted" or ("delete failed: " .. tostring(msg)))
		end)
		clearBtn.MouseButton1Click:Connect(function()
			nameBox.Text = ""
			renderConfigList()
			setStatus("name cleared")
		end)
		renderConfigList()
		return row
	end

	local settingsCreated = false
	ensureSettingsTab = function()
		if settingsCreated or env.settingsTab == false then return end
		settingsCreated = true
		local settings = window:Tab("__settings", "Settings", true)
		settings.button.LayoutOrder = 10000
		settings:Section("Menu")
		settings:ConfigManager({
			label = env.configLabel or "Configs",
			defaultName = env.configName or "default",
		})
		settings:Toggle({
			id = "__aether_keybind_list",
			label = "Keybind list",
			default = keybindFrame.Visible,
			get = function() return keybindFrame.Visible end,
			set = function(v) keybindFrame.Visible = v end,
		})
        settings:Toggle({
            id = "__aether_watermark",
            label = "Watermark",
            default = watermark.Visible,
            get = function() return watermark.Visible end,
            set = function(v) watermark.Visible = v end,
        })
        settings:Section("Watermark")
        local wmItems = {"FPS", "FPS 0.1", "Nickname", "Mode", "Config", "Server IP", "Speed", "Time"}
        local function currentSelections()
            local t = {}
            if cfg.WatermarkOptions.fps then table.insert(t, "FPS") end
            if cfg.WatermarkOptions.fps01 then table.insert(t, "FPS 0.1") end
            if cfg.WatermarkOptions.nick then table.insert(t, "Nickname") end
            if cfg.WatermarkOptions.mode then table.insert(t, "Mode") end
            if cfg.WatermarkOptions.config then table.insert(t, "Config") end
            if cfg.WatermarkOptions.serverIP then table.insert(t, "Server IP") end
            if cfg.WatermarkOptions.speed then table.insert(t, "Speed") end
            if cfg.WatermarkOptions.time then table.insert(t, "Time") end
            return t
        end
        settings:List({
            id = "__wm_list",
            label = "Elements",
            options = wmItems,
            default = currentSelections(),
            multi = true,
            after = function(vals)
                local items = vals
                if type(items) ~= "table" then items = {items} end
                for k,_ in pairs(cfg.WatermarkOptions) do cfg.WatermarkOptions[k] = false end
                local map = { ["FPS"] = "fps", ["FPS 0.1"] = "fps01", ["Nickname"] = "nick", ["Mode"] = "mode", ["Config"] = "config", ["Server IP"] = "serverIP", ["Speed"] = "speed", ["Time"] = "time" }
                for _, name in ipairs(items) do
                    local key = map[name]
                    if key then cfg.WatermarkOptions[key] = true end
                end
            end,
        })
		settings:Button({
			id = "__aether_unload",
			label = env.unloadLabel or "Unload",
			text = "UNLOAD",
			fire = function()
				pcall(function() api:DisableAllControls() end)
				if type(env.unload) == "function" then
					env.unload(api)
				end
				if root.Parent then
					api:Destroy()
				end
				notify("Menu unloaded")
			end,
		})
	end

	local function actionForInput(input, isDown)
		local key = keyName(input)
		if not key then return end
		for id, list in pairs(cfg.UIBinds) do
			local control = controls[id]
			if control then
				for _, bind in ipairs(list) do
					if tostring(bind.key):lower() == tostring(key):lower() then
						local mode = bind.mode or "Toggle"
						local holdKey = id .. ":" .. tostring(bind.key) .. ":" .. tostring(bind.value) .. ":" .. mode
						if isDown then
							if not holdActive[holdKey] then
								local previous = nil
								pcall(function()
									if control.get then previous = control.get() end
								end)
								holdActive[holdKey] = {previous = previous}
								setControlValue(control, bind.value, true, mode)
								bindActiveUntil[holdKey] = os.clock() + 0.85
								refreshKeybindList()
							end
						elseif holdActive[holdKey] then
							local previous = holdActive[holdKey].previous
							holdActive[holdKey] = nil
							if mode == "Hold" then
								setControlValue(control, bind.value, false, mode, previous)
							end
							if mode == "Hold" then
								bindActiveUntil[holdKey] = nil
							end
							refreshKeybindList()
						end
					end
				end
			end
		end
	end

	bindKeyBtn.MouseButton1Click:Connect(function()
		if not selectedControl then
			notify("Right-click a control first")
			return
		end
		captureBind = true
		bindKeyBtn.Text = "PRESS..."
		bindStatus.Text = "press key or mouse button..."
	end)

	bindModeBtn.MouseButton1Click:Connect(function()
		pendingMode = (pendingMode == "Toggle") and "Hold" or "Toggle"
		bindModeBtn.Text = string.upper(pendingMode)
	end)

	bindAddBtn.MouseButton1Click:Connect(function()
		if not selectedControl then
			notify("Right-click a control first")
			return
		end
		if not pendingKey then
			notify("Press key capture first")
			return
		end
		local value = normalizeBindValue(selectedControl, bindValueBox.Text)
		cfg.UIBinds[selectedControl.id] = cfg.UIBinds[selectedControl.id] or {}
		table.insert(cfg.UIBinds[selectedControl.id], {key = pendingKey, mode = pendingMode, value = value})
		pendingKey = nil
		captureBind = nil
		bindStatus.Text = pendingMode .. " bind added"
		bindKeyBtn.Text = "PICK KEY"
		refreshBindList()
		refreshKeybindList()
	end)

	bindClearBtn.MouseButton1Click:Connect(function()
		if not selectedControl then return end
		cfg.UIBinds[selectedControl.id] = {}
		refreshBindList()
		refreshKeybindList()
		notify("Control binds cleared")
	end)

	bindPopupClose.MouseButton1Click:Connect(function()
		bindPopup.Visible = false
		captureBind = nil
		selectedControl = nil
		bindStatus.Text = ""
		refreshBindList()
	end)

	trackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			local pos = input.Position
			if bindPopup.Visible and not pointInside(bindPopup, pos) then
				bindPopup.Visible = false
				captureBind = nil
				selectedControl = nil
				bindStatus.Text = ""
				refreshBindList()
			end
			local clickedPopup = false
			for _, popup in ipairs(dropdownPopups) do
				if pointInside(popup, pos) or pointInside(dropdownAnchors[popup], pos) then
					clickedPopup = true
					break
				end
			end
			if not clickedPopup then
				closeDropdownPopups(nil)
			end
		end
		if captureBind and selectedControl then
			local k = keyName(input)
			if k then
				pendingKey = k
				bindStatus.Text = "captured: " .. k
				bindKeyBtn.Text = "KEY: " .. k
				captureBind = nil
			end
			return
		end
		local toggleKey = env.toggleKey or Enum.KeyCode.Insert
		local toggleHit = input.UserInputType == Enum.UserInputType.Keyboard and (input.KeyCode == toggleKey or tostring(input.KeyCode):gsub("Enum.KeyCode.", "") == tostring(toggleKey))
		if toggleHit then
			api:SetVisible(not api:IsVisible())
			return
		end
		if UserInputService:GetFocusedTextBox() then return end
		actionForInput(input, true)
	end))

	trackConnection(UserInputService.InputEnded:Connect(function(input)
		actionForInput(input, false)
	end))

	makeDraggable(root, titleBar)
	makeDraggable(bindPopup, bindPopupTitle)

	local collapsed = false
	minimize.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		body.Visible = not collapsed
		nav.Visible = not collapsed
		bindPopup.Visible = false
		captureBind = nil
		root.Size = collapsed and UDim2.fromOffset(windowWidth, 78) or UDim2.fromOffset(windowWidth, windowHeight)
		minimize.Text = collapsed and "+" or "-"
		cfg.MenuCollapsed = collapsed
	end)

	close.MouseButton1Click:Connect(function()
		api:SetVisible(false)
	end)

	task.spawn(function()
		while root.Parent do
			local t = os.clock()
			grad.Rotation = 25 + math.sin(t * 0.35) * 10
			task.wait(0.08)
		end
	end)

	local keybindTick = 0
	trackConnection(RunService.Heartbeat:Connect(function(dt)
		if not keybindFrame.Parent then return end
		keybindTick = keybindTick + dt
		if keybindTick >= 0.18 then
			keybindTick = 0
			refreshKeybindList()
		end
	end))

	api.Root = root
	api.Watermark = watermark
	api.KeybindList = keybindFrame
	api.Window = window
	api.Theme = theme
	api.Config = configApi
	api.Controls = controls
	api.Events = Events
	function api:Tab(id, name) return window:Tab(id, name) end
	function api:CreateTab(id, name) return window:Tab(id, name) end
	api.SelectControl = selectControl
	api.RefreshBindList = refreshBindList
	api.SetControlValue = setControlValue

	return api
end

pcall(function()
	_G.Aether = Library
	_G.AetherMenuApi = Library
end)

pcall(function()
	if shared then
		shared.Aether = Library
		shared.AetherMenuApi = Library
	end
end)

return Library
