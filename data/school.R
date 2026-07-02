# ============================================================
# Dataset didattico per Simpson's paradox
# 15 scuole, SES su scala realistica 1-10
#
# Variabili finali:
# - school_id
# - ses
# - school_climate
# - motivation
# - homework
# - math
#
# Pattern voluto:
# - complessivamente: homework -> math negativo
# - dentro ogni scuola: homework -> math positivo
#
# Variabili aggiuntive:
# - school_climate: variabile a livello scuola
# - motivation: variabile a livello studente
# ============================================================

library(dplyr)
library(ggplot2)

set.seed(2026)

# -----------------------------
# 1. Definizione delle scuole
# -----------------------------

n_school <- 15
n_student <- 35

school_df <- data.frame(
  school_id = factor(1:n_school),

  # SES medio della scuola su scala 1-10:
  # 1 = contesto molto svantaggiato
  # 10 = contesto molto avvantaggiato
  ses = seq(2.0, 9.0, length.out = n_school)
)

school_df <- school_df %>%
  mutate(
    # Clima scolastico medio su scala 1-10.
    # È debolmente associato al SES, ma non coincide con il SES.
    school_climate = 4.5 + 0.35 * ses + rnorm(n_school, mean = 0, sd = 0.70),
    school_climate = pmin(pmax(school_climate, 1), 10),

    # Scuole con SES più basso assegnano più compiti
    homework_mean = 8.5 - 0.55 * ses,

    # Scuole con SES più alto hanno rendimento medio più alto.
    # Il clima scolastico contribuisce positivamente.
    math_mean = 62 + 5.0 * ses + 1.5 * (school_climate - mean(school_climate))
  )

# -----------------------------
# 2. Simulazione studenti
# -----------------------------

d_simpson <- school_df %>%
  slice(rep(1:n(), each = n_student)) %>%
  group_by(school_id) %>%
  mutate(
    student_id = row_number(),

    # Motivazione individuale allo studio su scala 1-10.
    # È leggermente più alta in scuole con clima migliore,
    # ma ha ampia variabilità individuale.
    motivation = 4.8 +
      0.25 * school_climate +
      rnorm(n(), mean = 0, sd = 1.20),
    motivation = pmin(pmax(motivation, 1), 10),

    # Ore settimanali di compiti di matematica.
    # Ogni studente varia attorno alla media della propria scuola.
    homework = homework_mean + rnorm(n(), mean = 0, sd = 0.65),

    # Punteggio in matematica.
    # Dentro ogni scuola, l'effetto dei compiti è positivo.
    # Anche la motivazione individuale ha un effetto positivo.
    math = math_mean +
      3.8 * (homework - homework_mean) +
      1.4 * (motivation - mean(motivation)) +
      rnorm(n(), mean = 0, sd = 2.5)
  ) %>%
  ungroup() %>%
  transmute(
    school_id,
    ses = round(ses, 1),
    school_climate = round(school_climate, 1),
    motivation = round(motivation, 1),
    homework = round(homework, 2),
    math = round(math, 1)
  )

saveRDS(d_simpson, "data/school.rds")
