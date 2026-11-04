# limpieza.R ------------------------------------------------------------------
library(dplyr)
library(stringr)
library(lubridate)

# Ejecutar con el proyecto abierto (.Rproj) para que las rutas relativas funcionen
raw <- read.csv("datos/crudos/2026-11-diagnostico_transporte_ags - Respuestas de formulario 1.csv",
                check.names = FALSE, fileEncoding = "UTF-8", na.strings = c("", "NA"))

# Toma la columna cuyo título empieza con "[código]", p. ej. col("4.1")
col <- function(codigo) {
  i <- which(startsWith(names(raw), paste0("[", codigo, "]")))
  if (length(i) == 0) return(rep(NA, nrow(raw)))
  raw[[i[1]]]
}

escala <- c("Muy insatisfecho", "Insatisfecho", "Neutral", "Satisfecho", "Muy satisfecho")
niveles_sat <- c("Vacío, muchos asientos libres", "Algunos asientos libres",
                 "Todos sentados, nadie de pie", "Algunas personas de pie",
                 "Lleno, difícil moverse")

datos <- data.frame(
  ts             = dmy_hms(raw[[1]], tz = "America/Mexico_City"),  # Marca temporal
  fuente         = col("0.1"),
  ruta_txt       = col("0.3"),
  ultimo_viaje   = col("0.4"),
  encuestador    = col("0.2"),
  s_encuestador  = col("0.5"),
  s_usuario      = col("0.6"),
  consentimiento = col("1.1"),
  mayor_edad     = col("1.2"),
  motivo         = col("2.1"),
  tarifa         = col("2.4"),
  espera         = as.numeric(col("3.1")),
  duracion       = as.numeric(col("3.3")),
  saturacion     = match(col("3.4"), niveles_sat),          # 1 = vacío ... 5 = lleno
  satisfaccion   = match(col("4.1"), escala),               # 1 ... 5
  viajes         = as.numeric(col("6.1")),
  inc_retraso    = as.numeric(col("6.2")),
  inc_omision    = as.numeric(col("6.3")),
  inc_inseg      = as.numeric(col("6.4")),
  prioridad      = col("7.1"),
  sexo           = col("8.1"),
  edad           = as.numeric(col("8.2")),
  ocupacion      = col("8.3"),
  acceso_auto    = col("8.5")
)

# --- Correcciones por errores de captura en la sección 6 ----------------------
# 1) Al inicio del levantamiento [6.4] exigía >= 1 y no permitía registrar 0, así
#    que cada encuestador capturó 1 en lugar de 0 en sus primeras entrevistas.
#    Por encuestador y en orden de hora, la racha inicial de 1 (sin contar filas
#    vacías) se corrige a 0.
corrige_ceros <- function(x) {
  for (i in which(!is.na(x))) {
    if (x[i] == 1) x[i] <- 0 else break
  }
  x
}

# 2) Centinelas: cada encuestador tecleó su propio código cuando no se pudo
#    capturar el dato (99, 666, 999, 1000, 9999). Aplica a retrasos, omisiones e
#    inseguridad; se recodifican a NA.
centinelas <- c(99, 666, 999, 1000, 9999)
a_na <- function(x) ifelse(x %in% centinelas, NA_real_, x)

datos <- datos |>
  arrange(ts) |>
  group_by(encuestador) |>
  mutate(inc_inseg = if (all(is.na(encuestador))) inc_inseg else corrige_ceros(inc_inseg)) |>
  ungroup() |>
  mutate(
    # encuesta nula según el encuestador: viajes = 999 (se excluye más abajo)
    encuesta_nula = viajes %in% 999,
    across(c(inc_retraso, inc_omision, inc_inseg), a_na)
  )

datos <- datos |>
  mutate(
    modo  = ifelse(fuente %in% c("P1", "P2", "P3"), "entrevista", "autoaplicada"),
    ruta  = ifelse(modo == "entrevista", 50, as.numeric(str_extract(ruta_txt, "\\d+"))),
    turno = ifelse(hour(ts) < 12, "mañana", "tarde"),
    sentido = case_when(
      str_detect(s_encuestador, "^Norte") ~ "N→S",
      str_detect(s_encuestador, "^Sur")   ~ "S→N",
      str_detect(s_usuario, regex("norte", ignore_case = TRUE)) ~ "S→N",
      str_detect(s_usuario, regex("sur",   ignore_case = TRUE)) ~ "N→S",
      TRUE ~ NA_character_
    ),
    satisfecho = as.integer(satisfaccion >= 4),             # Y = 1(S >= 4)
    incidentes = inc_retraso + inc_omision + inc_inseg,
    sexo = ifelse(sexo %in% c("Hombre", "Mujer"), sexo, NA), # otras categorías muy pequeñas
    prioridad = str_squish(prioridad),
    prioridad = case_when(
      str_to_lower(prioridad) %in% c("nada", "ninguna", "ninguno", "todo bien", "todo está bien") ~ "Ninguna",
      str_to_lower(prioridad) %in% c("na", "no se") ~ NA_character_,   # sin respuesta
      TRUE ~ prioridad
    ),
    motivo_exclusion = case_when(
      consentimiento != "Sí, acepto" | is.na(consentimiento) ~ "sin consentimiento",
      mayor_edad != "Sí" | is.na(mayor_edad)                 ~ "menor de edad",
      is.na(ruta) | ruta != 50                               ~ "otra ruta",
      ultimo_viaje %in% "Hace más de un mes"                 ~ "último viaje > 1 mes",
      encuesta_nula                                          ~ "encuesta nula (999)",
      TRUE ~ NA_character_
    )
  )

cat("Total de respuestas:", nrow(datos), "\n")
print(table(datos$motivo_exclusion, useNA = "ifany"))   # NA = válidas

validos <- filter(datos, is.na(motivo_exclusion))
cat("Válidas:", nrow(validos), "\n")
print(table(validos$fuente))
print(table(validos$turno, validos$sentido, useNA = "ifany"))

saveRDS(validos, "datos/limpios/datos_limpios.rds")
