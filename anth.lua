-- ANTH HUB - Delta Fixed Version
-- Same unified hub, rewritten for Delta (mobile + PC)
-- FIXED: the last version had 2-3 commands on one line, which is a
-- syntax error in Luau, so Delta would not run it at all.
-- This version is one statement per line, no continue, no +=,
-- no Vector3.zero, and uses gethui() if Delta has it.
--
-- If it still fails, open Delta > Console / Logs and send me the
-- red error line - it will say the exact line number.
--
-- HOW TO RUN ON DELTA:
--  1. Join a game, open Delta, tap Execute / Script tab
--  2. Paste the WHOLE code, tap Execute
--  3. You should see ANTH // TERMINAL in the middle.
--  4. If you see nothing, tap Delta's console icon and check for errors.
--  5. On mobile tap the ANTH logo / >_ button. On PC press ; (semicolon).
--  6. X minimises to ANTH logo on the left. Tap logo to reopen.
--  7. COMMANDS button opens / closes the list.

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PREFIX = ";"

local IS_MOBILE = false
pcall(function()
	IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

local NEON = Color3.fromRGB(0, 255, 65)
local NEON2 = Color3.fromRGB(0, 204, 255)
local BG = Color3.fromRGB(8, 14, 10)
local BG2 = Color3.fromRGB(14, 22, 16)
local TXT = Color3.fromRGB(220, 255, 220)

-- Delta puts UI in gethui() so it shows above the game.
-- If gethui does not exist, fall back to PlayerGui.
local guiParent = nil
if gethui then
	local ok, result = pcall(gethui)
	if ok and result then
		guiParent = result
	end
end
if not guiParent then
	guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ================= HACKER UI =================
local gui = Instance.new("ScreenGui")
gui.Name = "ANTH_Hub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = guiParent

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or NEON
	s.Thickness = thickness or 1
	s.Transparency = 0.2
	s.Parent = parent
	return s
end

local function makeButton(parent, text, size, pos, bg, tc)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bg or BG2
	b.TextColor3 = tc or NEON
	b.Font = Enum.Font.Code
	if IS_MOBILE then
		b.TextSize = 16
	else
		b.TextSize = 14
	end
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	addCorner(b, 8)
	addStroke(b, NEON, 1)
	return b
end

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
if IS_MOBILE then
	main.Size = UDim2.new(0.94, 0, 0, 440)
else
	main.Size = UDim2.new(0, 500, 0, 400)
end
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
addCorner(main, 12)
addStroke(main, NEON, 2)

local title = Instance.new("Frame")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = BG2
title.BorderSizePixel = 0
title.Parent = main
addCorner(title, 12)

local titleTxt = Instance.new("TextLabel")
titleTxt.Size = UDim2.new(1, -90, 1, 0)
titleTxt.Position = UDim2.new(0, 12, 0, 0)
titleTxt.BackgroundTransparency = 1
titleTxt.Text = "ANTH // TERMINAL [v1.1 DELTA]"
titleTxt.TextColor3 = NEON
titleTxt.Font = Enum.Font.Code
titleTxt.TextSize = 15
titleTxt.TextXAlignment = Enum.TextXAlignment.Left
titleTxt.Parent = title

local xBtn = makeButton(title, "X", UDim2.new(0, 34, 0, 30), UDim2.new(1, -40, 0, 5), Color3.fromRGB(60, 10, 10), Color3.fromRGB(255, 80, 80))
xBtn.TextSize = 16

local logo = Instance.new("TextButton")
logo.Name = "ANTH_Logo"
logo.Size = UDim2.new(0, 64, 0, 64)
logo.Position = UDim2.new(0, 10, 0.5, -32)
logo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
logo.TextColor3 = NEON
logo.Font = Enum.Font.Code
logo.TextSize = 15
logo.Text = "ANTH"
logo.Visible = false
logo.Parent = gui
addCorner(logo, 14)
addStroke(logo, NEON, 2)

local function minimise()
	main.Visible = false
	logo.Visible = true
end

local function maximise()
	main.Visible = true
	logo.Visible = false
end

xBtn.MouseButton1Click:Connect(minimise)
logo.MouseButton1Click:Connect(maximise)

-- Drag by title bar, mouse + touch
local dragging = false
local dragStart = nil
local startPos = nil
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
title.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end
end)

-- Log box
local logBox = Instance.new("ScrollingFrame")
logBox.Size = UDim2.new(1, -20, 0, 72)
logBox.Position = UDim2.new(0, 10, 0, 48)
logBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
logBox.BorderSizePixel = 0
logBox.ScrollBarThickness = 3
logBox.CanvasSize = UDim2.new(0, 0, 0, 0)
logBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
logBox.Parent = main
addCorner(logBox, 8)
addStroke(logBox, NEON, 1)

local logTxt = Instance.new("TextLabel")
logTxt.Size = UDim2.new(1, -10, 1, 0)
logTxt.Position = UDim2.new(0, 5, 0, 0)
logTxt.BackgroundTransparency = 1
logTxt.TextColor3 = NEON
logTxt.Font = Enum.Font.Code
logTxt.TextSize = 13
logTxt.TextXAlignment = Enum.TextXAlignment.Left
logTxt.TextYAlignment = Enum.TextYAlignment.Top
logTxt.TextWrapped = true
logTxt.Text = "> ANTH HUB loaded. Type ;cmds"
logTxt.Parent = logBox

local function logMsg(msg)
	logTxt.Text = logTxt.Text .. "\n> " .. msg
	print("[ANTH] " .. msg)
	task.delay(0.1, function()
		logBox.CanvasPosition = Vector2.new(0, 9999)
	end)
end

local function notify(msg)
	logMsg(msg)
end

-- Command input
local inputFrame = Instance.new("Frame")
if IS_MOBILE then
	inputFrame.Size = UDim2.new(1, -20, 0, 52)
else
	inputFrame.Size = UDim2.new(1, -20, 0, 44)
end
inputFrame.Position = UDim2.new(0, 10, 0, 128)
inputFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
inputFrame.BorderSizePixel = 0
inputFrame.Parent = main
addCorner(inputFrame, 8)
addStroke(inputFrame, NEON, 1)

local promptLbl = Instance.new("TextLabel")
promptLbl.Size = UDim2.new(0, 28, 1, 0)
promptLbl.BackgroundTransparency = 1
promptLbl.Text = ">_"
promptLbl.TextColor3 = NEON
promptLbl.Font = Enum.Font.Code
promptLbl.TextSize = 18
promptLbl.Parent = inputFrame

local barBox = Instance.new("TextBox")
barBox.Size = UDim2.new(1, -40, 1, 0)
barBox.Position = UDim2.new(0, 30, 0, 0)
barBox.BackgroundTransparency = 1
barBox.TextColor3 = TXT
barBox.PlaceholderColor3 = Color3.fromRGB(120, 180, 120)
barBox.PlaceholderText = ";blackhole me  ;hug bacon  ;dance"
barBox.Font = Enum.Font.Code
if IS_MOBILE then
	barBox.TextSize = 17
else
	barBox.TextSize = 15
end
barBox.Text = ""
barBox.ClearTextOnFocus = false
barBox.Parent = inputFrame

-- Quick buttons
local quick = Instance.new("Frame")
quick.Size = UDim2.new(1, -20, 0, 46)
quick.Position = UDim2.new(0, 10, 0, 182)
quick.BackgroundTransparency = 1
quick.Parent = main

local cmdsBtn = makeButton(quick, "COMMANDS ▼", UDim2.new(0.34, 0, 1, 0), UDim2.new(0, 0, 0, 0))
local runBtn = makeButton(quick, "RUN ▶", UDim2.new(0.30, 0, 1, 0), UDim2.new(0.34, 6, 0, 0), Color3.fromRGB(0, 60, 20))
local stopBtn = makeButton(quick, "STOP ■", UDim2.new(0.32, 0, 1, 0), UDim2.new(0.66, 6, 0, 0), Color3.fromRGB(60, 10, 10), Color3.fromRGB(255, 120, 120))

-- Collapsible commands list
local cmdsFrame = Instance.new("ScrollingFrame")
cmdsFrame.Size = UDim2.new(1, -20, 0, 150)
cmdsFrame.Position = UDim2.new(0, 10, 0, 236)
cmdsFrame.BackgroundColor3 = BG2
cmdsFrame.BorderSizePixel = 0
cmdsFrame.ScrollBarThickness = 3
cmdsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
cmdsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
cmdsFrame.Visible = false
cmdsFrame.Parent = main
addCorner(cmdsFrame, 8)
addStroke(cmdsFrame, NEON2, 1)

local cmdsTxt = Instance.new("TextLabel")
cmdsTxt.Size = UDim2.new(1, -10, 1, 0)
cmdsTxt.Position = UDim2.new(0, 5, 0, 0)
cmdsTxt.BackgroundTransparency = 1
cmdsTxt.TextColor3 = TXT
cmdsTxt.Font = Enum.Font.Code
cmdsTxt.TextSize = 13
cmdsTxt.TextXAlignment = Enum.TextXAlignment.Left
cmdsTxt.TextYAlignment = Enum.TextYAlignment.Top
cmdsTxt.TextWrapped = true
cmdsTxt.Text = "CORE\n;fly ;unfly ;speed 50 ;jump 80 ;god ;ungod\n;noclip ;clip ;spin 20 ;unspin ;tp bacon\n;bring bacon ;fling bacon ;reset ;sit\n\nPHYSICS\n;blackhole [player] ;unblackhole\n;tornado [player] ;untornado\n;tsunami ;untsunami ;stop\n\nSOCIAL\n;hug bacon ;unhug ;backpack bacon ;unbackpack\n;headsit bacon ;unheadsit ;headless ;unheadless\n\nEMOTES\n;dance ;dance2 ;dance3 ;floss ;shuffle ;dab\n;wave ;point ;cheer ;laugh ;cry ;bow\n;salute ;think ;shy ;clap ;sleep ;sit ;lay\n;stopemote"
cmdsTxt.Parent = cmdsFrame

local cmdsOpen = false
local function toggleCmds()
	cmdsOpen = not cmdsOpen
	cmdsFrame.Visible = cmdsOpen
	if cmdsOpen then
		cmdsBtn.Text = "COMMANDS ▲"
	else
		cmdsBtn.Text = "COMMANDS ▼"
	end
end
cmdsBtn.MouseButton1Click:Connect(toggleCmds)

-- ================= HELPERS =================
local function split(s)
	local t = {}
	for w in string.gmatch(s, "%S+") do
		table.insert(t, w)
	end
	return t
end

local function getChar()
	return LocalPlayer.Character
end

local function getHRP(p)
	if p == nil then
		p = LocalPlayer
	end
	if p.Character then
		return p.Character:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function getHum(p)
	if p == nil then
		p = LocalPlayer
	end
	if p.Character then
		return p.Character:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

local function getAnim()
	local h = getHum()
	if h then
		return h:FindFirstChildOfClass("Animator")
	end
	return nil
end

local function getPlayer(a)
	if not a or a == "" then
		return nil
	end
	a = a:lower()
	if a == "me" then
		return LocalPlayer
	end
	if a == "random" then
		local list = Players:GetPlayers()
		return list[math.random(1, #list)]
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #a) == a then
			return p
		end
		if p.DisplayName:lower():find(a, 1, true) then
			return p
		end
	end
	return nil
end

local function getUnanchored()
	local list = {}
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o:IsA("BasePart") and not o.Anchored then
			if o.Name ~= "BlackholeCenter" and o.Name ~= "TornadoCenter" and o.Name ~= "TsunamiWall" then
				local isChar = false
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr.Character and o:IsDescendantOf(plr.Character) then
						isChar = true
						break
					end
				end
				if not isChar then
					table.insert(list, o)
				end
			end
		end
	end
	return list
end

-- Motor6D helpers
local OrigC0 = {}

local function findMotor(a, b)
	local c = getChar()
	if not c then
		return nil
	end
	local t = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
	if not t then
		return nil
	end
	return t:FindFirstChild(a) or t:FindFirstChild(b)
end

local function getMotor(k)
	if k == "RS" then
		return findMotor("RightShoulder", "Right Shoulder")
	end
	if k == "LS" then
		return findMotor("LeftShoulder", "Left Shoulder")
	end
	if k == "RH" then
		return findMotor("RightHip", "Right Hip")
	end
	if k == "LH" then
		return findMotor("LeftHip", "Left Hip")
	end
	if k == "Neck" then
		local c = getChar()
		if not c then
			return nil
		end
		local h = c:FindFirstChild("Head")
		if h then
			return h:FindFirstChild("Neck")
		end
		return nil
	end
	if k == "Waist" then
		local c = getChar()
		if not c then
			return nil
		end
		local t = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
		if t then
			return t:FindFirstChild("Waist")
		end
		return nil
	end
	return nil
end

local function savePose()
	OrigC0 = {}
	local keys = {"RS", "LS", "RH", "LH", "Neck", "Waist"}
	for _, k in ipairs(keys) do
		local m = getMotor(k)
		if m then
			OrigC0[k] = m.C0
		end
	end
end

local function tj(k, cf, tm)
	local m = getMotor(k)
	if not m then
		return
	end
	if not OrigC0[k] then
		OrigC0[k] = m.C0
	end
	if tm == nil then
		tm = 0.35
	end
	local tw = TweenService:Create(m, TweenInfo.new(tm, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = cf})
	tw:Play()
end

local function restorePose(tm)
	if tm == nil then
		tm = 0.4
	end
	for k, c0 in pairs(OrigC0) do
		local m = getMotor(k)
		if m then
			local tw = TweenService:Create(m, TweenInfo.new(tm, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = c0})
			tw:Play()
		end
	end
end

local OFFICIAL = {}
OFFICIAL.wave = 507770239
OFFICIAL.point = 507770453
OFFICIAL.cheer = 507770677
OFFICIAL.laugh = 507770818
OFFICIAL.dance = 507771019
OFFICIAL.dance2 = 507771955
OFFICIAL.dance3 = 507772071
OFFICIAL.sleep = 507768375
OFFICIAL.sit = 507768901

local CurEmote = nil
local CurTrack = nil

local function stopTrack()
	if CurTrack then
		pcall(function()
			CurTrack:Stop(0.3)
		end)
		CurTrack = nil
	end
end

local function stopEmote()
	CurEmote = nil
	stopTrack()
	restorePose(0.3)
	local h = getHum()
	if h and h.Sit then
		h.Sit = false
	end
end

local function startCustom(name, fn)
	stopEmote()
	savePose()
	CurEmote = name
	task.spawn(function()
		while CurEmote == name do
			local ok = pcall(fn)
			if not ok then
				break
			end
			task.wait(0.05)
		end
	end)
end

local function playOfficial(name)
	local id = OFFICIAL[name]
	if not id then
		return false
	end
	local an = getAnim()
	if not an then
		return false
	end
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. tostring(id)
	local ok, tr = pcall(function()
		return an:LoadAnimation(a)
	end)
	if ok and tr then
		stopTrack()
		CurTrack = tr
		tr.Looped = true
		tr:Play(0.3)
		return true
	end
	return false
end

-- ================= FLY / NOCLIP / GOD / SPIN =================
local Flying = false
local flyGyro = nil
local flyVel = nil
local flyConn = nil

local function stopFly()
	Flying = false
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end
	if flyVel then
		flyVel:Destroy()
		flyVel = nil
	end
	local h = getHum()
	if h then
		h.PlatformStand = false
	end
end

local function startFly()
	if Flying then
		return
	end
	local hrp = getHRP()
	local hum = getHum()
	if not hrp or not hum then
		return
	end
	Flying = true
	hum.PlatformStand = true
	flyGyro = Instance.new("BodyGyro")
	flyGyro.P = 9000
	flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	flyGyro.CFrame = hrp.CFrame
	flyGyro.Parent = hrp
	flyVel = Instance.new("BodyVelocity")
	flyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyVel.Velocity = Vector3.new(0, 0, 0)
	flyVel.Parent = hrp
	flyConn = RunService.Heartbeat:Connect(function()
		if not Flying then
			return
		end
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		flyGyro.CFrame = cam.CFrame
		local d = Vector3.new(0, 0, 0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			d = d + cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			d = d - cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			d = d - cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			d = d + cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			d = d + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			d = d - Vector3.new(0, 1, 0)
		end
		local hum2 = getHum()
		if hum2 and hum2.MoveDirection.Magnitude > 0.1 then
			d = d + Vector3.new(hum2.MoveDirection.X, 0, hum2.MoveDirection.Z)
		end
		local sp = 50
		if hum2 then
			sp = hum2.WalkSpeed
		end
		if d.Magnitude > 0 then
			flyVel.Velocity = d.Unit * sp
		else
			flyVel.Velocity = Vector3.new(0, 0, 0)
		end
	end)
	notify("Fly ON - WASD / joystick, Space up")
end

local noclipConn = nil
local function setNoclip(on)
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local c = getChar()
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then
						p.CanCollide = false
					end
				end
			end
		end)
		notify("Noclip ON")
	else
		if noclipConn then
			noclipConn:Disconnect()
			noclipConn = nil
		end
		notify("Noclip OFF")
	end
end

local godConn = nil
local function setGod(on)
	if on then
		local h = getHum()
		if h then
			h.MaxHealth = math.huge
			h.Health = math.huge
		end
		godConn = RunService.Heartbeat:Connect(function()
			local hh = getHum()
			if hh and hh.Health < hh.MaxHealth then
				hh.Health = hh.MaxHealth
			end
		end)
		notify("God ON")
	else
		if godConn then
			godConn:Disconnect()
			godConn = nil
		end
		local h = getHum()
		if h then
			h.MaxHealth = 100
			h.Health = 100
		end
		notify("God OFF")
	end
end

local spinVel = nil
local function setSpin(s)
	if spinVel then
		spinVel:Destroy()
		spinVel = nil
	end
	local hrp = getHRP()
	if not hrp then
		return
	end
	if s == nil then
		s = 20
	end
	spinVel = Instance.new("BodyAngularVelocity")
	spinVel.AngularVelocity = Vector3.new(0, s, 0)
	spinVel.MaxTorque = Vector3.new(0, math.huge, 0)
	spinVel.Parent = hrp
	notify("Spin ON")
end

local function stopSpin()
	if spinVel then
		spinVel:Destroy()
		spinVel = nil
	end
	notify("Spin OFF")
end

-- ================= BLACKHOLE =================
local BHActive = false
local BHTarget = nil
local BHCenter = nil
local BHPart = nil
local BHTouched = {}

local function stopBH()
	BHActive = false
	if BHPart then
		BHPart:Destroy()
		BHPart = nil
	end
	for p, _ in pairs(BHTouched) do
		if p and p.Parent then
			pcall(function()
				p.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			end)
		end
	end
	BHTouched = {}
end

local function startBH(t)
	stopBH()
	BHTarget = t
	local hrp = getHRP()
	if not t then
		if hrp then
			BHCenter = hrp.Position + hrp.CFrame.LookVector * 8
		else
			BHCenter = Vector3.new(0, 10, 0)
		end
		notify("Blackhole ON - staying in one place")
	else
		notify("Blackhole ON - to " .. t.DisplayName)
	end
	BHActive = true
	local v = Instance.new("Part")
	v.Name = "BlackholeCenter"
	v.Anchored = true
	v.CanCollide = false
	v.CanQuery = false
	v.Size = Vector3.new(5, 5, 5)
	v.Shape = Enum.PartType.Ball
	v.Material = Enum.Material.Neon
	v.Color = Color3.fromRGB(10, 10, 10)
	v.Transparency = 0.1
	v.Parent = Workspace
	BHPart = v
	task.spawn(function()
		while BHActive do
			task.wait(0.03)
			local center = nil
			if BHTarget and BHTarget.Character then
				local th = BHTarget.Character:FindFirstChild("HumanoidRootPart")
				if th then
					center = th.Position
				end
			end
			if center == nil then
				center = BHCenter
			end
			if center then
				if BHPart then
					BHPart.CFrame = CFrame.new(center)
				end
				for _, part in ipairs(getUnanchored()) do
					if not BHActive then
						break
					end
					local off = center - part.Position
					local d = off.Magnitude
					if d > 0.5 and d < 300 then
						local strength = math.clamp(200 - d, 40, 180)
						local vel = off.Unit * strength
						local tan = Vector3.new(-off.Z, 0, off.X)
						if tan.Magnitude > 0.1 then
							vel = vel + tan.Unit * 30
						end
						if d < 6 then
							vel = tan.Unit * 70 + Vector3.new(0, 25, 0)
						end
						pcall(function()
							part.AssemblyLinearVelocity = vel
						end)
						BHTouched[part] = true
					end
				end
			end
		end
	end)
end

-- ================= TORNADO =================
local TORActive = false
local TORTarget = nil
local TORCenter = nil
local TORPart = nil

local function stopTOR()
	TORActive = false
	if TORPart then
		TORPart:Destroy()
		TORPart = nil
	end
end

local function startTOR(t)
	stopTOR()
	TORTarget = t
	local hrp = getHRP()
	if not t then
		if hrp then
			TORCenter = hrp.Position + hrp.CFrame.LookVector * 10
		else
			TORCenter = Vector3.new(0, 10, 0)
		end
		notify("Tornado ON - staying put")
	else
		notify("Tornado ON - on " .. t.DisplayName)
	end
	TORActive = true
	local v = Instance.new("Part")
	v.Name = "TornadoCenter"
	v.Anchored = true
	v.CanCollide = false
	v.CanQuery = false
	v.Size = Vector3.new(8, 50, 8)
	v.Shape = Enum.PartType.Cylinder
	v.Material = Enum.Material.Neon
	v.Color = Color3.fromRGB(180, 180, 200)
	v.Transparency = 0.7
	v.Parent = Workspace
	TORPart = v
	task.spawn(function()
		while TORActive do
			task.wait(0.03)
			local center = nil
			if TORTarget and TORTarget.Character then
				local th = TORTarget.Character:FindFirstChild("HumanoidRootPart")
				if th then
					center = th.Position
				end
			end
			if center == nil then
				center = TORCenter
			end
			if center then
				if TORPart then
					TORPart.CFrame = CFrame.new(center + Vector3.new(0, 25, 0)) * CFrame.Angles(0, 0, math.rad(90))
				end
				for _, part in ipairs(getUnanchored()) do
					if not TORActive then
						break
					end
					local off = part.Position - center
					local flat = Vector3.new(off.X, 0, off.Z).Magnitude
					if flat < 80 and off.Y > -5 and off.Y < 60 then
						local tan = Vector3.new(-off.Z, 0, off.X)
						if tan.Magnitude < 0.1 then
							tan = Vector3.new(1, 0, 0)
						end
						tan = tan.Unit
						local inw = Vector3.new(-off.X, 0, -off.Z)
						if inw.Magnitude > 0.1 then
							inw = inw.Unit * 20
						else
							inw = Vector3.new(0, 0, 0)
						end
						local up = 35
						if off.Y > 40 then
							up = -10
						end
						pcall(function()
							part.AssemblyLinearVelocity = tan * 70 + inw + Vector3.new(0, up, 0)
						end)
					end
				end
			end
		end
	end)
end

-- ================= TSUNAMI =================
local TSUActive = false
local TSUWall = nil
local TSUDir = nil
local TSUStart = nil
local TSUDist = 0

local function stopTSU()
	TSUActive = false
	if TSUWall then
		TSUWall:Destroy()
		TSUWall = nil
	end
end

local function startTSU()
	stopTSU()
	local hrp = getHRP()
	if not hrp then
		return
	end
	local dir = hrp.CFrame.LookVector
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	TSUDir = dir
	TSUStart = hrp.Position + dir * 10
	TSUDist = 0
	TSUActive = true
	local w = Instance.new("Part")
	w.Name = "TsunamiWall"
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.Size = Vector3.new(120, 25, 4)
	w.Color = Color3.fromRGB(0, 120, 255)
	w.Transparency = 0.3
	w.CFrame = CFrame.new(TSUStart + Vector3.new(0, 10, 0), TSUStart + dir + Vector3.new(0, 10, 0))
	w.Parent = Workspace
	TSUWall = w
	notify("Tsunami ON!")
	task.spawn(function()
		local last = os.clock()
		while TSUActive do
			task.wait(0.03)
			local now = os.clock()
			local dt = math.clamp(now - last, 0, 0.1)
			last = now
			TSUDist = TSUDist + 30 * dt
			if TSUDist > 250 then
				stopTSU()
				notify("Tsunami finished")
				break
			end
			local pos = TSUStart + TSUDir * TSUDist + Vector3.new(0, 10, 0)
			if TSUWall then
				TSUWall.CFrame = CFrame.new(pos, pos + TSUDir)
			end
			local push = TSUDir * 90 + Vector3.new(0, 35, 0)
			for _, part in ipairs(getUnanchored()) do
				local toP = part.Position - pos
				local f = toP:Dot(TSUDir)
				local s = math.abs(toP:Dot(Vector3.new(-TSUDir.Z, 0, TSUDir.X)))
				if f > -5 and f < 20 and s < 60 and math.abs(part.Position.Y - pos.Y) < 15 then
					pcall(function()
						part.AssemblyLinearVelocity = push
					end)
				end
			end
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character then
					local ph = plr.Character:FindFirstChild("HumanoidRootPart")
					if ph then
						local toP = ph.Position - pos
						local f = toP:Dot(TSUDir)
						local s = math.abs(toP:Dot(Vector3.new(-TSUDir.Z, 0, TSUDir.X)))
						if f > -5 and f < 20 and s < 60 then
							pcall(function()
								ph.AssemblyLinearVelocity = push
							end)
						end
					end
				end
			end
		end
	end)
end

local function stopAll()
	stopBH()
	stopTOR()
	stopTSU()
	stopFly()
	notify("Stopped everything")
end

-- ================= HUG / BACKPACK / HEADSIT =================
local AttachWeld = nil

local function detach()
	if AttachWeld then
		AttachWeld:Destroy()
		AttachWeld = nil
	end
	local h = getHum()
	if h then
		h.PlatformStand = false
	end
	restorePose(0.3)
end

local function attachTo(target, mode)
	if not target then
		notify("Pick a player: ;hug bacon")
		return
	end
	local thrp = nil
	if target.Character then
		thrp = target.Character:FindFirstChild("HumanoidRootPart")
	end
	local myHRP = getHRP()
	local myHum = getHum()
	if not thrp or not myHRP or not myHum then
		notify("Target not found")
		return
	end
	detach()
	stopEmote()
	savePose()
	myHum.PlatformStand = true
	local w = Instance.new("Weld")
	w.Name = "EmoteAttach"
	w.Part0 = thrp
	w.Part1 = myHRP
	w.Parent = myHRP
	if mode == "hug" then
		w.C0 = CFrame.new(0, 0, 1.8) * CFrame.Angles(0, math.rad(180), 0)
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-70), 0, math.rad(-20)), 0.4)
		tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-70), 0, math.rad(20)), 0.4)
		notify("Hugging " .. target.DisplayName)
	elseif mode == "backpack" then
		w.C0 = CFrame.new(0, 0.8, -1.1)
		tj("RH", CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(-80), 0, 0), 0.4)
		tj("LH", CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(-80), 0, 0), 0.4)
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-100), 0, math.rad(-30)), 0.4)
		tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-100), 0, math.rad(30)), 0.4)
		notify("On " .. target.DisplayName .. "'s back")
	elseif mode == "headsit" then
		w.C0 = CFrame.new(0, 2.8, 0)
		tj("RH", CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0), 0.4)
		tj("LH", CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0), 0.4)
		notify("Sitting on " .. target.DisplayName .. "'s head")
	end
	AttachWeld = w
	task.spawn(function()
		while AttachWeld == w do
			task.wait(0.5)
			if not target.Parent or not target.Character then
				detach()
				break
			end
			if not target.Character:FindFirstChild("HumanoidRootPart") then
				detach()
				break
			end
		end
	end)
end

local HeadlessOn = false
local function setHeadless(on)
	local c = getChar()
	if not c then
		return
	end
	local head = c:FindFirstChild("Head")
	if not head then
		return
	end
	HeadlessOn = on
	if on then
		head.Transparency = 1
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("Decal") then
				d.Transparency = 1
			end
		end
		notify("Headless ON")
	else
		head.Transparency = 0
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("Decal") then
				d.Transparency = 0
			end
		end
		notify("Headless OFF")
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	savePose()
	if HeadlessOn then
		setHeadless(true)
	end
end)

-- ================= EMOTES =================
local function doEmote(name)
	if OFFICIAL[name] then
		if playOfficial(name) then
			CurEmote = name
			notify("Emote: " .. name)
			return
		end
	end
	if name == "dance" or name == "dance2" or name == "dance3" then
		startCustom(name, function()
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-120)), 0.3)
			tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, 0, math.rad(120)), 0.3)
			tj("Waist", CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(15), 0), 0.3)
			task.wait(0.35)
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-60)), 0.3)
			tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, 0, math.rad(60)), 0.3)
			tj("Waist", CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-15), 0), 0.3)
			task.wait(0.35)
		end)
	elseif name == "floss" then
		startCustom(name, function()
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(-90)), 0.18)
			tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(90), 0, math.rad(90)), 0.18)
			task.wait(0.2)
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(90), 0, math.rad(-90)), 0.18)
			tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(90)), 0.18)
			task.wait(0.2)
		end)
	elseif name == "wave" then
		startCustom(name, function()
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-160)), 0.3)
			task.wait(0.3)
			for i = 1, 3 do
				tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-140)), 0.2)
				task.wait(0.22)
				tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-170)), 0.2)
				task.wait(0.22)
			end
		end)
	elseif name == "dab" then
		savePose()
		CurEmote = name
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-120), 0, math.rad(-60)), 0.3)
		tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(90), 0, math.rad(60)), 0.3)
		tj("Neck", CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(-25)), 0.3)
		notify("Emote: dab")
	elseif name == "shuffle" then
		startCustom(name, function()
			tj("RH", CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(-30), 0, 0), 0.2)
			tj("LH", CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(30), 0, 0), 0.2)
			task.wait(0.25)
			tj("RH", CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(30), 0, 0), 0.2)
			tj("LH", CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(-30), 0, 0), 0.2)
			task.wait(0.25)
		end)
	elseif name == "cheer" then
		startCustom(name, function()
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-160), 0, math.rad(-20)), 0.25)
			tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-160), 0, math.rad(20)), 0.25)
			task.wait(0.3)
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(0, 0, 0), 0.25)
			tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, 0, 0), 0.25)
			task.wait(0.3)
		end)
	elseif name == "clap" then
		startCustom(name, function()
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(-30)), 0.2)
			tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(30)), 0.2)
			task.wait(0.22)
			tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-70), 0, math.rad(-10)), 0.2)
			tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-70), 0, math.rad(10)), 0.2)
			task.wait(0.22)
		end)
	elseif name == "laugh" then
		startCustom(name, function()
			tj("Waist", CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(25), 0, 0), 0.25)
			task.wait(0.3)
			tj("Waist", CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(10), 0, 0), 0.25)
			task.wait(0.3)
		end)
	elseif name == "point" then
		savePose()
		CurEmote = name
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0), 0.35)
		notify("Emote: point")
	elseif name == "cry" then
		savePose()
		CurEmote = name
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-120), 0, math.rad(-20)), 0.4)
		tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-120), 0, math.rad(20)), 0.4)
		tj("Neck", CFrame.new(0, 1, 0) * CFrame.Angles(math.rad(20), 0, 0), 0.4)
		notify("Emote: cry")
	elseif name == "bow" then
		savePose()
		CurEmote = name
		tj("Waist", CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(45), 0, 0), 0.4)
		notify("Emote: bow")
	elseif name == "salute" then
		savePose()
		CurEmote = name
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-140), 0, math.rad(-20)), 0.35)
		notify("Emote: salute")
	elseif name == "think" then
		savePose()
		CurEmote = name
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-110), 0, math.rad(-30)), 0.4)
		notify("Emote: think")
	elseif name == "shy" then
		savePose()
		CurEmote = name
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-40), 0, math.rad(-40)), 0.4)
		tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-40), 0, math.rad(40)), 0.4)
		notify("Emote: shy")
	elseif name == "sleep" then
		savePose()
		CurEmote = name
		local h = getHum()
		if h then
			h.Sit = true
		end
		tj("Neck", CFrame.new(0, 1, 0) * CFrame.Angles(math.rad(25), math.rad(20), 0), 0.5)
		notify("Emote: sleep")
	elseif name == "sit" then
		local h = getHum()
		if h then
			h.Sit = true
		end
		CurEmote = name
		notify("Emote: sit")
	elseif name == "lay" then
		savePose()
		CurEmote = name
		local h = getHum()
		if h then
			h.Sit = true
		end
		tj("Waist", CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-70), 0, 0), 0.5)
		notify("Emote: lay")
	else
		notify("Unknown emote: " .. name)
	end
end

local function stopAllEmotes()
	detach()
	stopEmote()
	notify("Stopped emote")
end

-- ================= COMMAND HANDLER =================
local function runCommand(raw)
	if not raw or raw == "" then
		return
	end
	raw = raw:gsub("^%s+", "")
	raw = raw:gsub("%s+$", "")
	if raw:sub(1, 1) == PREFIX then
		raw = raw:sub(2)
	end
	if raw == "" then
		return
	end
	local args = split(raw)
	local cmd = args[1]:lower()
	table.remove(args, 1)
	logMsg(";" .. cmd .. " " .. table.concat(args, " "))
	if cmd == "cmds" or cmd == "help" or cmd == "ecmds" then
		toggleCmds()
	elseif cmd == "fly" then
		startFly()
	elseif cmd == "unfly" then
		stopFly()
	elseif cmd == "speed" or cmd == "ws" then
		local h = getHum()
		if h then
			local v = tonumber(args[1])
			if v == nil then
				v = 16
			end
			h.WalkSpeed = v
			notify("Speed: " .. tostring(h.WalkSpeed))
		end
	elseif cmd == "jump" or cmd == "jp" then
		local h = getHum()
		if h then
			local v = tonumber(args[1])
			if v == nil then
				v = 50
			end
			h.JumpPower = v
			notify("Jump: " .. tostring(h.JumpPower))
		end
	elseif cmd == "god" then
		setGod(true)
	elseif cmd == "ungod" then
		setGod(false)
	elseif cmd == "noclip" then
		setNoclip(true)
	elseif cmd == "clip" then
		setNoclip(false)
	elseif cmd == "spin" then
		local v = tonumber(args[1])
		if v == nil then
			v = 20
		end
		setSpin(v)
	elseif cmd == "unspin" then
		stopSpin()
	elseif cmd == "tp" or cmd == "goto" then
		local t = getPlayer(args[1])
		local m = getHRP()
		local th = nil
		if t then
			th = getHRP(t)
		end
		if m and th then
			m.CFrame = th.CFrame + Vector3.new(0, 3, 0)
			notify("TP to " .. t.DisplayName)
		end
	elseif cmd == "bring" then
		local t = getPlayer(args[1])
		local m = getHRP()
		local th = nil
		if t then
			th = getHRP(t)
		end
		if m and th then
			pcall(function()
				th.CFrame = m.CFrame + Vector3.new(0, 3, 0)
			end)
			notify("Bring " .. t.DisplayName)
		end
	elseif cmd == "fling" or cmd == "kill" then
		local t = getPlayer(args[1])
		local th = nil
		if t then
			th = getHRP(t)
		end
		if th then
			pcall(function()
				th.AssemblyLinearVelocity = Vector3.new(0, 200, 0)
				local bv = Instance.new("BodyAngularVelocity")
				bv.AngularVelocity = Vector3.new(0, 100, 0)
				bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				bv.Parent = th
				task.delay(1, function()
					bv:Destroy()
				end)
			end)
			notify("Fling " .. t.DisplayName)
		end
	elseif cmd == "reset" then
		local c = getChar()
		if c then
			c:BreakJoints()
		end
	elseif cmd == "sit" then
		local h = getHum()
		if h then
			h.Sit = true
		end
	elseif cmd == "blackhole" then
		startBH(getPlayer(args[1]))
	elseif cmd == "unblackhole" or cmd == "stopblackhole" then
		stopBH()
		notify("Blackhole OFF")
	elseif cmd == "tornado" then
		startTOR(getPlayer(args[1]))
	elseif cmd == "untornado" or cmd == "stoptornado" then
		stopTOR()
		notify("Tornado OFF")
	elseif cmd == "tsunami" then
		startTSU()
	elseif cmd == "untsunami" or cmd == "stoptsunami" then
		stopTSU()
		notify("Tsunami OFF")
	elseif cmd == "stop" or cmd == "stopall" then
		stopAll()
	elseif cmd == "hug" then
		attachTo(getPlayer(args[1]), "hug")
	elseif cmd == "unhug" then
		detach()
		notify("Unhugged")
	elseif cmd == "backpack" then
		attachTo(getPlayer(args[1]), "backpack")
	elseif cmd == "unbackpack" or cmd == "getoff" then
		detach()
		notify("Got off")
	elseif cmd == "headsit" then
		attachTo(getPlayer(args[1]), "headsit")
	elseif cmd == "unheadsit" then
		detach()
		notify("Off their head")
	elseif cmd == "headless" then
		setHeadless(true)
	elseif cmd == "unheadless" then
		setHeadless(false)
	elseif cmd == "stopemote" or cmd == "unemote" then
		stopAllEmotes()
	elseif cmd == "dance" or cmd == "dance2" or cmd == "dance3" or cmd == "floss" or cmd == "shuffle" or cmd == "dab" or cmd == "wave" or cmd == "point" or cmd == "cheer" or cmd == "laugh" or cmd == "cry" or cmd == "bow" or cmd == "salute" or cmd == "think" or cmd == "shy" or cmd == "clap" or cmd == "sleep" or cmd == "lay" then
		doEmote(cmd)
	else
		notify("Unknown: " .. cmd .. " - try ;cmds")
	end
end

local function submit()
	if barBox.Text ~= "" then
		runCommand(barBox.Text)
		barBox.Text = ""
	end
end

barBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		submit()
	end
end)

runBtn.MouseButton1Click:Connect(submit)

stopBtn.MouseButton1Click:Connect(function()
	stopAll()
	stopAllEmotes()
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.Semicolon and not gp then
		maximise()
		barBox:CaptureFocus()
	end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if main.Visible then
			minimise()
		else
			maximise()
		end
	end
end)

LocalPlayer.Chatted:Connect(function(m)
	if m:sub(1, 1) == PREFIX then
		runCommand(m)
	end
end)

savePose()
notify("ANTH HUB loaded - ;cmds for list, X minimises to ANTH logo")
print("[ANTH HUB] Loaded - Delta fixed version.")
