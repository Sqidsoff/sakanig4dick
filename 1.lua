--!strict
-- HvH All-in-One (ONE FILE) LocalScript
-- Put in: StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local LOSFilter = {}
local LOSParams = RaycastParams.new()
LOSParams.FilterType = Enum.RaycastFilterType.Exclude
LOSParams.FilterDescendantsInstances = LOSFilter
LOSParams.IgnoreWater = true

local function refreshLOSFilter()
	table.clear(LOSFilter)
	local char = LocalPlayer.Character
	if char then table.insert(LOSFilter, char) end
	LOSParams.FilterDescendantsInstances = LOSFilter
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)
refreshLOSFilter()

local cfg = {
	-- visuals
	ChamsEnabled = true,
	NameTagsEnabled = true,
	ChamsTeamColor = true,
	ChamsFillTransparency = 0.45,
	NameTagTeamColor = true,
	NameTagScale = 1.00,
	NameTagMaxScale = 1.20,
	VisualsAllPlayers = true, -- IMPORTANT: now chams/tags can include your team
	ShowDistance = true,
	ChamsThroughWalls = true,
	ChamsCustomColor = "#FF5050",

	-- aim
	AimEnabled = true,
	AimHitbox = "Head",
	AimFOV = 140,
	ShowFOV = true,
	AimSmoothness = 55, -- 0..100 speed (0=no aim movement, 100=instant snap)
	AimMaxDistance = 300,
	AimRequireLOS = true,
	AimAllPlayers = false,
	AimAlways = false,
	AimInputMode = "Hold", -- Hold | Toggle (double-press M1)
	AimToggleDoublePressWindow = 0.30,
	AimUseNearestVisibleHitbox = false,
	AimMultiPointEnabled = true,
	AimMultiPointScale = 0.42, -- 0..1, offsets from hitbox center
	AimPredictionEnabled = true,
	AimPredictionTime = 0.12,
	AimTrackingSmoothness = 65,
	SilentAim1Enabled = false,
	SilentAim1AutoMouse1 = false,
	SilentAim1AutoMouse1Interval = 0.06,
	SilentAim2Enabled = false,

	-- misc
	BhopEnabled = false,
	InfiniteJumpEnabled = false,
	FreecamEnabled = false,
	FreecamSpeed = 1.0,
	FreecamLookSensitivity = 0.18,
	NoClipEnabled = false,
	XrayEnabled = false,
	XrayTransparency = 0.65,
	RapidFireEnabled = false,
	RapidFireMultiplier = 1.0,
	BacklockEnabled = false,
	ProjectileRedirectEnabled = false,
	ProjectileRedirectRadius = 250,
	ProjectileRedirectStrength = 180,
	SlowModeEnabled = false,
	SlowMoveSpeed = 8,
	TriggerbotEnabled = false,
	TriggerbotRadius = 18,
	VerticalFreezeEnabled = false,
	FlyEnabled = false,
	FlySpeed = 90,
	FlyAcceleration = 12,
	GrappleEnabled = false,
	GrappleRange = 650,
	GrapplePull = 115,
	GrappleMaxSpeed = 150,
	WallRunEnabled = false,
	WallRunSpeed = 62,
	WallRunLift = 8,
	CeilingWalkEnabled = false,
	CeilingWalkSpeed = 34,
	CeilingWalkGravity = 85,
	TelekinesisEnabled = false,
	TelekinesisDistance = 18,
	TelekinesisPower = 145,
	TelekinesisMaxMass = 250,
	PhysicsTornadoEnabled = false,
	PhysicsTornadoRadius = 32,
	PhysicsTornadoForce = 95,
	PhysicsTornadoMaxParts = 24,
	SurfaceSurferEnabled = false,
	SurfaceSurferSpeed = 72,
	SurfaceSurferAcceleration = 85,
	TiltEnabled = false,
	TiltYaw = 0,
	TiltPitch = 0,
	TiltRoll = 0,
	ForwardLaunchEnabled = true,
	ForwardLaunchTiltDeg = 35,
	ForwardLaunchPower = 140,
	BananaDriftEnabled = false,
	BananaDriftStrength = 22,
	FakeLagPuppetEnabled = false,
	FakeLagStep = 0.10,
	MoonMagnetEnabled = false,
	MoonMagnetPower = 55,
	HeadHelicopterEnabled = false,
	HeadHelicopterSpeed = 420,
	PanicStatueEnabled = false,
	ReverseDayEnabled = false,
	RubberBandDashEnabled = false,
	RubberBandDashPower = 95,
	FloorIsLavaEnabled = false,
	FloorIsLavaIdleTime = 2.0,
	FloorIsLavaPower = 70,
	RandomLeanEnabled = false,
	RandomLeanRange = 28,
	ComedicRecoilEnabled = false,
	ComedicRecoilPower = 4.5,
	SafeTeleportEnabled = true,
	PlayerStickEnabled = false,
	PlayerStickInterval = 0.03,
	AutoUnstuckEnabled = true,
	AdaptiveAimEnabled = true,
	AdaptiveAimStrength = 45, -- 0..100, distance adaptation strength (100m baseline)
	WeaponProfilesEnabled = true,
	MoveSpeed = 16,
	SpiderEnabled = false,
	SpiderSpeed = 42,
	JumpPowerValue = 50,
	PlayerGravity = 196.2,
	GodModeEnabled = false,
	AutoSprint = false,
	ThirdPerson = false,
	ThirdPersonDistance = 12,
	CameraFOVOverride = false,
	CameraFOVValue = 90,
	CrosshairEnabled = false,
	CrosshairSize = 8,
	CrosshairGap = 4,
	Fullbright = false,
	ClockTimeOverride = false,
	ClockTimeValue = 14,
	HideLocalCharacter = false,
	AntiAFK = false,
	PanicMode = false,
	LowEndMode = false,
	ESPMaxDistance = 1200,
	SpectatorDetectionEnabled = true,
	UIScaleValue = 1.0,
	UIAnimations = true,
	HitSoundEnabled = true,
	HitSoundType = "Bell", -- Bell | Click | Bubble | Custom
	HitSoundCustomPath = "",
	AutoPeekEnabled = false,
	AutoPeekMode = "Normal", -- Normal | LagPeek
	MemeModeEnabled = false,

	-- ui
	MenuVisible = true,
	UIBinds = {},
	PlayerPriorityRules = {},
	PlayerESPRules = {},
}

local HITBOX_LIST = {
	"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso",
	"LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"
}

local AimHitboxPriority: {[string]: number} = {}
for _, p in ipairs(HITBOX_LIST) do
	AimHitboxPriority[p] = 3
end
AimHitboxPriority.Head = 5
AimHitboxPriority.UpperTorso = 4
AimHitboxPriority.HumanoidRootPart = 4

local isUnloaded = false
local mouse1Down = false
local aimToggleActive = false
local aimLastPressAt = 0
local spaceDown = false
local moveKeys = {W=false,A=false,S=false,D=false,E=false,Q=false}
local freecamCF: CFrame? = nil
local xrayApplied: {[BasePart]: boolean} = {}
local triggerbotAcc = 0
local backlockFireAcc = 0
local silent1HoldAcc = 0
local silent1AutoShootAcc = 0
local silent1PrelockPart = nil
local silent1PrelockUntil = 0
local rfPatchLastAt = 0
local infJumpLastAt = 0
local cleanupAcc = 0
local verticalFreezeY: number? = nil
local savedPositionCFrame: CFrame? = nil
local selectedPlayerName = ""
local selectedPlayerLabel = ""
local stickAcc = 0
local spectatorAcc = 0
local lastSpectatorSignature = ""
local stickyTargetPlayer: Player? = nil
local stickyTargetPart: BasePart? = nil
local stickyTargetUntil = 0
local STICKY_TARGET_GRACE = 0.45
local STICKY_FOV_MULTIPLIER = 1.30
local aimFilteredPart: BasePart? = nil
local aimFilteredPoint: Vector3? = nil
local recordShotCandidate: (() -> ())? = nil
local setProjectileRedirectEnabled: ((boolean) -> ())? = nil
local pendingShots: {[Humanoid]: {health: number, expires: number, part: BasePart?, player: Player?}} = {}
local characterModelCache: {[Player]: Model} = {}
local threatCache: {[Player]: {score: number, expires: number, maxDistance: number}} = {}
local Phantom = {
	enabled = game.PlaceId == 292439477 or game.GameId == 292439477,
	interface = nil,
	objectModule = nil,
	checked = false,
	lastTry = 0,
	scanAcc = 0,
}
local Motion = {
	flyActive = false,
	grappleHeld = false,
	grapplePoint = nil,
	grappleAnchor = nil,
	grappleBeam = nil,
	grappleRootAttachment = nil,
	ceilingActive = false,
	ceilingNormal = Vector3.yAxis,
	ceilingAttachment = nil,
	ceilingForce = nil,
	ceilingOrientation = nil,
	telePart = nil,
	teleTarget = nil,
	telePartAttachment = nil,
	teleTargetAttachment = nil,
	telePosition = nil,
	teleOrientation = nil,
	tornadoActive = false,
	tornadoParts = {},
	tornadoScanAcc = 0,
	tornadoAngle = 0,
	silentNamecallHook = false,
	silentIndexHook = false,
	silentDirectRayHook = false,
}
local projectileCandidates = setmetatable({}, {__mode = "k"})
local projectileAddedSubscription: any = nil
local projectileRemovedSubscription: any = nil
local projectileHeartbeatSubscription: any = nil
local silent2Cache = {}
local fakeLagAcc = 0
local lavaIdleAcc = 0
local randomLeanAcc = 0
local randomLeanPitch, randomLeanYaw, randomLeanRoll = 0, 0, 0
local recoilKick = Vector2.zero
local panicStatueUntil = 0
local rubberDashCooldownUntil = 0
local unstuckAcc = 0
local profileTickAcc = 0
local lastProfileToolName = ""
local antiAfkConn: RBXScriptConnection? = nil
local visualTickAcc = 0
local visualDynamicCursor: Player? = nil
local lastFOVViewportSize = Vector2.zero
local worldTickAcc = 0
local noclipTickAcc = 0
local autoPeekStartCF = nil
local autoPeekPendingReturn = false
local autoPeekReturnAt = 0
local customSoundFiles = {}
local lastHideLocalApplied: boolean? = nil
local lastFullbrightApplied = false

local function isAimInputActive(): boolean
	if cfg.AimInputMode == "Toggle" then
		return aimToggleActive
	end
	return mouse1Down
end

local SOUND_DIR = "SigmaSounds"

local function fsHas(fnName: string): boolean
	return typeof(getfenv()[fnName]) == "function"
end

local function refreshCustomSoundFiles()
	customSoundFiles = {}
	if not fsHas("listfiles") then return end
	if fsHas("isfolder") and fsHas("makefolder") then
		local ok, exists = pcall(function() return (getfenv().isfolder :: any)(SOUND_DIR) end)
		if ok and (not exists) then pcall(function() (getfenv().makefolder :: any)(SOUND_DIR) end) end
	end
	local ok, files = pcall(function() return (getfenv().listfiles :: any)(SOUND_DIR) end)
	if not ok or typeof(files) ~= "table" then return end
	for _, p in ipairs(files) do
		local low = string.lower(tostring(p))
		if low:match("%.ogg$") or low:match("%.mp3$") or low:match("%.wav$") then
			table.insert(customSoundFiles, tostring(p):gsub("\\", "/"))
		end
	end
	table.sort(customSoundFiles)
	if #customSoundFiles == 0 then
		cfg.HitSoundCustomPath = ""
		return
	end
	if cfg.HitSoundCustomPath == "" then
		cfg.HitSoundCustomPath = customSoundFiles[1]
		return
	end
	for _, p in ipairs(customSoundFiles) do
		if p == cfg.HitSoundCustomPath then return end
	end
	cfg.HitSoundCustomPath = customSoundFiles[1]
end

local function setFreecam(v: boolean)
	cfg.FreecamEnabled = v
	if not Camera then return end
	if v then
		freecamCF = Camera.CFrame
		Camera.CameraSubject = nil
		Camera.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		freecamCF = nil
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then Camera.CameraSubject = hum end
		Camera.CameraType = Enum.CameraType.Custom
		if cfg.MenuVisible then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end
end

local WEAPON_PROFILES = {
	{match = "sniper", aimFov = 95, aimSmooth = 35, triggerRadius = 10, rapidMult = 2},
	{match = "shotgun", aimFov = 170, aimSmooth = 82, triggerRadius = 24, rapidMult = 1},
	{match = "smg", aimFov = 145, aimSmooth = 74, triggerRadius = 18, rapidMult = 3},
	{match = "rifle", aimFov = 130, aimSmooth = 62, triggerRadius = 16, rapidMult = 2},
}

local function sanitizeTeleportCF(targetCF: CFrame): CFrame
	if not cfg.SafeTeleportEnabled then return targetCF end
	local char = LocalPlayer.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = char and {char} or {}
	params.IgnoreWater = true

	local origin = targetCF.Position + Vector3.new(0, 40, 0)
	local down = Vector3.new(0, -120, 0)
	local hit = Workspace:Raycast(origin, down, params)
	local pos = targetCF.Position
	if hit then
		pos = Vector3.new(pos.X, hit.Position.Y + 3.2, pos.Z)
	end

	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = char and {char} or {}
	local parts = Workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(2.5, 5, 2.5), overlap)
	for _, p in ipairs(parts) do
		if p.CanCollide then
			pos += Vector3.new(0, 3.5, 0)
			break
		end
	end
	return CFrame.new(pos, pos + targetCF.LookVector)
end

local function teleportToCamera()
	if not Camera then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		hrp.CFrame = sanitizeTeleportCF(Camera.CFrame)
	end
end

local function findPlayerByIdentity(identity: string): Player?
	if identity == "" then return nil end
	local direct = Players:FindFirstChild(identity)
	if direct and direct:IsA("Player") then return direct end
	local lowered = string.lower(identity)
	for _, player in ipairs(Players:GetPlayers()) do
		if string.lower(player.Name) == lowered
			or string.lower(player.DisplayName) == lowered
			or tostring(player.UserId) == identity
		then
			return player
		end
	end
	return nil
end

function Phantom.findModule(moduleName: string): any
	local env = getfenv()
	if type(env[moduleName]) == "table" then return env[moduleName] end
	local environments = {env}
	if type(env.getgenv) == "function" then
		local ok, globalEnv = pcall(env.getgenv)
		if ok and type(globalEnv) == "table" then table.insert(environments, globalEnv) end
	end
	if type(env.getrenv) == "function" then
		local ok, robloxEnv = pcall(env.getrenv)
		if ok and type(robloxEnv) == "table" then table.insert(environments, robloxEnv) end
	end
	table.insert(environments, shared :: any)
	for _, source in ipairs(environments) do
		if type(source) == "table" then
			local direct = source[moduleName]
			if type(direct) == "table" then return direct end
			local sharedTable = source.shared
			if type(sharedTable) == "table" then
				local exported = sharedTable[moduleName]
				if type(exported) == "table" then return exported end
				local requireFn = sharedTable.RequireTable or sharedTable.require
				if type(requireFn) == "function" then
					local ok, module = pcall(requireFn, moduleName)
					if ok and type(module) == "table" then return module end
					local debugTable = env.debug
					local getupvalueFn = type(debugTable) == "table" and debugTable.getupvalue or nil
					if type(getupvalueFn) == "function" then
						local upOk, firstValue, secondValue = pcall(getupvalueFn, requireFn, 1)
						local upvalue = secondValue or firstValue
						if upOk and type(upvalue) == "table" then
							local cache = upvalue._cache
							local cached = type(cache) == "table" and cache[moduleName] or nil
							local cachedModule = type(cached) == "table" and (cached.module or cached) or nil
							if type(cachedModule) == "table" then return cachedModule end
						end
					end
				end
			end
			local requireFn = source.RequireTable or source.require
			if type(requireFn) == "function" then
				local ok, module = pcall(requireFn, moduleName)
				if ok and type(module) == "table" then return module end
			end
		end
	end
	return nil
end

function Phantom.getInterface(): any
	if not Phantom.enabled then return nil end
	if Phantom.interface then return Phantom.interface end
	if Phantom.checked and os.clock() - Phantom.lastTry < 2 then return nil end
	Phantom.checked = true
	Phantom.lastTry = os.clock()
	local ok, interface = pcall(Phantom.findModule, "ReplicationInterface")
	if ok and type(interface) == "table" then
		Phantom.interface = interface
		local moduleOk, objectModule = pcall(Phantom.findModule, "ReplicationObject")
		if moduleOk and type(objectModule) == "table" then Phantom.objectModule = objectModule end
	end
	return Phantom.interface
end

function Phantom.getEntry(player: Player): any
	local interface = Phantom.getInterface()
	if not interface or type(interface.getEntry) ~= "function" then return nil end
	local ok, entry = pcall(interface.getEntry, player)
	return ok and entry or nil
end

function Phantom.getThirdPerson(player: Player): any
	local entry = Phantom.getEntry(player)
	if not entry then return nil end
	local readyOk, ready = pcall(function() return entry:isReady() end)
	if readyOk and not ready then return nil end
	local ok, thirdPerson = pcall(function() return entry:getThirdPersonObject() end)
	if ok and thirdPerson then return thirdPerson end
	local module = Phantom.objectModule
	if module and type(module.getThirdPersonObject) == "function" then
		local moduleOk, moduleThirdPerson = pcall(module.getThirdPersonObject, entry)
		if moduleOk then return moduleThirdPerson end
	end
	return entry._thirdPersonObject
end

function Phantom.getCharacterHash(player: Player): any
	local thirdPerson = Phantom.getThirdPerson(player)
	if not thirdPerson then return nil end
	local ok, hash = pcall(function() return thirdPerson:getCharacterHash() end)
	if ok and type(hash) == "table" then return hash end
	local fallback = {
		head = thirdPerson._head,
		torso = thirdPerson._torso,
		larm = thirdPerson._larm,
		rarm = thirdPerson._rarm,
		lleg = thirdPerson._lleg,
		rleg = thirdPerson._rleg,
	}
	return typeof(fallback.head) == "Instance" and fallback or nil
end

function Phantom.getCharacter(player: Player): Model?
	local thirdPerson = Phantom.getThirdPerson(player)
	if not thirdPerson then return nil end
	local ok, model = pcall(function() return thirdPerson:getCharacterModel() end)
	if not ok or typeof(model) ~= "Instance" then model = thirdPerson._character end
	if ok and typeof(model) == "Instance" and model:IsA("Model") and model.Parent then
		characterModelCache[player] = model
		return model
	end
	return nil
end

function Phantom.getHealth(player: Player): (number?, number?)
	local entry = Phantom.getEntry(player)
	if not entry then return nil, nil end
	local ok, health = pcall(function() return entry:getHealth() end)
	if not ok or type(health) ~= "number" then health = entry._health end
	if type(health) ~= "number" then
		local aliveOk, alive = pcall(function() return entry:isAlive() end)
		if aliveOk then health = alive and 100 or 0 end
	end
	if type(health) ~= "number" then return nil, nil end
	return health, 100
end

local function findWorkspaceCharacter(player: Player): Model?
	local cached = characterModelCache[player]
	if cached and cached.Parent then return cached end
	local folders = {
		Workspace:FindFirstChild("Players"),
		Workspace:FindFirstChild("Characters"),
		Workspace:FindFirstChild("Live"),
		Workspace:FindFirstChild("Alive"),
	}
	local names = {player.Name, tostring(player.UserId), player.DisplayName}
	for _, folder in ipairs(folders) do
		if folder then
			for _, name in ipairs(names) do
				local found = folder:FindFirstChild(name, true)
				if found then
					local model = found:IsA("Model") and found or found:FindFirstAncestorOfClass("Model")
					if model then
						characterModelCache[player] = model
						return model
					end
				end
			end
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Model") then
					local owner = Players:GetPlayerFromCharacter(child)
					local userId = child:GetAttribute("UserId") or child:GetAttribute("PlayerUserId")
					if owner == player or tonumber(userId) == player.UserId then
						characterModelCache[player] = child
						return child
					end
				end
			end
		end
	end
	return nil
end

local function resolvePlayerCharacter(player: Player): Model?
	if Phantom.enabled and Phantom.getInterface() then
		local phantomCharacter = Phantom.getCharacter(player)
		if phantomCharacter then return phantomCharacter end
	end
	local character = player.Character
	if character and character.Parent then
		characterModelCache[player] = character
		return character
	end
	return findWorkspaceCharacter(player)
end

local function findCharacterPart(character: Model, partName: string, player: Player?): BasePart?
	local direct = character:FindFirstChild(partName, true)
	if direct and direct:IsA("BasePart") then return direct end
	local aliases = {
		Head = {"head"},
		HumanoidRootPart = {"torso", "rootpart", "root"},
		UpperTorso = {"torso"},
		LowerTorso = {"torso"},
		Torso = {"torso"},
		LeftUpperArm = {"larm", "leftarm"},
		LeftLowerArm = {"larm", "leftarm"},
		LeftHand = {"larm", "leftarm"},
		RightUpperArm = {"rarm", "rightarm"},
		RightLowerArm = {"rarm", "rightarm"},
		RightHand = {"rarm", "rightarm"},
		LeftUpperLeg = {"lleg", "leftleg"},
		LeftLowerLeg = {"lleg", "leftleg"},
		LeftFoot = {"lleg", "leftleg"},
		RightUpperLeg = {"rleg", "rightleg"},
		RightLowerLeg = {"rleg", "rightleg"},
		RightFoot = {"rleg", "rightleg"},
	}
	if player and Phantom.enabled then
		local hash = Phantom.getCharacterHash(player)
		for _, alias in ipairs(aliases[partName] or {string.lower(partName)}) do
			local part = hash and hash[alias]
			if typeof(part) == "Instance" and part:IsA("BasePart") then return part end
		end
	end
	for _, alias in ipairs(aliases[partName] or {string.lower(partName)}) do
		local part = character:FindFirstChild(alias, true)
		if part and part:IsA("BasePart") then return part end
	end
	return nil
end

local function resolveCharacterRoot(character: Model?): BasePart?
	if not character then return nil end
	local root = character:FindFirstChild("HumanoidRootPart")
		or character.PrimaryPart
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("Head")
	return root and root:IsA("BasePart") and root or nil
end

local function moveLocalCharacterExact(targetCF: CFrame, resetState: boolean?): boolean
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and resolveCharacterRoot(character)
	if not character or not root then return false end
	character:PivotTo(targetCF)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	if humanoid and resetState ~= false then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		task.defer(function()
			if humanoid.Parent then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
		end)
	end
	return true
end

local function teleportToPlayer(name: string): boolean
	local player = findPlayerByIdentity(name)
	if not player or player == LocalPlayer then return false end
	local character = resolvePlayerCharacter(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = resolveCharacterRoot(character)
	if not humanoid or humanoid.Health <= 0 or not root then return false end
	return moveLocalCharacterExact(root.CFrame, true)
end

local function stickToSelectedPlayer(): boolean
	local player = findPlayerByIdentity(selectedPlayerName)
	if not player or player == LocalPlayer then return false end
	local character = resolvePlayerCharacter(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = resolveCharacterRoot(character)
	if not humanoid or humanoid.Health <= 0 or not root then return false end
	return moveLocalCharacterExact(root.CFrame, false)
end

local function saveCurrentPosition()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		savedPositionCFrame = hrp.CFrame
	end
end

local function teleportToSavedPosition()
	if not savedPositionCFrame then return end
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		hrp.CFrame = sanitizeTeleportCF(savedPositionCFrame)
	end
end

local function forwardLaunchRagdoll(customAngleDeg: number?)
	local char = LocalPlayer.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or not hrp:IsA("BasePart") then return false end

	local head = char:FindFirstChild("Head")
	local baseDir = (head and head:IsA("BasePart") and head.CFrame.UpVector) or hrp.CFrame.LookVector
	if baseDir.Magnitude < 0.001 then return false end
	baseDir = baseDir.Unit

	local right = hrp.CFrame.RightVector
	if right.Magnitude < 0.001 then right = Vector3.new(1,0,0) end
	right = right.Unit
	local selectedDeg = customAngleDeg or cfg.ForwardLaunchTiltDeg
	local tilt = math.rad(math.clamp(selectedDeg, -80, 80))
	local launchDir = (CFrame.fromAxisAngle(right, tilt):VectorToWorldSpace(baseDir)).Unit

	-- ragdoll-like launch
	hum.PlatformStand = true
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	hrp.AssemblyAngularVelocity = right * 8
	hrp.AssemblyLinearVelocity = launchDir * math.max(30, cfg.ForwardLaunchPower)

	-- restore only after character has mostly stopped, then wait ~3 sec
	task.spawn(function()
		local stopStableTime = 0
		local timeoutAt = os.clock() + 12
		while hum and hum.Parent and hrp and hrp.Parent and os.clock() < timeoutAt do
			local speed = hrp.AssemblyLinearVelocity.Magnitude
			local grounded = hum.FloorMaterial ~= Enum.Material.Air
			if grounded and speed <= 3 then
				stopStableTime += 0.1
				if stopStableTime >= 0.8 then
					break
				end
			else
				stopStableTime = 0
			end
			task.wait(0.1)
		end

		if hum and hum.Parent then
			task.wait(3)
			if hum and hum.Parent then
				hum.PlatformStand = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end)
	return true
end

local function setCharacterCollision(enabled: boolean)
	local char = LocalPlayer.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = enabled
		end
	end
end

local function fullUnload()
	if isUnloaded then return end
	isUnloaded = true
	pcall(function() notify("Unloading script...") end)

	cfg.BhopEnabled = false
	cfg.InfiniteJumpEnabled = false
	cfg.NoClipEnabled = false
	cfg.FreecamEnabled = false
	cfg.AutoSprint = false
	cfg.VerticalFreezeEnabled = false
	cfg.FlyEnabled = false
	cfg.GrappleEnabled = false
	cfg.WallRunEnabled = false
	cfg.CeilingWalkEnabled = false
	cfg.TelekinesisEnabled = false
	cfg.PhysicsTornadoEnabled = false
	cfg.SurfaceSurferEnabled = false
	cfg.TiltEnabled = false
	cfg.SlowModeEnabled = false
	cfg.BacklockEnabled = false
	if setProjectileRedirectEnabled then setProjectileRedirectEnabled(false) end
	cfg.SpiderEnabled = false
	cfg.AimEnabled = false
	cfg.TriggerbotEnabled = false
	cfg.RapidFireEnabled = false
	cfg.SilentAim1Enabled = false
	cfg.SilentAim2Enabled = false
	cfg.ChamsEnabled = false
	cfg.NameTagsEnabled = false
	cfg.XrayEnabled = false
	cfg.CrosshairEnabled = false
	cfg.ShowFOV = false
	cfg.CameraFOVOverride = false
	cfg.ThirdPerson = false
	cfg.Fullbright = false
	cfg.ClockTimeOverride = false
	cfg.HideLocalCharacter = false
	cfg.GodModeEnabled = false
	cfg.AutoPeekEnabled = false
	cfg.PlayerStickEnabled = false
	cfg.MemeModeEnabled = false
	cfg.PanicMode = false
	cfg.PlayerGravity = 196.2
	cfg.MoveSpeed = 16
	cfg.JumpPowerValue = 50

	if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
	if Motion.cleanup then pcall(Motion.cleanup) end
	pcall(function() if updateSilent2Hitboxes then updateSilent2Hitboxes(1) end end)

	for part, _ in pairs(xrayApplied) do
		if part and part.Parent then
			part.LocalTransparencyModifier = 0
		end
		xrayApplied[part] = nil
	end

	for _, p in ipairs(Players:GetPlayers()) do
		local c = resolvePlayerCharacter(p)
		if c then
			local hl = c:FindFirstChild("HvH_Chams")
			if hl then pcall(function() hl:Destroy() end) end
			local nt = c:FindFirstChild("HvH_NameTag")
			if nt then pcall(function() nt:Destroy() end) end
		end
	end

	setCharacterCollision(true)
	setFreecam(false)
	pcall(function()
		Workspace.Gravity = 196.2
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)
	pcall(function()
		if Camera then
			Camera.CameraType = Enum.CameraType.Custom
			Camera.FieldOfView = 70
		end
	end)
	pcall(function()
		local char = LocalPlayer.Character
		if char then
			for _, inst in ipairs(char:GetDescendants()) do
				if inst:IsA("BasePart") then
					inst.LocalTransparencyModifier = 0
					inst.CanCollide = true
				end
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = false
				hum.Sit = false
				hum.WalkSpeed = 16
				hum.UseJumpPower = true
				hum.JumpPower = 50
			end
		end
	end)
	pcall(function()
		local existing = PlayerGui:FindFirstChild("AetherFunctionUI")
		if existing then existing:Destroy() end
	end)
end

local function quickResetMovement()
	cfg.BhopEnabled = false
	cfg.InfiniteJumpEnabled = false
	cfg.NoClipEnabled = false
	cfg.FreecamEnabled = false
	cfg.AutoSprint = false
	cfg.VerticalFreezeEnabled = false
	cfg.FlyEnabled = false
	cfg.GrappleEnabled = false
	cfg.WallRunEnabled = false
	cfg.CeilingWalkEnabled = false
	cfg.TelekinesisEnabled = false
	cfg.PhysicsTornadoEnabled = false
	cfg.SurfaceSurferEnabled = false
	cfg.TiltEnabled = false
	cfg.SlowModeEnabled = false
	cfg.SilentAim1Enabled = false
	cfg.SilentAim2Enabled = false
	cfg.BacklockEnabled = false
	if setProjectileRedirectEnabled then setProjectileRedirectEnabled(false) end
	cfg.SpiderEnabled = false
	cfg.PlayerStickEnabled = false
	cfg.SafeTeleportEnabled = true
	cfg.AutoUnstuckEnabled = true
	cfg.AdaptiveAimEnabled = true
	cfg.WeaponProfilesEnabled = true
	cfg.BananaDriftEnabled = false
	cfg.FakeLagPuppetEnabled = false
	cfg.MoonMagnetEnabled = false
	cfg.HeadHelicopterEnabled = false
	cfg.PanicStatueEnabled = false
	cfg.ReverseDayEnabled = false
	cfg.RubberBandDashEnabled = false
	cfg.FloorIsLavaEnabled = false
	cfg.RandomLeanEnabled = false
	cfg.ComedicRecoilEnabled = false
	cfg.MoveSpeed = 16
	cfg.JumpPowerValue = 50
	cfg.PlayerGravity = 196.2
	verticalFreezeY = nil
	Motion.cleanup()
	setCharacterCollision(true)
	setFreecam(false)
end

local function applyXrayPart(p: BasePart)
	if p:IsDescendantOf(LocalPlayer.Character or Instance.new("Folder")) then return end
	local plrChar = p:FindFirstAncestorOfClass("Model")
	if plrChar and Players:GetPlayerFromCharacter(plrChar) then return end
	xrayApplied[p] = true
	p.LocalTransparencyModifier = cfg.XrayEnabled and cfg.XrayTransparency or 0
end

local function refreshXray()
	for part, _ in pairs(xrayApplied) do
		if part and part.Parent then
			part.LocalTransparencyModifier = 0
		end
		xrayApplied[part] = nil
	end
	if not cfg.XrayEnabled then return end
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("BasePart") then
			applyXrayPart(inst)
		end
	end
end

local rfOriginalValues: {[Instance]: number|boolean} = {}
local rfPatched = false

local function updateSpeedFire2(enabled: boolean)
	local weapons = ReplicatedStorage:FindFirstChild("Weapons")
	if not weapons then return end

	if enabled then
		rfPatched = true
		for _, inst in ipairs(weapons:GetDescendants()) do
			if inst:IsA("BoolValue") and string.lower(inst.Name) == "auto" then
				if rfOriginalValues[inst] == nil then rfOriginalValues[inst] = inst.Value end
				pcall(function() (inst :: any).Value = true end)
			elseif (inst:IsA("NumberValue") or inst:IsA("IntValue")) and string.lower(inst.Name) == "firerate" then
				if rfOriginalValues[inst] == nil then rfOriginalValues[inst] = inst.Value end
				pcall(function() (inst :: any).Value = 0.02 end)
			end
		end
	else
		if not rfPatched then return end
		rfPatched = false
		for inst, old in pairs(rfOriginalValues) do
			if inst and inst.Parent then
				pcall(function() (inst :: any).Value = old end)
			end
			rfOriginalValues[inst] = nil
		end
	end
end

local function emulateMouse1Click()
	local ok = false
	pcall(function()
		if mouse1click then
			mouse1click()
			ok = true
			return
		end
		if mouse1press and mouse1release then
			-- no yield inside RenderStepped path (prevents micro-freezes)
			mouse1press()
			mouse1release()
			ok = true
			return
		end
		local vim = game:GetService("VirtualInputManager")
		if vim then
			local vp = Camera and Camera.ViewportSize or Vector2.new(960, 540)
			local x, y = vp.X * 0.5, vp.Y * 0.5
			vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
			vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
			ok = true
			return
		end
	end)
	return ok
end

local function rapidFireOnce()
	-- universal primary-fire pulse: prefer real Mouse1 emulation, fallback to Tool:Activate()
	if recordShotCandidate then recordShotCandidate() end
	if emulateMouse1Click() then return end
	local char = LocalPlayer.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end
	pcall(function() tool:Activate() end)
end

Workspace.DescendantAdded:Connect(function(inst)
	if cfg.XrayEnabled and inst:IsA("BasePart") then
		applyXrayPart(inst)
	end
end)

type VData = {
	hl: Highlight?,
	gui: BillboardGui?,
	hpConn1: RBXScriptConnection?,
	hpConn2: RBXScriptConnection?,
	hpFill: Frame?,
	hpText: TextLabel?,
}
local visualsByPlayer: {[Player]: VData} = {}
local dirtyVisualPlayers: {[Player]: boolean} = {}
local dirtyVisualCount = 0
local dirtyVisualStylePlayers: {[Player]: boolean} = {}
local dirtyVisualStyleCount = 0
local dirtyChamsColorPlayers: {[Player]: boolean} = {}
local dirtyChamsColorCount = 0
local lastVisualRefreshAt = 0
local visualAuditAcc = 0

-- forward declaration (used by helper functions below)
local getCharacterParts: (p: Player) -> (Model?, Humanoid?, BasePart?)

-- ================= Helpers =================
local function getTeamColor(p: Player): Color3
	if p.TeamColor then return p.TeamColor.Color end
	return Color3.fromRGB(255, 90, 90)
end

local function isTargetCandidate(p: Player, includeTeam: boolean): boolean
	if p == LocalPlayer then return false end
	if includeTeam then return true end
	if LocalPlayer.Team and p.Team then
		return LocalPlayer.Team ~= p.Team
	end
	return true
end

local function isVisualCandidate(p: Player): boolean
	return isTargetCandidate(p, cfg.VisualsAllPlayers)
end

local function playerRuleKey(p: Player): string
	return tostring(p.UserId)
end

local function getPlayerESPRule(p: Player)
	local rules = cfg.PlayerESPRules
	return type(rules) == "table" and rules[playerRuleKey(p)] or nil
end

local function playerVisualEnabled(p: Player, kind: string, fallback: boolean): boolean
	local rule = getPlayerESPRule(p)
	local value = type(rule) == "table" and rule[kind] or nil
	if value == nil then return fallback end
	return value == true
end

local function getPlayerPriority(p: Player): number
	local rules = cfg.PlayerPriorityRules
	local value = type(rules) == "table" and tonumber(rules[playerRuleKey(p)]) or nil
	return math.clamp(value or 50, 0, 100)
end

local function isWithinESPDistance(p: Player): boolean
	if not Camera then return false end
	local character = resolvePlayerCharacter(p)
	local hrp = resolveCharacterRoot(character)
	if not hrp then return false end
	return (hrp.Position - Camera.CFrame.Position).Magnitude <= cfg.ESPMaxDistance
end

function getCharacterParts(p: Player)
	local char = resolvePlayerCharacter(p)
	if not char then return nil, nil, nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = findCharacterPart(char, "HumanoidRootPart", p) or resolveCharacterRoot(char)
	if not hrp then return nil, nil, nil end
	if hum then
		if hum.Health <= 0 then return nil, nil, nil end
	elseif Phantom.enabled then
		local health = Phantom.getHealth(p)
		if health ~= nil and health <= 0 then return nil, nil, nil end
	else
		return nil, nil, nil
	end
	return char, hum, hrp
end

local function getPlayerHealth(p: Player, hum: Humanoid?): (number, number)
	if hum then return hum.Health, math.max(1, hum.MaxHealth) end
	local health, maxHealth = Phantom.getHealth(p)
	return health or 100, math.max(1, maxHealth or 100)
end

local function getAimOrigin2D(): Vector2
	if not Camera then return Vector2.new(0, 0) end
	local vp = Camera.ViewportSize
	return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

local function hasLOSAtPoint(targetPart: BasePart, targetPos: Vector3): boolean
	if not Camera then return false end
	if not LocalPlayer.Character then return false end

	local origin = Camera.CFrame.Position
	local direction = (targetPos - origin)
	local result = Workspace:Raycast(origin, direction, LOSParams)
	if not result then return true end
	if result.Instance == targetPart then return true end
	return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function screenDist2AtPos(pos: Vector3, center: Vector2): (number?, number?)
	if not Camera then return nil, nil end
	local s, onScreen = Camera:WorldToViewportPoint(pos)
	if not onScreen or s.Z <= 0 then return nil, nil end
	local dx = s.X - center.X
	local dy = s.Y - center.Y
	return (dx * dx + dy * dy), s.Z
end

local function getPartAimPoints(part: BasePart): {Vector3}
	local points = table.create(7)
	local center = part.Position
	points[1] = center
	if not cfg.AimMultiPointEnabled then
		return points
	end
	local scale = math.clamp(cfg.AimMultiPointScale or 0.42, 0.05, 0.95)
	local sx = part.Size.X * 0.5 * scale
	local sy = part.Size.Y * 0.5 * scale
	local sz = part.Size.Z * 0.5 * scale
	points[2] = center + (part.CFrame.RightVector * sx)
	points[3] = center - (part.CFrame.RightVector * sx)
	points[4] = center + (part.CFrame.UpVector * sy)
	points[5] = center - (part.CFrame.UpVector * sy)
	points[6] = center + (part.CFrame.LookVector * sz)
	points[7] = center - (part.CFrame.LookVector * sz)
	return points
end

local PENETRATION_MATERIAL_COST = {
	[Enum.Material.Glass] = 0.30,
	[Enum.Material.Plastic] = 0.65,
	[Enum.Material.Wood] = 0.85,
	[Enum.Material.WoodPlanks] = 0.95,
	[Enum.Material.Fabric] = 0.35,
	[Enum.Material.Metal] = 2.40,
	[Enum.Material.DiamondPlate] = 2.75,
	[Enum.Material.Concrete] = 2.10,
	[Enum.Material.Brick] = 1.80,
	[Enum.Material.Rock] = 2.60,
}

local function getPenetrationCost(targetPart: BasePart, targetPoint: Vector3): number
	if not Camera then return math.huge end
	local origin = Camera.CFrame.Position
	local direction = targetPoint - origin
	if direction.Magnitude <= 0.001 then return 0 end
	local result = Workspace:Raycast(origin, direction, LOSParams)
	if not result or result.Instance == targetPart or result.Instance:IsDescendantOf(targetPart.Parent) then return 0 end
	local obstacle = result.Instance
	if not obstacle:IsA("BasePart") then return 100 end
	local unit = direction.Unit
	local cf = obstacle.CFrame
	local projectedThickness =
		math.abs(unit:Dot(cf.RightVector)) * obstacle.Size.X
		+ math.abs(unit:Dot(cf.UpVector)) * obstacle.Size.Y
		+ math.abs(unit:Dot(cf.LookVector)) * obstacle.Size.Z
	local materialCost = PENETRATION_MATERIAL_COST[obstacle.Material] or 1.40
	local collisionCost = obstacle.CanCollide and 1 or 0.35
	return projectedThickness * materialCost * collisionCost
end

local function getBestPointOnPart(part: BasePart, center: Vector2, requireLos: boolean): (number?, number?, Vector3?, number?)
	local bestD2: number? = nil
	local bestZ: number? = nil
	local bestPoint: Vector3? = nil
	local bestPenetration = math.huge
	for _, pt in ipairs(getPartAimPoints(part)) do
		local d2, z = screenDist2AtPos(pt, center)
		if d2 and z then
			local visible = hasLOSAtPoint(part, pt)
			if (not requireLos) or visible then
				local penetration = visible and 0 or getPenetrationCost(part, pt)
				if penetration < bestPenetration or (penetration == bestPenetration and ((bestD2 == nil) or d2 < bestD2)) then
					bestD2 = d2
					bestZ = z
					bestPoint = pt
					bestPenetration = penetration
				end
			end
		end
	end
	return bestD2, bestZ, bestPoint, bestPenetration
end

local function getPrimaryHitbox(char: Model, hitboxName: string, player: Player?): BasePart?
	return findCharacterPart(char, hitboxName, player)
		or findCharacterPart(char, "HumanoidRootPart", player)
end

local function getBestVisiblePartByPriority(char: Model, center: Vector2, priorities: {[string]: number}, requireLos: boolean, player: Player?): BasePart?
	local best: BasePart? = nil
	local bestPriority = -1
	local bestDist2 = math.huge
	local bestPenetration = math.huge

	for _, partName in ipairs(HITBOX_LIST) do
		local p = findCharacterPart(char, partName, player)
		if p then
			local d2, _, _, penetration = getBestPointOnPart(p, center, requireLos)
			if d2 then
				local pr = priorities[partName] or 1
				local pen = penetration or math.huge
				if pr > bestPriority or (pr == bestPriority and (pen < bestPenetration or (pen == bestPenetration and d2 < bestDist2))) then
					bestPriority = pr
					bestDist2 = d2
					bestPenetration = pen
					best = p
				end
			end
		end
	end

	return best
end

-- ================= UI root + FOV =================
local previousUi = PlayerGui:FindFirstChild("AetherFunctionUI")
if previousUi then previousUi:Destroy() end

local ui = Instance.new("ScreenGui")
ui.Name = "AetherFunctionUI"
ui.ResetOnSpawn = false
ui.IgnoreGuiInset = true
ui.DisplayOrder = 999999
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Parent = PlayerGui

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5,0.5)
crosshair.Size = UDim2.fromOffset(1,1)
crosshair.BackgroundTransparency = 1
crosshair.Parent = ui

local function mkCrossArm(): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(220,230,255)
	f.BorderSizePixel = 0
	f.Parent = crosshair
	return f
end
local chTop, chBottom, chLeft, chRight = mkCrossArm(), mkCrossArm(), mkCrossArm(), mkCrossArm()
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 0.92
fovCircle.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
fovCircle.BorderSizePixel = 0
fovCircle.ZIndex = 2
fovCircle.Parent = ui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 2
fovStroke.Transparency = 0.1
fovStroke.Color = Color3.fromRGB(130, 210, 255)
fovStroke.Parent = fovCircle

if Camera then
	Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
		if cfg.CameraFOVOverride and math.abs(Camera.FieldOfView - cfg.CameraFOVValue) > 0.01 then
			Camera.FieldOfView = cfg.CameraFOVValue
		end
	end)
end

local function updateFOVCircle()
	local center = getAimOrigin2D()
	lastFOVViewportSize = Camera and Camera.ViewportSize or Vector2.zero
	local d = cfg.AimFOV * 2
	fovCircle.Size = UDim2.fromOffset(d, d)
	fovCircle.Position = UDim2.fromOffset(center.X, center.Y)
	fovCircle.Visible = cfg.ShowFOV and (cfg.AimEnabled or cfg.SilentAim1Enabled or cfg.SilentAim2Enabled)

	crosshair.Position = UDim2.fromOffset(center.X, center.Y)
	local s = math.max(2, cfg.CrosshairSize)
	local g = math.max(1, cfg.CrosshairGap)
	chTop.Size = UDim2.fromOffset(2, s)
	chTop.Position = UDim2.fromOffset(-1, -(g+s))
	chBottom.Size = UDim2.fromOffset(2, s)
	chBottom.Position = UDim2.fromOffset(-1, g)
	chLeft.Size = UDim2.fromOffset(s, 2)
	chLeft.Position = UDim2.fromOffset(-(g+s), -1)
	chRight.Size = UDim2.fromOffset(s, 2)
	chRight.Position = UDim2.fromOffset(g, -1)
	crosshair.Visible = cfg.CrosshairEnabled
end

local MODERN_THEME = {
	bg = Color3.fromRGB(10, 10, 10),
	panel = Color3.fromRGB(17, 17, 17),
	panel2 = Color3.fromRGB(12, 12, 12),
	panelSoft = Color3.fromRGB(31, 31, 31),
	line = Color3.fromRGB(50, 48, 52),
	lineSoft = Color3.fromRGB(61, 65, 76),
	text = Color3.fromRGB(235, 235, 235),
	textSoft = Color3.fromRGB(105, 105, 105),
	good = Color3.fromRGB(149, 192, 33),
}

local function colorFromHex(hex: any, fallback: Color3): Color3
	if typeof(hex) ~= "string" then return fallback end
	local clean = string.match(hex, "#?([%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F])")
	if not clean then return fallback end
	local r = tonumber(string.sub(clean, 1, 2), 16)
	local g = tonumber(string.sub(clean, 3, 4), 16)
	local b = tonumber(string.sub(clean, 5, 6), 16)
	if not r or not g or not b then return fallback end
	return Color3.fromRGB(r, g, b)
end

local function colorToHex(color: Color3): string
	return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

-- ================= Visuals =================
local function cleanupVisual(p: Player)
	local v = visualsByPlayer[p]
	if not v then return end
	if visualDynamicCursor == p then visualDynamicCursor = nil end
	if v.hpConn1 then v.hpConn1:Disconnect() end
	if v.hpConn2 then v.hpConn2:Disconnect() end
	if v.hl then v.hl:Destroy() end
	if v.gui then v.gui:Destroy() end
	visualsByPlayer[p] = nil
end

local function createVisual(p: Player, char: Model, hum: Humanoid?, hrp: BasePart)
	cleanupVisual(p)
	if not isVisualCandidate(p) then return end
	if not isWithinESPDistance(p) then return end

	local teamColor = getTeamColor(p)
	local chamsEnabled = playerVisualEnabled(p, "chams", cfg.ChamsEnabled)
	local nameTagsEnabled = playerVisualEnabled(p, "nametags", cfg.NameTagsEnabled)

	local hl: Highlight? = nil
	if chamsEnabled then
		hl = Instance.new("Highlight")
		hl.Name = "HvH_Chams"
		hl.Adornee = char
		hl.DepthMode = cfg.ChamsThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
		hl.FillTransparency = cfg.ChamsFillTransparency
		hl.OutlineTransparency = 0.05
		hl.FillColor = cfg.ChamsTeamColor and teamColor or colorFromHex(cfg.ChamsCustomColor, Color3.fromRGB(255, 80, 80))
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.Parent = char
	end

	local bill: BillboardGui? = nil
	local hpConn1: RBXScriptConnection? = nil
	local hpConn2: RBXScriptConnection? = nil
	local hpFillRef: Frame? = nil
	local hpTextRef: TextLabel? = nil

	if nameTagsEnabled then
		bill = Instance.new("BillboardGui")
		bill.Name = "HvH_NameTag"
		bill.Adornee = hrp
		bill.AlwaysOnTop = true
		local ntBaseScale = math.min(cfg.NameTagScale, cfg.NameTagMaxScale or 1.2)
		bill.Size = UDim2.fromOffset(math.floor(188 * ntBaseScale), math.floor(50 * ntBaseScale))
		bill.StudsOffset = Vector3.new(0, 3.2 + ((ntBaseScale - 1) * 0.8), 0)
		bill.MaxDistance = 1e9
		bill.LightInfluence = 0
		bill.Parent = char

		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.ClipsDescendants = true
		bg.BackgroundColor3 = MODERN_THEME.panel
		bg.BackgroundTransparency = 0.04
		bg.BorderSizePixel = 1
		bg.BorderColor3 = MODERN_THEME.lineSoft
		bg.Parent = bill
		local bgStroke = Instance.new("UIStroke")
		bgStroke.Thickness = 1
		bgStroke.Transparency = 0.35
		bgStroke.Color = MODERN_THEME.lineSoft
		bgStroke.Parent = bg

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -12, 0, 18)
		nameLabel.Position = UDim2.fromOffset(6, 3)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.ArialBold
		nameLabel.TextSize = math.floor(11 * ntBaseScale)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.TextWrapped = false
		nameLabel.Text = p.DisplayName .. " (@" .. p.Name .. ")"
		nameLabel.Name = "NameLabel"
		nameLabel.TextColor3 = cfg.NameTagTeamColor and teamColor or MODERN_THEME.text
		nameLabel.Parent = bg
		local ntNameConstraint = Instance.new("UITextSizeConstraint")
		ntNameConstraint.MinTextSize = 9
		ntNameConstraint.MaxTextSize = math.max(10, math.floor(11 * ntBaseScale))
		ntNameConstraint.Parent = nameLabel

		local hpBg = Instance.new("Frame")
		hpBg.Size = UDim2.new(1, -12, 0, math.max(9, math.floor(10 * ntBaseScale)))
		hpBg.Position = UDim2.fromOffset(6, math.floor(27 * ntBaseScale))
		hpBg.BackgroundColor3 = MODERN_THEME.panelSoft
		hpBg.BorderSizePixel = 0
		hpBg.Parent = bg

		local hpFill = Instance.new("Frame")
		hpFill.Size = UDim2.fromScale(1, 1)
		hpFill.BackgroundColor3 = MODERN_THEME.good
		hpFill.BorderSizePixel = 0
		hpFill.Parent = hpBg
		hpFillRef = hpFill

		local hpText = Instance.new("TextLabel")
		hpText.Size = UDim2.fromScale(1, 1)
		hpText.BackgroundTransparency = 1
		hpText.Font = Enum.Font.Arial
		hpText.TextSize = math.max(8, math.floor(9 * ntBaseScale))
		hpText.TextColor3 = MODERN_THEME.text
		hpText.TextStrokeTransparency = 0.7
		hpText.TextTruncate = Enum.TextTruncate.AtEnd
		hpText.Parent = hpBg
		hpTextRef = hpText
		local ntHpConstraint = Instance.new("UITextSizeConstraint")
		ntHpConstraint.MinTextSize = 8
		ntHpConstraint.MaxTextSize = math.max(9, math.floor(10 * ntBaseScale))
		ntHpConstraint.Parent = hpText

		local function updHP()
			local current, maxH = getPlayerHealth(p, hum)
			local ratio = math.clamp(current / maxH, 0, 1)
			hpFill.Size = UDim2.fromScale(ratio, 1)
			hpText.Text = string.format("%d / %d", math.floor(current + 0.5), math.floor(maxH + 0.5))
			if ratio > 0.6 then
				hpFill.BackgroundColor3 = MODERN_THEME.good
			elseif ratio > 0.3 then
				hpFill.BackgroundColor3 = Color3.fromRGB(254, 211, 48)
			else
				hpFill.BackgroundColor3 = Color3.fromRGB(245, 96, 114)
			end
		end
		updHP()
		if hum then
			hpConn1 = hum.HealthChanged:Connect(updHP)
			hpConn2 = hum:GetPropertyChangedSignal("MaxHealth"):Connect(updHP)
		end
	end

	visualsByPlayer[p] = {
		hl = hl,
		gui = bill,
		hpConn1 = hpConn1,
		hpConn2 = hpConn2,
		hpFill = hpFillRef,
		hpText = hpTextRef,
	}
end

local function applyVisualStyle(p: Player): boolean
	local data = visualsByPlayer[p]
	if not data then return false end
	local teamColor = getTeamColor(p)
	local needsChams = playerVisualEnabled(p, "chams", cfg.ChamsEnabled)
	local needsNameTag = playerVisualEnabled(p, "nametags", cfg.NameTagsEnabled)
	local needsRebuild = false

	if data.hl and data.hl.Parent then
		if not needsChams then
			data.hl:Destroy()
			data.hl = nil
		else
			data.hl.DepthMode = cfg.ChamsThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
			data.hl.FillTransparency = cfg.ChamsFillTransparency
			data.hl.FillColor = cfg.ChamsTeamColor and teamColor or colorFromHex(cfg.ChamsCustomColor, Color3.fromRGB(255, 80, 80))
		end
	elseif needsChams then
		needsRebuild = true
	end

	if data.gui and data.gui.Parent then
		if not needsNameTag then
			data.gui:Destroy()
			data.gui = nil
			if data.hpConn1 then data.hpConn1:Disconnect(); data.hpConn1 = nil end
			if data.hpConn2 then data.hpConn2:Disconnect(); data.hpConn2 = nil end
		else
			local baseScale = math.min(cfg.NameTagScale, cfg.NameTagMaxScale or 1.2)
			data.gui.Size = UDim2.fromOffset(math.floor(188 * baseScale), math.floor(50 * baseScale))
			data.gui.StudsOffset = Vector3.new(0, 3.2 + ((baseScale - 1) * 0.8), 0)
			local frame = data.gui:FindFirstChildOfClass("Frame")
			local label = frame and frame:FindFirstChild("NameLabel")
			if label and label:IsA("TextLabel") then
				label.TextColor3 = cfg.NameTagTeamColor and teamColor or MODERN_THEME.text
			end
		end
	elseif needsNameTag then
		needsRebuild = true
	end
	return needsRebuild
end

local function refreshOnePlayer(p: Player)
	local char, hum, hrp = getCharacterParts(p)
	if not char or not hum or not hrp then
		cleanupVisual(p)
		return
	end
	createVisual(p, char, hum, hrp)
end

local markVisualDirty: (Player) -> ()

local function applyVisualSettings()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not dirtyVisualStylePlayers[player] then
			dirtyVisualStylePlayers[player] = true
			dirtyVisualStyleCount += 1
		end
	end
end

local function processVisualStyleQueue()
	if dirtyVisualStyleCount <= 0 then return end
	local budget = cfg.LowEndMode and 1 or 2
	for player in pairs(dirtyVisualStylePlayers) do
		local eligible = isVisualCandidate(player) and isWithinESPDistance(player)
		local data = visualsByPlayer[player]
		if not eligible then
			if data then cleanupVisual(player) end
		elseif not data or applyVisualStyle(player) then
			markVisualDirty(player)
		end
		dirtyVisualStylePlayers[player] = nil
		dirtyVisualStyleCount = math.max(0, dirtyVisualStyleCount - 1)
		budget -= 1
		if budget <= 0 then break end
	end
end

local function updateChamsColorOnly()
	for player, data in pairs(visualsByPlayer) do
		if data.hl and data.hl.Parent and not dirtyChamsColorPlayers[player] then
			dirtyChamsColorPlayers[player] = true
			dirtyChamsColorCount += 1
		end
	end
end

local function processChamsColorQueue()
	if dirtyChamsColorCount <= 0 then return end
	local customColor = colorFromHex(cfg.ChamsCustomColor, Color3.fromRGB(255, 80, 80))
	local budget = cfg.LowEndMode and 1 or 3
	for player in pairs(dirtyChamsColorPlayers) do
		local data = visualsByPlayer[player]
		if data and data.hl and data.hl.Parent then
			data.hl.FillColor = cfg.ChamsTeamColor and getTeamColor(player) or customColor
			data.hl.FillTransparency = cfg.ChamsFillTransparency
		end
		dirtyChamsColorPlayers[player] = nil
		dirtyChamsColorCount = math.max(0, dirtyChamsColorCount - 1)
		budget -= 1
		if budget <= 0 then break end
	end
end

markVisualDirty = function(p: Player)
	if isUnloaded then return end
	if p ~= LocalPlayer and not dirtyVisualPlayers[p] then
		dirtyVisualPlayers[p] = true
		dirtyVisualCount += 1
	end
end

local function processDirtyVisualQueue(force: boolean?)
	if isUnloaded then return end
	local t = os.clock()
	if (not force) and (t - lastVisualRefreshAt < 0.15) then return end
	if (not force) and dirtyVisualCount <= 0 then return end
	lastVisualRefreshAt = t

	if force then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then refreshOnePlayer(p) end
		end
		table.clear(dirtyVisualPlayers)
		dirtyVisualCount = 0
		table.clear(dirtyVisualStylePlayers)
		dirtyVisualStyleCount = 0
		table.clear(dirtyChamsColorPlayers)
		dirtyChamsColorCount = 0
		return
	end

	local budget = cfg.LowEndMode and 1 or 2
	for p, _ in pairs(dirtyVisualPlayers) do
		refreshOnePlayer(p)
		dirtyVisualPlayers[p] = nil
		dirtyVisualCount -= 1
		budget -= 1
		if budget <= 0 then break end
	end
	if dirtyVisualCount < 0 then dirtyVisualCount = 0 end
end

local playerDeathConnections: {[Player]: RBXScriptConnection} = {}

local function clearDirtyPlayer(p: Player)
	if dirtyVisualPlayers[p] then
		dirtyVisualPlayers[p] = nil
		dirtyVisualCount = math.max(0, dirtyVisualCount - 1)
	end
	if dirtyVisualStylePlayers[p] then
		dirtyVisualStylePlayers[p] = nil
		dirtyVisualStyleCount = math.max(0, dirtyVisualStyleCount - 1)
	end
	if dirtyChamsColorPlayers[p] then
		dirtyChamsColorPlayers[p] = nil
		dirtyChamsColorCount = math.max(0, dirtyChamsColorCount - 1)
	end
end

local function detachPlayerDeath(p: Player)
	local connection = playerDeathConnections[p]
	if connection then connection:Disconnect(); playerDeathConnections[p] = nil end
end

local function invalidatePlayerRuntime(p: Player, character: Model?)
	threatCache[p] = nil
	if stickyTargetPlayer == p then
		stickyTargetPlayer = nil
		stickyTargetPart = nil
		stickyTargetUntil = 0
	end
	for humanoid, shot in pairs(pendingShots) do
		if shot.player == p or (character and humanoid:IsDescendantOf(character)) then
			pendingShots[humanoid] = nil
		end
	end
	if character then
		for part, data in pairs(silent2Cache) do
			if part:IsDescendantOf(character) then
				if part.Parent then
					part.Size = data.size
					part.Transparency = data.tr
					part.CanCollide = data.cc
				end
				silent2Cache[part] = nil
			end
		end
	end
end

local function onTrackedCharacterAdded(p: Player, char: Model)
	if p == LocalPlayer or isUnloaded then return end
	invalidatePlayerRuntime(p, characterModelCache[p])
	if characterModelCache[p] == char then
		local data = visualsByPlayer[p]
		if data and ((data.hl and data.hl.Parent) or (data.gui and data.gui.Parent)) then return end
	end
	characterModelCache[p] = char
	detachPlayerDeath(p)
	task.spawn(function()
		for _ = 1, 24 do
			if isUnloaded or not char.Parent then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			local root = findCharacterPart(char, "HumanoidRootPart", p) or resolveCharacterRoot(char)
			local health = getPlayerHealth(p, hum)
			if root and health > 0 then
				if hum then
					playerDeathConnections[p] = hum.Died:Connect(function()
						cleanupVisual(p)
						clearDirtyPlayer(p)
					end)
				end
				refreshOnePlayer(p)
				return
			end
			task.wait(0.10)
		end
		markVisualDirty(p)
	end)
end

local function onTrackedCharacterRemoving(p: Player, char: Model?)
	if p == LocalPlayer then return end
	if char and characterModelCache[p] and characterModelCache[p] ~= char then return end
	invalidatePlayerRuntime(p, char or characterModelCache[p])
	characterModelCache[p] = nil
	detachPlayerDeath(p)
	cleanupVisual(p)
	clearDirtyPlayer(p)
end

local function trackPlayer(p: Player)
	if p == LocalPlayer then return end
	local character = resolvePlayerCharacter(p)
	if character then
		onTrackedCharacterAdded(p, character)
	else
		markVisualDirty(p)
	end
end

local function untrackPlayer(p: Player)
	invalidatePlayerRuntime(p, characterModelCache[p])
	characterModelCache[p] = nil
	detachPlayerDeath(p)
	cleanupVisual(p)
	clearDirtyPlayer(p)
end

local function findPlayerForModel(model: Instance): Player?
	local character = model:IsA("Model") and model or model:FindFirstAncestorOfClass("Model")
	if not character then return nil end
	for player, cached in pairs(characterModelCache) do
		if cached == character then return player end
	end
	local direct = Players:GetPlayerFromCharacter(character)
	if direct then return direct end
	local userId = tonumber(character:GetAttribute("UserId") or character:GetAttribute("PlayerUserId"))
	for _, key in ipairs({"Player", "Owner", "CharacterOwner", "PlayerOwner"}) do
		local marker = character:FindFirstChild(key)
		if marker and marker:IsA("ObjectValue") and marker.Value and marker.Value:IsA("Player") then
			return marker.Value
		end
		if marker and marker:IsA("IntValue") then userId = marker.Value end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if (userId and player.UserId == userId)
			or character.Name == player.Name
			or character.Name == tostring(player.UserId)
			or character.Name == player.DisplayName
		then
			return player
		end
	end
	return nil
end

local function onLocalCharacterReset()
	refreshLOSFilter()
	lastHideLocalApplied = nil
	verticalFreezeY = nil
	processDirtyVisualQueue(true)
	if cfg.NoClipEnabled or cfg.FlyEnabled then
		task.defer(function()
			setCharacterCollision(false)
		end)
	end
end

for _, p in ipairs(Players:GetPlayers()) do trackPlayer(p) end

-- ================= Menu API bridge =================
local menuApi: any = nil
local getBestTargetPart: any

local PROJECTILE_NAME_HINTS = {
	"bullet", "projectile", "rocket", "missile", "grenade", "arrow", "shell", "orb", "fireball", "snowball",
}

local function isProjectilePart(instance: Instance): boolean
	if not instance:IsA("BasePart") then return false end
	local localCharacter = LocalPlayer.Character
	if localCharacter and instance:IsDescendantOf(localCharacter) then return false end
	local model = instance:FindFirstAncestorOfClass("Model")
	if model and (Players:GetPlayerFromCharacter(model) or model:FindFirstChildOfClass("Humanoid")) then return false end
	local lowered = string.lower(instance.Name)
	if model then lowered = lowered .. " " .. string.lower(model.Name) end
	for _, hint in ipairs(PROJECTILE_NAME_HINTS) do
		if string.find(lowered, hint, 1, true) then return true end
	end
	return instance.AssemblyLinearVelocity.Magnitude >= 45 and instance.Size.Magnitude <= 12
end

local function trackProjectile(instance: Instance)
	if isProjectilePart(instance) then projectileCandidates[instance] = true end
end

local projectileRedirectElapsed = 0
local function updateProjectileRedirect(dt: number)
	projectileRedirectElapsed += dt
	if projectileRedirectElapsed < 0.03 then return end
	projectileRedirectElapsed = 0
	if not cfg.ProjectileRedirectEnabled or not getBestTargetPart then return end
	local localRoot = resolveCharacterRoot(LocalPlayer.Character)
	if not localRoot then return end
	local target = getBestTargetPart(
		cfg.AimAllPlayers,
		cfg.AimMaxDistance,
		cfg.AimFOV,
		false,
		true,
		cfg.AimHitbox,
		AimHitboxPriority
	)
	if not target then return end
	for part in pairs(projectileCandidates) do
		if not part.Parent then
			projectileCandidates[part] = nil
		elseif (part.Position - localRoot.Position).Magnitude <= cfg.ProjectileRedirectRadius then
			local delta = target.Position - part.Position
			if delta.Magnitude > 0.01 then
				local speed = math.max(part.AssemblyLinearVelocity.Magnitude, cfg.ProjectileRedirectStrength)
				pcall(function()
					part.AssemblyLinearVelocity = delta.Unit * speed
					part.CFrame = CFrame.lookAt(part.Position, target.Position)
				end)
			end
		end
	end
end

setProjectileRedirectEnabled = function(enabled: boolean)
	cfg.ProjectileRedirectEnabled = enabled == true
	if not menuApi or not menuApi.Events then return end
	if cfg.ProjectileRedirectEnabled then
		if not projectileAddedSubscription then
			projectileAddedSubscription = menuApi.Events:On("WorkspaceDescendantAdded", trackProjectile)
			projectileRemovedSubscription = menuApi.Events:On("WorkspaceDescendantRemoving", function(instance)
				projectileCandidates[instance] = nil
			end)
			projectileHeartbeatSubscription = menuApi.Events:On("Heartbeat", updateProjectileRedirect)
			task.spawn(function()
				local scanned = 0
				for _, instance in ipairs(Workspace:GetDescendants()) do
					if not cfg.ProjectileRedirectEnabled then return end
					trackProjectile(instance)
					scanned += 1
					if scanned % 300 == 0 then task.wait() end
				end
			end)
		end
	else
		for _, subscription in ipairs({projectileAddedSubscription, projectileRemovedSubscription, projectileHeartbeatSubscription}) do
			if subscription then subscription:Disconnect() end
		end
		projectileAddedSubscription = nil
		projectileRemovedSubscription = nil
		projectileHeartbeatSubscription = nil
		projectileRedirectElapsed = 0
		table.clear(projectileCandidates)
	end
end

function notify(msg)
	warn("[AETHER] " .. tostring(msg))
end

local function valueTargetsLocal(value: any): boolean
	local localCharacter = LocalPlayer.Character
	if typeof(value) == "Instance" then
		return value == LocalPlayer
			or value == localCharacter
			or (localCharacter ~= nil and value:IsDescendantOf(localCharacter))
	end
	local text = string.lower(tostring(value or ""))
	return text ~= "" and (
		text == string.lower(LocalPlayer.Name)
		or text == string.lower(LocalPlayer.DisplayName)
		or text == tostring(LocalPlayer.UserId)
	)
end

local function isConfirmedSpectator(player: Player): boolean
	if player == LocalPlayer then return false end
	for _, key in ipairs({"Spectating", "SpectateTarget", "SpectatingPlayer", "CameraTarget", "ViewTarget"}) do
		if valueTargetsLocal(player:GetAttribute(key)) then return true end
	end
	for _, object in ipairs(player:GetDescendants()) do
		local name = string.lower(object.Name)
		if string.find(name, "spectat", 1, true) or string.find(name, "camera", 1, true) or string.find(name, "target", 1, true) then
			if object:IsA("ObjectValue") and valueTargetsLocal(object.Value) then return true end
			if object:IsA("StringValue") and valueTargetsLocal(object.Value) then return true end
			if object:IsA("IntValue") and object.Value == LocalPlayer.UserId then return true end
		end
	end
	return false
end

local function getSpectatorLabels(): {string}
	local labels = {}
	if not cfg.SpectatorDetectionEnabled then return labels end
	for _, player in ipairs(Players:GetPlayers()) do
		if isConfirmedSpectator(player) then
			table.insert(labels, string.format("%s (@%s)", player.DisplayName, player.Name))
		end
	end
	table.sort(labels, function(a, b) return string.lower(a) < string.lower(b) end)
	return labels
end

local function playHitSound()
	if not cfg.HitSoundEnabled then return end
	local sound = Instance.new("Sound")
	sound.Volume = 0.55
	if cfg.HitSoundType == "Click" then
		sound.SoundId = "rbxasset://sounds/button.wav"
	elseif cfg.HitSoundType == "Bubble" then
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	elseif cfg.HitSoundType == "Custom" and cfg.HitSoundCustomPath ~= "" then
		sound.SoundId = "file://" .. cfg.HitSoundCustomPath
	else
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.PlaybackSpeed = 0.88
	end
	sound.Parent = SoundService
	pcall(function() sound:Play() end)
	task.delay(1.2, function() sound:Destroy() end)
end

local function getCurrentAimTargetPart(): BasePart?
	if not Camera then return nil end
	return getBestTargetPart(
		cfg.AimAllPlayers,
		cfg.AimMaxDistance,
		cfg.AimFOV,
		cfg.AimRequireLOS,
		cfg.AimUseNearestVisibleHitbox,
		cfg.AimHitbox,
		AimHitboxPriority
	)
end

recordShotCandidate = function()
	local part = getCurrentAimTargetPart()
	if not part then return end
	local character = part:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local player = findPlayerForModel(character)
	local existing = pendingShots[humanoid]
	local now = os.clock()
	if existing and existing.expires - now > 0.40 then return end
	pendingShots[humanoid] = {
		health = humanoid.Health,
		expires = now + 0.55,
		part = part,
		player = player,
	}
	if menuApi and menuApi.Events then
		menuApi.Events:Emit("ShotAttempted", player, part, humanoid.Health)
	end
end

local function processShotConfirmations()
	local now = os.clock()
	for humanoid, shot in pairs(pendingShots) do
		if not humanoid.Parent or now > shot.expires then
			pendingShots[humanoid] = nil
		elseif humanoid.Health < shot.health then
			local damage = shot.health - humanoid.Health
			pendingShots[humanoid] = nil
			playHitSound()
			if menuApi and menuApi.Events then
				menuApi.Events:Emit("ShotConfirmed", shot.player, shot.part, damage, humanoid.Health)
			end
			if cfg.MemeModeEnabled then
				notify(({"bonk!", "sheesh!", "clean tap", "snail tech"})[math.random(1, 4)])
			end
		end
	end
end

function refreshHitboxUI()
	if menuApi then menuApi:RefreshAll() end
end

function setMenuVisible(v: boolean)
	cfg.MenuVisible = v
	if menuApi then menuApi:SetVisible(v) end
end

refreshCustomSoundFiles()

-- ================= Aim/Misc =================
local function calculateThreatScore(player: Player, maxDistance: number): number
	local now = os.clock()
	local cached = threatCache[player]
	if cached and cached.expires > now and cached.maxDistance == maxDistance then return cached.score end
	local character, humanoid, root = getCharacterParts(player)
	local localCharacter = LocalPlayer.Character
	local localRoot = resolveCharacterRoot(localCharacter)
	if not character or not root or not localRoot then return getPlayerPriority(player) end
	local delta = localRoot.Position - root.Position
	local distance = delta.Magnitude
	local direction = distance > 0.001 and delta.Unit or root.CFrame.LookVector
	local facing = math.max(0, root.CFrame.LookVector:Dot(direction))
	local distancePressure = 1 - math.clamp(distance / math.max(1, maxDistance), 0, 1)
	local weaponPressure = character:FindFirstChildOfClass("Tool") and 12 or 0
	local visibilityPressure = hasLOSAtPoint(root, root.Position) and 16 or 0
	local health, maxHealth = getPlayerHealth(player, humanoid)
	local healthPressure = math.clamp(health / maxHealth, 0, 1) * 6
	local score = getPlayerPriority(player) * 1.20
		+ facing * 34
		+ distancePressure * 28
		+ weaponPressure
		+ visibilityPressure
		+ healthPressure
	threatCache[player] = {score = score, expires = now + 0.08, maxDistance = maxDistance}
	return score
end

local function getStickyCandidate(includeTeam: boolean, maxDist: number, fovPx: number, requireLos: boolean, useNearest: boolean, fixedHitbox: string, priorities: {[string]: number}): BasePart?
	local player = stickyTargetPlayer
	if not player or not isTargetCandidate(player, includeTeam) or not Camera then return nil end
	local character = resolvePlayerCharacter(player)
	if not character then return nil end
	local candidate = stickyTargetPart
	if not candidate or not candidate.Parent or not candidate:IsDescendantOf(character) then
		candidate = useNearest and getBestVisiblePartByPriority(character, getAimOrigin2D(), priorities, requireLos, player)
			or getPrimaryHitbox(character, fixedHitbox, player)
	end
	if not candidate then return nil end
	local center = getAimOrigin2D()
	local expandedFov = fovPx * STICKY_FOV_MULTIPLIER
	local d2 = getBestPointOnPart(candidate, center, requireLos)
	local worldDistance = (candidate.Position - Camera.CFrame.Position).Magnitude
	if d2 and d2 <= expandedFov * expandedFov and worldDistance <= maxDist then
		stickyTargetPart = candidate
		stickyTargetUntil = os.clock() + STICKY_TARGET_GRACE
		return candidate
	end
	if os.clock() <= stickyTargetUntil and candidate.Parent and worldDistance <= maxDist then
		local graceD2 = getBestPointOnPart(candidate, center, false)
		if graceD2 and graceD2 <= expandedFov * expandedFov then return candidate end
	end
	return nil
end

getBestTargetPart = function(includeTeam: boolean, maxDist: number, fovPx: number, requireLos: boolean, useNearest: boolean, fixedHitbox: string, priorities: {[string]: number}): BasePart?
	if not Camera then return nil end
	local sticky = getStickyCandidate(includeTeam, maxDist, fovPx, requireLos, useNearest, fixedHitbox, priorities)
	if sticky then return sticky end
	stickyTargetPlayer = nil
	stickyTargetPart = nil
	stickyTargetUntil = 0
	local center = getAimOrigin2D()
	local fov2 = fovPx * fovPx

	local bestPart: BasePart? = nil
	local bestPlayer: Player? = nil
	local bestDist2 = math.huge
	local bestPriority = -1
	local bestThreat = -math.huge

	for _, p in ipairs(Players:GetPlayers()) do
		if isTargetCandidate(p, includeTeam) then
			local char, _, _ = getCharacterParts(p)
			if char then
				local candidatePart: BasePart? = nil

				if useNearest then
					candidatePart = getBestVisiblePartByPriority(char, center, priorities, requireLos, p)
				else
					candidatePart = getPrimaryHitbox(char, fixedHitbox, p)
				end

				if candidatePart then
					local d2, _, bestPoint = getBestPointOnPart(candidatePart, center, requireLos)
					if d2 and d2 <= fov2 then
						local worldAnchor = bestPoint or candidatePart.Position
						local worldDist = (worldAnchor - Camera.CFrame.Position).Magnitude
						if worldDist <= maxDist then
							local pr = useNearest and (priorities[candidatePart.Name] or 1) or 1
							local threat = calculateThreatScore(p, maxDist)
							if threat > bestThreat + 0.01
								or (math.abs(threat - bestThreat) <= 0.01 and (pr > bestPriority or (pr == bestPriority and d2 < bestDist2)))
							then
								bestThreat = threat
								bestPriority = pr
								bestDist2 = d2
								bestPart = candidatePart
								bestPlayer = p
							end
						end
					end
				end
			end
		end
	end
	if bestPart and bestPlayer then
		stickyTargetPlayer = bestPlayer
		stickyTargetPart = bestPart
		stickyTargetUntil = os.clock() + STICKY_TARGET_GRACE
	end
	return bestPart
end

local silent2Acc = 0

function getSilentAimPart(forceRequireLos: boolean?): BasePart?
	local requireLos = (forceRequireLos == nil) and cfg.AimRequireLOS or forceRequireLos
	return getBestTargetPart(
		cfg.AimAllPlayers,
		cfg.AimMaxDistance,
		cfg.AimFOV,
		requireLos,
		cfg.AimUseNearestVisibleHitbox,
		cfg.AimHitbox,
		AimHitboxPriority
	)
end

local function getAimPointForPart(part: BasePart): Vector3
	local center = getAimOrigin2D()
	local _, _, point = getBestPointOnPart(part, center, cfg.AimRequireLOS)
	return point or part.Position
end

local function getPredictedAimPoint(part: BasePart, rawPoint: Vector3): Vector3
	if not cfg.AimPredictionEnabled then return rawPoint end
	local predictionTime = math.clamp(cfg.AimPredictionTime or 0, 0, 0.5)
	if predictionTime <= 0 then return rawPoint end
	local velocity = part.AssemblyLinearVelocity
	local lead = velocity * predictionTime
	if lead.Magnitude > 35 then
		lead = lead.Unit * 35
	end
	return rawPoint + lead
end

local function getSmoothedAimPoint(part: BasePart, targetPoint: Vector3, dt: number): Vector3
	if aimFilteredPart ~= part or not aimFilteredPoint then
		aimFilteredPart = part
		aimFilteredPoint = targetPoint
		return targetPoint
	end
	local smoothness = math.clamp(cfg.AimTrackingSmoothness or 0, 0, 100)
	local response = 30 - smoothness * 0.26
	local alpha = 1 - math.exp(-response * math.max(dt, 0))
	aimFilteredPoint = aimFilteredPoint:Lerp(targetPoint, math.clamp(alpha, 0, 1))
	return aimFilteredPoint
end

function doSilentAim1Shot()
	if not cfg.SilentAim1Enabled or cfg.MenuVisible or cfg.FreecamEnabled then return end
	local part = getSilentAimPart()
	if part then
		silent1PrelockPart = part
		silent1PrelockUntil = os.clock() + 0.35
	end
end

local function calculateDirection(origin: Vector3, destination: Vector3, length: number?): Vector3
	local len = length or 1000
	local delta = destination - origin
	if delta.Magnitude <= 0.0001 then
		return Vector3.new(0, 0, -1) * len
	end
	return delta.Unit * len
end

local function silentAim1Active(): boolean
	return cfg.SilentAim1Enabled and (not cfg.MenuVisible) and (not cfg.FreecamEnabled)
end

function getSilentHookPart(): BasePart?
	if silent1PrelockPart and silent1PrelockPart.Parent and os.clock() <= silent1PrelockUntil then
		return silent1PrelockPart
	end
	return getSilentAimPart()
end

pcall(function()
	if hookmetamethod and getnamecallmethod and checkcaller then
		local __namecall
		__namecall = hookmetamethod(game, "__namecall", function(...)
			local args = {...}
			if checkcaller() then
				return __namecall(...)
			end

			if not silentAim1Active() then
				return __namecall(...)
			end

			local self = args[1]
			if self ~= Workspace then
				return __namecall(...)
			end

			local method = getnamecallmethod()
			local part = getSilentHookPart()
			if not part then
				return __namecall(...)
			end

			if method == "Raycast" and typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3" then
				args[3] = calculateDirection(args[2], getAimPointForPart(part), math.max(1, args[3].Magnitude))
				return __namecall(unpack(args))
			elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and typeof(args[2]) == "Ray" then
				local origin = args[2].Origin
				args[2] = Ray.new(origin, calculateDirection(origin, getAimPointForPart(part), math.max(1, args[2].Direction.Magnitude)))
				return __namecall(unpack(args))
			end

			return __namecall(...)
		end)
		Motion.silentNamecallHook = true
	end
end)

pcall(function()
	if hookmetamethod and checkcaller then
		local __index
		__index = hookmetamethod(game, "__index", function(t, k)
			if checkcaller() then
				return __index(t, k)
			end

			if not silentAim1Active() then
				return __index(t, k)
			end

			if typeof(t) == "Instance" and t:IsA("Mouse") then
				local part = getSilentHookPart()
				if part then
					if k == "Target" then
						return part
					elseif k == "Hit" then
						local pt = getAimPointForPart(part)
						return CFrame.new(pt)
					elseif k == "UnitRay" then
						local ur = __index(t, k)
						local origin = ur.Origin
						return Ray.new(origin, calculateDirection(origin, getAimPointForPart(part), 1000))
					end
				end
			end

			return __index(t, k)
		end)
		Motion.silentIndexHook = true
	end
end)

pcall(function()
	if hookfunction and checkcaller and Workspace.Raycast then
		local oldRaycast
		oldRaycast = hookfunction(Workspace.Raycast, function(self, origin, direction, params)
			if (not checkcaller()) and silentAim1Active() and typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local part = getSilentHookPart()
				if part then
					direction = calculateDirection(origin, getAimPointForPart(part), math.max(1, direction.Magnitude))
				end
			end
			return oldRaycast(self, origin, direction, params)
		end)
		Motion.silentDirectRayHook = true
	end
end)

function updateSilent2Hitboxes(dt)
	silent2Acc += dt
	if silent2Acc < 0.2 then return end
	silent2Acc = 0

	if cfg.SilentAim2Enabled then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local c = resolvePlayerCharacter(p)
				if c then
					for _, name in ipairs({"HumanoidRootPart","Head","UpperTorso","LowerTorso","RightUpperLeg","LeftUpperLeg"}) do
						local part = findCharacterPart(c, name, p)
						if part then
							if not silent2Cache[part] then
								silent2Cache[part] = {part = part, size = part.Size, tr = part.Transparency, cc = part.CanCollide}
							end
							part.Size = Vector3.new(13,13,13)
							part.Transparency = 1
							part.CanCollide = false
						end
					end
				end
			end
		end
	else
		for k, data in pairs(silent2Cache) do
			local part = data.part
			if part and part.Parent then
				part.Size = data.size
				part.Transparency = data.tr
				part.CanCollide = data.cc
			end
			silent2Cache[k] = nil
		end
	end
end

function Motion.getLocalState(): (Model?, Humanoid?, BasePart?)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and resolveCharacterRoot(character)
	return character, humanoid, root
end

function Motion.raycast(origin: Vector3, direction: Vector3): RaycastResult?
	local character = LocalPlayer.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and {character} or {}
	params.IgnoreWater = true
	return Workspace:Raycast(origin, direction, params)
end

function Motion.stopGrapple()
	Motion.grappleHeld = false
	Motion.grapplePoint = nil
	for _, object in ipairs({Motion.grappleBeam, Motion.grappleRootAttachment, Motion.grappleAnchor}) do
		if typeof(object) == "Instance" then pcall(function() object:Destroy() end) end
	end
	Motion.grappleBeam = nil
	Motion.grappleRootAttachment = nil
	Motion.grappleAnchor = nil
end

function Motion.startGrapple()
	if not cfg.GrappleEnabled or not Camera or cfg.MenuVisible then return end
	local _, _, root = Motion.getLocalState()
	if not root then return end
	local viewport = Camera.ViewportSize
	local ray = Camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local hit = Motion.raycast(ray.Origin, ray.Direction * cfg.GrappleRange)
	if not hit then return end
	Motion.stopGrapple()
	Motion.grappleHeld = true
	Motion.grapplePoint = hit.Position

	local anchor = Instance.new("Part")
	anchor.Name = "AetherGrappleAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CFrame = CFrame.new(hit.Position)
	anchor.Parent = Workspace
	local anchorAttachment = Instance.new("Attachment")
	anchorAttachment.Parent = anchor
	local rootAttachment = Instance.new("Attachment")
	rootAttachment.Name = "AetherGrappleAttachment"
	rootAttachment.Parent = root
	local beam = Instance.new("Beam")
	beam.Attachment0 = rootAttachment
	beam.Attachment1 = anchorAttachment
	beam.Width0 = 0.08
	beam.Width1 = 0.04
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(Color3.fromRGB(120, 210, 255), Color3.fromRGB(235, 245, 255))
	beam.Parent = rootAttachment
	Motion.grappleAnchor = anchor
	Motion.grappleRootAttachment = rootAttachment
	Motion.grappleBeam = beam
end

function Motion.stopCeilingWalk()
	Motion.ceilingActive = false
	local _, humanoid = Motion.getLocalState()
	if humanoid then humanoid.AutoRotate = true end
	for _, object in ipairs({Motion.ceilingForce, Motion.ceilingOrientation, Motion.ceilingAttachment}) do
		if typeof(object) == "Instance" then pcall(function() object:Destroy() end) end
	end
	Motion.ceilingForce = nil
	Motion.ceilingOrientation = nil
	Motion.ceilingAttachment = nil
end

function Motion.toggleCeilingWalk()
	if not cfg.CeilingWalkEnabled or not Camera or cfg.MenuVisible then
		Motion.stopCeilingWalk()
		return
	end
	if Motion.ceilingActive then
		Motion.stopCeilingWalk()
		return
	end
	local _, humanoid, root = Motion.getLocalState()
	if not humanoid or not root then return end
	local viewport = Camera.ViewportSize
	local ray = Camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local hit = Motion.raycast(ray.Origin, ray.Direction * 35)
	if not hit then return end
	Motion.ceilingActive = true
	Motion.ceilingNormal = hit.Normal
	humanoid.AutoRotate = false
	local attachment = Instance.new("Attachment")
	attachment.Name = "AetherSurfaceAttachment"
	attachment.Parent = root
	local force = Instance.new("VectorForce")
	force.Name = "AetherSurfaceGravity"
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	force.Parent = root
	local orientation = Instance.new("AlignOrientation")
	orientation.Name = "AetherSurfaceOrientation"
	orientation.Attachment0 = attachment
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.RigidityEnabled = false
	orientation.Responsiveness = 35
	orientation.MaxTorque = 1e9
	orientation.Parent = root
	Motion.ceilingAttachment = attachment
	Motion.ceilingForce = force
	Motion.ceilingOrientation = orientation
end

function Motion.releaseTelekinesis(throwObject: boolean?)
	local part = Motion.telePart
	for _, object in ipairs({Motion.telePosition, Motion.teleOrientation, Motion.telePartAttachment}) do
		if typeof(object) == "Instance" then pcall(function() object:Destroy() end) end
	end
	Motion.telePosition = nil
	Motion.teleOrientation = nil
	Motion.telePartAttachment = nil
	Motion.telePart = nil
	if throwObject and part and part.Parent and Camera then
		pcall(function()
			part.AssemblyLinearVelocity = Camera.CFrame.LookVector * cfg.TelekinesisPower
			part.AssemblyAngularVelocity = Vector3.new(0, 8, 0)
		end)
	end
end

function Motion.toggleTelekinesis()
	if Motion.telePart then
		Motion.releaseTelekinesis(false)
		return
	end
	if not cfg.TelekinesisEnabled or not Camera or cfg.MenuVisible then return end
	local viewport = Camera.ViewportSize
	local ray = Camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local hit = Motion.raycast(ray.Origin, ray.Direction * 300)
	local part = hit and hit.Instance
	if not part or not part:IsA("BasePart") or part.Anchored then return end
	if part.AssemblyMass > cfg.TelekinesisMaxMass then
		notify("Object is too heavy")
		return
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then return end
	local attachment = Instance.new("Attachment")
	attachment.Name = "AetherTeleAttachment"
	attachment.Parent = part
	local position = Instance.new("AlignPosition")
	position.Name = "AetherTelePosition"
	position.Attachment0 = attachment
	position.Mode = Enum.PositionAlignmentMode.OneAttachment
	position.ApplyAtCenterOfMass = true
	position.MaxForce = math.max(50000, part.AssemblyMass * 12000)
	position.MaxVelocity = 180
	position.Responsiveness = 45
	position.Parent = part
	local orientation = Instance.new("AlignOrientation")
	orientation.Name = "AetherTeleOrientation"
	orientation.Attachment0 = attachment
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.MaxTorque = math.max(50000, part.AssemblyMass * 12000)
	orientation.Responsiveness = 35
	orientation.Parent = part
	Motion.telePart = part
	Motion.telePartAttachment = attachment
	Motion.telePosition = position
	Motion.teleOrientation = orientation
end

function Motion.scanTornado()
	table.clear(Motion.tornadoParts)
	if not cfg.PhysicsTornadoEnabled then return end
	local character, _, root = Motion.getLocalState()
	if not root then return end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = character and {character} or {}
	local count = 0
	for _, part in ipairs(Workspace:GetPartBoundsInRadius(root.Position, cfg.PhysicsTornadoRadius, overlap)) do
		if part:IsA("BasePart") and not part.Anchored and part ~= Motion.telePart and part.AssemblyMass <= cfg.TelekinesisMaxMass then
			local model = part:FindFirstAncestorOfClass("Model")
			if not model or not model:FindFirstChildOfClass("Humanoid") then
				table.insert(Motion.tornadoParts, part)
				count += 1
				if count >= cfg.PhysicsTornadoMaxParts then break end
			end
		end
	end
end

function Motion.blastTornado()
	local _, _, root = Motion.getLocalState()
	if not root then return end
	for _, part in ipairs(Motion.tornadoParts) do
		if part and part.Parent and not part.Anchored then
			local delta = part.Position - root.Position
			local direction = delta.Magnitude > 0.01 and delta.Unit or Vector3.yAxis
			pcall(function()
				part.AssemblyLinearVelocity = direction * (cfg.PhysicsTornadoForce * 1.7) + Vector3.new(0, cfg.PhysicsTornadoForce * 0.55, 0)
			end)
		end
	end
	table.clear(Motion.tornadoParts)
	Motion.tornadoActive = false
end

function Motion.stopFly()
	if not Motion.flyActive then return end
	Motion.flyActive = false
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	if humanoid and humanoid.Health > 0 then
		humanoid.AutoRotate = true
		if humanoid:GetState() == Enum.HumanoidStateType.Physics then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end
	if not cfg.NoClipEnabled then
		setCharacterCollision(true)
	end
end

function Motion.step(dt: number)
	local character, humanoid, root = Motion.getLocalState()
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		Motion.stopFly()
		Motion.stopGrapple()
		Motion.stopCeilingWalk()
		Motion.releaseTelekinesis(false)
		table.clear(Motion.tornadoParts)
		return
	end

	local flying = cfg.FlyEnabled and Camera ~= nil and not cfg.FreecamEnabled and not cfg.MenuVisible
	if flying then
		if not Motion.flyActive then
			Motion.flyActive = true
			setCharacterCollision(false)
			Motion.stopGrapple()
			Motion.stopCeilingWalk()
		end
		humanoid.AutoRotate = false
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		local cameraCF = Camera.CFrame
		local direction = Vector3.zero
		if moveKeys.W or UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += cameraCF.LookVector end
		if moveKeys.S or UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= cameraCF.LookVector end
		if moveKeys.D or UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += cameraCF.RightVector end
		if moveKeys.A or UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= cameraCF.RightVector end
		local targetVelocity = direction.Magnitude > 0.01 and direction.Unit * cfg.FlySpeed or Vector3.zero
		local blend = 1 - math.exp(-math.max(1, cfg.FlyAcceleration) * dt)
		root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(targetVelocity, blend)
		root.AssemblyAngularVelocity = Vector3.zero
		local flatLook = Vector3.new(cameraCF.LookVector.X, 0, cameraCF.LookVector.Z)
		if flatLook.Magnitude > 0.01 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook.Unit, Vector3.yAxis)
		end
	elseif Motion.flyActive then
		Motion.stopFly()
	end

	if not flying and Motion.grappleHeld and cfg.GrappleEnabled and Motion.grapplePoint then
		local delta = Motion.grapplePoint - root.Position
		if delta.Magnitude > 3 then
			local velocity = root.AssemblyLinearVelocity + delta.Unit * cfg.GrapplePull * dt
			if velocity.Magnitude > cfg.GrappleMaxSpeed then velocity = velocity.Unit * cfg.GrappleMaxSpeed end
			root.AssemblyLinearVelocity = velocity
		else
			Motion.stopGrapple()
		end
	elseif Motion.grappleHeld then
		Motion.stopGrapple()
	end

	if not flying and cfg.WallRunEnabled and not Motion.ceilingActive and humanoid.FloorMaterial == Enum.Material.Air and (moveKeys.W or UserInputService:IsKeyDown(Enum.KeyCode.W)) then
		local leftHit = Motion.raycast(root.Position, -root.CFrame.RightVector * 4)
		local rightHit = Motion.raycast(root.Position, root.CFrame.RightVector * 4)
		local wall = leftHit or rightHit
		if wall and math.abs(wall.Normal.Y) < 0.3 then
			local tangent = Vector3.yAxis:Cross(wall.Normal)
			if tangent:Dot(root.CFrame.LookVector) < 0 then tangent = -tangent end
			root.AssemblyLinearVelocity = tangent.Unit * cfg.WallRunSpeed + Vector3.new(0, cfg.WallRunLift, 0)
			root.CFrame = CFrame.lookAt(root.Position, root.Position + tangent, Vector3.yAxis)
		end
	end

	if Motion.ceilingActive and not flying then
		if not cfg.CeilingWalkEnabled or not Motion.ceilingForce or not Motion.ceilingOrientation then
			Motion.stopCeilingWalk()
		else
			local normal = Motion.ceilingNormal
			local towardSurface = -normal
			local surfaceHit = Motion.raycast(root.Position, towardSurface * 5)
			if surfaceHit then
				normal = surfaceHit.Normal
				Motion.ceilingNormal = normal
				towardSurface = -normal
			end
			Motion.ceilingForce.Force = Vector3.new(0, Workspace.Gravity * root.AssemblyMass, 0)
				+ towardSurface * cfg.CeilingWalkGravity * root.AssemblyMass
			local forward = Camera and Camera.CFrame.LookVector or root.CFrame.LookVector
			forward -= normal * forward:Dot(normal)
			if forward.Magnitude < 0.01 then forward = root.CFrame.LookVector end
			forward = forward.Unit
			local right = forward:Cross(normal).Unit
			Motion.ceilingOrientation.CFrame = CFrame.fromMatrix(Vector3.zero, right, normal, -forward)
			local move = humanoid.MoveDirection
			move -= normal * move:Dot(normal)
			local normalVelocity = normal * root.AssemblyLinearVelocity:Dot(normal)
			if move.Magnitude > 0.01 then
				root.AssemblyLinearVelocity = move.Unit * cfg.CeilingWalkSpeed + normalVelocity
			end
		end
	end

	if Motion.telePart and cfg.TelekinesisEnabled and Camera and Motion.telePosition and Motion.teleOrientation then
		if not Motion.telePart.Parent or Motion.telePart.Anchored then
			Motion.releaseTelekinesis(false)
		else
			Motion.telePosition.Position = Camera.CFrame.Position + Camera.CFrame.LookVector * cfg.TelekinesisDistance
			Motion.teleOrientation.CFrame = Camera.CFrame.Rotation
		end
	elseif Motion.telePart then
		Motion.releaseTelekinesis(false)
	end

	if cfg.PhysicsTornadoEnabled and Motion.tornadoActive then
		Motion.tornadoScanAcc += dt
		Motion.tornadoAngle += dt * 4
		if Motion.tornadoScanAcc >= 0.3 then
			Motion.tornadoScanAcc = 0
			Motion.scanTornado()
		end
		for index, part in ipairs(Motion.tornadoParts) do
			if part and part.Parent and not part.Anchored then
				local angle = Motion.tornadoAngle + index * 2.399
				local radius = 5 + (index % 5) * 1.5
				local height = 2 + (index % 7) * 1.2
				local target = root.Position + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
				local delta = target - part.Position
				pcall(function()
					part.AssemblyLinearVelocity = delta * 5 + Vector3.new(-math.sin(angle), 0, math.cos(angle)) * cfg.PhysicsTornadoForce
				end)
			end
		end
	else
		table.clear(Motion.tornadoParts)
	end

	if not flying and cfg.SurfaceSurferEnabled and not Motion.ceilingActive and humanoid.FloorMaterial ~= Enum.Material.Air and (moveKeys.W or UserInputService:IsKeyDown(Enum.KeyCode.W)) then
		local floor = Motion.raycast(root.Position, Vector3.new(0, -5, 0))
		if floor and floor.Normal.Y > 0.2 then
			local normal = floor.Normal
			local forward = Camera and Camera.CFrame.LookVector or root.CFrame.LookVector
			forward = Vector3.new(forward.X, 0, forward.Z)
			forward -= normal * forward:Dot(normal)
			if forward.Magnitude > 0.01 then
				local planar = root.AssemblyLinearVelocity - normal * root.AssemblyLinearVelocity:Dot(normal)
				local target = forward.Unit * cfg.SurfaceSurferSpeed
				local blend = math.clamp(cfg.SurfaceSurferAcceleration * dt / math.max(1, cfg.SurfaceSurferSpeed), 0, 1)
				root.AssemblyLinearVelocity = planar:Lerp(target, blend) - normal * 2
			end
		end
	end
end

function Motion.cleanup()
	Motion.stopFly()
	Motion.stopGrapple()
	Motion.stopCeilingWalk()
	Motion.releaseTelekinesis(false)
	Motion.tornadoActive = false
	table.clear(Motion.tornadoParts)
end

RunService.RenderStepped:Connect(function(dt)
	if isUnloaded then return end
	Motion.step(dt)
	if cfg.FreecamEnabled and Camera then
		if Camera.CameraType ~= Enum.CameraType.Scriptable then
			Camera.CameraType = Enum.CameraType.Scriptable
		end
	end

	if cfg.MenuVisible then
		UserInputService.MouseIconEnabled = true
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	elseif cfg.FreecamEnabled then
		UserInputService.MouseIconEnabled = false
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end

	updateSilent2Hitboxes(dt)
	processShotConfirmations()

	if cfg.PlayerStickEnabled then
		stickAcc += dt
		if stickAcc >= math.max(0.01, cfg.PlayerStickInterval) then
			stickAcc = 0
			if not stickToSelectedPlayer() then
				cfg.PlayerStickEnabled = false
				if menuApi then menuApi:RefreshAll() end
				notify("Stick target unavailable")
			end
		end
	else
		stickAcc = 0
	end

	if cfg.SpectatorDetectionEnabled then
		spectatorAcc += dt
		if spectatorAcc >= 1 then
			spectatorAcc = 0
			local labels = getSpectatorLabels()
			local signature = table.concat(labels, "\0")
			if signature ~= lastSpectatorSignature then
				lastSpectatorSignature = signature
				if menuApi then menuApi:RefreshAll() end
				if #labels > 0 then notify("Spectators: " .. table.concat(labels, ", ")) end
			end
		end
	else
		spectatorAcc = 0
		lastSpectatorSignature = ""
	end

	if silentAim1Active() and (isAimInputActive() or cfg.SilentAim1AutoMouse1) then
		silent1HoldAcc += dt
		if silent1HoldAcc >= 0.045 then
			silent1HoldAcc = 0
			doSilentAim1Shot()
		end
		if cfg.SilentAim1AutoMouse1 then
			-- pre-lock target without LOS for smoother behavior, shoot only when LOS/FOV conditions are valid
			local pre = getSilentAimPart(false)
			if pre then
				silent1PrelockPart = pre
				silent1PrelockUntil = os.clock() + 0.40
			elseif silent1PrelockUntil > 0 and os.clock() > silent1PrelockUntil then
				silent1PrelockPart = nil
				silent1PrelockUntil = 0
			end

			silent1AutoShootAcc += dt
			if silent1AutoShootAcc >= math.max(0.06, cfg.SilentAim1AutoMouse1Interval) then
				silent1AutoShootAcc = 0
				local part = nil
				if silent1PrelockPart and silent1PrelockPart.Parent and os.clock() <= silent1PrelockUntil then
					local center = getAimOrigin2D()
					local d2 = getBestPointOnPart(silent1PrelockPart, center, cfg.AimRequireLOS)
					if d2 and d2 <= (cfg.AimFOV * cfg.AimFOV) then
						part = silent1PrelockPart
					end
				end
				part = part or getSilentAimPart(true)
				if part then
					rapidFireOnce()
				end
			end
		else
			silent1AutoShootAcc = 0
		end
	else
		silent1HoldAcc = 0
		silent1AutoShootAcc = 0
	end

	if cfg.FreecamEnabled and Camera and (not cfg.MenuVisible) then
		freecamCF = freecamCF or Camera.CFrame
		local d = UserInputService:GetMouseDelta() * cfg.FreecamLookSensitivity
		-- rotate around camera's own pivot (not world origin), so mouse turn rotates camera instead of shifting it
		local cf = freecamCF * CFrame.Angles(-math.rad(d.Y), -math.rad(d.X), 0)

		local w = moveKeys.W or UserInputService:IsKeyDown(Enum.KeyCode.W)
		local a = moveKeys.A or UserInputService:IsKeyDown(Enum.KeyCode.A)
		local s = moveKeys.S or UserInputService:IsKeyDown(Enum.KeyCode.S)
		local dKey = moveKeys.D or UserInputService:IsKeyDown(Enum.KeyCode.D)
		local e = moveKeys.E or UserInputService:IsKeyDown(Enum.KeyCode.E)
		local q = moveKeys.Q or UserInputService:IsKeyDown(Enum.KeyCode.Q)

		local mv = Vector3.new(0,0,0)
		if w then mv += cf.LookVector end
		if s then mv -= cf.LookVector end
		if dKey then mv += cf.RightVector end
		if a then mv -= cf.RightVector end
		if e then mv += Vector3.new(0,1,0) end
		if q then mv -= Vector3.new(0,1,0) end
		if mv.Magnitude > 0 then
			mv = mv.Unit * (32 * cfg.FreecamSpeed) * dt
		end
		freecamCF = cf + mv
		Camera.CFrame = freecamCF
	end

	cleanupAcc += dt
	if cleanupAcc >= 3.0 then
		cleanupAcc = 0
		for part, _ in pairs(xrayApplied) do
			if (not part) or (not part.Parent) then
				xrayApplied[part] = nil
			end
		end
		for inst, _ in pairs(rfOriginalValues) do
			if (not inst) or (not inst.Parent) then
				rfOriginalValues[inst] = nil
			end
		end
		for p, _ in pairs(dirtyVisualPlayers) do
			if (not p) or (not p.Parent) then
				dirtyVisualPlayers[p] = nil
				dirtyVisualCount -= 1
			end
		end
		if dirtyVisualCount < 0 then dirtyVisualCount = 0 end
	end

	if cfg.UIAnimations then
		local color = Color3.fromHSV((0.33 + os.clock() * 0.05) % 1, 0.6, 1)
		chTop.BackgroundColor3 = color
		chBottom.BackgroundColor3 = color
		chLeft.BackgroundColor3 = color
		chRight.BackgroundColor3 = color
	end

	if Camera and Camera.ViewportSize ~= lastFOVViewportSize then
		updateFOVCircle()
	end

	local normalAimRuntimeEnabled = cfg.AimEnabled and (not cfg.SilentAim1Enabled)
	local currentAimPart: BasePart? = nil
	if (not cfg.FreecamEnabled) and normalAimRuntimeEnabled and Camera and (isAimInputActive() or cfg.AimAlways) then
		local part = getBestTargetPart(cfg.AimAllPlayers, cfg.AimMaxDistance, cfg.AimFOV, cfg.AimRequireLOS, cfg.AimUseNearestVisibleHitbox, cfg.AimHitbox, AimHitboxPriority)
		currentAimPart = part
		if part then
			local camPos = Camera.CFrame.Position
			local rawAimPoint = getAimPointForPart(part)
			local predictedAimPoint = getPredictedAimPoint(part, rawAimPoint)
			local aimPoint = getSmoothedAimPoint(part, predictedAimPoint, dt)
			local targetCF = CFrame.new(camPos, aimPoint)
			local baseSpeed = math.clamp(cfg.AimSmoothness or 0, 0, 100)
			local speed = baseSpeed
			if cfg.AdaptiveAimEnabled then
				local d = math.max(1, (aimPoint - camPos).Magnitude)
				local strength01 = math.clamp((cfg.AdaptiveAimStrength or 0) / 100, 0, 1)
				-- base speed is calibrated for 100m:
				-- closer than 100m => faster, farther => slower (continuous, no presets)
				local factor = (100 / d) ^ strength01
				speed = math.clamp(baseSpeed * factor, 0, 100)
			end
			local baseAlpha = math.clamp(speed / 100, 0, 1)
			local alpha = baseAlpha >= 1 and 1 or 1 - ((1 - baseAlpha) ^ math.max(dt * 60, 0))
			Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
		end
	else
		aimFilteredPart = nil
		aimFilteredPoint = nil
	end
	if normalAimRuntimeEnabled and not currentAimPart then
		aimFilteredPart = nil
		aimFilteredPoint = nil
	end

	if (not currentAimPart) then
		currentAimPart = getCurrentAimTargetPart()
	end
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	profileTickAcc += dt
	if cfg.WeaponProfilesEnabled and profileTickAcc >= 0.4 then
		profileTickAcc = 0
		local tool = char and char:FindFirstChildOfClass("Tool")
		local toolName = string.lower(tool and tool.Name or "")
		if toolName ~= "" and toolName ~= lastProfileToolName then
			lastProfileToolName = toolName
			for _, p in ipairs(WEAPON_PROFILES) do
				if string.find(toolName, p.match, 1, true) then
					cfg.AimFOV = p.aimFov
					cfg.AimSmoothness = p.aimSmooth
					cfg.TriggerbotRadius = p.triggerRadius
					cfg.RapidFireMultiplier = p.rapidMult
					break
				end
			end
		end
	end

	if autoPeekPendingReturn and autoPeekStartCF and os.clock() >= autoPeekReturnAt then
		autoPeekPendingReturn = false
		local c = LocalPlayer.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			hrp.CFrame = autoPeekStartCF
		end
		autoPeekStartCF = nil
	end

	if hum and hum.Health > 0 then
		if cfg.FreecamEnabled then
			-- freeze character while in freecam: only camera should move
			hum.WalkSpeed = 0
			hum.UseJumpPower = true
			hum.JumpPower = 0
			hum.AutoRotate = false
		elseif cfg.FlyEnabled then
			hum.WalkSpeed = 0
			hum.UseJumpPower = true
			hum.JumpPower = 0
			hum.AutoRotate = false
		else
			local baseSpeed = cfg.AutoSprint and math.max(cfg.MoveSpeed, 26) or cfg.MoveSpeed
			hum.WalkSpeed = cfg.SlowModeEnabled and math.min(baseSpeed, cfg.SlowMoveSpeed) or baseSpeed
			hum.UseJumpPower = true
			hum.JumpPower = cfg.JumpPowerValue
			hum.AutoRotate = not cfg.TiltEnabled
		end
		if cfg.GodModeEnabled then
			hum.Health = hum.MaxHealth
		end
	end
	if Camera then
		if cfg.CameraFOVOverride and math.abs(Camera.FieldOfView - cfg.CameraFOVValue) > 0.01 then Camera.FieldOfView = cfg.CameraFOVValue end
		if cfg.ThirdPerson and hum then
			Camera.CameraType = Enum.CameraType.Custom
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				Camera.CFrame = CFrame.new(hrp.Position - Camera.CFrame.LookVector * cfg.ThirdPersonDistance + Vector3.new(0,2,0), hrp.Position + Vector3.new(0,1.5,0))
			end
		end
		if cfg.ComedicRecoilEnabled and (math.abs(recoilKick.X) > 0.01 or math.abs(recoilKick.Y) > 0.01) then
			Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(-recoilKick.Y), math.rad(recoilKick.X), 0)
			recoilKick = recoilKick:Lerp(Vector2.zero, math.clamp(dt * 8, 0, 1))
		end
	end
	local lighting = Lighting
	if cfg.Fullbright then
		if (not lastFullbrightApplied)
			or lighting.Brightness ~= 3
			or lighting.Ambient ~= Color3.fromRGB(180,180,180)
			or lighting.OutdoorAmbient ~= Color3.fromRGB(170,170,170)
		then
			lighting.Brightness = 3
			lighting.Ambient = Color3.fromRGB(180,180,180)
			lighting.OutdoorAmbient = Color3.fromRGB(170,170,170)
			lastFullbrightApplied = true
		end
	else
		lastFullbrightApplied = false
	end

	worldTickAcc += dt
	if cfg.ClockTimeOverride and worldTickAcc >= 0.15 then
		worldTickAcc = 0
		lighting.ClockTime = cfg.ClockTimeValue
	end

	if char and lastHideLocalApplied ~= cfg.HideLocalCharacter then
		lastHideLocalApplied = cfg.HideLocalCharacter
		for _, bp in ipairs(char:GetDescendants()) do
			if bp:IsA("BasePart") then
				bp.LocalTransparencyModifier = cfg.HideLocalCharacter and 1 or 0
			end
		end
	end
	if hum and hum.Health > 0 and char and not cfg.FlyEnabled then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local extraG = cfg.PlayerGravity - Workspace.Gravity
			if math.abs(extraG) > 0.01 then
				hrp.AssemblyLinearVelocity += Vector3.new(0, -extraG * dt, 0)
			end

			if cfg.VerticalFreezeEnabled then
				verticalFreezeY = verticalFreezeY or hrp.Position.Y
				local ox, oy, oz = hrp.CFrame:ToOrientation()
				hrp.CFrame = CFrame.new(hrp.Position.X, verticalFreezeY, hrp.Position.Z) * CFrame.fromOrientation(ox, oy, oz)
				hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
			else
				verticalFreezeY = nil
			end

			if cfg.TiltEnabled then
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(math.rad(cfg.TiltPitch), math.rad(cfg.TiltYaw), math.rad(cfg.TiltRoll))
			elseif cfg.RandomLeanEnabled then
				randomLeanAcc += dt
				if randomLeanAcc >= 0.5 then
					randomLeanAcc = 0
					local r = cfg.RandomLeanRange
					randomLeanPitch = (math.random() * 2 - 1) * r
					randomLeanYaw = (math.random() * 2 - 1) * r
					randomLeanRoll = (math.random() * 2 - 1) * r
				end
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(math.rad(randomLeanPitch), math.rad(randomLeanYaw), math.rad(randomLeanRoll))
			end

			if cfg.HeadHelicopterEnabled then
				local spin = math.rad((os.clock() * cfg.HeadHelicopterSpeed) % 360)
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spin, 0)
			end

			if cfg.BananaDriftEnabled then
				hrp.AssemblyLinearVelocity += hrp.CFrame.RightVector * (cfg.BananaDriftStrength * dt)
			end

			if cfg.MoonMagnetEnabled and hum.FloorMaterial == Enum.Material.Air then
				hrp.AssemblyLinearVelocity += Vector3.new(0, cfg.MoonMagnetPower * dt, 0)
			end

			if cfg.FakeLagPuppetEnabled then
				fakeLagAcc += dt
				if fakeLagAcc >= cfg.FakeLagStep then
					fakeLagAcc = 0
					local v = hrp.AssemblyLinearVelocity
					hrp.AssemblyLinearVelocity = Vector3.new(v.X * 0.25, v.Y, v.Z * 0.25)
				end
			else
				fakeLagAcc = 0
			end

			if cfg.PanicStatueEnabled and os.clock() < panicStatueUntil then
				hrp.AssemblyLinearVelocity = Vector3.zero
			end

			if cfg.ReverseDayEnabled and hum.MoveDirection.Magnitude > 0.1 then
				hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position - hum.MoveDirection)
			end

			if cfg.FloorIsLavaEnabled then
				if hum.MoveDirection.Magnitude < 0.05 and hum.FloorMaterial ~= Enum.Material.Air then
					lavaIdleAcc += dt
					if lavaIdleAcc >= cfg.FloorIsLavaIdleTime then
						lavaIdleAcc = 0
						hrp.AssemblyLinearVelocity += Vector3.new(0, cfg.FloorIsLavaPower, 0)
					end
				else
					lavaIdleAcc = 0
				end
			else
				lavaIdleAcc = 0
			end

			if cfg.AutoUnstuckEnabled then
				local moveMag = hum.MoveDirection.Magnitude
				local vFlat = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
				if moveMag > 0.2 and hum.FloorMaterial ~= Enum.Material.Air and vFlat < 1.1 then
					unstuckAcc += dt
					if unstuckAcc >= 1.2 then
						unstuckAcc = 0
						hrp.AssemblyLinearVelocity += hum.MoveDirection.Unit * 26 + Vector3.new(0, 12, 0)
					end
				else
					unstuckAcc = 0
				end
			else
				unstuckAcc = 0
			end
		end
	end

	if Phantom.enabled and Phantom.getInterface() then
		Phantom.scanAcc += dt
		if Phantom.scanAcc >= 0.20 then
			Phantom.scanAcc = 0
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then
					local previous = characterModelCache[player]
					local current = Phantom.getCharacter(player)
					local health = Phantom.getHealth(player)
					if current and health ~= nil and health <= 0 then
						cleanupVisual(player)
						clearDirtyPlayer(player)
						invalidatePlayerRuntime(player, current)
					elseif current and current ~= previous then
						onTrackedCharacterAdded(player, current)
					elseif current and not visualsByPlayer[player] then
						markVisualDirty(player)
					elseif previous and (not current or not previous.Parent) then
						onTrackedCharacterRemoving(player, previous)
					end
				end
			end
		end
	end

	-- process queued visual refreshes + dynamic visual updates (throttled)
	processDirtyVisualQueue()
	processVisualStyleQueue()
	processChamsColorQueue()
	visualAuditAcc += dt
	if visualAuditAcc >= 1.2 then
		visualAuditAcc = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and isVisualCandidate(p) then
				local v = visualsByPlayer[p]
				if not isWithinESPDistance(p) then
					if v then cleanupVisual(p) end
				else
					local needsChams = playerVisualEnabled(p, "chams", cfg.ChamsEnabled)
					local needsNameTag = playerVisualEnabled(p, "nametags", cfg.NameTagsEnabled)
					if (needsChams and (not v or not v.hl or not v.hl.Parent))
						or (needsNameTag and (not v or not v.gui or not v.gui.Parent))
					then
						markVisualDirty(p)
					end
				end
			end
		end
	end
	visualTickAcc += dt
	local visualStep = cfg.LowEndMode and 0.12 or 0.06
	if visualTickAcc >= visualStep and (cfg.ShowDistance or Phantom.enabled) then
		visualTickAcc = 0
		local budget = cfg.LowEndMode and 1 or 3
		for _ = 1, budget do
			local plr, data = next(visualsByPlayer, visualDynamicCursor)
			if not plr then
				visualDynamicCursor = nil
				break
			end
			visualDynamicCursor = plr
			if data.gui and data.gui.Parent then
				local n = data.gui:FindFirstChildOfClass("Frame")
				local label = n and n:FindFirstChild("NameLabel")
				local _, _, hrp = getCharacterParts(plr)
				local dist = nil
				if Camera and hrp then
					dist = (hrp.Position - Camera.CFrame.Position).Magnitude
					-- softer distance scaling: less jumpy/less intrusive at range
					local t = math.clamp((dist - 40) / 420, 0, 1)
					local baseScale = math.min(cfg.NameTagScale, cfg.NameTagMaxScale or 1.2)
					local dynamicScale = baseScale * (1 - 0.12 * t)
					dynamicScale = math.clamp(dynamicScale, baseScale * 0.88, baseScale)
					data.gui.Size = UDim2.fromOffset(math.floor(188 * dynamicScale), math.floor(50 * dynamicScale))
					data.gui.StudsOffset = Vector3.new(0, 3.2 + ((dynamicScale - 1) * 0.7), 0)
				end
				if label and label:IsA("TextLabel") then
					if cfg.ShowDistance and dist then
						label.Text = string.format("%s (@%s) [%dm]", plr.DisplayName, plr.Name, math.floor(dist))
					else
						label.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
					end
				end
				if Phantom.enabled and data.hpFill and data.hpText then
					local _, hum = getCharacterParts(plr)
					local health, maxHealth = getPlayerHealth(plr, hum)
					local ratio = math.clamp(health / maxHealth, 0, 1)
					data.hpFill.Size = UDim2.fromScale(ratio, 1)
					data.hpText.Text = string.format("%d / %d", math.floor(health + 0.5), math.floor(maxHealth + 0.5))
					if ratio > 0.6 then
						data.hpFill.BackgroundColor3 = MODERN_THEME.good
					elseif ratio > 0.3 then
						data.hpFill.BackgroundColor3 = Color3.fromRGB(254, 211, 48)
					else
						data.hpFill.BackgroundColor3 = Color3.fromRGB(245, 96, 114)
					end
				end
			end
		end
	end

	if cfg.BacklockEnabled and hum and hum.Health > 0 and char and (not cfg.MenuVisible) and (not cfg.FreecamEnabled) and isAimInputActive() then
		local myHRP = char:FindFirstChild("HumanoidRootPart")
		if myHRP and myHRP:IsA("BasePart") then
			local tPart = getBestTargetPart(cfg.AimAllPlayers, cfg.AimMaxDistance, cfg.AimFOV, cfg.AimRequireLOS, cfg.AimUseNearestVisibleHitbox, cfg.AimHitbox, AimHitboxPriority)
			if tPart then
				local tChar = tPart:FindFirstAncestorOfClass("Model")
				local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
				local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
				if tHRP and tHRP:IsA("BasePart") and tHum and tHum.Health > 0 then
					backlockFireAcc += dt
					if backlockFireAcc >= 0.055 then
						backlockFireAcc = 0
						local originalCF = myHRP.CFrame
						local backPos = tHRP.Position - (tHRP.CFrame.LookVector * 2)
						myHRP.CFrame = CFrame.new(backPos + Vector3.new(0, 0.25, 0), tHRP.Position)
						rapidFireOnce()
						myHRP.CFrame = originalCF
					end
				end
			end
		end
	else
		backlockFireAcc = 0
	end

	if cfg.SpiderEnabled and not cfg.FlyEnabled and hum and hum.Health > 0 and char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local forwardPressed = moveKeys.W or UserInputService:IsKeyDown(Enum.KeyCode.W)
			if forwardPressed and (not cfg.MenuVisible) and (not cfg.FreecamEnabled) then
				local look = hrp.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z)
				if flat.Magnitude > 0.001 then
					flat = flat.Unit
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Blacklist
					params.FilterDescendantsInstances = {char}
					local hit = Workspace:Raycast(hrp.Position, flat * 1.8, params)
					if hit and hit.Instance and hit.Instance.CanCollide then
						local wallDist = (hit.Position - hrp.Position).Magnitude
						if wallDist <= 1.9 then
							hum:ChangeState(Enum.HumanoidStateType.Climbing)
							-- stick to wall instead of popping upward: push slightly into wall + controlled climb speed
							local stick = -(hit.Normal.Unit) * 8
							hrp.AssemblyLinearVelocity = Vector3.new(stick.X, math.max(6, cfg.SpiderSpeed * 0.55), stick.Z)
						end
					end
				end
			end
		end
	end

	if cfg.BhopEnabled and not cfg.FlyEnabled and spaceDown then
		if hum and hum.Health > 0 and (hum.FloorMaterial ~= Enum.Material.Air) then
			-- keep bhop jump height sane (do not amplify with custom jump power)
			local oldJP = hum.JumpPower
			hum.JumpPower = math.min(oldJP, 50)
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			hum.JumpPower = oldJP
		end
	end

	if cfg.NoClipEnabled or cfg.FlyEnabled then
		noclipTickAcc += dt
		if noclipTickAcc >= 0.12 then
			noclipTickAcc = 0
			local char = LocalPlayer.Character
			if char then
				for _, v in ipairs(char:GetDescendants()) do
					if v:IsA("BasePart") then v.CanCollide = false end
				end
			end
		end
	else
		noclipTickAcc = 0
	end

	-- silent aim works through raycast hooks; camera stays untouched

	if cfg.TriggerbotEnabled and (not cfg.FreecamEnabled) and (not cfg.MenuVisible) then
		triggerbotAcc += dt
		if triggerbotAcc >= 0.05 then
			triggerbotAcc = 0
			local part = getBestTargetPart(cfg.AimAllPlayers, cfg.AimMaxDistance, cfg.TriggerbotRadius, cfg.AimRequireLOS, cfg.AimUseNearestVisibleHitbox, cfg.AimHitbox, AimHitboxPriority)
			if part then
				rapidFireOnce()
			end
		end
	else
		triggerbotAcc = 0
	end

	if cfg.RapidFireEnabled then
		local now = os.clock()
		if now - rfPatchLastAt >= 0.35 then
			rfPatchLastAt = now
			updateSpeedFire2(true)
		end
		if isAimInputActive() and (not cfg.FreecamEnabled) and (not cfg.MenuVisible) then
			rapidFireOnce()
		end
	else
		updateSpeedFire2(false)
	end

end)

local function applyPanicModeState(v: boolean)
	cfg.PanicMode = v
	if not v then return end
	cfg.AimEnabled = false
	cfg.BhopEnabled = false
	cfg.InfiniteJumpEnabled = false
	cfg.NoClipEnabled = false
	cfg.FreecamEnabled = false
	cfg.RapidFireEnabled = false
	cfg.SlowModeEnabled = false
	cfg.SilentAim1Enabled = false
	cfg.SilentAim2Enabled = false
	cfg.BacklockEnabled = false
	cfg.SpiderEnabled = false
	cfg.TriggerbotEnabled = false
	cfg.AutoUnstuckEnabled = false
	cfg.WeaponProfilesEnabled = false
	cfg.VerticalFreezeEnabled = false
	cfg.FlyEnabled = false
	cfg.TiltEnabled = false
	cfg.BananaDriftEnabled = false
	cfg.FakeLagPuppetEnabled = false
	cfg.MoonMagnetEnabled = false
	cfg.HeadHelicopterEnabled = false
	cfg.PanicStatueEnabled = false
	cfg.ReverseDayEnabled = false
	cfg.RubberBandDashEnabled = false
	cfg.FloorIsLavaEnabled = false
	cfg.RandomLeanEnabled = false
	cfg.ComedicRecoilEnabled = false
	verticalFreezeY = nil
	cfg.XrayEnabled = false
	cfg.ShowDistance = false
	cfg.CrosshairEnabled = false
	refreshXray()
	applyVisualSettings()
	setMenuVisible(false)
end

local function runAction(action: string)
	if action == "PanicToggle" then
		applyPanicModeState(not cfg.PanicMode)
	elseif action == "ForwardLaunch" then
		if not cfg.ForwardLaunchEnabled then
			notify("Forward Launch is OFF")
			return
		end
		local ok = forwardLaunchRagdoll()
		notify(ok and "Forward launch" or "Forward launch failed")
	elseif action == "RubberBandDash" then
		if not cfg.RubberBandDashEnabled or os.clock() < rubberDashCooldownUntil then return end
		rubberDashCooldownUntil = os.clock() + 1.2
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local forward = hrp.CFrame.LookVector
			hrp.AssemblyLinearVelocity += -forward * 25
			task.delay(0.12, function()
				if hrp.Parent then hrp.AssemblyLinearVelocity += forward * cfg.RubberBandDashPower end
			end)
		end
	elseif action == "PanicStatue" and cfg.PanicStatueEnabled then
		panicStatueUntil = os.clock() + 2
	end
end
UserInputService.InputBegan:Connect(function(input, gpe)
	if isUnloaded then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local now = os.clock()
		mouse1Down = true
		if cfg.AimInputMode == "Toggle" then
			if (now - aimLastPressAt) <= cfg.AimToggleDoublePressWindow then
				aimToggleActive = not aimToggleActive
				notify("Aim Input: " .. (aimToggleActive and "TOGGLE ON" or "TOGGLE OFF"))
				aimLastPressAt = 0
			else
				aimLastPressAt = now
			end
		end
		doSilentAim1Shot()
		if recordShotCandidate then recordShotCandidate() end
		if cfg.AutoPeekEnabled then
			local c = LocalPlayer.Character
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				autoPeekStartCF = hrp.CFrame
				if cfg.AutoPeekMode == "LagPeek" then
					local t = getCurrentAimTargetPart()
					if t then
						hrp.CFrame = CFrame.new(t.Position - t.CFrame.LookVector * 2, t.Position)
					end
				end
				autoPeekPendingReturn = true
				autoPeekReturnAt = os.clock() + 0.06
			end
		end
		if cfg.ComedicRecoilEnabled then
			recoilKick = Vector2.new((math.random() * 2 - 1) * cfg.ComedicRecoilPower, (math.random() * 2 - 1) * cfg.ComedicRecoilPower)
		end
	end
	if input.KeyCode == Enum.KeyCode.Space then
		spaceDown = true
		if cfg.InfiniteJumpEnabled then
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local now = os.clock()
			if hum and hum.Health > 0 and (now - infJumpLastAt) >= 0.06 then
				infJumpLastAt = now
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end
	if input.KeyCode == Enum.KeyCode.W then moveKeys.W = true end
	if input.KeyCode == Enum.KeyCode.A then moveKeys.A = true end
	if input.KeyCode == Enum.KeyCode.S then moveKeys.S = true end
	if input.KeyCode == Enum.KeyCode.D then moveKeys.D = true end
	if input.KeyCode == Enum.KeyCode.E then moveKeys.E = true end
	if input.KeyCode == Enum.KeyCode.Q then moveKeys.Q = true end

	if gpe then return end
end)

UserInputService.InputEnded:Connect(function(input)
	if isUnloaded then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouse1Down = false
	end
	if input.KeyCode == Enum.KeyCode.Space then spaceDown = false end
	if input.KeyCode == Enum.KeyCode.W then moveKeys.W = false end
	if input.KeyCode == Enum.KeyCode.A then moveKeys.A = false end
	if input.KeyCode == Enum.KeyCode.S then moveKeys.S = false end
	if input.KeyCode == Enum.KeyCode.D then moveKeys.D = false end
	if input.KeyCode == Enum.KeyCode.E then moveKeys.E = false end
	if input.KeyCode == Enum.KeyCode.Q then moveKeys.Q = false end
end)

updateFOVCircle()

local function bootAetherMenuApi()
	local AETHER_MENU_API_URL = "https://raw.githubusercontent.com/Sqidsoff/sakanig4dick/refs/heads/main/menu_api.lua"
	local REQUIRED_MENU_API_VERSION = "8.1.1"
	local loaderSource: string? = nil

	local function fetchText(url: string): string?
		if url == "" then return nil end

		local ok, body = pcall(function()
			if game and game.HttpGet then
				return game:HttpGet(url, true)
			end
			return nil
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
			return nil
		end)

		if ok and type(body) == "table" then
			body = body.Body or body.body
		end
		if type(body) == "string" and #body > 0 then
			return body
		end

		return nil
	end

	local function versionAtLeast(actual: string?, required: string): boolean
		local function parts(value: string?): {number}
			local out = {}
			for n in string.gmatch(value or "", "%d+") do table.insert(out, tonumber(n) or 0) end
			return out
		end
		local a, b = parts(actual), parts(required)
		for i = 1, math.max(#a, #b) do
			local av, bv = a[i] or 0, b[i] or 0
			if av ~= bv then return av > bv end
		end
		return true
	end

	local function sourceVersion(source: string?): string?
		return source and string.match(source, 'Library%.Version%s*=%s*"([^"]+)"') or nil
	end

	pcall(function()
		if readfile then
			local okA, srcA = pcall(function() return readfile("D:\\it\\Lua\\menu_api.lua") end)
			if okA then loaderSource = srcA end
			if not loaderSource then
				local okB, srcB = pcall(function() return readfile("D:/it/Lua/menu_api.lua") end)
				if okB then loaderSource = srcB end
			end
		end
	end)
	if loaderSource and not versionAtLeast(sourceVersion(loaderSource), REQUIRED_MENU_API_VERSION) then
		loaderSource = nil
	end
	if not loaderSource then
		loaderSource = fetchText(AETHER_MENU_API_URL)
		if loaderSource and not versionAtLeast(sourceVersion(loaderSource), REQUIRED_MENU_API_VERSION) then
			loaderSource = nil
		end
	end
	if not loaderSource then
		notify("Menu API " .. REQUIRED_MENU_API_VERSION .. "+ is required; update Catbox or keep local menu_api.lua")
		return
	end
	if not loadstring then
		notify("loadstring is disabled in this executor")
		return
	end
	local loaderFn = loadstring(loaderSource)
	if not loaderFn then
		notify("menu_api.lua loadstring failed")
		return
	end
	local ok, library = pcall(loaderFn)
	if ok and not library then
		library = (shared and (shared.Aether or shared.AetherMenuApi)) or (_G and (_G.Aether or _G.AetherMenuApi))
	end
	if not ok or type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
		notify("menu_api.lua library failed")
		return
	end

	local api = library:CreateWindow({
		Players = Players,
		UserInputService = UserInputService,
		TweenService = TweenService,
		RunService = RunService,
		LocalPlayer = LocalPlayer,
		PlayerGui = PlayerGui,
		cfg = cfg,
		notify = notify,
		configFolder = "AetherHvHConfigs",
		title = "AETHER V7",
		subtitle = "HvH script client built on reusable menu_api.lua",
		unload = function(apiInstance)
			fullUnload()
			if apiInstance then apiInstance:Destroy() end
		end,
	})
	if not api then return end

	menuApi = api
	if api.Events then
		api.Events:On("PlayerAdded", function(player)
			trackPlayer(player)
			api:RefreshAll()
		end)
		api.Events:On("PlayerRemoving", function(player)
			untrackPlayer(player)
			if selectedPlayerName == player.Name then
				selectedPlayerName = ""
				selectedPlayerLabel = ""
				cfg.PlayerStickEnabled = false
			end
			api:RefreshAll()
		end)
		api.Events:On("CharacterAdded", function(player, character)
			onTrackedCharacterAdded(player, character)
		end)
		api.Events:On("CharacterRemoving", function(player, character)
			onTrackedCharacterRemoving(player, character)
		end)
		api.Events:On("CharacterModelAdded", function(player, model)
			player = player or findPlayerForModel(model)
			if player then onTrackedCharacterAdded(player, model) end
		end)
		api.Events:On("CharacterModelRemoving", function(player, model)
			player = player or findPlayerForModel(model)
			if player then onTrackedCharacterRemoving(player, model) end
		end)
		api.Events:On("PlayerTeamChanged", function(player)
			invalidatePlayerRuntime(player, characterModelCache[player])
			if player == LocalPlayer then
				applyVisualSettings()
			else
				refreshOnePlayer(player)
			end
		end)
		api.Events:On("ColorRainbowChanged", function(id, enabled)
			if id == "ChamsCustomColor" and enabled then
				cfg.ChamsTeamColor = false
				applyVisualSettings()
				api:RefreshAll()
			end
		end)
		api.Events:On("LocalCharacterRemoving", function()
			Motion.cleanup()
			stickyTargetPlayer = nil
			stickyTargetPart = nil
			stickyTargetUntil = 0
			table.clear(threatCache)
			table.clear(pendingShots)
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then cleanupVisual(player) end
			end
		end)
		api.Events:On("LocalCharacterAdded", function()
			onLocalCharacterReset()
		end)
	end

	function setMenuVisible(v: boolean)
		cfg.MenuVisible = v
		api:SetVisible(v)
		UserInputService.MouseIconEnabled = true
		if not v and cfg.FreecamEnabled then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		elseif UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end

	local window = api.Window
	local aim = window:Tab("aim", "Aim")
	local esp = window:Tab("esp", "Visuals")
	local move = window:Tab("move", "Move")
	local cam = window:Tab("cam", "Camera")
	local world = window:Tab("world", "World")
	local tools = window:Tab("tools", "Tools")
	local fun = window:Tab("fun", "Fun")
	local playersTab = window:Tab("players", "Players")
	local uiTab = window:Tab("ui", "UI")

	local boundCfg = {
		ChamsCustomColor = true,
		HitSoundCustomPath = true,
	}
	local function get(k) return function() return cfg[k] end end
	local function set(k, after)
		return function(v)
			cfg[k] = v
			if after then after(v) end
		end
	end
	local function bool(k, tab, label, after)
		boundCfg[k] = true
		return window:AddToggle(tab, {id = k, label = label, get = get(k), set = set(k, after)})
	end
	local function slider(k, tab, label, minV, maxV, step, after)
		boundCfg[k] = true
		return window:AddSlider(tab, {id = k, label = label, min = minV, max = maxV, step = step, get = get(k), set = set(k, after)})
	end
	local function drop(k, tab, label, options, after)
		boundCfg[k] = true
		return window:AddDropdown(tab, {id = k, label = label, options = options, get = get(k), set = set(k, after)})
	end

	aim:Section("Targeting")
	bool("AimEnabled", aim, "Aim assist", function() updateFOVCircle() end)
	bool("AimAlways", aim, "Aim without Mouse1")
	bool("ShowFOV", aim, "Show FOV circle", function() updateFOVCircle() end)
	bool("AimAllPlayers", aim, "Target all players")
	bool("AimRequireLOS", aim, "Require line of sight")
	bool("AimUseNearestVisibleHitbox", aim, "Nearest visible hitbox", function() refreshHitboxUI() end)
	bool("AimMultiPointEnabled", aim, "Multipoint hitbox scan")
	slider("AimFOV", aim, "Aim FOV", 40, 500, 10, function() updateFOVCircle() end)
	slider("AimSmoothness", aim, "Aim speed", 0, 100, 1)
	slider("AimMaxDistance", aim, "Aim max distance", 50, 2000, 25)
	slider("AimMultiPointScale", aim, "Multipoint scale", 0.05, 0.95, 0.05)
	bool("AimPredictionEnabled", aim, "Movement prediction")
	slider("AimPredictionTime", aim, "Prediction time", 0, 0.50, 0.01)
	slider("AimTrackingSmoothness", aim, "Tracking smoothness", 0, 100, 1)
	drop("AimHitbox", aim, "Fixed hitbox", HITBOX_LIST, function() refreshHitboxUI() end)
	drop("AimInputMode", aim, "Aim input mode", {"Hold", "Toggle"})
	slider("AimToggleDoublePressWindow", aim, "Toggle double-click window", 0.10, 0.60, 0.05)
	aim:Section("Silent / fire")
	bool("SilentAim1Enabled", aim, "Silent aim 1", function(v)
		updateFOVCircle()
		silent1PrelockPart = nil
		silent1PrelockUntil = 0
		if v and not (Motion.silentNamecallHook or Motion.silentIndexHook or Motion.silentDirectRayHook) then
			notify("Silent 1: executor has no supported hook API")
		end
	end)
	bool("SilentAim1AutoMouse1", aim, "Silent1 auto mouse")
	slider("SilentAim1AutoMouse1Interval", aim, "Silent1 interval", 0.03, 0.20, 0.01)
	bool("SilentAim2Enabled", aim, "Silent aim 2", function() updateFOVCircle() end)
	bool("TriggerbotEnabled", aim, "Triggerbot")
	slider("TriggerbotRadius", aim, "Triggerbot radius", 6, 60, 1)
	bool("RapidFireEnabled", aim, "Rapid fire")
	slider("RapidFireMultiplier", aim, "Rapid fire multiplier", 1, 100, 1)
	bool("BacklockEnabled", aim, "Backlock")
	bool("ProjectileRedirectEnabled", aim, "Projectile redirector", function(v)
		if setProjectileRedirectEnabled then setProjectileRedirectEnabled(v) end
	end)
	slider("ProjectileRedirectRadius", aim, "Projectile scan radius", 25, 1000, 25)
	slider("ProjectileRedirectStrength", aim, "Projectile redirect speed", 25, 500, 5)
	bool("AdaptiveAimEnabled", aim, "Adaptive aim")
	slider("AdaptiveAimStrength", aim, "Adaptive strength", 0, 100, 1)
	bool("WeaponProfilesEnabled", aim, "Weapon profiles")

	esp:Section("Player visuals")
	bool("VisualsAllPlayers", esp, "Visuals for all players", applyVisualSettings)
	bool("ChamsEnabled", esp, "Chams", applyVisualSettings)
	bool("ChamsTeamColor", esp, "Chams team color", applyVisualSettings)
	bool("ChamsThroughWalls", esp, "Chams through walls", applyVisualSettings)
	slider("ChamsFillTransparency", esp, "Chams transparency", 0.05, 0.95, 0.05, applyVisualSettings)
	window:AddColor(esp, {
		id = "ChamsCustomColor",
		label = "Chams custom color",
		get = function() return colorFromHex(cfg.ChamsCustomColor, Color3.fromRGB(255, 80, 80)) end,
		set = function(v) cfg.ChamsCustomColor = colorToHex(v) end,
		getAlpha = function() return 1 - (cfg.ChamsFillTransparency or 0.45) end,
		setAlpha = function(a) cfg.ChamsFillTransparency = math.clamp(1 - a, 0.05, 0.95) end,
		after = updateChamsColorOnly,
	})
	bool("NameTagsEnabled", esp, "Name tags", applyVisualSettings)
	bool("NameTagTeamColor", esp, "Name tag team color", applyVisualSettings)
	bool("ShowDistance", esp, "Show distance")
	slider("NameTagScale", esp, "Name tag size", 0.70, 1.80, 0.05, applyVisualSettings)
	slider("NameTagMaxScale", esp, "Name tag max size", 0.80, 1.80, 0.05, applyVisualSettings)
	slider("ESPMaxDistance", esp, "ESP max distance", 100, 3000, 50, applyVisualSettings)
	esp:Section("Crosshair")
	bool("CrosshairEnabled", esp, "Crosshair", function() updateFOVCircle() end)
	slider("CrosshairSize", esp, "Crosshair size", 2, 20, 1, function() updateFOVCircle() end)
	slider("CrosshairGap", esp, "Crosshair gap", 1, 12, 1, function() updateFOVCircle() end)

	move:Section("Movement")
	bool("BhopEnabled", move, "Bhop")
	bool("InfiniteJumpEnabled", move, "Infinite jump")
	slider("MoveSpeed", move, "Move speed", 1, 200, 1)
	bool("AutoSprint", move, "Auto sprint")
	bool("NoClipEnabled", move, "NoClip", function(v) if not v then setCharacterCollision(true) end end)
	bool("SpiderEnabled", move, "Spider wall climb")
	slider("SpiderSpeed", move, "Spider speed", 10, 100, 1)
	bool("SlowModeEnabled", move, "Slow mode")
	slider("SlowMoveSpeed", move, "Slow speed", 1, 16, 1)
	slider("JumpPowerValue", move, "Jump power", 1, 300, 1)
	slider("PlayerGravity", move, "Player gravity", 0, 500, 1)
	bool("VerticalFreezeEnabled", move, "Vertical freeze", function(v) if not v then verticalFreezeY = nil end end)
	move:Section("Traversal mechanics")
	bool("FlyEnabled", move, "Camera-direction fly", function(v) if not v then Motion.stopFly() end end)
	slider("FlySpeed", move, "Fly speed", 10, 300, 5)
	slider("FlyAcceleration", move, "Fly acceleration", 1, 30, 1)
	bool("GrappleEnabled", move, "Grappling hook", function(v) if not v then Motion.stopGrapple() end end)
	window:AddButton(move, {
		id = "GrappleAction",
		label = "Grapple action",
		text = "GRAPPLE",
		fire = Motion.startGrapple,
		release = Motion.stopGrapple,
	})
	slider("GrappleRange", move, "Grapple range", 50, 1500, 25)
	slider("GrapplePull", move, "Grapple pull", 20, 300, 5)
	slider("GrappleMaxSpeed", move, "Grapple max speed", 40, 350, 5)
	bool("WallRunEnabled", move, "Wall run")
	slider("WallRunSpeed", move, "Wall run speed", 20, 160, 2)
	slider("WallRunLift", move, "Wall run lift", -10, 40, 1)
	bool("CeilingWalkEnabled", move, "Surface/ceiling walk", function(v) if not v then Motion.stopCeilingWalk() end end)
	window:AddButton(move, {
		id = "CeilingWalkAction",
		label = "Surface walk attach/detach",
		text = "ATTACH",
		fire = Motion.toggleCeilingWalk,
	})
	slider("CeilingWalkSpeed", move, "Surface walk speed", 8, 100, 1)
	slider("CeilingWalkGravity", move, "Surface adhesion", 20, 250, 5)
	bool("SurfaceSurferEnabled", move, "Surface surfer")
	slider("SurfaceSurferSpeed", move, "Surf speed", 20, 180, 2)
	slider("SurfaceSurferAcceleration", move, "Surf acceleration", 10, 250, 5)

	tools:Section("Physics control")
	bool("TelekinesisEnabled", tools, "Telekinesis", function(v) if not v then Motion.releaseTelekinesis(false) end end)
	window:AddButton(tools, {
		id = "TelekinesisAction",
		label = "Telekinesis grab/release",
		text = "GRAB",
		fire = Motion.toggleTelekinesis,
	})
	window:AddButton(tools, {
		id = "TelekinesisThrowAction",
		label = "Telekinesis throw",
		text = "THROW",
		fire = function() Motion.releaseTelekinesis(true) end,
	})
	slider("TelekinesisDistance", tools, "Telekinesis hold distance", 5, 60, 1)
	slider("TelekinesisPower", tools, "Telekinesis throw power", 20, 400, 5)
	slider("TelekinesisMaxMass", tools, "Physics max mass", 10, 1000, 10)
	bool("PhysicsTornadoEnabled", tools, "Physics tornado", function(v)
		if not v then Motion.tornadoActive = false; table.clear(Motion.tornadoParts) end
	end)
	window:AddButton(tools, {
		id = "PhysicsTornadoAction",
		label = "Tornado start/stop",
		text = "TOGGLE",
		fire = function()
			if not cfg.PhysicsTornadoEnabled then return end
			Motion.tornadoActive = not Motion.tornadoActive
			if Motion.tornadoActive then Motion.scanTornado() else table.clear(Motion.tornadoParts) end
		end,
	})
	window:AddButton(tools, {
		id = "PhysicsTornadoBlastAction",
		label = "Tornado blast",
		text = "BLAST",
		fire = Motion.blastTornado,
	})
	slider("PhysicsTornadoRadius", tools, "Tornado radius", 8, 100, 2)
	slider("PhysicsTornadoForce", tools, "Tornado force", 20, 300, 5)
	slider("PhysicsTornadoMaxParts", tools, "Tornado max parts", 4, 60, 1)

	cam:Section("Camera")
	bool("FreecamEnabled", cam, "Freecam", function(v) setFreecam(v) end)
	slider("FreecamSpeed", cam, "Freecam speed", 0.2, 4.0, 0.1)
	slider("FreecamLookSensitivity", cam, "Freecam look sensitivity", 0.05, 0.6, 0.01)
	bool("ThirdPerson", cam, "Third person")
	slider("ThirdPersonDistance", cam, "Third person distance", 4, 30, 1)
	bool("CameraFOVOverride", cam, "Camera FOV override")
	slider("CameraFOVValue", cam, "Camera FOV", 40, 120, 1)
	bool("TiltEnabled", cam, "Model tilt")
	slider("TiltYaw", cam, "Tilt yaw", -180, 180, 1)
	slider("TiltPitch", cam, "Tilt pitch", -85, 85, 1)
	slider("TiltRoll", cam, "Tilt roll", -85, 85, 1)

	world:Section("World")
	bool("Fullbright", world, "Fullbright")
	bool("ClockTimeOverride", world, "ClockTime override")
	slider("ClockTimeValue", world, "ClockTime", 0, 24, 0.5)
	bool("XrayEnabled", world, "World Xray", function() refreshXray() end)
	slider("XrayTransparency", world, "Xray transparency", 0.15, 0.9, 0.05, function() if cfg.XrayEnabled then refreshXray() end end)
	bool("HideLocalCharacter", world, "Hide local character")
	bool("GodModeEnabled", world, "God mode")
	bool("AntiAFK", world, "Anti AFK", function(v)
		if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
		if v then
			antiAfkConn = LocalPlayer.Idled:Connect(function()
				pcall(function()
					local vu = game:GetService("VirtualUser")
					vu:CaptureController()
					vu:ClickButton2(Vector2.new())
				end)
			end)
		end
	end)

	tools:Section("Utility")
	bool("ForwardLaunchEnabled", tools, "Forward launch")
	slider("ForwardLaunchTiltDeg", tools, "Launch tilt", -20, 80, 1)
	slider("ForwardLaunchPower", tools, "Launch power", 30, 260, 5)
	bool("SafeTeleportEnabled", tools, "Safe teleport")
	bool("AutoUnstuckEnabled", tools, "Auto unstuck")
	bool("AutoPeekEnabled", tools, "Auto peek")
	drop("AutoPeekMode", tools, "Auto peek mode", {"Normal", "LagPeek"})
	bool("HitSoundEnabled", tools, "Hit sound")
	drop("HitSoundType", tools, "Hit sound type", {"Bell", "Click", "Bubble", "Custom"})
	window:AddTextBox(tools, {
		id = "HitSoundCustomPath",
		label = "Custom hit sound",
		get = get("HitSoundCustomPath"),
		set = set("HitSoundCustomPath"),
	})
	tools:Section("Actions")
	window:AddButton(tools, {id = "QuickResetButton", label = "Quick reset movement", text = "RESET", fire = quickResetMovement})
	window:AddButton(tools, {id = "TeleportCameraButton", label = "Teleport to camera", text = "TP CAM", fire = teleportToCamera})
	window:AddButton(tools, {id = "SavePositionButton", label = "Save current position", text = "SAVE", fire = saveCurrentPosition})
	window:AddButton(tools, {id = "TeleportSavedButton", label = "Teleport saved position", text = "TP SAVED", fire = teleportToSavedPosition})
	window:AddButton(tools, {id = "ForwardLaunchAction", label = "Run forward launch", text = "LAUNCH", fire = function() runAction("ForwardLaunch") end})
	window:AddButton(tools, {id = "PanicAction", label = "Panic mode", text = "PANIC", fire = function() runAction("PanicToggle") end})

	fun:Section("Movement effects")
	bool("FakeLagPuppetEnabled", fun, "Fake lag puppet")
	slider("FakeLagStep", fun, "Fake lag step", 0.03, 0.30, 0.01)
	bool("BananaDriftEnabled", fun, "Banana drift")
	slider("BananaDriftStrength", fun, "Banana drift strength", 1, 80, 1)
	bool("MoonMagnetEnabled", fun, "Moon magnet")
	slider("MoonMagnetPower", fun, "Moon magnet power", 10, 130, 1)
	bool("HeadHelicopterEnabled", fun, "Head helicopter")
	slider("HeadHelicopterSpeed", fun, "Helicopter speed", 60, 1080, 10)
	bool("PanicStatueEnabled", fun, "Panic statue")
	bool("ReverseDayEnabled", fun, "Reverse day")
	bool("RubberBandDashEnabled", fun, "Rubber band dash")
	slider("RubberBandDashPower", fun, "Rubber dash power", 30, 200, 1)
	bool("FloorIsLavaEnabled", fun, "Floor is lava")
	slider("FloorIsLavaIdleTime", fun, "Lava idle time", 1.0, 6.0, 0.1)
	slider("FloorIsLavaPower", fun, "Lava jump power", 20, 160, 1)
	bool("RandomLeanEnabled", fun, "Random lean")
	slider("RandomLeanRange", fun, "Random lean range", 5, 70, 1)
	bool("ComedicRecoilEnabled", fun, "Comedic recoil")
	slider("ComedicRecoilPower", fun, "Comedic recoil power", 0.5, 10, 0.1)
	bool("MemeModeEnabled", fun, "Meme mode")
	window:AddButton(fun, {id = "RubberDashAction", label = "Run rubber dash", text = "DASH", fire = function() runAction("RubberBandDash") end})
	window:AddButton(fun, {id = "PanicStatueAction", label = "Run panic statue", text = "STATUE", fire = function() runAction("PanicStatue") end})

	playersTab:Section("Player actions")
	local function playerOptions()
		local labels = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local _, humanoid = getCharacterParts(player)
				local health = getPlayerHealth(player, humanoid)
				if health > 0 and resolvePlayerCharacter(player) then
					table.insert(labels, string.format("%s (@%s)", player.DisplayName, player.Name))
				end
			end
		end
		table.sort(labels, function(a, b) return string.lower(a) < string.lower(b) end)
		return labels
	end
	window:AddDropdown(playersTab, {
		id = "SelectedPlayer",
		label = "Player",
		options = playerOptions,
		placeholder = "select player",
		emptyText = "no alive players",
		get = function() return selectedPlayerLabel end,
		set = function(v)
			selectedPlayerLabel = tostring(v or "")
			selectedPlayerName = selectedPlayerLabel:match("@([^%)]+)%)$") or ""
			api:RefreshAll()
		end,
	})
	window:AddButton(playersTab, {id = "PlayerTeleport", label = "Teleport to selected player", text = "TP", fire = function()
		if selectedPlayerName == "" then notify("Select player") return end
		notify(teleportToPlayer(selectedPlayerName) and "Teleported exactly into target" or "Player unavailable")
	end})
	bool("PlayerStickEnabled", playersTab, "Stick to selected player", function(v)
		if v and selectedPlayerName == "" then
			cfg.PlayerStickEnabled = false
			notify("Select player first")
		end
	end)
	slider("PlayerStickInterval", playersTab, "Stick update interval", 0.01, 0.20, 0.01)

	playersTab:Section("Selected player rules")
	window:AddSlider(playersTab, {
		id = "SelectedPlayerPriority",
		label = "Aim priority",
		min = 0,
		max = 100,
		step = 1,
		get = function()
			local player = findPlayerByIdentity(selectedPlayerName)
			return player and getPlayerPriority(player) or 50
		end,
		set = function(v)
			local player = findPlayerByIdentity(selectedPlayerName)
			if player then cfg.PlayerPriorityRules[playerRuleKey(player)] = v end
		end,
	})
	local function selectedESPRuleMode(kind: string): string
		local player = findPlayerByIdentity(selectedPlayerName)
		local rule = player and getPlayerESPRule(player) or nil
		local value = type(rule) == "table" and rule[kind] or nil
		if value == nil then return "Default" end
		return value and "On" or "Off"
	end
	local function setSelectedESPRule(kind: string, mode: string)
		local player = findPlayerByIdentity(selectedPlayerName)
		if not player then return end
		local key = playerRuleKey(player)
		local rule = cfg.PlayerESPRules[key]
		if type(rule) ~= "table" then
			rule = {}
			cfg.PlayerESPRules[key] = rule
		end
		rule[kind] = mode == "Default" and nil or mode == "On"
		if next(rule) == nil then cfg.PlayerESPRules[key] = nil end
		refreshOnePlayer(player)
	end
	window:AddDropdown(playersTab, {
		id = "SelectedPlayerChamsRule",
		label = "Chams rule",
		options = {"Default", "On", "Off"},
		get = function() return selectedESPRuleMode("chams") end,
		set = function(v) setSelectedESPRule("chams", tostring(v)) end,
	})
	window:AddDropdown(playersTab, {
		id = "SelectedPlayerNameTagRule",
		label = "Name tag rule",
		options = {"Default", "On", "Off"},
		get = function() return selectedESPRuleMode("nametags") end,
		set = function(v) setSelectedESPRule("nametags", tostring(v)) end,
	})
	window:AddButton(playersTab, {id = "PlayerRefreshVisuals", label = "Refresh selected player", text = "REFRESH", fire = function()
		local player = findPlayerByIdentity(selectedPlayerName)
		if not player then notify("Select player") return end
		refreshOnePlayer(player)
		notify("Selected player visuals refreshed")
	end})
	window:AddButton(playersTab, {id = "PlayerNearestTarget", label = "Print current aim target", text = "TARGET", fire = function()
		local part = getCurrentAimTargetPart()
		if not part then notify("No target in FOV") return end
		local model = part:FindFirstAncestorOfClass("Model")
		notify("Target: " .. (model and model.Name or part.Name) .. " / " .. part.Name)
	end})
	playersTab:Section("Spectators")
	bool("SpectatorDetectionEnabled", playersTab, "Spectator detection", function()
		lastSpectatorSignature = ""
		api:RefreshAll()
	end)
	window:AddList(playersTab, {
		id = "SpectatorList",
		label = "Confirmed spectators",
		mode = "open",
		height = 104,
		options = getSpectatorLabels,
		emptyText = "none detected",
		get = function() return "" end,
		set = function() end,
	})
	uiTab:Section("Interface")
	slider("UIScaleValue", uiTab, "UI scale", 0.8, 1.35, 0.05, function(v) api:SetScale(v) end)
	bool("UIAnimations", uiTab, "Crosshair animation")
	bool("LowEndMode", uiTab, "Low-end mode")

	for key, value in pairs(cfg) do
		local isRuntimeSetting = type(value) ~= "table" and key ~= "MenuVisible" and key ~= "PanicMode"
		if isRuntimeSetting and not boundCfg[key] then
			warn("[AETHER] cfg has no menu control: " .. tostring(key))
		end
	end
	if api.Controls then
		for key in pairs(boundCfg) do
			if not api.Controls[key] then
				warn("[AETHER] menu control was not registered: " .. tostring(key))
			end
		end
	end

	api:RefreshAll()
	setMenuVisible(cfg.MenuVisible)
	notify("AETHER V7 menu API loaded")
end

bootAetherMenuApi()
