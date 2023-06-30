if CLIENT then
    local particleObjectVault = {}

    do
        -- StealParticleObject
        -- Detour a particle creation function and save it's returned object to particleObjectVault
        
        -- @arg funcDestroyParticleName
        -- The name of the function to call on the particle object to completely destroy it
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
    end

    local ents = ents
    local isentity = isentity
    local ipairs = ipairs
    local pairs = pairs

    local function CleanupParticles(cleanupType)
        if cleanupType and cleanupType ~= 'particles' then return end
        
        for k, ent in ipairs(ents.GetAll()) do
            if isentity(ent) and ent ~= NULL then
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
end

local ParticleEffect = ParticleEffect
local game_GetWorld = game.GetWorld

-- If there wasn't a parent provided, force it to be the World entity instead.
-- This is so I can remove these particles with Entity:StopAndDestroyParticles()
function _G.ParticleEffect(particleName, position, angles, parent, ...)
    if not parent then
        parent = game_GetWorld()
    end

    return ParticleEffect(particleName, position, angles, parent, ...)
end

cleanup.Register('particles')
