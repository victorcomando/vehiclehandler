if not lib then print('^1ox_lib must be started before this resource.^0') return end
lib.locale()

---@class Handler : OxClass
local Handler = require 'modules.handler'
local Settings <const> = lib.load('data.vehicle')
local Units <const> = Settings.units == 'mph' and 2.23694 or 3.6
local FallSettings <const> = Settings.fall
local BurstSettings <const> = Settings.burst
local ImpactAngle <const> = 12.0
local FRONT_WHEELS <const> = {0, 1}
local MIDDLE_WHEELS <const> = {2, 3}
local REAR_WHEELS <const> = {4, 5}
local LEFT_WHEELS <const> = {0, 2, 4}
local RIGHT_WHEELS <const> = {1, 3, 5}
local ALL_WHEELS <const> = {0, 1, 4, 5, 2, 3}

local function insertUnique(list, value)
    for i = 1, #list do
        if list[i] == value then return end
    end

    list[#list + 1] = value
end

local function mergeWheels(target, source)
    for i = 1, #source do
        insertUnique(target, source[i])
    end
end

local function resolveImpactWheels(vehicle, class)
    local rotation = GetEntityRotation(vehicle, 2)
    local pitch = rotation.x
    local roll = GetEntityRoll(vehicle)
    local absPitch = math.abs(pitch)
    local absRoll = math.abs(roll)
    local inverted = absPitch > 95.0 or absRoll > 95.0
    local wheels = {}

    if class == 8 then
        if pitch <= -ImpactAngle then mergeWheels(wheels, FRONT_WHEELS) end
        if pitch >= ImpactAngle then mergeWheels(wheels, REAR_WHEELS) end

        if absRoll >= ImpactAngle then
            mergeWheels(wheels, FRONT_WHEELS)
            mergeWheels(wheels, REAR_WHEELS)
        end

        if inverted or #wheels == 0 then
            mergeWheels(wheels, FRONT_WHEELS)
            mergeWheels(wheels, REAR_WHEELS)
        end

        return wheels
    end

    if pitch <= -ImpactAngle then mergeWheels(wheels, FRONT_WHEELS) end
    if pitch >= ImpactAngle then mergeWheels(wheels, REAR_WHEELS) end
    if roll >= ImpactAngle then mergeWheels(wheels, LEFT_WHEELS) end
    if roll <= -ImpactAngle then mergeWheels(wheels, RIGHT_WHEELS) end

    if absPitch >= ImpactAngle and absRoll >= ImpactAngle then
        mergeWheels(wheels, MIDDLE_WHEELS)
    end

    if inverted then
        mergeWheels(wheels, FRONT_WHEELS)
        mergeWheels(wheels, REAR_WHEELS)
        mergeWheels(wheels, MIDDLE_WHEELS)
    end

    if #wheels == 0 then mergeWheels(wheels, ALL_WHEELS) end

    return wheels
end

---@param vehicle number
local function startThread(vehicle)
    if not vehicle then return end
    if not Handler or Handler:isActive() then return end

    Handler:setActive(true)

    local oxfuel = Handler:isFuelOx()
    local electric = Handler:isElectric()
    local class = Handler:getClass()
    local model = Handler:getModel()
    local fallEnabled = Settings.breaktire and FallSettings and FallSettings.enabled
    local wasAirborne = false
    local fallMaxZ = 0.0
    local fallMinZ = 0.0
    local fallImpactSpeed = 0.0
    local burstTimer = 0

    CreateThread(function()
        while (cache.vehicle == vehicle) and (cache.seat == -1) do

            -- Retrieve latest vehicle data
            local engine, body, speed = Handler:setData({
                ['engine'] = GetVehicleEngineHealth(vehicle),
                ['body'] = GetVehicleBodyHealth(vehicle),
                ['speed'] = GetEntitySpeed(vehicle) * Units
            })
            local velocity = GetEntityVelocity(vehicle)
            local horizontalSpeed = math.sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y)) * Units
            local coords = GetEntityCoords(vehicle)

            -- Prevent negative engine health & driveability handler (engine)
            if engine <= 0 then
                if engine < 0 then
                    SetVehicleEngineHealth(cache.vehicle, 0.0)
                end

                if IsVehicleDriveable(vehicle, true) then
                    SetVehicleUndriveable(vehicle, true)
                end
            end

            -- Prevent negative body health
            if body < 0 then
                SetVehicleBodyHealth(cache.vehicle, 0.0)
            end

            -- Driveability handler (fuel)
            if not electric and class ~= 14 then
                local fuel = oxfuel and Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)

                if fuel <= 7 then
                    if IsVehicleDriveable(vehicle, true) then
                        SetVehicleUndriveable(vehicle, true)
                    end
                end
            end

            -- Reduce torque after half-life
            if not Handler:isLimited() and engine < 500 then
                Handler:setLimited(true)

                CreateThread(function()
                    while cache.vehicle == vehicle and cache.seat == -1 do
                        local engineLevel = Handler:getData('engine')
                        if engineLevel >= 500 then break end

                        SetVehicleCheatPowerIncrease(vehicle, (engineLevel + 500) / 1100)
                        Wait(1)
                    end

                    Handler:setLimited(false)
                end)
            end

            -- Prevent rotation controls while flipped/airborne
            if Settings.regulated[class] and not Settings.exclusions[model] then
                local roll, airborne = 0.0, false

                if speed < 2.0 then
                    roll = GetEntityRoll(vehicle)
                else
                    airborne = IsEntityInAir(vehicle)
                end

                if (roll > 75.0 or roll < -75.0) or airborne then
                    if Handler:canControl() then
                        Handler:setControl(false)

                        CreateThread(function()
                            while not Handler:canControl() and cache.seat == -1 do
                                DisableControlAction(2, 59, true) -- Disable left/right
                                DisableControlAction(2, 60, true) -- Disable up/down
                                Wait(1)
                            end

                            if not Handler:canControl() then Handler:setControl(true) end
                        end)
                    end
                else
                    if not Handler:canControl() then Handler:setControl(true) end
                end
            end

            if fallEnabled then
                local airborneState = IsEntityInAir(vehicle)

                if airborneState then
                    local velocity = GetEntityVelocity(vehicle)
                    fallImpactSpeed = math.max(fallImpactSpeed, math.abs(velocity.z) * Units)

                    if not wasAirborne then
                        wasAirborne = true
                        fallMaxZ = coords.z
                        fallMinZ = coords.z
                    else
                        if coords.z > fallMaxZ then
                            fallMaxZ = coords.z
                        end

                        if coords.z < fallMinZ then
                            fallMinZ = coords.z
                        end
                    end
                elseif wasAirborne then
                    local dropHeight = fallMaxZ - fallMinZ

                    if dropHeight >= FallSettings.minHeight and fallImpactSpeed >= FallSettings.minSpeed then
                        local impactWheels = resolveImpactWheels(vehicle, class)

                        for i = 1, #impactWheels do
                            Handler:breakTire(vehicle, impactWheels[i])
                        end
                    end

                    wasAirborne = false
                    fallMaxZ = 0.0
                    fallMinZ = 0.0
                    fallImpactSpeed = 0.0
                end
            end

            if BurstSettings then
                local hasBurst = false

                for i = 0, 5 do
                    if IsVehicleTyreBurst(vehicle, i, true) then
                        hasBurst = true
                        break
                    end
                end

                if hasBurst and horizontalSpeed >= BurstSettings.thresholdSpeed then
                    burstTimer = burstTimer + 300

                    if burstTimer >= 900 then
                        burstTimer = 0

                        local degradation = BurstSettings.degradation or 1.0
                        local newEngine = math.max(engine - degradation, -1000.0)
                        local newBody = math.max(body - (degradation * 0.5), 0.0)

                        lib.callback('vehiclehandler:sync', false, function()
                            SetVehicleEngineHealth(vehicle, newEngine)
                            SetVehicleBodyHealth(vehicle, newBody)
                        end)
                    end
                else
                    burstTimer = 0
                end
            end

            Wait(300)
        end

        Handler:setActive(false)

        -- Retrigger thread if admin spawns a new vehicle while in one
        if cache.vehicle and cache.seat == -1 then
            startThread(cache.vehicle)
        end
    end)
end

---@param victim number
---@param weapon number | string
AddEventHandler('entityDamaged', function(victim, _, weapon, _)
    if not Handler or not Handler:isActive() then return end
    if victim ~= cache.vehicle then return end
    if GetWeapontypeGroup(weapon) ~= 0 then return end

    -- Damage handler
    local bodyDiff = Handler:getData('body') - GetVehicleBodyHealth(cache.vehicle)
    if bodyDiff > 0 then

        -- Calculate latest damage
        local bodyDamage = bodyDiff * Settings.globalmultiplier * Settings.classmultiplier[Handler:getClass()]
        local newEngine = GetVehicleEngineHealth(cache.vehicle) - bodyDamage

        -- Update engine health
        if newEngine > 0 and newEngine ~= Handler:getData('engine') then
            SetVehicleEngineHealth(cache.vehicle, newEngine)
        else
            SetVehicleEngineHealth(cache.vehicle, 0.0)
        end
    end

    -- Impact handler
    local speedDiff = Handler:getData('speed') - (GetEntitySpeed(cache.vehicle) *  Units)
    if speedDiff >= Settings.threshold.speed then

        -- Handle wheel loss
        if Settings.breaktire then
            if bodyDiff >= Settings.threshold.health then
                math.randomseed(GetGameTimer())
                Handler:breakTire(cache.vehicle, math.random(0, 1))
            end
        end

        -- Handle heavy impact (disable vehicle)
        if speedDiff >= Settings.threshold.heavy then
            SetVehicleUndriveable(cache.vehicle, true)
            SetVehicleEngineHealth(cache.vehicle, 0.0)
            SetVehicleEngineOn(cache.vehicle, false, true, false)
        end
    end
end)

---@param fixtype string
---@return boolean | nil success
lib.callback.register('vehiclehandler:basicfix', function(fixtype)
    if not Handler then return end
    return Handler:basicfix(fixtype)
end)

---@return boolean | nil success
lib.callback.register('vehiclehandler:basicwash', function()
    if not Handler then return end
    return Handler:basicwash()
end)

---@return boolean | nil success
lib.callback.register('vehiclehandler:adminfix', function()
    if not Handler or not Handler:isActive() then return end
    return Handler:adminfix()
end)

---@return boolean | nil success
lib.callback.register('vehiclehandler:adminwash', function()
    if not Handler or not Handler:isActive() then return end
    return Handler:adminwash()
end)

---@param newlevel number
---@return boolean | nil success
lib.callback.register('vehiclehandler:adminfuel', function(newlevel)
    if not Handler or not Handler:isActive() then return end
    return Handler:adminfuel(newlevel)
end)

---@param seat number
lib.onCache('seat', function(seat)
    if seat == -1 then
        startThread(cache.vehicle)
    end
end)

CreateThread(function()
    Handler = Handler:new()

    if cache.seat == -1 then
        startThread(cache.vehicle)
    end
end)