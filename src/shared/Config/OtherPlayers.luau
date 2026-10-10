--!strict
-- Seeing the throws of other players. Kept cheap on purpose, so weak phones stay smooth.
-- Lengths in studs.

return {
	-- Server: only players within this distance of the thrower are told about a throw.
	visibleDistance = 150,

	-- Client: at most this many throws of other players are drawn at the same time.
	-- Further ones are simply not shown.
	maxShownAtOnce = 6,

	-- Main throw of another player: the sword flies this far from the thrower while fading out,
	-- then it is gone. Must be shorter than the distance to the first wall, so it never touches one.
	mainThrowFadeDistance = 20,
	mainThrowSeconds = 0.5,
}
