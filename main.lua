-- ============================================================
--  BasimMod: Basim Ibn Ishaq (Assassin's Creed Mirage)
--  The Binding of Isaac: Repentance
-- ============================================================

local mod = RegisterMod("BasimMod", 1)

--  CONFIGURATION  (tweak these to balance the character)

local BASIM_ID       = Isaac.GetPlayerTypeByName("Basim")  -- auto-assigned by the game
local BASIM_NAME     = "Basim"

-- Stats applied on character init
local BASIM_STATS = {
    speed   = 1.2,    -- movement speed multiplier
    damage  = 3.5,    -- flat tear damage
    tears   = 2.73,   -- tears stat (higher = faster fire rate)
    range   = 6.5,    -- tear range
    shotspeed = 1.0,  -- tear travel speed
}

-- Smoke Bomb ability
local SMOKE_BOMB = {
    cooldown   = 300,   -- frames (300 = ~10 seconds at 30fps)
    slowRadius = 180,   -- pixels around teleport destination
    slowTime   = 90,    -- frames enemies stay slowed
    slowFactor = 0.4,   -- speed multiplier for slowed enemies (0.4 = 40% normal speed)
    teleportRange = 200, -- max pixel distance of teleport
}

--  INTERNAL STATE

local smokeBombTimer = {}   -- [playerIndex] = frames remaining on cooldown

--  HELPER UTILITIES

local function IsBasim(player)
    return player:GetPlayerType() == BASIM_ID
end

local function GetPlayerIndex(player)
    -- Simple index based on InitSeed; works for single-player
    return player.InitSeed
end

local function GetCooldownRemaining(player)
    local idx = GetPlayerIndex(player)
    return smokeBombTimer[idx] or 0
end

local function SetCooldown(player, frames)
    smokeBombTimer[GetPlayerIndex(player)] = frames
end

--  CHARACTER INITIALIZATION

-- Called when a new run starts or a character is added mid-run
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
    if not IsBasim(player) then return end

    -- Apply base stats
    player.MoveSpeed    = BASIM_STATS.speed
    player.Damage       = BASIM_STATS.damage
    player.MaxFireDelay = math.floor(30 / BASIM_STATS.tears) -- convert tears stat → fire delay
    player.TearRange    = BASIM_STATS.range * 40             -- range is internal units
    player.ShotSpeed    = BASIM_STATS.shotspeed

    -- Give Basim 6 HP (3 full red hearts = 6 half-hearts)
    player:SetMaxHearts(6, true)
    player:AddHearts(6)

    -- TODO: Set custom costume/sprite once assets are ready
    -- player:AddNullCostume(Isaac.GetCostumeIdByPath("gfx/characters/basim_costume.anm2"))

    -- Reset cooldown state
    SetCooldown(player, 0)

    print("[BasimMod] Basim initialised.")
end)


--  PIERCING TEARS

-- Fired every time a tear is created
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
    if not player or not IsBasim(player) then return end

    -- Add piercing flag so tears pass through enemies
    tear:AddTearFlags(TearFlags.TEAR_PIERCING)

    -- TODO: swap tear sprite to a "hidden blade" gfx once asset is ready
    -- tear:GetSprite():Load("gfx/tears/hidden_blade_tear.anm2", true)
end)

--  SMOKE BOMB ACTIVE ABILITY

-- MC_USE_ITEM fires when the player activates their active item.
-- Basim has no standard active item, so we hook the spacebar input directly
-- via the update loop instead.

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function(_)
    -- Iterate over all players (supports co-op)
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if IsBasim(player) then
            -- Tick cooldown down
            local cd = GetCooldownRemaining(player)
            if cd > 0 then
                SetCooldown(player, cd - 1)
            end

            -- Detect active item / spacebar press
            -- Input.IsActionTriggered returns true on the frame the button is first pressed
            if Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then
                if cd <= 0 then
                    SmokeBomb(player)
                    SetCooldown(player, SMOKE_BOMB.cooldown)
                else
                    -- Optional: play a "not ready" sound
                    -- SFXManager():Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.5, 0, false, 1.0)
                    print(string.format("[BasimMod] Smoke Bomb cooling down: %.1f s", cd / 30))
                end
            end
        end
    end
end)

--  SMOKE BOMB LOGIC

function SmokeBomb(player)
    local room   = Game():GetRoom()
    local origin = player.Position

    -- Pick a random valid floor tile within teleport range
    local dest = FindTeleportDestination(player, origin)

    -- Visual: spawn a poof/smoke effect at origin and destination
    -- TODO: replace with custom "smoke_bomb.anm2" once asset is ready
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, origin, Vector(0, 0), player)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, dest,   Vector(0, 0), player)

    -- Teleport the player
    player.Position = dest

    -- Slow all nearby enemies around the destination
    SlowNearbyEnemies(dest, SMOKE_BOMB.slowRadius, SMOKE_BOMB.slowTime, SMOKE_BOMB.slowFactor)

    -- Optional sound
    -- SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND, 1.0, 0, false, 1.0)

    print("[BasimMod] Smoke Bomb activated!")
end

function FindTeleportDestination(player, origin)
    local room = Game():GetRoom()

    -- Try up to 20 random positions; fall back to origin if none valid
    for _ = 1, 20 do
        local angle  = math.random() * 2 * math.pi
        local dist   = math.random(60, SMOKE_BOMB.teleportRange)
        local candidate = Vector(
            origin.X + math.cos(angle) * dist,
            origin.Y + math.sin(angle) * dist
        )

        -- IsPositionInRoom checks against room boundaries with padding
        if room:IsPositionInRoom(candidate, 0) then
            -- Make sure we're not landing inside a wall / obstacle
            if not room:IsObstaclePit(room:GetGridIndex(candidate)) then
                return candidate
            end
        end
    end

    -- Fallback: stay put (silently)
    return origin
end

function SlowNearbyEnemies(center, radius, duration, factor)
    -- Collect all NPCs in the current room
    local entities = Isaac.GetRoomEntities()
    for _, entity in ipairs(entities) do
        local npc = entity:ToNPC()
        if npc and npc:IsEnemy() and npc:IsVulnerableEnemy() then
            local dist = (npc.Position - center):Length()
            if dist <= radius then
                -- Apply slow via a StatusEffect if available,
                -- otherwise manually reduce velocity each frame via a timed flag.
                -- We use a simple approach: attach data and handle it in POST_NPC_UPDATE.
                npc:SetData("BasimSlowed", duration)
                npc:SetData("BasimSlowFactor", factor)
            end
        end
    end
end

-- Per-NPC update: apply the slow effect while the timer is active
mod:AddCallback(ModCallbacks.MC_POST_NPC_UPDATE, function(_, npc)
    local remaining = npc:GetData()["BasimSlowed"]
    if remaining and remaining > 0 then
        -- Reduce velocity
        local factor = npc:GetData()["BasimSlowFactor"] or 0.4
        npc.Velocity = npc.Velocity * factor

        -- Tick down
        npc:GetData()["BasimSlowed"] = remaining - 1

        -- Optional: tint enemy blue-grey while slowed
        -- npc.Color = Color(0.6, 0.8, 1.0, 1.0, 0, 0, 0)
    end
end)

--  HUD: SMOKE BOMB COOLDOWN INDICATOR

-- Draw a simple cooldown bar above the active item slot
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function(_)
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if IsBasim(player) then
            local cd    = GetCooldownRemaining(player)
            local ratio = 1 - (cd / SMOKE_BOMB.cooldown)  -- 0 → 1 (full = ready)

            -- Screen-space position (bottom-left HUD area)
            local barX  = 50
            local barY  = Isaac.GetScreenHeight() - 40
            local barW  = 80
            local barH  = 8

            -- Background
            Isaac.RenderScaledText("SMOKE", barX, barY - 12, 0.5, 0.5, 0.8, 0.8, 0.8, 1.0)

            -- TODO: replace text rendering with a proper sprite bar
            -- For now, print a simple text readout
            if cd <= 0 then
                Isaac.RenderScaledText("[READY]", barX, barY, 0.5, 0.5, 0.3, 1.0, 0.3, 1.0)
            else
                local secs = string.format("%.1fs", cd / 30)
                Isaac.RenderScaledText(secs, barX, barY, 0.5, 0.5, 1.0, 0.5, 0.2, 1.0)
            end
        end
    end
end)

--  SAVE / LOAD  (persist unlock + cooldown across sessions)

local SAVE_KEY = "BasimUnlocked"

-- Read persisted data from the mod's save file (slot 1)
local function LoadSaveData()
    if mod:HasData() then
        local raw = mod:LoadData()
        -- Data is stored as a simple key=value string: "BasimUnlocked=true"
        if raw and raw:find(SAVE_KEY .. "=true") then
            return { basimUnlocked = true }
        end
    end
    return { basimUnlocked = false }
end

local function SaveData(data)
    mod:SaveData(SAVE_KEY .. "=" .. tostring(data.basimUnlocked))
end

-- Load once at startup
local saveData = LoadSaveData()

--  UNLOCK CONDITION
--  Trigger: complete floor 1 (reach floor 2) with any character

-- MC_POST_NEW_LEVEL fires every time the player moves to a new floor
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function(_)
    -- Already unlocked – nothing to do
    if saveData.basimUnlocked then return end

    local level = Game():GetLevel()
    local floorNum = level:GetAbsoluteStage()

    -- AbsoluteStage 2 = Basement II / Cellar II / Burning Basement II
    -- Reaching it means the player cleared floor 1
    if floorNum >= 2 then
        saveData.basimUnlocked = true
        SaveData(saveData)

        -- Unlock the character so they appear on the select screen
        Isaac.ExecuteCommand("unlockchar " .. BASIM_ID)

        -- Show a short on-screen announcement
        -- (Isaac's built-in "item was found" style popup)
        Game():GetHUD():ShowItemText(
            "Character Unlocked",
            "Basim Ibn Ishaq joins the fight!"
        )

        print("[BasimMod] Basim unlocked and saved!")
    end
end)

--  DEBUG HELPERS  (remove before shipping)

-- Press F1 in-game to instantly reset Smoke Bomb cooldown
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function(_)
    if Input.IsButtonTriggered(Keyboard.KEY_F1, 0) then
        local player = Isaac.GetPlayer(0)
        if IsBasim(player) then
            SetCooldown(player, 0)
            print("[BasimMod] DEBUG: Smoke Bomb cooldown reset.")
        end
    end
end)

print("[BasimMod] Loaded successfully.")