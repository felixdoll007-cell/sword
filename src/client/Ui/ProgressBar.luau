--!strict
-- Building block: the progress bar. Wide, round ends, black border, the filled part in blue with
-- the stud texture on a light grey ground. Text lies on the bar: the count on the left, the
-- status on the right.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ui = require(ReplicatedStorage.Shared.Config.Ui)

local Draw = require(script.Parent.Draw)
local OutlinedText = require(script.Parent.OutlinedText)

export type ProgressBar = {
	-- The whole bar. Give it a size and a position like any other element.
	frame: Frame,
	-- progress: 0 to 1. The texts are shown as they are.
	set: (progress: number, leftText: string, rightText: string) -> (),
}

local ProgressBar = {}

function ProgressBar.new(name: string, parent: Instance?): ProgressBar
	local settings = Ui.progressBar
	local corner = Ui.corners.bar

	local frame = Draw.box(name, nil)
	local back = Draw.panel("Back", Ui.colors.progressBack, frame)
	Draw.corner(back, corner)
	Draw.border(back)

	-- The filled part is a full-width bar seen through a window that is as wide as the progress.
	-- So its left end stays round and its right end is cut straight.
	local window = Draw.box("FillWindow", frame)
	window.ClipsDescendants = true
	window.Size = UDim2.fromScale(0, 1)
	local fill = Draw.panel("Fill", Ui.colors.progress, window)
	Draw.corner(fill, corner)
	Draw.studs(fill, Ui.colors.progress, corner)

	local function makeText(textName: string, alignX: Enum.TextXAlignment): OutlinedText.OutlinedText
		local text = OutlinedText.new({ name = textName, parent = frame, alignX = alignX })
		text.frame.AnchorPoint = Vector2.new(0.5, 0.5)
		text.frame.Position = UDim2.fromScale(0.5, 0.5)
		text.frame.Size = UDim2.fromScale(1 - 2 * settings.textInset, settings.textHeight)
		text.frame.ZIndex = 3
		return text
	end
	local left = makeText("Left", Enum.TextXAlignment.Left)
	local right = makeText("Right", Enum.TextXAlignment.Right)

	frame.Parent = parent
	return {
		frame = frame,
		set = function(progress: number, leftText: string, rightText: string)
			local share = if progress == progress then math.clamp(progress, 0, 1) else 0
			window.Size = UDim2.fromScale(share, 1)
			window.Visible = share > 0
			if share > 0 then
				-- Keep the bar inside the window as wide as the whole bar.
				fill.Size = UDim2.fromScale(1 / share, 1)
			end
			left.setText(leftText)
			right.setText(rightText)
		end,
	}
end

return ProgressBar
