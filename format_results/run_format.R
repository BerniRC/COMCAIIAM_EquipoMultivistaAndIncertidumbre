# ==========================================================
# run_format.R
# Este archivo se encarga de tomar los resultados generados
# por el modelo y producir resúmenes, gráficas, tablas y boxplots.
# ==========================================================

# ==========================================================
# CARGAR ARCHIVOS SEGÚN DESDE DÓNDE SE EJECUTE EL SCRIPT
# ==========================================================

if (file.exists("format_results_functions.R")) {
  source("format_results_functions.R")
} else if (file.exists(file.path("format_results", "format_results_functions.R"))) {
  source(file.path("format_results", "format_results_functions.R"))
} else {
  stop("No encontré format_results_functions.R. Ejecuta este script desde la carpeta raíz o desde format_results/.")
}

library(reticulate)
library(caret)
library(ggplot2)
library(kableExtra)
library(ggpubr)
library(ggrepel)

if (file.exists(file.path("..", "notebooks", "globals.py"))) {
  reticulate::source_python(file.path("..", "notebooks", "globals.py"))
} else if (file.exists(file.path("notebooks", "globals.py"))) {
  reticulate::source_python(file.path("notebooks", "globals.py"))
} else {
  stop("No encontré notebooks/globals.py. Revisa la estructura de carpetas.")
}

pwidth <- 5
pheight <- 5

# ==========================================================
# CONFIGURACIÓN DEL DATASET
# ==========================================================

DATA_FILE <- file.path(DATASET_PATH, "data.csv")

CLASS_COLUMN <- "class"

# Para 2 vistas:
VIEW_NAMES <- c(
  v1 = "Context",
  v2 = "NetworkFlow"
)

# Si después ocupas 3 vistas, comenta el VIEW_NAMES de arriba
# y usa este:
# VIEW_NAMES <- c(
#   v1 = "Context",
#   v2 = "NetworkFlow",
#   v3 = "log"
# )

# ==========================================================
# VALIDAR DATASET
# ==========================================================

if (!dir.exists(DATASET_PATH)) {
  stop(paste0(
    "No existe DATASET_PATH:\n",
    DATASET_PATH,
    "\n\nRevisa notebooks/globals.py o la carpeta data/htad."
  ))
}

if (!file.exists(DATA_FILE)) {
  stop(paste0(
    "No existe data.csv en:\n",
    DATA_FILE
  ))
}

df_data <- read.csv(DATA_FILE)

if (!(CLASS_COLUMN %in% colnames(df_data))) {
  stop(paste0(
    "No existe la columna de clase llamada: ",
    CLASS_COLUMN,
    "\n\nColumnas encontradas en data.csv:\n",
    paste(colnames(df_data), collapse = ", "),
    "\n\nCambia CLASS_COLUMN por el nombre correcto."
  ))
}

classes <- sort(unique(df_data[[CLASS_COLUMN]]))

write.csv(
  classes,
  file.path(DATASET_PATH, "classes.csv"),
  row.names = FALSE,
  col.names = FALSE,
  quote = FALSE
)

cat("classes.csv actualizado correctamente en:\n")
cat(file.path(DATASET_PATH, "classes.csv"), "\n\n")

# ==========================================================
# PREPARAR CARPETA results_1
# ==========================================================

results_dir <- file.path(DATASET_PATH, "results_1")

if (!dir.exists(results_dir)) {
  dir.create(results_dir, recursive = TRUE)
}

results_original <- file.path(DATASET_PATH, "results.csv")
results_target <- file.path(results_dir, "results.csv")

results_mvc_target <- file.path(results_dir, "results_mvc.csv")

if (!file.exists(results_original)) {
  stop(paste0(
    "No existe results.csv en:\n",
    results_original,
    "\n\nPrimero necesitas correr el modelo para generar results.csv."
  ))
}

file.copy(
  from = results_original,
  to = results_target,
  overwrite = TRUE
)

cat("results.csv copiado correctamente a:\n")
cat(results_target, "\n\n")

if (file.exists(results_mvc_target)) {
  file.remove(results_mvc_target)
  cat("results_mvc.csv viejo eliminado de results_1.\n\n")
}

# ==========================================================
# CREAR results_mvc.csv
# ==========================================================

if (length(VIEW_NAMES) == 2) {
  add.intersection.model.2v(DATASET_PATH)
} else if (length(VIEW_NAMES) == 3) {
  add.intersection.model(DATASET_PATH)
} else {
  stop("Este script solo está preparado para 2 o 3 vistas.")
}

cat("results_mvc.csv creado correctamente.\n\n")

# ==========================================================
# CAMBIAR NOMBRES DE MÉTODOS
# ==========================================================

change.method.names(
  dataset_path = DATASET_PATH,
  view_names = VIEW_NAMES
)

cat("Nombres de métodos cambiados correctamente.\n\n")

# ==========================================================
# GENERAR RESÚMENES Y GRÁFICAS
# ==========================================================

res1 <- summarize.iterations(DATASET_PATH, "1")

cat("summary_iterations.csv creado correctamente.\n\n")

res2 <- summarize.all(DATASET_PATH, "1")

cat("summary_all.csv creado correctamente.\n\n")

pairwise.occurrences(DATASET_PATH, "1", pwidth, pheight)

cat("Matrices de co-ocurrencia creadas correctamente.\n\n")

plot.confusion.matrix(DATASET_PATH, "1", pwidth, pheight)

cat("Matrices de confusión creadas correctamente.\n\n")

latex.summary(DATASET_PATH, "1")

cat("Tabla LaTeX creada correctamente.\n\n")

plot.scatter(DATASET_PATH)

cat("Scatter plot creado correctamente.\n\n")

plot.histograms(DATASET_PATH, DATASET_NAME)

cat("Histogramas creados correctamente.\n\n")

# ==========================================================
# BOXPLOTS
# ==========================================================

summary_iterations_file <- file.path(DATASET_PATH, "results_1", "summary_iterations.csv")

if (!file.exists(summary_iterations_file)) {
  stop(paste0(
    "No se creó summary_iterations.csv en:\n",
    summary_iterations_file
  ))
}

df <- read.csv(summary_iterations_file)

pdf(file.path(DATASET_PATH, "results_1", "boxplot_setsize.pdf"), 8, 7)
boxplot(setsize ~ method, df)
dev.off()

pdf(file.path(DATASET_PATH, "results_1", "boxplot_F1.pdf"), 8, 7)
boxplot(F1 ~ method, df)
dev.off()

cat("Boxplots creados correctamente.\n\n")

cat("============================================\n")
cat("run_format terminó correctamente.\n")
cat("Resultados guardados en:\n")
cat(file.path(DATASET_PATH, "results_1"), "\n")
cat("============================================\n")