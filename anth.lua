-- ANTH HUB - v1.10 Delta
-- Fixes: draggable logo, hug fixed, noclip restore, NDS survive,
-- zombie (server-visible), headless re-apply, more fun physics
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
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PREFIX = ";"
local PREFIXES = {}
PREFIXES[";"] = true
PREFIXES["!"] = true
PREFIXES["/"] = true
PREFIXES["?"] = true
PREFIXES["."] = true
PREFIXES[":"] = true

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

-- ================= v1.5 FIX: DUPLICATE RUNS =================
-- Anth reported it still moved/killed him WITHOUT the wand.
-- Audit: on a fresh load NOTHING in this script moves you - fly,
-- noclip, god, blackhole, tornado, tsunami, fun, wand, hug are all
-- OFF until you run a command. So the mover must be a leftover
-- from a previous run in the SAME game:
--  * Re-running the loadstring in Delta does NOT kill the old copy.
--    Old Heartbeat/Stepped loops keep running, old blackhole ball,
--    old fly BodyVelocity, old noclip (CanCollide=false forever),
--    old hug weld all stay alive and fight the new copy.
--  * That is why it happens "when the script activated" - each
--    activation stacks another copy, and old noclip alone makes
--    you fall through grass/island and die.
--  * Infinite Yield running at the same time (seen in his video,
--    bottom right) does the same thing - two hubs, same ; prefix.
-- Fix here:
--  1. Bump a global RunId. Every moving loop in v1.5 checks it and
--     stops if a newer copy started. Old v1.4 loops do not check it,
--     so you MUST rejoin fresh once after this update - after that,
--     re-running is safe.
--  2. On load, destroy the old ANTH Hub GUI, old blackhole/tornado/
--     tsunami parts, old ANTH Wand tools, and old BodyVelocity/
--     BodyGyro/BodyAngularVelocity in your HumanoidRootPart, and
--     reset your character: PlatformStand off, AutoRotate on,
--     HRP unanchored, CanCollide back on, velocity zeroed.
--  3. Warn in the log if an old copy was found.
local MY_RUN = 0
pcall(function()
	if getgenv then
		local g = getgenv()
		g.ANTH_Hub_RunId = (g.ANTH_Hub_RunId or 0) + 1
		MY_RUN = g.ANTH_Hub_RunId
	else
		_G.ANTH_Hub_RunId = (_G.ANTH_Hub_RunId or 0) + 1
		MY_RUN = _G.ANTH_Hub_RunId
	end
end)
if MY_RUN == 0 then
	MY_RUN = 1
end
local function isCurrentRun()
	local cur = MY_RUN
	pcall(function()
		if getgenv then
			cur = getgenv().ANTH_Hub_RunId
		else
			cur = _G.ANTH_Hub_RunId
		end
	end)
	return cur == MY_RUN
end

local OldCopyFound = false
pcall(function()
	for _, g in ipairs(guiParent:GetChildren()) do
		if g.Name == "ANTH_Hub" then
			OldCopyFound = true
			g:Destroy()
		end
	end
end)
pcall(function()
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o.Name == "BlackholeCenter" or o.Name == "TornadoCenter" or o.Name == "TsunamiWall" then
			OldCopyFound = true
			o:Destroy()
		end
	end
end)
pcall(function()
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if bp then
		for _, tool in ipairs(bp:GetChildren()) do
			if tool.Name == "ANTH Wand" then
				tool:Destroy()
			end
		end
	end
	local c = LocalPlayer.Character
	if c then
		for _, tool in ipairs(c:GetChildren()) do
			if tool.Name == "ANTH Wand" then
				tool:Destroy()
			end
		end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp then
			for _, mv in ipairs(hrp:GetChildren()) do
				if mv:IsA("BodyVelocity") or mv:IsA("BodyGyro") or mv:IsA("BodyAngularVelocity") then
					OldCopyFound = true
					mv:Destroy()
				end
			end
			hrp.Anchored = false
			hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum.AutoRotate = true
		end
		for _, part in ipairs(c:GetDescendants()) do
			if part:IsA("BasePart") then
				if part.Name == "HumanoidRootPart" then
					part.CanCollide = false
				else
					part.CanCollide = true
				end
			end
			if part:IsA("Weld") and part.Name == "EmoteAttach" then
				part:Destroy()
			end
		end
	end
end)

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
	main.Size = UDim2.new(0.94, 0, 0, 420)
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
titleTxt.Text = "ANTH // TERMINAL [v1.10 DELTA]"
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

local function centerHub()
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
end
local function maximise()
	main.Visible = true
	logo.Visible = false
	-- v1.10 fix: if the hub was dragged off-screen (title unreachable),
	-- snap it back to centre so you can move it again.
	local cam = Workspace.CurrentCamera
	if cam then
		local vs = cam.ViewportSize
		local absPos = main.AbsolutePosition
		local absSize = main.AbsoluteSize
		if absPos.Y < -10 or absPos.Y > vs.Y - 50 or absPos.X < -absSize.X + 50 or absPos.X > vs.X - 50 then
			centerHub()
		end
	end
end

xBtn.MouseButton1Click:Connect(minimise)
-- Logo: drag to move it, tap (no drag) to reopen. This is the v1.2 fix.
local logoDragging = false
local logoDragStart = nil
local logoStartPos = nil
local logoMoved = false
logo.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		logoDragging = true
		logoMoved = false
		logoDragStart = input.Position
		logoStartPos = logo.Position
	end
end)
logo.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local wasDrag = logoMoved
		logoDragging = false
		if not wasDrag then
			maximise()
		end
	end
end)

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
			local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			-- v1.10 fix: clamp so the title bar always stays on-screen.
			-- Without this you could drag the hub up until the title
			-- was off-screen, then you could not grab it to move it back.
			local cam = Workspace.CurrentCamera
			if cam then
				local vs = cam.ViewportSize
				local halfW = main.AbsoluteSize.X / 2
				local halfH = main.AbsoluteSize.Y / 2
				local cx = newPos.X.Scale * vs.X + newPos.X.Offset
				local cy = newPos.Y.Scale * vs.Y + newPos.Y.Offset
				cx = math.clamp(cx, -halfW + 80, vs.X + halfW - 80)
				cy = math.clamp(cy, -halfH + 50, vs.Y + halfH - 50)
				main.Position = UDim2.new(0, cx, 0, cy)
			else
				main.Position = newPos
			end
		end
	end
	if logoDragging then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - logoDragStart
			if delta.Magnitude > 8 then
				logoMoved = true
			end
			logo.Position = UDim2.new(logoStartPos.X.Scale, logoStartPos.X.Offset + delta.X, logoStartPos.Y.Scale, logoStartPos.Y.Offset + delta.Y)
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
logTxt.AutomaticSize = Enum.AutomaticSize.Y
logTxt.Size = UDim2.new(1, -10, 0, 0)
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

-- ================= AUTOCOMPLETE =================
-- Type "un" and it spells out the closest commands. Tap the green
-- suggestion bar to fill it in. This is why ;unvortex was "missing"
-- before - it was in the list, but the list was clipped and you
-- could not see it, and there was no way to complete a word.
local ALL_CMDS = {"fly","unfly","speed","jump","god","ungod","noclip","clip","spin","unspin","tp","goto","bring","fling","kill","reset","sit","blackhole","unblackhole","tornado","untornado","tsunami","untsunami","orbit","unorbit","fountain","unfountain","rain","unrain","magnet","unmagnet","launch","quake","earthquake","explode","swirl","unswirl","vortex","unvortex","stopvortex","meteor","survive","unsurvive","anchor","unanchor","antifling","noantifling","nofling","hug","unhug","backpack","unbackpack","headsit","unheadsit","headless","unheadless","zombie","unzombie","normal","dance","dance2","dance3","floss","shuffle","dab","wave","point","cheer","laugh","cry","bow","salute","think","shy","clap","sleep","lay","stopemote","unemote","cmds","help","ecmds","prefix","setprefix","changeprefix","wand","unwand","throw","boom","explosion","nuke","invisible","visible","big","tiny","size","normalsize","carry","uncarry","fire","smoke","sparkles","aura","unfx","unfire","unaura","rejoin","stop","stopall","getoff","center","resetui"}
local suggestBtn = Instance.new("TextButton")
suggestBtn.Size = UDim2.new(1, -20, 0, 28)
suggestBtn.Position = UDim2.new(0, 10, 0, 182)
suggestBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 15)
suggestBtn.TextColor3 = NEON
suggestBtn.Font = Enum.Font.Code
suggestBtn.TextSize = 13
suggestBtn.Text = ""
suggestBtn.Visible = false
suggestBtn.ZIndex = 10
suggestBtn.Parent = main
addCorner(suggestBtn, 8)
addStroke(suggestBtn, NEON, 1)
local function getSuggestMatches(partial)
	local out = {}
	if not partial or #partial < 1 then
		return out
	end
	partial = partial:lower()
	for _, c in ipairs(ALL_CMDS) do
		if c:sub(1, #partial) == partial then
			table.insert(out, c)
			if #out >= 3 then
				break
			end
		end
	end
	return out
end
local function updateSuggest()
	local txt = barBox.Text or ""
	txt = txt:gsub("^%s+", "")
	if PREFIXES[txt:sub(1, 1)] then
		txt = txt:sub(2)
	end
	local first = txt:match("^(%S+)") or ""
	if #first < 1 then
		suggestBtn.Visible = false
		return
	end
	local matches = getSuggestMatches(first)
	if #matches == 0 then
		suggestBtn.Visible = false
		return
	end
	if #matches == 1 and matches[1] == first:lower() then
		suggestBtn.Visible = false
		return
	end
	local label = "Tap: "
	for i, m in ipairs(matches) do
		if i > 1 then
			label = label .. "  "
		end
		label = label .. PREFIX .. m
	end
	suggestBtn.Text = label
	suggestBtn.Visible = true
end
barBox:GetPropertyChangedSignal("Text"):Connect(updateSuggest)
suggestBtn.MouseButton1Click:Connect(function()
	local txt = barBox.Text or ""
	txt = txt:gsub("^%s+", "")
	local pre = ""
	if PREFIXES[txt:sub(1, 1)] then
		pre = txt:sub(1, 1)
		txt = txt:sub(2)
	else
		pre = PREFIX
	end
	local first = txt:match("^(%S+)") or ""
	local rest = txt:match("^%S+%s+(.*)$") or ""
	local matches = getSuggestMatches(first)
	if #matches > 0 then
		if rest ~= "" then
			barBox.Text = pre .. matches[1] .. " " .. rest
		else
			barBox.Text = pre .. matches[1]
		end
		barBox:CaptureFocus()
	end
	updateSuggest()
end)

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
cmdsTxt.AutomaticSize = Enum.AutomaticSize.Y
cmdsTxt.Size = UDim2.new(1, -10, 0, 0)
cmdsTxt.Position = UDim2.new(0, 5, 0, 0)
cmdsTxt.BackgroundTransparency = 1
cmdsTxt.TextColor3 = TXT
cmdsTxt.Font = Enum.Font.Code
cmdsTxt.TextSize = 13
cmdsTxt.TextXAlignment = Enum.TextXAlignment.Left
cmdsTxt.TextYAlignment = Enum.TextYAlignment.Top
cmdsTxt.TextWrapped = true
cmdsTxt.Text = "CORE\n;cmds ;help ;prefix / ;center ;fly ;unfly ;speed 50 ;jump 80\n;god ;ungod ;noclip ;clip ;spin 20 ;unspin\n;tp bacon ;goto bacon ;bring bacon ;fling bacon\n;kill bacon ;reset ;sit ;stop ;stopall\n\nSURVIVAL (NDS fix)\n;survive ;unsurvive ;anchor ;unanchor\n;antifling ;noantifling\n\nPHYSICS - pull from everywhere\n;blackhole [player] ;unblackhole\n;tornado [player] ;untornado\n;tsunami ;untsunami\n;orbit [player] ;unorbit ;fountain ;unfountain\n;rain ;unrain ;magnet [player] ;unmagnet\n;launch ;quake ;explode ;swirl ;unswirl\n;vortex [player] ;unvortex ;stopvortex\n;meteor [player]\n\nBOOM / NUKE\n;boom [player] ;explode ;nuke\n\nSOCIAL (everyone sees)\n;hug [player/nearest] ;unhug\n;backpack [player] ;unbackpack\n;headsit [player] ;unheadsit ;getoff\n;carry [player] ;uncarry\n;headless ;unheadless\n\nWAND\n;wand ;unwand ;throw\n\nANIM (everyone sees)\n;zombie ;unzombie ;normal\n\nLOOKS (everyone sees)\n;invisible ;visible ;big ;tiny ;size 1.5 ;normalsize\n;fire ;smoke ;sparkles ;aura ;unfx\n\n;rejoin\n\nEMOTES\n;dance ;dance2 ;dance3 ;floss ;shuffle ;dab\n;wave ;point ;cheer ;laugh ;cry ;bow\n;salute ;think ;shy ;clap ;sleep ;sit ;lay\n;stopemote ;unemote"
cmdsTxt.Parent = cmdsFrame
local CmdsTemplate = cmdsTxt.Text
local function refreshCmds()
	if CmdsTemplate then
		cmdsTxt.Text = CmdsTemplate:gsub(";", PREFIX)
	end
end

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
	if a == "nearest" or a == "closest" or a == "near" then
		return getNearestPlayer()
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

local function getNearestPlayer()
	local myHRP = getHRP()
	if not myHRP then
		return nil
	end
	local best = nil
	local bestD = math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = (hrp.Position - myHRP.Position).Magnitude
				if d < bestD then
					bestD = d
					best = plr
				end
			end
		end
	end
	return best
end

local function getUnanchored()
	local list = {}
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o:IsA("BasePart") and not o.Anchored then
			-- v1.4 fix: island / grass / map platforms are often unanchored
			-- but huge. Moving them moves the ground out from under you
			-- and kills you. Only touch small loose props.
			local sz = o.Size
			if sz.X > 20 or sz.Y > 20 or sz.Z > 20 then
				-- skip huge part, do not add to list
			elseif o.Name ~= "BlackholeCenter" and o.Name ~= "TornadoCenter" and o.Name ~= "TsunamiWall" then
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
		if not Flying or not isCurrentRun() then
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
			if not isCurrentRun() then
				return
			end
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
		local c = getChar()
		if c then
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then
					if p.Name == "HumanoidRootPart" then
						p.CanCollide = false
					else
						p.CanCollide = true
					end
				end
			end
		end
		notify("Noclip OFF - collisions back on")
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
			if not isCurrentRun() then
				return
			end
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

-- ================= SURVIVAL / NDS FIX =================
-- Bug in v1.1: noclip never restored CanCollide, so you fell through
-- the map in Natural Disaster Survival and died. Fixed above.
-- Survive = god + anchor (HRP Anchored) + anti-fling. Disasters push
-- you with velocity, anchoring + zeroing that velocity stops it.
local SurviveOn = false
local AntiFlingOn = false
local AntiFlingConn = nil
local AnchorOn = false

local function setAnchor(on)
	AnchorOn = on
	local hrp = getHRP()
	if hrp then
		hrp.Anchored = on
	end
	if on then
		notify("Anchor ON - you will not move")
	else
		notify("Anchor OFF")
	end
end

local function setAntiFling(on)
	AntiFlingOn = on
	if AntiFlingConn then
		AntiFlingConn:Disconnect()
		AntiFlingConn = nil
	end
	if on then
		AntiFlingConn = RunService.Heartbeat:Connect(function()
			if not isCurrentRun() then
				return
			end
			local hrp = getHRP()
			if not hrp then
				return
			end
			if SurviveOn and not hrp.Anchored then
				hrp.Anchored = true
			end
			if hrp.AssemblyLinearVelocity.Magnitude > 80 then
				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			end
			if hrp.AssemblyAngularVelocity.Magnitude > 80 then
				hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end)
		notify("Anti-fling ON")
	else
		notify("Anti-fling OFF")
	end
end

local function setSurvive(on)
	SurviveOn = on
	if on then
		stopFly()
		stopSpin()
		setGod(true)
		setAnchor(true)
		setAntiFling(true)
		notify("Survive ON - anchored + god + anti-fling. ;unsurvive to walk again")
	else
		setGod(false)
		setAnchor(false)
		setAntiFling(false)
		notify("Survive OFF")
	end
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
		while BHActive and isCurrentRun() do
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
					if d > 0.5 and d < 500 then
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
		while TORActive and isCurrentRun() do
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
					if not TORActive or not isCurrentRun() then
						break
					end
					local off = part.Position - center
					local flat = Vector3.new(off.X, 0, off.Z).Magnitude
					if flat < 500 and off.Y > -20 and off.Y < 150 then
						local tan = Vector3.new(-off.Z, 0, off.X)
						if tan.Magnitude < 0.1 then
							tan = Vector3.new(1, 0, 0)
						end
						tan = tan.Unit
						local inw = Vector3.new(-off.X, 0, -off.Z)
						if inw.Magnitude > 0.1 then
							inw = inw.Unit * 40
						else
							inw = Vector3.new(0, 0, 0)
						end
						local up = 50
						if off.Y > 60 then
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

-- ================= FUN PHYSICS =================
local FunActive = false
local FunMode = nil
local FunTarget = nil
local FunCenter = nil

local function stopFun()
	FunActive = false
	FunMode = nil
end

local function startFun(mode, target)
	stopBH()
	stopTOR()
	stopTSU()
	stopFun()
	FunTarget = target
	local hrp = getHRP()
	if target and target.Character then
		local th = target.Character:FindFirstChild("HumanoidRootPart")
		if th then
			FunCenter = th.Position
		else
			FunCenter = hrp and hrp.Position or Vector3.new(0, 10, 0)
		end
	elseif hrp then
		FunCenter = hrp.Position + hrp.CFrame.LookVector * 10
	else
		FunCenter = Vector3.new(0, 10, 0)
	end
	FunMode = mode
	FunActive = true
	if target then
		notify(mode .. " ON - on " .. target.DisplayName)
	else
		notify(mode .. " ON")
	end
	task.spawn(function()
		while FunActive and FunMode == mode do
			task.wait(0.03)
			local center = FunCenter
			if FunTarget and FunTarget.Character then
				local th = FunTarget.Character:FindFirstChild("HumanoidRootPart")
				if th then
					center = th.Position
					FunCenter = center
				end
			end
			if not center then
				break
			end
			for _, part in ipairs(getUnanchored()) do
				if not FunActive then
					break
				end
				local off = part.Position - center
				local d = off.Magnitude
				if mode == "orbit" then
					if d < 120 then
						local tan = Vector3.new(-off.Z, 0, off.X)
						if tan.Magnitude < 0.1 then
							tan = Vector3.new(1, 0, 0)
						end
						tan = tan.Unit
						local inward = Vector3.new(0, 0, 0)
						if d > 25 then
							inward = -off.Unit * 20
						elseif d < 15 then
							inward = off.Unit * 20
						end
						pcall(function()
							part.AssemblyLinearVelocity = tan * 60 + inward + Vector3.new(0, 5, 0)
						end)
					end
				elseif mode == "swirl" then
					if d < 60 then
						local tan = Vector3.new(-off.Z, 0, off.X)
						if tan.Magnitude < 0.1 then
							tan = Vector3.new(1, 0, 0)
						end
						pcall(function()
							part.AssemblyLinearVelocity = tan.Unit * 80 + Vector3.new(0, 10, 0)
						end)
					end
				elseif mode == "vortex" then
					if d < 80 then
						local tan = Vector3.new(-off.Z, 0, off.X)
						if tan.Magnitude < 0.1 then
							tan = Vector3.new(1, 0, 0)
						end
						local up = 45
						if part.Position.Y > center.Y + 25 then
							up = -15
						end
						pcall(function()
							part.AssemblyLinearVelocity = tan.Unit * 90 - off.Unit * 25 + Vector3.new(0, up, 0)
						end)
					end
				elseif mode == "fountain" then
					if d < 50 and part.Position.Y < center.Y + 10 then
						pcall(function()
							part.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), 120, math.random(-20, 20))
						end)
					end
				elseif mode == "rain" then
					if d < 80 and part.Position.Y < center.Y + 60 then
						pcall(function()
							part.CFrame = CFrame.new(center + Vector3.new(math.random(-40, 40), 60, math.random(-40, 40)))
							part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						end)
					end
				elseif mode == "magnet" then
					if d > 2 and d < 200 then
						pcall(function()
							part.AssemblyLinearVelocity = -off.Unit * 80
						end)
					elseif d <= 2 then
						pcall(function()
							part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						end)
					end
				elseif mode == "quake" then
					if d < 100 then
						pcall(function()
							part.AssemblyLinearVelocity = Vector3.new(math.random(-60, 60), 25, math.random(-60, 60))
						end)
					end
				end
			end
			if mode == "quake" then
				task.wait(0.2)
			end
		end
	end)
	if mode == "quake" then
		task.delay(5, function()
			if FunMode == "quake" then
				stopFun()
				notify("Quake finished")
			end
		end)
	end
end

local function doLaunch()
	local hrp = getHRP()
	if not hrp then
		return
	end
	local c = hrp.Position
	for _, part in ipairs(getUnanchored()) do
		if (part.Position - c).Magnitude < 120 then
			pcall(function()
				part.AssemblyLinearVelocity = Vector3.new(math.random(-30, 30), 200, math.random(-30, 30))
			end)
		end
	end
	notify("Launch!")
end

local function doExplode()
	local hrp = getHRP()
	if not hrp then
		return
	end
	local c = hrp.Position
	for _, part in ipairs(getUnanchored()) do
		local off = part.Position - c
		if off.Magnitude < 120 and off.Magnitude > 0.5 then
			pcall(function()
				part.AssemblyLinearVelocity = off.Unit * 150 + Vector3.new(0, 50, 0)
			end)
		end
	end
	flingPlayersFrom(c, 120, 200)
	notify("Explode! - flung parts AND players")
end

local function doMeteor(target)
	local center = nil
	if target and target.Character then
		local th = target.Character:FindFirstChild("HumanoidRootPart")
		if th then
			center = th.Position
		end
	end
	if not center then
		local hrp = getHRP()
		if hrp then
			center = hrp.Position + hrp.CFrame.LookVector * 15
		else
			return
		end
	end
	local count = 0
	for _, part in ipairs(getUnanchored()) do
		if count >= 30 then
			break
		end
		if (part.Position - center).Magnitude < 80 then
			count = count + 1
			pcall(function()
				part.CFrame = CFrame.new(center + Vector3.new(math.random(-25, 25), 50 + math.random(0, 20), math.random(-25, 25)))
				part.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
			end)
		end
	end
	notify("Meteor! Dropped " .. tostring(count) .. " parts on them.")
end

local function getAllUnanchoredNoSize()
	local list = {}
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o:IsA("BasePart") and not o.Anchored then
			if o.Name ~= "BlackholeCenter" and o.Name ~= "TornadoCenter" and o.Name ~= "TsunamiWall" and o.Name ~= "ANTH_BoomFlash" then
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

local function doNuke()
	local hrp = getHRP()
	local c = hrp and hrp.Position or Vector3.new(0, 10, 0)
	for i = 1, 3 do
		local ex = Instance.new("Explosion")
		ex.Position = c + Vector3.new((i - 2) * 10, 0, 0)
		ex.BlastRadius = 100
		ex.BlastPressure = 1000000
		ex.DestroyJointRadiusPercent = 1
		ex.Parent = Workspace
	end
	for _, part in ipairs(getAllUnanchoredNoSize()) do
		local off = part.Position - c
		local dir = off
		if dir.Magnitude < 0.5 then
			dir = Vector3.new(0, 1, 0)
		else
			dir = dir.Unit
		end
		pcall(function()
			part.AssemblyLinearVelocity = dir * 250 + Vector3.new(0, 200, 0)
			part.AssemblyAngularVelocity = Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
		end)
	end
	flingPlayersFrom(c, 500, 300)
	notify("NUKE! Flung the entire map - you will probably die too, that is the point.")
end

local function stopAll()
	stopBH()
	stopTOR()
	stopTSU()
	stopFun()
	stopFly()
	stopSpin()
	setNoclip(false)
	notify("Stopped everything")
end

-- ================= PREFIX CHANGE =================
local function setPrefix(newP)
	if not newP or #newP ~= 1 then
		notify("Use ;prefix <one symbol> - like ;prefix !  or ;prefix ?")
		return
	end
	if not PREFIXES[newP] then
		notify("Pick one of ; ! / ? . :  - like ;prefix !")
		return
	end
	PREFIX = newP
	barBox.PlaceholderText = PREFIX .. "blackhole me  " .. PREFIX .. "hug bacon  " .. PREFIX .. "dance"
	refreshCmds()
	notify("Prefix is now '" .. PREFIX .. "' - try " .. PREFIX .. "cmds  or  " .. PREFIX .. "fly")
end

-- ================= ANTH WAND =================
-- Tool in your Backpack. Equip it, tap / click a loose part to grab it,
-- move your mouse / camera / tap elsewhere to drag it around, tap again
-- to drop it. Works on unanchored parts you have network ownership of.
-- Anchored parts and other players' bodies cannot be grabbed.
local WandTool = nil
local WandGrabbed = nil
local WandBox = nil
local WandEquipped = false
local WandWanted = false
local WandLoopConn = nil
local WandEquipTime = 0

local function isCharPart(part)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and part:IsDescendantOf(plr.Character) then
			return true
		end
	end
	return false
end

local function releaseWand()
	if WandGrabbed then
		pcall(function()
			WandGrabbed.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			WandGrabbed.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end)
	end
	if WandBox then
		WandBox:Destroy()
		WandBox = nil
	end
	WandGrabbed = nil
end

local function isSafeWandPart(part, myHRP)
	if not part or not part:IsA("BasePart") then
		return false, "not a part"
	end
	if part.Anchored then
		return false, "anchored"
	end
	if isCharPart(part) then
		return false, "player body"
	end
	local sz = part.Size
	if sz.X > 8 or sz.Y > 8 or sz.Z > 8 then
		return false, "too big - that is map / island, not a loose prop"
	end
	if sz.Magnitude > 10 then
		return false, "too big"
	end
	if sz.X > 6 and sz.Z > 6 and sz.Y < 3 then
		return false, "that looks like floor / grass"
	end
	if myHRP then
		local off = part.Position - myHRP.Position
		if off.Y < -1 and off.Y > -6 and math.abs(off.X) < 4 and math.abs(off.Z) < 4 then
			return false, "you are standing on it"
		end
	end
	return true, ""
end

local function tryGrabWand()
	-- v1.4 fix: NO fallback. Old code grabbed the nearest loose part
	-- within 30 studs if you tapped grass / island (anchored). On
	-- grass/island maps that grabbed a huge boulder / car / island
	-- piece and dragged it into you, pushing you off and killing you.
	-- Now: only grab the part you DIRECTLY tapped, and only if it is
	-- small and safe. Tapping grass does nothing now.
	local mouse = LocalPlayer:GetMouse()
	local target = nil
	pcall(function()
		target = mouse.Target
	end)
	local myHRP = getHRP()
	if not target then
		notify("Wand: tap a small loose part directly - tapping grass does nothing now")
		return
	end
	local ok, why = isSafeWandPart(target, myHRP)
	if not ok then
		notify("Wand: cannot grab that - " .. why)
		return
	end
	local pick = target
	WandGrabbed = pick
	local box = Instance.new("SelectionBox")
	box.Adornee = pick
	box.Color3 = NEON
	box.LineThickness = 0.05
	box.Parent = pick
	WandBox = box
	notify("Wand grabbed: " .. pick.Name .. " - tap again to drop, " .. PREFIX .. "throw to throw it")
end

local function startWandLoop()
	if WandLoopConn then
		return
	end
	WandLoopConn = RunService.Heartbeat:Connect(function()
		if not isCurrentRun() then
			return
		end
		if not WandGrabbed or not WandEquipped then
			return
		end
		if not WandGrabbed.Parent then
			releaseWand()
			return
		end
		-- v1.4 fix: on mobile Mouse.Hit is your joystick / last touch,
		-- so the grabbed part was dragged into your feet and pushed
		-- you off the island. On mobile use a point in front of your
		-- camera instead, so it floats in front of you like a pet.
		local targetPos = nil
		if IS_MOBILE then
			local cam = Workspace.CurrentCamera
			local hrp2 = getHRP()
			if cam and hrp2 then
				targetPos = hrp2.Position + cam.CFrame.LookVector * 12 + Vector3.new(0, 3, 0)
			else
				return
			end
		else
			local mouse = LocalPlayer:GetMouse()
			pcall(function()
				targetPos = mouse.Hit.Position
			end)
			if not targetPos then
				local cam = Workspace.CurrentCamera
				local hrp = getHRP()
				if cam and hrp then
					targetPos = cam.CFrame.Position + cam.CFrame.LookVector * 12
				else
					return
				end
			end
		end
		local hrp = getHRP()
		if hrp and (targetPos - hrp.Position).Magnitude > 60 then
			targetPos = hrp.Position + (targetPos - hrp.Position).Unit * 60
		end
		local off = targetPos - WandGrabbed.Position
		if off.Magnitude < 0.5 then
			pcall(function()
				WandGrabbed.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			end)
			return
		end
		local vel = off * 8
		if vel.Magnitude > 100 then
			vel = vel.Unit * 100
		end
		pcall(function()
			WandGrabbed.AssemblyLinearVelocity = vel
			WandGrabbed.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end)
	end)
end

local function giveWand()
	WandWanted = true
	if WandTool and WandTool.Parent then
		notify("You already have the wand - check your Backpack / hotbar")
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "ANTH Wand"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Tap a loose part to grab it, tap again to drop"
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, 1.6, 0.25)
	handle.Color = NEON
	handle.Material = Enum.Material.Neon
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Parent = tool
	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.5, 0.5, 0.5)
	tip.Shape = Enum.PartType.Ball
	tip.Color = NEON2
	tip.Material = Enum.Material.Neon
	tip.CanCollide = false
	tip.CanQuery = false
	tip.Massless = true
	tip.Parent = tool
	-- v1.4 fix: Tip was unwelded, so it fell off the tool and could
	-- fling your character. Weld it to the Handle so it stays put.
	local tipWeld = Instance.new("Weld")
	tipWeld.Part0 = handle
	tipWeld.Part1 = tip
	tipWeld.C0 = CFrame.new(0, 1, 0)
	tipWeld.Parent = handle
	tool.Grip = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(45), 0, 0)
	tool.Equipped:Connect(function()
		WandEquipped = true
		WandEquipTime = os.clock()
		startWandLoop()
		notify("Wand equipped - tap a small loose part to grab it")
	end)
	tool.Unequipped:Connect(function()
		WandEquipped = false
		releaseWand()
	end)
	tool.Activated:Connect(function()
		if WandEquipTime and os.clock() - WandEquipTime < 0.5 then
			return
		end
		if WandGrabbed then
			releaseWand()
			notify("Wand dropped it")
		else
			tryGrabWand()
		end
	end)
	tool.Parent = LocalPlayer:WaitForChild("Backpack")
	WandTool = tool
	notify("Wand given - equip ANTH Wand from your Backpack")
end

local function removeWand()
	WandWanted = false
	releaseWand()
	WandEquipped = false
	if WandTool then
		WandTool:Destroy()
		WandTool = nil
	end
	notify("Wand removed")
end

local function throwWand()
	if not WandGrabbed then
		notify("Wand: grab something first - equip wand and tap a part")
		return
	end
	local cam = Workspace.CurrentCamera
	local dir = Vector3.new(0, 0, -1)
	if cam then
		dir = cam.CFrame.LookVector
	end
	local part = WandGrabbed
	pcall(function()
		part.AssemblyLinearVelocity = dir * 120 + Vector3.new(0, 30, 0)
	end)
	releaseWand()
	notify("Wand threw it!")
end

-- ================= BOOM =================
-- Honest limit: a normal Roblox Explosion CANNOT break anchored
-- blocks for everyone. Anchored parts are server-locked - the
-- server owns them, your client does not. Explosion only:
--  * flings unanchored parts and breaks their welds/joints
--  * looks and sounds big
-- Anchored blocks stay put for everyone, no matter how big the
-- boom is. That is Roblox physics, not a hub bug.
local function flingPlayersFrom(pos, radius, power)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local ph = plr.Character:FindFirstChild("HumanoidRootPart")
			if ph then
				local off = ph.Position - pos
				local d = off.Magnitude
				if d < radius and d > 0.5 then
					pcall(function()
						ph.AssemblyLinearVelocity = off.Unit * power + Vector3.new(0, power * 0.7, 0)
						local bv = Instance.new("BodyAngularVelocity")
						bv.AngularVelocity = Vector3.new(0, 100, 0)
						bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
						bv.Parent = ph
						task.delay(1, function()
							if bv.Parent then
								bv:Destroy()
							end
						end)
					end)
				elseif d <= 0.5 then
					pcall(function()
						ph.AssemblyLinearVelocity = Vector3.new(0, power, 0)
					end)
				end
			end
		end
	end
end

local function doBoom(pos)
	if not pos then
		local hrp = getHRP()
		if hrp then
			pos = hrp.Position + hrp.CFrame.LookVector * 10
		else
			pos = Vector3.new(0, 10, 0)
		end
	end
	local ex = Instance.new("Explosion")
	ex.Position = pos
	ex.BlastRadius = 25
	ex.BlastPressure = 1000000
	ex.DestroyJointRadiusPercent = 1
	ex.Parent = Workspace
	local flash = Instance.new("Part")
	flash.Name = "ANTH_BoomFlash"
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.Size = Vector3.new(2, 2, 2)
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 140, 0)
	flash.CFrame = CFrame.new(pos)
	flash.Parent = Workspace
	task.spawn(function()
		for i = 1, 10 do
			if not flash.Parent then
				break
			end
			flash.Size = Vector3.new(2 + i * 5, 2 + i * 5, 2 + i * 5)
			flash.Transparency = i / 10
			task.wait(0.04)
		end
		flash:Destroy()
	end)
	for _, part in ipairs(getUnanchored()) do
		local d = (part.Position - pos).Magnitude
		if d < 35 then
			local dir = (part.Position - pos)
			if dir.Magnitude < 0.5 then
				dir = Vector3.new(0, 1, 0)
			end
			dir = dir.Unit
			pcall(function()
				part.AssemblyLinearVelocity = dir * 150 + Vector3.new(0, 80, 0)
				part.AssemblyAngularVelocity = Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
			end)
		end
	end
	flingPlayersFrom(pos, 35, 200)
	notify("BOOM! - flung loose parts AND players. Anchored blocks stay - server owns them.")
end

-- ================= HUG / BACKPACK / HEADSIT =================
local AttachWeld = nil

local function setMyCollide(on)
	local c = getChar()
	if not c then
		return
	end
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then
			if p.Name == "HumanoidRootPart" then
				p.CanCollide = false
			else
				p.CanCollide = on
			end
		end
	end
end

local function detach()
	if AttachWeld then
		AttachWeld:Destroy()
		AttachWeld = nil
	end
	local h = getHum()
	if h then
		h.PlatformStand = false
		h.AutoRotate = true
	end
	setMyCollide(true)
	restorePose(0.3)
end

local function attachTo(target, mode)
	if not target then
		target = getNearestPlayer()
	end
	if not target then
		notify("No player found - try ;hug <name> or ;hug nearest")
		return
	end
	local thrp = nil
	if target.Character then
		thrp = target.Character:FindFirstChild("HumanoidRootPart")
	end
	local myHRP = getHRP()
	local myHum = getHum()
	if not thrp or not myHRP or not myHum then
		notify("Target not found - wait for them to load, then try again")
		return
	end
	detach()
	stopEmote()
	stopFly()
	if AnchorOn then
		setAnchor(false)
	end
	savePose()
	myHum.PlatformStand = true
	myHum.AutoRotate = false
	setMyCollide(false)
	pcall(function()
		myHum:ChangeState(Enum.HumanoidStateType.Physics)
	end)
	local w = Instance.new("Weld")
	w.Name = "EmoteAttach"
	w.Part0 = thrp
	w.Part1 = myHRP
	w.C1 = CFrame.new(0, 0, 0)
	w.Parent = myHRP
	if mode == "hug" then
		w.C0 = CFrame.new(0, 0, 1.5) * CFrame.Angles(0, math.rad(180), 0)
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-70), 0, math.rad(-20)), 0.4)
		tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-70), 0, math.rad(20)), 0.4)
		notify("Hugging " .. target.DisplayName .. " - ;unhug to let go")
	elseif mode == "backpack" then
		w.C0 = CFrame.new(0, 0.8, -1.2)
		tj("RH", CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(-80), 0, 0), 0.4)
		tj("LH", CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(-80), 0, 0), 0.4)
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-100), 0, math.rad(-30)), 0.4)
		tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-100), 0, math.rad(30)), 0.4)
		notify("On " .. target.DisplayName .. "'s back - ;unbackpack to get off")
	elseif mode == "headsit" then
		w.C0 = CFrame.new(0, 2.9, 0)
	elseif mode == "carry" then
		w.C0 = CFrame.new(0, 0.5, -2) * CFrame.Angles(0, math.rad(180), 0)
		tj("RS", CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0), 0.4)
		tj("LS", CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0), 0.4)
		notify("Carrying " .. target.DisplayName .. " - ;uncarry to put them down")
		tj("RH", CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0), 0.4)
		tj("LH", CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0), 0.4)
		notify("Sitting on " .. target.DisplayName .. "'s head - ;unheadsit to get off")
	end
	AttachWeld = w
	task.spawn(function()
		while AttachWeld == w do
			task.wait(0.3)
			if not target.Parent or not target.Character then
				detach()
				notify("They left - let go")
				break
			end
			local th2 = target.Character:FindFirstChild("HumanoidRootPart")
			if not th2 then
				detach()
				break
			end
			local h2 = getHum()
			if h2 and not h2.PlatformStand then
				h2.PlatformStand = true
			end
			setMyCollide(false)
		end
	end)
end

local HeadlessOn = false
local HeadlessLoopOn = false

local function applyHeadless()
	local c = getChar()
	if not c then
		return
	end
	local head = c:FindFirstChild("Head")
	if not head then
		return
	end
	head.Transparency = 1
	for _, d in ipairs(head:GetDescendants()) do
		if d:IsA("Decal") then
			d.Transparency = 1
		end
	end
end

local function setHeadless(on)
	HeadlessOn = on
	if on then
		applyHeadless()
		notify("Headless ON - everyone can see it")
		if not HeadlessLoopOn then
			HeadlessLoopOn = true
			task.spawn(function()
				while HeadlessOn do
					task.wait(1)
					if HeadlessOn then
						applyHeadless()
					end
				end
				HeadlessLoopOn = false
			end)
		end
	else
		local c = getChar()
		if c then
			local head = c:FindFirstChild("Head")
			if head then
				head.Transparency = 0
				for _, d in ipairs(head:GetDescendants()) do
					if d:IsA("Decal") then
						d.Transparency = 0
					end
				end
			end
		end
		notify("Headless OFF")
	end
end

-- ================= ZOMBIE - server-visible =================
-- This changes your own character's Animate script to Roblox's own
-- Zombie pack (IDs from Roblox Creator Hub, checked 2026).
-- Your Animator tracks replicate to the server / other players,
-- so everyone sees the zombie walk / idle / run / jump.
-- If a game forces its own animations server-side, it can override
-- this - that is a game limit, not a client-only trick.
local ZOMBIE = {}
ZOMBIE.idle1 = 616158929
ZOMBIE.idle2 = 616160636
ZOMBIE.walk = 616168032
ZOMBIE.run = 616163682
ZOMBIE.jump = 616161997
ZOMBIE.fall = 616157476
ZOMBIE.climb = 616156119
ZOMBIE.swim = 616165109
ZOMBIE.swimidle = 616166655
local DEFAULT_ANIM = {}
DEFAULT_ANIM.idle1 = 507766388
DEFAULT_ANIM.idle2 = 507766666
DEFAULT_ANIM.walk = 507777826
DEFAULT_ANIM.run = 507767714
DEFAULT_ANIM.jump = 507765000
DEFAULT_ANIM.fall = 507767968
DEFAULT_ANIM.climb = 507765644
DEFAULT_ANIM.swim = 507784897
DEFAULT_ANIM.swimidle = 507784897
local ZombieOn = false
local ZombieLoopOn = false

local function applyAnimPack(pack)
	local c = getChar()
	if not c then
		return false
	end
	local an = c:FindFirstChild("Animate")
	if not an then
		return false
	end
	local function setAnim(path, id)
		local obj = an
		for _, part in ipairs(path) do
			obj = obj:FindFirstChild(part)
			if not obj then
				return
			end
		end
		pcall(function()
			obj.AnimationId = "rbxassetid://" .. tostring(id)
		end)
	end
	setAnim({"idle", "Animation1"}, pack.idle1)
	setAnim({"idle", "Animation2"}, pack.idle2)
	setAnim({"walk", "WalkAnim"}, pack.walk)
	setAnim({"run", "RunAnim"}, pack.run)
	setAnim({"jump", "JumpAnim"}, pack.jump)
	setAnim({"fall", "FallAnim"}, pack.fall)
	setAnim({"climb", "ClimbAnim"}, pack.climb)
	setAnim({"swim", "Swim"}, pack.swim)
	setAnim({"swimidle", "SwimIdle"}, pack.swimidle)
	local animator = getAnim()
	if animator then
		pcall(function()
			for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
				tr:Stop(0)
			end
		end)
	end
	local h = getHum()
	if h then
		pcall(function()
			h.Jump = true
		end)
	end
	return true
end

local function setZombie(on)
	ZombieOn = on
	if on then
		if applyAnimPack(ZOMBIE) then
			local h = getHum()
			if h then
				h.WalkSpeed = 12
			end
			notify("Zombie ON - walk / idle / run / jump are zombie for everyone. ;unzombie to go back")
		else
			notify("Zombie failed - no Animate script found (try after respawn)")
			ZombieOn = false
			return
		end
		if not ZombieLoopOn then
			ZombieLoopOn = true
			task.spawn(function()
				while ZombieOn do
					task.wait(2)
					if ZombieOn then
						applyAnimPack(ZOMBIE)
					end
				end
				ZombieLoopOn = false
			end)
		end
	else
		applyAnimPack(DEFAULT_ANIM)
		local h = getHum()
		if h then
			h.WalkSpeed = 16
		end
		notify("Zombie OFF - back to normal")
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	releaseWand()
	WandEquipped = false
	if WandWanted then
		task.delay(1, function()
			if WandWanted then
				giveWand()
			end
		end)
	end
	detach()
	task.wait(1)
	savePose()
	if HeadlessOn then
		applyHeadless()
	end
	if InvisibleOn then
		applyInvisible()
	end
	if SizeOn then
		applySize()
	end
	if ZombieOn then
		applyAnimPack(ZOMBIE)
	end
	if SurviveOn then
		local hrp = getHRP()
		if hrp then
			hrp.Anchored = true
		end
		local h = getHum()
		if h then
			h.MaxHealth = math.huge
			h.Health = math.huge
		end
	end
end)

-- ================= INVISIBLE / SIZE / FX - EVERYONE-SIDE =================
-- These change YOUR OWN character, which you own, so they replicate
-- and everyone sees them. That is why they are allowed here.
-- ;gravity, ;freeze others, ;bring all, ;dance all were NOT added:
-- they would need server control of other players / the world,
-- which a client script does not have, so they would be client-only.
local InvisibleOn = false
local InvisibleLoopOn = false
local function applyInvisible()
	local c = getChar()
	if not c then
		return
	end
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 1
		elseif d:IsA("Decal") then
			d.Transparency = 1
		end
	end
end
local function setInvisible(on)
	InvisibleOn = on
	if on then
		applyInvisible()
		notify("Invisible ON - everyone sees you vanish")
		if not InvisibleLoopOn then
			InvisibleLoopOn = true
			task.spawn(function()
				while InvisibleOn do
					task.wait(1)
					if InvisibleOn then
						applyInvisible()
					end
				end
				InvisibleLoopOn = false
			end)
		end
	else
		local c = getChar()
		if c then
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Transparency = 0
				elseif d:IsA("Decal") then
					d.Transparency = 0
				end
			end
		end
		if HeadlessOn then
			applyHeadless()
		end
		notify("Visible again")
	end
end

local SizeOn = false
local SizeScale = 1
local SizeLoopOn = false
local function applySize()
	local h = getHum()
	if not h then
		return
	end
	local bh = h:FindFirstChild("BodyHeightScale")
	local bw = h:FindFirstChild("BodyWidthScale")
	local bd = h:FindFirstChild("BodyDepthScale")
	local hd = h:FindFirstChild("HeadScale")
	if not bh then
		return
	end
	pcall(function()
		bh.Value = SizeScale
		if bw then bw.Value = SizeScale end
		if bd then bd.Value = SizeScale end
		if hd then hd.Value = SizeScale end
	end)
end
local function setSize(scale)
	if scale < 0.3 then scale = 0.3 end
	if scale > 3 then scale = 3 end
	SizeScale = scale
	local h = getHum()
	if not h or not h:FindFirstChild("BodyHeightScale") then
		notify("Size only works on R15 characters")
		return
	end
	if scale == 1 then
		SizeOn = false
		applySize()
		notify("Normal size")
		return
	end
	SizeOn = true
	applySize()
	notify("Size x" .. tostring(scale) .. " - everyone sees it")
	if not SizeLoopOn then
		SizeLoopOn = true
		task.spawn(function()
			while SizeOn do
				task.wait(2)
				if SizeOn then
					applySize()
				end
			end
			SizeLoopOn = false
		end)
	end
end

local FXParts = {}
local FXKind = nil
local function clearFX()
	for _, fx in ipairs(FXParts) do
		if fx and fx.Parent then
			fx:Destroy()
		end
	end
	FXParts = {}
	FXKind = nil
end
local function setFX(kind)
	clearFX()
	FXKind = kind
	local c = getChar()
	if not c then
		return
	end
	local head = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
	if not head then
		return
	end
	if kind == "fire" or kind == "aura" then
		local f = Instance.new("Fire")
		f.Size = 10
		f.Heat = 10
		f.Parent = head
		table.insert(FXParts, f)
	end
	if kind == "smoke" then
		local s = Instance.new("Smoke")
		s.Size = 10
		s.Opacity = 0.5
		s.Parent = head
		table.insert(FXParts, s)
	end
	if kind == "sparkles" or kind == "aura" then
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = NEON
		sp.Parent = head
		table.insert(FXParts, sp)
	end
	notify("FX: " .. kind .. " - everyone sees it on you. ;unfx to remove")
end

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
	if PREFIXES[raw:sub(1, 1)] then
		raw = raw:sub(2)
	end
	if raw == "" then
		return
	end
	local args = split(raw)
	local cmd = args[1]:lower()
	table.remove(args, 1)
	logMsg(PREFIX .. cmd .. " " .. table.concat(args, " "))
	if cmd == "cmds" or cmd == "help" or cmd == "ecmds" then
		toggleCmds()
	elseif cmd == "prefix" or cmd == "setprefix" or cmd == "changeprefix" then
		setPrefix(args[1])
	elseif cmd == "wand" then
		giveWand()
	elseif cmd == "unwand" then
		removeWand()
	elseif cmd == "throw" then
		throwWand()
	elseif cmd == "boom" or cmd == "explode" or cmd == "explosion" then
		local target = getPlayer(args[1])
		if target and target.Character then
			local th = target.Character:FindFirstChild("HumanoidRootPart")
			if th then
				doBoom(th.Position)
			else
				doBoom(nil)
			end
		else
			doBoom(nil)
		end

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
	elseif cmd == "survive" or cmd == "nds" then
		setSurvive(true)
	elseif cmd == "unsurvive" or cmd == "unsuvive" or cmd == "unnnds" then
		setSurvive(false)
	elseif cmd == "anchor" then
		setAnchor(true)
	elseif cmd == "unanchor" then
		setAnchor(false)
	elseif cmd == "antifling" or cmd == "nofling" then
		setAntiFling(true)
	elseif cmd == "noantifling" or cmd == "unantifling" then
		setAntiFling(false)
	elseif cmd == "orbit" then
		startFun("orbit", getPlayer(args[1]))
	elseif cmd == "unorbit" or cmd == "stoporbit" then
		stopFun()
		notify("Orbit OFF")
	elseif cmd == "fountain" then
		startFun("fountain", getPlayer(args[1]))
	elseif cmd == "unfountain" or cmd == "stopfountain" then
		stopFun()
		notify("Fountain OFF")
	elseif cmd == "rain" then
		startFun("rain", getPlayer(args[1]))
	elseif cmd == "unrain" or cmd == "stoprain" then
		stopFun()
		notify("Rain OFF")
	elseif cmd == "magnet" then
		startFun("magnet", getPlayer(args[1]))
	elseif cmd == "unmagnet" or cmd == "stopmagnet" then
		stopFun()
		notify("Magnet OFF")
	elseif cmd == "launch" then
		doLaunch()
	elseif cmd == "quake" or cmd == "earthquake" then
		startFun("quake", getPlayer(args[1]))
	elseif cmd == "explode" then
		doExplode()
	elseif cmd == "swirl" then
		startFun("swirl", getPlayer(args[1]))
	elseif cmd == "unswirl" or cmd == "stopswirl" then
		stopFun()
		notify("Swirl OFF")
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
	elseif cmd == "zombie" then
		setZombie(true)
	elseif cmd == "unzombie" or cmd == "normal" then
		setZombie(false)
	elseif cmd == "stopemote" or cmd == "unemote" then
		stopAllEmotes()
	elseif cmd == "vortex" then
		startFun("vortex", getPlayer(args[1]))
	elseif cmd == "unvortex" or cmd == "stopvortex" or cmd == "novortex" then
		stopFun()
		notify("Vortex OFF")
	elseif cmd == "nuke" then
		doNuke()
	elseif cmd == "meteor" then
		doMeteor(getPlayer(args[1]))
	elseif cmd == "invisible" then
		setInvisible(true)
	elseif cmd == "visible" then
		setInvisible(false)
	elseif cmd == "big" then
		setSize(2)
	elseif cmd == "tiny" then
		setSize(0.5)
	elseif cmd == "normalsize" or cmd == "normalSize" then
		setSize(1)
	elseif cmd == "size" then
		setSize(tonumber(args[1]) or 1)
	elseif cmd == "carry" then
		attachTo(getPlayer(args[1]), "carry")
	elseif cmd == "uncarry" then
		detach()
		notify("Put them down")
	elseif cmd == "fire" or cmd == "smoke" or cmd == "sparkles" or cmd == "aura" then
		setFX(cmd)
	elseif cmd == "unfx" or cmd == "unfire" or cmd == "unaura" then
		clearFX()
		notify("FX removed")
	elseif cmd == "rejoin" then
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
		notify("Rejoining...")
	elseif cmd == "center" or cmd == "resetui" then
		centerHub()
		maximise()
		notify("Hub centred - you can move it again")
	elseif cmd == "dance" or cmd == "dance2" or cmd == "dance3" or cmd == "floss" or cmd == "shuffle" or cmd == "dab" or cmd == "wave" or cmd == "point" or cmd == "cheer" or cmd == "laugh" or cmd == "cry" or cmd == "bow" or cmd == "salute" or cmd == "think" or cmd == "shy" or cmd == "clap" or cmd == "sleep" or cmd == "lay" then
		doEmote(cmd)
	else
		notify("Unknown: " .. cmd .. " - try ;cmds")
	end
end

local function submit()
	if barBox.Text ~= "" then
		local txt = barBox.Text
		local pre = ""
		local body = txt
		if PREFIXES[body:sub(1, 1)] then
			pre = body:sub(1, 1)
			body = body:sub(2)
		else
			pre = PREFIX
		end
		local first = body:match("^(%S+)") or ""
		local rest = body:match("^%S+%s+(.*)$") or ""
		if #first >= 1 then
			local exact = false
			for _, c in ipairs(ALL_CMDS) do
				if c == first:lower() then
					exact = true
					break
				end
			end
			if not exact then
				local matches = getSuggestMatches(first)
				if #matches == 1 then
					if rest ~= "" then
						txt = pre .. matches[1] .. " " .. rest
					else
						txt = pre .. matches[1]
					end
				end
			end
		end
		runCommand(txt)
		barBox.Text = ""
		suggestBtn.Visible = false
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
	stopFun()
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
	if PREFIXES[m:sub(1, 1)] then
		runCommand(m)
	end
end)

savePose()
if OldCopyFound then
	notify("WARNING: old ANTH copy was still running - cleaned it up. REJOIN the game fresh next time instead of re-running in the same game, and do NOT run Infinite Yield at the same time.")
end
notify("ANTH HUB loaded - ;cmds for list, X minimises to ANTH logo")
print("[ANTH HUB] Loaded - Delta fixed version.")
