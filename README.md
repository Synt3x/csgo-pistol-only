# Pistol Only

A SourceMod plugin for **Counter-Strike: Global Offensive** servers. Every player spawns with a knife, a pistol, and kevlar + helmet, and picks their pistol from a menu.

> **Note:** This project is no longer maintained and is provided as-is.

## Install

1. Install [Metamod:Source](https://www.sourcemm.net/) and [SourceMod](https://www.sourcemod.net/) on your server.
2. Download `pistol-only.smx` from the [latest release](https://github.com/Synt3x/csgo-pistol-only/releases/latest).
3. Put it in `addons/sourcemod/plugins/`.
4. Restart the server or change the map.

## How to play

Join T or CT and the pistol menu opens.

- Type `!gun` (or `!guns`, `!pistol`, `!pistols`) to open the menu again.
- Choose **Keep current pistol** to stop the menu opening on every spawn.

Pistols: Glock, P2000, USP-S, P250, Five-SeveN, CZ75-Auto, Dual Berettas, Tec-9, Desert Eagle and R8 Revolver.

## Settings

Change these in `cfg/sourcemod/pistol_only.cfg`, which is created the first time the plugin loads.

| Setting | Default | What it does |
|---|---|---|
| `sm_pistolonly_default` | `weapon_usp_silencer` | Pistol for players who haven't picked one, e.g. `weapon_glock` or `deagle` |
| `sm_pistolonly_bots` | `1` | `1` = bots get a random pistol every spawn, `0` = off, or a pistol name, e.g. `deagle`, to give all bots that pistol |
| `sm_pistolonly_debug` | `0` | `1` prints each menu pick to the player's console |

<details>
<summary><strong>Recommended server config (deathmatch)</strong></summary>

Put this in your server config, e.g. `cfg/server.cfg`.

```
// Respawn
mp_respawn_on_death_t 1           // T respawn on death
mp_respawn_on_death_ct 1          // CT respawn on death
mp_respawn_immunitytime 1         // Spawn protection (seconds)
mp_deathcam_skippable 1           // Players can skip the deathcam
mp_randomspawn 0                  // Use team spawn points (1 = random)
mp_randomspawn_los 0              // Random spawns don't avoid enemy line of sight

// Teams
mp_autoteambalance 0              // No automatic team balancing
mp_limitteams 0                   // No team size limit
mp_force_pick_time 15             // Seconds to pick a team
mp_teammates_are_enemies 0        // Set to 1 for free-for-all
mp_solid_teammates 0              // Walk through teammates
mp_friendlyfire 0                 // No friendly fire
mp_spectators_max 2               // Spectator slots
mp_forcecamera 0                  // Spectators can watch anyone

// Weapons and items
mp_free_armor 2                   // Kevlar + helmet (the plugin also gives it)
sv_infinite_ammo 2                // Infinite ammo, but you still reload
mp_weapons_allow_map_placed 0     // No weapons placed on the map
mp_weapons_allow_zeus 0           // No Zeus
ammo_grenade_limit_total 0        // No grenades
ammo_grenade_limit_flashbang 0    // No flashbangs
mp_defuser_allocation 0           // No defusers
mp_death_drop_gun 0               // Don't drop weapons on death
mp_death_drop_grenade 0
mp_death_drop_defuser 0
mp_weapons_glow_on_ground 0

// No buying or money
mp_startmoney 1337
mp_buytime 0
mp_buy_anywhere 0
mp_buy_during_immunity 0
mp_afterroundmoney 0
mp_teamcashawards 0
mp_playercashawards 0

// No warmup
mp_do_warmup_offline 0
mp_do_warmup_period 0
mp_warmuptime 0
mp_warmuptime_all_players_connected 0
mp_warmup_end

// Rounds
mp_roundtime 30
mp_timelimit 30
mp_freezetime 0
mp_halftime 0
mp_halftime_pausetimer 0
mp_match_can_clinch 0
mp_maxrounds 999

// No bots
bot_quota 0
bot_quota_mode normal
bot_join_after_player 0
bot_kick

// Server
sv_cheats 0
sv_pausable 0
sv_gameinstructor_disable 1       // No game instructor hints
mp_display_kill_assists 0
sv_dc_friends_reqd 0              // Allow direct connections
host_name_store 1
host_info_show 1
host_players_show 2
```

</details>

## FAQ

**Do bots get pistols?**
Yes. By default every bot gets a random pistol, plus armor, each time it spawns. Use `sm_pistolonly_bots` to turn this off or pick one pistol for all bots.

**Why don't players see their weapon skins?**
Players always get the plain pistol. Otherwise the game can swap the chosen pistol for one from the player's inventory, e.g. a P250 instead of the CZ75.

**Can players still buy or pick up other weapons?**
The plugin only sets weapons when players spawn or pick from the menu. Use the server config above to turn off buying and map weapons.

## For developers

Compile `plugin.sp` with the SourceMod compiler (`addons/sourcemod/scripting/spcomp`). See the [SourceMod wiki](https://wiki.alliedmods.net/Compiling_SourceMod_Plugins).

GitHub Actions compiles every push. To publish a release:

1. Update `PLUGIN_VERSION` at the top of `plugin.sp` and commit.
2. Tag and push, e.g. `git tag v1.5` and `git push origin v1.5`.

The release gets the compiled `.smx` attached. It fails if the tag doesn't match `PLUGIN_VERSION`.

## License

See [LICENSE](LICENSE).
