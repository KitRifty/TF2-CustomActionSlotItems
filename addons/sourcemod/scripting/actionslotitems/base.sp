/*
    Action Slot Item standalone base

    Engine functions/offsets used:
    - CBaseAnimating::m_pStudioHdr (offset) - g_BaseAnimatingStudioHdrOffset
    - CStudioHdr::LookupSequence (signature) - g_CStudioHdrLookupSequenceSDKCall
    - CBasePlayer::Weapon_Switch (virtual, grab from SDKHooks) - g_PlayerWeaponSwitchSDKCall
        - Used by PlayerSwitchWeapon stock
    - CBaseAnimating::ResetSequence (signature) - g_BaseAnimatingResetSequenceSDKCall
    - CTFPlayer::PlayGesture (signature, not required) - g_PlayerPlayGestureSDKCall
        - Find string "mp_playgesture: unknown sequence or act"

    Plugin hooks used (forward to TheActionSlotItems):
    - OnPluginStart
    - OnMapStart
    - OnEntityCreated
    - OnEntityDestroyed
    - OnGameFrame
    - OnClientCommandKeyValues
    - OnClientPutInServer
    - OnPlayerRunCmdPost
*/

#define ASI_DEFAULT_WEAPON_VIEWMODEL "models/workshop/weapons/c_models/stattrack.mdl"

#if defined ASI_PLUGIN

GlobalForward g_OnPlayerEquipCustomActionSlotItem;

#endif

#if !defined ASI_PLUGIN

enum
{
	ActionSlotItemAnimation_Deploy = 0,
	ActionSlotItemAnimation_Idle,
	ActionSlotItemAnimation_Charge,
	ActionSlotItemAnimation_Reload,
	ActionSlotItemAnimation_Fire
}

enum ActionSlotItemCallbackType
{
	ActionSlotItemCallbackType_OnEquip = 0,
	ActionSlotItemCallbackType_OnFire,
	ActionSlotItemCallbackType_CanFire,
	ActionSlotItemCallbackType_Think,
	ActionSlotItemCallbackType_OnDeploy,
	ActionSlotItemCallbackType_OnHolster,
	ActionSlotItemCallbackType_CanReload,
	ActionSlotItemCallbackType_OnReload,
	ActionSlotItemCallbackType_OnReloadFinish,
	ActionSlotItemCallbackType_ShouldDrawViewModel,
	ActionSlotItemCallbackType_GetViewModelAnimation,
	ActionSlotItemCallbackType_GetAmmo,
	ActionSlotItemCallbackType_SetAmmo,
	ActionSlotItemCallbackType_Max
}

typeset ActionSlotItemCallback
{
	// OnFire
	// Think
	// OnDeploy
	// OnHolster
	// OnReload
	// OnReloadFinish
	function void(ActionSlotItem weapon, int owner);

	// CanFire
	// CanReload
	function bool(ActionSlotItem weapon, int owner);	

	// ShouldDrawViewModel
	function bool(ActionSlotItem weapon, int owner, int weaponViewModel, int client);
	
	// GetViewModelAnimation
	function void(ActionSlotItem weapon, int owner, int animationType, TFClassType classType, char[] buffer, int bufferLen);

	// GetAmmo
	function int(ActionSlotItem weapon, int owner);

	// SetAmmo
	function void(ActionSlotItem weapon, int owner, int ammo);
};

#endif

enum struct ActionSlotItemClassData
{
	Handle Plugin;

	ActionSlotItemCallback OnEquipCallback;
	ActionSlotItemCallback OnFireCallback;
	ActionSlotItemCallback CanFireCallback;
	ActionSlotItemCallback ThinkCallback;
	ActionSlotItemCallback OnDeployCallback;
	ActionSlotItemCallback OnHolsterCallback;
	ActionSlotItemCallback CanReloadCallback;
	ActionSlotItemCallback OnReloadCallback;
	ActionSlotItemCallback OnReloadFinishCallback;
	ActionSlotItemCallback ShouldDrawViewModelCallback;
	ActionSlotItemCallback GetViewModelAnimationCallback;
	ActionSlotItemCallback GetAmmoCallback;
	ActionSlotItemCallback SetAmmoCallback;

	bool CanCharge;
	bool CanReload;

	float ViewModelOffsets[27];
	float ViewModelAngles[27];
	float ViewModelScale[10];

	float RightHandPoseParameter[10];

	void Init()
	{
		this.Plugin = INVALID_HANDLE;

		this.OnEquipCallback = INVALID_FUNCTION;
		this.OnFireCallback = INVALID_FUNCTION;
		this.CanFireCallback = INVALID_FUNCTION;
		this.ThinkCallback = INVALID_FUNCTION;
		this.OnDeployCallback = INVALID_FUNCTION;
		this.OnHolsterCallback = INVALID_FUNCTION;
		this.OnReloadCallback = INVALID_FUNCTION;
		this.OnReloadFinishCallback = INVALID_FUNCTION;
		this.ShouldDrawViewModelCallback = INVALID_FUNCTION;
		this.GetViewModelAnimationCallback = INVALID_FUNCTION;
		this.GetAmmoCallback = INVALID_FUNCTION;
		this.SetAmmoCallback = INVALID_FUNCTION;

		this.CanCharge = false;
		this.CanReload = false;

		for (TFClassType classType = view_as<TFClassType>(1); classType <= view_as<TFClassType>(9); classType++)
		{
			this.SetViewModelOffset(classType, NULL_VECTOR);
			this.SetViewModelAngles(classType, NULL_VECTOR);

			this.ViewModelScale[view_as<int>(classType)] = 1.0;
			this.RightHandPoseParameter[view_as<int>(classType)] = 0.0;
		}
	}

	void GetViewModelOffset( TFClassType classType, float offset[3] )
	{
		int index = (view_as<int>(classType) - 1) * 3;
		for (int i = 0; i < 3; i++)
			offset[i] = this.ViewModelOffsets[index + i];
	}

	void SetViewModelOffset( TFClassType classType, const float offset[3] )
	{
		int index = (view_as<int>(classType) - 1) * 3;
		for (int i = 0; i < 3; i++)
			this.ViewModelOffsets[index + i] = offset[i];
	}

	void SetViewModelOffsetAll( const float offset[3] )
	{
		for (TFClassType classType = view_as<TFClassType>(1); classType <= view_as<TFClassType>(9); classType++)
		{
			this.SetViewModelOffset(classType, offset);
		}
	}

	void GetViewModelAngles( TFClassType classType, float angles[3] )
	{
		int index = (view_as<int>(classType) - 1) * 3;
		for (int i = 0; i < 3; i++)
			angles[i] = this.ViewModelAngles[index + i];
	}

	void SetViewModelAngles( TFClassType classType, const float angles[3] )
	{
		int index = (view_as<int>(classType) - 1) * 3;
		for (int i = 0; i < 3; i++)
			this.ViewModelAngles[index + i] = angles[i];
	}

	void SetViewModelAnglesAll( const float angles[3] )
	{
		for (TFClassType classType = view_as<TFClassType>(1); classType <= view_as<TFClassType>(9); classType++)
		{
			this.SetViewModelAngles(classType, angles);
		}
	}

	void SetViewModelScaleAll( const float scale )
	{
		for (TFClassType classType = view_as<TFClassType>(1); classType <= view_as<TFClassType>(9); classType++)
		{
			this.ViewModelScale[view_as<int>(classType)] = scale;
		}
	}

	int GetViewModelAnimation( int actionSlotItem, int animationType, TFClassType classType, char[] buffer, int bufferLen )
	{
		if ((this.Plugin != INVALID_HANDLE && GetPluginStatus(this.Plugin) != Plugin_Running) ||
			this.GetViewModelAnimationCallback == INVALID_FUNCTION)
			return -1;

		int owner = GetEntPropEnt(actionSlotItem, Prop_Send, "m_hOwnerEntity");
		if (!IsValidEntity(owner))
			return -1;

		int viewModel = GetEntPropEnt(actionSlotItem, Prop_Send, "m_hViewModel");
		if (!IsValidEntity(viewModel))
			return -1;

		strcopy(buffer, bufferLen, "");

		Call_StartFunction(this.Plugin, this.GetViewModelAnimationCallback);
		Call_PushCell(actionSlotItem);
		Call_PushCell(owner);
		Call_PushCell(animationType);
		Call_PushCell(classType);
		Call_PushStringEx(buffer, bufferLen, 0, SM_PARAM_COPYBACK);
		Call_PushCell(bufferLen);
		Call_Finish();

		return CBaseAnimating_LookupSequence(viewModel, buffer);
	}

	bool StartClassHookFunctionCall(ActionSlotItemCallbackType callbackType)
	{
		if (this.Plugin != INVALID_HANDLE && GetPluginStatus(this.Plugin) != Plugin_Running)
			return false;

		ActionSlotItemCallback callback = INVALID_FUNCTION;

		switch (callbackType)
		{
			case ActionSlotItemCallbackType_OnEquip:
			{
				callback = this.OnEquipCallback;
			}
			case ActionSlotItemCallbackType_OnFire:
			{
				callback = this.OnFireCallback;
			}
			case ActionSlotItemCallbackType_CanFire:
			{
				callback = this.CanFireCallback;
			}
			case ActionSlotItemCallbackType_Think:
			{
				callback = this.ThinkCallback;
			}
			case ActionSlotItemCallbackType_OnDeploy:
			{
				callback = this.OnDeployCallback;
			}
			case ActionSlotItemCallbackType_OnHolster:
			{
				callback = this.OnHolsterCallback;
			}
			case ActionSlotItemCallbackType_CanReload:
			{
				callback = this.CanReloadCallback;
			}
			case ActionSlotItemCallbackType_OnReload:
			{
				callback = this.OnReloadCallback;
			}
			case ActionSlotItemCallbackType_OnReloadFinish:
			{
				callback = this.OnReloadFinishCallback;
			}
			case ActionSlotItemCallbackType_ShouldDrawViewModel:
			{
				callback = this.ShouldDrawViewModelCallback;
			}
			case ActionSlotItemCallbackType_GetViewModelAnimation:
			{
				callback = this.GetViewModelAnimationCallback;
			}
			case ActionSlotItemCallbackType_GetAmmo:
			{
				callback = this.GetAmmoCallback;
			}
			case ActionSlotItemCallbackType_SetAmmo:
			{
				callback = this.SetAmmoCallback;
			}
		}

		if (callback == INVALID_FUNCTION)
			return false;
		
		Call_StartFunction(this.Plugin, callback);

		return true;
	}
}

enum struct ActionSlotItemWeaponData
{
	int WeaponEntRef;
	int ClassIndex;
	int BaseViewModelEntRef;
	int ViewModelEntRef;
	bool PlayDeployAnimation;
	bool IsCharging;
	bool IsReloading;
	float ReloadFinishTime;
}

enum struct ActionSlotItemsManager
{
	ArrayList ActionSlotItemClasses;
	ArrayList ActionSlotItemClassnames;
	StringMap ActionSlotItems;
	ArrayList ActionSlotItemEntRefs;
	ArrayList ActionSlotItemViewModels;

#if defined ASI_PLUGIN

    void AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
    {
        g_OnPlayerEquipCustomActionSlotItem = new GlobalForward("OnPlayerEquipCustomActionSlotItem", ET_Ignore, Param_Cell, Param_Cell);
    }

#endif

	void OnPluginStart()
	{
		this.ActionSlotItemClasses = new ArrayList(sizeof(ActionSlotItemClassData));
		this.ActionSlotItemClassnames = new ArrayList(256);
		this.ActionSlotItems = new StringMap();
		this.ActionSlotItemEntRefs = new ArrayList();
		this.ActionSlotItemViewModels = new ArrayList(PLATFORM_MAX_PATH);

		{
			ActionSlotItemClassData baseClass;
			baseClass.Init();
			this.RegisterClass("base", baseClass);
		}

		{
			ActionSlotItemClassData baseClass;
			baseClass.Init();
			baseClass.CanCharge = true;
			this.RegisterClass("base_charge", baseClass);
		}
		
		// Late load compensation.
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			this.OnClientPutInServer(i);
		}
	}

	bool SetClassWeaponViewModel(const char[] classname, const char[] modelPath)
	{
		int classIndex = this.FindClass(classname);
		if (classIndex == -1)
			return false;

		this.ActionSlotItemViewModels.SetString(classIndex, modelPath);
		return true;
	}

	void OnMapStart()
	{
		this.ActionSlotItems.Clear();
		this.ActionSlotItemEntRefs.Clear();
	}

	void OnClientPutInServer(int client)
	{
		SDKHook(client, SDKHook_WeaponSwitchPost, TheActionSlotItems_OnWeaponSwitchPost);
		SDKHook(client, SDKHook_WeaponDropPost, TheActionSlotItems_OnWeaponDropPost);
	}

	void OnEntityCreated(int ent, const char[] classname)
	{
		if (!IsValidEntity(ent))
			return;
	}

	void OnEntityDestroyed(int entity)
	{
		ActionSlotItemWeaponData weaponData;
		if (entity > 0 && IsValidEntity(entity) && this.GetActionSlotItemWeaponData(entity, weaponData))
		{
			char sId[32];
			IntToString(weaponData.WeaponEntRef, sId, sizeof(sId));

			this.ActionSlotItems.Remove(sId);

			int extraWearable = EntRefToEntIndex(weaponData.BaseViewModelEntRef);
			if (IsValidEntity(extraWearable))
			{
				RemoveEntity(extraWearable);
			}

			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (IsValidEntity(owner) && GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon") == entity)
			{
				PlayerSwitchToValidWeapon(owner);
			}

			int index = this.ActionSlotItemEntRefs.FindValue(weaponData.WeaponEntRef);
			if (index != -1)
				this.ActionSlotItemEntRefs.Erase(index);
		}
	}

	void OnGameFrame()
	{
		char animationBuffer[64];

		for (int i = 0; i < this.ActionSlotItemEntRefs.Length; i++)
		{
			int weapon = EntRefToEntIndex(this.ActionSlotItemEntRefs.Get(i));
			if (weapon == INVALID_ENT_REFERENCE)
				continue;

			ActionSlotItemWeaponData weaponData;
			if (!this.GetActionSlotItemWeaponData(weapon, weaponData))
				continue;

			ActionSlotItemClassData classData;
			this.ActionSlotItemClasses.GetArray(weaponData.ClassIndex, classData, sizeof(classData));

			int ownerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
			int viewModel = -1;
			if (IsValidEntity(ownerEntity))
			{
				viewModel = GetEntPropEnt(ownerEntity, Prop_Send, "m_hViewModel");

				if (GetEntPropEnt(ownerEntity, Prop_Send, "m_hActiveWeapon") == weapon)
				{
					if (GetGameTime() >= GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack") && GetEntProp(weapon, Prop_Send, "m_iSpellCharges") == 0)
					{
						// Force weapon switch.
						PlayerSwitchToValidWeapon(ownerEntity);

						continue;
					}

					int idleSequence = -1;
					if (IsValidEntity(viewModel) && (idleSequence = classData.GetViewModelAnimation(weapon, ActionSlotItemAnimation_Idle, TF2_GetPlayerClass(ownerEntity), animationBuffer, sizeof(animationBuffer))) == -1)
					{
						// Have different animations for Spy's viewmodels.
						// The animations of the Spy has the left arm covering the left side of the screen
						// so we use a different animation instead.
						switch (TF2_GetPlayerClass(ownerEntity))
						{
							case TFClass_Spy:
							{
								idleSequence = CBaseAnimating_LookupSequence(viewModel, "melee_allclass_idle");
							}
							default:
							{
								idleSequence = CBaseAnimating_LookupSequence(viewModel, "throw_idle");
							}
						}
					}

					// Set this so ItemPostFrame() is always called while this weapon is out.
					// ItemPostFrame() on the spellbook removes green flame effect if m_bFiredAttack is false.
					SetEntPropFloat(ownerEntity, Prop_Send, "m_flNextAttack", 0.0);
					SetEntProp(weapon, Prop_Send, "m_bFiredAttack", 0);

					// Prevent the spellbook from switching out or firing automatically.
					SetEntPropFloat(weapon, Prop_Send, "m_flTimeNextSpell", GetGameTime() + 666.66);

					int oldSequence = GetEntProp(viewModel, Prop_Send, "m_nSequence");
					int desiredSequence = -1;
					float desiredPlaybackRate = 1.0;
					bool restartSequence = false;

					if (weaponData.PlayDeployAnimation)
					{
						if ((desiredSequence = classData.GetViewModelAnimation(weapon, ActionSlotItemAnimation_Deploy, TF2_GetPlayerClass(ownerEntity), animationBuffer, sizeof(animationBuffer))) == -1)
						{
							switch (TF2_GetPlayerClass(ownerEntity))
							{
								case TFClass_Spy:
								{
									desiredSequence = CBaseAnimating_LookupSequence(viewModel, "melee_allclass_draw");
								}
								default:
								{
									desiredSequence = CBaseAnimating_LookupSequence(viewModel, "throw_draw");
								}
							}
						}
						
						weaponData.PlayDeployAnimation = false;

						this.SetActionSlotItemWeaponData(weapon, weaponData);
					}

					if (weaponData.IsReloading)
					{
						if (GetGameTime() >= weaponData.ReloadFinishTime)
						{
							weaponData.IsReloading = false;

							if (classData.StartClassHookFunctionCall(ActionSlotItemCallbackType_OnReloadFinish))
							{
								Call_PushCell(weapon);
								Call_PushCell(ownerEntity);
								Call_Finish();
							}

							this.SetActionSlotItemWeaponData(weapon, weaponData);
						}
					}
					
					if (desiredSequence == -1)
					{
						// Only set the idle animation if we're not in a busy sequence.
						if (oldSequence != idleSequence && GetEntPropFloat(viewModel, Prop_Data, "m_flCycle") >= 1.0 && GetEntProp(weapon, Prop_Send, "m_iSpellCharges") != 0)
						{
							desiredSequence = idleSequence;
						}
					}

					if (desiredSequence != -1 && (restartSequence || oldSequence != desiredSequence))
					{
						// Is setting just the m_nSequence prop enough?
						// Even though CBaseAnimating::ResetSequence() also sets animation parity, player's viewmodel is predicted
						// so parity doesn't get checked anyways for a restarted sequence. Wtf.
						SDKCall(g_BaseAnimatingResetSequenceSDKCall, viewModel, desiredSequence);
						SetEntPropFloat(viewModel, Prop_Data, "m_flCycle", 0.0);
					}

					SetEntPropFloat(viewModel, Prop_Send, "m_flPlaybackRate", desiredPlaybackRate);

					if (classData.StartClassHookFunctionCall(ActionSlotItemCallbackType_Think))
					{
						Call_PushCell(weapon);
						Call_PushCell(ownerEntity);
						Call_Finish();
					}
				}
				else 
				{
					if (weaponData.IsCharging)
					{
						weaponData.IsCharging = false;
						this.SetActionSlotItemWeaponData(weapon, weaponData);
					}

					if (weaponData.IsReloading)
					{
						weaponData.IsReloading = false;
					}
				}
			}
		}
	}

    void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
    {
        if (IsPlayerAlive(client))
        {
            int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            if (IsValidEntity(activeWeapon) && this.IsCustomActionSlotItem(activeWeapon))
            {
                char animationBuffer[64];

                ActionSlotItemWeaponData actionSlotItemData;
                this.GetActionSlotItemWeaponData(activeWeapon, actionSlotItemData);

                ActionSlotItemClassData actionSlotItemClassData;
                this.ActionSlotItemClasses.GetArray(actionSlotItemData.ClassIndex, actionSlotItemClassData, sizeof(actionSlotItemClassData));

                int viewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");

                if (!actionSlotItemData.IsReloading && actionSlotItemClassData.CanReload)
                {
                    bool wantsToReload = (buttons & IN_RELOAD) > 0 || GetEntProp(activeWeapon, Prop_Send, "m_iSpellCharges") == 0;

                    if ( wantsToReload && GetGameTime() >= GetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack"))
                    {
                        bool canReload = false;
                        if (actionSlotItemClassData.StartClassHookFunctionCall(ActionSlotItemCallbackType_CanReload))
                        {
                            Call_PushCell(activeWeapon);
                            Call_PushCell(client);
                            Call_Finish(canReload);
                        }

                        if (canReload)
                        {
                            actionSlotItemData.IsReloading = true;
                            actionSlotItemData.ReloadFinishTime = GetGameTime();

                            if (IsValidEntity(viewModel))
                            {
                                int sequence = actionSlotItemClassData.GetViewModelAnimation(activeWeapon, ActionSlotItemAnimation_Reload, TF2_GetPlayerClass(client), animationBuffer, sizeof(animationBuffer));
                                if (sequence != -1)
                                {
                                    SDKCall(g_BaseAnimatingResetSequenceSDKCall, viewModel, sequence);
                                    SetEntPropFloat(viewModel, Prop_Data, "m_flCycle", 0.0);
                                }
                            }

                            if (actionSlotItemClassData.StartClassHookFunctionCall(ActionSlotItemCallbackType_OnReload))
                            {
                                Call_PushCell(activeWeapon);
                                Call_PushCell(client);
                                Call_Finish();
                            }

                            this.SetActionSlotItemWeaponData(activeWeapon, actionSlotItemData);
                        }
                    }
                }

                if (!actionSlotItemData.IsReloading)
                {
                    bool wantsToAttack = (buttons & IN_ATTACK) > 0;

                    if (actionSlotItemClassData.CanCharge)
                    {
                        if ( actionSlotItemData.IsCharging )
                        {
                            if (!wantsToAttack)
                            {
                                actionSlotItemData.IsCharging = false;
                                this.SetActionSlotItemWeaponData(activeWeapon, actionSlotItemData);

                                SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);

                                if (IsValidEntity(viewModel))
                                {
                                    int sequence = actionSlotItemClassData.GetViewModelAnimation(activeWeapon, ActionSlotItemAnimation_Fire, TF2_GetPlayerClass(client), animationBuffer, sizeof(animationBuffer));
                                    if (sequence == -1)
                                        sequence = CBaseAnimating_LookupSequence(viewModel, "throw_fire");

                                    if (sequence != -1)
                                    {
                                        SDKCall(g_BaseAnimatingResetSequenceSDKCall, viewModel, sequence);
                                        SetEntPropFloat(viewModel, Prop_Data, "m_flCycle", 0.0);
                                    }
                                }

                                if (actionSlotItemClassData.StartClassHookFunctionCall(ActionSlotItemCallbackType_OnFire))
                                {
                                    Call_PushCell(activeWeapon);
                                    Call_PushCell(client);
                                    Call_Finish();
                                }
                                else 
                                {
                                    if (g_PlayerPlayGestureSDKCall != INVALID_HANDLE)
                                        SDKCall(g_PlayerPlayGestureSDKCall, client, "ACT_MP_THROW");
                                }
                            }
                            else 
                            {
                                if (IsValidEntity(viewModel))
                                {
                                    int sequence = actionSlotItemClassData.GetViewModelAnimation(activeWeapon, ActionSlotItemAnimation_Charge, TF2_GetPlayerClass(client), animationBuffer, sizeof(animationBuffer));
                                    if (sequence == -1)
                                        sequence = CBaseAnimating_LookupSequence(viewModel, "spell_draw");

                                    if (sequence != -1)
                                    {
                                        SDKCall(g_BaseAnimatingResetSequenceSDKCall, viewModel, sequence);
                                        SetEntPropFloat(viewModel, Prop_Data, "m_flCycle", 0.0);
                                    }
                                }
                            }
                        }
                        else 
                        {
                            if (wantsToAttack && GetGameTime() >= GetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack"))
                            {
                                bool canFire = GetEntProp(activeWeapon, Prop_Send, "m_iSpellCharges") != 0;

                                if (actionSlotItemClassData.StartClassHookFunctionCall(ActionSlotItemCallbackType_CanFire))
                                {
                                    Call_PushCell(activeWeapon);
                                    Call_PushCell(client);
                                    Call_Finish(canFire);
                                }

                                if (canFire)
                                {
                                    if (IsValidEntity(viewModel))
                                    {
                                        int sequence = actionSlotItemClassData.GetViewModelAnimation(activeWeapon, ActionSlotItemAnimation_Charge, TF2_GetPlayerClass(client), animationBuffer, sizeof(animationBuffer));
                                        if (sequence == -1)
                                            sequence = CBaseAnimating_LookupSequence(viewModel, "spell_draw");

                                        if (sequence != -1)
                                        {
                                            SDKCall(g_BaseAnimatingResetSequenceSDKCall, viewModel, sequence);
                                            SetEntPropFloat(viewModel, Prop_Data, "m_flCycle", 0.0);
                                        }
                                    }

                                    actionSlotItemData.IsCharging = true;
                                    this.SetActionSlotItemWeaponData(activeWeapon, actionSlotItemData);
                                }
                            }
                        }
                    }
                    else
                    {
                        if (wantsToAttack && GetGameTime() >= GetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack"))
                        {
                            bool canFire = GetEntProp(activeWeapon, Prop_Send, "m_iSpellCharges") != 0;

                            if (actionSlotItemClassData.StartClassHookFunctionCall(ActionSlotItemCallbackType_CanFire))
                            {
                                Call_PushCell(activeWeapon);
                                Call_PushCell(client);
                                Call_Finish(canFire);
                            }

                            if (canFire)
                            {
                                SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);

                                if (IsValidEntity(viewModel))
                                {
                                    int sequence = actionSlotItemClassData.GetViewModelAnimation(activeWeapon, ActionSlotItemAnimation_Fire, TF2_GetPlayerClass(client), animationBuffer, sizeof(animationBuffer));
                                    if (sequence == -1)
                                        sequence = CBaseAnimating_LookupSequence(viewModel, "throw_fire");

                                    if (sequence != -1)
                                    {
                                        SDKCall(g_BaseAnimatingResetSequenceSDKCall, viewModel, sequence);
                                        SetEntPropFloat(viewModel, Prop_Data, "m_flCycle", 0.0);
                                    }
                                }

                                if (actionSlotItemClassData.StartClassHookFunctionCall(ActionSlotItemCallbackType_OnFire))
                                {
                                    Call_PushCell(activeWeapon);
                                    Call_PushCell(client);
                                    Call_Finish();
                                }
                                else 
                                {
                                    if (g_PlayerPlayGestureSDKCall != INVALID_HANDLE)
                                        SDKCall(g_PlayerPlayGestureSDKCall, client, "ACT_MP_THROW");
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Action OnClientCommandKeyValues(int client, KeyValues kv)
    {
        char sectionName[128];
        kv.GetSectionName(sectionName, sizeof(sectionName));

        if (strcmp(sectionName, "+use_action_slot_item_server", false) == 0)
        {
            return this.OnPlayerUseActionSlotItem(client);
        }
        else if (strcmp(sectionName, "+inspect_server", false) == 0)
        {
            return this.OnPlayerInspectItem(client);
        }

        return Plugin_Continue;
    }

	Action OnPlayerUseActionSlotItem(int client)
	{
		int actionSlotItem = TF2_GetPlayerActionSlotItem(client);
		if (!IsValidEntity(actionSlotItem))
			return Plugin_Continue;

		if (!this.IsCustomActionSlotItem(actionSlotItem))
			return Plugin_Continue;

		if (GetGameTime() < GetEntPropFloat(actionSlotItem, Prop_Send, "m_flNextPrimaryAttack"))
			return Plugin_Handled;

		return Plugin_Continue;
	}

	Action OnPlayerInspectItem(int client)
	{
		int actionSlotItem = TF2_GetPlayerActionSlotItem(client);
		if (!IsValidEntity(actionSlotItem))
			return Plugin_Continue;

		if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != actionSlotItem)
			return Plugin_Continue;

		if (!this.IsCustomActionSlotItem(actionSlotItem))
			return Plugin_Continue;

		// For some reason the spellbook weapon can be inspected.
		// Animations are so broken on it so disable it.

		return Plugin_Handled;
	}

	int FindClass(const char[] name)
	{
		for (int i = 0; i < this.ActionSlotItemClassnames.Length; i++)
		{
			char buffer[256];
			this.ActionSlotItemClassnames.GetString(i, buffer, sizeof(buffer));

			if ( strcmp(buffer, name) == 0 )
				return i;
		}

		return -1;
	}

	int RegisterClass(const char[] classname, ActionSlotItemClassData classData)
	{
		int classIndex = this.FindClass(classname);
		if (classIndex != -1)
		{
			this.ActionSlotItemClasses.SetArray(classIndex, classData, sizeof(classData));
			return classIndex;
		}
			
		classIndex = this.ActionSlotItemClasses.PushArray(classData, sizeof(classData));
		this.ActionSlotItemClassnames.PushString(classname);
		this.ActionSlotItemViewModels.PushString(ASI_DEFAULT_WEAPON_VIEWMODEL);

		return classIndex;
	}

	bool RegisterClassHook(const char[] classname, ActionSlotItemCallbackType callbackType, ActionSlotItemCallback callback)
    {
        int classIndex = this.FindClass(classname);
        if (classIndex == -1)
            return false;
        
        ActionSlotItemClassData classData;
        this.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

        switch (callbackType)
        {
            case ActionSlotItemCallbackType_OnEquip:
            {
                classData.OnEquipCallback = callback;
            }
            case ActionSlotItemCallbackType_OnFire:
            {
                classData.OnFireCallback = callback;
            }
            case ActionSlotItemCallbackType_CanFire:
            {
                classData.CanFireCallback = callback;
            }
            case ActionSlotItemCallbackType_Think:
            {
                classData.ThinkCallback = callback;
            }
            case ActionSlotItemCallbackType_OnDeploy:
            {
                classData.OnDeployCallback = callback;
            }
            case ActionSlotItemCallbackType_OnHolster:
            {
                classData.OnHolsterCallback = callback;
            }
            case ActionSlotItemCallbackType_CanReload:
            {
                classData.CanReloadCallback = callback;
            }
            case ActionSlotItemCallbackType_OnReload:
            {
                classData.OnReloadCallback = callback;
            }
            case ActionSlotItemCallbackType_OnReloadFinish:
            {
                classData.OnReloadFinishCallback = callback;
            }
            case ActionSlotItemCallbackType_ShouldDrawViewModel:
            {
                classData.ShouldDrawViewModelCallback = callback;
            }
            case ActionSlotItemCallbackType_GetViewModelAnimation:
            {
                classData.GetViewModelAnimationCallback = callback;
            }
            case ActionSlotItemCallbackType_GetAmmo:
            {
                classData.GetAmmoCallback = callback;
            }
            case ActionSlotItemCallbackType_SetAmmo:
            {
                classData.SetAmmoCallback = callback;
            }
            default:
            {
                return false;
            }
        }

        this.ActionSlotItemClasses.SetArray(classIndex, classData, sizeof(classData));

        return true;
    }

	int GiveActionSlotItem(int client, int classIndex, int charges)
	{
		if (!IsClientInGame(client))
			return -1;

		if (classIndex < 0 || classIndex >= this.ActionSlotItemClasses.Length)
		{
			LogError("Attempted to create custom action slot item, but classIndex is invalid!");
			return -1;
		}

		ActionSlotItemClassData classData;
		this.ActionSlotItemClasses.GetArray(classIndex, classData, sizeof(classData));

		float rightHandPoseParameter = classData.RightHandPoseParameter[view_as<int>(TF2_GetPlayerClass(client))];
		char attributes[256];
		Format(attributes, sizeof(attributes), "538 ; %0.1f", rightHandPoseParameter); // righthand pose parameter

		bool forceCallSwitch = false;

		int actionSlotItem = TF2_GetPlayerActionSlotItem(client);
		if (IsValidEntity(actionSlotItem) && actionSlotItem == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			forceCallSwitch = true;

		TF2_RemovePlayerActionSlotItem(client);

		Handle spellbookItemHandle = PrepareItemHandle("tf_weapon_spellbook", 1070, 0, 0, attributes);
		if (spellbookItemHandle != INVALID_HANDLE)
		{
			int weapon = TF2Items_GiveNamedItem(client, spellbookItemHandle);

			delete spellbookItemHandle;

			if (IsValidEntity(weapon)) 
			{
				EquipPlayerWeapon(client, weapon);
				SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", true);
				SetEntProp(weapon, Prop_Send, "m_iSelectedSpellIndex", 0);
				SetEntProp(weapon, Prop_Send, "m_iSpellCharges", charges);

				ActionSlotItemWeaponData weaponData;
				weaponData.WeaponEntRef = EntIndexToEntRef(weapon);
				weaponData.ClassIndex = classIndex;
				weaponData.ViewModelEntRef = -1;
				weaponData.BaseViewModelEntRef = -1;
				weaponData.IsCharging = false;
				weaponData.IsReloading = false;
				weaponData.ReloadFinishTime = 0.0;

				this.SetActionSlotItemWeaponData(weapon, weaponData);
				this.ActionSlotItemEntRefs.Push(weaponData.WeaponEntRef);

				if (forceCallSwitch)
					TheActionSlotItems_OnWeaponSwitchPost(client, weapon);

				if (classData.StartClassHookFunctionCall(ActionSlotItemCallbackType_OnEquip))
				{
					Call_PushCell(weapon);
					Call_PushCell(client);
					Call_Finish();
				}

#if defined ASI_PLUGIN

				Call_StartForward(g_OnPlayerEquipCustomActionSlotItem);
				Call_PushCell(client);
				Call_PushCell(weapon);
				Call_Finish();

#endif

				return weapon;
			}
		}

		return -1;
	}

	int GiveActionSlotItemByClass(int client, const char[] classname, int charges)
	{
		int classIndex = this.FindClass(classname);
		if (classIndex == -1)
			return -1;
		
		return this.GiveActionSlotItem(client, classIndex, charges);
	}

	int GetPlayerCustomActionSlotItem(int client)
	{
		if (!IsClientInGame(client))
			return -1;
		
		int actionSlotItem = TF2_GetPlayerActionSlotItem(client);
		if (!IsValidEntity(actionSlotItem))
			return -1;
		
		if (!this.IsCustomActionSlotItem(actionSlotItem))
			return -1;

		return actionSlotItem;
	}

	bool GetActionSlotItemWeaponData(int weapon, ActionSlotItemWeaponData weaponData)
	{
		if (!IsValidEntity(weapon))
			return false;

		char sId[32];
		IntToString(EntIndexToEntRef(weapon), sId, sizeof(sId));

		return this.ActionSlotItems.GetArray(sId, weaponData, sizeof(weaponData));
	}

	void SetActionSlotItemWeaponData(int weapon, ActionSlotItemWeaponData weaponData)
	{
		if (!IsValidEntity(weapon))
			return;
		
		char sId[32];
		IntToString(EntIndexToEntRef(weapon), sId, sizeof(sId));

		this.ActionSlotItems.SetArray(sId, weaponData, sizeof(weaponData));
	}

	bool IsCustomActionSlotItem(int weapon)
	{
		if (!IsValidEntity(weapon))
			return false;

		ActionSlotItemWeaponData weaponData;
		return this.GetActionSlotItemWeaponData(weapon, weaponData);
	}

	void GetThrowableClassname(int weapon, char[] buffer, int bufferLen)
	{
		ActionSlotItemWeaponData weaponData;
		if (!this.GetActionSlotItemWeaponData(weapon, weaponData))
			return;

		this.ActionSlotItemClassnames.GetString(weaponData.ClassIndex, buffer, bufferLen);
	}
}

ActionSlotItemsManager TheActionSlotItems;

#if !defined ASI_PLUGIN

methodmap ActionSlotItem
{
	public ActionSlotItem(int weapon)
	{
		return view_as<ActionSlotItem>(weapon);
	}

	property int Entity
	{
		public get() { return view_as<int>(this); }
	}

	property int Clip1
	{
		public get()
		{
			return GetEntProp(this.Entity, Prop_Send, "m_iSpellCharges");
		}
		public set(int clip)
		{
			SetEntProp(this.Entity, Prop_Send, "m_iSpellCharges", clip);
		}
	}

	property float NextPrimaryAttack
	{
		public get()
		{
			return GetEntPropFloat(this.Entity, Prop_Send, "m_flNextPrimaryAttack");
		}
		public set(float time)
		{
			SetEntPropFloat(this.Entity, Prop_Send, "m_flNextPrimaryAttack", time);
		}
	}

	property int ViewModel
	{
		public get()
		{
			ActionSlotItemWeaponData weaponData;
			if (!TheActionSlotItems.GetActionSlotItemWeaponData(this.Entity, weaponData))
				ThrowError("Weapon must be a custom action slot item!");
			
			return EntRefToEntIndex(weaponData.ViewModelEntRef);
		}
	}

	property bool Charging
	{
		public get()
		{
			ActionSlotItemWeaponData weaponData;
			if (!TheActionSlotItems.GetActionSlotItemWeaponData(this.Entity, weaponData))
				ThrowError("Weapon must be a custom action slot item!");
			
			return weaponData.IsCharging;
		}
	}

	property bool Reloading
	{
		public get()
		{
			ActionSlotItemWeaponData weaponData;
			if (!TheActionSlotItems.GetActionSlotItemWeaponData(this.Entity, weaponData))
				ThrowError("Weapon must be a custom action slot item!");
			
			return weaponData.IsReloading;
		}
	}

	property float ReloadFinishTime
	{
		public get()
		{
			ActionSlotItemWeaponData weaponData;
			if (!TheActionSlotItems.GetActionSlotItemWeaponData(this.Entity, weaponData))
				ThrowError("Weapon must be a custom action slot item!");
			
			return weaponData.ReloadFinishTime;
		}

		public set(float time)
		{
			ActionSlotItemWeaponData weaponData;
			if (!TheActionSlotItems.GetActionSlotItemWeaponData(this.Entity, weaponData))
				ThrowError("Weapon must be a custom action slot item!");
			
			weaponData.ReloadFinishTime = time;
		}
	}

	/**
	 * Returns whether or not the weapon is a valid custom action slot item.
	 *
	 * @return					True if the weapon is a custom action slot item; false otherwise.
	 */
	public bool IsValid()
	{
		return TheActionSlotItems.IsCustomActionSlotItem(this.Entity);
	}

	/**
	 * Retrives the action slot class of the item.
	 *
	 * @param buffer		String to store result.
	 * @param bufferLen		Size of buffer.
	 */
	public void GetClassname(char[] buffer, int bufferLen)
	{
		if (!this.IsValid())
			ThrowError("Weapon must be a custom action slot item!");
		
		TheActionSlotItems.GetThrowableClassname(this.Entity, buffer, bufferLen);
	}
}

#endif

static void TheActionSlotItems_OnWeaponSwitchPost(int client, int weapon)
{
	if (client <= 0 || client > MaxClients)
		return;

	int actionSlotItem = TF2_GetPlayerActionSlotItem(client);
	if (!IsValidEntity(actionSlotItem))
		return;

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(actionSlotItem, weaponData))
		return;

	if (weapon == actionSlotItem)
	{
		ActionSlotItemClassData classData;
		TheActionSlotItems.ActionSlotItemClasses.GetArray(weaponData.ClassIndex, classData, sizeof(classData));

		weaponData.PlayDeployAnimation = true;

		int viewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
		if (IsValidEntity(viewModel))
		{
			int weaponViewModel = EntRefToEntIndex(weaponData.ViewModelEntRef);
			if (weaponViewModel == INVALID_ENT_REFERENCE)
			{
				int parentWearable = EntRefToEntIndex(weaponData.BaseViewModelEntRef);
				if (!IsValidEntity(parentWearable))
				{
					// Create a dummy wearable to parent to.
					// We have to do this because SetParentAttachment doesn't work properly when parenting to the viewmodel directly.
					// The only solution is to keep the bonemerge property on this entity and have the actual weapon's viewmodel parent 
					// to this entity with SetParentAttachment. It's really jank, but it works.

					parentWearable = CreateEntityByName("tf_wearable_vm");

					SetEntProp(parentWearable, Prop_Send, "m_nModelIndex", PrecacheModel("models/weapons/c_models/urinejar.mdl"));
					SetEntProp(parentWearable, Prop_Send, "m_iTeamNum", GetClientTeam(client));
					SetEntProp(parentWearable, Prop_Send, "m_usSolidFlags", 0); // FSOLID_NOT_SOLID
					SetEntProp(parentWearable, Prop_Send, "m_CollisionGroup", 11); // COLLISION_GROUP_WEAPON

					// BUGFIX: Do not call EquipWearable.
					// This messes with the m_hMyWearables network vector on the player, and only 8 wearables can be rendered
					// at a time. Each call to EquipWearable pushes the wearable onto this vector. Because of this, repeated calls to 
					// EquipWearable will cause existing wearables on the player to suddenly stop drawing. We don't have to do this; 
					// just setting the m_hExtraWearableViewModel and m_hWeaponAssociatedWith is enough to get the thing to draw!

					DispatchSpawn(parentWearable);
					ActivateEntity(parentWearable);
					// SDKCall(g_PlayerEquipWearableSDKCall, client, parentWearable);
					SetEntPropEnt(parentWearable, Prop_Send, "m_hOwnerEntity", client);
					SetEntProp(parentWearable, Prop_Send, "m_fEffects", 0x1 | 0x80 | 0x20); // EF_BONEMERGE | EF_BONEMERGE_FASTCULL | EF_NODRAW
					SetEntPropEnt(actionSlotItem, Prop_Send, "m_hExtraWearableViewModel", parentWearable);
					SetEntPropEnt(parentWearable, Prop_Send, "m_hWeaponAssociatedWith", actionSlotItem);

					SetVariantString("!activator");
					AcceptEntityInput(parentWearable, "SetParent", viewModel);

					weaponData.BaseViewModelEntRef = EntIndexToEntRef(parentWearable);
				}

				if (IsValidEntity(parentWearable))
				{
					// Use a tf_wearable_vm, because it's the only entity that is rendered on the same layer as
					// tf_viewmodel.

					weaponViewModel = CreateEntityByName("tf_wearable_vm");

					if (IsValidEntity(weaponViewModel))
					{
						char model[PLATFORM_MAX_PATH];
						TheActionSlotItems.ActionSlotItemViewModels.GetString(weaponData.ClassIndex, model, sizeof(model));

						SetEntProp(weaponViewModel, Prop_Send, "m_nModelIndex", PrecacheModel(model));
						SetEntProp(weaponViewModel, Prop_Send, "m_usSolidFlags", 0); // FSOLID_NOT_SOLID
						SetEntProp(weaponViewModel, Prop_Send, "m_CollisionGroup", 11); // COLLISION_GROUP_WEAPON
						DispatchSpawn(weaponViewModel);
						ActivateEntity(weaponViewModel);
						SetEntPropEnt(weaponViewModel, Prop_Send, "m_hOwnerEntity", client);
						SetEntProp(weaponViewModel, Prop_Send, "m_fEffects", 0);
						SetEntPropEnt(weaponViewModel, Prop_Send, "m_hWeaponAssociatedWith", actionSlotItem);

						SetVariantString("!activator");
						AcceptEntityInput(weaponViewModel, "SetParent", parentWearable);
						SetVariantString("pedestal_0");
						AcceptEntityInput(weaponViewModel, "SetParentAttachment");

						float offset[3]; float angles[3];
						classData.GetViewModelOffset(TF2_GetPlayerClass(client), offset);
						classData.GetViewModelAngles(TF2_GetPlayerClass(client), angles);
						SetEntPropVector(weaponViewModel, Prop_Send, "m_vecOrigin", offset);
						SetEntPropVector(weaponViewModel, Prop_Send, "m_angRotation", angles);
						SetEntPropFloat(weaponViewModel, Prop_Send, "m_flModelScale", classData.ViewModelScale[TF2_GetPlayerClass(client)]);

						weaponData.ViewModelEntRef = EntIndexToEntRef(weaponViewModel);

						SDKHook(weaponViewModel, SDKHook_SetTransmit, TheActionSlotItems_OnViewModelSetTransmit);
					}
				}
			}
		}

		TheActionSlotItems.SetActionSlotItemWeaponData(actionSlotItem, weaponData);

		if (classData.StartClassHookFunctionCall(ActionSlotItemCallbackType_OnDeploy))
		{
			Call_PushCell(weapon);
			Call_PushCell(client);
			Call_Finish();
		}
	}
	else if (actionSlotItem == GetEntPropEnt(client, Prop_Send, "m_hLastWeapon"))
	{
		ActionSlotItemClassData classData;
		TheActionSlotItems.ActionSlotItemClasses.GetArray(weaponData.ClassIndex, classData, sizeof(classData));

		if (classData.StartClassHookFunctionCall(ActionSlotItemCallbackType_OnHolster))
		{
			Call_PushCell(weapon);
			Call_PushCell(client);
			Call_Finish();
		}
	}
}

static void TheActionSlotItems_OnWeaponDropPost(int client, int weapon)
{
	ActionSlotItemWeaponData actionSlotItemData;
	if (TheActionSlotItems.GetActionSlotItemWeaponData(weapon, actionSlotItemData))
	{
		int extraWearable = EntRefToEntIndex(actionSlotItemData.BaseViewModelEntRef);
		if (extraWearable != INVALID_ENT_REFERENCE)
		{
			RemoveEntity(extraWearable);
		}
	}
}

static Action TheActionSlotItems_OnViewModelSetTransmit(int entity, int client)
{
	int ownerEntity = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(ownerEntity))
		return Plugin_Continue;

	int actionSlotItem = TF2_GetPlayerActionSlotItem(ownerEntity);
	if (!IsValidEntity(actionSlotItem))
		return Plugin_Continue;

	if (actionSlotItem != GetEntPropEnt(ownerEntity, Prop_Send, "m_hActiveWeapon") ||
		TF2_IsPlayerInCondition(ownerEntity, TFCond_Taunting) || 
		GetEntProp(ownerEntity, Prop_Send, "m_nForceTauntCam") > 0)
		return Plugin_Handled;

	ActionSlotItemWeaponData weaponData;
	if (!TheActionSlotItems.GetActionSlotItemWeaponData(actionSlotItem, weaponData))
		return Plugin_Continue;

	ActionSlotItemClassData classData;
	TheActionSlotItems.ActionSlotItemClasses.GetArray(weaponData.ClassIndex, classData, sizeof(classData));

	bool canTransmit = true;

	if (classData.StartClassHookFunctionCall(ActionSlotItemCallbackType_ShouldDrawViewModel))
	{
		Call_PushCell(actionSlotItem);
		Call_PushCell(ownerEntity);
		Call_PushCell(entity);
		Call_PushCell(client);
		Call_Finish(canTransmit);
	}

	return canTransmit ? Plugin_Continue : Plugin_Handled;
}

stock int CBaseAnimating_LookupSequence(int entity, const char[] sequenceName)
{
	Address pStudioHdr = view_as<Address>(GetEntData(entity, g_BaseAnimatingStudioHdrOffset * 4));
	if (pStudioHdr != Address_Null)
	{
		return SDKCall(g_CStudioHdrLookupSequenceSDKCall, pStudioHdr, sequenceName);
	}
	return -1;
}

stock Handle PrepareItemHandle(char[] classname, int index, int level, int quality, char[] att, bool preserveAttributes=false)
{
	Handle hItem = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION | (preserveAttributes ? PRESERVE_ATTRIBUTES : 0) );
	TF2Items_SetClassname(hItem, classname);
	TF2Items_SetItemIndex(hItem, index);
	TF2Items_SetLevel(hItem, level);
	TF2Items_SetQuality(hItem, quality);
	
	// Set attributes.
	char atts[32][32];
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 1)
	{
		TF2Items_SetNumAttributes(hItem, count / 2);
		int i2 = 0;
		for (int i = 0; i < count; i+= 2)
		{
			TF2Items_SetAttribute(hItem, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hItem, 0);
	}
	
	return hItem;
}

// TODO: Change this to read m_hMyWearables when SourceMod stable build can read CUtlVector netprops.
stock int TF2_GetPlayerActionSlotItem(int client)
{
	int ent = GetPlayerWeaponSlot(client, TFWeaponSlot_Action);
	if (IsValidEntity(ent))
		return ent;

	ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_powerup_bottle")) != -1)
	{
		int ownerEntity = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (ownerEntity == client)
			return ent;
	}

	ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
	{
		int ownerEntity = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (ownerEntity == client)
			return ent;
	}

	ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_weapon_grapplinghook")) != -1)
	{
		int ownerEntity = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (ownerEntity == client)
			return ent;
	}

	// ConTracker
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable_campaign_item")) != -1)
	{
		int ownerEntity = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (ownerEntity == client)
			return ent;
	}

	ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != -1)
	{
		int ownerEntity = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (ownerEntity != client)
			continue;

		// FeelsBadMan
		int itemDefinitionIndex = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
		if (itemDefinitionIndex == 228 ||
			itemDefinitionIndex == 231 ||
			itemDefinitionIndex == 233 ||
			itemDefinitionIndex == 234 ||
			itemDefinitionIndex == 241 ||
			itemDefinitionIndex == 280 ||
			itemDefinitionIndex == 281 ||
			itemDefinitionIndex == 282 ||
			itemDefinitionIndex == 283 ||
			itemDefinitionIndex == 284 ||
			itemDefinitionIndex == 286 ||
			itemDefinitionIndex == 288 ||
			itemDefinitionIndex == 362 ||
			itemDefinitionIndex == 364 ||
			itemDefinitionIndex == 365 ||
			itemDefinitionIndex == 493 ||
			itemDefinitionIndex == 536 ||
			itemDefinitionIndex == 542 ||
			itemDefinitionIndex == 577 ||
			itemDefinitionIndex == 599 ||
			itemDefinitionIndex == 673 ||
			itemDefinitionIndex == 729 ||
			itemDefinitionIndex == 790 ||
			itemDefinitionIndex == 791 ||
			itemDefinitionIndex == 839 ||
			itemDefinitionIndex == 928 ||
			itemDefinitionIndex == 1027 ||
			itemDefinitionIndex == 1037 ||
			itemDefinitionIndex == 1126 || 
			itemDefinitionIndex == 1176 ||
			itemDefinitionIndex == 1195 ||
			itemDefinitionIndex == 5086 ||
			itemDefinitionIndex == 5087 ||
			itemDefinitionIndex == 5607 ||
			itemDefinitionIndex == 5626 ||
			itemDefinitionIndex == 5637 ||
			itemDefinitionIndex == 5638 ||
			itemDefinitionIndex == 5772 ||
			itemDefinitionIndex == 5773 ||
			itemDefinitionIndex == 5776 ||
			itemDefinitionIndex == 5777 ||
			itemDefinitionIndex == 5779 ||
			itemDefinitionIndex == 5780 ||
			itemDefinitionIndex == 5869
		)
		{
			return ent;
		}
	}

	return -1;
}

stock void TF2_RemovePlayerActionSlotItem(int client)
{
	int actionSlotItem = TF2_GetPlayerActionSlotItem(client);
	if (!IsValidEntity(actionSlotItem))
		return;

	char classname[256];
	GetEntityClassname(actionSlotItem, classname, sizeof(classname));

	if (strcmp(classname, "tf_powerup_bottle", false) == 0)
	{
		RemoveEntity(actionSlotItem);
	}
	else if (strcmp(classname, "tf_wearable", false) == 0 || strcmp(classname, "tf_wearable_campaign_item", false) == 0)
	{
		RemoveEntity(actionSlotItem);
	}
	else 
	{
		int extraWearable = GetEntPropEnt(actionSlotItem, Prop_Send, "m_hExtraWearable");
		if (extraWearable != -1)
		{
			RemoveEntity(extraWearable);
		}

		extraWearable = GetEntPropEnt(actionSlotItem, Prop_Send, "m_hExtraWearableViewModel");
		if (extraWearable != -1)
		{
			RemoveEntity(extraWearable);
		}

		RemovePlayerItem(client, actionSlotItem);
		RemoveEntity(actionSlotItem);
	}
}

stock bool PlayerSwitchWeapon(int client, int weapon)
{
	return SDKCall(g_PlayerWeaponSwitchSDKCall, client, weapon, 0);
}

stock bool PlayerSwitchToValidWeapon(int client)
{
	int switchedWeapon;

	if (IsValidEntity((switchedWeapon = GetEntPropEnt(client, Prop_Send, "m_hLastWeapon"))) && PlayerSwitchWeapon(client, switchedWeapon))
	{
		return true;
	}
	else if (IsValidEntity((switchedWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))) && PlayerSwitchWeapon(client, switchedWeapon))
	{
		return true;
	}
	else if (IsValidEntity((switchedWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))) && PlayerSwitchWeapon(client, switchedWeapon))
	{
		return true;
	}
	else if (IsValidEntity((switchedWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))) && PlayerSwitchWeapon(client, switchedWeapon))
	{
		return true;
	}

	return false;
}