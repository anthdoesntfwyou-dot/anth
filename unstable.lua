-- UNSTABLE SMP FFA | ANTH Hub v2.0
-- REDONE FROM SCRATCH - 2026-11-28
-- v1.x kept failing in Solara: no UI, and ESP left Highlights +
-- name tags on everyone that looked like clones of people.
-- v2.0 removes ALL of that. No ESP, no Aimbot, no dummies,
-- no ScrollingFrame, no tabs, no CoreGui, no gethui.
-- Just a plain ScreenGui in PlayerGui with big buttons.
-- Executing this alone does NOTHING except show the UI.
-- Everything is OFF until you tap it. So if clones show up
-- after running this, it is NOT this script - it is an old
-- v1 copy still running in that server. Rejoin fresh.
-- Game: Unstable SMP FFA by [IS] Insomnia Studios
-- Java 1.21 combat: sword / spear / mace, golden apples.
-- ALT ONLY. No script bypasses all anti-cheat. Safe Mode ON
-- by default: range 14, swing 0.65s, speed 28, no teleport.

repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
print("[Unstable v2.0] starting")

-- Kill any old Unstable copies, in every place they could hide
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
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			for _, d in ipairs(plr.Character:GetDescendants()) do
				if d.Name == "UNSTABLE_ESP" or d.Name == "UNSTABLE_ESP_BB" then d:Destroy() end
			end
		end
	end
end)

local S = {
	AutoHit = false,
	FaceTarget = true,
	WallCheck = true,
	SafeMode = true,
	AutoEat = false,
	Fly = false,
	Speed = false,
	Range = 14,
	SpeedValue = 28,
}
local LastSwing = 0

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
local function getRange()
	if S.SafeMode then return 14 end
	return S.Range
end
local function getSwing()
	if S.SafeMode then return 0.65 end
	return 0.45
end

-- Anti-AFK, harmless
LocalPlayer.Idled:Connect(function()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end)
end)

local function findWeapon()
	local pack = LocalPlayer:FindFirstChild("Backpack")
	local char = getChar()
	local function scan(container)
		if not container then return nil end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") then
				local n = t.Name:lower()
				if string.find(n, "mace") or string.find(n, "sword") or string.find(n, "spear") or string.find(n, "axe") or string.find(n, "trident") then return t end
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
				if string.find(n, "golden apple") or string.find(n, "apple") then return t end
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

-- Auto Hit: only runs when you turn it ON in the UI
task.spawn(function()
	while true do
		task.wait(0.1)
		if S.AutoHit then
			local hrp = getHRP()
			local hum = getHum()
			if hrp and hum and hum.Health > 0 then
				local best = nil
				local bestDist = getRange()
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= LocalPlayer and plr.Character then
						local thum = plr.Character:FindFirstChildOfClass("Humanoid")
						local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
						if thum and thum.Health > 0 and thrp then
							local dist = (thrp.Position - hrp.Position).Magnitude
							if dist < bestDist then
								local clear = true
								if S.WallCheck then
									local params = RaycastParams.new()
									params.FilterType = Enum.RaycastFilterType.Exclude
									params.FilterDescendantsInstances = {getChar()}
									local result = Workspace:Raycast(hrp.Position, thrp.Position - hrp.Position, params)
									if result and result.Instance and not result.Instance:IsDescendantOf(plr.Character) then clear = false end
								end
								if clear then
									best = plr
									bestDist = dist
								end
							end
						end
					end
				end
				if best and best.Character then
					local thrp = best.Character:FindFirstChild("HumanoidRootPart")
					if thrp then
						if S.FaceTarget then
							local p = hrp.Position
							pcall(function() hrp.CFrame = CFrame.lookAt(p, Vector3.new(thrp.Position.X, p.Y, thrp.Position.Z)) end)
						end
						if os.clock() - LastSwing >= getSwing() then
							local weapon = findWeapon()
							if weapon then
								pcall(function() getHum():EquipTool(weapon) end)
								task.wait(0.05)
								pcall(function() weapon:Activate() end)
								LastSwing = os.clock()
							end
						end
					end
				end
			end
		end
	end
end)

-- Auto Eat: only runs when you turn it ON
task.spawn(function()
	while true do
		task.wait(0.5)
		if S.AutoEat then
			local hum = getHum()
			if hum and hum.Health > 0 and hum.Health / hum.MaxHealth * 100 < 55 then
				local apple = findApple()
				if apple then
					pcall(function() hum:EquipTool(apple) end)
					task.wait(0.1)
					pcall(function() apple:Activate() end)
				end
			end
		end
	end
end)

-- Fly / Speed: only runs when you turn it ON
local flyBV = nil
local flyBG = nil
RunService.Heartbeat:Connect(function()
	local hum = getHum()
	local hrp = getHRP()
	if not hum or not hrp then return end
	if S.Speed then
		local sp = S.SpeedValue
		if S.SafeMode then sp = 28 end
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
		local cf = Workspace.CurrentCamera.CFrame
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
		if dir.Magnitude > 0 then dir = dir.Unit * 50 else dir = Vector3.new(0, 0, 0) end
		pcall(function()
			flyBV.Velocity = dir
			flyBG.CFrame = cf
		end)
	else
		if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
		if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
	end
end)

-- ================= UI - SIMPLE, NO TABS =================
-- Plain PlayerGui, plain Frame, plain buttons. If this does not
-- show, the problem is Solara / the game, not the UI code.
local pg = LocalPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "UnstableANTH"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = pg
print("[Unstable v2.0] gui parented to PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 500, 0, 380)
main.Position = UDim2.new(0.5, -250, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
main.BorderSizePixel = 0
main.Visible = true
main.Active = true
main.Draggable = true
main.Parent = gui

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
header.BorderSizePixel = 0
header.Parent = main
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Unstable SMP FFA | v2.0"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header
local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0, 34, 0, 34)
xBtn.Position = UDim2.new(1, -40, 0, 5)
xBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 25)
xBtn.Text = "X"
xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
xBtn.Font = Enum.Font.GothamBold
xBtn.TextSize = 16
xBtn.Parent = header

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 24)
status.Position = UDim2.new(0, 12, 0, 52)
status.BackgroundTransparency = 1
status.Text = "Loaded. Everything is OFF - tap a button to turn it on."
status.TextColor3 = Color3.fromRGB(255, 120, 120)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local function makeButton(y, label, key)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -24, 0, 36)
	b.Position = UDim2.new(0, 12, 0, y)
	b.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
	b.Text = label .. "  [OFF]"
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = main
	b.MouseButton1Click:Connect(function()
		S[key] = not S[key]
		if S[key] then
			b.Text = label .. "  [ON]"
			b.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
			status.Text = label .. " ON"
		else
			b.Text = label .. "  [OFF]"
			b.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
			status.Text = label .. " OFF"
		end
		print("[Unstable v2.0] " .. label .. " = " .. tostring(S[key]))
	end)
	return b
end
makeButton(84, "Auto Hit", "AutoHit")
makeButton(126, "Face Target", "FaceTarget")
makeButton(168, "Wall Check", "WallCheck")
makeButton(210, "Safe Mode", "SafeMode")
makeButton(252, "Auto Eat Golden Apple", "AutoEat")
makeButton(294, "Fly  (WASD, Space up, Ctrl down)", "Fly")
makeButton(336, "Speed", "Speed")
-- Set the default ON ones to show ON
-- Face Target, Wall Check and Safe Mode start ON, so fix their text
for _, b in ipairs(main:GetChildren()) do
	if b:IsA("TextButton") and b.Text ~= "X" then
		if string.find(b.Text, "Face Target") or string.find(b.Text, "Wall Check") or string.find(b.Text, "Safe Mode") then
			b.Text = string.gsub(b.Text, "%[OFF%]", "[ON]")
			b.BackgroundColor3 = Color3.fromRGB(185, 30, 35)
		end
	end
end

local logo = Instance.new("TextButton")
logo.Size = UDim2.new(0, 64, 0, 64)
logo.Position = UDim2.new(0, 20, 0.5, -32)
logo.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
logo.Text = "ANTH"
logo.TextColor3 = Color3.fromRGB(255, 80, 80)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 14
logo.Visible = false
logo.Active = true
logo.Draggable = true
logo.Parent = gui
xBtn.MouseButton1Click:Connect(function()
	main.Visible = false
	logo.Visible = true
end)
logo.MouseButton1Click:Connect(function()
	main.Visible = true
	logo.Visible = false
end)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
		logo.Visible = not main.Visible
	end
end)
print("[Unstable v2.0] UI built, main visible = " .. tostring(main.Visible))
