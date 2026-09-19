if (Library and Library.ScreenGui) then
	pcall(function() Library.ScreenGui:Destroy() end)
	getgenv().Library = nil
end

local InputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = gethui and gethui() or (cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui"))
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
if cloneref then Mouse = cloneref(Mouse) end

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui
ScreenGui.DisplayOrder = 20

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
	Registry = {},
	RegistryMap = {},
	HudRegistry = {},

	FontColor = Color3.fromRGB(245, 250, 255),
	MainColor = Color3.fromRGB(18, 22, 32),
	BackgroundColor = Color3.fromRGB(12, 14, 22),
	AccentColor = Color3.fromRGB(80, 170, 255),
	OutlineColor = Color3.fromRGB(60, 80, 110),
	RiskColor = Color3.fromRGB(255, 50, 50),

	Black = Color3.new(0, 0, 0),
	Font = Enum.Font.Code,

	OpenedFrames = {},
	DependencyBoxes = {},

	NotificationStyle = {
		Transparency = 0,
		BarSide = "Left",
	},

	KeypickerListVisible = true,
	KeypickerListMode = "All",

	Events = {},
	Signals = {},
	ScreenGui = ScreenGui,
}

local _UI_IS_VISIBLE = false

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
	RainbowStep = RainbowStep + Delta
	if RainbowStep >= (1 / 60) then
		RainbowStep = 0
		Hue = Hue + (1 / 400)
		if Hue > 1 then Hue = 0 end
		Library.CurrentRainbowHue = Hue
		Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
	end
end))

local function GetPlayersString()
	local PlayerList = Players:GetPlayers()
	for i = 1, #PlayerList do
		PlayerList[i] = PlayerList[i].Name
	end
	table.sort(PlayerList, function(a, b) return a < b end)
	return PlayerList
end

local function GetTeamsString()
	local TeamList = Teams:GetTeams()
	for i = 1, #TeamList do
		TeamList[i] = TeamList[i].Name
	end
	table.sort(TeamList, function(a, b) return a < b end)
	return TeamList
end

function Library:SafeCallback(f, ...)
	if not f then return end
	if not Library.NotifyOnError then
		return f(...)
	end
	local success, event = pcall(f, ...)
	if not success then
		local _, i = event:find(":%d+: ")
		if not i then
			return Library:Notify(event)
		end
		return Library:Notify(event:sub(i + 1), 3)
	end
end

function Library:AttemptSave()
	if Library.SaveManager then
		Library.SaveManager:Save()
	end
end

function Library:Create(Class, Properties)
	local _Instance = Class
	if type(Class) == "string" then
		_Instance = Instance.new(Class)
	end
	for Property, Value in next, Properties do
		_Instance[Property] = Value
	end
	return _Instance
end

function Library:ApplyTextStroke(Inst)
	Inst.TextStrokeTransparency = 1
	Library:Create("UIStroke", {
		Color = Color3.new(0, 0, 0),
		Thickness = 1,
		LineJoinMode = Enum.LineJoinMode.Miter,
		Parent = Inst,
	})
end

function Library:CreateLabel(Properties, IsHud)
	local _Instance = Library:Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Library.Font,
		TextColor3 = Library.FontColor,
		TextSize = 16,
		TextStrokeTransparency = 0,
	})
	Library:ApplyTextStroke(_Instance)
	Library:AddToRegistry(_Instance, {
		TextColor3 = "FontColor",
	}, IsHud)
	return Library:Create(_Instance, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
	Instance.Active = true
	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local ObjPos = Vector2.new(
				Mouse.X - Instance.AbsolutePosition.X,
				Mouse.Y - Instance.AbsolutePosition.Y
			)
			if ObjPos.Y > (Cutoff or 40) then return end
			while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				Instance.Position = UDim2.new(
					0,
					Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
					0,
					Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
				)
				RenderStepped:Wait()
			end
		end
	end)
end

local DraggingGui = Instance.new("ScreenGui")
DraggingGui.Parent = (gethui and gethui()) or CoreGui
DraggingGui.Name = "DraggingGui"

function Library:MakeDraggableOutline(Instance, Cutoff)
	Instance.Active = true
	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local ObjPos = Vector2.new(
				Mouse.X - Instance.AbsolutePosition.X,
				Mouse.Y - Instance.AbsolutePosition.Y
			)
			if ObjPos.Y > (Cutoff or 40) then return end

			local frame = Library:Create("Frame", {
				Parent = DraggingGui,
				AnchorPoint = Instance.AnchorPoint,
				BackgroundTransparency = 1,
				Size = Instance.Size,
				Position = Instance.Position,
			})
			local uistroke = Library:Create("UIStroke", {
				Parent = frame,
				Color = Library.AccentColor or Color3.new(0, 0, 0),
			})

			while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				frame.Position = UDim2.new(
					0,
					Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
					0,
					Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
				)
				uistroke.Color = Library.AccentColor or Color3.new(0, 0, 0)
				RenderStepped:Wait()
			end
			Instance.Position = UDim2.new(
				0,
				Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
				0,
				Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
			)
			frame:Destroy()
		end
	end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
	local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14)
	local Tooltip = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		Size = UDim2.fromOffset(X + 5, Y + 4),
		ZIndex = 100,
		Parent = Library.ScreenGui,
		Visible = false,
	})
	local Label = Library:CreateLabel({
		Position = UDim2.fromOffset(3, 1),
		Size = UDim2.fromOffset(X, Y),
		TextSize = 14,
		Text = InfoStr,
		TextColor3 = Library.FontColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Tooltip.ZIndex + 1,
		Parent = Tooltip,
	})
	Library:AddToRegistry(Tooltip, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	})
	Library:AddToRegistry(Label, {
		TextColor3 = "FontColor",
	})
	local IsHovering = false
	HoverInstance.MouseEnter:Connect(function()
		if Library:MouseIsOverOpenedFrame() then return end
		IsHovering = true
		Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		Tooltip.Visible = true
		while IsHovering do
			RunService.Heartbeat:Wait()
			Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		end
	end)
	HoverInstance.MouseLeave:Connect(function()
		IsHovering = false
		Tooltip.Visible = false
	end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
	HighlightInstance.MouseEnter:Connect(function()
		local Reg = Library.RegistryMap[Instance]
		for Property, ColorIdx in next, Properties do
			Instance[Property] = Library[ColorIdx] or ColorIdx
			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx
			end
		end
	end)
	HighlightInstance.MouseLeave:Connect(function()
		local Reg = Library.RegistryMap[Instance]
		for Property, ColorIdx in next, PropertiesDefault do
			Instance[Property] = Library[ColorIdx] or ColorIdx
			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx
			end
		end
	end)
end

function Library:MouseIsOverOpenedFrame()
	for Frame, _ in next, Library.OpenedFrames do
		local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
		if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
			and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
			return true
		end
	end
end

function Library:IsMouseOverFrame(Frame)
	local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
	if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
		and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
		return true
	end
end

function Library:UpdateDependencyBoxes()
	for _, Depbox in next, Library.DependencyBoxes do
		Depbox:Update()
	end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
	return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
	local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
	return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
	local H, S, V = Color3.toHSV(Color)
	return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
	local Idx = #Library.Registry + 1
	local Data = {
		Instance = Instance,
		Properties = Properties,
		Idx = Idx,
	}
	table.insert(Library.Registry, Data)
	Library.RegistryMap[Instance] = Data
	if IsHud then
		table.insert(Library.HudRegistry, Data)
	end
end

function Library:RemoveFromRegistry(Instance)
	local Data = Library.RegistryMap[Instance]
	if Data then
		for Idx = #Library.Registry, 1, -1 do
			if Library.Registry[Idx] == Data then
				table.remove(Library.Registry, Idx)
			end
		end
		for Idx = #Library.HudRegistry, 1, -1 do
			if Library.HudRegistry[Idx] == Data then
				table.remove(Library.HudRegistry, Idx)
			end
		end
		Library.RegistryMap[Instance] = nil
	end
end

function Library:UpdateColorsUsingRegistry()
	for Idx, Object in next, Library.Registry do
		for Property, ColorIdx in next, Object.Properties do
			if type(ColorIdx) == "string" then
				Object.Instance[Property] = Library[ColorIdx]
			elseif type(ColorIdx) == "function" then
				Object.Instance[Property] = ColorIdx()
			end
		end
	end
end

function Library:GiveSignal(Signal)
	table.insert(Library.Signals, Signal)
end

function Library:Unload()
	for Idx = #Library.Signals, 1, -1 do
		local Connection = table.remove(Library.Signals, Idx)
		Connection:Disconnect()
	end
	if Library.OnUnload then
		Library.OnUnload()
	end
	ScreenGui:Destroy()
end

function Library:CreateEvent(name)
	self.Events[name] = Instance.new("BindableEvent")
end

function Library:FireEvent(name, ...)
	self.Events[name]:Fire(...)
end

function Library:OnEvent(name)
	return self.Events[name].Event
end

function Library:OnUnload(Callback)
	Library.OnUnload = Callback
end

local _callbacks = {}
function Library:BindToInput(key, callback)
	_callbacks[key] = _callbacks[key] or {}
	table.insert(_callbacks[key], callback)
end

Library:GiveSignal(InputService.InputBegan:Connect(function(input, ...)
	if not _UI_IS_VISIBLE then return end
	local callbacks = _callbacks[input.KeyCode] or _callbacks[input.UserInputType]
	if callbacks then
		for _, callback in pairs(callbacks) do
			task.spawn(callback, input, ...)
		end
	end
end))

-- Simplified but complete CreateWindow with liquid glass
function Library:CreateWindow(...)
	local Arguments = {...}
	local Config = { AnchorPoint = Vector2.zero }

	if type(...) == "table" then
		Config = ...
	else
		Config.Title = Arguments[1]
		Config.AutoShow = Arguments[2] or false
	end

	_UI_IS_VISIBLE = Config.AutoShow
	if type(Config.Title) ~= "string" then Config.Title = "No title" end
	if type(Config.TabPadding) ~= "number" then Config.TabPadding = 0 end
	if type(Config.MenuFadeTime) ~= "number" then Config.MenuFadeTime = 0.2 end
	if typeof(Config.Position) ~= "UDim2" then Config.Position = UDim2.fromOffset(175, 50) end
	if typeof(Config.Size) ~= "UDim2" then Config.Size = UDim2.fromOffset(550, 600) end
	if Config.Center then
		Config.AnchorPoint = Vector2.new(0.5, 0.5)
		Config.Position = UDim2.fromScale(0.5, 0.5)
	end

	Library.UISize = Config.Size

	local Window = { Tabs = {} }

	-- OUTER - liquid glass base
	local Outer = Library:Create("Frame", {
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Position = Config.Position,
		Size = Config.Size,
		Visible = false,
		ZIndex = 1,
		Parent = ScreenGui,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Outer })

	-- Outline Glow
	local GlowOuter = Library:Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 12, 1, 12),
		Position = UDim2.new(0, -6, 0, -6),
		ZIndex = 0,
		Parent = Outer,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = GlowOuter })
	local GlowStroke = Library:Create("UIStroke", {
		Color = Library.AccentColor,
		Thickness = 4,
		Transparency = 0.55,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = GlowOuter,
	})
	Library:AddToRegistry(GlowStroke, { Color = "AccentColor" })

	-- Soft white glass border
	Library:Create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1.5,
		Transparency = 0.7,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = Outer,
	})

	Library:MakeDraggableOutline(Outer, 25)

	-- INNER - frosted glass
	local Inner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 1,
		Parent = Outer,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = Inner })
	Library:AddToRegistry(Inner, { BackgroundColor3 = "MainColor" })

	-- Top glass highlight
	local GlassHighlight = Library:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 28),
		ZIndex = 2,
		Parent = Inner,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = GlassHighlight })
	Library:Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.75),
			NumberSequenceKeypoint.new(0.4, 0.95),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90,
		Parent = GlassHighlight,
	})

	-- CENTERED TITLE
	local WindowLabel = Library:CreateLabel({
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 25),
		Text = Config.Title or "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 3,
		Parent = Inner,
	})

	local VersionLabel = Library:CreateLabel({
		Position = UDim2.new(0, -8, 0, 0),
		Size = UDim2.new(1, 0, 0, 25),
		Text = Config.Version or "",
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
		Parent = Inner,
	})

	local MainSectionOuter = Library:Create("Frame", {
		BackgroundColor3 = Library.BackgroundColor,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 25),
		Size = UDim2.new(1, -16, 1, -33),
		ZIndex = 1,
		Parent = Inner,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainSectionOuter })
	Library:AddToRegistry(MainSectionOuter, { BackgroundColor3 = "BackgroundColor" })

	local MainSectionInner = Library:Create("Frame", {
		BackgroundColor3 = Library.BackgroundColor,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
		Parent = MainSectionOuter,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = MainSectionInner })
	Library:AddToRegistry(MainSectionInner, { BackgroundColor3 = "BackgroundColor" })

	-- TAB BAR WITH SHADOW
	local TabBarShadow = Library:Create("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 3),
		Size = UDim2.new(1, -12, 0, 30),
		ZIndex = 1,
		Parent = MainSectionInner,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBarShadow })
	Library:Create("UIStroke", {
		Color = Color3.new(0, 0, 0),
		Thickness = 1,
		Transparency = 0.7,
		Parent = TabBarShadow,
	})

	local TabBar = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 2),
		Size = UDim2.new(1, -12, 0, 28),
		ZIndex = 2,
		Parent = MainSectionInner,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBar })
	local TabBarStroke = Library:Create("UIStroke", {
		Color = Library.AccentColor,
		Thickness = 1,
		Transparency = 0.65,
		Parent = TabBar,
	})
	Library:AddToRegistry(TabBarStroke, { Color = "AccentColor" })

	local TabBarHighlight = Library:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 10),
		ZIndex = 3,
		Parent = TabBar,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBarHighlight })

	local TabArea = Library:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 2),
		Size = UDim2.new(1, -8, 0, 24),
		ZIndex = 4,
		Parent = TabBar,
	})

	local TabListLayout = Library:Create("UIListLayout", {
		Padding = UDim.new(0, Config.TabPadding),
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabArea,
	})

	local TabContainer = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 36),
		Size = UDim2.new(1, -12, 1, -42),
		ZIndex = 2,
		Parent = MainSectionInner,
	})
	Library:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabContainer })
	Library:AddToRegistry(TabContainer, { BackgroundColor3 = "MainColor" })

	function Window:SetWindowTitle(Title)
		WindowLabel.Text = Title
	end

	function Window:AddTab(Name)
		local Tab = {
			Groupboxes = {},
			Tabboxes = {},
		}

		local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16)

		local TabButton = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0),
			ZIndex = 1,
			Parent = TabArea,
		})
		Library:AddToRegistry(TabButton, {
			BackgroundColor3 = "BackgroundColor",
			BorderColor3 = "OutlineColor",
		})

		local TabButtonLabel = Library:CreateLabel({
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, -1),
			Text = Name,
			ZIndex = 1,
			Parent = TabButton,
		})

		local Blocker = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = TabButton,
		})
		Library:AddToRegistry(Blocker, { BackgroundColor3 = "MainColor" })

		local TabFrame = Library:Create("Frame", {
			Name = "TabFrame",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			ZIndex = 2,
			Parent = TabContainer,
		})

		local LeftSide = Library:Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 8 - 1, 0, 8 - 1),
			Size = UDim2.new(0.5, -12 + 2, 0, Library.UISize.Height.Offset - 91),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			BottomImage = "",
			TopImage = "",
			ScrollBarThickness = 0,
			ZIndex = 2,
			Parent = TabFrame,
		})

		local RightSide = Library:Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1),
			Size = UDim2.new(0.5, -12 + 2, 0, Library.UISize.Height.Offset - 91),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			BottomImage = "",
			TopImage = "",
			ScrollBarThickness = 0,
			ZIndex = 2,
			Parent = TabFrame,
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = LeftSide,
		})
		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = RightSide,
		})

		for _, Side in next, { LeftSide, RightSide } do
			Side:WaitForChild("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
			end)
		end

		function Tab:ShowTab()
			for _, T in next, Window.Tabs do
				T:HideTab()
			end
			Blocker.BackgroundTransparency = 0
			TabButton.BackgroundColor3 = Library.MainColor
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = "MainColor"
			TabFrame.Visible = true
		end

		function Tab:HideTab()
			Blocker.BackgroundTransparency = 1
			TabButton.BackgroundColor3 = Library.BackgroundColor
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = "BackgroundColor"
			TabFrame.Visible = false
		end

		function Tab:SetLayoutOrder(Position)
			TabButton.LayoutOrder = Position
			TabListLayout:ApplyLayout()
		end

		function Tab:AddGroupbox(Info)
			local Groupbox = {}
			local BoxOuter = Library:Create("Frame", {
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 0, 507 + 2),
				ZIndex = 2,
				Parent = Info.Side == 1 and LeftSide or RightSide,
			})
			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = "BackgroundColor",
				BorderColor3 = "OutlineColor",
			})

			local BoxInner = Library:Create("Frame", {
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				ZIndex = 4,
				Parent = BoxOuter,
			})
			Library:AddToRegistry(BoxInner, { BackgroundColor3 = "BackgroundColor" })

			local Highlight = Library:Create("Frame", {
				BackgroundColor3 = Library.AccentColor,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 2),
				ZIndex = 5,
				Parent = BoxInner,
			})
			Library:AddToRegistry(Highlight, { BackgroundColor3 = "AccentColor" })

			Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.new(0, 4, 0, 2),
				TextSize = 14,
				Text = Info.Name,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 5,
				Parent = BoxInner,
			})

			local Container = Library:Create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 4, 0, 20),
				Size = UDim2.new(1, -4, 1, -20),
				ZIndex = 1,
				Parent = BoxInner,
			})
			Library:Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = Container,
			})

			function Groupbox:Resize()
				local Size = 0
				for _, Element in next, Groupbox.Container:GetChildren() do
					if (not Element:IsA("UIListLayout")) and Element.Visible then
						Size = Size + Element.Size.Y.Offset
					end
				end
				BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
			end

			Groupbox.Container = Container
			-- metatable will be set if BaseGroupbox exists
			Groupbox:AddBlank = function(self, Size)
				return Library:Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, Size),
					ZIndex = 1,
					Parent = Container,
				})
			end
			Groupbox:AddBlank(3)
			Groupbox:Resize()
			Tab.Groupboxes[Info.Name] = Groupbox
			return Groupbox
		end

		function Tab:AddLeftGroupbox(Name)
			return self:AddGroupbox({ Side = 1, Name = Name })
		end

		function Tab:AddRightGroupbox(Name)
			return self:AddGroupbox({ Side = 2, Name = Name })
		end

		TabButton.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Tab:ShowTab()
			end
		end)

		if #TabContainer:GetChildren() == 1 then
			Tab:ShowTab()
		end

		Window.Tabs[Name] = Tab
		return Tab
	end

	-- CURSOR from your paste (exact)
	local ModalElement = Library:Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 0),
		Visible = true,
		Text = "",
		Modal = false,
		Parent = Library:Create("ScreenGui", {
			Parent = CoreGui,
		}),
	})

	local TransparencyCache = {}
	local Toggled = false
	local Fading = false

	function Library:Toggle()
		if Fading then return end
		local FadeTime = Config.MenuFadeTime
		Fading = true
		Toggled = not Toggled
		_UI_IS_VISIBLE = Toggled
		Library:FireEvent("VisibilityChanged", _UI_IS_VISIBLE)
		ModalElement.Modal = Toggled

		if Toggled then
			Outer.Visible = true
			local guiservice = game:GetService("GuiService")
			task.spawn(function()
				local State = InputService.MouseIconEnabled

				-- YOUR CURSOR exactly
				local Cursor = Instance.new("ImageLabel", ScreenGui)
				Cursor.Image = "http://www.roblox.com/asset/?id=4292970642"
				Cursor.BackgroundTransparency = 1
				Cursor.ZIndex = 100

				local CursorOutline = Instance.new("ImageLabel", ScreenGui)
				CursorOutline.Image = "http://www.roblox.com/asset/?id=4292970642"
				CursorOutline.ImageColor3 = Color3.new()
				CursorOutline.BackgroundTransparency = 1
				CursorOutline.ZIndex = 99

				Cursor.Size, CursorOutline.Size = UDim2.fromOffset(17, 17), UDim2.fromOffset(19, 19)
				Cursor.Rotation, CursorOutline.Rotation = -45, -45

				while Toggled and ScreenGui.Parent do
					InputService.MouseIconEnabled = false
					local mPos = InputService:GetMouseLocation()
					local udim = UDim2.fromOffset(mPos.X, mPos.Y - guiservice:GetGuiInset().Y - 1)
					Cursor.ImageColor3 = Library.AccentColor
					Cursor.Position, CursorOutline.Position = udim, udim - UDim2.fromOffset(1, 1)
					RenderStepped:Wait()
				end

				InputService.MouseIconEnabled = State
				Cursor:Destroy()
				CursorOutline:Destroy()
			end)
		end

		if not Config.DontFade then
			Outer.Parent = ScreenGui
			for _, Desc in next, Outer:GetDescendants() do
				local Properties = {}
				if Desc:IsA("ImageLabel") then
					table.insert(Properties, "ImageTransparency")
					table.insert(Properties, "BackgroundTransparency")
				elseif Desc:IsA("TextLabel") or Desc:IsA("TextBox") then
					table.insert(Properties, "TextTransparency")
				elseif Desc:IsA("Frame") or Desc:IsA("ScrollingFrame") then
					table.insert(Properties, "BackgroundTransparency")
				elseif Desc:IsA("UIStroke") then
					table.insert(Properties, "Transparency")
				end
				local Cache = TransparencyCache[Desc]
				if not Cache then
					Cache = {}
					TransparencyCache[Desc] = Cache
				end
				for _, Prop in next, Properties do
					if not Cache[Prop] then
						Cache[Prop] = Desc[Prop]
					end
					if Cache[Prop] == 1 then continue end
					TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play()
				end
			end
			task.wait(FadeTime)
		end

		Outer.Visible = Toggled
		Outer.Parent = Toggled and ScreenGui or nil
		Fading = false
	end

	Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
		if type(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Type == "KeyPicker" then
			if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
				task.spawn(Library.Toggle)
			end
		elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and not Processed) then
			task.spawn(Library.Toggle)
		end
	end))

	if Config.AutoShow then task.spawn(Library.Toggle) end
	Window.Holder = Outer
	return Window
end

Library:CreateEvent("VisibilityChanged")

getgenv().Library = Library
return Library
