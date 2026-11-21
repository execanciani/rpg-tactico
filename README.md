# RPG Táctico Isométrico — prototipo

Prototipo offline realizado con Godot 4.7.2 y GDScript. Todo el arte visible se dibuja con primitivas del motor, por lo que no depende de recursos externos ni licencias de terceros.

## Ejecutar

1. Abrí `project.godot` con Godot 4.7.2.
2. Presioná **F6/F5** o **Ejecutar proyecto**.
3. Seleccioná una unidad azul y elegí **Mover**, **Atacar**, **Habilidad** o **Esperar**.

### Controles

- `M`: mover.
- `A`: atacar.
- `S`: habilidad.
- `W` o `Espacio`: esperar.
- `Esc`: cancelar el modo actual.
- Flechas: desplazar la cámara.
- Botón central/derecho y arrastre: desplazar la cámara.
- Rueda: zoom.
- Android: toque para seleccionar; gesto de dos dedos para desplazar y ampliar.

Los botones **Guardar** y **Cargar** usan `user://campaign_save.json`. Sólo se guarda durante el turno del jugador para evitar estados intermedios de animaciones o IA.

## Campaña

La campaña contiene tres encuentros consecutivos:

1. **Las ruinas de la frontera**: introducción a desniveles y obstáculos.
2. **El paso quebrado**: crestas de hasta dos niveles y cuatro enemigos.
3. **La cumbre de las runas**: asalto final con cinco enemigos.

Tras una victoria se habilita la siguiente misión. Una derrota permite reiniciar el encuentro actual; al completar la última misión se puede reiniciar la campaña.

## Altura y línea de visión

- Cada casilla puede tener una altura lógica independiente.
- Subir o bajar consume `1 + diferencia de altura` puntos de movimiento.
- Las unidades tienen un límite `max_climb`; arquero y explorador pueden salvar dos niveles.
- La distancia vertical afecta el alcance efectivo.
- Atacar desde una posición superior añade daño; hacerlo desde abajo lo reduce.
- Rocas y crestas que superan la trayectoria bloquean ataques y habilidades.

## Arquitectura

- `data/abilities`: habilidades editables como recursos `.tres`.
- `data/archetypes`: estadísticas y profesiones editables como `.tres`.
- `data/missions`: formaciones, alturas y obstáculos de cada encuentro.
- `scripts/domain`: modelos de unidades, habilidades, arquetipos y misiones.
- `scripts/core`: comandos serializables, reglas, controlador y simulador determinista.
- `scripts/grid`: conversión isométrica y navegación con coste vertical.
- `scripts/campaign`: progreso entre encuentros.
- `scripts/persistence`: guardado JSON versionado.
- `scripts/ai`: decisiones de los enemigos.
- `scripts/presentation`: cámara, unidades procedurales y efectos.
- `scripts/ui`: interfaz adaptable para mouse y pantalla táctil.
- `tests`: pruebas automáticas sin interfaz gráfica.

La UI emite intenciones y el controlador las convierte en `BattleCommand`. Las reglas no dependen de nodos visuales, y los comandos pueden serializarse para una futura capa de red autoritativa.

## Pruebas

Desde PowerShell, ajustando la ruta del ejecutable si fuera necesario:

```powershell
& 'C:\ruta\a\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/smoke_test.gd
```

Las pruebas comprueban recursos externos, navegación con altura, límites de escalada, línea de visión, daño, serialización de guardado, carga de la escena y simulaciones completas de las tres misiones.

## Alcance pendiente

Quedan fuera por ahora inventario, equipo, progresión entre misiones, diálogos, objetivos distintos de eliminar enemigos, efectos de estado, animaciones con sprites definitivos, audio y multijugador.
