Config = {}

Config.Territories = {}

-- Generic
Config.Territories.MaxRadius = 250

-- Attack Configs
Config.Territories.AttackTimer =  30 -- in Minuti
Config.Territories.MinimumDefendingPlayers = 6
Config.Territories.MinAttackingPlayers = 3
Config.Territories.MaxAttackingPlayers = 6

-- Item Farming
Config.Territories.MinItems = 1
Config.Territories.MaxItems = 3

-- Blips
Config.Territories.BlipSprite = 161 -- https://docs.fivem.net/docs/game-references/blips/#blips
Config.Territories.BlipRadius = 250.0
Config.Territories.BlipColor = 1 -- https://docs.fivem.net/docs/game-references/blips/#blip-colors

-- Markers
Config.Markers = {}

-- Stashes
Config.Markers.Stashes = {}
Config.Markers.Stashes.Slots = 100
Config.Markers.Stashes.MaxWeight = 3000000

-- Boss Menu
Config.Markers.BossMenu = {}
Config.Markers.BossMenu.RecruitDistance = 3 -- Mostra tra la lista dei giocatori da poter assumere, tutti gli utenti all'interno di questa distanza dal Boss
Config.Markers.BossMenu.DefaultJobGrade = 0 -- Grado Default da attribuire a chi viene assunto
Config.Markers.BossMenu.MenuLocation = "bottomright"

-- Garage
Config.Markers.Garages = {}
Config.Markers.Garages.DefaultCar = 'blista' -- default car to spawn if args[4] is nil
Config.Markers.Garages.MenuLocation = "bottomright"

Config.Debug = false
