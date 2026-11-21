# Auditoría técnica del RPG táctico — 21/11/2026

## Alcance

Se inspeccionó el proyecto recibido en `rpg-tactico(1).zip`, sin reemplazar los datos del usuario. Se comprobaron por lectura los scripts de Godot, la estructura de escenas, recursos y los PNG del mago (62 imágenes PNG en total; las 55 del subárbol del mago se abrieron y verificaron con Pillow). La auditoría **no** equivale a una prueba de ejecución.

**Limitación:** este entorno no incluye el binario Godot y no tiene acceso de red para obtenerlo. Los smoke tests incluidos no pudieron ejecutarse aquí. Probar obligatoriamente en Godot antes de dar por validada una compilación comercial.

## Estado observado

- Selección de hasta 3 personajes, flujo de raza, profesión, retrato y nombre: hay escenas y controladores implementados.
- Progresión: hay razas, profesiones, experiencia, SP y guardado.
- Combate: mapa isométrico, navegación, turnos, ataques, habilidades y enemigos.
- Visual del mago humano: sprites PNG, animaciones y efectos integrados en scripts.
- La campaña tiene 3 misiones configuradas, pero no hay pruebas funcionales completas realizadas en esta auditoría.
- Todavía no hay inventario/equipamiento, exportaciones verificadas para Android, ni PvP.

## Correcciones realizadas sobre la copia

1. `scripts/core/battle_controller.gd`: se reinicia `phase` y estado de selección al comenzar cualquier misión. Antes, después de terminar una batalla, el siguiente nivel podía conservar `FINISHED` y no iniciar turnos.
2. `scripts/core/battle_controller.gd`: validación defensiva de movimiento repetido y casilla de origen; ataques repetidos rechazados al nivel del ejecutor además de la UI.
3. `scripts/persistence/save_system.gd`: escritura temporal antes de sustituir el guardado, verificación del JSON escrito, respaldo `.bak` del guardado anterior y lectura de respaldo si el principal está corrupto. El código conserva el formato de guardado 6 y la compatibilidad existente con versiones 3–6.
4. `scripts/presentation/tactical_unit.gd`: la posición lógica avanza al completar cada tramo animado y no al programar anticipadamente los tweens de movimiento.
5. `scripts/presentation/mage_visual.gd`: animaciones de daño y derrota no se quedan esperando al evento `animation_finished` si faltan frames.
6. `tests/smoke_test.gd`: casos de regresión añadidos para recuperación desde respaldo y reinicio de misión después de `FINISHED`.

## Riesgos y pendientes

- Ejecutar pruebas reales en Godot y corregir cualquier error de importación o sintaxis que aparezca.
- Inspeccionar visualmente las transparencias y bordes de los sprites del mago; una imagen PNG válida no garantiza recortes perfectos.
- Revisar UI en teléfono Android físico (zonas táctiles, escalado y orientación), porque no hay una validación de exportación.
- Considerar refactorización progresiva de `battle_controller.gd` y `battle_ui.gd` para separar responsabilidades; no se realizó una reescritura masiva por riesgo de regresión.
- Una copia temporal y un `.bak` reducen el riesgo de pérdida de guardado, pero no hacen la operación absolutamente atómica en todos los sistemas de archivos.

## Verificación recomendada en Windows

Abrir `project.godot` en Godot, esperar que termine de importar assets y ejecutar desde PowerShell, en la carpeta del proyecto:

```powershell
& 'C:\ruta\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/smoke_test.gd
```

Después ejecutar la escena con **F5** y probar: crear 1–3 personajes, combate completo, continuar de una misión a otra, guardado, carga y las animaciones del mago. No usar el ZIP modificado como única copia del proyecto hasta haber probado estas operaciones.
