if (_G.hitboxVisualization == nil) then
	_G.hitboxVisualization = true;
end
local Config = {Theme={primary=Color3.fromRGB(45, 49, 66),secondary=Color3.fromRGB(239, 35, 60),tertiary=Color3.fromRGB(237, 242, 244),success=Color3.fromRGB(72, 202, 118),danger=Color3.fromRGB(235, 77, 75),warning=Color3.fromRGB(250, 152, 58),info=Color3.fromRGB(86, 207, 225),background=Color3.fromRGB(45, 49, 66),card=Color3.fromRGB(65, 69, 86),button=Color3.fromRGB(83, 86, 101),text=Color3.fromRGB(237, 242, 244),border=Color3.fromRGB(83, 86, 101),highlight=Color3.fromRGB(239, 35, 60),headerFont=Enum.Font.GothamBold,bodyFont=Enum.Font.Gotham,cornerRadius=UDim.new(0, 6),padding=UDim.new(0, 8),playerHighlightFill=Color3.fromRGB(239, 35, 60),playerHighlightOutline=Color3.fromRGB(255, 205, 0)},Hotkeys={Aimbot="T"},AutoFarm={beaconScanInterval=0.1,repathDistance=6,sprintThreshold=25,pauseMin=0.4,pauseMax=1.1,fallbackLocation=Vector3.new(588.46, 4.64, -152.45),secondaryFallbackLocation=Vector3.new(597.97, 4.64, -152.21)},AutoFish={TiltAngle=-15,Tolerance=5,PredictionDelay=0.1,MouseEventCooldown=0.05},Combat={AutoAttackAnims={"11710200495","6219995905","12340314557","12340307545"},DodgeAnimations={"rbxassetid://12295888509","rbxassetid://6498021806","rbxassetid://6498027916","rbxassetid://11714217847","rbxassetid://11287868223","rbxassetid://11316123603","rbxassetid://6497992904","rbxassetid://11714322242","rbxassetid://11287880533","rbxassetid://6869874789"},DodgeDelays={["rbxassetid://12295888509"]=0.3,["rbxassetid://6498021806"]=0.3,["rbxassetid://6498027916"]=0.3,["rbxassetid://11714217847"]=0.7,["rbxassetid://11287868223"]=0.5,["rbxassetid://11316123603"]=0.3,["rbxassetid://6497992904"]=0.3,["rbxassetid://11714322242"]=0.7,["rbxassetid://11287880533"]=0.5,["rbxassetid://6869874789"]=0.3}},Items={ValidGuns={P9=true,Nambu=true,Howa=true,MP5=true,Mossberg=true},RangedTypes={P9=true,Howa=true,Mossberg=true,MP5=true,Nambu=true},MeleeTypes={Bat=true,Bokken=true,Bottle=true,Brick=true,Fireaxe=true,Hammer=true,Katana=true,Knife=true,Sledgehammer=true,Tanto=true},MaxItemsPerType=5,RefreshItemsInterval=0.5}};
Config.Items.ItemBlacklist = {Vector3.new(282.552551, 1.22421908, 33.9915695),Vector3.new(610.258118, 3.79939222, 5.27697182),Vector3.new(712.373596, 11.3274336, -853.52124)};
Config.Items.BlacklistRadius = 5;
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local VirtualInputManager = game:GetService("VirtualInputManager");
local UserInputService = game:GetService("UserInputService");
local PathfindingService = game:GetService("PathfindingService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local HttpService = game:GetService("HttpService");
local SETTINGS_FILE = "Shin1988.json";
local autoFishEnabled = false;
local alignmentConnection = nil;
local currentFishingMinigame = nil;
local yellowHistory = {};
local whiteHistory = {};
local mouseHeld = false;
local lastMouseEventTime = 0;
local localPlayer = Players.LocalPlayer;
local mouse = localPlayer:GetMouse();
local trackedItems = {};
local autoAttackEnabled = true;
local autoDodgeEnabled = true;
local weaponLabelsEnabled = true;
local gunLabelsEnabled = true;
local trackAllEnabled = false;
local autoAttackToggle;
local autoDodgeToggle;
local weaponLabelsToggle;
local itemFarmEnabled = false;
local aimbotEnabled = false;
local updatePlayerList;
local highlightToggledPlayers = {};
local gunLabelsForPlayers = {};
local gunLabelsData = {};
local meleeToggleButtons = {};
local rangedToggleButtons = {};
local updateItemLabels;
local infiniteStaminaEnabled = false;
local updateGunLabelForPlayer;
local updatePlayerHighlight;
local autoFarmEnabled = false;
local notifiedRangedItems = {};
local farmerCoroutine = nil;
local pizzaFarmer;
local itemFarmerCoroutine = nil;
local holdingAim = false;
local lockedTarget = nil;
local camera = workspace.CurrentCamera;
local SpecialBeaconRoutes = {{type="bridge",beacon=Vector3.new(330.022644, 9.29997826, -338.289032),manual=Vector3.new(336.68, -1.44, -327.1),second=Vector3.new(329.07, 8.3, -337.08)}};
local enabledItemTypes = {};
for name, _ in pairs(Config.Items.MeleeTypes) do
	enabledItemTypes[name] = false;
end
for name in pairs(Config.Items.RangedTypes) do
	enabledItemTypes[name] = false;
end
local showItemDistance = true;
local searchDroppedItemsEnabled = true;
local function createCornerRadius(parent, radius)
	local corner = Instance.new("UICorner");
	corner.CornerRadius = radius or Config.Theme.cornerRadius;
	corner.Parent = parent;
	return corner;
end
local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke");
	stroke.Color = color or Config.Theme.border;
	stroke.Thickness = thickness or 1;
	stroke.Parent = parent;
	return stroke;
end
local function createPadding(parent, padding)
	local uiPadding = Instance.new("UIPadding");
	uiPadding.PaddingTop = padding or Config.Theme.padding;
	uiPadding.PaddingBottom = padding or Config.Theme.padding;
	uiPadding.PaddingLeft = padding or Config.Theme.padding;
	uiPadding.PaddingRight = padding or Config.Theme.padding;
	uiPadding.Parent = parent;
	return uiPadding;
end
local function createShadow(parent)
	local shadow = Instance.new("ImageLabel");
	shadow.Name = "Shadow";
	shadow.AnchorPoint = Vector2.new(0.5, 0.5);
	shadow.BackgroundTransparency = 1;
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4);
	shadow.Size = UDim2.new(1, 10, 1, 10);
	shadow.ZIndex = parent.ZIndex - 1;
	shadow.Image = "rbxassetid://6014261993";
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0);
	shadow.ImageTransparency = 0.6;
	shadow.ScaleType = Enum.ScaleType.Slice;
	shadow.SliceCenter = Rect.new(49, 49, 450, 450);
	shadow.Parent = parent;
	return shadow;
end
local function saveKeybinds()
	local encoded = HttpService:JSONEncode(Config.Hotkeys);
	writefile(SETTINGS_FILE, encoded);
end
if isfile(SETTINGS_FILE) then
	local raw = readfile(SETTINGS_FILE);
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw);
	end);
	if (ok and (type(decoded) == "table")) then
		for k, v in pairs(decoded) do
			if Config.Hotkeys[k] then
				Config.Hotkeys[k] = v;
			end
		end
	end
end
local function createToggleButton(labelText, startingState, callback, hotkeyConfigKey)
	local button = Instance.new("Frame");
	button.Name = labelText:gsub("%s", "") .. "Button";
	button.Size = UDim2.new(1, 0, 0, 40);
	button.BackgroundColor3 = (startingState and Config.Theme.success) or Config.Theme.danger;
	button.BorderSizePixel = 0;
	button:SetAttribute("State", startingState);
	createCornerRadius(button);
	local innerPadding = Instance.new("UIPadding");
	innerPadding.PaddingLeft = UDim.new(0, 10);
	innerPadding.PaddingTop = UDim.new(0, 4);
	innerPadding.PaddingBottom = UDim.new(0, 4);
	innerPadding.Parent = button;
	local hitbox = Instance.new("TextButton");
	hitbox.Name = "Hitbox";
	hitbox.Size = UDim2.new(1, 0, 1, 0);
	hitbox.BackgroundTransparency = 1;
	hitbox.Text = "";
	hitbox.Parent = button;
	local label = Instance.new("TextLabel");
	label.Name = "Label";
	label.BackgroundTransparency = 1;
	label.Font = Config.Theme.bodyFont;
	label.TextSize = 14;
	label.TextColor3 = Config.Theme.text;
	label.TextXAlignment = Enum.TextXAlignment.Left;
	label.Text = labelText;
	label.Parent = button;
	label.Size = UDim2.new(0, label.TextBounds.X, 1, 0);
	local hotkeyLabel;
	if hotkeyConfigKey then
		hotkeyLabel = Instance.new("TextButton");
		hotkeyLabel.Name = "HotkeyInfo";
		hotkeyLabel.Size = UDim2.new(0, 30, 0, 20);
		hotkeyLabel.BackgroundColor3 = Config.Theme.primary;
		hotkeyLabel.BackgroundTransparency = 0.5;
		hotkeyLabel.Font = Config.Theme.bodyFont;
		hotkeyLabel.TextSize = 12;
		hotkeyLabel.TextColor3 = Config.Theme.text;
		hotkeyLabel.TextXAlignment = Enum.TextXAlignment.Center;
		hotkeyLabel.Parent = button;
		createCornerRadius(hotkeyLabel);
		local function positionHotkey()
			local offset = 5;
			hotkeyLabel.Position = UDim2.new(0, 10 + label.TextBounds.X + offset, 0.5, -10);
		end
		hotkeyLabel.Text = Config.Hotkeys[hotkeyConfigKey] or "?";
		positionHotkey();
		label:GetPropertyChangedSignal("TextBounds"):Connect(positionHotkey);
		hotkeyLabel.MouseButton1Click:Connect(function()
			hotkeyLabel.Text = "Press…";
			local conn;
			conn = UserInputService.InputBegan:Connect(function(input, gp)
				if (not gp and (input.UserInputType == Enum.UserInputType.Keyboard)) then
					local newKey = input.KeyCode.Name;
					Config.Hotkeys[hotkeyConfigKey] = newKey;
					saveKeybinds();
					hotkeyLabel.Text = newKey;
					positionHotkey();
					conn:Disconnect();
				end
			end);
		end);
	end
	local statusIndicator = Instance.new("Frame");
	statusIndicator.Name = "StatusIndicator";
	statusIndicator.Size = UDim2.new(0, 16, 0, 16);
	statusIndicator.Position = UDim2.new(1, -26, 0.5, -8);
	statusIndicator.BorderSizePixel = 0;
	statusIndicator.BackgroundColor3 = (startingState and Config.Theme.success) or Config.Theme.danger;
	statusIndicator.Parent = button;
	createCornerRadius(statusIndicator, UDim.new(1, 0));
	hitbox.MouseButton1Click:Connect(function()
		local current = button:GetAttribute("State");
		local newState = not current;
		button:SetAttribute("State", newState);
		button.BackgroundColor3 = (newState and Config.Theme.success) or Config.Theme.danger;
		statusIndicator.BackgroundColor3 = (newState and Config.Theme.success) or Config.Theme.danger;
		local tweenUp = TweenService:Create(statusIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(0, 20, 0, 20),Position=UDim2.new(1, -28, 0.5, -10)});
		tweenUp:Play();
		tweenUp.Completed:Connect(function()
			TweenService:Create(statusIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(0, 16, 0, 16),Position=UDim2.new(1, -26, 0.5, -8)}):Play();
		end);
		if callback then
			callback(newState);
		end
	end);
	return button;
end
local oldFireServer;
oldFireServer = hookmetamethod(game, "__namecall", function(self, ...)
	if ((getnamecallmethod() == "FireServer") and (self.Name == "StaminaDrain") and infiniteStaminaEnabled and (select(1, ...) == 1)) then
		return;
	end
	return oldFireServer(self, ...);
end);
if localPlayer.PlayerGui:FindFirstChild("CombatAssistUI") then
	localPlayer.PlayerGui:FindFirstChild("CombatAssistUI"):Destroy();
end
local screenGui = Instance.new("ScreenGui");
screenGui.Name = "CombatAssistUI";
screenGui.ResetOnSpawn = false;
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
screenGui.Parent = localPlayer:WaitForChild("PlayerGui");
local function showNotification(message)
	local notification = Instance.new("TextLabel");
	notification.Size = UDim2.new(0, 0, 0, 50);
	notification.AutomaticSize = Enum.AutomaticSize.X;
	notification.Position = UDim2.new(0.5, 0, 0, 70);
	notification.BackgroundColor3 = Config.Theme.primary;
	notification.BackgroundTransparency = 0.2;
	notification.Text = message;
	notification.TextColor3 = Config.Theme.text;
	notification.Font = Config.Theme.headerFont;
	notification.TextSize = 18;
	notification.Parent = screenGui;
	createCornerRadius(notification);
	local padding = Instance.new("UIPadding");
	padding.PaddingLeft = UDim.new(0, 15);
	padding.PaddingRight = UDim.new(0, 15);
	padding.PaddingTop = UDim.new(0, 10);
	padding.PaddingBottom = UDim.new(0, 10);
	padding.Parent = notification;
	task.defer(function()
		if (notification and notification.Parent) then
			local maxWidth = screenGui.AbsoluteSize.X * 0.8;
			local currentWidth = notification.AbsoluteSize.X;
			if (currentWidth > maxWidth) then
				notification.AutomaticSize = Enum.AutomaticSize.None;
				notification.Size = UDim2.new(0, maxWidth, 0, notification.AbsoluteSize.Y);
			end
			notification.Position = UDim2.new(0.5, -notification.AbsoluteSize.X / 2, 0, 70);
		end
	end);
	task.delay(3, function()
		if (notification and notification.Parent) then
			local tween = TweenService:Create(notification, TweenInfo.new(1), {TextTransparency=1,BackgroundTransparency=1});
			tween:Play();
			tween.Completed:Connect(function()
				if (notification and notification.Parent) then
					notification:Destroy();
				end
			end);
		end
	end);
end
local mainContainer = Instance.new("Frame");
mainContainer.Name = "MainContainer";
mainContainer.Size = UDim2.new(0, 300, 0, 40);
mainContainer.Position = UDim2.new(0, 20, 0, 20);
mainContainer.BackgroundColor3 = Config.Theme.primary;
mainContainer.BorderSizePixel = 0;
mainContainer.ClipsDescendants = true;
mainContainer.ZIndex = 10;
mainContainer.Parent = screenGui;
createCornerRadius(mainContainer);
createShadow(mainContainer);
local header = Instance.new("Frame");
header.Name = "Header";
header.Size = UDim2.new(1, 0, 0, 40);
header.BackgroundColor3 = Config.Theme.primary;
header.BorderSizePixel = 0;
header.ZIndex = 11;
header.Parent = mainContainer;
local title = Instance.new("TextLabel");
title.Name = "Title";
title.Size = UDim2.new(0.7, 0, 1, 0);
title.Position = UDim2.new(0, 15, 0, 0);
title.BackgroundTransparency = 1;
title.Text = "shitjuku 1988";
title.TextColor3 = Config.Theme.text;
title.Font = Config.Theme.headerFont;
title.TextSize = 18;
title.TextXAlignment = Enum.TextXAlignment.Left;
title.ZIndex = 12;
title.Parent = header;
local toggleButton = Instance.new("TextButton");
toggleButton.Name = "ToggleButton";
toggleButton.Size = UDim2.new(0, 34, 0, 34);
toggleButton.Position = UDim2.new(1, -40, 0, 3);
toggleButton.BackgroundColor3 = Config.Theme.button;
toggleButton.Text = "≡";
toggleButton.TextColor3 = Config.Theme.text;
toggleButton.Font = Config.Theme.headerFont;
toggleButton.TextSize = 20;
toggleButton.ZIndex = 12;
toggleButton.Parent = header;
createCornerRadius(toggleButton);
local contentContainer = Instance.new("Frame");
contentContainer.Name = "ContentContainer";
contentContainer.Size = UDim2.new(1, 0, 0, 350);
contentContainer.Position = UDim2.new(0, 0, 0, 40);
contentContainer.BackgroundColor3 = Config.Theme.background;
contentContainer.BackgroundTransparency = 0.1;
contentContainer.BorderSizePixel = 0;
contentContainer.ZIndex = 10;
contentContainer.Parent = mainContainer;
local tabsContainer = Instance.new("ScrollingFrame");
tabsContainer.Name = "TabsContainer";
tabsContainer.Size = UDim2.new(1, 0, 0, 40);
tabsContainer.BackgroundColor3 = Config.Theme.card;
tabsContainer.BorderSizePixel = 0;
tabsContainer.ZIndex = 11;
tabsContainer.Parent = contentContainer;
tabsContainer.CanvasSize = UDim2.new(0, 0, 0, 40);
tabsContainer.ScrollBarThickness = 4;
tabsContainer.ScrollingEnabled = true;
tabsContainer.ScrollingDirection = Enum.ScrollingDirection.X;
local tabsLayout = Instance.new("UIListLayout");
tabsLayout.FillDirection = Enum.FillDirection.Horizontal;
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder;
tabsLayout.Padding = UDim.new(0, 5);
tabsLayout.Parent = tabsContainer;
tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tabsContainer.CanvasSize = UDim2.new(0, tabsLayout.AbsoluteContentSize.X + 10, 0, 40);
end);
createPadding(tabsContainer, UDim.new(0, 5));
local tabContent = Instance.new("ScrollingFrame");
tabContent.Name = "TabContent";
tabContent.Size = UDim2.new(1, 0, 1, -50);
tabContent.Position = UDim2.new(0, 0, 0, 45);
tabContent.BackgroundTransparency = 1;
tabContent.BorderSizePixel = 0;
tabContent.ScrollBarThickness = 6;
tabContent.ScrollBarImageColor3 = Config.Theme.button;
tabContent.CanvasSize = UDim2.new(0, 0, 0, 0);
tabContent.ZIndex = 11;
tabContent.Parent = contentContainer;
local contentLayout = Instance.new("UIListLayout");
contentLayout.Padding = UDim.new(0, 10);
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
contentLayout.Parent = tabContent;
createPadding(tabContent, UDim.new(0, 10));
local openTab = nil;
local tabs = {};
local tabButtons = {};
local isExpanded = false;
local function createTab(name, displayName, layoutOrder)
	local tabButton = Instance.new("TextButton");
	tabButton.Name = name .. "Tab";
	tabButton.Size = UDim2.new(0, 90, 1, -10);
	tabButton.BackgroundColor3 = Config.Theme.button;
	tabButton.Text = displayName;
	tabButton.TextColor3 = Config.Theme.text;
	tabButton.Font = Config.Theme.bodyFont;
	tabButton.TextSize = 14;
	tabButton.LayoutOrder = layoutOrder;
	tabButton.ZIndex = 12;
	tabButton.Parent = tabsContainer;
	createCornerRadius(tabButton);
	local tabFrame = Instance.new("Frame");
	tabFrame.Name = name .. "Content";
	tabFrame.Size = UDim2.new(1, 0, 0, 0);
	tabFrame.BackgroundColor3 = Config.Theme.card;
	tabFrame.BorderSizePixel = 0;
	tabFrame.Visible = false;
	tabFrame.ZIndex = 11;
	tabFrame.Parent = tabContent;
	createCornerRadius(tabFrame);
	local tabContentLayout = Instance.new("UIListLayout");
	tabContentLayout.Padding = UDim.new(0, 10);
	tabContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
	tabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	tabContentLayout.Parent = tabFrame;
	createPadding(tabFrame, UDim.new(0, 10));
	tabButtons[name] = tabButton;
	tabs[name] = {button=tabButton,content=tabFrame,layout=tabContentLayout};
	tabButton.MouseButton1Click:Connect(function()
		if openTab then
			tabs[openTab].content.Visible = false;
			tabs[openTab].button.BackgroundColor3 = Config.Theme.button;
		end
		openTab = name;
		tabFrame.Visible = true;
		tabButton.BackgroundColor3 = Config.Theme.primary;
		tabFrame.Size = UDim2.new(1, -20, 0, tabContentLayout.AbsoluteContentSize.Y + 20);
		tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContentLayout.AbsoluteContentSize.Y + 40);
	end);
	return tabFrame, tabContentLayout;
end
do
	local dragging = false;
	local dragInput;
	local dragStart;
	local startPos;
	header.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = true;
			dragStart = input.Position;
			startPos = mainContainer.Position;
		end
	end);
	header.InputEnded:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false;
		end
	end);
	UserInputService.InputChanged:Connect(function(input)
		if (dragging and (input.UserInputType == Enum.UserInputType.MouseMovement)) then
			local delta = input.Position - dragStart;
			mainContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		end
	end);
end
toggleButton.MouseButton1Click:Connect(function()
	isExpanded = not isExpanded;
	local targetSize = (isExpanded and UDim2.new(0, 300, 0, 400)) or UDim2.new(0, 300, 0, 40);
	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=targetSize});
	tween:Play();
	if (isExpanded and not openTab) then
		local firstTab = next(tabs);
		if firstTab then
			tabs[firstTab].button.BackgroundColor3 = Config.Theme.primary;
			tabs[firstTab].content.Visible = true;
			openTab = firstTab;
			local layout = tabs[firstTab].layout;
			tabs[firstTab].content.Size = UDim2.new(1, -20, 0, layout.AbsoluteContentSize.Y + 20);
			tabContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 40);
		end
	end
end);
local function forceClick(pathTbl)
	local function waitPath(p)
		local inst = p[1];
		for i = 2, #p do
			inst = inst:WaitForChild(p[i], 5);
			if not inst then
				return nil;
			end
		end
		return inst;
	end
	local btn = waitPath(pathTbl);
	if not btn then
		return false;
	end
	local clickSigs = {btn.MouseButton1Click,btn.MouseButton1Down,btn.MouseButton1Up,btn.Activated,btn.TouchTap};
	local fired = false;
	print("[forceClick] Checking signals for:", btn:GetFullName());
	print("   Active?  Visible?", btn.Active, btn.Visible, "  Class:", btn.ClassName);
	for _, sName in ipairs({"MouseButton1Click","Activated","MouseButton1Down","MouseButton1Up","TouchTap"}) do
		local sig = btn[sName];
		if sig then
			local ok, cons = pcall(getconnections, sig);
			print(("   • %-15s   hasSignal=%s   connections=%d"):format(sName, tostring(not not sig), (ok and #cons) or -1));
		else
			print(("   • %-15s   <nil>"):format(sName));
		end
	end
	print("--------------------------------------------------");
	for _, sig in ipairs(clickSigs) do
		if not sig then
			continue;
		end
		local ok, cons = pcall(getconnections, sig);
		if ok then
			for _, c in ipairs(cons) do
				if pcall(c.Fire, c) then
					fired = true;
				end
			end
		end
		if pcall(firesignal, sig) then
			fired = true;
		end
		if (pcall(cansignalreplicate, sig) and pcall(replicatesignal, sig)) then
			fired = true;
		end
	end
	return fired;
end
local function forceClickPizzaAccept()
	local plr = Players.LocalPlayer;
	local path = {plr,"PlayerGui","PizzaGUI","Frame","AcceptButton"};
	return forceClick(path);
end
local manualFallbackPositions = {Vector3.new(157.66, 6.7, 176.21),Vector3.new(237.05, 14.03, -663.73),Vector3.new(329.44, 8.3, -335.66),Vector3.new(635.95, 3.63, -322.58),Vector3.new()};
local function getClosestManualPoint(beaconPos)
	local closest, minDist = nil, math.huge;
	for _, pos in ipairs(manualFallbackPositions) do
		local d = (pos - beaconPos).Magnitude;
		if (d < minDist) then
			minDist = d;
			closest = pos;
		end
	end
	if (minDist <= 50) then
		return closest;
	end
	return nil;
end
local function forceClickPizzaDecline()
	local plr = Players.LocalPlayer;
	local path = {plr,"PlayerGui","PizzaGUI","Frame","DeclineButton"};
	return forceClick(path);
end
local combatTabContent, combatLayout = createTab("combat", "Combat", 1);
local playersTabContent, playersLayout = createTab("players", "Player", 2);
local itemFinderTabContent, itemFinderLayout = createTab("itemFinder", "Item ESP", 3);
local autoFarmTabContent, autoFarmLayout = createTab("autoFarm", "Auto Farm", 4);
local settingsTabContent, settingsLayout = createTab("settings", "Misc", 5);
local meleeWeaponsSection = Instance.new("Frame");
meleeWeaponsSection.Name = "MeleeWeaponsSection";
meleeWeaponsSection.Size = UDim2.new(1, -20, 0, 40);
meleeWeaponsSection.BackgroundColor3 = Config.Theme.primary;
meleeWeaponsSection.BackgroundTransparency = 0.2;
meleeWeaponsSection.BorderSizePixel = 0;
meleeWeaponsSection.LayoutOrder = 1;
meleeWeaponsSection.ZIndex = 12;
meleeWeaponsSection.Parent = itemFinderTabContent;
createCornerRadius(meleeWeaponsSection);
local meleeTitle = Instance.new("TextLabel");
meleeTitle.Name = "Title";
meleeTitle.Size = UDim2.new(1, -20, 0, 20);
meleeTitle.Position = UDim2.new(0, 10, 0, 10);
meleeTitle.BackgroundTransparency = 1;
meleeTitle.Text = "Melee Weapons";
meleeTitle.TextColor3 = Config.Theme.text;
meleeTitle.Font = Config.Theme.headerFont;
meleeTitle.TextSize = 16;
meleeTitle.TextXAlignment = Enum.TextXAlignment.Left;
meleeTitle.ZIndex = 13;
meleeTitle.Parent = meleeWeaponsSection;
local meleeToggleContainer = Instance.new("Frame");
meleeToggleContainer.Name = "MeleeToggleContainer";
meleeToggleContainer.Size = UDim2.new(1, -20, 0, 182);
meleeToggleContainer.BackgroundColor3 = Config.Theme.card;
meleeToggleContainer.BackgroundTransparency = 0.3;
meleeToggleContainer.BorderSizePixel = 0;
meleeToggleContainer.LayoutOrder = 2;
meleeToggleContainer.ZIndex = 12;
meleeToggleContainer.Parent = itemFinderTabContent;
meleeToggleContainer.AutomaticSize = Enum.AutomaticSize.Y;
createCornerRadius(meleeToggleContainer);
local meleeToggleLayout = Instance.new("UIGridLayout");
meleeToggleLayout.CellSize = UDim2.new(0.5, -5, 0, 35);
meleeToggleLayout.CellPadding = UDim2.new(0, 10, 0, 4);
meleeToggleLayout.FillDirectionMaxCells = 2;
meleeToggleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
meleeToggleLayout.StartCorner = Enum.StartCorner.TopLeft;
meleeToggleLayout.Parent = meleeToggleContainer;
createPadding(meleeToggleContainer, UDim.new(0, 5));
for weaponName, _ in pairs(Config.Items.MeleeTypes) do
	local toggle = createToggleButton(weaponName, enabledItemTypes[weaponName], function(state)
		enabledItemTypes[weaponName] = state;
		if weaponLabelsEnabled then
			updateItemLabels();
		end
	end);
	toggle.Parent = meleeToggleContainer;
	meleeToggleButtons[weaponName] = toggle;
end
local meleeControlsContainer = Instance.new("Frame");
meleeControlsContainer.Name = "MeleeControlsContainer";
meleeControlsContainer.Size = UDim2.new(1, -20, 0, 35);
meleeControlsContainer.BackgroundTransparency = 1;
meleeControlsContainer.LayoutOrder = 3;
meleeControlsContainer.ZIndex = 12;
meleeControlsContainer.Parent = itemFinderTabContent;
local meleeControlsLayout = Instance.new("UIGridLayout");
meleeControlsLayout.CellSize = UDim2.new(0.5, -5, 1, 0);
meleeControlsLayout.CellPadding = UDim2.new(0, 10, 0, 0);
meleeControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
meleeControlsLayout.Parent = meleeControlsContainer;
local selectAllMeleeButton = Instance.new("TextButton");
selectAllMeleeButton.Name = "SelectAllMelee";
selectAllMeleeButton.BackgroundColor3 = Config.Theme.button;
selectAllMeleeButton.Text = "Select All Melee";
selectAllMeleeButton.TextColor3 = Config.Theme.text;
selectAllMeleeButton.Font = Config.Theme.bodyFont;
selectAllMeleeButton.TextSize = 14;
selectAllMeleeButton.ZIndex = 13;
selectAllMeleeButton.Parent = meleeControlsContainer;
createCornerRadius(selectAllMeleeButton);
local deselectAllMeleeButton = Instance.new("TextButton");
deselectAllMeleeButton.Name = "DeselectAllMelee";
deselectAllMeleeButton.BackgroundColor3 = Config.Theme.button;
deselectAllMeleeButton.Text = "Deselect All Melee";
deselectAllMeleeButton.TextColor3 = Config.Theme.text;
deselectAllMeleeButton.Font = Config.Theme.bodyFont;
deselectAllMeleeButton.TextSize = 14;
deselectAllMeleeButton.ZIndex = 13;
deselectAllMeleeButton.Parent = meleeControlsContainer;
createCornerRadius(deselectAllMeleeButton);
selectAllMeleeButton.MouseButton1Click:Connect(function()
	for weaponName, _ in pairs(Config.Items.MeleeTypes) do
		enabledItemTypes[weaponName] = true;
		local toggle = meleeToggleButtons[weaponName];
		if toggle then
			toggle.BackgroundColor3 = Config.Theme.success;
			toggle:SetAttribute("State", true);
			local statusIndicator = toggle:FindFirstChild("StatusIndicator");
			if statusIndicator then
				statusIndicator.BackgroundColor3 = Config.Theme.success;
			end
		end
	end
	if (weaponLabelsEnabled and updateItemLabels) then
		updateItemLabels();
	end
end);
deselectAllMeleeButton.MouseButton1Click:Connect(function()
	for weaponName, _ in pairs(Config.Items.MeleeTypes) do
		enabledItemTypes[weaponName] = false;
		local toggle = meleeToggleButtons[weaponName];
		if toggle then
			toggle.BackgroundColor3 = Config.Theme.danger;
			toggle:SetAttribute("State", false);
			local statusIndicator = toggle:FindFirstChild("StatusIndicator");
			if statusIndicator then
				statusIndicator.BackgroundColor3 = Config.Theme.danger;
			end
		end
	end
	if (weaponLabelsEnabled and updateItemLabels) then
		updateItemLabels();
	end
end);
local SprintKeeper = {};
SprintKeeper.thread = nil;
SprintKeeper.start = function(self)
	if self.thread then
		return;
	end
	self.thread = task.spawn(function()
		while autoFarmEnabled or itemFarmEnabled do
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game);
			task.wait(0.25);
		end
		self.thread = nil;
	end);
end;
SprintKeeper.stop = function(self)
	if self.thread then
		task.cancel(self.thread);
		self.thread = nil;
	end
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game);
end;
autoAttackToggle = createToggleButton("Auto Clothesline", autoAttackEnabled, function(state)
	autoAttackEnabled = state;
	print("Auto Clothesline toggled:", autoAttackEnabled);
	if autoAttackEnabled then
		if (not visualHitbox or not visualHitbox.Parent) then
			visualHitbox = Instance.new("Part");
			visualHitbox.Name = "HitboxVisualization";
			visualHitbox.Size = Vector3.new(2.5, 3, 2.5);
			visualHitbox.Anchored = true;
			visualHitbox.CanCollide = false;
			visualHitbox.Material = Enum.Material.Neon;
			visualHitbox.Color = Config.Theme.secondary;
			visualHitbox.Parent = workspace;
		end
		visualHitbox.Transparency = 0.7;
	elseif (visualHitbox and visualHitbox.Parent) then
		visualHitbox.Transparency = 1;
	end
end);
autoAttackToggle.Parent = combatTabContent;
autoAttackToggle.LayoutOrder = 1;
local function getCenter(guiObject)
	local absolutePosition = guiObject.AbsolutePosition;
	local absoluteSize = guiObject.AbsoluteSize;
	return Vector2.new(absolutePosition.X + (absoluteSize.X / 2), absolutePosition.Y + (absoluteSize.Y / 2));
end
local function updateHistory(history, position, timestamp)
	table.insert(history, {position=position,time=timestamp});
	if (#history > 10) then
		table.remove(history, 1);
	end
end
local function predictPosition(history, currentPos, currentTime)
	if (#history < 2) then
		return currentPos;
	end
	local velocitySum = Vector2.new(0, 0);
	local samples = 0;
	for i = 2, #history do
		local prev = history[i - 1];
		local curr = history[i];
		local dt = curr.time - prev.time;
		if (dt > 0) then
			local velocity = (curr.position - prev.position) / dt;
			velocitySum = velocitySum + velocity;
			samples = samples + 1;
		end
	end
	if (samples == 0) then
		return currentPos;
	end
	local avgVelocity = velocitySum / samples;
	return currentPos + (avgVelocity * Config.AutoFish.PredictionDelay);
end
local function rotateVector(vector, angleDegrees)
	local angleRadians = math.rad(angleDegrees);
	local cosAngle = math.cos(angleRadians);
	local sinAngle = math.sin(angleRadians);
	return Vector2.new((vector.X * cosAngle) - (vector.Y * sinAngle), (vector.X * sinAngle) + (vector.Y * cosAngle));
end
local aimbotToggle = createToggleButton("Aimbot", aimbotEnabled, function(state)
	aimbotEnabled = state;
end, "Aimbot");
aimbotToggle.Parent = combatTabContent;
aimbotToggle.LayoutOrder = 2;
autoDodgeToggle = createToggleButton("Auto Dodge", autoDodgeEnabled, function(state)
	autoDodgeEnabled = state;
	if autoDodgeEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if (player ~= localPlayer) then
				monitorEnemy(player);
			end
		end
	end
end);
autoDodgeToggle.Parent = combatTabContent;
autoDodgeToggle.LayoutOrder = 3;
local infiniteStaminaToggle = createToggleButton("Infinite Stamina", infiniteStaminaEnabled, function(state)
	infiniteStaminaEnabled = state;
	print("Infinite Stamina toggled:", infiniteStaminaEnabled);
end);
infiniteStaminaToggle.Parent = settingsTabContent;
infiniteStaminaToggle.LayoutOrder = 2;
local separator = Instance.new("Frame");
separator.Name = "Separator";
separator.Size = UDim2.new(1, -20, 0, 2);
separator.BackgroundColor3 = Config.Theme.border;
separator.BorderSizePixel = 0;
separator.LayoutOrder = 4;
separator.ZIndex = 12;
separator.Parent = itemFinderTabContent;
local rangedWeaponsSection = Instance.new("Frame");
rangedWeaponsSection.Name = "RangedWeaponsSection";
rangedWeaponsSection.Size = UDim2.new(1, -20, 0, 40);
rangedWeaponsSection.BackgroundColor3 = Config.Theme.primary;
rangedWeaponsSection.BackgroundTransparency = 0.2;
rangedWeaponsSection.BorderSizePixel = 0;
rangedWeaponsSection.LayoutOrder = 5;
rangedWeaponsSection.ZIndex = 12;
rangedWeaponsSection.Parent = itemFinderTabContent;
createCornerRadius(rangedWeaponsSection);
local rangedTitle = Instance.new("TextLabel");
rangedTitle.Name = "Title";
rangedTitle.Size = UDim2.new(1, -20, 0, 20);
rangedTitle.Position = UDim2.new(0, 10, 0, 10);
rangedTitle.BackgroundTransparency = 1;
rangedTitle.Text = "Ranged Weapons";
rangedTitle.TextColor3 = Config.Theme.text;
rangedTitle.Font = Config.Theme.headerFont;
rangedTitle.TextSize = 16;
rangedTitle.TextXAlignment = Enum.TextXAlignment.Left;
rangedTitle.ZIndex = 13;
rangedTitle.Parent = rangedWeaponsSection;
local rangedToggleContainer = Instance.new("Frame");
rangedToggleContainer.Name = "RangedToggleContainer";
rangedToggleContainer.Size = UDim2.new(1, -20, 0, 79);
rangedToggleContainer.BackgroundColor3 = Config.Theme.card;
rangedToggleContainer.BackgroundTransparency = 0.3;
rangedToggleContainer.BorderSizePixel = 0;
rangedToggleContainer.LayoutOrder = 6;
rangedToggleContainer.ZIndex = 12;
rangedToggleContainer.Parent = itemFinderTabContent;
rangedToggleContainer.AutomaticSize = Enum.AutomaticSize.Y;
createCornerRadius(rangedToggleContainer);
local rangedToggleLayout = Instance.new("UIGridLayout");
rangedToggleLayout.CellSize = UDim2.new(0.5, -5, 0, 35);
rangedToggleLayout.CellPadding = UDim2.new(0, 10, 0, 4);
rangedToggleLayout.FillDirectionMaxCells = 2;
rangedToggleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
rangedToggleLayout.StartCorner = Enum.StartCorner.TopLeft;
rangedToggleLayout.Parent = rangedToggleContainer;
createPadding(rangedToggleContainer, UDim.new(0, 5));
local rangedWeapons = {};
for weapon, _ in pairs(Config.Items.RangedTypes) do
	table.insert(rangedWeapons, weapon);
end
for _, weaponName in ipairs(rangedWeapons) do
	local toggle = createToggleButton(weaponName, enabledItemTypes[weaponName], function(state)
		enabledItemTypes[weaponName] = state;
		if weaponLabelsEnabled then
			updateItemLabels();
		end
	end);
	toggle.Parent = rangedToggleContainer;
	rangedToggleButtons[weaponName] = toggle;
end
local rangedControlsContainer = Instance.new("Frame");
rangedControlsContainer.Name = "RangedControlsContainer";
rangedControlsContainer.Size = UDim2.new(1, -20, 0, 35);
rangedControlsContainer.BackgroundTransparency = 1;
rangedControlsContainer.LayoutOrder = 7;
rangedControlsContainer.ZIndex = 12;
rangedControlsContainer.Parent = itemFinderTabContent;
local rangedControlsLayout = Instance.new("UIGridLayout");
rangedControlsLayout.CellSize = UDim2.new(0.5, -5, 1, 0);
rangedControlsLayout.CellPadding = UDim2.new(0, 10, 0, 0);
rangedControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
rangedControlsLayout.Parent = rangedControlsContainer;
local selectAllRangedButton = Instance.new("TextButton");
selectAllRangedButton.Name = "SelectAllRanged";
selectAllRangedButton.BackgroundColor3 = Config.Theme.button;
selectAllRangedButton.Text = "Select All Ranged";
selectAllRangedButton.TextColor3 = Config.Theme.text;
selectAllRangedButton.Font = Config.Theme.bodyFont;
selectAllRangedButton.TextSize = 14;
selectAllRangedButton.ZIndex = 13;
selectAllRangedButton.Parent = rangedControlsContainer;
createCornerRadius(selectAllRangedButton);
local deselectAllRangedButton = Instance.new("TextButton");
deselectAllRangedButton.Name = "DeselectAllRanged";
deselectAllRangedButton.BackgroundColor3 = Config.Theme.button;
deselectAllRangedButton.Text = "Deselect All Ranged";
deselectAllRangedButton.TextColor3 = Config.Theme.text;
deselectAllRangedButton.Font = Config.Theme.bodyFont;
deselectAllRangedButton.TextSize = 14;
deselectAllRangedButton.ZIndex = 13;
deselectAllRangedButton.Parent = rangedControlsContainer;
selectAllRangedButton.MouseButton1Click:Connect(function()
	for _, weaponName in ipairs(rangedWeapons) do
		enabledItemTypes[weaponName] = true;
		local toggle = rangedToggleButtons[weaponName];
		if toggle then
			toggle.BackgroundColor3 = Config.Theme.success;
			toggle:SetAttribute("State", true);
			local statusIndicator = toggle:FindFirstChild("StatusIndicator");
			if statusIndicator then
				statusIndicator.BackgroundColor3 = Config.Theme.success;
			end
		end
	end
	if (weaponLabelsEnabled and updateItemLabels) then
		updateItemLabels();
	end
end);
deselectAllRangedButton.MouseButton1Click:Connect(function()
	for _, weaponName in ipairs(rangedWeapons) do
		enabledItemTypes[weaponName] = false;
		local toggle = rangedToggleButtons[weaponName];
		if toggle then
			toggle.BackgroundColor3 = Config.Theme.danger;
			toggle:SetAttribute("State", false);
			local statusIndicator = toggle:FindFirstChild("StatusIndicator");
			if statusIndicator then
				statusIndicator.BackgroundColor3 = Config.Theme.danger;
			end
		end
	end
	if (weaponLabelsEnabled and updateItemLabels) then
		updateItemLabels();
	end
end);
createCornerRadius(deselectAllRangedButton);
local separator2 = Instance.new("Frame");
separator2.Name = "Separator2";
separator2.Size = UDim2.new(1, -20, 0, 2);
separator2.BackgroundColor3 = Config.Theme.border;
separator2.BorderSizePixel = 0;
separator2.LayoutOrder = 8;
separator2.ZIndex = 12;
separator2.Parent = itemFinderTabContent;
local displaySettingsSection = Instance.new("Frame");
displaySettingsSection.Name = "DisplaySettingsSection";
displaySettingsSection.Size = UDim2.new(1, -20, 0, 40);
displaySettingsSection.BackgroundColor3 = Config.Theme.primary;
displaySettingsSection.BackgroundTransparency = 0.2;
displaySettingsSection.BorderSizePixel = 0;
displaySettingsSection.LayoutOrder = 9;
displaySettingsSection.ZIndex = 12;
displaySettingsSection.Parent = itemFinderTabContent;
createCornerRadius(displaySettingsSection);
local displayTitle = Instance.new("TextLabel");
displayTitle.Name = "Title";
displayTitle.Size = UDim2.new(1, -20, 0, 20);
displayTitle.Position = UDim2.new(0, 10, 0, 10);
displayTitle.BackgroundTransparency = 1;
displayTitle.Text = "Display Settings";
displayTitle.TextColor3 = Config.Theme.text;
displayTitle.Font = Config.Theme.headerFont;
displayTitle.TextSize = 16;
displayTitle.TextXAlignment = Enum.TextXAlignment.Left;
displayTitle.ZIndex = 13;
displayTitle.Parent = displaySettingsSection;
local displaySettingsContainer = Instance.new("Frame");
displaySettingsContainer.Name = "DisplaySettingsContainer";
displaySettingsContainer.Size = UDim2.new(1, -20, 0, 85);
displaySettingsContainer.BackgroundColor3 = Config.Theme.card;
displaySettingsContainer.BackgroundTransparency = 0.3;
displaySettingsContainer.BorderSizePixel = 0;
displaySettingsContainer.LayoutOrder = 10;
displaySettingsContainer.ZIndex = 12;
displaySettingsContainer.Parent = itemFinderTabContent;
local displaySettingsLayout = Instance.new("UIListLayout");
displaySettingsLayout.Padding = UDim.new(0, 5);
displaySettingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
displaySettingsLayout.FillDirection = Enum.FillDirection.Vertical;
displaySettingsLayout.Parent = displaySettingsContainer;
createCornerRadius(displaySettingsContainer);
createPadding(displaySettingsContainer, UDim.new(0, 5));
local searchDroppedToggle = createToggleButton("Search Dropped Items", searchDroppedItemsEnabled, function(state)
	searchDroppedItemsEnabled = state;
	if weaponLabelsEnabled then
		updateItemLabels();
	end
end);
searchDroppedToggle.Size = UDim2.new(1, -10, 0, 35);
searchDroppedToggle.LayoutOrder = 1;
searchDroppedToggle.Parent = displaySettingsContainer;
local showDistanceToggle = createToggleButton("Show Distance", showItemDistance, function(state)
	showItemDistance = state;
	if weaponLabelsEnabled then
		updateItemLabels();
	end
end);
showDistanceToggle.Size = UDim2.new(1, -10, 0, 35);
showDistanceToggle.LayoutOrder = 2;
showDistanceToggle.Parent = displaySettingsContainer;
task.spawn(function()
	task.wait();
	local totalHeight = itemFinderLayout.AbsoluteContentSize.Y + 20;
	tabContent.CanvasSize = UDim2.new(0, 0, 0, totalHeight);
	tabs['itemFinder'].content.Size = UDim2.new(1, -20, 0, totalHeight);
end);
local searchContainer = Instance.new("Frame");
searchContainer.Name = "SearchContainer";
searchContainer.Size = UDim2.new(1, -20, 0, 35);
searchContainer.BackgroundColor3 = Config.Theme.button;
searchContainer.BorderSizePixel = 0;
searchContainer.LayoutOrder = 0;
searchContainer.ZIndex = 12;
searchContainer.Parent = playersTabContent;
createCornerRadius(searchContainer);
local searchBox = Instance.new("TextBox");
searchBox.Name = "SearchBox";
searchBox.Size = UDim2.new(1, -16, 1, -10);
searchBox.Position = UDim2.new(0, 8, 0, 5);
searchBox.BackgroundTransparency = 1;
searchBox.PlaceholderText = "Search players...";
searchBox.Text = "";
searchBox.TextColor3 = Config.Theme.text;
searchBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180);
searchBox.Font = Config.Theme.bodyFont;
searchBox.TextSize = 14;
searchBox.TextXAlignment = Enum.TextXAlignment.Left;
searchBox.ClearTextOnFocus = false;
searchBox.ZIndex = 13;
searchBox.Parent = searchContainer;
local searchIcon = Instance.new("ImageLabel");
searchIcon.Name = "SearchIcon";
searchIcon.Size = UDim2.new(0, 16, 0, 16);
searchIcon.Position = UDim2.new(1, -24, 0.5, -8);
searchIcon.BackgroundTransparency = 1;
searchIcon.Image = "rbxassetid://3192528333";
searchIcon.ImageColor3 = Config.Theme.text;
searchIcon.ZIndex = 13;
searchIcon.Parent = searchContainer;
local clearButton = Instance.new("TextButton");
clearButton.Name = "ClearButton";
clearButton.Size = UDim2.new(0, 16, 0, 16);
clearButton.Position = UDim2.new(1, -48, 0.5, -8);
clearButton.BackgroundTransparency = 1;
clearButton.Text = "✕";
clearButton.TextColor3 = Config.Theme.text;
clearButton.Font = Config.Theme.bodyFont;
clearButton.TextSize = 14;
clearButton.Visible = false;
clearButton.ZIndex = 13;
clearButton.Parent = searchContainer;
clearButton.MouseButton1Click:Connect(function()
	searchBox.Text = "";
	clearButton.Visible = false;
	updatePlayerList();
end);
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local searchText = searchBox.Text;
	clearButton.Visible = searchText ~= "";
	updatePlayerList(searchText);
end);
local playersListFrame = Instance.new("Frame");
playersListFrame.Name = "PlayersListFrame";
playersListFrame.Size = UDim2.new(1, -20, 0, 240);
playersListFrame.BackgroundColor3 = Config.Theme.card;
playersListFrame.BackgroundTransparency = 0.3;
playersListFrame.BorderSizePixel = 0;
playersListFrame.ClipsDescendants = true;
playersListFrame.LayoutOrder = 1;
playersListFrame.ZIndex = 12;
playersListFrame.Parent = playersTabContent;
createCornerRadius(playersListFrame);
createStroke(playersListFrame, Config.Theme.border, 1);
local playerListContainer = Instance.new("ScrollingFrame");
playerListContainer.Name = "PlayerListContainer";
playerListContainer.Size = UDim2.new(1, 0, 1, 0);
playerListContainer.BackgroundTransparency = 1;
playerListContainer.ScrollBarThickness = 6;
playerListContainer.ScrollBarImageColor3 = Config.Theme.button;
playerListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y;
playerListContainer.ZIndex = 12;
playerListContainer.Parent = playersListFrame;
createCornerRadius(playerListContainer);
createStroke(playerListContainer, Config.Theme.border, 1);
local playerListLayout = Instance.new("UIListLayout");
playerListLayout.Padding = UDim.new(0, 12);
playerListLayout.SortOrder = Enum.SortOrder.Name;
playerListLayout.Parent = playerListContainer;
createPadding(playerListContainer, UDim.new(0, 8));
local playersControlsContainer = Instance.new("Frame");
playersControlsContainer.Name = "PlayersControlsContainer";
playersControlsContainer.Size = UDim2.new(1, -20, 0, 90);
playersControlsContainer.BackgroundColor3 = Config.Theme.card;
playersControlsContainer.BackgroundTransparency = 0.3;
playersControlsContainer.BorderSizePixel = 0;
playersControlsContainer.LayoutOrder = 3;
playersControlsContainer.ZIndex = 12;
playersControlsContainer.Parent = playersTabContent;
createCornerRadius(playersControlsContainer);
createStroke(playersControlsContainer, Config.Theme.border, 1);
local controlsLayout = Instance.new("UIListLayout");
controlsLayout.FillDirection = Enum.FillDirection.Vertical;
controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder;
controlsLayout.Padding = UDim.new(0, 10);
controlsLayout.Parent = playersControlsContainer;
createPadding(playersControlsContainer, UDim.new(0, 10));
trackAllToggle = createToggleButton("Track Everyone", trackAllEnabled, function(state)
	trackAllEnabled = state;
	for _, pl in ipairs(Players:GetPlayers()) do
		if (pl ~= localPlayer) then
			highlightToggledPlayers[pl] = state;
			updatePlayerHighlight(pl);
		end
	end
	updatePlayerList();
end);
trackAllToggle.Size = UDim2.new(1, -20, 0, 35);
trackAllToggle.Parent = playersControlsContainer;
trackAllToggle.LayoutOrder = 1;
local function clearOldPath()
	local character = localPlayer.Character;
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid");
		local hrp = character:FindFirstChild("HumanoidRootPart");
		if (humanoid and hrp) then
			humanoid:MoveTo(hrp.Position);
		end
	end
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game);
end
local function addChamsToCharacter(character)
	if not character then
		return;
	end
	for _, part in ipairs(character:GetDescendants()) do
		if (part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory")) then
			local existingCham = part:FindFirstChild("ChamAdornment");
			if existingCham then
				existingCham:Destroy();
			end
			local chamAdornment = Instance.new("BoxHandleAdornment");
			chamAdornment.Name = "ChamAdornment";
			chamAdornment.Adornee = part;
			chamAdornment.Size = part.Size;
			chamAdornment.Color3 = Config.Theme.playerHighlightFill;
			chamAdornment.Transparency = 0.7;
			chamAdornment.AlwaysOnTop = true;
			chamAdornment.ZIndex = 5;
			chamAdornment.Parent = part;
		end
	end
end
local function removeChamsFromCharacter(character)
	if not character then
		return;
	end
	for _, part in ipairs(character:GetDescendants()) do
		if (part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory")) then
			local chamAdornment = part:FindFirstChild("ChamAdornment");
			if chamAdornment then
				chamAdornment:Destroy();
			end
		end
	end
end
function updatePlayerHighlight(player)
	if not player.Character then
		return;
	end
	if highlightToggledPlayers[player] then
		addChamsToCharacter(player.Character);
	else
		removeChamsFromCharacter(player.Character);
	end
end
local function findPizzaBeacons()
	local beacons = {};
	local character = localPlayer.Character;
	local hrp = character and character:FindFirstChild("HumanoidRootPart");
	if not hrp then
		return beacons;
	end
	for _, part in pairs(workspace:GetChildren()) do
		if (part.Name == "PizzaBeacon") then
			local distance = (part.Position - hrp.Position).Magnitude;
			table.insert(beacons, {model=part,distance=distance,position=part.Position});
		end
	end
	table.sort(beacons, function(a, b)
		return a.distance < b.distance;
	end);
	return beacons;
end
local autoFishToggle = createToggleButton("Auto Fish", autoFishEnabled, function(state)
	autoFishEnabled = state;
	if autoFishEnabled then
		local existingFishingMinigame = localPlayer.PlayerGui:FindFirstChild("FishingMinigame");
		if (existingFishingMinigame and existingFishingMinigame:IsA("ScreenGui")) then
			startAlignment(existingFishingMinigame);
		end
		local function onFishingMinigameAdded(child)
			if ((child.Name == "FishingMinigame") and child:IsA("ScreenGui")) then
				startAlignment(child);
				child.AncestryChanged:Connect(function(_, parent)
					if not parent then
						stopAlignment();
						if autoFishEnabled then
							autoCast();
						end
					end
				end);
			end
		end
		localPlayer.PlayerGui.ChildAdded:Connect(onFishingMinigameAdded);
		monitorCanCatchFish();
	else
		stopAlignment();
		if alignmentConnection then
			alignmentConnection:Disconnect();
			alignmentConnection = nil;
		end
	end
end);
autoFishToggle.LayoutOrder = 2;
autoFishToggle.Parent = autoFarmTabContent;
local function canSendMouseEvent()
	return (tick() - lastMouseEventTime) >= Config.AutoFish.MouseEventCooldown;
end
local function sendMouseEvent(isDown)
	if not canSendMouseEvent() then
		return;
	end
	local mouseLocation = UserInputService:GetMouseLocation();
	local success, err = pcall(function()
		VirtualInputManager:SendMouseButtonEvent(mouseLocation.X, mouseLocation.Y, 0, isDown, game, 0);
	end);
	if not success then
	else
		lastMouseEventTime = tick();
		mouseHeld = isDown;
	end
end
local function holdMouse()
	if not mouseHeld then
		sendMouseEvent(true);
	end
end
local function releaseMouse()
	if mouseHeld then
		sendMouseEvent(false);
	end
end
local function getCastPoint()
	local character = localPlayer.Character;
	if not character then
		return;
	end
	local hrp = character:FindFirstChild("HumanoidRootPart");
	if not hrp then
		return;
	end
	local basePoint = hrp.Position + (hrp.CFrame.LookVector * 5);
	local castPoint = Vector3.new(basePoint.X, 4.5, basePoint.Z);
	local distance = (hrp.Position - castPoint).Magnitude;
	if (distance > 25) then
		return nil;
	end
	return castPoint;
end
local function castFishingLine()
	local tool = localPlayer.Character and localPlayer.Character:FindFirstChild("Fishing Rod");
	if not tool then
		tool = localPlayer:WaitForChild("Backpack"):FindFirstChild("Fishing Rod");
	end
	if tool then
		local castEvent = tool:FindFirstChild("CastLine");
		if (castEvent and castEvent:IsA("RemoteEvent")) then
			local castPoint = getCastPoint();
			if castPoint then
				castEvent:FireServer(castPoint);
				task.delay(1, function()
					local fishHook = tool:FindFirstChild("FishHook");
					if (fishHook and (fishHook.Value == nil)) then
						autoCast();
					end
				end);
			else
			end
		else
		end
	else
	end
end
function startAlignment(fishingMinigame)
	if not autoFishEnabled then
		return;
	end
	currentFishingMinigame = fishingMinigame;
	yellowHistory = {};
	whiteHistory = {};
	local mainFrame = fishingMinigame:WaitForChild("Frame");
	local fishBar = mainFrame:WaitForChild("FishBar");
	local reelBar = fishBar:WaitForChild("ReelBar");
	local fishIcon = fishBar:WaitForChild("FishIcon");
	if alignmentConnection then
		alignmentConnection:Disconnect();
	end
	alignmentConnection = RunService.Heartbeat:Connect(function(dt)
		if not autoFishEnabled then
			stopAlignment();
			return;
		end
		local currentTime = tick();
		local currentYellow = getCenter(reelBar);
		local currentWhite = getCenter(fishIcon);
		updateHistory(yellowHistory, currentYellow, currentTime);
		updateHistory(whiteHistory, currentWhite, currentTime);
		local predictedYellow = predictPosition(yellowHistory, currentYellow, currentTime);
		local predictedWhite = predictPosition(whiteHistory, currentWhite, currentTime);
		local rotatedYellow = rotateVector(predictedYellow, Config.AutoFish.TiltAngle);
		local rotatedWhite = rotateVector(predictedWhite, Config.AutoFish.TiltAngle);
		local verticalDiff = rotatedYellow.Y - rotatedWhite.Y;
		if (math.abs(verticalDiff) <= Config.AutoFish.Tolerance) then
			holdMouse();
		elseif (verticalDiff < 0) then
			releaseMouse();
		else
			holdMouse();
		end
	end);
end
function stopAlignment()
	if alignmentConnection then
		alignmentConnection:Disconnect();
		alignmentConnection = nil;
	end
	releaseMouse();
	currentFishingMinigame = nil;
end
function autoCast()
	if not autoFishEnabled then
		return;
	end
	task.delay(1, castFishingLine);
end
function monitorCanCatchFish()
	if not autoFishEnabled then
		return;
	end
	local function getFishingRod()
		local tool = localPlayer.Character and localPlayer.Character:FindFirstChild("Fishing Rod");
		if not tool then
			tool = localPlayer:WaitForChild("Backpack"):FindFirstChild("Fishing Rod");
		end
		return tool;
	end
	local fishingRod = getFishingRod();
	if not fishingRod then
		print("Fishing Rod not found, setting up watch for it");
		local backpackAddedConn;
		backpackAddedConn = localPlayer.Backpack.ChildAdded:Connect(function(item)
			if (item.Name == "Fishing Rod") then
				backpackAddedConn:Disconnect();
				fishingRod = item;
				setupCanCatchFishMonitor(fishingRod);
			end
		end);
		local charAddedConn;
		if localPlayer.Character then
			charAddedConn = localPlayer.Character.ChildAdded:Connect(function(item)
				if (item.Name == "Fishing Rod") then
					charAddedConn:Disconnect();
					fishingRod = item;
					setupCanCatchFishMonitor(fishingRod);
				end
			end);
		end
		return;
	end
	setupCanCatchFishMonitor(fishingRod);
end
function setupCanCatchFishMonitor(fishingRod)
	print("Setting up canCatchFish monitor for", fishingRod:GetFullName());
	local canCatchFish = fishingRod:FindFirstChild("canCatchFish");
	if canCatchFish then
		connectCanCatchFish(canCatchFish);
	else
		local connection;
		connection = fishingRod.ChildAdded:Connect(function(child)
			if (child.Name == "canCatchFish") then
				print("canCatchFish value added to fishing rod");
				connection:Disconnect();
				connectCanCatchFish(child);
			end
		end);
		task.delay(2, function()
			if connection.Connected then
				local recheck = fishingRod:FindFirstChild("canCatchFish");
				if recheck then
					print("Found canCatchFish on recheck");
					connection:Disconnect();
					connectCanCatchFish(recheck);
				end
			end
		end);
	end
end
function connectCanCatchFish(canCatchFish)
	print("Connected to canCatchFish value");
	canCatchFish.Changed:Connect(function(newValue)
		if (autoFishEnabled and (newValue == true)) then
			print("Fish bite detected! Clicking...");
			sendMouseEvent(true);
			task.delay(0.1, function()
				sendMouseEvent(false);
			end);
		end
	end);
end
RunService:BindToRenderStep("AimLock", Enum.RenderPriority.Camera.Value, function()
	if not aimbotEnabled then
		return;
	end
	if (holdingAim and lockedTarget and lockedTarget.Parent) then
		local camPos = camera.CFrame.Position;
		local headPos = lockedTarget.Position;
		camera.CFrame = CFrame.new(camPos, headPos);
	end
end);
local farmCfg = Config.AutoFarm;
local function nearestBeacon(hrp)
	local nearest, dist = nil, math.huge;
	for _, p in ipairs(workspace:GetChildren()) do
		if (p.Name == "PizzaBeacon") then
			local d = (p.Position - hrp.Position).Magnitude;
			if (d < dist) then
				dist, nearest = d, p;
			end
		end
	end
	return nearest, dist;
end
local function getBeaconPosition(beacon)
	if beacon:IsA("Model") then
		local part = beacon.PrimaryPart or beacon:FindFirstChildWhichIsA("BasePart");
		return (part and part.Position) or beacon:GetModelCFrame().p;
	else
		return beacon.Position;
	end
end
local function pressF()
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game);
	task.wait(0.08);
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game);
end
local function walkPathToItem(humanoid, rootPart, itemModel, doInteract)
	doInteract = doInteract ~= false;
	local originPart;
	if itemModel:IsA("BasePart") then
		originPart = itemModel;
	else
		originPart = itemModel:FindFirstChild("Origin");
		if not (originPart and originPart:IsA("MeshPart")) then
			originPart = itemModel.PrimaryPart or itemModel:FindFirstChildWhichIsA("BasePart");
		end
	end
	if not originPart then
		warn("[walkPathToItem] Could not find any part to path to for", itemModel.Name);
		return false;
	end
	local dest = originPart.Position;
	local agentParams = {AgentRadius=3,AgentHeight=5,AgentCanJump=false,AgentCanClimb=true,WaypointSpacing=3};
	local function computePath()
		local p = PathfindingService:CreatePath(agentParams);
		p:ComputeAsync(rootPart.Position, dest);
		return p;
	end
	local attempt = 1;
	local path;
	while attempt <= 2 do
		path = computePath();
		local status = path.Status;
		if ((status == Enum.PathStatus.Success) or (status == Enum.PathStatus.ClosestNoPath)) then
			break;
		elseif (attempt == 1) then
		else
			return false;
		end
		attempt = attempt + 1;
		task.wait(0.2);
	end
	local function shouldSprint()
		return (rootPart.Position - dest).Magnitude > Config.AutoFarm.sprintThreshold;
	end
	if shouldSprint() then
		SprintKeeper:start();
	end
	local lastPosition = rootPart.Position;
	local lastCheckTime = tick();
	local progressThreshold = 5;
	local progressInterval = 2;
	local blockedConn;
	local function onBlocked()
		warn(("[walkPathToItem] path blocked en route to %s; recomputing…"):format(itemModel.Name));
		path = computePath();
		blockedConn:Disconnect();
		blockedConn = path.Blocked:Connect(onBlocked);
		lastPosition = rootPart.Position;
		lastCheckTime = tick();
	end
	blockedConn = path.Blocked:Connect(onBlocked);
	local waypoints = path:GetWaypoints();
	local idx = 1;
	while idx <= #waypoints do
		local wp = waypoints[idx];
		if (not itemModel or not itemModel.Parent) then
			warn(("[walkPathToItem] %s vanished mid-path; aborting"):format(tostring(itemModel and itemModel.Name)));
			blockedConn:Disconnect();
			SprintKeeper:stop();
			return false;
		end
		humanoid:MoveTo(wp.Position);
		local distToWP = (rootPart.Position - wp.Position).Magnitude;
		local timeout = math.clamp(distToWP / 5, 3, 10);
		local reached = humanoid.MoveToFinished:Wait(timeout);
		local now = tick();
		if ((now - lastCheckTime) >= progressInterval) then
			local distBefore = (lastPosition - dest).Magnitude;
			local distAfter = (rootPart.Position - dest).Magnitude;
			if ((distBefore - distAfter) < progressThreshold) then
				warn(("[walkPathToItem] stuck (only %.1f→%.1f studs); recomputing path to %s"):format(distBefore, distAfter, itemModel.Name));
				path = computePath();
				waypoints = path:GetWaypoints();
				idx = 1;
				if shouldSprint() then
					SprintKeeper:start();
				else
					SprintKeeper:stop();
				end
				lastPosition = rootPart.Position;
				lastCheckTime = now;
				continue;
			else
				lastPosition = rootPart.Position;
				lastCheckTime = now;
			end
		end
		if not reached then
			humanoid.Jump = true;
			task.wait(0.2);
			path = computePath();
			waypoints = path:GetWaypoints();
			idx = 1;
			if shouldSprint() then
				SprintKeeper:start();
			else
				SprintKeeper:stop();
			end
		else
			idx = idx + 1;
		end
	end
	blockedConn:Disconnect();
	SprintKeeper:stop();
	if doInteract then
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game);
		task.wait(1);
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game);
	end
	print(("[walkPathToItem] Arrived at item: %s"):format(itemModel.Name));
	return true;
end
local function walkPath(humanoid, rootPart, dest, doInteract)
	doInteract = doInteract ~= false;
	local function computePath()
		local cfg = {AgentRadius=2,AgentHeight=5,AgentCanJump=false,WaypointSpacing=3};
		return PathfindingService:CreatePath(cfg);
	end
	local path = computePath();
	path:ComputeAsync(rootPart.Position, dest);
	if not ((path.Status == Enum.PathStatus.Success) or (path.Status == Enum.PathStatus.ClosestNoPath)) then
		warn(string.format("[walkPath] Compute failed: %s - Distance: %.2f studs", tostring(path.Status), (rootPart.Position - dest).Magnitude));
		return false;
	end
	if ((rootPart.Position - dest).Magnitude > Config.AutoFarm.sprintThreshold) then
		SprintKeeper:start();
	end
	local blockedConn = path.Blocked:Connect(function()
		warn(string.format("[walkPath] Path blocked at position (%.2f, %.2f, %.2f); recomputing…", rootPart.Position.X, rootPart.Position.Y, rootPart.Position.Z));
		path = computePath();
		path:ComputeAsync(rootPart.Position, dest);
	end);
	for _, waypoint in ipairs(path:GetWaypoints()) do
		if not autoFarmEnabled then
			blockedConn:Disconnect();
			SprintKeeper:stop();
			return false;
		end
		humanoid:MoveTo(waypoint.Position);
		if not humanoid.MoveToFinished:Wait(3) then
			warn(string.format("[walkPath] MoveTo timeout at waypoint (%.2f, %.2f, %.2f); retrying…", waypoint.Position.X, waypoint.Position.Y, waypoint.Position.Z));
			path = computePath();
			path:ComputeAsync(rootPart.Position, dest);
		end
	end
	blockedConn:Disconnect();
	SprintKeeper:stop();
	if doInteract then
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game);
		task.wait(0.15);
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game);
	end
	print("[walkPath] Arrived at destination");
	return true;
end
local function goToFallbackAndStartFarmer()
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait();
	local hum = char:WaitForChild("Humanoid");
	local hrp = char:WaitForChild("HumanoidRootPart");
	if not (hum and hrp) then
		return;
	end
	print("[goToFallback] Heading to fallback:", farmCfg.fallbackLocation);
	if not walkPath(hum, hrp, farmCfg.fallbackLocation, false) then
		warn("[goToFallback] couldn't reach fallback");
		return;
	end
	autoFarmEnabled = true;
	if not farmerCoroutine then
		farmerCoroutine = task.spawn(pizzaFarmer);
		print("[goToFallback] started pizzaFarmer");
	end
end
local function safePizzaInteract(maxAttempts)
	maxAttempts = maxAttempts or 5;
	for attempt = 1, maxAttempts do
		pressF();
		RunService.RenderStepped:Wait();
		local gui = localPlayer.PlayerGui:FindFirstChild("PizzaGUI");
		local frame = gui and gui:FindFirstChild("Frame");
		if not frame then
			task.wait(0.3);
			continue;
		end
		local acceptBtn = frame:FindFirstChild("AcceptButton");
		local declineBtn = frame:FindFirstChild("DeclineButton");
		if (acceptBtn and acceptBtn.Visible) then
			print(("[safePizzaInteract] clicking Accept on try %d"):format(attempt));
			forceClickPizzaAccept();
			goToFallbackAndStartFarmer();
			return true;
		elseif (declineBtn and declineBtn.Visible) then
			print(("[safePizzaInteract] Accept hidden; clicking Decline on try %d"):format(attempt));
			forceClickPizzaDecline();
			task.wait(0.3);
		else
			task.wait(0.3);
		end
	end
	warn(("[safePizzaInteract] gave up after %d attempts]"):format(maxAttempts));
	return false;
end
function pizzaFarmer()
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait();
	local hum = char:WaitForChild("Humanoid");
	local hrp = char:WaitForChild("HumanoidRootPart");
	if not (hum and hrp) then
		warn("[AutoFarm] Farmer could not find Humanoid or HumanoidRootPart.");
		return;
	end
	local target, tDist = nearestBeacon(hrp);
	local inFallbackMode = false;
	while autoFarmEnabled and task.wait(farmCfg.beaconScanInterval) do
		if (not char or not char.Parent) then
			char = localPlayer.Character or localPlayer.CharacterAdded:Wait();
			hum = char and char:FindFirstChild("Humanoid");
			hrp = char and char:FindFirstChild("HumanoidRootPart");
			if not (hum and hrp) then
				warn("[AutoFarm] Character lost during farming.");
				break;
			end
			target = nil;
			inFallbackMode = false;
		end
		local currentTarget = target;
		local newTarget, newDist = nearestBeacon(hrp);
		if (not currentTarget or not currentTarget.Parent or (newTarget and (newTarget ~= currentTarget) and (newDist < ((tDist or math.huge) - farmCfg.repathDistance)))) then
			target, tDist = newTarget, newDist;
			inFallbackMode = false;
		elseif target then
			tDist = (target.Position - hrp.Position).Magnitude;
		end
		if not target then
			if not inFallbackMode then
				print("[AutoFarm] No beacons found, going to fallback location sequence.");
				inFallbackMode = true;
				local distToFallback = (farmCfg.fallbackLocation - hrp.Position).Magnitude;
				if (distToFallback > 5) then
					print("[AutoFarm] Pathfinding to primary fallback:", farmCfg.fallbackLocation);
					local successPrimary = walkPath(hum, hrp, farmCfg.fallbackLocation, false);
					if (successPrimary and autoFarmEnabled) then
						print("[AutoFarm] Arrived at primary fallback. Pathfinding to secondary fallback:", farmCfg.secondaryFallbackLocation);
						local successSecondary = walkPath(hum, hrp, farmCfg.secondaryFallbackLocation, false);
						if (successSecondary and autoFarmEnabled) then
							print("[AutoFarm] Arrived at secondary fallback location. Pressing F and clicking Accept.");
							VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game);
							task.wait(0.1);
							VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game);
							local character = localPlayer.Character;
							local humanoid = character and character:FindFirstChildOfClass("Humanoid");
							if humanoid then
								humanoid:MoveTo(farmCfg.fallbackLocation);
							end
						elseif autoFarmEnabled then
							warn("[AutoFarm] Failed to reach secondary fallback location.");
						end
					elseif autoFarmEnabled then
						warn("[AutoFarm] Failed to reach primary fallback location.");
						inFallbackMode = false;
					end
				else
					print("[AutoFarm] Close to primary fallback. Pathfinding directly to secondary fallback:", farmCfg.secondaryFallbackLocation);
					local successSecondary = walkPath(hum, hrp, farmCfg.secondaryFallbackLocation, false);
					if (successSecondary and autoFarmEnabled) then
						print("[AutoFarm] Arrived at secondary fallback location from nearby. Pressing F and clicking Accept.");
						safePizzaInteract();
						task.wait(1);
						print("[AutoFarm] Fallback sequence complete, waiting for beacons.");
					elseif autoFarmEnabled then
						warn("[AutoFarm] Failed to reach secondary fallback location from nearby.");
					end
				end
			end
			continue;
		end
		inFallbackMode = false;
		local dest = getBeaconPosition(target);
		local specialRoute = nil;
		for _, routeData in ipairs(SpecialBeaconRoutes) do
			if ((dest - routeData.beacon).Magnitude < 0.5) then
				specialRoute = routeData;
				break;
			end
		end
		if specialRoute then
			if (specialRoute.type == "bridge") then
				print("[AutoFarm] Detected 'bridge' special beacon route. Executing pre-routing sequence.");
				local preRouteSuccess1 = walkPath(hum, hrp, specialRoute.manual, false);
				if not autoFarmEnabled then
					break;
				end
				if preRouteSuccess1 then
					print("[AutoFarm] Reached special manual point. Moving to second point.");
					hum:MoveTo(specialRoute.second);
					local arrived = hum.MoveToFinished:Wait(3);
					if not autoFarmEnabled then
						break;
					end
					if arrived then
						print("[AutoFarm] Reached second special point. Proceeding to beacon.");
					else
						warn("[AutoFarm] Timed out moving to second special point. Proceeding to beacon anyway.");
					end
				else
					warn("[AutoFarm] Failed to reach special manual point. Skipping pre-routing.");
				end
			end
		end
		print("[AutoFarm] Moving directly to beacon basepart at:", dest);
		local success = walkPath(hum, hrp, dest);
		if not autoFarmEnabled then
			break;
		end
		if success then
			print("[AutoFarm] Successfully reached and interacted with beacon.");
			target = nil;
			task.wait(farmCfg.pauseMin + (math.random() * (farmCfg.pauseMax - farmCfg.pauseMin)));
		else
			warn("[AutoFarm] Failed to reach beacon directly. Checking for manual fallback.");
			local manualPoint = getClosestManualPoint(dest);
			if manualPoint then
				print("[AutoFarm] Found close manual fallback point. Pathing to:", manualPoint);
				local fallbackSuccess = walkPath(hum, hrp, manualPoint, false);
				if not autoFarmEnabled then
					break;
				end
				if fallbackSuccess then
					print("[AutoFarm] Reached manual fallback point. Attempting interaction.");
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game);
					task.wait(0.15);
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game);
					task.wait(farmCfg.pauseMin + (math.random() * (farmCfg.pauseMax - farmCfg.pauseMin)));
				else
					warn("[AutoFarm] Failed to reach manual fallback point.");
				end
			else
				warn("[AutoFarm] No suitable manual fallback point found.");
			end
			target = nil;
		end
	end
	print("[AutoFarm] Loop ended.");
	clearOldPath();
	farmerCoroutine = nil;
end
autoFarmToggle = createToggleButton("Pizza Delivery", autoFarmEnabled, function(state)
	autoFarmEnabled = state;
	if not autoFarmEnabled then
		clearOldPath();
		if farmerCoroutine then
			task.cancel(farmerCoroutine);
			farmerCoroutine = nil;
			print("[AutoFarm] Disabled and stopped farmer coroutine.");
		end
	elseif not farmerCoroutine then
		print("[AutoFarm] Enabled, starting farmer coroutine.");
		farmerCoroutine = task.spawn(pizzaFarmer);
	end
end);
autoFarmToggle.LayoutOrder = 1;
autoFarmToggle.Parent = autoFarmTabContent;
weaponLabelsToggle = createToggleButton("Gun Labels", gunLabelsEnabled, function(state)
	gunLabelsEnabled = state;
	print("Gun Labels toggled:", gunLabelsEnabled);
	if not gunLabelsEnabled then
		for player, label in pairs(gunLabelsForPlayers) do
			if label then
				label:Destroy();
				gunLabelsForPlayers[player] = nil;
			end
		end
	else
		for _, player in ipairs(Players:GetPlayers()) do
			updateGunLabelForPlayer(player);
		end
	end
end);
weaponLabelsToggle.Size = UDim2.new(1, -20, 0, 35);
weaponLabelsToggle.Parent = playersControlsContainer;
weaponLabelsToggle.LayoutOrder = 2;
local forceRespawnButton = Instance.new("TextButton");
forceRespawnButton.Name = "ForceRespawnButton";
forceRespawnButton.Size = UDim2.new(1, -20, 0, 35);
forceRespawnButton.BackgroundColor3 = Config.Theme.danger;
forceRespawnButton.Text = "Force Respawn";
forceRespawnButton.TextColor3 = Config.Theme.text;
forceRespawnButton.Font = Config.Theme.bodyFont;
forceRespawnButton.TextSize = 14;
forceRespawnButton.LayoutOrder = 3;
forceRespawnButton.ZIndex = 12;
forceRespawnButton.Parent = settingsTabContent;
createCornerRadius(forceRespawnButton);
forceRespawnButton.MouseButton1Click:Connect(function()
	local char = Players.LocalPlayer.Character;
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid");
		if hum then
			hum.Health = 0;
		end
	end
end);
local isUpdatingPlayerList = false;
local function syncPlayerHighlightState(player)
	local hasActiveChams = false;
	if player.Character then
		for _, part in ipairs(player.Character:GetDescendants()) do
			if (part:IsA("BasePart") and part:FindFirstChild("ChamAdornment")) then
				hasActiveChams = true;
				break;
			end
		end
	end
	highlightToggledPlayers[player] = hasActiveChams;
	local playerItem = playerListContainer:FindFirstChild(player.Name .. "Item");
	if playerItem then
		local highlightButton = playerItem:FindFirstChild("HighlightButton");
		if highlightButton then
			highlightButton.BackgroundColor3 = (hasActiveChams and Config.Theme.success) or Config.Theme.button;
		end
	end
end
function updatePlayerList(searchFilter)
	if isUpdatingPlayerList then
		return;
	end
	isUpdatingPlayerList = true;
	searchFilter = searchFilter or "";
	searchFilter = string.lower(searchFilter);
	for _, player in ipairs(Players:GetPlayers()) do
		if (player ~= localPlayer) then
			syncPlayerHighlightState(player);
		end
	end
	local processedPlayers = {};
	for _, child in ipairs(playerListContainer:GetChildren()) do
		if (child:IsA("Frame") and string.match(child.Name, "Item$")) then
			local playerName = string.gsub(child.Name, "Item$", "");
			local player = Players:FindFirstChild(playerName);
			if (not player or processedPlayers[player]) then
				child:Destroy();
			else
				local matchesSearch = (searchFilter == "") or string.find(string.lower(player.Name), searchFilter);
				if matchesSearch then
					child.Visible = true;
					processedPlayers[player] = true;
					local highlightButton = child:FindFirstChild("HighlightButton");
					if highlightButton then
						highlightButton.BackgroundColor3 = (highlightToggledPlayers[player] and Config.Theme.success) or Config.Theme.button;
					end
					local infoLabel = child:FindFirstChild("InfoLabel");
					if infoLabel then
						local weapons = gunLabelsData[player] or "";
						infoLabel.Text = ((weapons ~= "") and weapons) or "No weapon";
					end
				else
					child.Visible = false;
				end
			end
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if ((player ~= localPlayer) and not processedPlayers[player]) then
			local matchesSearch = (searchFilter == "") or string.find(string.lower(player.Name), searchFilter);
			if matchesSearch then
				local playerItemName = player.Name .. "Item";
				local existing = playerListContainer:FindFirstChild(playerItemName);
				if existing then
					existing:Destroy();
				end
				local playerFrame = Instance.new("Frame");
				playerFrame.Name = playerItemName;
				playerFrame.Size = UDim2.new(1, -10, 0, 50);
				playerFrame.BackgroundColor3 = Config.Theme.card;
				playerFrame.BorderSizePixel = 0;
				playerFrame.ZIndex = 13;
				createCornerRadius(playerFrame);
				local playerIcon = Instance.new("ImageLabel");
				playerIcon.Name = "PlayerIcon";
				playerIcon.Size = UDim2.new(0, 40, 0, 40);
				playerIcon.Position = UDim2.new(0, 5, 0, 5);
				playerIcon.BackgroundColor3 = Config.Theme.tertiary;
				playerIcon.BorderSizePixel = 0;
				playerIcon.ZIndex = 14;
				pcall(function()
					playerIcon.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
				end);
				createCornerRadius(playerIcon);
				playerIcon.Parent = playerFrame;
				local nameLabel = Instance.new("TextLabel");
				nameLabel.Name = "PlayerName";
				nameLabel.Size = UDim2.new(0.5, 0, 0, 20);
				nameLabel.Position = UDim2.new(0, 55, 0, 5);
				nameLabel.BackgroundTransparency = 1;
				nameLabel.Text = player.Name;
				nameLabel.TextColor3 = Config.Theme.text;
				nameLabel.Font = Config.Theme.bodyFont;
				nameLabel.TextSize = 14;
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left;
				nameLabel.ZIndex = 14;
				nameLabel.Parent = playerFrame;
				local infoLabel = Instance.new("TextLabel");
				infoLabel.Name = "InfoLabel";
				infoLabel.Size = UDim2.new(0.5, 0, 0, 20);
				infoLabel.Position = UDim2.new(0, 55, 0, 25);
				infoLabel.BackgroundTransparency = 1;
				local weapons = gunLabelsData[player] or "";
				infoLabel.Text = ((weapons ~= "") and weapons) or "No weapon";
				infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200);
				infoLabel.Font = Config.Theme.bodyFont;
				infoLabel.TextSize = 12;
				infoLabel.TextXAlignment = Enum.TextXAlignment.Left;
				infoLabel.ZIndex = 14;
				infoLabel.Parent = playerFrame;
				local highlightButton = Instance.new("TextButton");
				highlightButton.Name = "HighlightButton";
				highlightButton.Size = UDim2.new(0, 60, 0, 30);
				highlightButton.Position = UDim2.new(1, -65, 0.5, -15);
				highlightButton.BackgroundColor3 = (highlightToggledPlayers[player] and Config.Theme.success) or Config.Theme.button;
				highlightButton.Text = "Track";
				highlightButton.TextColor3 = Config.Theme.text;
				highlightButton.Font = Config.Theme.bodyFont;
				highlightButton.TextSize = 12;
				highlightButton.ZIndex = 14;
				createCornerRadius(highlightButton);
				highlightButton.Parent = playerFrame;
				highlightButton.MouseButton1Click:Connect(function()
					if highlightToggledPlayers[player] then
						if player.Character then
							removeChamsFromCharacter(player.Character);
						end
						highlightToggledPlayers[player] = false;
						highlightButton.BackgroundColor3 = Config.Theme.button;
					else
						if player.Character then
							addChamsToCharacter(player.Character);
						end
						highlightToggledPlayers[player] = true;
						highlightButton.BackgroundColor3 = Config.Theme.success;
					end
				end);
				playerFrame.Parent = playerListContainer;
				processedPlayers[player] = true;
			end
		end
	end
	isUpdatingPlayerList = false;
end
local lastUpdateTime = 0;
local function debouncedUpdatePlayerList()
	local now = tick();
	if ((now - lastUpdateTime) < 0.5) then
		return;
	end
	lastUpdateTime = now;
	updatePlayerList();
end
updatePlayerList();
local lastClickTime = 0;
local lastDodgeTime = 0;
local weaponLabels = {};
local function getHumanoidRootPart(character)
	return character and character:FindFirstChild("HumanoidRootPart");
end
local function createOverlapParams()
	local params = OverlapParams.new();
	params.FilterType = Enum.RaycastFilterType.Blacklist;
	local char = localPlayer.Character;
	if char then
		params.FilterDescendantsInstances = {char};
	else
		params.FilterDescendantsInstances = {};
	end
	return params;
end
local function simulateKeyPress(keyCode, duration)
	VirtualInputManager:SendKeyEvent(true, keyCode, false, game);
	task.delay(duration, function()
		VirtualInputManager:SendKeyEvent(false, keyCode, false, game);
	end);
end
local function isReleaseAnimation(animationId)
	local attackAnimations = Config.Combat.DodgeAnimations;
	local shortAnimationId = string.match(animationId, "%d+$");
	for _, id in ipairs(attackAnimations) do
		if (animationId == id) then
			return true;
		end
	end
	for _, id in ipairs(attackAnimations) do
		local shortId = string.match(id, "%d+$");
		if (shortAnimationId == shortId) then
			return true;
		end
	end
	return false;
end
local function getPrimaryPart(instance)
	if (instance:IsA("Tool") and instance:IsA("BasePart")) then
		return instance;
	end
	if instance:IsA("Tool") then
		local handle = instance:FindFirstChild("Handle");
		if (handle and handle:IsA("BasePart")) then
			return handle;
		end
	end
	return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart");
end
local function calculateCustomDelay(baseDelay)
	local pingMs = localPlayer:GetNetworkPing() * 1000;
	local clampedPing = math.clamp(pingMs, 50, 300);
	local fraction = (clampedPing - 50) / 250;
	local minDelay = 0.01;
	local highPingCompensation = 0;
	if (pingMs > 150) then
		highPingCompensation = math.min(0.07, (pingMs - 150) / 1000);
	end
	return math.max(0, (baseDelay - ((baseDelay - minDelay) * fraction)) - highPingCompensation);
end
local function setupItemTracking()
	local function getItemBaseType(modelName)
		local baseName = modelName:gsub("_dropped$", "");
		return baseName;
	end
	for _, model in ipairs(workspace:GetChildren()) do
		local baseItemName = getItemBaseType(model.Name);
		if ((model:IsA("Model") or model:IsA("Tool")) and (Config.Items.MeleeTypes[baseItemName] or Config.Items.RangedTypes[baseItemName])) then
			local primaryPart = getPrimaryPart(model);
			if primaryPart then
				trackedItems[model] = {model=model,itemType=baseItemName,isDropped=(model.Name:match("_dropped$") ~= nil)};
			end
		end
	end
	workspace.ChildAdded:Connect(function(model)
		if not (model:IsA("Model") or model:IsA("Tool")) then
			return;
		end
		local baseItemName = getItemBaseType(model.Name);
		if (Config.Items.MeleeTypes[baseItemName] or Config.Items.RangedTypes[baseItemName]) then
			task.delay(0.1, function()
				if (model and model.Parent) then
					local primaryPart = getPrimaryPart(model);
					if primaryPart then
						trackedItems[model] = {model=model,itemType=baseItemName,isDropped=(model.Name:match("_dropped$") ~= nil)};
						if (Config.Items.RangedTypes[baseItemName] and weaponLabelsEnabled) then
							updateItemLabels();
						elseif (weaponLabelsEnabled and enabledItemTypes[baseItemName]) then
							updateItemLabels();
						end
					end
				end
			end);
		end
	end);
	workspace.ChildRemoved:Connect(function(model)
		if trackedItems[model] then
			trackedItems[model] = nil;
			if weaponLabelsEnabled then
				updateItemLabels();
			end
		end
	end);
end
local function findItems()
	local function getItemBaseType(modelName)
		local baseName = modelName:gsub("_dropped$", "");
		return baseName;
	end
	local items = {};
	local characterPos = getHumanoidRootPart(localPlayer.Character);
	if not characterPos then
		return items;
	end
	for model, itemInfo in pairs(trackedItems) do
		if model.Parent then
			local primaryPart = getPrimaryPart(model);
			if primaryPart then
				local isBlacklisted = false;
				local radius = Config.Items.BlacklistRadius or 1;
				for _, blackPos in ipairs(Config.Items.ItemBlacklist) do
					if ((primaryPart.Position - blackPos).Magnitude <= radius) then
						isBlacklisted = true;
						break;
					end
				end
				if isBlacklisted then
					continue;
				end
				local baseItemName = itemInfo.itemType;
				local isDropped = itemInfo.isDropped;
				if (enabledItemTypes[baseItemName] and (not isDropped or searchDroppedItemsEnabled)) then
					local distance = (primaryPart.Position - characterPos.Position).Magnitude;
					table.insert(items, {model=model,distance=distance,position=primaryPart.Position,itemType=baseItemName,isDropped=isDropped});
				end
			end
		else
			trackedItems[model] = nil;
		end
	end
	local itemsByType = {};
	for _, item in ipairs(items) do
		if not itemsByType[item.itemType] then
			itemsByType[item.itemType] = {};
		end
		table.insert(itemsByType[item.itemType], item);
	end
	local result = {};
	for itemType, typeItems in pairs(itemsByType) do
		table.sort(typeItems, function(a, b)
			return a.distance < b.distance;
		end);
		for i = 1, math.min(#typeItems, Config.Items.MaxItemsPerType) do
			table.insert(result, typeItems[i]);
		end
	end
	return result;
end
local function purchaseAllAndExit()
	local plr = Players.LocalPlayer;
	local function clickGuiObject(obj)
		local evt = obj:FindFirstChild("MouseButton1Click") or obj.MouseButton1Click;
		if (evt and pcall(cansignalreplicate, evt)) then
			replicatesignal(evt);
			return true;
		end
		return false;
	end
	local playerGui = plr:WaitForChild("PlayerGui");
	local shopGUI;
	local elapsed = 0;
	while elapsed < 5 do
		shopGUI = playerGui:FindFirstChild("ShopGUI");
		if shopGUI then
			break;
		end
		task.wait(0.1);
		elapsed = elapsed + 0.1;
	end
	if not shopGUI then
		warn("purchaseAllAndExit: ShopGUI never appeared. Aborting.");
		return;
	end
	local shopFrame = shopGUI:FindFirstChild("ShopFrame");
	if not shopFrame then
		warn("purchaseAllAndExit: ShopFrame missing. Aborting.");
		return;
	end
	local itemFrame = shopFrame:FindFirstChild("BuyFrame") and shopFrame.BuyFrame:FindFirstChild("ItemFrame");
	if not itemFrame then
		warn("purchaseAllAndExit: ItemFrame missing. Aborting.");
		return;
	end
	for _, btn in ipairs(itemFrame:GetChildren()) do
		if (btn.Name == "BuyObjTemplate") then
			clickGuiObject(btn);
		end
	end
	local checkoutBtn = shopFrame:FindFirstChild("CheckoutFrame") and shopFrame.CheckoutFrame:FindFirstChild("CheckoutButton");
	if clickGuiObject(checkoutBtn) then
		task.wait(0.3);
		local exitBtn = shopFrame:FindFirstChild("Exit");
		if exitBtn then
			clickGuiObject(exitBtn);
		end
	else
		warn("purchaseAllAndExit: CheckoutButton missing or unclickable.");
	end
end
local function itemFarmer()
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait();
	local hum = char:WaitForChild("Humanoid");
	local hrp = char:WaitForChild("HumanoidRootPart");
	if not (hum and hrp) then
		return;
	end
	while itemFarmEnabled do
		if (not char or not char.Parent) then
			char = localPlayer.Character or localPlayer.CharacterAdded:Wait();
			hum = char and char:FindFirstChild("Humanoid");
			hrp = char and char:FindFirstChild("HumanoidRootPart");
			if not (hum and hrp) then
				break;
			end
		end
		do
			local inv = Players.LocalPlayer:FindFirstChild("Inventory");
			if inv then
				local slotCount = 0;
				for i = 1, 13 do
					local slot = inv:FindFirstChild("Slot" .. i);
					if slot then
						for _, item in ipairs(slot:GetChildren()) do
							if item:IsA("Tool") then
								slotCount = slotCount + 1;
								break;
							end
						end
					end
				end
				if (slotCount >= 13) then
					local hrpPos = hrp.Position;
					local shopA = Vector3.new(745.52, 14.87, -617.38);
					local shopB = Vector3.new(212.24, 4.1, 270.4);
					local shopAApproach = Vector3.new(715.45, 13.48, -630.94);
					local shopBApproach = Vector3.new(212.57, 3.85, 289.88);
					local dest = (((hrpPos - shopA).Magnitude < (hrpPos - shopB).Magnitude) and shopA) or shopB;
					if (dest == shopB) then
						local tmp = Instance.new("Part");
						tmp.Size, tmp.CFrame = Vector3.new(1, 1, 1), CFrame.new(shopBApproach);
						tmp.Transparency, tmp.Anchored, tmp.CanCollide, tmp.CanQuery = 1, true, false, false;
						tmp.Parent = workspace;
						local ok = walkPathToItem(hum, hrp, tmp, false);
						tmp:Destroy();
						if not ok then
							continue;
						end
						hum:MoveTo(shopB);
						if hum.MoveToFinished:Wait(5) then
							pressF();
						else
							continue;
						end
					else
						local tmp = Instance.new("Part");
						tmp.Size, tmp.CFrame = Vector3.new(1, 1, 1), CFrame.new(shopAApproach);
						tmp.Transparency, tmp.Anchored, tmp.CanCollide, tmp.CanQuery = 1, true, false, false;
						tmp.Parent = workspace;
						local ok = walkPathToItem(hum, hrp, tmp, false);
						tmp:Destroy();
						if not ok then
							continue;
						end
						hum:MoveTo(shopA);
						if hum.MoveToFinished:Wait(5) then
							pressF();
						else
							continue;
						end
					end
					task.wait(0.3);
					purchaseAllAndExit();
					local backTo = ((dest == shopB) and shopBApproach) or shopAApproach;
					hum:MoveTo(backTo);
					hum.MoveToFinished:Wait(3);
					continue;
				end
			end
		end
		local allEnabledItems = findItems();
		if (#allEnabledItems == 0) then
			showNotification("No items to farm. Enable them in Item ESP tab.");
			task.wait(1);
			continue;
		end
		table.sort(allEnabledItems, function(a, b)
			return a.distance < b.distance;
		end);
		local pathSuccess = false;
		local attemptedItems = {};
		for i, targetItem in ipairs(allEnabledItems) do
			if attemptedItems[targetItem.model] then
				continue;
			end
			attemptedItems[targetItem.model] = true;
			local destPart = getPrimaryPart(targetItem.model);
			if not destPart then
				continue;
			end
			local destPos = destPart.Position;
			local blacklisted = false;
			for _, bp in ipairs(Config.Items.ItemBlacklist) do
				if ((destPos - bp).Magnitude <= Config.Items.BlacklistRadius) then
					blacklisted = true;
					break;
				end
			end
			if blacklisted then
				SprintKeeper:stop();
				continue;
			end
			local disappeared = false;
			local conn = destPart.AncestryChanged:Connect(function(_, parent)
				if not destPart.Parent then
					disappeared = true;
				end
			end);
			if ((hrp.Position - destPos).Magnitude > Config.AutoFarm.sprintThreshold) then
				SprintKeeper:start();
			else
				SprintKeeper:stop();
			end
			local success = walkPathToItem(hum, hrp, targetItem.model);
			conn:Disconnect();
			if not success then
				if disappeared then
					continue;
				end
				continue;
			end
			SprintKeeper:stop();
			pathSuccess = true;
			break;
		end
		if not pathSuccess then
			task.wait(1);
		end
	end
	clearOldPath();
	itemFarmerCoroutine = nil;
end
local itemFarmToggle = createToggleButton("Item Farm", itemFarmEnabled, function(state)
	itemFarmEnabled = state;
	if itemFarmEnabled then
		if not itemFarmerCoroutine then
			itemFarmerCoroutine = task.spawn(itemFarmer);
		end
	elseif itemFarmerCoroutine then
		task.cancel(itemFarmerCoroutine);
		itemFarmerCoroutine = nil;
		clearOldPath();
	end
end);
itemFarmToggle.LayoutOrder = 3;
itemFarmToggle.Parent = autoFarmTabContent;
function updateGunLabelForPlayer(player)
	local character = player.Character;
	if not character then
		return;
	end
	local head = character:FindFirstChild("Head") or getHumanoidRootPart(character);
	if not head then
		return;
	end
	local gunTools = {};
	local inventory = player:FindFirstChild("Inventory");
	if inventory then
		for i = 1, 13 do
			local slot = inventory:FindFirstChild("Slot" .. i);
			if slot then
				for _, tool in ipairs(slot:GetChildren()) do
					if (Config.Items.ValidGuns[tool.Name] and not table.find(gunTools, tool.Name)) then
						table.insert(gunTools, tool.Name);
					end
				end
			end
		end
	end
	for _, tool in ipairs(character:GetChildren()) do
		if (tool:IsA("Tool") and Config.Items.ValidGuns[tool.Name] and not table.find(gunTools, tool.Name)) then
			table.insert(gunTools, tool.Name);
		end
	end
	local backpack = player:FindFirstChild("Backpack");
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if (tool:IsA("Tool") and Config.Items.ValidGuns[tool.Name] and not table.find(gunTools, tool.Name)) then
				table.insert(gunTools, tool.Name);
			end
		end
	end
	local currentGuns = table.concat(gunTools, ", ");
	gunLabelsData[player] = currentGuns;
	local playerItem = playerListContainer:FindFirstChild(player.Name .. "Item");
	if playerItem then
		local infoLabel = playerItem:FindFirstChild("InfoLabel");
		if infoLabel then
			infoLabel.Text = ((currentGuns ~= "") and currentGuns) or "No weapon";
		end
	end
	if (not gunLabelsEnabled or (currentGuns == "")) then
		if gunLabelsForPlayers[player] then
			gunLabelsForPlayers[player]:Destroy();
			gunLabelsForPlayers[player] = nil;
		end
		return;
	end
	if not gunLabelsForPlayers[player] then
		local label = Instance.new("BillboardGui");
		label.Size = UDim2.new(0, 120, 0, 30);
		label.StudsOffset = Vector3.new(0, 3, 0);
		label.AlwaysOnTop = true;
		label.LightInfluence = 0;
		label.MaxDistance = math.huge;
		local textLabel = Instance.new("TextLabel");
		textLabel.Size = UDim2.new(1, 0, 1, 0);
		textLabel.BackgroundTransparency = 1;
		textLabel.TextColor3 = Config.Theme.text;
		textLabel.TextSize = 12;
		textLabel.Font = Config.Theme.bodyFont;
		textLabel.TextStrokeTransparency = 0.5;
		textLabel.TextStrokeColor3 = Color3.new(0, 0, 0);
		textLabel.Text = currentGuns;
		textLabel.Parent = label;
		label.Parent = head;
		gunLabelsForPlayers[player] = label;
	else
		local textLabel = gunLabelsForPlayers[player]:FindFirstChildWhichIsA("TextLabel");
		if textLabel then
			textLabel.Text = currentGuns;
		end
	end
end
local activeAttackTrack = nil;
local autoAttackRenderStepName = "AutoAttackHitboxCheck";
local function isAutoAttackAnimation(animationId)
	local animId = string.gsub(animationId, "rbxassetid://", "");
	for _, id in ipairs(Config.Combat.AutoAttackAnims) do
		if (animId == id) then
			return true;
		end
	end
	return false;
end
local function performAutoAttack()
	if not autoAttackEnabled then
		return;
	end
	local character = localPlayer.Character;
	if not character then
		return;
	end
	local hrp = getHumanoidRootPart(character);
	if not hrp then
		return;
	end
	if (not visualHitbox or not visualHitbox.Parent) then
		visualHitbox = Instance.new("Part");
		visualHitbox.Name = "HitboxVisualization";
		visualHitbox.Size = Vector3.new(2.5, 3, 2.5);
		visualHitbox.Anchored = true;
		visualHitbox.CanCollide = false;
		visualHitbox.Material = Enum.Material.Neon;
		visualHitbox.Color = Config.Theme.secondary;
		visualHitbox.Parent = workspace;
	end
	local forward = hrp.CFrame.LookVector;
	local hitboxCenter = hrp.Position + (forward * 1.5);
	local hitboxCFrame = CFrame.new(hitboxCenter, hitboxCenter + forward);
	visualHitbox.Size = Vector3.new(2.5, 3, 2.5);
	visualHitbox.CFrame = hitboxCFrame;
	visualHitbox.Transparency = 0.7;
	local now = tick();
	if ((now - lastClickTime) < 0.3) then
		return;
	end
	local params = createOverlapParams();
	local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, visualHitbox.Size, params);
	local enemyDetected = false;
	for _, part in ipairs(partsInBox) do
		local model = part:FindFirstAncestorOfClass("Model");
		if (model and (model ~= localPlayer.Character) and Players:GetPlayerFromCharacter(model)) then
			enemyDetected = true;
			break;
		end
	end
	if enemyDetected then
		local x, y = mouse.X, mouse.Y;
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1);
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1);
		lastClickTime = now;
	end
end
local function setupAutoAttackListener()
	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid", 5);
		if not humanoid then
			return;
		end
		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5);
		if not animator then
			return;
		end
		animator.AnimationPlayed:Connect(function(track)
			if not autoAttackEnabled then
				return;
			end
			if isAutoAttackAnimation(track.Animation.AnimationId) then
				activeAttackTrack = track;
				if (visualHitbox and visualHitbox.Parent) then
					visualHitbox.Transparency = 1;
				end
				game:GetService("RunService"):BindToRenderStep(autoAttackRenderStepName, Enum.RenderPriority.Character.Value, performAutoAttack);
				track.Stopped:Connect(function()
					if (activeAttackTrack == track) then
						if (visualHitbox and visualHitbox.Parent) then
							visualHitbox.Transparency = 1;
						end
						game:GetService("RunService"):UnbindFromRenderStep(autoAttackRenderStepName);
						activeAttackTrack = nil;
					end
				end);
			end
		end);
	end
	if localPlayer.Character then
		onCharacterAdded(localPlayer.Character);
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded);
end
setupAutoAttackListener();
local function updateAutoAttackState()
	if not autoAttackEnabled then
		if (visualHitbox and visualHitbox.Parent) then
			visualHitbox.Transparency = 1;
		end
		pcall(function()
			game:GetService("RunService"):UnbindFromRenderStep(autoAttackRenderStepName);
		end);
		activeAttackTrack = nil;
	else
		local character = localPlayer.Character;
		if not character then
			return;
		end
		local humanoid = character:FindFirstChild("Humanoid");
		if not humanoid then
			return;
		end
		for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
			if isAutoAttackAnimation(track.Animation.AnimationId) then
				activeAttackTrack = track;
				if (visualHitbox and visualHitbox.Parent) then
					visualHitbox.Transparency = 1;
				end
				game:GetService("RunService"):BindToRenderStep(autoAttackRenderStepName, Enum.RenderPriority.Character.Value, performAutoAttack);
				track.Stopped:Connect(function()
					if (activeAttackTrack == track) then
						if (visualHitbox and visualHitbox.Parent) then
							visualHitbox.Transparency = 1;
						end
						game:GetService("RunService"):UnbindFromRenderStep(autoAttackRenderStepName);
						activeAttackTrack = nil;
					end
				end);
				break;
			end
		end
	end
end
local function determineDodgeDirection(localHRP, enemyHRP)
	local ping = localPlayer:GetNetworkPing();
	local predictedEnemyPos = enemyHRP.Position + (enemyHRP.Velocity * ping);
	local direction = (localHRP.Position - predictedEnemyPos).Unit;
	local rightVec = localHRP.CFrame.RightVector;
	local dotRight = direction:Dot(rightVec);
	if (math.abs(dotRight) < 0.3) then
		return "Back";
	elseif (dotRight > 0) then
		return "Right";
	else
		return "Left";
	end
end
local function triggerDodge(dodgeDir, customDelay)
	local currentTime = tick();
	if ((currentTime - lastDodgeTime) < 0.3) then
		return;
	end
	lastDodgeTime = currentTime;
	if (dodgeDir == "Left") then
		simulateKeyPress(Enum.KeyCode.A, 0.05);
	elseif (dodgeDir == "Right") then
		simulateKeyPress(Enum.KeyCode.D, 0.05);
	elseif (dodgeDir == "Back") then
		simulateKeyPress(Enum.KeyCode.S, 0.05);
	end
	if (customDelay and (customDelay > 0)) then
		task.delay(customDelay, function()
			simulateKeyPress(Enum.KeyCode.LeftControl, 0.05);
		end);
	else
		simulateKeyPress(Enum.KeyCode.LeftControl, 0.05);
	end
end
local connections = {characterAdded={},animator={},inventory={},tools={}};
local function setupAnimation(character, player)
	if connections.animator[character] then
		connections.animator[character]:Disconnect();
	end
	local humanoid = character:WaitForChild("Humanoid", 5);
	if not humanoid then
		local childAddedConn;
		childAddedConn = character.ChildAdded:Connect(function(child)
			if child:IsA("Humanoid") then
				childAddedConn:Disconnect();
				setupAnimation(character, player);
			end
		end);
		return;
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5);
	if not animator then
		return;
	end
	connections.animator[character] = animator.AnimationPlayed:Connect(function(animationTrack)
		if not autoDodgeEnabled then
			return;
		end
		local anim = animationTrack.Animation;
		if (anim and isReleaseAnimation(anim.AnimationId)) then
			local enemyHRP = getHumanoidRootPart(character);
			local localHRP = getHumanoidRootPart(localPlayer.Character);
			if (enemyHRP and localHRP) then
				local ping = localPlayer:GetNetworkPing();
				local predictedEnemyPos = enemyHRP.Position + (enemyHRP.Velocity * ping);
				local distance = (predictedEnemyPos - localHRP.Position).Magnitude;
				if (distance <= 15) then
					local dodgeDir = determineDodgeDirection(localHRP, enemyHRP);
					local baseDelay = Config.Combat.DodgeDelays[anim.AnimationId] or 0;
					local customDelay = calculateCustomDelay(baseDelay);
					triggerDodge(dodgeDir, customDelay);
				end
			end
		end
	end);
end
local function spoofMoveDirection(humanoid, rootPart)
	local mt = getrawmetatable(humanoid);
	setreadonly(mt, false);
	local oldIndex = mt.__index;
	mt.__index = function(self, key)
		if ((self == humanoid) and (key == "MoveDirection")) then
			local look = rootPart.CFrame.LookVector;
			return Vector3.new(look.X, 0, look.Z).Unit;
		end
		return oldIndex(self, key);
	end;
	mt.__moveDirPatched = true;
	setreadonly(mt, true);
	print(("[+] MoveDirection spoofed for %s"):format(humanoid.Parent.Name));
end
local function monitorEnemy(player)
	if connections.characterAdded[player] then
		return;
	end
	if player.Character then
		setupAnimation(player.Character, player);
	end
	connections.characterAdded[player] = player.CharacterAdded:Connect(function(character)
		setupAnimation(character, player);
	end);
end
local function handleCharacterAdded(player, character)
	if not character then
		return;
	end
	local hrp = character:WaitForChild("HumanoidRootPart", 5);
	if not hrp then
		return;
	end
	if highlightToggledPlayers[player] then
		addChamsToCharacter(character);
	end
	if (player == localPlayer) then
		task.defer(function()
			local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5);
			local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5);
			if (hum and hrp) then
				spoofMoveDirection(hum, hrp);
			end
		end);
		return;
	end
	local shouldTrack = trackAllEnabled or highlightToggledPlayers[player];
	if shouldTrack then
		addChamsToCharacter(character);
		highlightToggledPlayers[player] = true;
		local playerItem = playerListContainer:FindFirstChild(player.Name .. "Item");
		if playerItem then
			local highlightButton = playerItem:FindFirstChild("HighlightButton");
			if highlightButton then
				highlightButton.BackgroundColor3 = Config.Theme.success;
			end
		end
	end
	character.ChildAdded:Connect(function(child)
		if (child:IsA("Tool") and Config.Items.ValidGuns[child.Name]) then
			task.delay(0.1, function()
				updateGunLabelForPlayer(player);
				debouncedUpdatePlayerList();
			end);
		end
	end);
	character.ChildRemoved:Connect(function(child)
		if (child:IsA("Tool") and Config.Items.ValidGuns[child.Name]) then
			task.delay(0.1, function()
				updateGunLabelForPlayer(player);
				debouncedUpdatePlayerList();
			end);
		end
	end);
	if autoDodgeEnabled then
		setupAnimation(character, player);
	end
	task.delay(0.5, function()
		if trackAllEnabled then
			updatePlayerHighlight(player);
		end
		debouncedUpdatePlayerList();
	end);
	debouncedUpdatePlayerList();
end
if localPlayer.Character then
	handleCharacterAdded(localPlayer, localPlayer.Character);
end
localPlayer.CharacterAdded:Connect(function(character)
	handleCharacterAdded(localPlayer, character);
	if autoFarmEnabled then
		print("[AutoFarm] Detected respawn, resetting farmer…");
		if farmerCoroutine then
			task.cancel(farmerCoroutine);
			farmerCoroutine = nil;
		end
		clearOldPath();
		goToFallbackAndStartFarmer();
	end
end);
function updateItemLabels()
	for _, label in pairs(weaponLabels) do
		label:Destroy();
	end
	weaponLabels = {};
	local anyItemsEnabled = false;
	for _, enabled in pairs(enabledItemTypes) do
		if enabled then
			anyItemsEnabled = true;
			break;
		end
	end
	if (not anyItemsEnabled or not weaponLabelsEnabled) then
		return;
	end
	local items = findItems();
	for _, item in ipairs(items) do
		local primaryPart = getPrimaryPart(item.model);
		if primaryPart then
			local label = (function()
				local billboardGui = Instance.new("BillboardGui");
				billboardGui.Size = UDim2.new(0, 100, 0, 40);
				billboardGui.StudsOffset = Vector3.new(0, 2, 0);
				billboardGui.AlwaysOnTop = true;
				billboardGui.LightInfluence = 0;
				billboardGui.MaxDistance = math.huge;
				billboardGui.SizeOffset = Vector2.new(0, 0.5);
				local textLabel = Instance.new("TextLabel");
				textLabel.Size = UDim2.new(1, 0, 1, 0);
				textLabel.BackgroundTransparency = 1;
				if Config.Items.RangedTypes[item.itemType] then
					if item.isDropped then
						textLabel.TextColor3 = Config.Theme.warning;
					else
						textLabel.TextColor3 = Config.Theme.danger;
					end
				elseif item.isDropped then
					textLabel.TextColor3 = Config.Theme.success;
				else
					textLabel.TextColor3 = Color3.new(1, 1, 0);
				end
				textLabel.TextSize = 12;
				textLabel.Font = Enum.Font.GothamBold;
				textLabel.TextStrokeTransparency = 0.5;
				textLabel.TextStrokeColor3 = Color3.new(0, 0, 0);
				textLabel.Text = "";
				textLabel.Parent = billboardGui;
				return billboardGui;
			end)();
			label.Adornee = primaryPart;
			local textLabel = label:FindFirstChildWhichIsA("TextLabel");
			if textLabel then
				local labelText = item.itemType;
				if showItemDistance then
					textLabel.Text = string.format("%s\n%.1f m", labelText, item.distance);
				else
					textLabel.Text = labelText;
				end
			end
			label.Parent = workspace;
			table.insert(weaponLabels, label);
			if (Config.Items.RangedTypes[item.itemType] and not item.isDropped) then
				if not notifiedRangedItems[item.model] then
					notifiedRangedItems[item.model] = true;
					showNotification(string.format("%s has spawned!", item.itemType));
				end
			end
		end
	end
	for model, _ in pairs(notifiedRangedItems) do
		if not model.Parent then
			notifiedRangedItems[model] = nil;
		end
	end
end
local lastLabelUpdate = 0;
RunService.Heartbeat:Connect(function()
	local now = tick();
	if (weaponLabelsEnabled and ((now - lastLabelUpdate) >= Config.Items.RefreshItemsInterval)) then
		updateItemLabels();
		lastLabelUpdate = now;
	end
end);
setupItemTracking();
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return;
	end
	if (input.KeyCode == Enum.KeyCode[Config.Hotkeys.Aimbot]) then
		aimbotEnabled = not aimbotEnabled;
		print("Aimbot toggled via hotkey:", aimbotEnabled);
		local bg = (aimbotEnabled and Config.Theme.success) or Config.Theme.danger;
		aimbotToggle.BackgroundColor3 = bg;
		local dot = aimbotToggle:FindFirstChild("StatusIndicator");
		if dot then
			dot.BackgroundColor3 = bg;
		end
	end
end);
for _, player in ipairs(Players:GetPlayers()) do
	if (player ~= localPlayer) then
		monitorEnemy(player);
	end
end
local function watchInventory(player)
	if player:FindFirstChild("Inventory") then
		player.Inventory.DescendantAdded:Connect(function(item)
			if Config.Items.ValidGuns[item.Name] then
				task.delay(0.1, function()
					updateGunLabelForPlayer(player);
					debouncedUpdatePlayerList();
				end);
			end
		end);
		player.Inventory.DescendantRemoving:Connect(function(item)
			if Config.Items.ValidGuns[item.Name] then
				task.delay(0.1, function()
					updateGunLabelForPlayer(player);
					debouncedUpdatePlayerList();
				end);
			end
		end);
	end
	player.ChildAdded:Connect(function(child)
		if (child.Name == "Inventory") then
			child.DescendantAdded:Connect(function(item)
				if Config.Items.ValidGuns[item.Name] then
					task.delay(0.1, function()
						updateGunLabelForPlayer(player);
						debouncedUpdatePlayerList();
					end);
				end
			end);
			child.DescendantRemoving:Connect(function(item)
				if Config.Items.ValidGuns[item.Name] then
					task.delay(0.1, function()
						updateGunLabelForPlayer(player);
						debouncedUpdatePlayerList();
					end);
				end
			end);
		end
	end);
	local backpack = player:FindFirstChild("Backpack");
	if backpack then
		backpack.ChildAdded:Connect(function(child)
			if Config.Items.ValidGuns[child.Name] then
				task.delay(0.1, function()
					updateGunLabelForPlayer(player);
					debouncedUpdatePlayerList();
				end);
			end
		end);
		backpack.ChildRemoved:Connect(function(child)
			if Config.Items.ValidGuns[child.Name] then
				task.delay(0.1, function()
					updateGunLabelForPlayer(player);
					debouncedUpdatePlayerList();
				end);
			end
		end);
	end
	if not backpack then
		player.ChildAdded:Connect(function(child)
			if (child.Name == "Backpack") then
				child.ChildAdded:Connect(function(item)
					if Config.Items.ValidGuns[item.Name] then
						task.delay(0.1, function()
							updateGunLabelForPlayer(player);
							debouncedUpdatePlayerList();
						end);
					end
				end);
				child.ChildRemoved:Connect(function(item)
					if Config.Items.ValidGuns[item.Name] then
						task.delay(0.1, function()
							updateGunLabelForPlayer(player);
							debouncedUpdatePlayerList();
						end);
					end
				end);
			end
		end);
	end
end
mouse.Button2Down:Connect(function()
	if not aimbotEnabled then
		return;
	end
	holdingAim = true;
	local bestDist, bestHead = math.huge, nil;
	for _, other in ipairs(Players:GetPlayers()) do
		if ((other ~= localPlayer) and other.Character) then
			local head = other.Character:FindFirstChild("Head");
			if head then
				local screenPos, onScreen = camera:WorldToViewportPoint(head.Position);
				if onScreen then
					local d = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude;
					if (d < bestDist) then
						bestDist, bestHead = d, head;
					end
				end
			end
		end
	end
	lockedTarget = bestHead;
end);
mouse.Button2Up:Connect(function()
	holdingAim = false;
	lockedTarget = nil;
end);
Players.PlayerAdded:Connect(function(player)
	task.delay(0.2, function()
		highlightToggledPlayers[player] = false;
		debouncedUpdatePlayerList();
	end);
	if ((player ~= localPlayer) and autoDodgeEnabled) then
		monitorEnemy(player);
	end
	task.delay(0.2, function()
		updateGunLabelForPlayer(player);
	end);
	player.CharacterAdded:Connect(function(character)
		handleCharacterAdded(player, character);
	end);
	player.CharacterRemoving:Connect(function(character)
		local hadCham = false;
		for _, part in ipairs(character:GetDescendants()) do
			if (part:IsA("BasePart") and part:FindFirstChild("ChamAdornment")) then
				hadCham = true;
				break;
			end
		end
		highlightToggledPlayers[player] = hadCham;
	end);
	watchInventory(player);
end);
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		removeChamsFromCharacter(player.Character);
	end
	highlightToggledPlayers[player] = nil;
	task.delay(0.2, debouncedUpdatePlayerList);
end);
for _, player in ipairs(Players:GetPlayers()) do
	if (player ~= localPlayer) then
		monitorEnemy(player);
		watchInventory(player);
		player.CharacterRemoving:Connect(function(character)
			if character:FindFirstChild("PlayerHighlight") then
				highlightToggledPlayers[player] = true;
			end
		end);
		player.CharacterAdded:Connect(function(character)
			handleCharacterAdded(player, character);
		end);
		if player.Character then
			handleCharacterAdded(player, player.Character);
		end
	end
end
task.spawn(function()
	task.wait(1);
	for _, player in ipairs(Players:GetPlayers()) do
		if ((player ~= localPlayer) and player.Character) then
			local hasChams = false;
			for _, part in ipairs(player.Character:GetDescendants()) do
				if (part:IsA("BasePart") and part:FindFirstChild("ChamAdornment")) then
					hasChams = true;
					break;
				end
			end
			highlightToggledPlayers[player] = hasChams;
		end
	end
	updatePlayerList();
	for _, player in ipairs(Players:GetPlayers()) do
		updateGunLabelForPlayer(player);
	end
end);
