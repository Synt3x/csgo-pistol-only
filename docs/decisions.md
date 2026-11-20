# Decisions

Newest first.

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
