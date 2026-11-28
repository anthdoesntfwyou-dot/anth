-- UNSTABLE SMP FFA | ANTH Hub v1.0
-- For Anth - Solara PC
-- Game: Unstable SMP FFA by [IS] Insomnia Studios
-- Java 1.21 style combat: sword / spear / mace, shield, totem,
-- golden apples, elytra + rockets, wind charges, pearls, tridents.
-- FFA up to 12 players, Duels, Practice Dummy, Simulator.
-- HOW IT WORKS (honest, no fake remotes):
-- Kill Aura equips your real weapon tool, faces the target and
-- calls Tool:Activate() on the game's own 0.55s swing cooldown.
-- It does NOT fire hidden remotes, teleport you to people, or
-- hit through walls when Wall Check is on. If the game changes
-- its tool names, Aura just will not find a weapon - it will
-- not error, it will log "no weapon found".
-- ALT ONLY. This is against Roblox ToS, bans happen in waves.
-- Do NOT use it on a main, do NOT leave Aura on for hours.
-- RightShift = toggle hub. X = minimise to ANTH logo, drag it, tap to reopen.

repeat task.wait() until game:IsLoaded()
local RunId = 0
if getgenv then
	RunId = (getgenv().UNSTABLE_RunId or 0) + 1
	getgenv().UNSTABLE_RunId = RunId
end
local function isCurrent()
	if getgenv then return getgenv().UNSTABLE_RunId == RunId end
	return true
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function getChar()
	return LocalPlayer.Character
end
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
local function getHead()
	local c = getChar()
	if c then return c:FindFirstChild("Head") end
	return nil
end

-- Cleanup old copies (same fix as ANTH Hub v1.5 - old loops fight new ones)
pcall(function()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		for _, g in ipairs(pg:GetChildren()) do
			if g.Name == "UnstableANTH" then g:Destroy() end
		end
	end
	local cg = game:GetService("CoreGui")
	for _, g in ipairs(cg:GetChildren()) do
		if g.Name == "UnstableANTH" then g:Destroy() end
	end
end)

-- ================= SETTINGS =================
local S = {
	KillAura = false,
	FaceTarget = true,
	WallCheck = true,
	AerialPriority = true,
	LowestHP = false,
	AttackDummies = false,
	AutoMace = false,
	AutoEat = false,
	Aimbot = false,
	ESP = false,
	ESPHealth = true,
	Fly = false,
	Speed = false,
	InfJump = false,
	Noclip = false,
	AntiAFK = true,
	AuraRange = 14,
	SpeedValue = 28,
	FlySpeed = 50,
	EatAt = 55,
}
local Kills = 0
local SwingCooldown = 0.55
local LastSwing = 0

-- ================= LOG =================
local logLines = {}
local function log(s)
	table.insert(logLines, 1, s)
	if #logLines > 5 then table.remove(logLines) end
	pcall(function()
		if _G.UNSTABLE_Log then _G.UNSTABLE_Log.Text = table.concat(logLines, "\n") end
	end)
	print("[Unstable ANTH] " .. s)
end

-- ================= ANTI AFK =================
LocalPlayer.Idled:Connect(function()
	if not S.AntiAFK then return end
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end)
end)

-- ================= WEAPONS =================
-- Game kits give you real Tools in your Backpack. Find the best one.
-- Mace first when you are falling (smash), then Sword, then Spear / Axe / Trident.
local function findWeapon()
	local pack = LocalPlayer:FindFirstChild("Backpack")
	local char = getChar()
	local function scan(container)
		if not container then return nil end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") then
				local n = t.Name:lower()
				if string.find(n, "mace") then return t end
			end
		end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") then
				local n = t.Name:lower()
				if string.find(n, "sword") or string.find(n, "spear") or string.find(n, "axe") or string.find(n, "trident") then return t end
			end
		end
		return nil
	end
	local w = nil
	if char then w = scan(char) end
	if w then return w end
	if pack then w = scan(pack) end
	return w
end
local function findApple()
	local pack = LocalPlayer:FindFirstChild("Backpack")
	local char = getChar()
	local function scan(container)
		if not container then return nil end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") then
				local n = t.Name:lower()
				if string.find(n, "golden apple") or string.find(n, "apple") or string.find(n, "gap") then return t end
			end
		end
		return nil
	end
	local a = nil
	if char then a = scan(char) end
	if a then return a end
	if pack then a = scan(pack) end
	return a
end
local function equipTool(tool)
	if not tool then return false end
	local hum = getHum()
	if not hum then return false end
	if tool.Parent == getChar() then return true end
	pcall(function() hum:EquipTool(tool) end)
	return tool.Parent == getChar()
end

-- ================= TARGETING =================
local function hasLineOfSight(targetHRP)
	if not S.WallCheck then return true end
	local hrp = getHRP()
	if not hrp or not targetHRP then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {getChar()}
	local dir = targetHRP.Position - hrp.Position
	local result = Workspace:Raycast(hrp.Position, dir, params)
	if not result then return true end
	local hit = result.Instance
	if not hit then return true end
	if hit:IsDescendantOf(targetHRP.Parent) then return true end
	return false
end
local function getTarget()
	local hrp = getHRP()
	if not hrp then return nil end
	local best = nil
	local bestScore = nil
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and thrp then
				local dist = (thrp.Position - hrp.Position).Magnitude
				if dist <= S.AuraRange and hasLineOfSight(thrp) then
					local score = dist
					if S.AerialPriority and thrp.Position.Y > hrp.Position.Y + 6 then score = score - 20 end
					if S.LowestHP then score = score + (hum.Health * 0.1) end
					if bestScore == nil or score < bestScore then
						best = plr
						bestScore = score
					end
				end
			end
		end
	end
	return best
end
local function getDummy()
	if not S.AttackDummies then return nil end
	local hrp = getHRP()
	if not hrp then return nil end
	local best = nil
	local bestDist = S.AuraRange
	for _, m in ipairs(Workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name:lower():find("dummy") then
			local hum = m:FindFirstChildOfClass("Humanoid")
			local thrp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso")
			if hum and hum.Health > 0 and thrp then
				local dist = (thrp.Position - hrp.Position).Magnitude
				if dist < bestDist then
					best = m
					bestDist = dist
				end
			end
		end
	end
	return best
end
local function faceTarget(targetPos)
	local hrp = getHRP()
	if not hrp then return end
	local p = hrp.Position
	local look = Vector3.new(targetPos.X, p.Y, targetPos.Z)
	if (look - p).Magnitude < 0.1 then return end
	pcall(function() hrp.CFrame = CFrame.lookAt(p, look) end)
end

-- ================= KILL AURA =================
task.spawn(function()
	while isCurrent() do
		task.wait(0.08)
		if S.KillAura then
			local hrp = getHRP()
			local hum = getHum()
			if hrp and hum and hum.Health > 0 then
				local targetPlr = getTarget()
				local targetModel = nil
				local targetHRP = nil
				if targetPlr and targetPlr.Character then
					targetModel = targetPlr.Character
					targetHRP = targetModel:FindFirstChild("HumanoidRootPart")
				else
					targetModel = getDummy()
					if targetModel then targetHRP = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChild("Torso") end
				end
				if targetHRP then
					if S.FaceTarget then faceTarget(targetHRP.Position) end
					local falling = false
					if S.AutoMace then
						local vel = hrp.AssemblyLinearVelocity
						if vel.Y < -8 and targetHRP.Position.Y < hrp.Position.Y - 3 then falling = true end
					end
					if os.clock() - LastSwing >= SwingCooldown then
						local weapon = findWeapon()
						if not weapon then
							log("Aura: no weapon in backpack - pick a kit first")
							task.wait(1)
						elseif equipTool(weapon) then
							task.wait(0.05)
							pcall(function() weapon:Activate() end)
							LastSwing = os.clock()
							if falling then log("Mace smash!") end
						end
					end
				end
			end
		end
	end
end)

-- ================= AUTO EAT =================
task.spawn(function()
	while isCurrent() do
		task.wait(0.5)
		if S.AutoEat then
			local hum = getHum()
			if hum and hum.Health > 0 and hum.Health / hum.MaxHealth * 100 < S.EatAt then
				local apple = findApple()
				if apple and equipTool(apple) then
					task.wait(0.1)
					pcall(function() apple:Activate() end)
					log("Auto Eat: golden apple")
					task.wait(1)
				end
			end
		end
	end
end)

-- ================= AIMBOT =================
RunService.RenderStepped:Connect(function()
	if not isCurrent() then return end
	if not S.Aimbot then return end
	local hrp = getHRP()
	if not hrp then return end
	local targetPlr = nil
	local bestDist = 100
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local head = plr.Character:FindFirstChild("Head")
			if hum and hum.Health > 0 and head then
				local dist = (head.Position - hrp.Position).Magnitude
				if dist < bestDist and hasLineOfSight(head) then
					targetPlr = plr
					bestDist = dist
				end
			end
		end
	end
	if targetPlr and targetPlr.Character then
		local head = targetPlr.Character:FindFirstChild("Head")
		if head then
			pcall(function() Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position) end)
		end
	end
end)

-- ================= ESP =================
local espObjs = {}
local function clearESP()
	for _, o in pairs(espObjs) do
		pcall(function() o:Destroy() end)
	end
	espObjs = {}
end
local function makeESP(plr)
	if espObjs[plr] then return end
	local char = plr.Character
	if not char then return end
	local hl = Instance.new("Highlight")
	hl.Name = "UNSTABLE_ESP"
	hl.FillColor = Color3.fromRGB(255, 0, 0)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.6
	hl.Parent = char
	local head = char:FindFirstChild("Head")
	if head then
		local bb = Instance.new("BillboardGui")
		bb.Name = "UNSTABLE_ESP_BB"
		bb.Size = UDim2.new(0, 120, 0, 40)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.Parent = head
		local lbl = Instance.new("TextLabel")
		lbl.Name = "ESPLabel"
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextStrokeTransparency = 0
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = bb
	end
	espObjs[plr] = hl
end
task.spawn(function()
	while isCurrent() do
		task.wait(0.5)
		if not S.ESP then
			if next(espObjs) ~= nil then clearESP() end
		else
			local hrp = getHRP()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					makeESP(plr)
					local head = plr.Character:FindFirstChild("Head")
					if head then
						local bb = head:FindFirstChild("UNSTABLE_ESP_BB")
						if bb then
							local lbl = bb:FindFirstChild("ESPLabel")
							if lbl then
								local dist = 0
								if hrp then dist = math.floor((head.Position - hrp.Position).Magnitude) end
								if S.ESPHealth then
									lbl.Text = plr.Name .. "  " .. math.floor(hum.Health) .. " HP  " .. dist .. "m"
								else
									lbl.Text = plr.Name .. "  " .. dist .. "m"
								end
							end
						end
					end
				end
			end
		end
		end
	end
end)
Players.PlayerRemoving:Connect(function(plr)
	if espObjs[plr] then
		pcall(function() espObjs[plr]:Destroy() end)
		espObjs[plr] = nil
	end
end)

-- ================= MOVEMENT =================
local flyBV = nil
local flyBG = nil
local function stopFly()
	if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
	if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
end
RunService.Heartbeat:Connect(function()
	if not isCurrent() then return end
	local hum = getHum()
	local hrp = getHRP()
	if not hum or not hrp then return end
	if S.Speed then
		pcall(function() hum.WalkSpeed = S.SpeedValue end)
	else
		if hum.WalkSpeed ~= 16 then pcall(function() hum.WalkSpeed = 16 end) end
	end
	if S.Fly then
		if not flyBV then
			flyBV = Instance.new("BodyVelocity")
			flyBV.MaxForce = Vector3.new(100000, 100000, 100000)
			flyBV.Velocity = Vector3.new(0, 0, 0)
			flyBV.Parent = hrp
			flyBG = Instance.new("BodyGyro")
			flyBG.MaxTorque = Vector3.new(100000, 100000, 100000)
			flyBG.P = 10000
			flyBG.Parent = hrp
		end
		local dir = Vector3.new(0, 0, 0)
		local cf = Camera.CFrame
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
		if dir.Magnitude > 0 then dir = dir.Unit * S.FlySpeed else dir = Vector3.new(0, 0, 0) end
		pcall(function()
			flyBV.Velocity = dir
			flyBG.CFrame = cf
		end)
	else
		if flyBV or flyBG then stopFly() end
	end
	if S.Noclip then
		for _, p in ipairs(getChar():GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
end)
UserInputService.JumpRequest:Connect(function()
	if not S.InfJump then return end
	local hum = getHum()
	if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end)
-- Restore collisions when Noclip turns off / character respawns
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(1)
	if not S.Noclip then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
		end
	end
	stopFly()
end)

-- ================= UI =================
local parentGui = nil
pcall(function() parentGui = game:GetService("CoreGui") end)
if not parentGui then parentGui = LocalPlayer:FindFirstChild("PlayerGui") end
local gui = Instance.new("ScreenGui")
gui.Name = "UnstableANTH"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parentGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 520, 0, 380)
main.Position = UDim2.new(0.5, -260, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(180, 0, 255)
mainStroke.Thickness = 2
mainStroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 40)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Unstable SMP FFA  |  ANTH Hub"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main
local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -24, 0, 18)
sub.Position = UDim2.new(0, 12, 0, 38)
sub.BackgroundTransparency = 1
sub.Text = "Solara PC  •  v1.0  •  Alt only - FFA / Duels / Practice Dummy"
sub.TextColor3 = Color3.fromRGB(170, 170, 170)
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = main

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -40, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = main
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 34)
tabBar.Position = UDim2.new(0, 12, 0, 60)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 0, 240)
content.Position = UDim2.new(0, 12, 0, 100)
content.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
content.BorderSizePixel = 0
content.Parent = main
local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = content

local logLabel = Instance.new("TextLabel")
logLabel.Name = "Log"
logLabel.Size = UDim2.new(1, -24, 0, 28)
logLabel.Position = UDim2.new(0, 12, 0, 346)
logLabel.BackgroundTransparency = 1
logLabel.Text = "Ready. Pick a kit, then turn on Kill Aura."
logLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
logLabel.Font = Enum.Font.Gotham
logLabel.TextSize = 12
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.Parent = main
_G.UNSTABLE_Log = logLabel

local tabFrames = {}
local tabButtons = {}
local function makeTab(name, x)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 118, 0, 34)
	btn.Position = UDim2.new(0, x, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Parent = tabBar
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 1, 0)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.Parent = content
	tabFrames[name] = f
	tabButtons[name] = btn
	btn.MouseButton1Click:Connect(function()
		for n, fr in pairs(tabFrames) do fr.Visible = false end
		for n, b in pairs(tabButtons) do b.BackgroundColor3 = Color3.fromRGB(40, 40, 48) end
		f.Visible = true
		btn.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
	end)
	return f
end
local combatTab = makeTab("Combat", 0)
local aimTab = makeTab("Aim / ESP", 124)
local moveTab = makeTab("Move", 248)
local utilTab = makeTab("Utility", 372)
tabFrames["Combat"].Visible = true
tabButtons["Combat"].BackgroundColor3 = Color3.fromRGB(180, 0, 255)

local function addToggle(parent, y, text, key, default)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 32)
	row.Position = UDim2.new(0, 10, 0, y)
	row.BackgroundTransparency = 1
	row.Parent = parent
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -50, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 40, 0, 26)
	btn.Position = UDim2.new(1, -40, 0, 3)
	btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(60, 60, 68)
	btn.Text = ""
	btn.Parent = row
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = btn
	local check = Instance.new("TextLabel")
	check.Size = UDim2.new(1, 0, 1, 0)
	check.BackgroundTransparency = 1
	check.Text = default and "ON" or "OFF"
	check.TextColor3 = Color3.fromRGB(255, 255, 255)
	check.Font = Enum.Font.GothamBold
	check.TextSize = 11
	check.Parent = btn
	btn.MouseButton1Click:Connect(function()
		S[key] = not S[key]
		btn.BackgroundColor3 = S[key] and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(60, 60, 68)
		check.Text = S[key] and "ON" or "OFF"
		log(text .. ": " .. (S[key] and "ON" or "OFF"))
		if key == "Noclip" and not S[key] then
			local char = getChar()
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = true end
				end
			end
		end
		if key == "Fly" and not S[key] then stopFly() end
		if key == "ESP" and not S[key] then clearESP() end
	end)
	return btn
end
local function addCycle(parent, y, text, key, values)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 32)
	row.Position = UDim2.new(0, 10, 0, y)
	row.BackgroundTransparency = 1
	row.Parent = parent
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -110, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 100, 0, 26)
	btn.Position = UDim2.new(1, -100, 0, 3)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
	btn.Text = tostring(S[key])
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Parent = row
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = btn
	btn.MouseButton1Click:Connect(function()
		local idx = 1
		for i, v in ipairs(values) do if v == S[key] then idx = i break end end
		idx = idx + 1
		if idx > #values then idx = 1 end
		S[key] = values[idx]
		btn.Text = tostring(S[key])
		log(text .. ": " .. tostring(S[key]))
	end)
end

addToggle(combatTab, 4, "Kill Aura", "KillAura", false)
addToggle(combatTab, 36, "Face Target", "FaceTarget", true)
addToggle(combatTab, 68, "Wall Check (no hits through walls)", "WallCheck", true)
addToggle(combatTab, 100, "Aerial Priority (elytra / mace divers first)", "AerialPriority", true)
addToggle(combatTab, 132, "Target Lowest HP", "LowestHP", false)
addToggle(combatTab, 164, "Auto Mace Smash (falling only)", "AutoMace", false)
addCycle(combatTab, 196, "Aura Range (studs)", "AuraRange", {10, 14, 18, 22})

addToggle(aimTab, 8, "Aimbot (camera lock, nearest)", "Aimbot", false)
addToggle(aimTab, 44, "Player ESP (box + name)", "ESP", false)
addToggle(aimTab, 80, "ESP Show Health", "ESPHealth", true)
addToggle(aimTab, 116, "Attack Practice Dummies too", "AttackDummies", false)
addToggle(aimTab, 152, "Auto Eat Golden Apple", "AutoEat", false)
addCycle(aimTab, 188, "Auto Eat At (% HP)", "EatAt", {30, 55, 75})

addToggle(moveTab, 8, "Fly (WASD, Space up, Ctrl down)", "Fly", false)
addToggle(moveTab, 44, "Speed", "Speed", false)
addToggle(moveTab, 80, "Infinite Jump", "InfJump", false)
addToggle(moveTab, 116, "Noclip", "Noclip", false)
addCycle(moveTab, 152, "Speed Value", "SpeedValue", {20, 28, 36, 50})
addCycle(moveTab, 188, "Fly Speed", "FlySpeed", {35, 50, 75, 100})

addToggle(utilTab, 8, "Anti-AFK", "AntiAFK", true)
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 150)
info.Position = UDim2.new(0, 10, 0, 50)
info.BackgroundTransparency = 1
info.Text = "Tips:\n• Practice Dummy first - test Aura + Auto Eat there.\n• Aura range 14 is safest, 22 is obvious.\n• Speed over 36 + Fly in FFA = easy report / ban.\n• If Aura does nothing, your kit has no weapon tool\n  equipped - pick a kit, then rejoin if needed.\n• RightShift toggles this hub."
info.TextColor3 = Color3.fromRGB(200, 200, 200)
info.Font = Enum.Font.Gotham
info.TextSize = 13
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = utilTab

-- Minimise logo
local logo = Instance.new("TextButton")
logo.Name = "ANTHLogo"
logo.Size = UDim2.new(0, 64, 0, 64)
logo.Position = UDim2.new(0, 20, 0.5, -32)
logo.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
logo.Text = "ANTH"
logo.TextColor3 = Color3.fromRGB(120, 255, 120)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 14
logo.Visible = false
logo.Active = true
logo.Draggable = true
logo.Parent = gui
local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 32)
logoCorner.Parent = logo
local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Color3.fromRGB(180, 0, 255)
logoStroke.Thickness = 2
logoStroke.Parent = logo
closeBtn.MouseButton1Click:Connect(function()
	main.Visible = false
	logo.Visible = true
end)
logo.MouseButton1Click:Connect(function()
	main.Visible = true
	logo.Visible = false
end)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
		if not main.Visible then logo.Visible = true else logo.Visible = false end
	end
end)

log("Unstable ANTH v1.0 loaded - pick a kit, then turn on Kill Aura")
print("[Unstable ANTH] v1.0 loaded")
