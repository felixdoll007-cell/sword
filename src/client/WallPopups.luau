--!strict
-- "+..." labels during a throw: currency of each broken wall, and a bigger one for the zone bonus.
-- Only on this client.
--
-- A label appears where the sword breaks the wall and then travels along above the sword while it
-- rises and fades. (Fixed to the wall it would be gone at once: the camera follows the sword and
-- flies past the wall within a fraction of a second.)
-- The number of labels at the same time is capped; above the cap, amounts are added into
-- the newest label of the same kind instead of opening a new one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local Ui = require(Shared.Config.Ui)
local NumberFormat = require(Shared.Rules.NumberFormat)

local FOLDER_NAME = "MyWallPopups"

type Popup = {
	anchor: Part,
	label: TextLabel,
	amount: number,
	isZoneBonus: boolean,
	-- Height above the sword.
	height: number,
}

local WallPopups = {}

local active: { Popup } = {}

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function getFolder(): Folder
	local folder = Workspace:FindFirstChild(FOLDER_NAME) :: Folder?
	if folder then
		return folder
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = FOLDER_NAME
	newFolder.Parent = Workspace
	return newFolder
end

local function textFor(amount: number): string
	return "+" .. NumberFormat.abbreviate(NumberFormatConfig, amount)
end

local function remove(popup: Popup)
	local index = table.find(active, popup)
	if index then
		table.remove(active, index)
	end
	popup.anchor:Destroy()
end

local function newestOfKind(isZoneBonus: boolean): Popup?
	for i = #active, 1, -1 do
		if active[i].isZoneBonus == isZoneBonus then
			return active[i]
		end
	end
	return active[#active]
end

-- swordTip: where the sword is right now, i.e. at the wall it just broke.
function WallPopups.show(swordTip: Vector3, amount: number, isZoneBonus: boolean)
	if not (amount > 0) then
		return
	end
	local settings = Ui.wallPopup

	-- Too many on screen: add into an existing label instead.
	if #active >= settings.maxActive then
		local target = newestOfKind(isZoneBonus)
		if target then
			target.amount += amount
			target.label.Text = textFor(target.amount)
			return
		end
	end

	local height = settings.heightAboveSword + (if isZoneBonus then settings.zoneExtraHeight else 0)

	-- An invisible point in the world that the label hangs on.
	local anchor = Instance.new("Part")
	anchor.Name = "PopupAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.1
	anchor.Position = swordTip + Vector3.new(0, height, 0)

	local sizeFactor = if isZoneBonus then settings.zoneSizeFactor else 1
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(settings.widthStuds * sizeFactor, settings.heightStuds * sizeFactor)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Adornee = anchor
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color(if isZoneBonus then settings.zoneColor else settings.color)
	label.TextStrokeTransparency = 0
	label.Text = textFor(amount)
	label.Parent = gui

	anchor.Parent = getFolder()
	local popup: Popup = { anchor = anchor, label = label, amount = amount, isZoneBonus = isZoneBonus, height = height }
	table.insert(active, popup)

	local info = TweenInfo.new(settings.seconds)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = Vector3.new(0, settings.riseStuds, 0) }):Play()
	local fade = TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 })
	fade.Completed:Connect(function()
		remove(popup)
	end)
	fade:Play()
end

-- Called every frame during the throw: the labels travel along above the sword.
function WallPopups.follow(swordTip: Vector3)
	for _, popup in active do
		popup.anchor.Position = swordTip + Vector3.new(0, popup.height, 0)
	end
end

return WallPopups
