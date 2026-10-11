--!strict
-- The pets that follow a player: every equipped pet floats behind its player, side by side,
-- bobbing a little and looking where the player looks. Without collision.
-- Drawn and moved on this client, for every player near the camera. The server only publishes
-- who owns and has equipped which pets (attributes on the Player), so every client shows the
-- same pets, and nothing has to be sent while they move.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local Ui = require(Shared.Config.Ui)
local Pets = require(Shared.Rules.Pets)

local PetPreview = require(script.Parent.Ui.PetPreview)

local FOLDER_NAME = "MyPetFollowers"
local ROOT_NAME = "HumanoidRootPart"

type Follower = {
	uid: number,
	model: Model,
	-- Where the pet is right now. nil until it is placed for the first time.
	frame: CFrame?,
	-- Its own point in the bobbing, so pets do not bob in step.
	phase: number,
}

type State = {
	followers: { Follower },
	-- The equipped pets changed and the followers have to be made anew.
	stale: boolean,
	connections: { RBXScriptConnection },
}

local PetFollowView = {}

local states: { [Player]: State } = {}
local folder: Folder

-- The equipped pets of a player, in the order they were equipped: uid and kind.
local function equippedPets(player: Player): { Pets.OwnedPet }
	local owned = Pets.decodeOwned(player:GetAttribute(Remotes.Attributes.Pets))
	local list = {}
	for _, uid in Pets.decodeEquipped(player:GetAttribute(Remotes.Attributes.EquippedPets)) do
		for _, pet in owned do
			if pet.uid == uid then
				table.insert(list, pet)
				break
			end
		end
	end
	return list
end

local function clear(state: State)
	for _, follower in state.followers do
		follower.model:Destroy()
	end
	state.followers = {}
end

-- Makes the followers match the equipped pets. Pets that stay keep their place in the air.
local function rebuild(player: Player, state: State)
	local wanted = equippedPets(player)
	local kept: { [number]: Follower } = {}
	for _, follower in state.followers do
		kept[follower.uid] = follower
	end
	local followers = {}
	for index, pet in wanted do
		local follower = kept[pet.uid]
		if follower then
			kept[pet.uid] = nil
		else
			local model = PetPreview.petModel(pet.id)
			model.Name = `{player.Name}Pet{pet.uid}`
			follower = { uid = pet.uid, model = model, frame = nil, phase = index / (#wanted + 1) }
		end
		table.insert(followers, follower)
	end
	for _, follower in kept do
		follower.model:Destroy()
	end
	state.followers = followers
	state.stale = false
end

local function update(player: Player, state: State, deltaTime: number, time: number, cameraPosition: Vector3)
	local settings = Ui.world.petFollow
	local character = player.Character
	local root = character and character:FindFirstChild(ROOT_NAME)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local shown = root ~= nil
		and root:IsA("BasePart")
		and humanoid ~= nil
		and humanoid.Health > 0
		and (root.Position - cameraPosition).Magnitude <= settings.maxDistance
	if not shown or not root or not root:IsA("BasePart") then
		-- No character, dead, or too far away: no pets in the world.
		for _, follower in state.followers do
			follower.model.Parent = nil
			follower.frame = nil
		end
		return
	end
	if state.stale then
		rebuild(player, state)
	end

	-- The player's direction, flat on the ground.
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	local right = look:Cross(Vector3.yAxis)
	local count = #state.followers
	local blend = 1 - math.exp(-settings.followSpeed * deltaTime)

	for index, follower in state.followers do
		-- Its place: behind the player, side by side with the others.
		local sideways = (index - (count + 1) / 2) * settings.spacing
		local place = root.Position - look * settings.behind + right * sideways + Vector3.new(0, settings.height, 0)
		local target = CFrame.lookAt(place, place + look)

		local frame = follower.frame
		if not frame or (frame.Position - place).Magnitude > settings.jumpDistance then
			frame = target
		else
			frame = frame:Lerp(target, blend)
		end
		follower.frame = frame

		local bob = math.sin((time / settings.bobSeconds + follower.phase) * 2 * math.pi) * settings.bobHeight
		follower.model:PivotTo(frame + Vector3.new(0, bob, 0))
		if follower.model.Parent ~= folder then
			follower.model.Parent = folder
		end
	end
end

local function onPlayerAdded(player: Player)
	local state: State = { followers = {}, stale = true, connections = {} }
	states[player] = state
	local function markStale()
		state.stale = true
	end
	for _, attribute in { Remotes.Attributes.Pets, Remotes.Attributes.EquippedPets } do
		table.insert(state.connections, player:GetAttributeChangedSignal(attribute):Connect(markStale))
	end
end

local function onPlayerRemoving(player: Player)
	local state = states[player]
	if not state then
		return
	end
	for _, connection in state.connections do
		connection:Disconnect()
	end
	clear(state)
	states[player] = nil
end

function PetFollowView.start()
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	RunService.Heartbeat:Connect(function(deltaTime: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local time = os.clock()
		local cameraPosition = camera.CFrame.Position
		for player, state in states do
			update(player, state, deltaTime, time, cameraPosition)
		end
	end)
end

return PetFollowView
