-- UNSTABLE SMP FFA | ANTH Hub v1.2
-- For Anth - Solara PC
-- v1.1: UI restyled to match Jailbreak for Gooners / Enchanted Hub
-- (red header, pill tabs, red checkbox rows, log at bottom).
-- v1.2 FIX: v1.1 UI never showed in Solara - it used CoreGui,
-- which Solara blocks. Now uses gethui / PlayerGui like Jailbreak,
-- which is proven to show. Also fixed ESP copies: old runs left
-- Highlights + name tags on every player, and re-running stacked
-- more on top. Now ESP checks if one already exists on that
-- character, and old ESP is destroyed on load / respawn.
-- Added Auto Hit (Kill Aura, same thing, clearer name) and
-- Safe Mode + Anti-Cheat Check. There is NO script that bypasses
-- all anti-cheat - Safe Mode just makes you look human: capped
-- range, 0.65s swing, no teleport, no crazy speed.
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
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then
			for _, g in ipairs(h:GetChildren()) do
				if g.Name == "UnstableANTH" then g:Destroy() end
			end
		end
	end
	local cg = game:GetService("CoreGui")
	for _, g in ipairs(cg:GetChildren()) do
		if g.Name == "UnstableANTH" then g:Destroy() end
	end
	-- Destroy ESP copies left by old runs, on every player
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			for _, d in ipairs(plr.Character:GetDescendants()) do
				if d.Name == "UNSTABLE_ESP" or d.Name == "UNSTABLE_ESP_BB" then d:Destroy() end
			end
		end
	end
end)

-- ================= SETTINGS =================
local S = {
	KillAura = false,
	AutoHit = false,
	SafeMode = true,
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

-- ================= ANTI-CHEAT / SAFE MODE =================
-- Honest check, run from the Utility tab. Roblox Hyperion +
-- the game's own server checks flag impossible speed, teleport
-- distance, and too-fast hits. No client script can bypass
-- all of that. Safe Mode is the closest thing: human swing
-- timing, capped range/speed, no teleport, Wall Check on.
-- Turning Safe Mode OFF lets you go to range 22 / speed 50,
-- but that is much more likely to get flagged / reported.
local function effectiveRange()
	if S.SafeMode then return math.min(S.AuraRange, 14) end
	return S.AuraRange
end
local function effectiveSwing()
	if S.SafeMode then return 0.65 end
	return 0.45
end
local function checkAntiCheat()
	log("Anti-Cheat Check:")
	log(" - No full bypass exists. Hyperion + server checks are server-side.")
	if S.SafeMode then
		log(" - Safe Mode ON: range capped 14, swing 0.65s, speed capped 28")
	else
		log(" - WARNING: Safe Mode OFF - range/speed uncapped, high flag risk")
	end
	if S.WallCheck then log(" - Wall Check ON: no hits through walls") else log(" - WARNING: Wall Check OFF") end
	if S.Fly and S.Speed then log(" - WARNING: Fly + Speed together is obvious") end
	local hum = getHum()
	if hum then log(" - Character OK, HP " .. math.floor(hum.Health)) else log(" - No character yet - respawn first") end
	local w = findWeapon()
	if w then log(" - Weapon found: " .. w.Name) else log(" - No weapon found - pick a kit first") end
	log(" - Use an ALT, small server, short sessions.")
end
_G.UNSTABLE_CheckAntiCheat = checkAntiCheat
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
				if dist <= effectiveRange() and hasLineOfSight(thrp) then
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
	local bestDist = effectiveRange()
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
		if S.KillAura or S.AutoHit then
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
					if os.clock() - LastSwing >= effectiveSwing() then
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
	local char = plr.Character
	if not char then return end
	if char:FindFirstChild("UNSTABLE_ESP") then return end
	if espObjs[plr] and espObjs[plr].Parent then return end
	local hl = Instance.new("Highlight")
	hl.Name = "UNSTABLE_ESP"
	hl.FillColor = Color3.fromRGB(255, 0, 0)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.6
	hl.Parent = char
	local head = char:FindFirstChild("Head")
	if head and not head:FindFirstChild("UNSTABLE_ESP_BB") then
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
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		if espObjs[plr] then espObjs[plr] = nil end
	end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
	plr.CharacterAdded:Connect(function()
		if espObjs[plr] then espObjs[plr] = nil end
	end)
end
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
		local sp = S.SpeedValue
		if S.SafeMode then sp = math.min(sp, 28) end
		pcall(function() hum.WalkSpeed = sp end)
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

-- ================= UI - Enchanted Hub style =================
-- Same layout as Jailbreak for Gooners in Anth's screenshot:
-- red header, pill tabs, red checkbox rows, --- sections ---,
-- log at the bottom. Solara PC, RightShift toggles, X minimises
-- to a draggable ANTH logo.
local guiParent = nil
if gethui then
	local ok, r = pcall(gethui)
	if ok and r then guiParent = r end
end
if not guiParent then guiParent = LocalPlayer:WaitForChild("PlayerGui") end
local gui = Instance.new("ScreenGui")
gui.Name = "UnstableANTH"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = guiParent
-- Load toast, so you can SEE it loaded even before you open the hub
local toast = Instance.new("TextLabel")
toast.Size = UDim2.new(0, 360, 0, 36)
toast.Position = UDim2.new(0.5, -180, 0, 20)
toast.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
toast.Text = "UNSTABLE v1.2 LOADED - RightShift to open"
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 14
toast.Parent = gui
local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 8)
toastCorner.Parent = toast
task.spawn(function()
	task.wait(4)
	pcall(function() toast:Destroy() end)
end)
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 560, 0, 420)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
main.BorderSizePixel = 0
main.Visible = true
main.Parent = gui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(185, 30, 35)
mainStroke.Thickness = 1
mainStroke.Parent = main
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
titleIcon.Text = "US"
titleIcon.Parent = titleBar
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 13)
iconCorner.Parent = titleIcon
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 42, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Unstable SMP FFA | Public Version"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar
local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0, 30, 0, 30)
xBtn.Position = UDim2.new(1, -34, 0, 4)
xBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 25)
xBtn.Text = "X"
xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
xBtn.Font = Enum.Font.GothamBold
xBtn.TextSize = 14
xBtn.Parent = titleBar
local xCorner = Instance.new("UICorner")
xCorner.CornerRadius = UDim.new(0, 6)
xCorner.Parent = xBtn
local tabNames = {"Combat", "Aim", "Move", "Utility"}
local tabBtns = {}
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -10, 0, 32)
tabBar.Position = UDim2.new(0, 5, 0, 44)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main
for i, name in ipairs(tabNames) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1 / 4, -3, 0, 29)
	b.Position = UDim2.new((i - 1) / 4, 1, 0, 0)
	b.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
	b.Text = name
	b.TextColor3 = Color3.fromRGB(210, 210, 210)
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.Parent = tabBar
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = b
	tabBtns[name] = b
end
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -10, 0, 238)
content.Position = UDim2.new(0, 5, 0, 82)
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
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 0, 48)
logLabel.Position = UDim2.new(0, 5, 0, 326)
logLabel.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
logLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 11
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Text = "Loaded. Pick a tab. Safe Mode ON."
logLabel.Parent = main
_G.UNSTABLE_Log = logLabel
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -10, 0, 14)
statsLabel.Position = UDim2.new(0, 5, 0, 380)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
statsLabel.Font = Enum.Font.Code
statsLabel.TextSize = 10
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Text = "Solara PC  •  v1.1  •  RightShift toggles hub"
statsLabel.Parent = main
local logo = Instance.new("TextButton")
logo.Size = UDim2.new(0, 64, 0, 64)
logo.Position = UDim2.new(0, 10, 0.5, -32)
logo.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
logo.Text = "ANTH"
logo.TextColor3 = Color3.fromRGB(255, 80, 80)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 14
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
	pcall(function() main.Position = UDim2.new(0.5, 0, 0.5, 0) end)
end
local function minimise()
	main.Visible = false
	logo.Visible = true
end
xBtn.MouseButton1Click:Connect(minimise)
logo.MouseButton1Click:Connect(maximise)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
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
local currentTab = "Combat"
local function clearContent()
	for _, c in ipairs(content:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
end
local function makeRow()
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -4, 0, 34)
	b.Text = ""
	b.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
	b.TextColor3 = Color3.fromRGB(235, 235, 235)
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = content
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = b
	return b
end
local function makeSection(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -4, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.Text = "--- " .. text .. " ---"
	lbl.TextColor3 = Color3.fromRGB(170, 170, 170)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.Parent = content
	return lbl
end
local function makeNote(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -4, 0, 36)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(170, 170, 170)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.Parent = content
	return lbl
end
local function makeToggle(label, key)
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
	check.Text = ""
	check.TextColor3 = Color3.fromRGB(255, 255, 255)
	check.Font = Enum.Font.GothamBold
	check.TextSize = 13
	check.Parent = box
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -36, 1, 0)
	lbl.Position = UDim2.new(0, 34, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = b
	local function refresh()
		if S[key] then
			box.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
			check.Text = "✓"
		else
			box.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
			check.Text = ""
		end
	end
	refresh()
	b.MouseButton1Click:Connect(function()
		S[key] = not S[key]
		refresh()
		log(label .. ": " .. (S[key] and "ON" or "OFF"))
		if key == "SafeMode" and not S[key] then log("WARNING: Safe Mode OFF - high flag risk") end
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
		if key == "AutoHit" then S.KillAura = S[key] end
		if key == "KillAura" then S.AutoHit = S[key] end
	end)
	return b
end
local function makeCycle(label, key, values)
	local b = makeRow()
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -120, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = b
	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(0, 100, 1, 0)
	val.Position = UDim2.new(1, -108, 0, 0)
	val.BackgroundTransparency = 1
	val.Text = tostring(S[key]) .. "  v"
	val.TextColor3 = Color3.fromRGB(235, 235, 235)
	val.Font = Enum.Font.GothamBold
	val.TextSize = 13
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = b
	b.MouseButton1Click:Connect(function()
		local idx = 1
		for i, v in ipairs(values) do if v == S[key] then idx = i break end end
		idx = idx + 1
		if idx > #values then idx = 1 end
		S[key] = values[idx]
		val.Text = tostring(S[key]) .. "  v"
		log(label .. ": " .. tostring(S[key]))
	end)
	return b
end
local function makeButton(label, fn)
	local b = makeRow()
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = b
	b.MouseButton1Click:Connect(function() fn() end)
	return b
end
local function renderTab(name)
	clearContent()
	currentTab = name
	for n, b in pairs(tabBtns) do
		if n == name then
			b.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			b.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
			b.TextColor3 = Color3.fromRGB(210, 210, 210)
		end
	end
	if name == "Combat" then
		makeSection("Auto Hit")
		makeToggle("Auto Hit - Kill Aura", "AutoHit")
		makeToggle("Face Target", "FaceTarget")
		makeToggle("Wall Check (no hits through walls)", "WallCheck")
		makeToggle("Aerial Priority (elytra / mace divers first)", "AerialPriority")
		makeToggle("Target Lowest HP", "LowestHP")
		makeToggle("Auto Mace Smash (falling only)", "AutoMace")
		makeCycle("Aura Range (studs)", "AuraRange", {10, 14, 18, 22})
		makeNote("Auto Hit equips your real weapon and swings on the game's 0.65s cooldown in Safe Mode. Range 14 is safest.")
	elseif name == "Aim" then
		makeSection("Aim / ESP")
		makeToggle("Aimbot (camera lock, nearest)", "Aimbot")
		makeToggle("Player ESP (box + name)", "ESP")
		makeToggle("ESP Show Health", "ESPHealth")
		makeToggle("Attack Practice Dummies too", "AttackDummies")
		makeToggle("Auto Eat Golden Apple", "AutoEat")
		makeCycle("Auto Eat At (% HP)", "EatAt", {30, 55, 75})
	elseif name == "Move" then
		makeSection("Movement")
		makeToggle("Fly (WASD, Space up, Ctrl down)", "Fly")
		makeToggle("Speed", "Speed")
		makeToggle("Infinite Jump", "InfJump")
		makeToggle("Noclip", "Noclip")
		makeCycle("Speed Value", "SpeedValue", {20, 28, 36, 50})
		makeCycle("Fly Speed", "FlySpeed", {35, 50, 75, 100})
		makeNote("Speed over 36 + Fly in FFA is obvious. Safe Mode caps Speed at 28.")
	elseif name == "Utility" then
		makeSection("Anti-Cheat / Safety")
		makeToggle("Safe Mode (capped range / speed / swing)", "SafeMode")
		makeToggle("Anti-AFK", "AntiAFK")
		makeButton("Check Anti-Cheat  >  Run safety check", function() checkAntiCheat() end)
		makeNote("There is NO full bypass. Safe Mode just makes hits look human. Use an ALT, small server, short sessions.")
		makeSection("Tips")
		makeNote("Practice Dummy first - test Auto Hit + Auto Eat there.\nIf Auto Hit does nothing, your kit has no weapon tool - pick a kit, then rejoin if needed.")
	end
end
for n, b in pairs(tabBtns) do
	b.MouseButton1Click:Connect(function() renderTab(n) end)
end
renderTab("Combat")
log("Safe Mode ON. Use a small server, ALT only.")
log("UNSTABLE SMP FFA loaded. Pick a kit, then turn on Auto Hit.")
print("[Unstable ANTH] v1.1 loaded - Enchanted style UI, Auto Hit + Safe Mode")
