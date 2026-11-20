# Decisions

Newest first.

## 2026-11-20 – Default pistol is the USP-S and is set with a ConVar
- **Area:** Settings
- **Decision:** `sm_pistolonly_default` (default `weapon_usp_silencer`) and `sm_pistolonly_debug` replace hardcoded values. Invalid names fall back to the USP-S and are logged.
- **Why:** Admins can change the default without recompiling, and a typo can't leave players without a pistol.
- **Level:** LIVE

## 2026-11-20 – Pistols are always given without skins
- **Area:** Gameplay
- **Decision:** The pistol is given while the player briefly has no team, so the game gives the plain weapon instead of one from the player's inventory.
- **Why:** Shared loadout slots made picks like CZ75, USP-S and R8 give the wrong gun. Skins don't matter on this server. Giving skins the player doesn't own breaks Valve's server rules, so that was ruled out.
- **Objection:** Claude suggested keeping skins when the first attempt gave the right gun; Robin chose always plain for simplicity.
- **Level:** LIVE

## 2026-11-20 – Menu choices while dead are saved for the next spawn
- **Area:** Gameplay / menu
- **Decision:** Picking a pistol while dead or in spectator saves it and gives it on the next spawn. Living players can still pick from the menu once per life.
- **Why:** The menu stays open forever, so it was possible to get weapons while dead. Saving the choice keeps the player's intent.
- **Level:** LIVE

## 2026-11-20 – Command hint is shown once, not on every spawn
- **Area:** GUI / chat
- **Decision:** "Type !gun, …" is printed on a player's first spawn and when they choose "Keep current pistol".
- **Why:** In deathmatch, players respawn every few seconds and the hint flooded chat.
- **Level:** LIVE

## 2026-11-20 – "Hide Menu" renamed to "Keep current pistol"
- **Area:** GUI / menu
- **Decision:** The option is labelled after what it does: it keeps the pistol and stops the menu from opening on spawn until the player types !gun.
- **Why:** "Hide Menu" sounded like a one-time close, and players didn't know how to get the menu back.
- **Level:** LIVE

## 2026-11-20 – Readme keeps the "no longer maintained" note
- **Area:** Docs
- **Decision:** The note stays, even though bugs were fixed and releases are now built automatically.
- **Objection:** Claude suggested removing it since releases are being made again; Robin chose to keep it.
- **Level:** LIVE (releases are meant to be usable on real servers)

## 2026-11-20 – Plugin URL points to GitHub
- **Area:** Plugin info
- **Decision:** `url` in `myinfo` is `https://github.com/Synt3x/csgo-pistol-only`.
- **Why:** synt3x.com is no longer in use; admins can find source and releases on GitHub.
- **Level:** LIVE
