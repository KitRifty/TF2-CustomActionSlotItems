#if defined _actionslotitems_included
 #endinput
#endif
#define _actionslotitems_included

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
		public native get();
		public native set(int clip);
	}

	property float NextPrimaryAttack
	{
		public native get();
		public native set(float time);
	}

	property int ViewModel
	{
		public native get();
	}

	property bool Charging
	{
		public native get();
	}

	property bool Reloading
	{
		public native get();
	}

	property float ReloadFinishTime
	{
		public native get();
		public native set(float time);
	}

	/**
	* Returns whether or not the weapon is a valid custom action slot item.
	*
	* @return					True if the weapon is a custom action slot item; false otherwise.
	*/
	public native bool IsValid();

	/**
	 * Retrives the action slot class of the item.
	 *
	 * @param buffer		String to store result.
	 * @param bufferLen		Size of buffer.
	 */
	public native void GetClassname(char[] buffer, int bufferLen);
}

/**
 * Called when a custom action slot item is given to the player.
 *
 * @param client			Client index.
 * @param actionSlotItem	The action slot item entity.
 */
forward void OnPlayerEquipCustomActionSlotItem(int client, ActionSlotItem actionSlotItem);

/**
 * Registers a new custom action slot item. This is required to be able to use class hooks.
 *
 * @param classname			Classname.
 */
native void ActionSlotItems_RegisterClass(const char[] classname);

/**
 * Registers a class hook to the custom action slot item.
 * @param classname			Classname.
 * @param callbackType		Type of hook to register.
 * @param callback			The hook callback function.
 * @return					True if successful, false otherwise.
 */
native bool ActionSlotItems_RegisterClassHook(const char[] classname, ActionSlotItemCallbackType callbackType, ActionSlotItemCallback callback);

/**
 * Returns whether or not the custom action slot item can charge (hold before throw).
 *
 * @param classname			Classname.
 */
native bool ActionSlotItems_GetClassCanCharge(const char[] classname);

/**
 * Sets whether or not the custom action slot item should charge (hold before throw).
 *
 * @param classname			Classname.
 * @param canCharge			Boolean.
 */
native void ActionSlotItems_SetClassCanCharge(const char[] classname, bool canReload);

/**
 * Returns whether or not the custom action slot item can charge (hold before throw).
 *
 * @param classname			Classname.
 */
native bool ActionSlotItems_GetClassCanReload(const char[] classname);

/**
 * Sets whether or not the custom action slot item should charge (hold before throw).
 *
 * @param classname			Classname.
 * @param canCharge			Boolean.
 */
native void ActionSlotItems_SetClassCanReload(const char[] classname, bool canReload);

native float ActionSlotItems_GetClassRightHandPoseParameter(const char[] classname, TFClassType classType);
native void ActionSlotItems_SetClassRightHandPoseParameter(const char[] classname, TFClassType classType, float value);

/**
 * Retrieves the model path of the custom action slot item's view model.
 * 
 * @param classname			Classname.
 * @param buffer			Buffer to store the viewmodel path.
 * @param bufferLen			Max length of buffer.
 */
native void ActionSlotItems_GetClassViewModel(const char[] classname, char[] buffer, int bufferLen);

/**
 * Sets the model path of the custom action slot item's view model.
 *
 * @param classname			Classname.
 * @param model				The model path.
 */
native void ActionSlotItems_SetClassViewModel(const char[] classname, const char[] model);

/**
 * Gets the local position offset of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param classType			The TF2 class to take into account.
 * @param offset			Buffer to store offset vector.
 */
native void ActionSlotItems_GetClassViewModelOffset(const char[] classname, TFClassType classType, float offset[3]);

/**
 * Sets the local position offset of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param classType			The TF2 class to take into account.
 * @param offset			The local position offset.
 */
native void ActionSlotItems_SetClassViewModelOffset(const char[] classname, TFClassType classType, const float offset[3]);

/**
 * Sets the local position offset of all player classes of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param offset			The local position offset.
 */
stock void ActionSlotItems_SetClassViewModelOffsetAll(const char[] classname, const float offset[3])
{
	for (int i = 1; i <= 9; i++)
		ActionSlotItems_SetClassViewModelOffset(classname, view_as<TFClassType>(i), offset);
}

/**
 * Gets the local angles of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param classType			The TF2 class to take into account.
 * @param angles			Buffer to store local angles.
 */
native void ActionSlotItems_GetClassViewModelAngles(const char[] classname, TFClassType classType, float angles[3]);

/**
 * Sets the local angles of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param classType			The TF2 class to take into account.
 * @param angles			The local angles.
 */
native void ActionSlotItems_SetClassViewModelAngles(const char[] classname, TFClassType classType, const float angles[3]);

/**
 * Sets the local angles of all player classes of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param angles			The local angles.
 */
stock void ActionSlotItems_SetClassViewModelAnglesAll(const char[] classname, const float angles[3])
{
	for (int i = 1; i <= 9; i++)
		ActionSlotItems_SetClassViewModelAngles(classname, view_as<TFClassType>(i), angles);
}

/**
 * Gets the model scale of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param classType			The TF2Class to take into account.
 * @return					The model scale.
 */
native float ActionSlotItems_GetClassViewModelScale(const char[] classname, TFClassType classType);

/**
 * Gets the model scale of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param classType			The TF2Class to take into account.
 * @param scale				The model scale.
 */
native void ActionSlotItems_SetClassViewModelScale(const char[] classname, TFClassType classType, float scale);

/**
 * Sets the local angles of all player classes of the custom action slot item's viewmodel.
 *
 * @param classname			Classname.
 * @param angles			The local angles.
 */
stock void ActionSlotItems_SetClassViewModelScaleAll(const char[] classname, float scale)
{
	for (int i = 1; i <= 9; i++)
		ActionSlotItems_SetClassViewModelScale(classname, view_as<TFClassType>(i), scale);
}

/**
 * Returns the custom action slot item of the player.
 *
 * @param client			Client index.
 * @return					The custom action slot item, or -1 if fail.
 */
native ActionSlotItem ActionSlotItems_GetPlayerCustomActionSlotItem(int client);

/**
 * Plays a gesture activity on the client.
 *
 * @param client			Client index.
 * @param activityName		Name of activity.
 */
native void ActionSlotItems_PlayerPlayGesture(int client, const char[] activityName);

/**
 * Gives a custom action slot item to the client.
 *
 * @param client			Client index.
 * @param className			Class name.
 * @param charges			How many charges to give.
 * @return					The custom Action Slot item.
 */
native ActionSlotItem ActionSlotItems_Give(int client, const char[] className, int charges=1);

public SharedPlugin:__pl_actionslotitems = 
{
	name = "actionslotitems",
	file = "actionslotitems.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};