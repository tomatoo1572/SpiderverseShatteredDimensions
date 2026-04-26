# SSD Cooking Phase 31C - Appliance Cooking

This pass moves cooking away from simple crafting/furnace-style conversions and into appliance behavior.

## What changed
- Oven now uses a real fuel slot.
- Oven recipes only cook while fueled and hot.
- Stove now uses a burner dial style toggle in the station UI.
- Stove requires cookware in the secondary slot.
- Pan and Pot are now meaningful requirements instead of generic add-ins.
- Prep Table remains the place for slicing, shredding, kneading, and assembly.
- All ingredients and finished dishes stay in the Food creative tab.

## Station behavior
### Oven
- Slot 1: food input
- Slot 2: fuel (coal, sticks, planks, logs)
- Slot 3: cooked dish output
- Current recipes: Baked Potato, Cheese Pizza, Chocolate Chip Cookie

### Stove
- Slot 1: ingredient
- Slot 2: cookware (Pan or Pot)
- Slot 3: cooked dish output
- Use the Burner button in the UI to turn the stove on and off.
- Current recipes: Steak, Cooked Chicken, Cooked Rice, Mashed Potatoes

### Prep Table
- Used for dough, noodles, sliced tomato, shredded cheese, pizza base, broth, and other prep steps.

## Notes
- This is the appliance foundation pass, not the final kitchen mod feature-complete pass.
- Multi-ingredient pot dishes and more complex appliance visuals can be layered on top next.
