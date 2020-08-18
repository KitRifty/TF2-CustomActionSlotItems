#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <actionslotitems>

#define PLUGIN_VERSION "1.0.0"

#pragma newdecls required

public Plugin myinfo =
{
	name = "[TF2] Custom Action Slot Items",
	author = "KitRifty",
	description = "Give players custom items in their action slot!",
	version = PLUGIN_VERSION,
	url = ""
};

#define TFWeaponSlot_Action 9

#define EF_BONEMERGE 0x1 
#define	EF_BONEMERGE_FASTCULL 0x80

#define FSOLID_NOT_SOLID 0

#define COLLISION_GROUP_WEAPON 5

#define EF_NODRAW 0x20

#define OBS_MODE_IN_EYE 4

int g_BaseAnimatingStudioHdrOffset;
Handle g_CStudioHdrLookupSequenceSDKCall;
Handle g_BaseAnimatingResetSequenceSDKCall;
Handle g_PlayerWeaponSwitchSDKCall;

// "mp_playgesture: unknown sequence or act"
Handle g_PlayerPlayGestureSDKCall; 

#define ASI_PLUGIN

#include "actionslotitems/base.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("actionslotitems");

	TheActionSlotItems.AskPluginLoad2(myself, late, error, err_max);

	CreateNative("ActionSlotItems_RegisterClass", Native_RegisterClass);
	CreateNative("ActionSlotItems_RegisterClassHook", Native_RegisterClassHook);
	CreateNative("ActionSlotItems_GetClassCanCharge", Native_GetClassCanCharge);
	CreateNative("ActionSlotItems_SetClassCanCharge", Native_SetClassCanCharge);
	CreateNative("ActionSlotItems_GetClassCanReload", Native_GetClassCanReload);
	CreateNative("ActionSlotItems_SetClassCanReload", Native_SetClassCanReload);
	CreateNative("ActionSlotItems_GetClassViewModel", Native_GetClassViewModelModel);
	CreateNative("ActionSlotItems_SetClassViewModel", Native_SetClassViewModelModel);
	CreateNative("ActionSlotItems_GetClassViewModelOffset", Native_GetClassViewModelOffset);
	CreateNative("ActionSlotItems_SetClassViewModelOffset", Native_SetClassViewModelOffset);
	CreateNative("ActionSlotItems_GetClassViewModelAngles", Native_GetClassViewModelAngles);
	CreateNative("ActionSlotItems_SetClassViewModelAngles", Native_SetClassViewModelAngles);
	CreateNative("ActionSlotItems_GetClassViewModelScale", Native_GetClassViewModelScale);
	CreateNative("ActionSlotItems_SetClassViewModelScale", Native_SetClassViewModelScale);
	CreateNative("ActionSlotItems_GetClassRightHandPoseParameter", Native_GetClassRightHandPoseParameter);
	CreateNative("ActionSlotItems_SetClassRightHandPoseParameter", Native_SetClassRightHandPoseParameter);
	CreateNative("ActionSlotItems_GetPlayerCustomActionSlotItem", Native_GetPlayerCustomActionSlotItem);
	CreateNative("ActionSlotItems_PlayerPlayGesture", Native_PlayerPlayGesture);
	CreateNative("ActionSlotItems_Give", Native_GiveActionSlotItem);

	CreateNative("ActionSlotItem.Clip1.get", Native_GetActionSlotItemClip);
	CreateNative("ActionSlotItem.Clip1.set", Native_SetActionSlotItemClip);
	CreateNative("ActionSlotItem.NextPrimaryAttack.get", Native_GetActionSlotItemNextPrimaryAttack);
	CreateNative("ActionSlotItem.NextPrimaryAttack.set", Native_SetActionSlotItemNextPrimaryAttack);
	CreateNative("ActionSlotItem.ViewModel.get", Native_GetActionSlotItemViewModel);
	CreateNative("ActionSlotItem.Charging.get", Native_GetActionSlotItemIsCharging);
	CreateNative("ActionSlotItem.Reloading.get", Native_GetActionSlotItemIsReloading);
	CreateNative("ActionSlotItem.ReloadFinishTime.get", Native_GetActionSlotItemReloadFinishTime);
	CreateNative("ActionSlotItem.ReloadFinishTime.set", Native_SetActionSlotItemReloadFinishTime);
	CreateNative("ActionSlotItem.IsValid", Native_IsActionSlotItemValid);
	CreateNative("ActionSlotItem.GetClassname", Native_GetActionSlotItemClassname);
}

public void OnPluginStart()
{
	Handle hConfig = LoadGameConfigFile("sdkhooks.games");
	if (hConfig == INVALID_HANDLE) SetFailState("Couldn't find sdkhooks.games gamedata!");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf( hConfig, SDKConf_Virtual, "Weapon_Switch" );
	PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_PlayerWeaponSwitchSDKCall = EndPrepSDKCall()) == INVALID_HANDLE)
		SetFailState("Failed to create Weapon_Switch SDKCall!");

	delete hConfig;

	hConfig = LoadGameConfigFile("actionslotitems.games");
	if (hConfig == INVALID_HANDLE) SetFailState("Couldn't find actionslotitems.games gamedata!");

	g_BaseAnimatingStudioHdrOffset = GameConfGetOffset(hConfig, "CBaseAnimating::m_pStudioHdr");

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CStudioHdr::LookupSequence");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_CStudioHdrLookupSequenceSDKCall = EndPrepSDKCall()) == INVALID_HANDLE)
		SetFailState("Failed to retrieve CStudioHdr::LookupSequence signature");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimating::ResetSequence");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_BaseAnimatingResetSequenceSDKCall = EndPrepSDKCall()) == INVALID_HANDLE)
		SetFailState("Failed to retrieve CBaseAnimating::ResetSequence signature");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CTFPlayer::PlayGesture");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	if ((g_PlayerPlayGestureSDKCall = EndPrepSDKCall()) == INVALID_HANDLE)
	{
		LogError("Failed to retrieve CTFPlayer::PlayGesture signature!");
	}

	delete hConfig;

	RegAdminCmd("sm_casi_give", Command_GiveActionSlotItem, ADMFLAG_CHEATS);
	RegAdminCmd("sm_casi_setviewmodel", Command_SetViewModel, ADMFLAG_CHEATS);
	RegAdminCmd("sm_casi_setviewmodelscale", Command_SetViewModelScale, ADMFLAG_CHEATS);
	RegAdminCmd("sm_casi_setviewmodeloffset", Command_SetViewModelOffset, ADMFLAG_CHEATS);
	RegAdminCmd("sm_casi_setviewmodelangles", Command_SetViewModelAngles, ADMFLAG_CHEATS);

	TheActionSlotItems.OnPluginStart();
}

public void OnMapStart()
{
	TheActionSlotItems.OnMapStart();
}

public void OnEntityCreated(int ent, const char[] classname)
{
	TheActionSlotItems.OnEntityCreated(ent, classname);
}

public void OnEntityDestroyed(int ent)
{
	TheActionSlotItems.OnEntityDestroyed(ent);
}

public void OnGameFrame()
{
	TheActionSlotItems.OnGameFrame();
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	Action result = Plugin_Continue;
	Action tempResult = Plugin_Continue;
	if ((tempResult = TheActionSlotItems.OnClientCommandKeyValues(client, kv)) > result)
		result = tempResult;

	if (result == Plugin_Stop)
		return result;

	return result;
}

public void OnClientPutInServer(int client)
{
	TheActionSlotItems.OnClientPutInServer(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	TheActionSlotItems.OnPlayerRunCmdPost(client, buttons, impulse, vel, angles, weapon, subtype, cmdnum, tickcount, seed, mouse);
}

static Action Command_GiveActionSlotItem(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_casi_give <classname> <charges>");
		return Plugin_Handled;
	}

	int charges = 3;
	if (args > 1)
	{
		char sArg[16];
		GetCmdArg(2, sArg, sizeof(sArg));
		int arg = StringToInt(sArg);
		if (arg > 0)
			charges = arg;
	}

	char itemClassname[256];
	GetCmdArg(1, itemClassname, sizeof(itemClassname));

	int classIndex = TheActionSlotItems.FindClass(itemClassname);
	if (classIndex == -1)
	{
		ReplyToCommand(client, "Custom action slot item class does not exist.");
		return Plugin_Handled;
	}

	TheActionSlotItems.GiveActionSlotItem(client, classIndex, charges);

	return Plugin_Handled;
}

static Action Command_SetViewModel(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_casi_setviewmodel <model>");
		return Plugin_Handled;
	}

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon))
	{
		ReplyToCommand(client, "You must be holding a custom action slot item first!");
		return Plugin_Handled;
	}

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
	{
		ReplyToCommand(client, "You must be holding a custom action slot item first!");
		return Plugin_Handled;
	}
	
	int weaponViewModel = EntRefToEntIndex(weaponData.ViewModelEntRef);
	if (!IsValidEntity(weaponViewModel))
		return Plugin_Handled;

	char sArg[PLATFORM_MAX_PATH];
	GetCmdArg(1, sArg, sizeof(sArg));

	int modelIndex = PrecacheModel(sArg);

	if (!modelIndex)
	{
		ReplyToCommand(client, "Invalid model specified.");
		return Plugin_Handled;
	}

	SetEntProp(weaponViewModel, Prop_Send, "m_nModelIndexOverrides", modelIndex);
	
	return Plugin_Handled;
}

static Action Command_SetViewModelScale(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_casi_setviewmodelscale <scale>");
		return Plugin_Handled;
	}

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon))
	{
		ReplyToCommand(client, "You must be holding a custom action slot item first!");
		return Plugin_Handled;
	}

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
	{
		ReplyToCommand(client, "You must be holding a custom action slot item first!");
		return Plugin_Handled;
	}

	int weaponViewModel = EntRefToEntIndex(weaponData.ViewModelEntRef);
	if (!IsValidEntity(weaponViewModel))
		return Plugin_Handled;

	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));

	SetEntPropFloat(weaponViewModel, Prop_Send, "m_flModelScale", StringToFloat(sArg));
	
	return Plugin_Handled;
}

static Action Command_SetViewModelOffset(int client, int args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage: sm_casi_setviewmodeloffset <x> <y> <z>");
		return Plugin_Handled;
	}

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon))
		return Plugin_Handled;

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
	{
		ReplyToCommand(client, "You must be holding a custom action slot item first!");
		return Plugin_Handled;
	}

	int weaponViewModel = EntRefToEntIndex(weaponData.ViewModelEntRef);
	if (!IsValidEntity(weaponViewModel))
		return Plugin_Handled;

	float offset[3];
	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));
	offset[0] = StringToFloat(sArg);
	GetCmdArg(2, sArg, sizeof(sArg));
	offset[1] = StringToFloat(sArg);
	GetCmdArg(3, sArg, sizeof(sArg));
	offset[2] = StringToFloat(sArg);

	SetEntPropVector(weaponViewModel, Prop_Send, "m_vecOrigin", offset);

	return Plugin_Handled;
}

static Action Command_SetViewModelAngles(int client, int args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage: sm_casi_setviewmodelangles <p> <y> <r>");
		return Plugin_Handled;
	}

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon))
		return Plugin_Handled;

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
	{
		ReplyToCommand(client, "You must be holding a custom action slot item first!");
		return Plugin_Handled;
	}

	int weaponViewModel = EntRefToEntIndex(weaponData.ViewModelEntRef);
	if (!IsValidEntity(weaponViewModel))
		return Plugin_Handled;

	float angles[3];
	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));
	angles[0] = StringToFloat(sArg);
	GetCmdArg(2, sArg, sizeof(sArg));
	angles[1] = StringToFloat(sArg);
	GetCmdArg(3, sArg, sizeof(sArg));
	angles[2] = StringToFloat(sArg);

	SetEntPropVector(weaponViewModel, Prop_Send, "m_angRotation", angles);

	return Plugin_Handled;
}

public int Native_RegisterClass(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	ActionSlotItemClassData classData;
	classData.Init();
	classData.Plugin = plugin;

	TheActionSlotItems.RegisterClass(classname, classData);
}

public int Native_RegisterClassHook(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");
	
	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	if (classData.Plugin != plugin)
		ThrowNativeError(0, "Cannot register a class hook for a different plugin!");

	ActionSlotItemCallbackType callbackType = view_as<ActionSlotItemCallbackType>(GetNativeCell(2));
	ActionSlotItemCallback callback = view_as<ActionSlotItemCallback>(GetNativeFunction(3));

	return view_as<int>(TheActionSlotItems.RegisterClassHook(classname, callbackType, callback));
}

public int Native_IsActionSlotItemValid(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	return TheActionSlotItems.IsCustomActionSlotItem(entity);
}

public int Native_GetClassCanCharge(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");
	
	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	return view_as<int>(classData.CanCharge);
}

public int Native_SetClassCanCharge(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");
	
	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	classData.CanCharge = view_as<bool>(GetNativeCell(2));

	TheActionSlotItems.ActionSlotItemClasses.SetArray(classIndex, classData, sizeof(classData));
}

public int Native_GetClassCanReload(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");
	
	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	return view_as<int>(classData.CanReload);
}

public int Native_SetClassCanReload(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");
	
	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	classData.CanReload = view_as<bool>(GetNativeCell(2));

	TheActionSlotItems.ActionSlotItemClasses.SetArray(classIndex, classData, sizeof(classData));
}

public int Native_GetClassViewModelModel(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	char model[PLATFORM_MAX_PATH];
	TheActionSlotItems.ActionSlotItemViewModels.GetString(classIndex, model, sizeof(model));

	SetNativeString(2, model, GetNativeCell(3));
}

public int Native_SetClassViewModelModel(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	char model[PLATFORM_MAX_PATH];
	GetNativeString(2, model, sizeof(model));

	TheActionSlotItems.ActionSlotItemViewModels.SetString(classIndex, model);
}

public int Native_GetClassViewModelOffset(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	TFClassType classType = view_as<TFClassType>(GetNativeCell(2));
	float buffer[3];
	classData.GetViewModelOffset(classType, buffer);

	SetNativeArray(3, buffer, 3);
}

public int Native_SetClassViewModelOffset(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	TFClassType classType = view_as<TFClassType>(GetNativeCell(2));
	float buffer[3];
	GetNativeArray(3, buffer, 3);

	classData.SetViewModelOffset(classType, buffer);

	TheActionSlotItems.ActionSlotItemClasses.SetArray(classIndex, classData, sizeof(classData));
}

public int Native_GetClassViewModelAngles(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	TFClassType classType = view_as<TFClassType>(GetNativeCell(2));
	float buffer[3];
	classData.GetViewModelAngles(classType, buffer);

	SetNativeArray(3, buffer, 3);
}

public int Native_SetClassViewModelAngles(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	TFClassType classType = view_as<TFClassType>(GetNativeCell(2));
	float buffer[3];
	GetNativeArray(3, buffer, 3);

	classData.SetViewModelAngles(classType, buffer);

	TheActionSlotItems.ActionSlotItemClasses.SetArray(classIndex, classData, sizeof(classData));
}

public int Native_GetClassViewModelScale(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	return view_as<int>(classData.ViewModelScale[GetNativeCell(2)]);
}

public int Native_SetClassViewModelScale(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	classData.ViewModelScale[GetNativeCell(2)] = view_as<float>(GetNativeCell(3));

	TheActionSlotItems.ActionSlotItemClasses.SetArray(classIndex, classData, sizeof(classData));
}

public int Native_GetClassRightHandPoseParameter(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	return view_as<int>(classData.RightHandPoseParameter[GetNativeCell(2)]);
}

public int Native_SetClassRightHandPoseParameter(Handle plugin, int numParams)
{
	char classname[256];
	GetNativeString(1, classname, sizeof(classname));

	int classIndex = TheActionSlotItems.FindClass(classname);
	if (classIndex == -1)
		ThrowNativeError(0, "Class does not exist.");

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

	classData.RightHandPoseParameter[GetNativeCell(2)] = view_as<float>(GetNativeCell(3));

	TheActionSlotItems.ActionSlotItemClasses.SetArray(classIndex, classData, sizeof(classData));
}

public int Native_GetPlayerCustomActionSlotItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsClientInGame(client))
		return -1;
	
	int actionSlotItem = TF2_GetPlayerActionSlotItem(client);
	if (!IsValidEntity(actionSlotItem))
		return -1;
	
	if (!TheActionSlotItems.IsCustomActionSlotItem(actionSlotItem))
		return -1;

	return actionSlotItem;
}

public int Native_PlayerPlayGesture(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	char sequence[64];
	GetNativeString(2, sequence, sizeof(sequence));

	if (g_PlayerPlayGestureSDKCall != INVALID_HANDLE)
		SDKCall(g_PlayerPlayGestureSDKCall, client, sequence);
}

public int Native_GiveActionSlotItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return -1;
	
	char classname[256];
	GetNativeString(2, classname, sizeof(classname));

	int actionSlotItemClassIndex = TheActionSlotItems.FindClass(classname);
	if (actionSlotItemClassIndex == -1)
		ThrowNativeError(0, "Weapon class does not exist!")

	int charges = GetNativeCell(3);

	return TheActionSlotItems.GiveActionSlotItem(client, actionSlotItemClassIndex, charges);
}

public int Native_GetActionSlotItemClip(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "weapon is not a valid entity!");

	if (!TheActionSlotItems.IsCustomActionSlotItem(weapon))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");
	
	return GetEntProp(weapon, Prop_Send, "m_iSpellCharges");
}

public int Native_SetActionSlotItemClip(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "weapon is not a valid entity!");

	if (!TheActionSlotItems.IsCustomActionSlotItem(weapon))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");

	SetEntProp(weapon, Prop_Send, "m_iSpellCharges", GetNativeCell(2));
}

public int Native_GetActionSlotItemNextPrimaryAttack(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "Weapon is not a valid entity!");

	if (!TheActionSlotItems.IsCustomActionSlotItem(weapon))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");
	
	return view_as<int>(GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack"));
}

public int Native_SetActionSlotItemNextPrimaryAttack(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "Weapon is not a valid entity!");

	if (!TheActionSlotItems.IsCustomActionSlotItem(weapon))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");
	
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", view_as<float>(GetNativeCell(2)));
}

public int Native_GetActionSlotItemClassname(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "weapon is not a valid entity!");
	
	if (!TheActionSlotItems.IsCustomActionSlotItem(weapon))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");

	char classname[256];
	TheActionSlotItems.GetThrowableClassname(weapon, classname, sizeof(classname));

	SetNativeString(2, classname, GetNativeCell(3));
}

public int Native_GetActionSlotItemViewModel(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "weapon is not a valid entity!");

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");
	
	return EntRefToEntIndex(weaponData.ViewModelEntRef);
}

public int Native_GetActionSlotItemIsCharging(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "weapon is not a valid entity!");

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");
	
	return weaponData.IsCharging;
}

public int Native_GetActionSlotItemIsReloading(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "weapon is not a valid entity!");

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");
	
	return weaponData.IsReloading;
}

public int Native_GetActionSlotItemReloadFinishTime(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "weapon is not a valid entity!");

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");
	
	return view_as<int>(weaponData.ReloadFinishTime);
}

public int Native_SetActionSlotItemReloadFinishTime(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	if (!IsValidEntity(weapon))
		ThrowNativeError(0, "weapon is not a valid entity!");

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(weapon, weaponData))
		ThrowNativeError(0, "Weapon must be a custom action slot item!");
	
	weaponData.ReloadFinishTime = view_as<float>(GetNativeCell(2));

	TheActionSlotItems.SetActionSlotItemWeaponData(weapon, weaponData);
}