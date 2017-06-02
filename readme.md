# Pistol Only for Counter-Strike:Global Offensive (Server)

## Usage
*This plugin works best when playing deathmatch*

##### requires the following packages to run
* Sourcemod - https://www.sourcemod.net/
* Metamod:Source - https://www.sourcemm.net/

##### how do i use the plugin?
1. After you installed the required packages, you have to compile the plugin into an smx file.
2. When the file is compiled you move the smx file into '*addons/sourcemod/plugins*'.
3. Launch your dedicated server and join it, now it's up and running with the plugin.
4. In-game instruction will appear when you join CT or T.

##### server config
```
// #Pistol Only (Deathmatch) Configuration

// https://www.gametracker.com/games/csgo/forum.php?thread=91691
host_name_store 1
host_info_show 1
host_players_show 2

// Config
mp_autoteambalance 0            // Let us disable team balancing and hope the players do that them selves
mp_limitteams 0                 // How many more people could be in CT or T? 0 = Disable
sv_gameinstructor_disable 0     // Who need game instructions?
sv_dc_friends_reqd 0            // ALlow direct connection
sv_cheats 0                     // We don't need cheats
sv_pausable 0                   // We don't need to pause either

// Player
mp_forcecamera 0                // Everybody can spectate everyone
mp_display_kill_assists 0       // Disable kill assists
mp_force_pick_time 15           // Force player to choose team
mp_free_armor 2                 // Plugin should give kev+helm
mp_teammates_are_enemies 0      // Should it be FFA then turn this to 1
mp_solid_teammates 0            // Friends will now be ghosts

// Player respawn
mp_spectators_max 2             // Max amount of slots in spectator
mp_deathcam_skippable 1         // Player can skip deathcam
mp_respawn_on_death_t 1         // T will spawn on death
mp_respawn_on_death_ct 1        // CT will spawn on death
mp_respawn_immunitytime 1       // Protection time when spawning
mp_randomspawn 0                // Witch team player will respawn in
mp_randomspawn_los 0            // Should players be line in sight when spawning

// Weapon & item
sv_infinite_ammo 2              // Infinite ammo but needs to reload
mp_friendlyfire 0               // Disable friendlyfire
mp_death_drop_gun 0             // Weapons doesn't drop on ground
mp_death_drop_defuser 0	        // Player doesn't drop defuser
mp_death_drop_grenade 0         // Player doesn't drop grenades
mp_defuser_allocation 0         // Disable defuser
mp_weapons_allow_map_placed 0   // No other weapon should be used
mp_weapons_glow_on_ground 0     // Shouldn't be any weapon on ground
mp_weapons_allow_zeus 0         // Disables Zeus
ammo_grenade_limit_flashbang 0  // Disables flashbangs
ammo_grenade_limit_total 0      // Disables grenades, smokes, flashes, decoy, molotov

// Buy menu
mp_startmoney 1337              // l33t
mp_buytime 0                    // No buytime
mp_buy_anywhere 0               // Player can't buy anywhere
mp_buy_during_immunity 0        // Player can't buy item when he is in immunity

// Bot
bot_quota 0                     // How many bots should spawn?
bot_join_after_player 0         // Should bot join afer player?
bot_quota_mode normal           // How difficult should the bots be?
bot_kick                        // Let us kick the bots

// Warmup                       // Let us try to disable warmup
mp_do_warmup_offine 0
mp_do_warmup_period 0
mp_warmuptime 0
mp_warmuptime_all_players_connected 0
mp_warmup_end

// Cash                         // No rewards
mp_afterroundmoney 0
mp_teamcashawards 0
mp_playercashawards 0

// Round                        // AIM map settings
mp_roundtime 30
mp_timelimit 30
mp_freezetime 0
mp_halftime 0
mp_match_can_clinch 0 
mp_maxrounds 999
mp_halftime_pausetimer 0

```


## Development
##### how to compile?
* Sourcemod, You can use the compiler from the package, you find it in '*addons/sourcemod/scripting*' - https://wiki.alliedmods.net/Compiling_SourceMod_Plugins.
* Sourcemod, Online Compiler - https://www.sourcemod.net/compiler.php.

__online compiler sometimes shows error when the compiler from the package doesn't__

## FAQ
* Does this work with bots?

*No, bot doesn't get random pistol at spawn.*

* Player can still pickup and buy other weapons

*Yes, this plugin doesn't remove weapon that player picks up. Use the 'server configs' to make it a bit better.*
