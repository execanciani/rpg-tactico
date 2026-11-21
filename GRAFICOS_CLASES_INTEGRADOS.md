# Gráficos de clases integrados — 21/11/2026

Se añadieron sprites PNG originales, sobre fondo transparente, para cuatro familias de clases iniciales: guerrero, arquero, acólito y explorador. La hoja de ilustraciones de origen se conserva en `assets/sprites/characters/class_art_source.png`.

## Archivos y conexión con Godot

- `assets/sprites/characters/{warrior,archer,acolyte,explorer}/`: PNG por acción, dirección y retratos.
- `assets/portraits/classes/portrait_{warrior,archer,acolyte,explorer}.png`: retratos de clase (aplicados a humanos; las demás razas conservan su retrato racial).
- `scripts/presentation/class_visual.gd` y `scenes/presentation/class_visual.tscn`: adaptador de AnimatedSprite2D basado en la interfaz de `MageVisual`.
- `scripts/presentation/tactical_unit.gd`: selecciona el adaptador de sprite de acuerdo con `profession_id`, sin modificar reglas de batalla.
- `scripts/ui/character_portrait.gd`: muestra retratos de estas clases para humanos; conserva el fallback racial.

Profesiones avanzadas reutilizan temporalmente los gráficos de su familia inicial:

- Warrior: swordsman, guardian, blade_master, iron_protector.
- Archer: marksman, hunter, imperial_archer.
- Acolyte: healer, oracle, light_priest.
- Explorer: assassin, stalker, lethal_shadow.

El mago humano conserva su sprite y animaciones previas. Los magos de otras razas siguen usando sus representaciones anteriores mientras no existan sprites específicos.

## Límites gráficos importantes

La ilustración de IA inicial contenía **una sola vista de cada personaje**, no una secuencia real de múltiples poses. Para poder usarla inmediatamente, se extrajeron personajes y generaron cuadros *provisionales* mediante desplazamientos, parpadeos de color y rotación. Las vistas 'front/back' son provisionales y no muestran la auténtica espalda del personaje. Para la versión comercial deben crearse sprites dibujados individualmente, especialmente para caminar en cuatro direcciones, diferencias raciales, profesiones avanzadas y ataque/magia. El objetivo de este paquete es dejar las cuatro familias visibles sin figuras geométricas en el combate.

## Verificación

Se verificó que existen las rutas de recursos PNG y que los archivos pueden abrirse con Pillow. Este entorno no dispone de ejecutable Godot: no se pudo validar la importación ni ejecutar las escenas. Abrir `project.godot` en Godot, esperar la importación de los recursos y probar selección, movimiento, ataque y muerte. Si hay errores de sintaxis, revisar primero `class_visual.gd`.
