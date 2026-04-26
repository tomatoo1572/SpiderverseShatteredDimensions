
# Phase 31B Cooking Stations and Process Pass

This pass moves the food loop away from simple crafting-table/furnace clones.

## What changed
- Prep Table now opens as its own cooking/prep station.
- Cooking stations use a live 3-slot workflow:
  - Ingredient
  - Secondary slot (add-in / cookware / liquid / brine)
  - Dish output
- Cooking stations no longer rely on furnace fuel logic.
- Food ingredients and dishes were moved into the **Food** creative tab.
- The **Cooking** creative tab now focuses on stations and cookware.

## New items
- Pizza Base
- Steak
- Noodles
- Broth
- Chicken Noodle Soup
- Mac and Cheese
- Ground Beef
- Sliced Tomato
- Shredded Cheese

## New station flows
### Prep Table
- Flour + Bottle of Water -> Dough
- Dough -> Noodles
- Tomato -> Sliced Tomato
- Cheese -> Shredded Cheese
- Raw Beef -> Ground Beef
- Dough + Sliced Tomato -> Pizza Base
- Pizza Base + Shredded Cheese -> Raw Cheese Pizza
- Flour + Shredded Cheese -> Cookie Dough
- Cooked Rice + Cooked Chicken -> Rice and Chicken
- Cooked Chicken + Bottle of Water -> Broth

### Stove
- Raw Beef + Pan -> Steak
- Rice + Pot -> Cooked Rice
- Potato + Pot -> Mashed Potatoes
- Raw Chicken + Pot -> Cooked Chicken
- Noodles + Shredded Cheese -> Mac and Cheese
- Broth + Noodles -> Chicken Noodle Soup

### Oven
- Raw Cheese Pizza + Pan -> Cheese Pizza
- Cookie Dough + Pan -> Chocolate Chip Cookie

### Fermentation Jar
- Cucumber + Bottle of Water -> Pickles

### Blender
- Strawberry/Blueberry/Blackberry/Mango + Bottle of Water -> Smoothie
