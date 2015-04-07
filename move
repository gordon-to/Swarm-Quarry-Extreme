--[[ move
An advanced turtle API, with position tracking and navigational functions.

Written by apemanzilla
]]

assert(turtle, "for turtles only")

local compass
if peripheral.getType("right") == "compass" then
	compass = peripheral.wrap("right")
elseif peripheral.getType("left") == "compass" then
	compass = peripheral.wrap("left")
end
if compass and not compass.getFacing then
	compass = nil
end

local pos = {}

local df = {
	[0] = {		-- South
		dx = 0,
		dz = 1
	},
	[1] = {		-- West
		dx = -1,
		dz = 0
	},
	[2] = {		-- North
		dx = 0,
		dz = -1
	},
	[3] = {		-- East
		dx = 1,
		dz = 0
	}
}

--[[ Utility and positioning functions ]]

local function dirToFacing(dir)
	if dir == "north" then
		return 2
	elseif dir == "south" then
		return 0
	elseif dir == "east" then
		return 3
	elseif dir == "west" then
		return 1
	end
end

function savePos()
	local f = fs.open(".position","w")
	f.write(textutils.serialize(pos))
	f.close()
end

function updateFacing()
	if compass then
		pos.f = dirToFacing(compass.getFacing())
		savePos()
		return true
	else
		local x,y,z = gps.locate(0.1)
		if not (x and y and z) then
			return false, "cannot determine position"
		end
		if turtle.forward() then
			local newx, newy, newz = gps.locate(0.1)
			if not (newx and newy and newz) then
				return false, "cannot determine position"
			else
				if newx > x then
					pos.f = 3
				elseif newx < x then
					pos.f = 1
				elseif newz > z then
					pos.f = 0
				else
					pos.f = 2
				end
			end
			if not turtle.back() then
				pos.x, pos.y, pos.z = newx, newy, newz
			end
			savePos()
			return true
		elseif turtle.back() then
			local newx, newy, newz = gps.locate(0.1)
			if not (newx and newy and newz) then
				return false, "cannot determine position"
			else
				if newx < x then
					pos.f = 3
				elseif newx > x then
					pos.f = 1
				elseif newz < z then
					pos.f = 0
				else
					pos.f = 2
				end
			end
			if not turtle.forward() then
				pos.x, pos.y, pos.z = newx, newy, newz
			end
			savePos()
			return true
		else
			return false, "cannot determine facing"
		end
	end
end

function updatePos()
	local x, y, z = gps.locate(0.1)
	if x and y and z then
		pos.x = x
		pos.y = y
		pos.z = z
	else
		return false, "cannot determine position"
	end
	return updateFacing()
end

function getPos()
	return pos
end

function setPos(x,y,z,f)
	assert(x and y and z and f,"expected number, number, number, number")
	pos.x = x
	pos.y = y
	pos.z = z
	pos.f = f
end

local function loadPos()
	if fs.exists(".position") then
		local f = fs.open(".position","r")
		local temppos = textutils.unserialize(f.readAll())
		f.close()
		local x, y, z = gps.locate(0.1)
		if x and y and z then
			pos.x = x
			pos.y = y
			pos.z = z
		else
			pos = temppos
		end
		if compass then 
			pos.f = dirToFacing(compass.getFacing())
		else
			if temppos.x == pos.x and temppos.y == pos.y and temppos.z == pos.z then
				pos.f = temppos.f
			else
				updateFacing()
			end
		end
		savePos()
	else
		updatePos()
	end
end

loadPos()

-- Local copy of turtle functions in case they are overridden later
local turtle = {}
for k,v in pairs(_G.turtle) do
	turtle[k] = v
end
-- turtle.forward = _G.turtle.forward
-- turtle.back = _G.turtle.back
-- turtle.up = _G.turtle.up
-- turtle.down = _G.turtle.down
-- turtle.turnRight = _G.turtle.turnRight
-- turtle.turnLeft = _G.turtle.turnLeft

--[[ Basic Movement Functions ]]

function forward()
	local success, err = turtle.forward()
	if success then
		if pos.x and pos.z and pos.f then
			pos.x = pos.x + df[pos.f].dx
			pos.z = pos.z + df[pos.f].dz
		end
		savePos()
		return true
	else
		return false, err
	end
end

function back()
	local success, err = turtle.back()
	if success then
		if pos.x and pos.z and pos.f then
			pos.x = pos.x - df[pos.f].dx
			pos.z = pos.z - df[pos.f].dz
		end
		savePos()
		return true
	else
		return false, err
	end
end

function up()
	local success, err = turtle.up()
	if success then
		if pos.y then
			pos.y = pos.y + 1
		end
		savePos()
		return true
	else
		return false, err
	end
end

function down()
	local success, err = turtle.down()
	if success then
		if pos.y then
			pos.y = pos.y - 1
		end
		savePos()
		return true
	else
		return false, err
	end
end

function right()
	local success, err = turtle.turnRight()
	if success then
		if pos.f then
			pos.f = pos.f + 1
			if pos.f > 3 then pos.f = 0 end
		end
		savePos()
		return true
	else
		return false, err4
	end
end

function left()
	local success, err = turtle.turnLeft()
	if success then
		if pos.f then
			pos.f = pos.f - 1
			if pos.f < 0 then pos.f = 3 end
		end
		savePos()
		return true
	else
		return false, err
	end
end

--[[ Advanced movement functions ]]

function rotateTo(f)
	if f > 3 or f < 0 then
		return false, "invalid facing"
	end
	if not pos.f then
		updateFacing()
		if not pos.f then
			return false, "cannot determine facing"
		end
	end
	local function simulateRotateTo(startf, endf)
		local right, left = 0, 0
		local f = startf
		while f ~= endf do
			right = right + 1
			f = f + 1
			if f > 3 then f = 0 end
		end
		f = startf
		while f ~= endf do
			left = left + 1
			f = f - 1
			if f < 0 then f = 3 end
		end
		return right, left
	end
	local r,l = simulateRotateTo(pos.f, f)
	if r <= l then
		for i = 1, r do
			right()
		end
	else
		for i = 1, l do
			left()
		end
	end
	return true
end

function canReach(x, y, z)
	if not (pos.x and pos.y and pos.z) then
		return false, "cannot determine position"
	end
	if not x then x = pos.x end
	if not y then y = pos.y end
	if not z then z = pos.z end
	local fuelNeeded = math.abs(pos.x - x) + math.abs(pos.y - y) + math.abs(pos.z - z)
	if turtle.getFuelLevel() < fuelNeeded then
		return false, "need more fuel", math.abs(turtle.getFuelLevel() - fuelNeeded)
	end
	return true, turtle.getFuelLevel() - fuelNeeded
end

function goto(x, y, z, f, validatePos)
	if validatePos == nil then validatePos = true end
	-- Validation and inital setup
	if f and (f < 0 or f > 3) then
		return false, "invalid facing"
	end
	if not (pos.x and pos.y and pos.z and pos.f) then
		local success, err = updatePos()
		if not success then return false, err end
	end
	local start = {}
	start.x, start.y, start.z, start.f = pos.x, pos.y, pos.z, pos.f
	local dest = {}
	dest.x, dest.y, dest.z, dest.f = x, y, z, f
	if not dest.x then dest.x = start.x end
	if not dest.y then dest.y = start.y end
	if not dest.z then dest.z = start.z end
	if not dest.f then dest.f = start.f end

	if canReach(dest.x, dest.y, dest.z) then
		-- Function to determine facing necessary for coordinate change
		local function facingForCoordChange(axis, change)
			if axis == "x" then
				if change > 0 then
					return 3
				elseif change < 0 then
					return 1
				else
					return
				end
			elseif axis == "z" then
				if change > 0 then
					return 0
				elseif change < 0 then
					return 2
				else
					return
				end
			end
			return
		end
		-- Move to specified coordinates
		-- X first
		if facingForCoordChange("x", dest.x - start.x) then
			rotateTo(facingForCoordChange("x", dest.x - start.x))
		end
		for i = 1, math.abs(start.x - dest.x) do
			while not forward() do
				turtle.dig()
				turtle.attack()
			end
		end
		-- Z second
		if facingForCoordChange("z", dest.z - start.z) then
			rotateTo(facingForCoordChange("z", dest.z - start.z))
		end
		for i = 1, math.abs(start.z - dest.z) do
			while not forward() do
				turtle.dig()
				turtle.attack()
			end
		end
		-- Y last
		if start.y > dest.y then
			for i = 1, math.abs(start.y - dest.y) do
				while not down() do
					turtle.digDown()
					turtle.attackDown()
				end
			end
		elseif start.y < dest.y then
			for i = 1, math.abs(start.y - dest.y) do
				while not up() do
					turtle.digUp()
					turtle.attackUp()
				end
			end
		end
		-- Rotate
		rotateTo(dest.f)
		-- Attempt to validate position
		local final = {}
		final.x, final.y, final.z = gps.locate(0.1)
		if final.x and final.y and final.z and validatePos then
			if final.x == dest.x and final.y == dest.y and final.z == dest.z then
				return true
			else
				return false, "final position does not match"
			end
		else
			-- Assume we are in the right spot
			return true
		end
	else
		return canReach(dest.x, dest.y, dest.z)
	end
end
