```lua
--[[
    Darkness Player v5.5 - Unified Script
    Features:
    - SoundCloud Integration (API based)
    - Mobile GUI with Drag & Drop
    - Voice Search (Client-side simulation + API hook ready)
    - Responsive UI
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- CONFIGURATION
-- ==========================================
local CONFIG = {
	ApiBase = "https://api.soundcloud.com",
	ClientId = "YOUR_SOUND_CLOUD_CLIENT_ID", -- Замените на ваш ID
	Width = 350,
	Height = 500,
	TopBarHeight = 50,
	SearchBarHeight = 45,
	ItemHeight = 60,
	Padding = 10,
	AnimationSpeed = 0.1,
	Colors = {
		Background = Color3.fromRGB(15, 15, 20),
		Header = Color3.fromRGB(25, 25, 35),
		Border = Color3.fromRGB(60, 60, 80),
		Text = Color3.fromRGB(200, 200, 210),
		Highlight = Color3.fromRGB(80, 80, 100),
		PlayBtn = Color3.fromRGB(200, 50, 50),
		MicIdle = Color3.fromRGB(60, 60, 80),
		MicActive = Color3.fromRGB(255, 80, 80),
		Close = Color3.fromRGB(180, 40, 40)
	}
}

-- ==========================================
-- SOUNDCloud API HANDLER
-- ==========================================
local SoundCloud = {}
SoundCloud.__index = SoundCloud

function SoundCloud.new(clientId)
	local self = setmetatable({}, SoundCloud)
	self.ClientId = clientId
	self.Cache = {}
	return self
end

function SoundCloud:Search(query)
	if self.Cache[query] then
		return self.Cache[query]
	end

	local success, result = pcall(function()
		local url = string.format("%s/tracks?client_id=%s&q=%s&linked_partitioning=1", 
			CONFIG.ApiBase, self.ClientId, HttpService:UrlEncode(query))
		local response = game:GetService("HttpService"):GetAsync(url)
		local data = game:GetService("HttpService"):JSONDecode(response)
		return data.collection or {}
	end)

	if success then
		self.Cache[query] = result
		return result
	else
		warn("SoundCloud Search Error:", result)
		return {}
	end
end

-- ==========================================
-- VOICE SEARCH MODULE
-- ==========================================
local VoiceSearch = {}
VoiceSearch.__index = VoiceSearch

function VoiceSearch:new(menuInstance)
	local self = setmetatable({}, VoiceSearch)
	self.Menu = menuInstance
	self.IsListening = false
	self.Recognition = nil
	
	-- Check support
	self.IsSupported = (UserInputService.TouchEnabled or UserInputService.MouseEnabled)
	return self
end

function VoiceSearch:StartListening()
	if self.IsListening then return end
	self.IsListening = true
	self.Menu:UpdateMicState(true)
	
	-- Simulation for demonstration (Replace with actual MicrophoneService if available)
	-- In a real scenario, you'd use a library like 'VoiceChatService' or external API
	print("[Voice] Listening...")
	
	task.spawn(function()
		task.wait(2.5) -- Simulate speaking duration
		if self.IsListening then
			self:SimulateResult("Dark Horse - Katy Perry")
		end
	end)
end

function VoiceSearch:StopListening()
	self.IsListening = false
	self.Menu:UpdateMicState(false)
	print("[Voice] Stopped")
end

function VoiceSearch:SimulateResult(text)
	self.Menu.SearchText = text
	self.Menu:UpdateSearchUI()
	self:StopListening()
	
	-- Auto search
	print("[Voice] Recognized: " .. text)
	self.Menu:PerformSearch(text)
end

function VoiceSearch:Toggle()
	if self.IsListening then
		self:StopListening()
	else
		self:StartListening()
	end
end

-- ==========================================
-- MAIN UI MODULE
-- ==========================================
local UI = {}
UI.__index = UI

function UI:new()
	local self = setmetatable({}, UI)
	self.IsOpen = true
	self.IsDragging = false
	self.DragData = {StartPos = nil, StartFramePos = nil}
	
	-- Position initialization (Center Bottom)
	self.X = (Display:GetSize().X / 2) - (CONFIG.Width / 2)
	self.Y = Display:GetSize().Y - CONFIG.Height - 20
	
	self.SearchText = ""
	self.CurrentTracks = {}
	
	-- Services
	self.SoundCloud = SoundCloud.new(CONFIG.ClientId)
	self.Voice = VoiceSearch:new(self)
	
	-- Build UI
	self:CreateBaseUI()
	
	-- Events
	self:BindEvents()
	
	-- Initial Search
	self:PerformSearch("lofi hip hop")
	
	return self
end

function UI:CreateBaseUI()
	-- ScreenGui
	local SGui = Instance.new("ScreenGui")
	SGui.Name = "DarknessPlayer"
	SGui.ResetOnSpawn = false
	SGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SGui.Parent = StarterGui
	
	-- Main Frame
	local Frame = Instance.new("Frame")
	Frame.Name = "MainFrame"
	Frame.Size = UDim2.new(0, CONFIG.Width, 0, CONFIG.Height)
	Frame.Position = UDim2.new(0, self.X, 0, self.Y)
	Frame.BackgroundTransparency = 0
	Frame.BackgroundColor3 = CONFIG.Colors.Background
	Frame.BorderSizePixel = 0
	Frame.Parent = SGui
	
	-- Corner Radius (Rounded)
	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 15)
	UICorner.Parent = Frame
	
	-- Border
	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = CONFIG.Colors.Border
	UIStroke.Thickness = 2
	UIStroke.Parent = Frame

	-- Header
	local Header = Instance.new("Frame")
	Header.Size = UDim2.new(1, 0, 0, CONFIG.TopBarHeight)
	Header.Position = UDim2.new(0, 0, 0, 0)
	Header.BackgroundColor3 = CONFIG.Colors.Header
	Header.BorderSizePixel = 0
	Header.Parent = Frame
	
	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, 15)
	HeaderCorner.Parent = Header
	
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Text = "🎵 Darkness Player"
	TitleLabel.TextColor3 = CONFIG.Colors.Text
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextSize = 18
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Size = UDim2.new(0, 200, 0, 30)
	TitleLabel.Position = UDim2.new(0, 10, 0, 10)
	TitleLabel.Parent = Header
	
	-- Close Button
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Color3.new(1, 1, 1)
	CloseBtn.BackgroundColor3 = CONFIG.Colors.Close
	CloseBtn.Size = UDim2.new(0, 30, 0, 30)
	CloseBtn.Position = UDim2.new(1, -40, 0, 10)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.Parent = Header
	CloseBtn.MouseButton1Click:Connect(function()
		self.IsOpen = not self.IsOpen
		Frame.Visible = self.IsOpen
	end)
	
	-- Search Area
	local SearchFrame = Instance.new("Frame")
	SearchFrame.Size = UDim2.new(1, -20, 0, CONFIG.SearchBarHeight)
	SearchFrame.Position = UDim2.new(0, 10, 0, CONFIG.TopBarHeight + 5)
	SearchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	SearchFrame.BorderSizePixel = 0
	SearchFrame.Parent = Frame
	
	local SearchCorner = Instance.new("UICorner")
	SearchCorner.CornerRadius = UDim.new(0, 8)
	SearchCorner.Parent = SearchFrame
	
	-- Search Text Label
	local SearchLabel = Instance.new("TextLabel")
	SearchLabel.Name = "SearchText"
	SearchLabel.Text = self.SearchText
	SearchLabel.TextColor3 = CONFIG.Colors.Text
	SearchLabel.Font = Enum.Font.Gotham
	SearchLabel.TextSize = 14
	SearchLabel.BackgroundTransparency = 1
	SearchLabel.Size = UDim2.new(0, 220, 0, 30)
	SearchLabel.Position = UDim2.new(0, 5, 0, 7)
	SearchLabel.Parent = SearchFrame
	
	-- Mic Button
	local MicBtn = Instance.new("TextButton")
	MicBtn.Name = "MicBtn"
	MicBtn.Text = "🎤"
	MicBtn.TextColor3 = Color3.new(1, 1, 1)
	MicBtn.BackgroundColor3 = CONFIG.Colors.MicIdle
	MicBtn.Size = UDim2.new(0, 40, 0, 30)
	MicBtn.Position = UDim2.new(1, -45, 0, 7)
	MicBtn.Font = Enum.Font.Gotham
	MicBtn.BorderSizePixel = 0
	MicBtn.Parent = SearchFrame
	
	MicBtn.MouseButton1Click:Connect(function()
		self.Voice:Toggle()
	end)
	
	-- Scrollable List Area
	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Size = UDim2.new(1, -20, 1, -(CONFIG.TopBarHeight + CONFIG.SearchBarHeight + 30))
	ScrollFrame.Position = UDim2.new(0, 10, 0, CONFIG.TopBarHeight + CONFIG.SearchBarHeight + 15)
	ScrollFrame.BackgroundColor3 = CONFIG.Colors.Background
	ScrollFrame.BorderSizePixel = 0
	ScrollFrame.ScrollBarThickness = 4
	ScrollFrame.ScrollBarImageColor3 = CONFIG.Colors.Border
	ScrollFrame.Parent = Frame
	
	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, 5)
	UIListLayout.Parent = ScrollFrame
	
	self.ScrollFrame = ScrollFrame
	self.SearchLabel = SearchLabel
	self.MicBtn = MicBtn
	self.Frame = Frame
	self.SGui = SGui
end

function UI:BindEvents()
	-- Dragging Logic
	self.Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.IsDragging = true
			self.DragData.StartPos = input.Position
			self.DragData.StartFramePos = self.Frame.Position
		end
	end)
	
	self.Frame.InputChanged:Connect(function(input)
		if self.IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local Delta = input.Position - self.DragData.StartPos
			self.Frame.Position = UDim2.new(
				self.DragData.StartFramePos.X.Scale,
				self.DragData.StartFramePos.X.Offset + Delta.X,
				self.DragData.StartFramePos.Y.Scale,
				self.DragData.StartFramePos.Y.Offset + Delta.Y
			)
		end
	end)
	
	self.Frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.IsDragging = false
		end
	end)
end

function UI:UpdateMicState(active)
	self.MicBtn.BackgroundColor3 = active and CONFIG.Colors.MicActive or CONFIG.Colors.MicIdle
	if active then
		self.MicBtn.Text = "●" -- Recording indicator
	else
		self.MicBtn.Text = "🎤"
	end
end

function UI:UpdateSearchUI()
	self.SearchLabel.Text = self.SearchText
end

function UI:PerformSearch(query)
	self.SearchText = query
	self:UpdateSearchUI()
	
	-- Clear existing items
	for _, child in ipairs(self.ScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Fetch from API
	task.spawn(function()
		local tracks = self.SoundCloud:Search(query)
		
		for i, track in ipairs(tracks) do
			if i > 20 then break end -- Limit UI items
			
			local TrackItem = Instance.new("Frame")
			TrackItem.Size = UDim2.new(1, -10, 0, CONFIG.ItemHeight)
			TrackItem.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			TrackItem.BorderSizePixel = 0
			TrackItem.Parent = self.ScrollFrame
			
			local ItemCorner = Instance.new("UICorner")
			ItemCorner.CornerRadius = UDim.new(0, 5)
			ItemCorner.Parent = TrackItem
			
			-- Title Label
			local TitleLbl = Instance.new("TextLabel")
			TitleLbl.Text = track.title or "Unknown Track"
			TitleLbl.TextColor3 = CONFIG.Colors.Text
			TitleLbl.Font = Enum.Font.Gotham
			TitleLbl.TextSize = 14
			TitleLbl.BackgroundTransparency = 1
			TitleLbl.Size = UDim2.new(0, 200, 0, 20)
			TitleLbl.Position = UDim2.new(0, 5, 0, 5)
			TitleLbl.Parent = TrackItem
			
			-- Play Button
			local PlayBtn = Instance.new("TextButton")
			PlayBtn.Text = "▶"
			PlayBtn.BackgroundColor3 = CONFIG.Colors.PlayBtn
			PlayBtn.Size = UDim2.new(0, 40, 0, 30)
			PlayBtn.Position = UDim2.new(1, -45, 0, 15)
			PlayBtn.TextColor3 = Color3.new(1, 1, 1)
			PlayBtn.Font = Enum.Font.GothamBold
			PlayBtn.Parent = TrackItem
			
			PlayBtn.MouseButton1Click:Connect(function()
				print("Playing track: " .. track.title)
				-- Implement actual playback logic here
			end)
		end
		
		if #tracks == 0 then
			local NoRes = Instance.new("TextLabel")
			NoRes.Text = "No results found"
			NoRes.TextColor3 = CONFIG.Colors.Text
			NoRes.Font = Enum.Font.GothamItalic
			NoRes.BackgroundTransparency = 1
			NoRes.Size = UDim2.new(1, 0, 0, 30)
			NoRes.Parent = self.ScrollFrame
		end
	end)
end

-- ==========================================
-- INITIALIZATION
-- ==========================================
local DarknessPlayer = {}

function DarknessPlayer.Init()
	local Player = UI:new()
	print("Darkness Player v5.5 Loaded")
	return Player
end

return DarknessPlayer
```
