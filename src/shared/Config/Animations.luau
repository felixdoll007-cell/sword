--!strict
-- The throw animations of the character. All times in seconds.
--
-- The animations are real Roblox animations, uploaded to the account that owns the game.
-- Roblox then shows them to all players by itself. Their first version is built from
-- tools/animations/build_throw_animations.luau and can be reworked in Studio's animation editor
-- (see docs/ANIMATIONS.md).

return {
	-- The throw in the throw zone.
	mainThrow = {
		-- Number Roblox shows after uploading the animation. 0 = not uploaded yet: in Studio the
		-- animation from the editor is used for the own character, everywhere else the simple
		-- arm swing from code.
		assetId = 0,
		-- Name of the animation at the animation rig in the place (ReplicatedStorage.Assets).
		name = "ThrowMain",
		-- The moment the weapon leaves the hand, counted from the start of the animation.
		-- Must match the marker "Release" in the animation. Until then the camera stays with the
		-- character; the server adds this time to the flight plan and the throw lock.
		releaseSeconds = 0.55,
	},

	-- The shorter throw on a training lane. Must fit between two training throws.
	trainingThrow = {
		assetId = 0,
		name = "ThrowTraining",
		releaseSeconds = 0.25,
	},

	-- How quickly an animation blends in and out.
	fadeSeconds = 0.08,

	-- Where the animations and their rig lie in the place, for the editor and for the preview in Studio.
	rigFolder = "Assets",
	rigName = "ThrowAnimationRig",
	savesName = "AnimSaves",
	-- Name of the marker in the animations for the moment of release.
	releaseMarker = "Release",
}
