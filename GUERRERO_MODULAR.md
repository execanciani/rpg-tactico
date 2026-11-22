# Guerrero 2D modular

El cuerpo viste túnica borgoña, cinturón, pantalón y calzado de tela y cuero. Los cinco objetos de hierro son capas independientes con contorno oscuro, acero azulado y luz superior izquierda. Las cuatro orientaciones tienen su propia cara o nuca. El casco, la coraza, el calzado y las armas tienen detalles direccionales.

## Auditoría

- La hoja anterior ofrecía una nuca dibujada y poses iniciales aprovechables como referencia. La dirección frontal se parecía al perfil en movimiento y el ataque tenía espada, destellos y fragmentos de fondo incrustados. Recortar esos destellos también afectaba la silueta.
- El sistema anterior aplicaba texturas estáticas con pequeños desplazamientos. La prenda y las botas quedaban fijas durante la marcha y la caída, y el puño podía perder contacto con la espada. Se conservan las hojas, PNG y recursos anteriores para los consumidores que requieren sus variantes estáticas.
- La nueva composición se inspecciona en `artifacts/warrior/comparacion.png` (sin equipo y con las cinco piezas) y `artifacts/warrior/animaciones.png` (todas las poses equipadas). El exportador verifica que las celdas estén dentro del lienzo y que cada clip tenga fotogramas distintos.

## Formato y reproducción

Cada celda mide 96 × 96, tiene fondo transparente y se muestra con filtro nearest. El origen de registro en el suelo está en (48, 86) contando desde arriba a la izquierda. Cada bota lleva su propio anclaje. Cabeza, torso, agarre de la espada y brazo del escudo comparten el mismo sistema de coordenadas del cuerpo. En derrota, cuerpo y capas giran y se desplazan juntos.

Los PNG de `assets/characters/warrior/modular/` tienen cuatro columnas en orden frente, derecha, espalda e izquierda. La cuadrícula es de 384 × 1824 px.

| Animación | Filas desde cero | Fotogramas por dirección |
| --- | ---: | ---: |
| Reposo | 0–2 | 3 |
| Caminar | 3–8 | 6 |
| Ataque | 9–12 | 4 |
| Recibir daño | 13–14 | 2 |
| Derrota | 15–18 | 4 |
| Habilidad | 9–12 | 4, reutiliza ataque |

`WarriorVisual` ofrece el fotograma a `EquipmentLayerVisual`. Las cinco texturas se registran con la misma celda. Los Resources pueden sobrescribir la profundidad por dirección, estado o fotograma. En el inventario, elegí la orientación con Frente, Der., Espalda o Izq. Abrí `res://scenes/debug/warrior_equipment_preview.tscn` y pulsá F6 para comparar dos vistas, combinar las cinco piezas, repetir un clip y mostrar anclajes. El blanco indica suelo, el amarillo cabeza, el verde torso, el naranja espada, el celeste escudo y el rosa botas.

## Fuentes y ampliación

- `assets/characters/warrior/warrior_turnaround_source.png` conserva la referencia de ImageGen integrado. Prompt resumido: mismo guerrero medieval original de pelo castaño, túnica borgoña, cinturón y botas de cuero en cuatro vistas, pixel art táctico, fondo transparente y sin armas ni armadura. El exportador extrae y normaliza las cabezas. Cuerpo, piezas y poses restantes están dibujados en la fuente reproducible `tools/build_warrior_atlases.py`.
- Ejecutá `python tools/build_warrior_atlases.py` con Pillow. Para PNG individuales, añadí `--frames .godot/warrior-frames`.
- Para un objeto futuro, creá su Resource, icono de inventario y atlas de combate independiente. Usá `body_model_id` y `combat_pose_atlas` para indicar la compatibilidad, y `combat_draw_order` si requiere otro orden. El campo `preview_visual` admite una imagen estática separada. La vista giratoria compone las capas del juego. El mismo contrato permite añadir piezas a otros cuerpos con una cuadrícula propia. Los futuros grados None, D, C, B, A, S y R pueden asociarse al catálogo sin acoplar la calidad del objeto al orden de dibujo.

## Arte pendiente

La habilidad tiene un fallback funcional. Para una animación propia se requieren 4–6 poses 96 × 96 por dirección para el cuerpo y cada pieza, con preparación, ejecución y recuperación. El cuerpo debe aparecer sin armas incrustadas. Usar el anclaje (48, 86) y registrar la mano y el antebrazo para espada y escudo. Colocar los PNG individuales en `assets/characters/warrior/modular/source/cast/<capa>/<dirección>_00.png` en adelante, donde `<capa>` es `body` o el ID de la pieza. Añadir un bloque compartido de filas en los seis atlas y actualizar la entrada `cast` de `WarriorVisual.CLIPS`. La implementación actual usa caída por poses y rotación pixelada sincronizada. Si se quiere una caída dibujada desde cero, reemplazar las últimas cuatro filas con la misma cuadrícula y anclaje.
