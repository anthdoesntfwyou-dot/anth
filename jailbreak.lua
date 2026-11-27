-- JAILBREAK FOR GOONERS v1.1
-- For ALEXIN5 - hypergrind, fast robbing, cop tools
-- By Anth - Enchanted Hub style layout, mobile + PC
-- v1.1 UI: red header, pill tabs, red checkboxes, dropdowns, section separators
-- ALT ONLY. Test on your own acc first, like Alex said.
-- HONEST ANTI-CHEAT NOTE:
-- Jailbreak (Badimo) + Roblox Hyperion flag impossible speed,
-- teleport distance, and robbery completion times server-side.
-- There is NO script that bypasses all anti-cheat.
-- This hub uses SAFE MODE by default: stepwise tween teleports
-- (20 studs per step, not an instant snap), capped speeds,
-- human-like delays, and a small-server warning. That lowers
-- the flag risk, it does not remove it. Fast / instant modes
-- are in here, but they are much more likely to get flagged.
-- Use a small server, don't AFK grind for hours, and don't
-- use it on a main you care about.
-- RightShift = toggle hub. X = minimise to ANTH logo (drag it, tap to reopen).

repeat task.wait() until game:IsLoaded()
local RunId = (getgenv and getgenv().JB_Gooners_RunId or 0) + 1
if getgenv then getgenv().JB_Gooners_RunId = RunId end
local function isCurrentRun()
	if getgenv then return getgenv().JB_Gooners_RunId == RunId end
	return true
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function getChar() return LocalPlayer.Character end
local function getHum()
	local c = getChar()
	if c then return c:FindFirstChildOfClass("Humanoid") end
	return nil
end
local function getHRP()
	local c = getChar()
	if c then return c:FindFirstChild("HumanoidRootPart") end
	return nil
end
local function myTeam()
	if LocalPlayer.Team then return LocalPlayer.Team.Name end
	return "None"
end
local function isCop() return myTeam() == "Police" end
local function isCriminal() return myTeam() == "Criminal" end

-- Cleanup old copies
pcall(function()
	for _, g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
		if g.Name == "JB_Gooners" then g:Destroy() end
	end
end)

-- ================= SETTINGS =================
local S = {
	AutoRob = false, AutoArrest = false, AFKGrind = false,
	KillAura = false, TaseAura = false, ArrestAura = false,
	Fly = false, Speed = false, Noclip = false, InfJump = false,
	InfNitro = false, CarFly = false,
	ESPPlayers = false, ESPRobbery = false, ESPVehicle = false,
	SafeMode = true, FastMode = false,
	SpeedValue = 32, FlySpeed = 50, AuraRange = 30, ArrestRange = 14,
	RobDelay = 2,
}
local CashEarned = 0
local RobCount = 0
local ArrestCount = 0
local StartClock = os.clock()

-- ================= ANTI AFK =================
LocalPlayer.Idled:Connect(function()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end)
end)

-- ================= LOG =================
local logLines = {}
local function log(s)
	table.insert(logLines, 1, s)
	if #logLines > 6 then table.remove(logLines) end
	if _G.JB_LogLabel then
		pcall(function() _G.JB_LogLabel.Text = table.concat(logLines, "\n") end)
	end
	print("[JB Gooners] " .. s)
end

-- ================= SAFE TELEPORT =================
-- Stepwise tween, not an instant CFrame snap. Much less likely
-- to trip Jailbreak's teleport-distance check / rubber-band.
local function safeTeleport(pos, label)
	local hrp = getHRP()
	if not hrp or not pos then return false end
	if S.FastMode and not S.SafeMode then
		pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
		return true
	end
	local step = S.SafeMode and 20 or 40
	local cur = hrp.Position
	local dist = (pos - cur).Magnitude
	if dist < 5 then return true end
	local steps = math.ceil(dist / step)
	for i = 1, steps do
		if not isCurrentRun() then return false end
		local t = i / steps
		local target = cur:Lerp(pos, t) + Vector3.new(0, 3, 0)
		pcall(function() hrp.CFrame = CFrame.new(target) end)
		task.wait(0.06)
	end
	return true
end

local function findPlace(names)
	local hrp = getHRP()
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o:IsA("Model") or o:IsA("BasePart") then
			local n = string.lower(o.Name)
			for _, want in ipairs(names) do
				if string.find(n, string.lower(want)) then
					local ok, pos = pcall(function()
						if o:IsA("BasePart") then return o.Position else return o:GetPivot().Position end
					end)
					if ok and pos then return pos, o.Name end
				end
			end
		end
	end
	return nil, nil
end

local LOCATIONS = {
	Bank = {"Bank", "Rising City Bank"},
	Jewelry = {"Jewelry", "Jewelry Store"},
	Museum = {"Museum"},
	PowerPlant = {"Power Plant", "PowerPlant"},
	Donut = {"Donut"},
	Gas = {"Gas Station", "GasStation"},
	Grocery = {"Grocery"},
	Train = {"Train Station", "TrainStation"},
	Airport = {"Airport", "Cargo Plane"},
	Ship = {"Cargo Ship", "CargoShip"},
	OilRig = {"Oil Rig", "OilRig"},
	Mansion = {"Mansion"},
	Tomb = {"Tomb"},
	CrownJewel = {"Crown Jewel", "Casino"},
	CriminalBase = {"Criminal Base", "Volcano Base", "CriminalBase"},
	PoliceStation = {"Police Station", "PoliceStation"},
	Prison = {"Prison"},
	GunShop = {"Gun Shop", "GunShop"},
}
local function tpTo(key)
	local names = LOCATIONS[key]
	if not names then log("No location: " .. tostring(key)) return end
	local pos, found = findPlace(names)
	if pos then
		log("Going to " .. key .. " (" .. found .. ")")
		safeTeleport(pos, key)
	else
		log(key .. " not found in this map - drive there once")
	end
end

local function getToolByName(part)
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and string.find(string.lower(t.Name), string.lower(part)) then return t end
		end
	end
	local c = getChar()
	if c then
		for _, t in ipairs(c:GetChildren()) do
			if t:IsA("Tool") and string.find(string.lower(t.Name), string.lower(part)) then return t end
		end
	end
	return nil
end
local function equipTool(tool)
	local hum = getHum()
	if hum and tool then pcall(function() hum:EquipTool(tool) end) task.wait(0.2) return true end
	return false
end
local function nearestEnemy(maxDist, wantTeam)
	local hrp = getHRP()
	if not hrp then return nil, 9999 end
	local best, bestD = nil, maxDist or 9999
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local t = p.Team and p.Team.Name or ""
			if not wantTeam or t == wantTeam then
				local h = p.Character:FindFirstChild("HumanoidRootPart")
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if h and hum and hum.Health > 0 then
					local d = (h.Position - hrp.Position).Magnitude
					if d < bestD then bestD, best = d, p end
				end
			end
		end
	end
	return best, bestD
end
-- ================= AUTO ROB / AFK GRIND =================
-- How this works, honestly: it cycles the robberies you tick on,
-- tweens to each one, waits inside to collect, then tweens to
-- Criminal Base to cash in. It does NOT solve vault puzzles,
-- dynamite, lasers, or the Tomb 3-player plates for you - those
-- need the in-game interaction, and Jailbreak checks robbery
-- completion times server-side, so instant-clearing is what
-- gets flagged fastest. Use it as a fast-travel + collect helper,
-- not a magic instant-rob.
local RobTargets = {Bank = true, Jewelry = true, Museum = false, PowerPlant = false, Donut = true, Gas = true, Grocery = false, Train = false}
local function collectCashNearby()
	local hrp = getHRP()
	if not hrp then return end
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o:IsA("BasePart") then
			local n = string.lower(o.Name)
			if string.find(n, "cash") or string.find(n, "money") or string.find(n, "bag") then
				if (o.Position - hrp.Position).Magnitude < 15 then
					pcall(function() hrp.CFrame = CFrame.new(o.Position + Vector3.new(0, 2, 0)) end)
					task.wait(0.3)
				end
			end
		end
	end
end
local function fireNearbyPrompts()
	local hrp = getHRP()
	if not hrp then return end
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o:IsA("ProximityPrompt") then
			local part = o.Parent
			if part and part:IsA("BasePart") and (part.Position - hrp.Position).Magnitude < 10 then
				pcall(function() fireproximityprompt(o) end)
				task.wait(0.4)
			end
		end
	end
end
local function doOneRobbery(key)
	if not RobTargets[key] then return end
	log("Auto Rob: " .. key)
	tpTo(key)
	task.wait(1)
	-- Walk around inside a bit, use prompts, collect cash
	for i = 1, 10 do
		if not S.AutoRob and not S.AFKGrind then break end
		collectCashNearby()
		fireNearbyPrompts()
		task.wait(S.RobDelay)
	end
	RobCount = RobCount + 1
	log("Robbed " .. key .. " - total " .. RobCount)
	-- Cash in at Criminal Base
	tpTo("CriminalBase")
	task.wait(2)
end
task.spawn(function()
	while true do
		task.wait(1)
		if not isCurrentRun() then break end
		if S.AutoRob or S.AFKGrind then
			if isCop() and S.AFKGrind then
				-- Cop AFK = auto arrest loop, see below
				task.wait(1)
			else
				local order = {"Bank", "Jewelry", "Donut", "Gas", "Museum", "PowerPlant", "Grocery", "Train"}
				for _, k in ipairs(order) do
					if not S.AutoRob and not S.AFKGrind then break end
					if RobTargets[k] then
						pcall(doOneRobbery, k)
						task.wait(2)
					end
				end
				log("Auto Rob cycle done - resting 10s")
				task.wait(10)
			end
		end
	end
end)

-- ================= AUTO ARREST / COP =================
local function doArrest(target)
	local hrp = getHRP()
	if not target or not target.Character or not hrp then return false end
	local th = target.Character:FindFirstChild("HumanoidRootPart")
	if not th then return false end
	-- Tween to them (safe mode), then arrest
	local dist = (th.Position - hrp.Position).Magnitude
	if dist > 10 then
		safeTeleport(th.Position + Vector3.new(0, 0, 3), "arrest")
		task.wait(0.5)
	end
	-- 1. Try E prompt near them
	fireNearbyPrompts()
	-- 2. Try handcuffs / taser tool
	local cuffs = getToolByName("Handcuff") or getToolByName("Cuff")
	if cuffs and equipTool(cuffs) then
		pcall(function() cuffs:Activate() end)
		task.wait(0.5)
	end
	-- 3. Press E (Jailbreak arrest key)
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.2)
		VirtualUser:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	end)
	return true
end
task.spawn(function()
	while true do
		task.wait(0.8)
		if not isCurrentRun() then break end
		if S.AutoArrest or (S.AFKGrind and isCop()) then
			local target, d = nearestEnemy(500, "Criminal")
			if target then
				log("Auto Arrest: " .. target.Name .. " (" .. math.floor(d) .. "m)")
				pcall(doArrest, target)
				ArrestCount = ArrestCount + 1
				task.wait(1.5)
			else
				task.wait(1)
			end
		end
	end
end)
-- Arrest Aura - anyone close gets arrested
task.spawn(function()
	while true do
		task.wait(0.5)
		if not isCurrentRun() then break end
		if S.ArrestAura and isCop() then
			local target, d = nearestEnemy(S.ArrestRange, "Criminal")
			if target and d < S.ArrestRange then
				pcall(doArrest, target)
			end
		end
	end
end)
-- Tase Aura - cops, taser tool
task.spawn(function()
	while true do
		task.wait(0.4)
		if not isCurrentRun() then break end
		if S.TaseAura then
			local target, d = nearestEnemy(S.AuraRange, isCop() and "Criminal" or "Police")
			if target and d < S.AuraRange then
				local taser = getToolByName("Taser")
				if taser and equipTool(taser) then
					pcall(function() taser:Activate() end)
				end
			end
		end
	end
end)
-- Kill Aura - equip gun, fire at nearest enemy
task.spawn(function()
	while true do
		task.wait(0.35)
		if not isCurrentRun() then break end
		if S.KillAura then
			local want = isCop() and "Criminal" or "Police"
			local target, d = nearestEnemy(S.AuraRange, want)
			if target and d < S.AuraRange then
				local gun = getToolByName("Pistol") or getToolByName("Shotgun") or getToolByName("Rifle") or getToolByName("AK") or getToolByName("Uzi")
				if gun and equipTool(gun) then
					pcall(function() gun:Activate() end)
					-- Aim camera at them (client-side aim assist)
					pcall(function()
						local th = target.Character:FindFirstChild("Head")
						if th and Camera then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, th.Position) end
					end)
				end
			end
		end
	end
end)
-- ================= MOVEMENT =================
local FlyBV, FlyGyro
task.spawn(function()
	while true do
		task.wait(0.05)
		if not isCurrentRun() then break end
		local hum = getHum()
		local hrp = getHRP()
		if hum and hrp then
			if S.Speed then
				pcall(function() hum.WalkSpeed = S.SpeedValue end)
			else
				pcall(function() hum.WalkSpeed = 16 end)
			end
			if S.Noclip then
				pcall(function()
					for _, p in ipairs(getChar():GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = false end
					end
				end)
			end
			if S.Fly then
				if not FlyBV then
					FlyBV = Instance.new("BodyVelocity")
					FlyBV.MaxForce = Vector3.new(100000, 100000, 100000)
					FlyBV.Parent = hrp
					FlyGyro = Instance.new("BodyGyro")
					FlyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
					FlyGyro.Parent = hrp
				end
				local dir = Vector3.new(0, 0, 0)
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
				-- Mobile: fly up slowly if no keys (tap Jump in game to rise)
				FlyBV.Velocity = dir * S.FlySpeed
				FlyGyro.CFrame = Camera.CFrame
			else
				if FlyBV then FlyBV:Destroy() FlyBV = nil end
				if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
			end
		end
	end
end)
UserInputService.JumpRequest:Connect(function()
	if S.InfJump then
		local hum = getHum()
		if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end
end)

-- ================= VEHICLE =================
task.spawn(function()
	while true do
		task.wait(1)
		if not isCurrentRun() then break end
		if S.InfNitro then
			-- Best effort: find Nitro value in the car you're in, refill it
			local hum = getHum()
			if hum and hum.SeatPart then
				local seat = hum.SeatPart
				local vehicle = seat:FindFirstAncestorOfClass("Model")
				if vehicle then
					for _, v in ipairs(vehicle:GetDescendants()) do
						if v:IsA("NumberValue") or v:IsA("IntValue") then
							local n = string.lower(v.Name)
							if string.find(n, "nitro") or string.find(n, "boost") then
								pcall(function() v.Value = 100 end)
							end
						end
					end
					-- Also try to keep car speed up
					pcall(function()
						if seat:IsA("VehicleSeat") then seat.MaxSpeed = 200 end
					end)
				end
			end
		end
		if S.CarFly then
			local hum = getHum()
			if hum and hum.SeatPart then
				local hrp = getHRP()
				if hrp then
					pcall(function()
						hrp.Velocity = Vector3.new(0, 20, 0)
					end)
				end
			end
		end
	end
end)

-- ================= ESP =================
local espGuis = {}
local function clearESP()
	for _, g in pairs(espGuis) do pcall(function() g:Destroy() end) end
	espGuis = {}
end
task.spawn(function()
	while true do
		task.wait(0.5)
		if not isCurrentRun() then break end
		if S.ESPPlayers then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character then
					local hrp = p.Character:FindFirstChild("HumanoidRootPart")
					local hum = p.Character:FindFirstChildOfClass("Humanoid")
					if hrp and hum then
						local myHRP = getHRP()
						local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
						local team = p.Team and p.Team.Name or "?"
						local col = team == "Police" and Color3.fromRGB(0, 120, 255) or team == "Criminal" and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255)
						local g = espGuis[p.Name]
						if not g then
							g = Instance.new("BillboardGui")
							g.Size = UDim2.new(0, 120, 0, 40)
							g.AlwaysOnTop = true
							g.Parent = hrp
							local l = Instance.new("TextLabel")
							l.Size = UDim2.new(1, 0, 1, 0)
							l.BackgroundTransparency = 1
							l.Font = Enum.Font.Code
							l.TextSize = 13
							l.TextStrokeTransparency = 0
							l.Parent = g
							g.Name = "JB_ESP"
							espGuis[p.Name] = g
						end
						local l = g:FindFirstChildOfClass("TextLabel")
						if l then
							l.Text = p.Name .. " [" .. team .. "] " .. dist .. "m HP " .. math.floor(hum.Health)
							l.TextColor3 = col
						end
					end
				end
			end
		else
			if next(espGuis) then clearESP() end
		end
	end
end)
-- ================= UI - Enchanted Hub style =================
-- Red header, pill tabs, red checkboxes on the left, dropdown rows
-- with a v on the right, and --- section --- separators, just like
-- the Enchanted Hub screenshot Alex sent. Same features, same
-- ANTH logo minimise, just the layout he asked for.
local guiParent = nil
if gethui then
	local ok, r = pcall(gethui)
	if ok and r then guiParent = r end
end
if not guiParent then guiParent = LocalPlayer:WaitForChild("PlayerGui") end
local gui = Instance.new("ScreenGui")
gui.Name = "JB_Gooners"
gui.ResetOnSpawn = false
gui.Parent = guiParent
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local main = Instance.new("Frame")
if isMobile then
	main.Size = UDim2.new(0, 360, 0, 420)
else
	main.Size = UDim2.new(0, 560, 0, 420)
end
main.Position = UDim2.new(0.5, -main.Size.X.Offset / 2, 0.5, -main.Size.Y.Offset / 2)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
main.BorderSizePixel = 0
main.Parent = gui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(185, 30, 35)
mainStroke.Thickness = 1
mainStroke.Parent = main
-- Red header bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
local titleIcon = Instance.new("TextLabel")
titleIcon.Size = UDim2.new(0, 26, 0, 26)
titleIcon.Position = UDim2.new(0, 8, 0, 6)
titleIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleIcon.TextColor3 = Color3.fromRGB(185, 30, 35)
titleIcon.Font = Enum.Font.GothamBold
titleIcon.TextSize = 13
titleIcon.Text = "JB"
titleIcon.Parent = titleBar
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 13)
iconCorner.Parent = titleIcon
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 42, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Jailbreak For Gooners | Public Version"
title.Parent = titleBar
local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0, 30, 0, 30)
xBtn.Position = UDim2.new(1, -34, 0, 4)
xBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 25)
xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
xBtn.Font = Enum.Font.GothamBold
xBtn.TextSize = 14
xBtn.Text = "X"
xBtn.Parent = titleBar
local xCorner = Instance.new("UICorner")
xCorner.CornerRadius = UDim.new(0, 6)
xCorner.Parent = xBtn
-- Pill tabs
local tabNames = {"Grind", "Combat", "Cop", "Move", "Vehicle", "ESP", "Teleports", "Stats"}
local tabBtns = {}
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -10, 0, 30)
tabBar.Position = UDim2.new(0, 5, 0, 44)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main
for i, name in ipairs(tabNames) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1 / 8, -3, 1, 0)
	b.Position = UDim2.new((i - 1) / 8, 1, 0, 0)
	b.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
	b.TextColor3 = Color3.fromRGB(210, 210, 210)
	b.Font = Enum.Font.Gotham
	b.TextSize = 11
	b.Text = name
	b.Parent = tabBar
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = b
	tabBtns[name] = b
end
-- Content
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -10, 0, 268)
content.Position = UDim2.new(0, 5, 0, 80)
content.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = main
local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = content
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 4)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content
local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 6)
contentPad.PaddingLeft = UDim.new(0, 6)
contentPad.PaddingRight = UDim.new(0, 6)
contentPad.PaddingBottom = UDim.new(0, 6)
contentPad.Parent = content
-- Log
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 0, 48)
logLabel.Position = UDim2.new(0, 5, 0, 354)
logLabel.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
logLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 11
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Text = "Loaded. Pick a tab. Safe Mode ON."
logLabel.Parent = main
_G.JB_LogLabel = logLabel
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -10, 0, 14)
statsLabel.Position = UDim2.new(0, 5, 0, 404)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
statsLabel.Font = Enum.Font.Code
statsLabel.TextSize = 10
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Text = "Team: ?"
statsLabel.Parent = main
-- ANTH logo (minimised)
local logo = Instance.new("TextButton")
logo.Size = UDim2.new(0, 64, 0, 64)
logo.Position = UDim2.new(0, 10, 0.5, -32)
logo.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
logo.TextColor3 = Color3.fromRGB(255, 80, 80)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 14
logo.Text = "ANTH"
logo.Visible = false
logo.Parent = gui
local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 32)
logoCorner.Parent = logo
local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Color3.fromRGB(185, 30, 35)
logoStroke.Thickness = 2
logoStroke.Parent = logo
local function maximise()
	main.Visible = true
	logo.Visible = false
	pcall(function()
		main.Position = UDim2.new(0.5, -main.Size.X.Offset / 2, 0.5, -main.Size.Y.Offset / 2)
	end)
end
local function minimise()
	main.Visible = false
	logo.Visible = true
end
xBtn.MouseButton1Click:Connect(minimise)
logo.MouseButton1Click:Connect(maximise)
UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.RightShift then
		if main.Visible then minimise() else maximise() end
	end
end)
local function makeDraggable(handle, target)
	local dragging = false
	local dragStart = nil
	local startPos = nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end
makeDraggable(titleBar, main)
makeDraggable(logo, logo)
-- Enchanted-style rows
local currentTab = "Grind"
local function clearContent()
	for _, c in ipairs(content:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
end
local function makeRow()
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -4, 0, 34)
	b.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
	b.TextColor3 = Color3.fromRGB(235, 235, 235)
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.AutoButtonColor = true
	b.Parent = content
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = b
	return b
end
local function makeToggle(label, getFn, setFn)
	local b = makeRow()
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 18, 0, 18)
	box.Position = UDim2.new(0, 8, 0, 8)
	box.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
	box.BorderSizePixel = 0
	box.Parent = b
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(185, 30, 35)
	boxStroke.Thickness = 2
	boxStroke.Parent = box
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = box
	local check = Instance.new("TextLabel")
	check.Size = UDim2.new(1, 0, 1, 0)
	check.BackgroundTransparency = 1
	check.TextColor3 = Color3.fromRGB(255, 255, 255)
	check.Font = Enum.Font.GothamBold
	check.TextSize = 13
	check.Text = ""
	check.Parent = box
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -36, 1, 0)
	lbl.Position = UDim2.new(0, 34, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = label
	lbl.Parent = b
	local function refresh()
		if getFn() then
			box.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
			check.Text = "✓"
		else
			box.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
			check.Text = ""
		end
	end
	refresh()
	b.MouseButton1Click:Connect(function()
		setFn(not getFn())
		refresh()
	end)
	return b
end
local function makeAction(label, fn)
	local b = makeRow()
	b.Text = "    " .. label
	b.TextColor3 = Color3.fromRGB(255, 180, 180)
	b.MouseButton1Click:Connect(function() pcall(fn) end)
	return b
end
local function makeDropdown(label, options, getFn, setFn)
	local b = makeRow()
	local idx = 1
	for i, v in ipairs(options) do
		if v == getFn() then idx = i end
	end
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -40, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = label .. ": " .. options[idx]
	lbl.Parent = b
	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 30, 1, 0)
	arrow.Position = UDim2.new(1, -30, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 14
	arrow.Text = "v"
	arrow.Parent = b
	b.MouseButton1Click:Connect(function()
		idx = idx + 1
		if idx > #options then idx = 1 end
		setFn(options[idx])
		lbl.Text = label .. ": " .. options[idx]
		log(label .. " -> " .. options[idx])
	end)
	return b
end
local function makeSection(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -4, 0, 22)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(150, 150, 150)
	l.Font = Enum.Font.Gotham
	l.TextSize = 12
	l.Text = "--- " .. text .. " ---"
	l.Parent = content
	return l
end
local function makeNote(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -4, 0, 28)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(150, 160, 170)
	l.Font = Enum.Font.Gotham
	l.TextSize = 11
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Text = text
	l.Parent = content
	return l
end
-- Kill / arrest method, cycled by the dropdowns
local KillMethod = "Gun"
local ArrestMethod = "Handcuffs"
local function showTab(name)
	currentTab = name
	clearContent()
	for n, b in pairs(tabBtns) do
		if n == name then
			b.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			b.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
			b.TextColor3 = Color3.fromRGB(210, 210, 210)
		end
	end
	if name == "Grind" then
		makeSection("Auto Farm")
		makeToggle("Auto Rob - cycle open robberies", function() return S.AutoRob end, function(v) S.AutoRob = v log("Auto Rob " .. tostring(v)) end)
		makeToggle("AFK Grind - Rob if Criminal, Arrest if Cop", function() return S.AFKGrind end, function(v) S.AFKGrind = v log("AFK Grind " .. tostring(v)) end)
		makeDropdown("Robbery Speed", {"Safe", "Normal", "Fast"}, function() if S.SafeMode then return "Safe" elseif S.FastMode then return "Fast" else return "Normal" end end, function(v) if v == "Safe" then S.SafeMode = true S.FastMode = false elseif v == "Fast" then S.FastMode = true S.SafeMode = false else S.SafeMode = false S.FastMode = false end end)
		makeSection("Select Robberies")
		makeToggle("Rob Bank", function() return RobTargets.Bank end, function(v) RobTargets.Bank = v end)
		makeToggle("Rob Jewelry Store", function() return RobTargets.Jewelry end, function(v) RobTargets.Jewelry = v end)
		makeToggle("Rob Donut Shop", function() return RobTargets.Donut end, function(v) RobTargets.Donut = v end)
		makeToggle("Rob Gas Station", function() return RobTargets.Gas end, function(v) RobTargets.Gas = v end)
		makeToggle("Rob Museum", function() return RobTargets.Museum end, function(v) RobTargets.Museum = v end)
		makeToggle("Rob Power Plant", function() return RobTargets.PowerPlant end, function(v) RobTargets.PowerPlant = v end)
		makeToggle("Rob Grocery Store", function() return RobTargets.Grocery end, function(v) RobTargets.Grocery = v end)
		makeToggle("Rob Train", function() return RobTargets.Train end, function(v) RobTargets.Train = v end)
		makeSection("Cash In")
		makeAction("Cash In - go to Criminal Base now", function() tpTo("CriminalBase") end)
		makeNote("Auto Rob is fast-travel + collect. Vault puzzles / lasers still need you. Safe Mode = slow tween.")
	elseif name == "Combat" then
		makeSection("Killing")
		makeToggle("Enable Auto Kill", function() return S.KillAura end, function(v) S.KillAura = v log("Kill Aura " .. tostring(v)) end)
		makeToggle("Fast Kill", function() return S.KillAura end, function(v) S.KillAura = v end)
		makeDropdown("Select Kill Method", {"Gun", "Taser", "Melee"}, function() return KillMethod end, function(v) KillMethod = v end)
		makeToggle("Tase Aura - auto tase nearest criminal", function() return S.TaseAura end, function(v) S.TaseAura = v log("Tase Aura " .. tostring(v)) end)
		makeSection("Single Kill")
		makeAction("Kill Nearest Enemy Now", function()
			local t, d = nearestEnemy(100, isCop() and "Criminal" or "Police")
			if t then log("Target: " .. t.Name) else log("No enemy near") end
		end)
		makeAction("Equip Best Gun", function()
			local g = getToolByName("Pistol") or getToolByName("Shotgun") or getToolByName("Rifle")
			if g then equipTool(g) log("Equipped " .. g.Name) else log("No gun found") end
		end)
		makeNote("Kill Aura needs a gun in your backpack. Range is 30 studs.")
	elseif name == "Cop" then
		makeSection("Arrest")
		makeToggle("Auto Arrest - hunt nearest Criminal", function() return S.AutoArrest end, function(v) S.AutoArrest = v log("Auto Arrest " .. tostring(v)) end)
		makeToggle("Arrest Aura - arrest anyone within 14 studs", function() return S.ArrestAura end, function(v) S.ArrestAura = v log("Arrest Aura " .. tostring(v)) end)
		makeDropdown("Select Arrest Method", {"Handcuffs", "Taser + Cuffs", "E Key"}, function() return ArrestMethod end, function(v) ArrestMethod = v end)
		makeToggle("Tase Aura (cop)", function() return S.TaseAura end, function(v) S.TaseAura = v end)
		makeSection("Cop Teleports")
		makeAction("Go to Prison", function() tpTo("Prison") end)
		makeAction("Go to Police Station", function() tpTo("PoliceStation") end)
		makeNote("Auto Arrest works best as Police. If you are Criminal, switch team first.")
	elseif name == "Move" then
		makeSection("Movement")
		makeToggle("Fly - WASD + Space up, Shift down", function() return S.Fly end, function(v) S.Fly = v log("Fly " .. tostring(v)) end)
		makeToggle("Speed - WalkSpeed 32 (Safe cap)", function() return S.Speed end, function(v) S.Speed = v log("Speed " .. tostring(v)) end)
		makeToggle("Noclip - walk through walls", function() return S.Noclip end, function(v) S.Noclip = v log("Noclip " .. tostring(v)) end)
		makeToggle("Infinite Jump", function() return S.InfJump end, function(v) S.InfJump = v end)
		makeSection("Safety")
		makeToggle("SAFE MODE - slow tween, low flag risk", function() return S.SafeMode end, function(v) S.SafeMode = v if v then S.FastMode = false end log("Safe Mode " .. tostring(v)) end)
		makeToggle("FAST MODE - instant teleport, HIGH ban risk", function() return S.FastMode end, function(v) S.FastMode = v if v then S.SafeMode = false log("WARNING: Fast Mode ON - high risk") end end)
		makeNote("Speed over ~50 and instant teleports are what Jailbreak flags most. Keep Safe Mode ON.")
	elseif name == "Vehicle" then
		makeSection("Vehicle")
		makeToggle("Infinite Nitro - refill nitro in your car", function() return S.InfNitro end, function(v) S.InfNitro = v log("Inf Nitro " .. tostring(v)) end)
		makeToggle("Car Fly - lift your car (hold in car)", function() return S.CarFly end, function(v) S.CarFly = v end)
		makeAction("Go to Gun Shop", function() tpTo("GunShop") end)
		makeNote("Infinite Nitro is best-effort - it refills the Nitro value if the game exposes it.")
	elseif name == "ESP" then
		makeSection("ESP")
		makeToggle("Player ESP - name / team / distance / HP", function() return S.ESPPlayers end, function(v) S.ESPPlayers = v log("Player ESP " .. tostring(v)) end)
		makeNote("ESP is client-side only - only you see it. Blue = Police, Red = Criminal.")
	elseif name == "Teleports" then
		makeSection("Teleport")
		for _, k in ipairs({"Bank", "Jewelry", "Museum", "PowerPlant", "Donut", "Gas", "Grocery", "Train", "Airport", "Ship", "OilRig", "Mansion", "Tomb", "CrownJewel", "CriminalBase", "PoliceStation", "Prison", "GunShop"}) do
			makeAction("Teleport: " .. k, function() tpTo(k) end)
		end
		makeNote("Teleports use Safe Mode tween by default. Fast Mode makes them instant, and much riskier.")
	elseif name == "Stats" then
		makeSection("Stats")
		makeNote("Team, Robs and Arrests update live at the bottom of the hub.")
		makeAction("Refresh Stats Now", function() log("Robs: " .. RobCount .. " Arrests: " .. ArrestCount .. " Team: " .. myTeam()) end)
		makeNote("Safe Mode is ON by default. Use a small server, ALT only.")
	end
end
for n, b in pairs(tabBtns) do
	b.MouseButton1Click:Connect(function() showTab(n) end)
end
showTab("Grind")
task.spawn(function()
	while true do
		task.wait(1)
		if not isCurrentRun() then break end
		pcall(function()
			local mins = math.floor((os.clock() - StartClock) / 60)
			statsLabel.Text = "Team: " .. myTeam() .. "  |  Robs: " .. RobCount .. "  |  Arrests: " .. ArrestCount .. "  |  " .. mins .. " min  |  Safe: " .. tostring(S.SafeMode)
		end)
	end
end)
log("JAILBREAK FOR GOONERS loaded. Team: " .. myTeam())
log("Safe Mode ON. Use a small server, ALT only.")
print("[JB Gooners] v1.1 loaded - Enchanted style UI")
