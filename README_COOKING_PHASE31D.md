Phase 31D - Kitchen-style stove interaction

What changed:
- Stove is now mainly an in-world appliance instead of a GUI-first station.
- Right-click a stove with a Pan or Pot in hand to place the cookware on top.
- Right-click the stove with an ingredient in hand to place the food into the cookware.
- Right-click with empty hand to plate finished food if output is ready.
- Right-click with empty hand and no plated food toggles the stove burner on/off.
- Crouch + right-click with empty hand pulls raw food back out of the cookware.
- Crouch + right-click again with empty hand removes the Pan/Pot from the stove once empty.
- Stoves now render visible cookware and the current food on top, instead of relying on the station UI.

Current limitations:
- Stove interaction is the main kitchen-style appliance pass in this phase.
- Oven, blender, prep table, and fermenter still use the station UI.
- Stove visuals are lightweight placeholder meshes meant to prove the placement workflow.
- Multiplayer sync for stove cookware/food visuals may still need a later polish pass.
