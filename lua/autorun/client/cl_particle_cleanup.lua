local particleObjectVault = {}

local ents = ents
local isentity = isentity
local ipairs = ipairs
local pairs = pairs

local function isValid(ent)
    return ent:GetTable() ~= nil -- GetTable returns no value if the entity is NULL
end

local function isCreatedByMap(ent)
    if ent:GetClass() == 'class CLuaEffect' then
        -- Entity:CreatedByMap() returns true for Lua effects, what the fudge?
        -- Note: This will be fixed in the next gmod update

        return false
    end

    if ent == game.GetWorld() then
        return false
    end

    return ent:CreatedByMap()
end

local doNotCleanUp = {
    ['_firesmoke'] = 'env_fire'
}

local function isValidForCleanUp(ent)
    if not isentity(ent) then
        return false
    end

    local shouldCleanUp = isValid(ent) and not isCreatedByMap(ent)

    if shouldCleanUp then
        local blacklistedParent = doNotCleanUp[ent:GetClass()]

        if blacklistedParent then
            local parent = ent:GetParent()

            if parent:IsValid() and blacklistedParent == parent:GetClass() then
                return false
            end
        end

        return true
    end
end

local function CleanupParticles(cleanupType)
    if cleanupType and cleanupType ~= 'particles' then return end
    
    for k, ent in ipairs(ents.GetAll()) do
        if isValidForCleanUp(ent) then
            ent:StopAndDestroyParticles()

            if ent:GetClass() == 'class CLuaEffect' then
                ent:Remove()
            end
        end
    end

    for particleObj, funcDestroyParticleName in pairs(particleObjectVault) do
        local destroy = particleObj[funcDestroyParticleName]

        if destroy then
            destroy(particleObj, 0)
        end

        particleObjectVault[particleObj] = nil
    end
end

language.Add('Cleanup_particles', 'Particles')

hook.Add('OnCleanup', 'particle_cleanup', CleanupParticles)
hook.Add('PreCleanupMap', 'particle_cleanup', CleanupParticles)

-- StealParticleObject
-- Detour a particle creation function and save it's returned object to particleObjectVault
local function StealParticleObject(meta, funcName, funcDestroyParticleName)
    local createParticle = meta[funcName]

    if createParticle then
        meta[funcName] = function(...)
            local particleObj = createParticle(...)

            if particleObj then
                if not particleObj.IsValid or particleObj:IsValid() then
                    particleObjectVault[particleObj] = funcDestroyParticleName
                end
            end

            return particleObj
        end
    end
end

local CLuaEmitter = debug.getregistry().CLuaEmitter

StealParticleObject(CLuaEmitter, 'Add', 'SetDieTime')
StealParticleObject(_G, 'CreateParticleSystemNoEntity', 'StopEmissionAndDestroyImmediately')