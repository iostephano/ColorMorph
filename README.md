# ColorMorph — Playground de un campo de color animado con Metal

ColorMorph es una app de iOS que dibuja a pantalla completa un campo de color
procedural con un fragment shader de Metal: un patrón de `sin`/`cos` que se mueve en
el tiempo. Un panel de controles permite cambiar en vivo la velocidad, la densidad
del patrón y el brillo, o saltar entre presets con nombre. Existe como proyecto de
portafolio para mostrar cómo se integra un shader de Metal como fondo de una vista
SwiftUI y cómo se le pasan parámetros desde Swift, con esos parámetros modelados en
un tipo de valor puro y verificado por pruebas. Es la pareja "de color" de ShapeMorph.

---

## Tecnologías usadas

- Swift 6 (con verificación estricta de concurrencia activada)
- SwiftUI para la interfaz
- Metal / MetalKit para el render del fondo (`MTKView` vía `UIViewRepresentable`)
- `simd` para el tinte por canal
- Swift Testing para las pruebas
- Integración continua con GitHub Actions (compila y corre los tests en cada push/PR)
- Cero dependencias externas

---

## Cómo está organizado el proyecto

```
ColorMorph/
├── ColorMorphApp.swift              # @main
├── ContentView.swift                # ZStack: fondo Metal + panel de controles
├── Models/
│   └── ColorFieldParameters.swift   # Parámetros del shader: rangos, presets, clamp, lerp
├── Views/
│   ├── MetalBackgroundView.swift    # UIViewRepresentable sobre MTKView; envía los parámetros al shader
│   └── ControlsView.swift           # Presets + sliders (en español)
└── Shaders/
    └── AnimatedBackground.metal      # vertex (quad) + fragment (campo de color procedural)
```

`ColorFieldParameters` no importa Metal ni SwiftUI: es geometría de datos pura, y es
lo que cubren las pruebas.

---

## Cómo funciona / flujo principal

1. `ContentView` guarda un `ColorFieldParameters` en `@State` (arranca en el primer
   preset).
2. `MetalBackgroundView` crea un `MTKView` con un `Coordinator` que compila el
   pipeline (`vertexShader` + `animatedBackground`). Si algo del pipeline falla, la
   vista se queda en negro en vez de reventar.
3. A 60 fps, el `Coordinator` acumula el tiempo transcurrido (en `Double`, para no
   perder precisión) y en cada frame envía al fragment shader tres cosas por buffer:
   la resolución, el tiempo y los parámetros ya recortados a su rango válido
   (`ColorFieldParameters.ShaderFields`, seis `Float` que coinciden campo por campo
   con el `struct` del `.metal`).
4. El fragment shader calcula, para cada píxel, tres ondas (`sin`/`cos`) de la
   posición y el tiempo escaladas por `frequency` y `speed`, las combina en un color,
   lo tiñe por canal y lo multiplica por `brightness`.
5. `ControlsView` edita ese `@State` con sliders y botones de preset; SwiftUI vuelve
   a llamar a `updateUIView`, que empuja los nuevos parámetros al `Coordinator`.

---

## Funcionalidades / qué demuestra

- Un fragment shader de Metal como fondo a pantalla completa de una vista SwiftUI,
  vía `UIViewRepresentable` + `MTKViewDelegate`.
- Paso de parámetros tipados de Swift al shader por buffer, con una disposición plana
  que espeja el `struct` de Metal (verificado por un test de `MemoryLayout`).
- Modelo de parámetros con rangos, recorte (`clamped()`), interpolación (`lerp`) y
  presets con nombre, todo aislado de Metal y testeado.
- Manejo de errores de Metal sin `fatalError` ni force-unwrap: si el pipeline no se
  crea, no se dibuja nada en vez de crashear.

---

## Pruebas

`ColorMorphTests` (Swift Testing) cubre `ColorFieldParameters`:

- **`clamped()`**: los valores dentro de rango no se tocan; los que se salen vuelven
  al límite más cercano, canal por canal.
- **Presets**: todos están ya dentro de rango; el `default` es el primer preset; los
  nombres son únicos.
- **`lerp`**: en `t = 0` / `1` devuelve inicio / fin; en `0.5` el punto medio campo a
  campo (incluido el tinte); `t` se recorta a `0...1`.
- **`shaderFields`**: los seis `Float` reflejan los parámetros y quedan contiguos sin
  relleno (lo que espera el shader).

Correr los tests:

```bash
xcodebuild test \
  -project ColorMorph.xcodeproj \
  -scheme ColorMorph \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Cómo correr el proyecto

1. Clona el repo:
   ```bash
   git clone https://github.com/iostephano/ColorMorph.git
   ```
2. Abre `ColorMorph.xcodeproj` con **Xcode 26** (ver `.xcode-version`).
3. El objetivo mínimo es **iOS 26**. Elige un simulador de iPhone o un dispositivo con
   Metal y ejecuta (Cmd-R).
4. Toca los presets o mueve los sliders para ver cambiar el fondo en vivo.

---

## Cosas pendientes o limitadas (a propósito)

- **El cambio de preset es instantáneo**, no animado. `ColorFieldParameters.lerp` está
  hecho y probado para animarlo, pero no se usa desde la UI todavía.
- **El slider "Frecuencia" controla un solo valor**; el shader deriva las otras dos
  ondas como múltiplos fijos de ese (`0.8x` y `1.2x`).
- **El tiempo se acumula en `Double` y se pasa como `Float`**: en sesiones muy largas
  (horas) el `Float` pierde algo de resolución y la animación cuantiza un poco.
- **El shader es puramente procedural**: no lee texturas ni imágenes, y el patrón es
  el mismo `sin`/`cos` original, solo parametrizado.
- **Sin persistencia**: al cerrar la app se vuelve al primer preset.

---

## Autor

Stephano Portella
