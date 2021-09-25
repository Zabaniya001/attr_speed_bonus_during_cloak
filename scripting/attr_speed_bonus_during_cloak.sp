#include <sourcemod>

#include <sdkhooks>

#include <tf2>
#include <tf2_stocks>

#include <tf2utils>
#include <tf2attributes>
#include <tf_custom_attributes>

#include <tf2_cloakapi>
#include <tf_calcmaxspeed>

#pragma semicolon 1;
#pragma newdecls required;

#define PLUGIN_NAME         "[TF2-CA] Bonus Speed During Cloak"
#define PLUGIN_AUTHOR       "Zabaniya001"
#define PLUGIN_DESCRIPTION  "Custom attribute that utilizes Nosoop's CA framework. Gives you a bonus speed while being cloaked."
#define PLUGIN_VERSION      "1.0.0"
#define PLUGIN_URL          "https://github.com/Zabaniya001/attr_speed_bonus_during_cloak"

public Plugin myinfo = 
{
	name        =   PLUGIN_NAME,
	author      =   PLUGIN_AUTHOR,
	description =   PLUGIN_DESCRIPTION,
	version     =   PLUGIN_VERSION,
	url         =   PLUGIN_URL
}

// ||─────────────────────────────────────────────────────────────────────────||
// ||                             GLOBAL VARIABLES                            ||
// ||─────────────────────────────────────────────────────────────────────────||

float g_flBoostDurationCache[36];

// ||──────────────────────────────────────────────────────────────────────────||
// ||                               SOURCEMOD API                              ||
// ||──────────────────────────────────────────────────────────────────────────||

public void OnPluginStart()
{
	// Late-load Support
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(!IsClientInGame(iClient))
			continue;

		TF2CloakAPI_Hook(iClient, OnActivateInvisibilityWatch, TF2CloakAPI_OnActivateInvisibilityWatch);
	}

	return;
}

public void OnClientPutInServer(int iClient)
{
	g_flBoostDurationCache[iClient] = 0.0;

	TF2CloakAPI_Hook(iClient, OnActivateInvisibilityWatch, TF2CloakAPI_OnActivateInvisibilityWatch);

	return;
}

// ||──────────────────────────────────────────────────────────────────────────||
// ||                                EVENTS                                    ||
// ||──────────────────────────────────────────────────────────────────────────||

public Action TF2CloakAPI_OnActivateInvisibilityWatch(int iClient, int iCloak, float flCloakMeter, bool& bReturnValue)
{
	float flBoostDuration = TF2CustAttr_GetFloat(iCloak, "speed boost during cloak", 0.0);

	if(!flBoostDuration)
		return Plugin_Continue;

	// It means that we were cloaked, thus we gotta disable our effects.
	if(TF2_IsPlayerInCondition(iClient, TFCond_Cloaked))
	{
		TF2CloakAPI_Unhook(iClient, OnCleanupInvisibilityWatch, TF2CloakAPI_OnCleanupInvisibilityWatch);
		TF2CloakAPI_Unhook(iClient, OnUpdateCloakMeter,         TF2CloakAPI_OnUpdateCloakMeter);

		g_flBoostDurationCache[iClient] = 0.0;

		TF2Util_UpdatePlayerSpeed(iClient);

		return Plugin_Continue;
	}

	// Internally it doesn't let you cloak unless you have more than 8%.
	if(flCloakMeter <= 8.0)
		return Plugin_Continue;

	g_flBoostDurationCache[iClient] = flBoostDuration;

	TF2Util_UpdatePlayerSpeed(iClient);

	TF2CloakAPI_Hook(iClient, OnCleanupInvisibilityWatch, TF2CloakAPI_OnCleanupInvisibilityWatch);
	TF2CloakAPI_Hook(iClient, OnUpdateCloakMeter,         TF2CloakAPI_OnUpdateCloakMeter);

	return Plugin_Continue;
}

public Action TF2CloakAPI_OnUpdateCloakMeter(int iClient, float flCloakMeter)
{
	if(flCloakMeter > 0.0)
		return Plugin_Continue;

	g_flBoostDurationCache[iClient] = 0.0;

	TF2Util_UpdatePlayerSpeed(iClient);

	TF2CloakAPI_Unhook(iClient, OnCleanupInvisibilityWatch, TF2CloakAPI_OnCleanupInvisibilityWatch);
	TF2CloakAPI_Unhook(iClient, OnUpdateCloakMeter,         TF2CloakAPI_OnUpdateCloakMeter);

	return Plugin_Continue;
}

public Action TF2CloakAPI_OnCleanupInvisibilityWatch(int iClient, int iCloak, bool bIsEventDeath)
{
	g_flBoostDurationCache[iClient] = 0.0;

	TF2Util_UpdatePlayerSpeed(iClient);

	TF2CloakAPI_Unhook(iClient, OnCleanupInvisibilityWatch, TF2CloakAPI_OnCleanupInvisibilityWatch);
	TF2CloakAPI_Unhook(iClient, OnUpdateCloakMeter,         TF2CloakAPI_OnUpdateCloakMeter);

	return Plugin_Continue;
}

public Action TF2_OnCalculateMaxSpeed(int iClient, float &flMaxSpeed) 
{
	if(!g_flBoostDurationCache[iClient])
		return Plugin_Continue;

	flMaxSpeed *= g_flBoostDurationCache[iClient];

	return Plugin_Changed;
}

// ||──────────────────────────────────────────────────────────────────────────||
// ||                                   STOCKS                                 ||
// ||──────────────────────────────────────────────────────────────────────────||

stock bool IsValidClient(int iClient)
{
    if(iClient <= 0 || iClient > MaxClients)
        return false;

    if(!IsClientInGame(iClient))
        return false;
    
    return true;
}