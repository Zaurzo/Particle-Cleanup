local _ParticleEffect = ParticleEffect

-- If there wasn't a parent provided, force it to be the World entity instead.
-- This is so I can remove these particles with Entity:StopAndDestroyParticles()
function ParticleEffect(particleName, position, angles, parent, ...)
    if not parent then
        parent = game.GetWorld()
    end

    return _ParticleEffect(particleName, position, angles, parent, ...)
end

cleanup.Register('particles')