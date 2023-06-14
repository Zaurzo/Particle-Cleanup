if CLIENT then
    local _R = debug.getregistry()

    local particleObjectVault = {}

    local StopAndDestroyParticles = _R.Entity.StopAndDestroyParticles
    local ents_GetAll = ents.GetAll

    local isentity = isentity
    local ipairs = ipairs
    local pairs = pairs
    local ents = ents

    do
        -- StealParticleObject
        -- Detour a particle creation function and save it's returned object to particleObjectVault
        
        -- @arg funcDestroyParticle
        -- The function to call on the particle object to completely destroy it
        local function StealParticleObject(meta, funcName, funcDestroyParticle)
            local createParticle = meta[funcName]

            if createParticle then
                meta[funcName] = function(...)
                    local particleObj = createParticle(...)

                    if particleObj then
                        particleObjectVault[particleObj] = funcDestroyParticle
                    end

                    return particleObj
                end
            end
        end

        local CNewParticleEffect = _R.CNewParticleEffect
        local StopEmissionAndDestroyImmediately = CNewParticleEffect.StopEmissionAndDestroyImmediately

        StealParticleObject(_R.CLuaEmitter, 'Add', _R.CLuaParticle.SetDieTime)
        StealParticleObject(CNewParticleEffect, 'CreateParticleSystemNoEntity', StopEmissionAndDestroyImmediately)
    end

    local function CleanupParticles(cleanupType)
        if cleanupType and cleanupType ~= 'particles' then return end

        for particleObj, destroy in pairs(particleObjectVault) do
            local particleIsValid = particleObj.IsValid
            local isValid = true

            if particleIsValid then
                if not particleIsValid(particleObj) then
                    isValid = false
                end
            end
            
            if isValid then
                destroy(particleObj, 0)
            end
        end

        for k, ent in ipairs(ents_GetAll()) do
            if isentity(ent) then
                StopAndDestroyParticles(ent)
            end
        end
    end

    language.Add('Cleanup_particles', 'Particles')

    hook.Add('OnCleanup', 'particle_cleanup', CleanupParticles)
    hook.Add('PostCleanupMap', 'particle_cleanup', CleanupParticles)
end

local ParticleEffect = ParticleEffect
local Entity = Entity
local World

-- If there wasn't any parent provided, force it to be the World entity instead.
-- This is so I can remove these particles with Entity:StopParticles() or Entity:StopParticleEmission()
function _G.ParticleEffect(particleName, position, angles, parent, ...)
    if not isentity(parent) then
        if not World then
            World = Entity(0)
        end

        parent = World
    end

    return ParticleEffect(particleName, position, angles, parent, ...)
end

cleanup.Register('particles')