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
                        if not particleObj.IsValid or particleObj:IsValid() then
                            particleObjectVault[particleObj] = funcDestroyParticle
                        end
                    end

                    return particleObj
                end
            end
        end

        StealParticleObject(_R.CLuaEmitter, 'Add', _R.CLuaParticle.SetDieTime)
        StealParticleObject(_G, 'CreateParticleSystemNoEntity', _R.CNewParticleEffect.StopEmissionAndDestroyImmediately)
    end

    local function CleanupParticles(cleanupType)
        if cleanupType and cleanupType ~= 'particles' then return end
        
        for k, ent in ipairs(ents_GetAll()) do
            if isentity(ent) then
                StopAndDestroyParticles(ent)
            end
        end

        for particleObj, destroy in pairs(particleObjectVault) do
            if not particleObj.IsValid or particleObj:IsValid() then
                destroy(particleObj, 0)
            end

            particleObjectVault[particleObj] = nil
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
-- This is so I can remove these particles with Entity:StopAndDestroyParticles()
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
