# Fase 5 — Auditoría gráfica y guía visual

## Alcance verificado

La auditoría se realizó sobre los scripts de presentación, inventario, catálogo, Resources, escenas, herramientas y pruebas solicitados. La rama de trabajo es `feature/fase-5-mejora-grafica`, creada desde `main` actualizado al commit `084fc8f`.

No se modificaron reglas de combate, pathfinding, experiencia, profesiones ni versión/formato de guardado. Tampoco se cambió la escala lógica del mapa.

## Inventario de recursos y problemas encontrados

| Área | Estado inicial | Problema | Resolución Fase 5 |
|---|---|---|---|
| Guerrero modular | 56 fotogramas, 4 direcciones y 5 piezas de hierro | Era el único conjunto realmente direccional | Se conserva como referencia; la vista previa reutiliza sus mismas capas |
| Mago | Movimiento, ataque, cast, hurt y death laterales; frente/espalda estáticos | No existen secuencias completas en cuatro direcciones | Se conserva el fallback y se añaden 4 turnarounds idle reales |
| Arquero | 4 direcciones y estados derivados de una ilustración | Los cuadros no son animación dibujada real | Se conserva sin presentar duplicados como arte definitivo; 4 turnarounds nuevos |
| Acólito | Igual que arquero | Movimiento provisional | 4 turnarounds nuevos, fallback documentado |
| Explorador | Igual que arquero | Movimiento provisional | 4 turnarounds nuevos, fallback documentado |
| Equipo no guerrero | Capas estáticas 96×96 y previews 256×384 | No siguen cada pose individual | Se mantienen por compatibilidad; quedan pendientes variantes por fotograma |
| Iconos | Mezcla de 40×40, 64×64 y capas completas usadas como icono | Escalas, márgenes y lectura inconsistentes | 33 iconos individuales normalizados a 64×64 |
| Inventario | Funcional y táctil | Sin giro; selección/equipado/vacío poco diferenciados | Preview giratoria y estados con bordes diferenciados |

No se detectaron iconos sin definición ni Resources sin icono después de la integración.

## Guía visual unificada

### Personajes de combate

- Lienzo: `96×96 px`, RGBA real.
- Ancla objetivo de pies: `(48, 88)`.
- Zona máxima sugerida del personaje base: `70×82 px`.
- Filtrado: nearest-neighbor; sin mipmaps visuales ni suavizado en CanvasItem.
- Direcciones canónicas: `front`, `right`, `back`, `left`.
- Estados canónicos: `idle`, `walk`, `attack`, `cast`, `hurt`, `death`.
- El cuerpo base no debe contener casco, armadura completa, arma, escudo o capa equipables.
- Las sombras pertenecen al render táctico, no al PNG del personaje.

### Paleta por familia

- Guerrero: acero `#D4DDE2`, cuero `#67412D`, rojo oscuro `#7A2F32`.
- Mago: azul-violeta `#4B3F79`, luz arcana `#8E78C8`.
- Arquero: verde cuero `#60754F`, marrón `#7A4C31`.
- Acólito: marfil `#EEE9D8`, dorado `#D8AB4F`, azul claro `#8FB5B2`.
- Explorador: gris verdoso `#3D4B49`, cuero oscuro `#493A32`.

### Iconos

- Lienzo: `64×64 px`, RGBA.
- Objeto centrado con margen mínimo aproximado de 6 px.
- Contorno oscuro discreto, sin texto, cantidades ni marco de rareza incorporado.
- La futura clasificación `None/D/C/B/A/S/R` debe representarse desde la interfaz, no modificando los PNG.

### Vista previa

- Reutiliza `MageVisual`, `ClassVisual`, `WarriorVisual` y `EquipmentLayerVisual`.
- Escala dinámica entre `1.6×` y `3.2×`, siempre con nearest-neighbor.
- El orden relativo negativo/positivo de arma y escudo se conserva dentro de un escenario elevado para no quedar detrás del panel UI.

## Recursos creados

- Fuente original generada: `assets/characters/class_turnarounds_fase5.png` (`1122×1402`, RGBA).
- 20 turnarounds normalizados: cinco clases × cuatro orientaciones.
- 33 iconos Fase 5 en `assets/items/icons/fase5/`.
- Manifiesto de iconos: `assets/items/icons/fase5/MANIFEST.md`.
- Vista previa reutilizable: `CharacterEquipmentPreview`.
- Diagnóstico interno: `scenes/debug/visual_diagnostics.tscn`.
- Capturas OpenGL: `artifacts/fase5/`.

Los PNG anteriores se conservaron. Los Resources apuntan a los nuevos iconos, pero las capas de combate y preview antiguas siguen disponibles.

## Estado de animaciones

| Clase | Idle | Walk | Attack | Cast | Hurt | Death | Estado artístico |
|---|---:|---:|---:|---:|---:|---:|---|
| Guerrero modular | 3×4 | 3×4 | 3×4 | reutiliza attack | 2×4 | 3×4 | Estable con fuente real disponible |
| Mago | 1×4 | 4 laterales, 1 frente/espalda | 4 laterales | 4 laterales | 3 laterales | 4 lateral | Incompleto en frente/espalda |
| Arquero | 1×4 | 4×4 | 4×4 | 4×4 | 3×4 | 4 lateral | Provisional: derivado de una vista fuente |
| Acólito | 1×4 | 4×4 | 4×4 | 4×4 | 3×4 | 4 lateral | Provisional: derivado de una vista fuente |
| Explorador | 1×4 | 4×4 | 4×4 | 4×4 | 3×4 | 4 lateral | Provisional: derivado de una vista fuente |

Los 20 turnarounds Fase 5 son vistas reales y diferenciadas, pero no se duplicaron para fingir animaciones. Se utilizan en la creación de personaje y en el diagnóstico; el combate conserva los fallbacks validados.

## Estado del equipamiento

- Guerrero: casco, armadura, botas, espada y escudo direccionales y visibles en inventario/combate.
- Orden de capas comprobado en frente y espalda. El escenario de preview evita ocultar capas negativas detrás del panel.
- Equipar/desequipar reconstruye inmediatamente la preview desde `CharacterProgress.equipped_items`.
- Otras clases: arquitectura preparada y capas estáticas funcionales; falta arte direccional por pose.
- Sin definición actual en catálogo para pantalones o capas, por lo que no se inventaron objetos ni se alteró balance.

## Iconos: estado honesto

- Total integrado: **33/33**.
- Redibujados como motivos originales Fase 5: **12** (botas, sandalias, guantes, bastones y arco).
- Recortados, contorneados y normalizados desde arte existente: **21**.
- Faltantes o con fondo opaco: **0**.
- Los 33 cumplen técnicamente tamaño, transparencia, margen y asociación. Los 21 derivados conservan carácter de arte provisional y admiten una futura pasada manual sin cambiar IDs ni Resources.

## Fuente generada con ImageGen

Se utilizó el generador integrado en modo `stylized-concept`, con fondo transparente. Prompt resumido: hoja estricta 5×4, filas Guerrero/Mago/Arquero/Acólito/Explorador, columnas frente/derecha/espalda/izquierda; pixel art táctico original, cuerpos base sin equipo, escala y pies uniformes, sin texto, marcos, sombras, fondos ni diseños reconocibles de terceros.

## Validación visual

- `artifacts/fase5/inventory_front.png`: guerrero equipado de frente.
- `artifacts/fase5/inventory_back.png`: mismo estado y equipamiento de espalda.
- `artifacts/fase5/visual_diagnostics.png`: guerrero, controles, animación y catálogo completo.

Las capturas fueron renderizadas con Godot 4.7.2, OpenGL Compatibility, a `1280×720`.

## Pendiente para arte comercial completo

1. Dibujar a mano walk 6, attack/cast 4–6, hurt 2–3 y death 4–6 para mago, arquero, acólito y explorador en cuatro vistas.
2. Crear capas de equipo por estado/fotograma para esas cuatro familias.
3. Añadir arte de guantes, piernas y capa del guerrero cuando existan objetos de esas ranuras.
4. Revisión artística manual de los 21 iconos derivados, aunque ya son funcionales y consistentes técnicamente.
5. Variantes corporales por raza; actualmente la apariencia visual depende de familia de clase.

## Cómo comprobarlo

1. Abrir `scenes/debug/visual_diagnostics.tscn` y ejecutar la escena actual (`F6`).
2. Cambiar clase, estado y orientación; alternar `CUERPO BASE`/`KIT COMPLETO`.
3. Ejecutar el juego, crear un guerrero, abrir Inventario y usar los botones `◀/▶`.
4. Ejecutar:

```powershell
& 'C:\Users\ezega\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/smoke_test.gd
```
