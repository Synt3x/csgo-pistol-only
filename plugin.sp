#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0.0"
#define WEAPON_NAME_LENGTH 32
#define FALLBACK_WEAPON "weapon_usp_silencer"
#define MENU_ITEM_KEEP "same"

enum struct Pistol {
	char weapon[WEAPON_NAME_LENGTH]; // Entity class name, e.g. "weapon_glock"
	char name[WEAPON_NAME_LENGTH];   // Menu label
	int defindex;                    // Item definition index, to check what was given
}

// Pistols that can be chosen, in menu order
static const Pistol PISTOLS[] = {
	{ "weapon_glock",        "Glock-18",      4 },
	{ "weapon_hkp2000",      "P2000",         32 },
	{ "weapon_usp_silencer", "USP-S",         61 },
	{ "weapon_p250",         "P250",          36 },
	{ "weapon_fiveseven",    "Five-SeveN",    3 },
	{ "weapon_cz75a",        "CZ75-Auto",     63 },
	{ "weapon_elite",        "Dual Berettas", 2 },
	{ "weapon_tec9",         "Tec-9",         30 },
	{ "weapon_deagle",       "Desert Eagle",  1 },
	{ "weapon_revolver",     "R8 Revolver",   64 }
};

// What bots get on spawn (sm_pistolonly_bots)
enum BotMode {
	BotMode_Off,    // 0: leave bots alone
	BotMode_Random, // 1: random pistol every spawn
	BotMode_Fixed   // pistol name: always that pistol
};

ConVar g_cvDefault;
ConVar g_cvDebug;
ConVar g_cvBots;

Menu g_PistolMenu;
char g_DefaultWeapon[WEAPON_NAME_LENGTH] = FALLBACK_WEAPON;
BotMode g_BotMode = BotMode_Random;
char g_BotWeapon[WEAPON_NAME_LENGTH];

// Per player
char g_ChosenWeapon[MAXPLAYERS + 1][WEAPON_NAME_LENGTH];
bool g_ShowMenuOnSpawn[MAXPLAYERS + 1];
bool g_PickedThisLife[MAXPLAYERS + 1];
bool g_ShownHint[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "Pistol Only",
	author = "Robin Linusson",
	description = "Pistol Only for Counter-Strike: Global Offensive",
	version = PLUGIN_VERSION,
	url = "https://github.com/Synt3x/csgo-pistol-only"
};

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

public void OnPluginStart() {
	g_PistolMenu = BuildPistolMenu();

	// Settings, saved to cfg/sourcemod/pistol_only.cfg
	CreateConVar("sm_pistolonly_version", PLUGIN_VERSION, "Pistol Only version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvDefault = CreateConVar("sm_pistolonly_default", FALLBACK_WEAPON, "Pistol for players who haven't chosen one, e.g. weapon_glock or weapon_deagle");
	g_cvDebug = CreateConVar("sm_pistolonly_debug", "0", "1 = print menu picks to the player's console", _, true, 0.0, true, 1.0);
	g_cvBots = CreateConVar("sm_pistolonly_bots", "1", "Bot pistols: 1 = random every spawn, 0 = off, or a pistol name, e.g. weapon_deagle");
	AutoExecConfig(true, "pistol_only");

	RegConsoleCmd("sm_gun", Command_Pistol);
	RegConsoleCmd("sm_guns", Command_Pistol);
	RegConsoleCmd("sm_pistol", Command_Pistol);
	RegConsoleCmd("sm_pistols", Command_Pistol);

	HookEvent("player_spawn", Event_PlayerSpawn);

	// Players already on the server when the plugin is loaded mid-game
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			ResetClient(client);
		}
	}
}

// Read the settings once the config has run (also called after a mid-game load).
// Change hooks are added here, not in OnPluginStart, so loading the config
// doesn't trigger them too and log the same invalid value twice.
public void OnConfigsExecuted() {
	static bool hooked = false;
	if (!hooked) {
		g_cvDefault.AddChangeHook(ConVar_DefaultChanged);
		g_cvBots.AddChangeHook(ConVar_BotsChanged);
		hooked = true;
	}

	UpdateDefaultWeapon();
	UpdateBotMode();
}

public void OnClientPutInServer(int client) {
	ResetClient(client);
}

// Start every player with no pick, the menu on spawn and the hint unseen
void ResetClient(int client) {
	g_ChosenWeapon[client][0] = '\0';
	g_ShowMenuOnSpawn[client] = true;
	g_PickedThisLife[client] = false;
	g_ShownHint[client] = false;
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

public void ConVar_DefaultChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	UpdateDefaultWeapon();
}

public void ConVar_BotsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	UpdateBotMode();
}

// Read a ConVar as a weapon name, accepting names without "weapon_", e.g. "deagle"
void ReadWeaponConVar(ConVar convar, char[] value, int maxlength) {
	convar.GetString(value, maxlength);
	TrimString(value);

	if (value[0] != '\0' && StrContains(value, "weapon_") != 0) {
		Format(value, maxlength, "weapon_%s", value);
	}
}

// sm_pistolonly_default: falls back to the USP-S if it isn't a menu pistol
void UpdateDefaultWeapon() {
	char value[WEAPON_NAME_LENGTH];
	ReadWeaponConVar(g_cvDefault, value, sizeof(value));

	if (FindPistol(value) == -1) {
		LogError("sm_pistolonly_default \"%s\" is not a pistol from the menu, using %s", value, FALLBACK_WEAPON);
		strcopy(value, sizeof(value), FALLBACK_WEAPON);
	}

	strcopy(g_DefaultWeapon, sizeof(g_DefaultWeapon), value);
}

// sm_pistolonly_bots: 0 = off, 1 = random, or a pistol name
void UpdateBotMode() {
	char value[WEAPON_NAME_LENGTH];
	g_cvBots.GetString(value, sizeof(value));
	TrimString(value);

	if (StrEqual(value, "0")) {
		g_BotMode = BotMode_Off;
		return;
	}

	if (StrEqual(value, "1")) {
		g_BotMode = BotMode_Random;
		return;
	}

	ReadWeaponConVar(g_cvBots, value, sizeof(value));
	if (FindPistol(value) == -1) {
		LogError("sm_pistolonly_bots \"%s\" is not 0, 1 or a pistol from the menu, using random pistols", value);
		g_BotMode = BotMode_Random;
		return;
	}

	g_BotMode = BotMode_Fixed;
	strcopy(g_BotWeapon, sizeof(g_BotWeapon), value);
}

// ---------------------------------------------------------------------------
// Spawning
// ---------------------------------------------------------------------------

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	// Wait one frame so the game's own spawn weapons don't override ours
	RequestFrame(Frame_PlayerSpawned, event.GetInt("userid"));
}

public void Frame_PlayerSpawned(any userid) {
	int client = GetClientOfUserId(userid); // 0 if they left during the frame
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsOnPlayingTeam(client)) {
		return;
	}

	if (IsFakeClient(client)) {
		GiveBotPistol(client);
		return;
	}

	if (!g_ShownHint[client]) {
		PrintMenuHint(client);
		g_ShownHint[client] = true;
	}

	// Players who haven't picked a pistol get the current default
	if (g_ChosenWeapon[client][0] == '\0') {
		GivePistol(client, g_DefaultWeapon);
	} else {
		GivePistol(client, g_ChosenWeapon[client]);
	}
	GiveArmor(client);
	g_PickedThisLife[client] = false;

	if (g_ShowMenuOnSpawn[client]) {
		g_PistolMenu.Display(client, MENU_TIME_FOREVER);
	}
}

// Bots get a pistol and armor based on sm_pistolonly_bots
void GiveBotPistol(int client) {
	if (g_BotMode == BotMode_Off) {
		return;
	}

	if (g_BotMode == BotMode_Random) {
		GivePistol(client, PISTOLS[GetRandomInt(0, sizeof(PISTOLS) - 1)].weapon);
	} else {
		GivePistol(client, g_BotWeapon);
	}

	GiveArmor(client);
}

// ---------------------------------------------------------------------------
// Weapons
// ---------------------------------------------------------------------------

// Strip the player's weapons, then give a knife and the pistol
void GivePistol(int client, const char[] weapon) {
	StripWeapons(client);
	GivePlayerItem(client, "weapon_knife");

	// Pistols that share a loadout slot (P2000/USP-S, P250/CZ75, Deagle/R8 ...)
	// are swapped for the one in the player's inventory. Without a T/CT team
	// the game has no loadout to use, so the plain weapon is given instead.
	int team = GetEntProp(client, Prop_Send, "m_iTeamNum");
	SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_NONE);
	int entity = GivePlayerItem(client, weapon);
	SetEntProp(client, Prop_Send, "m_iTeamNum", team);

	// Log it if the game still gave a different pistol
	int index = FindPistol(weapon);
	if (entity != -1 && index != -1) {
		int given = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if (given != PISTOLS[index].defindex) {
			LogError("Asked for %s (item %d) but %N got item %d", weapon, PISTOLS[index].defindex, client, given);
		}
	}
}

// Remove and delete everything in slots 0-3 (slot 4, the bomb, is kept)
void StripWeapons(int client) {
	for (int slot = 0; slot <= 3; slot++) {
		int entity;

		// A slot can hold several items (e.g. grenades)
		while ((entity = GetPlayerWeaponSlot(client, slot)) != -1) {
			if (!RemovePlayerItem(client, entity)) {
				break;
			}
			AcceptEntityInput(entity, "Kill");
		}
	}
}

void GiveArmor(int client) {
	SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
	SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
}

// Position of a weapon in PISTOLS, or -1 if it isn't a menu pistol
int FindPistol(const char[] weapon) {
	for (int i = 0; i < sizeof(PISTOLS); i++) {
		if (StrEqual(PISTOLS[i].weapon, weapon)) {
			return i;
		}
	}
	return -1;
}

bool IsOnPlayingTeam(int client) {
	int team = GetClientTeam(client);
	return team == CS_TEAM_T || team == CS_TEAM_CT;
}

// ---------------------------------------------------------------------------
// Menu and command
// ---------------------------------------------------------------------------

void PrintMenuHint(int client) {
	PrintToChat(client, "Type !gun, !guns, !pistol or !pistols to choose a new pistol");
}

public Action Command_Pistol(int client, int args) {
	if (client == 0) {
		ReplyToCommand(client, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	g_ShowMenuOnSpawn[client] = true;

	if (g_PickedThisLife[client]) {
		PrintToChat(client, "Pistol menu will appear next time you spawn.");
	} else {
		g_PistolMenu.Display(client, MENU_TIME_FOREVER);
	}

	return Plugin_Handled;
}

Menu BuildPistolMenu() {
	Menu menu = new Menu(MenuHandler_Pistol);
	menu.SetTitle("Pistol Menu:");
	menu.ExitButton = false;

	menu.AddItem(MENU_ITEM_KEEP, "Keep current pistol");
	for (int i = 0; i < sizeof(PISTOLS); i++) {
		menu.AddItem(PISTOLS[i].weapon, PISTOLS[i].name);
	}

	return menu;
}

public int MenuHandler_Pistol(Menu menu, MenuAction action, int client, int item) {
	if (action != MenuAction_Select) {
		return 0;
	}

	char weapon[WEAPON_NAME_LENGTH];
	menu.GetItem(item, weapon, sizeof(weapon));

	if (g_cvDebug.BoolValue) {
		PrintToConsole(client, "[Pistol Only] Menu item %d: %s", item, weapon);
	}

	// Keep the current pistol and stop showing the menu on spawn
	if (StrEqual(weapon, MENU_ITEM_KEEP)) {
		g_ShowMenuOnSpawn[client] = false;
		PrintMenuHint(client);
		return 0;
	}

	// Remember the pick; dead players and spectators get it on their next spawn
	strcopy(g_ChosenWeapon[client], sizeof(g_ChosenWeapon[]), weapon);
	if (!IsPlayerAlive(client) || !IsOnPlayingTeam(client)) {
		return 0;
	}

	GivePistol(client, weapon);
	g_PickedThisLife[client] = true;
	return 0;
}
