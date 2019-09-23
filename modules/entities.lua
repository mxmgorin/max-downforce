-- Max Downforce - modules/entities.lua
-- 2017-2019 Foppygames

local entities = {}

-- =========================================================
-- includes
-- =========================================================

require "classes.banner"
require "classes.building"
require "classes.car"
require "classes.flag"
require "classes.grass"
require "classes.light"
require "classes.sign"
require "classes.spark"
require "classes.stadium"
require "classes.tree"
require "classes.tunnelend"
require "classes.tunnelstart"

local aspect = require("modules.aspect")
local perspective = require("modules.perspective")
local road = require("modules.road")
local utils = require("modules.utils")

-- =========================================================
-- constants
-- =========================================================

-- ...

-- =========================================================
-- variables
-- =========================================================

local list = {}

local lap = false

local images = {}
local baseScale = {}
local index = nil
	
-- =========================================================
-- functions
-- =========================================================

function entities.init()
	list = {}
	index = nil
end

function entities.getListLength()
	return #list
end

function entities.reset()
	local i = 1
	while i <= #list do
		list[i]:clean()
		i = i + 1
	end
	list = {}
end

function entities.checkLap()
	return lap
end

function entities.addBanner(x,z,forcedImageIndex)
	local banner = Banner:new(x,z,forcedImageIndex)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,banner)
	
	return banner
end

function entities.addBuilding(x,z)
	local building = Building:new(x,z)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,building)
	
	return building
end

function entities.addCar(x,z,isPlayer,progress)
	local car = Car:new(x,z,isPlayer,progress)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,car)
	
	return car
end

function entities.addFlag(x,z)
	local flag = Flag:new(x,z)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,flag)
	
	return flag
end

function entities.addGrass(x,z)
	local grass = Grass:new(x,z)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,grass)
	
	return grass
end

function entities.addLight(x,z)
	local light = Light:new(x,z)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,light)
	
	return light
end

function entities.addSpark(x,z,speed,color)
	local spark = Spark:new(x,z,speed,color)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,spark)
	
	return spark
end

function entities.addStadium(x,z)
	local stadium = Stadium:new(x,z)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,stadium)
	
	return stadium
end

function entities.addSign(x,z)
	local sign = Sign:new(x,z)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,sign)
	
	return sign
end

function entities.addTree(x,z,color)
	local tree = Tree:new(x,z,color)
	
	-- insert at end since most items introduced at horizon (max z)
	table.insert(list,tree)
	
	return tree
end

function entities.addTunnelEnd(z)
	local tunnelEnd = TunnelEnd:new(z)
	table.insert(list,tunnelEnd)
	return tunnelEnd
end

function entities.addTunnelStart(z)
	local tunnelStart = TunnelStart:new(z)
	table.insert(list,tunnelStart)
	return tunnelStart
end

-- returns collision speed if car collides with other entity, nil otherwise
-- Note: this function modifies car speed in case of collision
local function checkCollision(car)
	local baseCarWidth = Car.getBaseTotalCarWidth()
	local carLength = perspective.maxZ / 50
	local carWidth = baseCarWidth * car.baseScale
	
	local i = 1
	while i <= #list do
		local other = list[i]
		if (other ~= car) then
			-- other entity is scenery
			if (not other:isCar()) then
				-- car is not in tunnel
				if (not car.inTunnel) then
					if (other.solid) then
						-- collision on z
						if ((car.z < other.z) and ((car.z + carLength) >= other.z)) then
							local collision = false
							local collisionDx = 0
							-- other entity is start of tunnel
							if (other:isTunnelStart()) then
								-- collision on x
								if (car:outsideTunnelBounds()) then
									collision = true
								end
							-- other entity is not start of tunnel
							else
								local dx = math.abs(other.x - car.x)
								-- collision on x
								if (dx < (other:getCollisionWidth() * other.baseScale / 2 + carWidth / 2)) then
									collision = true
									collisionDx = dx
								end
							end
							if (collision) then
								-- car is halted
								local speed = car.speed
								car.speed = 0
								car.accEffect = 0
								return {
									speed = speed,
									dx = collisionDx
								}
							end
						end
					end
				end
			-- other entity is car
			else
				-- collision on z
				if ((car.z < other.z) and ((car.z + carLength) >= other.z)) then
					-- closing in on each other
					if (car.speed > other.speed) then
						local dx = math.abs(other.x - car.x)
						-- collision on x
						if (dx < (baseCarWidth * other.baseScale / 2 + carWidth / 2)) then 
							-- car is blocked
							local speed = car.speed - other.speed
							car.speed = other.speed * 0.90
							car.accEffect = 0
							return {
								speed = speed,
								dx = dx/2
							}
						end
					end
				end
			end
		end
		i = i + 1
	end	
	
	return nil
end

-- checks if a car is ahead
local function lookAhead(car,x)
	local baseCarWidth = Car.getBaseTotalCarWidth()
	local carLength = perspective.maxZ / 50
	local carWidth = Car.getBaseTotalCarWidth() * car.baseScale
	local checkDistance = carLength * (1 + 5 * (car.speed / car.topSpeed)) --8
	
	if (x == nil) then
		x = car.x
	end
	
	local i = 1
	while i <= #list do
		local other = list[i]
		if (other ~= car) then
			-- other entity is car
			if (other:isCar()) then
				-- collision on z
				if ((car.z < other.z) and ((car.z + checkDistance) >= other.z)) then
					-- closing in on each other
					if (car.speed > other.speed) then
						local dX = math.abs(other.x - x)
						-- collision on x
						if (dX < (baseCarWidth * other.baseScale / 2 + carWidth / 2)) then 
							return {
								collision = true,
								collisionX = other.x,
								collisionDz = other.z - car.z,
								blockingCarSpeed = other.speed
							}
						end
					end
				end
			end
		end
		i = i + 1
	end	
	
	return {collision = false}
end

function entities.update(playerSpeed,dt,trackLength)
	lap = false
	
	local aiCarCount = 0
	
	local i = 1
	while i <= #list do
		if (list[i]:isCar()) then
			-- update collision property of car
			list[i].collision = checkCollision(list[i])
			
			-- check for sparks to be generated
			local sparks = list[i]:getSparks()
			if (sparks ~= nil) then
				for j = 1,#sparks,1 do
					entities.addSpark(sparks[j].x,sparks[j].z,sparks[j].speed,sparks[j].color)
				end
				list[i]:resetSparks()
			end
		end
		
		-- update
		local delete = list[i]:update(dt)
		
		-- scroll
		result = list[i]:scroll(playerSpeed,dt)
		
		delete = delete or result.delete
		
		if (result.lap) then
			lap = true
		end
		
		if (list[i]:isCar()) then
			if (not delete) then
				if (not list[i].isPlayer) then
					aiCarCount = aiCarCount + 1
					
					local lookAheadResult = lookAhead(list[i],list[i].x)
					
					-- possible collision detected
					if (lookAheadResult.collision) then
						-- check other lane
						local otherLaneX
						if (list[i].x < 0) then
							otherLaneX = Car.getXFromLane(1,false)
						else
							otherLaneX = Car.getXFromLane(-1,false)
						end
						local otherLaneResult = lookAhead(list[i],otherLaneX)
						
						-- consider changing lane
						list[i]:selectNewLane(lookAheadResult.collisionX,lookAheadResult.collisionDz,lookAheadResult.blockingCarSpeed,otherLaneResult)
					end
				end
			end
		end
		
		if (delete) then
			list[i]:clean()
		
			table.remove(list,i)
		else
			i = i + 1
		end
	end
	
	-- sort all entities on increasing z
	table.sort(list,function(a,b) return a.z < b.z end)
	
	return aiCarCount
end

function entities.resetForDraw()
	index = 1
end

function entities.setupForDraw(z,roadX,screenY,scale,previousZ,previousRoadX,previousScreenY,previousScale,segment)
	while (index <= #list) and (list[index].z <= z) do
		list[index]:setupForDraw(z,roadX,screenY,scale,previousZ,previousRoadX,previousScreenY,previousScale,segment)
		index = index + 1
	end
end

function entities.draw()
	for i = #list,1,-1 do
		list[i]:draw()
	end
end

function entities.cancelXSmoothing()
	for i = #list,1,-1 do
		list[i].smoothX = false
	end
end

return entities