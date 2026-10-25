Config = {}

Config.Debug = false

Config.Language = "en" -- Language to use.

Config.UseTarget = false -- Enables the use of target, automatically supports ox_target, qb-target, and qtarget.

Config.RenderDistance = 100.0 -- Visibility distance of interaction points.

Config.InteractDistance = 2.0 -- Interaction distance.

Config.EmoteCommandPrefix = "e" -- Emote command prefix (used for in-fight emotes).

Config.Photos = {
    -- Configure the private upload endpoint in server_config.lua.
    uploadProtocol = 'files[]',
    ResponseHandler = function(resp) -- Return URL from response.
       return resp.attachments[1].url
    end,
    brightness = 1.0,
    coords = vector3(-3554.9810, 2273.0916, 10.0380),
    heading = 0.0,
}

Config.Fights = {
    RecoverTime = 10, -- Amount of time allowed to recover from a knockout.
    RecoverClicks = {30, 90}, -- Range of clicks required to recover from a knockout between fully healed, and 0 simulated health.
    RecoverHealth = {5, 10}, -- Amount of simulated health to regenerate upon recovering from a knockout.
    RecoverHealthRound = {15, 20}, -- Amount of simulated health to regenerate after a round is over.
    KnockoutInterval = 4, -- Every (x) contacts by another player, check for a chance to get knocked out.
    AttackDamage = {2, 5}, -- Amount of simulated health to remove per-punch, randomized minimum and maximum damage. 
    BoxingGloveProp = `pfc_boxing_glove`,
}

Config.DefaultFighterInfo = {
    age = 18,
    weight = 200,
    height = "5\"11",
    emoteIntro = "boxing",
    emoteWin = "boxdance",
    emoteLoss = "sitscared",
}

Config.Locations = {
    {
        blip = { -- Blip for the match, optional.
            enabled = true,
            id = 268,
            display = 4,
            scale = 1.0,
            color = 1,
            label = "Maze Bank Arena"
        },
        defaultSettings = {
            rounds = 3, -- How many rounds
            roundLength = 1, -- How many minutes per round
            fightType = "boxing", -- Fight Type ("mma", "boxing")
            event = "Main Event"
        },
        permissions = { -- Permissions that can manage fights at this location, remove this entry to disable the check.
            { type = "group", name = "admin" },
            { type = "group", name = "god" },
            -- { type = "ace", name = "ace.permission" }
            -- { type = "job", name = "fightclub", rank = 0 }
        },
        -- joinPermissions = { -- Permissions that can join the fights at this location, remove this entry to disable the check.
        --     { type = "group", name = "admin" },
        --     { type = "group", name = "god" },
        --     { type = "ace", name = "ace.permission" }
        --     { type = "job", name = "fightclub", rank = 0 }
        -- },
        interact = { -- This should be a location outside of the ring that will allow players to use the interaction menu for the match.
            coords = vector3(-328.0378, -1973.1385, 21.6035),
            heading = 129.1393,
        },
        center = { -- This should be the center of the ring, which is used for camera transitions.
            coords = vector3(-324.3031, -1968.5017, 22.3923),
            heading = 140.6748,
            radius = 30.0, -- The distance where video scenes will display at, as well as the scoreboard.
        },
        fighterPositions = { -- These are the locations for each fighter to occupy, there must always be 2 at all times
            {
                coords = vector3(-327.0898, -1966.1340, 21.3923),
                heading = 233.4384
            },    
            {
                coords = vector3(-321.3947, -1970.7633, 21.3923),
                heading = 54.8536
            },
        },
    }
}