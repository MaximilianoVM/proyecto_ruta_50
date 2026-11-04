# Diccionario de datos — `datos/limpios/datos_limpios.rds`

Generado por `scripts/01_limpieza.R` a partir de
`datos/crudos/2026-11-diagnostico_transporte_ags - Respuestas de formulario 1.csv`
(encuesta de diagnóstico de transporte, Ruta 50, Aguascalientes).

- **Unidad de observación:** una respuesta de encuesta.
- **Tamaño:** 138 filas × 32 columnas (de 146 respuestas crudas se excluyen 8, ver [Filtros de exclusión](#filtros-de-exclusión)).
- **Código `[x.y]`:** número de la pregunta en el formulario. Las columnas se localizan por ese prefijo, no por posición (salvo `ts`).
- Las celdas vacías o `"NA"` del CSV se leen como `NA`.

## Variables tomadas directamente de la encuesta

| Variable | Pregunta | Tipo | Valores / unidades |
|---|---|---|---|
| `ts` | Marca temporal (columna 1, automática de Google Forms) | POSIXct (America/Mexico_City) | Se lee con formato día/mes/año. Rango: 2026-11-03 06:16 a 19:36. |
| `fuente` | [0.1] Fuente (viene premarcada) | texto | `P1`, `P2`, `P3` = puntos de entrevista presencial; `Enlace` = formulario autoaplicado por enlace. |
| `ruta_txt` | [0.3] ¿En qué ruta fue su viaje más reciente? (ej. 01, 50) | entero | Solo se pregunta en autoaplicada; `NA` en entrevistas (124). |
| `ultimo_viaje` | [0.4] ¿Cuándo fue su último viaje en esa ruta? | texto | `Hoy`, `Esta semana`; `NA` en entrevistas. (`Hace más de un mes` se excluye.) |
| `encuestador` | [0.2] Entrevistador (lo registra el encuestador) | texto | `AJM` (29), `JBG` (19), `JPA` (13), `MAC` (21), `MVM` (10), `RCP` (15), `SHM` (16); `NA` en autoaplicada (15). Se usa para corregir `inc_inseg` (ver [Correcciones](#correcciones-de-captura-sección-6)). |
| `s_encuestador` | [0.5] Sentido (lo registra el encuestador) | texto | `Norte → Sur`, `Sur →Norte`; `NA` en autoaplicada. |
| `s_usuario` | [0.6] ¿Hacia dónde iba el camión en ese viaje? | texto | `Hacia el norte (rumbo a Av. Gerónimo de la Cueva)`, `Hacia el sur (rumbo a Blvd. José Ma. Chávez / Av. Tecnológico)`; `NA` en entrevistas. |
| `consentimiento` | [1.1] ¿Acepta participar en la encuesta? | texto | Siempre `Sí, acepto` en los datos limpios. |
| `mayor_edad` | [1.2] ¿Tiene 18 años o más? | texto | Siempre `Sí` en los datos limpios. |
| `motivo` | [2.1] Motivo del viaje | texto | `Trabajo` (94), `Estudio` (19), `Regreso a casa` (18), `Compras`, `Trámites o salud`, `Gimnasio`, `Recreación o visita`. |
| `tarifa` | [2.4] Tipo de tarifa | texto | `General` (118), `Estudiante` (17), `Adulto mayor` (3). |
| `espera` | [3.1] Espera percibida en minutos | numérico (min) | 3–60, mediana 15. |
| `duracion` | [3.3] Duración total del viaje en minutos | numérico (min) | 1–120, mediana 30. |
| `saturacion` | [3.4] Saturación | entero 1–5 | 1 = Vacío, muchos asientos libres · 2 = Algunos asientos libres · 3 = Todos sentados, nadie de pie · 4 = Algunas personas de pie · 5 = Lleno, difícil moverse. Mediana 5. |
| `satisfaccion` | [4.1] En general, ¿qué tan satisfecho(a) está con el servicio utilizado en este viaje? | entero 1–5 | 1 = Muy insatisfecho · 2 = Insatisfecho · 3 = Neutral · 4 = Satisfecho · 5 = Muy satisfecho. |
| `viajes` | [6.1] viajes (sección «Últimos 30 días») | numérico | Número de viajes en los **últimos 30 días**, 1–288, mediana 30. Sin `NA`. Los valores altos (hasta 288) son plausibles por la frecuencia de uso, ida y vuelta y transbordos. Ver [Sección 6](#sección-6-últimos-30-días). |
| `inc_retraso` | [6.2] retrasos (sección «Últimos 30 días») | numérico | Número de retrasos en los últimos 30 días. Centinelas → `NA` (9 `NA`). |
| `inc_omision` | [6.3] omisiones de parada (sección «Últimos 30 días») | numérico | Número de omisiones de parada en los últimos 30 días. Centinelas → `NA` (14 `NA`). |
| `inc_inseg` | [6.4] inseguridad o acoso (sección «Últimos 30 días») | numérico | Número de eventos de inseguridad o acoso en los últimos 30 días. Primeros 1 corregidos a 0 y centinelas → `NA` (29 `NA`). |
| `prioridad` | [7.1] Prioridad de mejora | texto | **Normalizada** (ver abajo). Categorías del formulario: `Menor tiempo de espera` (37), `Menos saturación` (31), `Puntualidad` (21), `Tarifa` (6), `Información de rutas y horarios` (5), `Accesibilidad` (4), `Comodidad de las unidades` (2), `Limpieza` (2), `Trato del chofer` (2). `Ninguna` (12) agrupa a quienes no piden mejora. 1 `NA`. El resto (~20) son respuestas abiertas únicas, sin recodificar. |
| `sexo` | [8.1] sexo | texto | `Hombre` (72), `Mujer` (66). Otras categorías se recodifican a `NA` (no hay ninguna en los datos limpios). |
| `edad` | [8.2] edad | numérico (años) | 18–69, mediana 38. |
| `ocupacion` | [8.3] ocupación | texto | `Empleado(a)` (95), `Estudiante` (28), `Trabajo por cuenta propia` (5), y ocupaciones abiertas con 1–2 casos. |
| `acceso_auto` | [8.5] acceso a auto | texto | `No` (114), `Sí` (24). |

## Variables derivadas

| Variable | Cálculo | Valores |
|---|---|---|
| `modo` | `fuente` ∈ {P1, P2, P3} → entrevista; si no, autoaplicada | `entrevista` (123), `autoaplicada` (15) |
| `ruta` | 50 si `modo` es entrevista; si no, el primer número de `ruta_txt` | 50 en todos los datos limpios |
| `turno` | hora de `ts` < 12 → mañana; si no, tarde | `mañana` (77), `tarde` (61) |
| `sentido` | Prioriza `s_encuestador`; si es `NA`, usa `s_usuario` **invirtiendo** la lectura: "Hacia el norte" → `S→N`, "Hacia el sur" → `N→S` (el camión va hacia ese destino, el viaje parte del extremo opuesto) | `N→S` (71), `S→N` (67) |
| `satisfecho` | `1` si `satisfaccion` ≥ 4, `0` en otro caso (variable respuesta Y de la regresión logística) | 0/1; proporción de 1 = 0.572 |
| `incidentes` | `inc_retraso + inc_omision + inc_inseg` (suma de eventos en los últimos 30 días) | numérico; `NA` si cualquiera de las tres columnas es `NA` (35 filas). Sin `NA`: mediana 5, media 20.2, máx. 400. |
| `encuesta_nula` | `TRUE` si `viajes` = 999 (el encuestador indicó que esa encuesta es nula) | `FALSE` en todos los datos limpios |
| `motivo_exclusion` | Primer criterio de exclusión que cumple la fila | `NA` en todos los datos limpios (ver abajo) |

## Normalización de `prioridad`

En `scripts/01_limpieza.R`: se quitan espacios sobrantes (`str_squish`) y después
- `Nada`, `Ninguna`, `Ninguno`, `Todo bien`, `Todo está bien` (sin distinguir mayúsculas) → `Ninguna`;
- `Na`, `No se` → `NA` (sin respuesta);
- cualquier otro texto se deja igual. Las respuestas abiertas únicas (p. ej. «Que la gente se recorra», «Seguridad») no se agrupan: hacerlo implicaría un criterio de codificación que conviene decidir aparte.

## Filtros de exclusión

`motivo_exclusion` se evalúa en este orden y se conservan solo las filas con `NA`:

1. `sin consentimiento` — `consentimiento` distinto de `Sí, acepto` (1 fila).
2. `menor de edad` — `mayor_edad` distinto de `Sí` (4 filas).
3. `otra ruta` — `ruta` ausente o distinta de 50 (1 fila).
4. `último viaje > 1 mes` — `ultimo_viaje` = `Hace más de un mes` (1 fila).

5. `encuesta nula (999)` — `viajes` = 999; según el encuestador esa encuesta es nula (1 fila).

Total: 146 respuestas → 138 válidas.

## Notas sobre el diseño del formulario

- Total de respuestas del formulario: 146 (P1 61, P2 51, P3 16, Enlace 18; las opciones QR1–QR3 no se usaron). Las preguntas `[0.2]`, `[0.5]` las llena el encuestador (128 respuestas); `[0.3]`, `[0.4]`, `[0.6]` solo el usuario en la versión por enlace (18).
- `[0.3]` es texto libre: `01` (1) y `50` (17) en el formulario. `[0.4]` tiene además la opción `Este mes` (0 respuestas). `[0.6]` tiene además `No sé` (1 respuesta; esa fila no queda en los datos limpios porque no se puede asignar sentido).
- `[2.4]` Tipo de tarifa también ofrece `Embarazada`, `Persona con discapacidad` y `Otra` (0 respuestas). `[2.5]` solo se contesta si hay descuento (21 respuestas: 3 `Sí`, 18 `No`).
- `[5.1]` usa la escala de satisfacción de 5 puntos más `No sé / No aplica`.
- `[8.1]` y `[8.4]` incluyen `Prefiero no responder` (0 respuestas). `[9.3]` Motivo solo se llena si la persona rechazó o interrumpió (1 `Rechazó participar`).
- `[2.2]` Días por semana va de `Menos de 1` a `7`; `[2.3]` Transbordos de 0 a 5.

## Columnas del formulario que NO pasan a los datos limpios

`[0.2]` Entrevistador, `[2.2]` Días por semana, `[2.3]` Transbordos, `[2.5]` Problemas con el descuento,
`[5.1]` Satisfacción por aspecto (8 columnas: puntualidad y frecuencia, limpieza, comodidad, trato del chofer,
seguridad personal, facilidad para subir y bajar, información de rutas y horarios, relación precio–calidad),
`[8.4]` discapacidad, `[9.1]` Comentario, `[9.3]` Motivo.
Si se necesitan, hay que agregarlas al `data.frame` en `scripts/01_limpieza.R` con `col("código")`.

## Sección 6: últimos 30 días

Las cuatro preguntas `[6.1]`–`[6.4]` están bajo el encabezado **«Últimos 30 días»** del formulario. El texto de cada pregunta es solo su título
(«viajes», «retrasos», «omisiones de parada», «inseguridad o acoso»), así que se interpretan como **conteos de eventos en los 30 días previos a la encuesta**.
`incidentes` es la suma de los tres últimos.

### Correcciones de captura (sección 6)

Se aplican en `scripts/01_limpieza.R` antes de calcular variables derivadas, según lo informado por el equipo de levantamiento:

1. **Ceros capturados como 1 en `inc_inseg` ([6.4]).** Al inicio del levantamiento la pregunta exigía un valor ≥ 1 y no permitía registrar 0, por lo que los
   encuestadores anotaron 1 en lugar de 0. Por encuestador, en orden de hora (`ts`) y sin contar filas vacías, la **racha inicial de valores 1 se corrige a 0**
   (se detiene en el primer valor distinto de 1). Efecto: AJM 2 filas, JPA 3, SHM 2, RCP 1, JBG 2. **MAC no se corrige**: su primer valor es 2, lo que rompe la racha
   (2, 1, 1, 1, 1 quedan tal cual). Las respuestas autoaplicadas no se corrigen (no tienen encuestador).
2. **Centinelas → `NA`.** Cuando no se pudo capturar el dato, cada encuestador tecleó su propio código: 99 (MAC, JPA, SHM), 666 (RCP), 999 y 9999 (AJM), 1000 (JBG).
   Aparecen en `inc_retraso`, `inc_omision` e `inc_inseg` (por un malentendido la instrucción se aplicó a los tres campos). Los códigos 99, 666, 999, 1000 y 9999 pasan a `NA`
   en esas tres columnas. Es una lista exacta: valores altos que no son códigos (retrasos 100, 160, 200; omisiones 200) se conservan porque se consideran verosímiles.
3. **Encuesta nula.** Una fila tiene `viajes` = 999; el encuestador indicó que toda esa encuesta es nula y se excluye (`encuesta nula (999)`).

`NA` resultantes: `inc_retraso` 9, `inc_omision` 14, `inc_inseg` 29, `incidentes` 35 (de 138 filas).

### Valores altos que se conservan

- `viajes` > 60 en 30 días (23 filas, hasta 210, 211 y 288) se consideran plausibles: uso de 5–7 días por semana, ida y vuelta y transbordos
  (los viajes pueden incluir tramos de otras rutas además de la 50).
- Algunas filas tienen `retrasos`, `omisiones` o `inseguridad` mayores que `viajes`; no se corrigen. Puede deberse al conteo de tramos de otras rutas.

## Advertencias

- **Sección 6:** `inc_retraso`, `inc_omision`, `inc_inseg` e `incidentes` tienen `NA` por centinelas (ver [Correcciones](#correcciones-de-captura-sección-6)); hay que decidir cómo tratarlos en `06_poisson.R` (casos completos u otra estrategia). La corrección de 1 → 0 depende de la regla de racha inicial por encuestador (MAC sin corregir).
- Una sola ruta (50) y un solo día de levantamiento (2026-11-03).
