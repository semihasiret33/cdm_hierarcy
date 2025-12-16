################################################################################
# GDINA ANALİZİ - KENDİ VERİNİZLE KULLANMAK İÇİN ŞABLON
################################################################################
#
# Bu şablon scripti kendi verilerinizle GDINA analizi yapmak için kullanın.
# İlgili bölümleri kendi verilerinize göre düzenleyin.
#
################################################################################

# Gerekli Paketler -------------------------------------------------------------
packages <- c("GDINA", "Qval", "CDM", "lattice", "ggplot2")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

cat("GDINA Analizi Başlatılıyor...\n\n")

# Çıktı klasörü
output_dir <- "my_gdina_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

################################################################################
# 1. VERİ YÜKLEME
################################################################################

cat("1. Veri Yükleniyor...\n\n")

# SEÇENEK A: CSV'den yükleme ---------------------------------------------------
# Yanıt verisi (1-0 formatında)
# data <- read.csv("your_response_data.csv", header = TRUE)
# data <- as.matrix(data)

# Q-matrix
# Q <- read.csv("your_qmatrix.csv", header = TRUE)
# Q <- as.matrix(Q)


# SEÇENEK B: Excel'den yükleme -------------------------------------------------
# library(readxl)
# data <- read_excel("your_data.xlsx", sheet = "Responses")
# data <- as.matrix(data)
# Q <- read_excel("your_data.xlsx", sheet = "Qmatrix")
# Q <- as.matrix(Q)


# SEÇENEK C: Manuel tanımlama (küçük veri setleri için) ------------------------
# Örnek veri (BU BÖLÜMÜ KENDİ VERİNİZLE DEĞİŞTİRİN)

# Yanıt verisi: Öğrenciler x Maddeler (1=doğru, 0=yanlış)
data <- matrix(c(
  # Item1, Item2, Item3, Item4, Item5, ... (her satır bir öğrenci)
  1, 0, 1, 1, 0,
  1, 1, 1, 0, 1,
  0, 0, 1, 1, 0,
  1, 1, 0, 1, 1,
  0, 1, 1, 1, 0
), ncol = 5, byrow = TRUE)  # ncol = madde sayısı

# Q-matrix: Maddeler x Bilişsel Özellikler (1=gerekli, 0=gerekli değil)
Q <- matrix(c(
  # Attr1, Attr2, Attr3 (her satır bir madde)
  1, 0, 0,  # Item 1: Sadece Attr1
  1, 1, 0,  # Item 2: Attr1 ve Attr2
  0, 1, 0,  # Item 3: Sadece Attr2
  0, 1, 1,  # Item 4: Attr2 ve Attr3
  1, 1, 1   # Item 5: Tüm özellikler
), ncol = 3, byrow = TRUE)  # ncol = özellik sayısı

# Özellik isimleri (KENDİ ÖZELLİKLERİNİZE GÖRE DEĞİŞTİRİN)
colnames(Q) <- c("BasicSkill", "IntermediateSkill", "AdvancedSkill")

# Madde isimleri (opsiyonel)
rownames(Q) <- paste0("Item", 1:nrow(Q))


# VERİ KONTROLÜ ----------------------------------------------------------------
cat("Veri Bilgileri:\n")
cat(sprintf("  - Öğrenci sayısı: %d\n", nrow(data)))
cat(sprintf("  - Madde sayısı: %d\n", ncol(data)))
cat(sprintf("  - Bilişsel özellik sayısı: %d\n", ncol(Q)))
cat(sprintf("  - Ortalama doğru cevap oranı: %.2f%%\n\n",
            mean(data, na.rm = TRUE) * 100))

# Q-matrix kontrolü
if (nrow(Q) != ncol(data)) {
  stop("HATA: Q-matrix satır sayısı, veri madde sayısına eşit olmalı!")
}

cat("Q-Matrix:\n")
print(Q)
cat("\n")

cat("Q-Matrix İstatistikleri:\n")
cat(sprintf("  - Ortalama özellik sayısı/madde: %.2f\n", mean(rowSums(Q))))
cat("\nÖzellik Dağılımı:\n")
print(colSums(Q))
cat("\n")

################################################################################
# 2. MODEL TAHMİNLEME
################################################################################

cat("\n2. Model Tahminleme...\n\n")

# GDINA Modeli -----------------------------------------------------------------
cat("  2.1 GDINA modeli tahminleniyor...\n")
fit_GDINA <- GDINA::GDINA(
  dat = data,
  Q = Q,
  model = "GDINA",
  control = list(maxitr = 2000)
)

# DINA Modeli ------------------------------------------------------------------
cat("  2.2 DINA modeli tahminleniyor...\n")
fit_DINA <- GDINA::GDINA(
  dat = data,
  Q = Q,
  model = "DINA",
  control = list(maxitr = 2000)
)

# DINO Modeli ------------------------------------------------------------------
cat("  2.3 DINO modeli tahminleniyor...\n")
fit_DINO <- GDINA::GDINA(
  dat = data,
  Q = Q,
  model = "DINO",
  control = list(maxitr = 2000)
)

# ACDM Modeli ------------------------------------------------------------------
cat("  2.4 ACDM modeli tahminleniyor...\n")
fit_ACDM <- GDINA::GDINA(
  dat = data,
  Q = Q,
  model = "ACDM",
  control = list(maxitr = 2000)
)

cat("\n  Tüm modeller başarıyla tahminlendi!\n\n")

################################################################################
# 3. MODEL KARŞILAŞTIRMA
################################################################################

cat("\n3. Model Karşılaştırma\n\n")

models_list <- list(
  GDINA = fit_GDINA,
  DINA = fit_DINA,
  DINO = fit_DINO,
  ACDM = fit_ACDM
)

# Fit statistics
fit_stats <- data.frame(
  Model = names(models_list),
  Deviance = NA,
  AIC = NA,
  BIC = NA,
  CAIC = NA,
  n_par = NA
)

for (i in 1:length(models_list)) {
  fit <- modelfit(models_list[[i]])
  fit_stats$Deviance[i] <- fit$deviance
  fit_stats$AIC[i] <- fit$AIC
  fit_stats$BIC[i] <- fit$BIC
  fit_stats$CAIC[i] <- fit$CAIC
  fit_stats$n_par[i] <- fit$npar
}

cat("Model Fit İstatistikleri:\n")
print(fit_stats)
cat("\n")

# En iyi model
best_model_idx <- which.min(fit_stats$BIC)
best_model_name <- fit_stats$Model[best_model_idx]
cat(sprintf("En iyi model (BIC'e göre): %s (BIC = %.2f)\n\n",
            best_model_name, fit_stats$BIC[best_model_idx]))

# Model karşılaştırma grafiği
pdf(file.path(output_dir, "model_comparison.pdf"), width = 10, height = 6)
par(mfrow = c(1, 2))

barplot(fit_stats$BIC,
        names.arg = fit_stats$Model,
        main = "Model Karşılaştırma (BIC)",
        ylab = "BIC",
        col = "steelblue",
        las = 2)

barplot(fit_stats$AIC,
        names.arg = fit_stats$Model,
        main = "Model Karşılaştırma (AIC)",
        ylab = "AIC",
        col = "coral",
        las = 2)

dev.off()
cat("Model karşılaştırma grafiği kaydedildi.\n\n")

# Likelihood Ratio Test
cat("Likelihood Ratio Test (DINA vs GDINA):\n")
lrt <- anova(fit_DINA, fit_GDINA)
print(lrt)
cat("\n")

################################################################################
# 4. Q-MATRIX VALIDATION
################################################################################

cat("\n4. Q-Matrix Validation\n\n")

# CDM paketi formatına çevir
fit_CDM <- CDM::gdina(
  data = data,
  q.matrix = Q,
  rule = "GDINA"
)

# Hull method
cat("  4.1 Hull method ile validation...\n")
Q_Hull <- tryCatch({
  Qval::validation(
    data = data,
    q.matrix = Q,
    CDM.obj = fit_CDM,
    method = "Hull"
  )
}, error = function(e) {
  cat("    Hull method hatası (büyük Q-matrix için normal olabilir)\n")
  NULL
})

# MLR-B method
cat("  4.2 MLR-B method ile validation...\n")
Q_MLR <- tryCatch({
  Qval::validation(
    data = data,
    q.matrix = Q,
    CDM.obj = fit_CDM,
    method = "MLR-B"
  )
}, error = function(e) {
  cat("    MLR-B method hatası\n")
  NULL
})

# Validation sonuçları
if (!is.null(Q_Hull) && !is.null(Q_Hull$Q.sug)) {
  cat("\nHull Method Sonuçları:\n")
  qrr_hull <- Qval::zQRR(Q, Q_Hull$Q.sug)
  usr_hull <- Qval::zUSR(Q, Q_Hull$Q.sug)
  osr_hull <- Qval::zOSR(Q, Q_Hull$Q.sug)

  cat(sprintf("  - QRR (Recovery Rate): %.2f%%\n", qrr_hull * 100))
  cat(sprintf("  - USR (Underspecification): %.2f%%\n", usr_hull * 100))
  cat(sprintf("  - OSR (Overspecification): %.2f%%\n", osr_hull * 100))
  cat("\n")

  # Suggested Q-matrix'i kaydet
  write.csv(Q_Hull$Q.sug,
            file.path(output_dir, "Q_matrix_hull_suggested.csv"))
  cat("  Hull suggested Q-matrix kaydedildi.\n\n")
}

if (!is.null(Q_MLR) && !is.null(Q_MLR$Q.sug)) {
  cat("MLR-B Method Sonuçları:\n")
  qrr_mlr <- Qval::zQRR(Q, Q_MLR$Q.sug)
  usr_mlr <- Qval::zUSR(Q, Q_MLR$Q.sug)
  osr_mlr <- Qval::zOSR(Q, Q_MLR$Q.sug)

  cat(sprintf("  - QRR (Recovery Rate): %.2f%%\n", qrr_mlr * 100))
  cat(sprintf("  - USR (Underspecification): %.2f%%\n", usr_mlr * 100))
  cat(sprintf("  - OSR (Overspecification): %.2f%%\n", osr_mlr * 100))
  cat("\n")

  # Suggested Q-matrix'i kaydet
  write.csv(Q_MLR$Q.sug,
            file.path(output_dir, "Q_matrix_mlr_suggested.csv"))
  cat("  MLR-B suggested Q-matrix kaydedildi.\n\n")
}

################################################################################
# 5. ITEM FIT ANALYSIS
################################################################################

cat("\n5. Item Fit Analysis\n\n")

# En iyi modeli kullan
best_fit <- models_list[[best_model_name]]

item_fit <- GDINA::itemfit(best_fit, method = "transformed")
cat("Item Fit İstatistikleri:\n")
print(item_fit)
cat("\n")

# Problematic items
problem_items <- which(item_fit$pval < 0.05)
if (length(problem_items) > 0) {
  cat(sprintf("Uyum sorunu olan madde sayısı: %d\n", length(problem_items)))
  cat("Problematic items:", paste(problem_items, collapse = ", "), "\n")
  cat("Bu maddelerin Q-matrix girdileri gözden geçirilmeli!\n\n")
} else {
  cat("Uyum sorunu olan madde bulunmamaktadır.\n\n")
}

# Item fit'i kaydet
write.csv(item_fit, file.path(output_dir, "item_fit_statistics.csv"),
          row.names = FALSE)

################################################################################
# 6. PERSON FIT ANALYSIS
################################################################################

cat("\n6. Person Fit Analysis\n\n")

person_fit <- GDINA::personfit(best_fit, method = "lz")

cat("Person Fit İstatistikleri:\n")
cat(sprintf("  - Ortalama lz: %.3f\n", mean(person_fit$lz, na.rm = TRUE)))
cat(sprintf("  - Standart sapma: %.3f\n", sd(person_fit$lz, na.rm = TRUE)))
cat(sprintf("  - Min: %.3f\n", min(person_fit$lz, na.rm = TRUE)))
cat(sprintf("  - Max: %.3f\n", max(person_fit$lz, na.rm = TRUE)))

# Aberrant respondents
aberrant <- which(abs(person_fit$lz) > 2)
cat(sprintf("\nAberrant yanıt veren öğrenci sayısı: %d (%.1f%%)\n",
            length(aberrant),
            length(aberrant) / nrow(data) * 100))

if (length(aberrant) > 0) {
  cat("Aberrant respondents:", paste(aberrant, collapse = ", "), "\n")
  cat("Bu öğrenciler detaylı incelenmelidir.\n\n")
}

# Person fit'i kaydet
write.csv(person_fit, file.path(output_dir, "person_fit_statistics.csv"),
          row.names = FALSE)

################################################################################
# 7. BİLİŞSEL ÖZELLİK SINIFLANDIRMASI
################################################################################

cat("\n7. Bilişsel Özellik Sınıflandırması\n\n")

# EAP estimates
est_alpha <- personparm(best_fit, what = "EAP")

# Hakimiyet oranları
cat("Özellik Hakimiyet Oranları:\n")
mastery_rates <- colMeans(est_alpha)
for (k in 1:ncol(Q)) {
  cat(sprintf("  - %s: %.1f%%\n", colnames(Q)[k], mastery_rates[k] * 100))
}
cat("\n")

# Sınıflandırma sonuçlarını kaydet
colnames(est_alpha) <- colnames(Q)
write.csv(est_alpha, file.path(output_dir, "attribute_classifications.csv"))

# Hakimiyet grafiği
pdf(file.path(output_dir, "attribute_mastery.pdf"), width = 10, height = 6)
barplot(mastery_rates * 100,
        names.arg = colnames(Q),
        main = "Bilişsel Özellik Hakimiyet Oranları",
        ylab = "Hakimiyet Oranı (%)",
        col = rainbow(ncol(Q)),
        las = 2,
        ylim = c(0, 100))
abline(h = 50, lty = 2, col = "red")
text(x = 1:ncol(Q), y = mastery_rates * 100 + 5,
     labels = sprintf("%.1f%%", mastery_rates * 100))
dev.off()

cat("Hakimiyet grafiği kaydedildi.\n\n")

################################################################################
# 8. DETAYLI ITEM PARAMETRELERI
################################################################################

cat("\n8. Item Parametreleri\n\n")

# DINA için (eğer en iyi model DINA ise)
if (best_model_name == "DINA") {
  guess_slip <- data.frame(
    Item = rownames(Q),
    Guessing = NA,
    Slip = NA
  )

  for (i in 1:nrow(Q)) {
    params <- coef(best_fit, what = "catprob")[[i]]
    guess_slip$Guessing[i] <- params[1, 2]
    guess_slip$Slip[i] <- 1 - params[2, 2]
  }

  cat("DINA Parametreleri:\n")
  print(guess_slip)
  cat("\n")

  cat("Özet İstatistikler:\n")
  cat(sprintf("  - Ortalama Guessing: %.3f (SD: %.3f)\n",
              mean(guess_slip$Guessing), sd(guess_slip$Guessing)))
  cat(sprintf("  - Ortalama Slip: %.3f (SD: %.3f)\n\n",
              mean(guess_slip$Slip), sd(guess_slip$Slip)))

  write.csv(guess_slip, file.path(output_dir, "dina_parameters.csv"),
            row.names = FALSE)

  # Guess-Slip grafiği
  pdf(file.path(output_dir, "guess_slip_plot.pdf"), width = 12, height = 6)
  par(mfrow = c(1, 2))

  barplot(guess_slip$Guessing,
          names.arg = guess_slip$Item,
          main = "DINA: Guessing Parameters",
          ylab = "Guessing Probability",
          col = "orange",
          las = 2,
          cex.names = 0.7)
  abline(h = 0.25, lty = 2, col = "red")

  barplot(guess_slip$Slip,
          names.arg = guess_slip$Item,
          main = "DINA: Slip Parameters",
          ylab = "Slip Probability",
          col = "skyblue",
          las = 2,
          cex.names = 0.7)
  abline(h = 0.15, lty = 2, col = "red")

  dev.off()
  cat("Guess-Slip grafiği kaydedildi.\n\n")
}

# GDINA için tüm parametreler
item_params_all <- coef(best_fit)
saveRDS(item_params_all, file.path(output_dir, "item_parameters_all.rds"))
cat("Tüm item parametreleri kaydedildi (RDS format).\n\n")

################################################################################
# 9. GÖRSELLEŞTİRMELER
################################################################################

cat("\n9. Ek Görselleştirmeler\n\n")

# Q-matrix heatmap
pdf(file.path(output_dir, "qmatrix_heatmap.pdf"), width = 10, height = 8)
heatmap(Q,
        Rowv = NA,
        Colv = NA,
        scale = "none",
        col = c("white", "darkblue"),
        main = "Q-Matrix Heatmap",
        xlab = "Bilişsel Özellikler",
        ylab = "Maddeler")
dev.off()

cat("Q-matrix heatmap kaydedildi.\n\n")

################################################################################
# 10. ÖZET RAPOR
################################################################################

cat("\n################################################################################\n")
cat("ANALİZ ÖZET RAPORU\n")
cat("################################################################################\n\n")

cat(sprintf("Öğrenci Sayısı: %d\n", nrow(data)))
cat(sprintf("Madde Sayısı: %d\n", ncol(data)))
cat(sprintf("Bilişsel Özellik Sayısı: %d\n", ncol(Q)))
cat(sprintf("\nEn İyi Model: %s\n", best_model_name))
cat(sprintf("BIC: %.2f\n", fit_stats$BIC[best_model_idx]))
cat(sprintf("AIC: %.2f\n", fit_stats$AIC[best_model_idx]))
cat(sprintf("Parametre Sayısı: %d\n", fit_stats$n_par[best_model_idx]))

cat("\nÖzellik Hakimiyet Oranları:\n")
for (k in 1:ncol(Q)) {
  cat(sprintf("  %s: %.1f%%\n", colnames(Q)[k], mastery_rates[k] * 100))
}

cat(sprintf("\nUyum Sorunu Olan Madde Sayısı: %d\n", length(problem_items)))
cat(sprintf("Aberrant Öğrenci Sayısı: %d (%.1f%%)\n",
            length(aberrant),
            length(aberrant) / nrow(data) * 100))

cat("\n=== Çıktı Dosyaları ===\n\n")
cat(sprintf("Tüm dosyalar '%s' klasörüne kaydedildi:\n", output_dir))
cat("  - model_comparison.pdf\n")
cat("  - attribute_mastery.pdf\n")
cat("  - qmatrix_heatmap.pdf\n")
cat("  - item_fit_statistics.csv\n")
cat("  - person_fit_statistics.csv\n")
cat("  - attribute_classifications.csv\n")
if (best_model_name == "DINA") {
  cat("  - dina_parameters.csv\n")
  cat("  - guess_slip_plot.pdf\n")
}
cat("  - item_parameters_all.rds\n")
if (!is.null(Q_Hull)) cat("  - Q_matrix_hull_suggested.csv\n")
if (!is.null(Q_MLR)) cat("  - Q_matrix_mlr_suggested.csv\n")

cat("\n################################################################################\n")
cat("ANALİZ TAMAMLANDI!\n")
cat("################################################################################\n\n")

# Workspace'i kaydet
save.image(file = file.path(output_dir, "analysis_workspace.RData"))
cat(sprintf("Workspace '%s/analysis_workspace.RData' olarak kaydedildi.\n",
            output_dir))
cat(sprintf("Tekrar yüklemek için: load('%s/analysis_workspace.RData')\n\n",
            output_dir))
