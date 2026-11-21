# Auditoría técnica — 21/11/2026

## Alcance

Revisión estática de la rama `main` del proyecto Godot 4.7.2: configuración, README, sistema de personajes, equipamiento, guardado, comandos de combate, turnos, simulador, navegación e inventario. El repositorio también incluye recursos de clases, misiones y pruebas automáticas.

Esta primera entrega propone correcciones pequeñas y reproducibles, no una certificación del funcionamiento global del juego.

## Hallazgos corregidos

1. **Destino ocupado en rutas tácticas:** `GridPathfinder.find_path()` permitía recorrer hasta la casilla final aunque estuviera ocupada, a diferencia de `reachable_cells()`. Se bloquean destinos ocupados, fuera del tablero o marcados como obstáculos. El origen puede continuar ocupado por el personaje que se mueve.
2. **Estado del inventario no validado:** `InventorySlotData.normalized()` asumía que `state` siempre era un diccionario. Una partida JSON editada o malformada podía provocar una llamada `.duplicate()` sobre otro tipo. Ahora se normaliza a diccionario vacío.
3. **Restauración de slots:** `CampaignProfile._sanitize_restored_character()` también asumía un estado tipo diccionario y provocaba el mismo fallo. Se aplica la misma validación.

## Cobertura añadida

- Rechazo de rutas con casilla final ocupada o fuera del tablero.
- Normalización de un slot con un estado inválido.
- Restauración de un personaje cuyo inventario contiene un estado inválido.

## Revisión adicional: trabajo pendiente

- **Motor de combate:** `BattleCommand.is_valid_for()` verifica solo estructura y actor; las reglas específicas están distribuidas en `BattleController`. Conviene centralizar validaciones antes de implementar PvP.
- **Simulador:** `BattleSimulator` repite partes del flujo de ejecución de ataques. Podría divergir de la partida real; necesita refactorización y pruebas de paridad.
- **Persistencia:** `SaveSystem.decode_payload()` acepta varias versiones; se debe verificar la migración semántica de cada formato y casos de archivos corruptos/reemplazos durante el guardado en Windows y Android.
- **Riesgos visuales:** el equipamiento por capas reutiliza recursos y offsets por dirección/animación; requiere comprobación visual en el editor de Godot.
- **Lanzamiento comercial:** faltan pruebas de exportación Android/Windows, desempeño y verificación de licencias de todos los recursos.

## Pruebas y límites

**No se ejecutaron pruebas en Godot en este entorno:** no está disponible el ejecutable de Godot y el acceso a GitHub se realizó mediante el conector. Las correcciones se revisaron estáticamente; el resultado es un PR para revisión, no un cambio validado en tiempo de ejecución.

Ejecutar en una máquina con Godot 4.7.2:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
```

Si el ejecutable no está en el PATH, sustituir `godot` por su ruta local. Verificar también F5, seleccionar 1–3 personajes, mover unidades, equipar objetos, guardar/cargar y ejecutar las tres misiones.

No se modificó la rama `main`.

## Segunda pasada: turnos, combate y persistencia

Se añadieron nuevas correcciones a la misma rama, sin modificar `main`:

1. **TurnManager.restore():** elimina IDs desconocidos o duplicados de la iniciativa; reincorpora unidades vivas ausentes del snapshot; elimina IDs inválidos del registro de acciones; selecciona una unidad activa válida y evita que una ronda totalmente consumida quede bloqueada.
2. **CombatRules.can_basic_attack():** rechaza referencias nulas de atacante o defensor sin intentar acceder a sus propiedades.
3. **SaveSystem.decode_payload():** rechaza versiones no numéricas (cadena, null, objeto) o fraccionarias en lugar de convertirlas implícitamente.
4. **Pruebas de regresión:** nuevas aserciones para cada caso, incluidas restauraciones de ronda y versiones JSON inválidas.

**Pendiente:** ejecutar el smoke test con Godot 4.7.2 y comprobar visualmente el equipamiento en sus cuatro direcciones. No se modificó la presentación 2D ni se añadió 3D.
