-- Make the bolt impacts able to be cleaned up

local cleanUpBolts = CreateClientConVar('cl_particle_cleanup_bolts', '1', true, false)

local EFFECT = {}
local tempBoltEnts

-- Ported from
-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/mathlib/mathlib_base.cpp#L535
local function VectorAngles(forward)
	local tmp, yaw, pitch
	
	if forward.x == 0 and forward.y == 0 then
		yaw = 0

		if forward.z > 0 then
			pitch = 270
		else
			pitch = 90
        end
	else
		yaw = math.atan2(forward.y, forward.x) * 180 / math.pi

		if yaw < 0 then
			yaw = yaw + 360
        end

		tmp = math.sqrt(forward.x * forward.x + forward.y * forward.y)
		pitch = math.atan2(-forward.z, tmp) * 180 / math.pi

		if pitch < 0 then
			pitch = pitch + 360
        end
    end

    return Angle(pitch, yaw, 0)
end

function EFFECT:Init(data)
	local bolt = ClientsideModel('models/crossbow_bolt.mdl')
	if not bolt:IsValid() then return end

	local dir = data:GetNormal()

	bolt:SetPos(data:GetOrigin() - dir * 8)
	bolt:SetAngles(VectorAngles(dir))

	tempBoltEnts[bolt] = true
end

function EFFECT:Render()
end

local function clearTempBoltEnts()
    if not tempBoltEnts then return end

	for bolt in pairs(tempBoltEnts) do
		if bolt:IsValid() then
			bolt:Remove()
		end
	end

    tempBoltEnts = {}
end

local function setupBoltCleanUp(value)
    local handleHook = value and hook.Add or hook.Remove

    clearTempBoltEnts()

    handleHook('PreCleanupMap', 'particle_cleanup_bolts', clearTempBoltEnts)

    if value then
        tempBoltEnts = tempBoltEnts or {}
    else
        tempBoltEnts = nil
    end

    effects.Register(value and EFFECT or nil, 'BoltImpact')
end

if cleanUpBolts:GetBool() then
    setupBoltCleanUp(true)
end

cvars.AddChangeCallback('cl_particle_cleanup_bolts', function(name, old, new)
    setupBoltCleanUp(new == '1')
end)