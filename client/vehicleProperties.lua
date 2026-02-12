--[[
    EF Library - Vehicle Properties
    Compatible with ox_lib VehicleProperties format.
    
    Usage:
    local props = exports.ef_lib:GetVehicleProperties(vehicle)
    exports.ef_lib:SetVehicleProperties(vehicle, props)
]]

local gameBuild = GetGameBuildNumber()

-- Mod index to property name mapping (used for compact code)
local MOD_NAMES = {
    [0]  = 'modSpoilers',
    [1]  = 'modFrontBumper',
    [2]  = 'modRearBumper',
    [3]  = 'modSideSkirt',
    [4]  = 'modExhaust',
    [5]  = 'modFrame',
    [6]  = 'modGrille',
    [7]  = 'modHood',
    [8]  = 'modFender',
    [9]  = 'modRightFender',
    [10] = 'modRoof',
    [11] = 'modEngine',
    [12] = 'modBrakes',
    [13] = 'modTransmission',
    [14] = 'modHorns',
    [15] = 'modSuspension',
    [16] = 'modArmor',
    [17] = 'modNitrous',
    -- 18 = modTurbo (toggle)
    [19] = 'modSubwoofer',
    -- 20 = modSmokeEnabled (toggle)
    -- 21 = modHydraulics (toggle)
    -- 22 = modXenon (toggle)
    [23] = 'modFrontWheels',
    [24] = 'modBackWheels',
    [25] = 'modPlateHolder',
    [26] = 'modVanityPlate',
    [27] = 'modTrimA',
    [28] = 'modOrnaments',
    [29] = 'modDashboard',
    [30] = 'modDial',
    [31] = 'modDoorSpeaker',
    [32] = 'modSeats',
    [33] = 'modSteeringWheel',
    [34] = 'modShifterLeavers',
    [35] = 'modAPlate',
    [36] = 'modSpeakers',
    [37] = 'modTrunk',
    [38] = 'modHydrolic',
    [39] = 'modEngineBlock',
    [40] = 'modAirFilter',
    [41] = 'modStruts',
    [42] = 'modArchCover',
    [43] = 'modAerials',
    [44] = 'modTrimB',
    [45] = 'modTank',
    [46] = 'modWindows',
    [47] = 'modDoorR',
    [48] = 'modLivery',
    [49] = 'modLightbar',
}

--- Get all vehicle properties (ox_lib compatible format)
--- @param vehicle number Vehicle entity handle
--- @return table|nil VehicleProperties table or nil if entity doesn't exist
local function GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local paintType1 = GetVehicleModColor_1(vehicle)
    local paintType2 = GetVehicleModColor_2(vehicle)

    -- Custom colors (RGB arrays)
    if GetIsVehiclePrimaryColourCustom(vehicle) then
        colorPrimary = { GetVehicleCustomPrimaryColour(vehicle) }
    end

    if GetIsVehicleSecondaryColourCustom(vehicle) then
        colorSecondary = { GetVehicleCustomSecondaryColour(vehicle) }
    end

    -- Extras (1-15)
    local extras = {}
    for i = 1, 15 do
        if DoesExtraExist(vehicle, i) then
            extras[i] = IsVehicleExtraTurnedOn(vehicle, i) and 0 or 1
        end
    end

    -- Damage: broken windows, doors, tyres
    local windows = {}
    local windowCount = 0
    for i = 0, 7 do
        RollUpWindow(vehicle, i)
        if not IsVehicleWindowIntact(vehicle, i) then
            windowCount = windowCount + 1
            windows[windowCount] = i
        end
    end

    local doors = {}
    local doorCount = 0
    for i = 0, 5 do
        if IsVehicleDoorDamaged(vehicle, i) then
            doorCount = doorCount + 1
            doors[doorCount] = i
        end
    end

    local tyres = {}
    for i = 0, 7 do
        if IsVehicleTyreBurst(vehicle, i, false) then
            tyres[i] = IsVehicleTyreBurst(vehicle, i, true) and 2 or 1
        end
    end

    -- Neon lights
    local neons = {}
    for i = 0, 3 do
        neons[i + 1] = IsVehicleNeonLightEnabled(vehicle, i)
    end

    -- Build properties table (same keys as ox_lib)
    local props = {
        model             = GetEntityModel(vehicle),
        plate             = GetVehicleNumberPlateText(vehicle),
        plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),
        bodyHealth        = math.floor(GetVehicleBodyHealth(vehicle) + 0.5),
        engineHealth      = math.floor(GetVehicleEngineHealth(vehicle) + 0.5),
        tankHealth        = math.floor(GetVehiclePetrolTankHealth(vehicle) + 0.5),
        fuelLevel         = math.floor(GetVehicleFuelLevel(vehicle) + 0.5),
        oilLevel          = math.floor(GetVehicleOilLevel(vehicle) + 0.5),
        dirtLevel         = math.floor(GetVehicleDirtLevel(vehicle) + 0.5),
        paintType1        = paintType1,
        paintType2        = paintType2,
        color1            = colorPrimary,
        color2            = colorSecondary,
        pearlescentColor  = pearlescentColor,
        interiorColor     = GetVehicleInteriorColor(vehicle),
        dashboardColor    = GetVehicleDashboardColour(vehicle),
        wheelColor        = wheelColor,
        wheelWidth        = GetVehicleWheelWidth(vehicle),
        wheelSize         = GetVehicleWheelSize(vehicle),
        wheels            = GetVehicleWheelType(vehicle),
        windowTint        = GetVehicleWindowTint(vehicle),
        xenonColor        = GetVehicleXenonLightsColor(vehicle),
        neonEnabled       = neons,
        neonColor         = { GetVehicleNeonLightsColour(vehicle) },
        extras            = extras,
        tyreSmokeColor    = { GetVehicleTyreSmokeColor(vehicle) },

        -- Toggle mods
        modTurbo          = IsToggleModOn(vehicle, 18),
        modSmokeEnabled   = IsToggleModOn(vehicle, 20),
        modHydraulics     = IsToggleModOn(vehicle, 21),
        modXenon          = IsToggleModOn(vehicle, 22),

        -- Custom tire variations
        modCustomTiresF   = GetVehicleModVariation(vehicle, 23),
        modCustomTiresR   = GetVehicleModVariation(vehicle, 24),

        -- Livery
        modRoofLivery     = GetVehicleRoofLivery(vehicle),
        livery            = GetVehicleLivery(vehicle),

        -- Damage state
        windows           = windows,
        doors             = doors,
        tyres             = tyres,
        bulletProofTyres  = GetVehicleTyresCanBurst(vehicle),
        driftTyres        = gameBuild >= 2372 and GetDriftTyresEnabled(vehicle) or false,
    }

    -- All standard mods (0-49 except toggles)
    for modIndex, propName in pairs(MOD_NAMES) do
        props[propName] = GetVehicleMod(vehicle, modIndex)
    end

    return props
end

--- Set/restore all vehicle properties (ox_lib compatible format)
--- @param vehicle number Vehicle entity handle
--- @param props table VehicleProperties table
--- @param fixVehicle? boolean Fix the vehicle after setting properties
--- @return boolean isEntityOwner Whether client owns the entity
local function SetVehicleProperties(vehicle, props, fixVehicle)
    if not DoesEntityExist(vehicle) then
        print('^1[EF_LIB] SetVehicleProperties: Entity does not exist^0')
        return false
    end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

    SetVehicleModKit(vehicle, 0)

    -- ─── Extras ───
    if props.extras then
        for id, disable in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(id), disable == 1)
        end
    end

    -- ─── Plate ───
    if props.plate then
        SetVehicleNumberPlateText(vehicle, props.plate)
    end

    if props.plateIndex then
        SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
    end

    -- ─── Health Values ───
    if props.bodyHealth then
        SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
    end

    if props.engineHealth then
        SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
    end

    if props.tankHealth then
        SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
    end

    if props.fuelLevel then
        SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
    end

    if props.oilLevel then
        SetVehicleOilLevel(vehicle, props.oilLevel + 0.0)
    end

    if props.dirtLevel then
        SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
    end

    -- ─── Colors ───
    if props.color1 then
        if type(props.color1) == 'number' then
            ClearVehicleCustomPrimaryColour(vehicle)
            SetVehicleColours(vehicle, props.color1, colorSecondary)
        else
            if props.paintType1 then
                SetVehicleModColor_1(vehicle, props.paintType1, 0, props.pearlescentColor or 0)
            end
            SetVehicleCustomPrimaryColour(vehicle, props.color1[1], props.color1[2], props.color1[3])
        end
    end

    if props.color2 then
        if type(props.color2) == 'number' then
            ClearVehicleCustomSecondaryColour(vehicle)
            SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
        else
            if props.paintType2 then
                SetVehicleModColor_2(vehicle, props.paintType2, 0)
            end
            SetVehicleCustomSecondaryColour(vehicle, props.color2[1], props.color2[2], props.color2[3])
        end
    end

    if props.pearlescentColor or props.wheelColor then
        SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor or wheelColor)
    end

    if props.interiorColor then
        SetVehicleInteriorColor(vehicle, props.interiorColor)
    end

    if props.dashboardColor then
        SetVehicleDashboardColor(vehicle, props.dashboardColor)
    end

    -- ─── Wheels ───
    if props.wheels then
        SetVehicleWheelType(vehicle, props.wheels)
    end

    if props.wheelSize then
        SetVehicleWheelSize(vehicle, props.wheelSize)
    end

    if props.wheelWidth then
        SetVehicleWheelWidth(vehicle, props.wheelWidth)
    end

    -- ─── Window Tint ───
    if props.windowTint then
        SetVehicleWindowTint(vehicle, props.windowTint)
    end

    -- ─── Neons ───
    if props.neonEnabled then
        for i = 1, #props.neonEnabled do
            SetVehicleNeonLightEnabled(vehicle, i - 1, props.neonEnabled[i])
        end
    end

    if props.neonColor then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end

    -- ─── Damage State ───
    if props.windows then
        for i = 1, #props.windows do
            RemoveVehicleWindow(vehicle, props.windows[i])
        end
    end

    if props.doors then
        for i = 1, #props.doors do
            SetVehicleDoorBroken(vehicle, props.doors[i], true)
        end
    end

    if props.tyres then
        for tyre, state in pairs(props.tyres) do
            SetVehicleTyreBurst(vehicle, tonumber(tyre), state == 2, 1000.0)
        end
    end

    -- ─── Smoke ───
    if props.modSmokeEnabled ~= nil then
        ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled)
    end

    if props.tyreSmokeColor then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end

    -- ─── Standard Mods (0-49 except toggles) ───
    for modIndex, propName in pairs(MOD_NAMES) do
        if props[propName] then
            -- Front/back wheels can have custom tire variations
            if modIndex == 23 then
                SetVehicleMod(vehicle, 23, props[propName], props.modCustomTiresF or false)
            elseif modIndex == 24 then
                SetVehicleMod(vehicle, 24, props[propName], props.modCustomTiresR or false)
            else
                SetVehicleMod(vehicle, modIndex, props[propName], false)
            end
        end
    end

    -- ─── Toggle Mods ───
    if props.modTurbo ~= nil then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end

    if props.modSubwoofer ~= nil then
        ToggleVehicleMod(vehicle, 19, props.modSubwoofer)
    end

    if props.modHydraulics ~= nil then
        ToggleVehicleMod(vehicle, 21, props.modHydraulics)
    end

    if props.modXenon ~= nil then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end

    if props.xenonColor then
        SetVehicleXenonLightsColor(vehicle, props.xenonColor)
    end

    -- ─── Livery ───
    if props.modRoofLivery then
        SetVehicleRoofLivery(vehicle, props.modRoofLivery)
    end

    if props.livery then
        SetVehicleLivery(vehicle, props.livery)
    end

    -- ─── Tyre Options ───
    if props.bulletProofTyres ~= nil then
        SetVehicleTyresCanBurst(vehicle, props.bulletProofTyres)
    end

    if gameBuild >= 2372 and props.driftTyres then
        SetDriftTyresEnabled(vehicle, true)
    end

    -- ─── Fix Vehicle ───
    if fixVehicle then
        SetVehicleFixed(vehicle)
    end

    return not NetworkGetEntityIsNetworked(vehicle) or NetworkGetEntityOwner(vehicle) == PlayerId()
end

-- ─── Exports ───

exports('GetVehicleProperties', GetVehicleProperties)
exports('SetVehicleProperties', SetVehicleProperties)
