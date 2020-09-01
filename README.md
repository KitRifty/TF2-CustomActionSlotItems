# [TF2] Custom Action Slot Items
A SourceMod plugin for Team Fortress 2 that provides a base for creating custom action slot items.

## Requirements
- [TF2Items](https://builds.limetech.io/?project=tf2items)

## How it works
Under the hood, a custom action slot item is nothing more than a `tf_weapon_spellbook` entity. Once equipped, the item can be switched to by using the Action Slot Item key (H key by default). The plugin suspends the normal functionality of the spellbook to allow for user-defined custom behavior; the plugin provides useful hooks and functions to facilitate this.

You may either compile this project as a standalone plugin and use the natives, or embed `actionslotitems/base.sp` into an existing plugin. If embedding, make sure to forward the correct plugin hooks and provide the appropriate SDKCalls to `TheActionSlotItems`. In embedded style, you are also responsible for providing the gamedata in your plugin.

## Creating an item
To begin, you must register a custom item **class**. Use the `ActionSlotItems_RegisterClass` native, or in embedded style, create a `ActionSlotItemClassData` structure and call the  `TheActionSlotItems.RegisterClass` method. Use `ActionSlotItems_RegisterClassHook`/`TheActionSlotItems.RegisterClassHook` to register callback functions. These callback functions are called per weapon entity registered with the class at the appropriate times.

## Equipping the item
If using the standalone plugin, use the `sm_casi_give` command followed by the classname of your custom item. If embedded, utilize the `TheActionSlotItems.GiveActionSlotItem` method.

## Issues
- ***Affected by Halloween spell rolls.*** Because it's a `tf_weapon_spellbook` entity, the spell will be rolled upon touching a spell or teleported to Merasmus in the wheel of doom, and can also change the amount of spell charges the spellbook has. Therefore, it's not recommended to use this in Halloween maps unless you properly hook the correct functions to prevent this from happening.
- ***Unpredicted viewmodel animations.*** All animations of the viewmodel is controlled by the server, therefore animations sent by the server cannot be predicted client-side. As a result, higher latency players will experience a bigger delay in animations, so when designing a custom item, keep this fact in mind.
- ***Viewmodel animations cannot be repeated.*** Viewmodel entities are predicted by the client by default. [The viewmodel uses a parity value to check if an animation is being repeated.](https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/client/c_baseviewmodel.cpp#L443) However, this is ignored if the entity is predicted by the client (which it always is). Therefore, repeated animations will not play on the client despite it playing correctly server-side. To work around this, play a different sequence before repeating.
