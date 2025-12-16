################################################################################
# BİLİŞSEL TANI MODELİ (COGNITIVE DIAGNOSTIC MODEL) ANALİZİ
# GDINA Model Kullanarak Kapsamlı CDM Analizi
################################################################################
#
# Bu script iki farklı örnek dataset üzerinden detaylı GDINA analizi yapar:
#   1. OKUMA ANLAMA (Reading Comprehension) - 5 Bilişsel Özellik
#   2. MATEMATİK (Mathematics) - 4 Bilişsel Özellik
#
# Analizler:
#   - Q-matrix tanımlama ve validation
#   - Farklı CDM modellerinin karşılaştırılması (GDINA, DINA, DINO, ACDM, RRUM, LLM)
#   - Model fit istatistikleri
#   - Item fit ve Person fit analizleri
#   - Bilişsel özellik sınıflandırması
#   - Detaylı tanısal raporlama
#   - Görselleştirmeler
#
################################################################################

# Gerekli kütüphaneleri yükle ---------------------------------------------------
packages <- c("GDINA", "Qval", "CDM", "lattice", "ggplot2", "reshape2", "knitr")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

cat("\n================================================================================\n")
cat("BİLİŞSEL TANI MODELİ ANALİZİ - GDINA Paketi\n")
cat("================================================================================\n\n")

# Çıktı klasörü oluştur
if (!dir.exists("gdina_outputs")) {
  dir.create("gdina_outputs")
}

################################################################################
# DATASET 1: OKUMA ANLAMA (READING COMPREHENSION)
################################################################################

cat("\n################################################################################\n")
cat("DATASET 1: OKUMA ANLAMA ANALİZİ\n")
cat("################################################################################\n\n")

set.seed(2024)

# 1.1 Q-Matrix Tanımlama -------------------------------------------------------
cat("1.1 Q-Matrix Tanımlama...\n\n")

# Bilişsel Özellikler (Attributes):
# A1: Kelime bilgisi (Vocabulary)
# A2: Ana fikir bulma (Main idea identification)
# A3: Çıkarım yapma (Inference)
# A4: Yapı analizi (Structural analysis)
# A5: Eleştirel düşünme (Critical thinking)

Q1 <- matrix(c(
  # A1  A2  A3  A4  A5
    1,  0,  0,  0,  0,  # Item 1: Sadece kelime bilgisi
    1,  1,  0,  0,  0,  # Item 2: Kelime + Ana fikir
    0,  1,  0,  0,  0,  # Item 3: Sadece ana fikir
    0,  1,  1,  0,  0,  # Item 4: Ana fikir + Çıkarım
    1,  0,  1,  0,  0,  # Item 5: Kelime + Çıkarım
    0,  0,  1,  0,  0,  # Item 6: Sadece çıkarım
    0,  0,  1,  1,  0,  # Item 7: Çıkarım + Yapı
    1,  1,  1,  0,  0,  # Item 8: Kelime + Ana fikir + Çıkarım
    0,  1,  0,  1,  0,  # Item 9: Ana fikir + Yapı
    0,  0,  0,  1,  0,  # Item 10: Sadece yapı
    1,  0,  0,  1,  0,  # Item 11: Kelime + Yapı
    0,  1,  1,  1,  0,  # Item 12: Ana fikir + Çıkarım + Yapı
    0,  0,  0,  0,  1,  # Item 13: Sadece eleştirel düşünme
    0,  0,  1,  0,  1,  # Item 14: Çıkarım + Eleştirel düşünme
    0,  1,  0,  0,  1,  # Item 15: Ana fikir + Eleştirel düşünme
    1,  1,  0,  0,  1,  # Item 16: Kelime + Ana fikir + Eleştirel
    0,  0,  1,  1,  1,  # Item 17: Çıkarım + Yapı + Eleştirel
    1,  0,  1,  0,  1,  # Item 18: Kelime + Çıkarım + Eleştirel
    0,  1,  1,  0,  1,  # Item 19: Ana fikir + Çıkarım + Eleştirel
    1,  1,  1,  1,  1   # Item 20: Tüm özellikler
), ncol = 5, byrow = TRUE)

colnames(Q1) <- c("Vocabulary", "MainIdea", "Inference", "Structure", "Critical")
rownames(Q1) <- paste0("Item", 1:nrow(Q1))

cat("Q-Matrix (Okuma Anlama):\n")
print(Q1)
cat("\n")

# Q-matrix özellikleri
cat("Q-Matrix İstatistikleri:\n")
cat(sprintf("  - Madde sayısı: %d\n", nrow(Q1)))
cat(sprintf("  - Özellik sayısı: %d\n", ncol(Q1)))
cat(sprintf("  - Ortalama özellik sayısı/madde: %.2f\n", mean(rowSums(Q1))))
cat("\nÖzellik Dağılımı:\n")
print(colSums(Q1))
cat("\n")

# 1.2 Simulated Data Oluşturma -------------------------------------------------
cat("1.2 Veri Simülasyonu...\n\n")

n_students <- 500  # Öğrenci sayısı

# Gerçek bilişsel özellik profillerini simüle et
# Her özelliğe sahip olma olasılığı
attr_prob <- c(0.7, 0.6, 0.5, 0.4, 0.3)  # Artan zorluk
true_alpha1 <- matrix(NA, n_students, ncol(Q1))
for (k in 1:ncol(Q1)) {
  true_alpha1[, k] <- rbinom(n_students, 1, attr_prob[k])
}
colnames(true_alpha1) <- colnames(Q1)

# GDINA modeli ile veri simüle et
# Her madde için item parametreleri
sim_model1 <- GDINA::simGDINA(
  N = n_students,
  Q = Q1,
  model = "GDINA",
  attribute = true_alpha1,
  gs.parm = list(
    delta0 = rep(0.15, nrow(Q1)),  # Guess parametresi (başlangıç)
    delta = NULL  # GDINA otomatik hesaplasın
  )
)

# Simüle edilmiş yanıt verisi
data1 <- sim_model1$dat
cat(sprintf("Simüle edilmiş veri boyutu: %d öğrenci x %d madde\n",
            nrow(data1), ncol(data1)))
cat(sprintf("Ortalama doğru cevap oranı: %.2f%%\n\n",
            mean(data1, na.rm = TRUE) * 100))

# 1.3 Model Tahminleme ---------------------------------------------------------
cat("1.3 GDINA Model Tahminlemesi...\n\n")

# 1.3.1 GDINA (General Diagnostic Model)
cat("  1.3.1 GDINA modeli tahminleniyor...\n")
fit1_GDINA <- GDINA::GDINA(
  dat = data1,
  Q = Q1,
  model = "GDINA",
  control = list(maxitr = 2000)
)

# 1.3.2 DINA (Deterministic Input, Noisy "And" gate)
cat("  1.3.2 DINA modeli tahminleniyor...\n")
fit1_DINA <- GDINA::GDINA(
  dat = data1,
  Q = Q1,
  model = "DINA",
  control = list(maxitr = 2000)
)

# 1.3.3 DINO (Deterministic Input, Noisy "Or" gate)
cat("  1.3.3 DINO modeli tahminleniyor...\n")
fit1_DINO <- GDINA::GDINA(
  dat = data1,
  Q = Q1,
  model = "DINO",
  control = list(maxitr = 2000)
)

# 1.3.4 ACDM (Additive CDM)
cat("  1.3.4 ACDM modeli tahminleniyor...\n")
fit1_ACDM <- GDINA::GDINA(
  dat = data1,
  Q = Q1,
  model = "ACDM",
  control = list(maxitr = 2000)
)

# 1.3.5 LLM (Linear Logistic Model)
cat("  1.3.5 LLM modeli tahminleniyor...\n")
fit1_LLM <- GDINA::GDINA(
  dat = data1,
  Q = Q1,
  model = "LLM",
  control = list(maxitr = 2000)
)

# 1.3.6 RRUM (Reduced Reparameterized Unified Model)
cat("  1.3.6 RRUM modeli tahminleniyor...\n")
fit1_RRUM <- GDINA::GDINA(
  dat = data1,
  Q = Q1,
  model = "RRUM",
  control = list(maxitr = 2000)
)

cat("\n  Tüm modeller başarıyla tahminlendi!\n\n")

# 1.4 Model Karşılaştırma ------------------------------------------------------
cat("1.4 Model Karşılaştırma\n\n")

# Model fit istatistikleri
cat("=== Model Fit İstatistikleri ===\n\n")

models_list1 <- list(
  GDINA = fit1_GDINA,
  DINA = fit1_DINA,
  DINO = fit1_DINO,
  ACDM = fit1_ACDM,
  LLM = fit1_LLM,
  RRUM = fit1_RRUM
)

fit_stats1 <- data.frame(
  Model = names(models_list1),
  Deviance = NA,
  AIC = NA,
  BIC = NA,
  CAIC = NA,
  SABIC = NA,
  n_par = NA
)

for (i in 1:length(models_list1)) {
  fit <- modelfit(models_list1[[i]])
  fit_stats1$Deviance[i] <- fit$deviance
  fit_stats1$AIC[i] <- fit$AIC
  fit_stats1$BIC[i] <- fit$BIC
  fit_stats1$CAIC[i] <- fit$CAIC
  fit_stats1$SABIC[i] <- fit$SABIC
  fit_stats1$n_par[i] <- fit$npar
}

print(fit_stats1)
cat("\n")

# En iyi modeli belirle (BIC'e göre)
best_model_idx <- which.min(fit_stats1$BIC)
cat(sprintf("En iyi model (BIC'e göre): %s\n", fit_stats1$Model[best_model_idx]))
cat(sprintf("BIC değeri: %.2f\n\n", fit_stats1$BIC[best_model_idx]))

# Likelihood ratio test (DINA vs GDINA)
cat("=== Likelihood Ratio Test ===\n\n")
lrt1 <- anova(fit1_DINA, fit1_GDINA)
print(lrt1)
cat("\n")

# 1.5 Q-Matrix Validation ------------------------------------------------------
cat("1.5 Q-Matrix Validation\n\n")

# Qval paketi ile Q-matrix validation
cat("  1.5.1 Hull method ile Q-matrix validation...\n")

# CDM paketi formatına çevir (Qval için)
fit1_CDM <- CDM::gdina(
  data = data1,
  q.matrix = Q1,
  rule = "GDINA"
)

# Hull method
Q1_Hull <- Qval::validation(
  data = data1,
  q.matrix = Q1,
  CDM.obj = fit1_CDM,
  method = "Hull"
)

cat("\n  1.5.2 MLR-B method ile Q-matrix validation...\n")
Q1_MLR <- Qval::validation(
  data = data1,
  q.matrix = Q1,
  CDM.obj = fit1_CDM,
  method = "MLR-B"
)

# Q-matrix değişim oranları
cat("\n=== Q-Matrix Validation Sonuçları ===\n\n")

if (!is.null(Q1_Hull$Q.sug)) {
  qrr_hull <- Qval::zQRR(Q1, Q1_Hull$Q.sug)
  usr_hull <- Qval::zUSR(Q1, Q1_Hull$Q.sug)
  osr_hull <- Qval::zOSR(Q1, Q1_Hull$Q.sug)

  cat("Hull Method:\n")
  cat(sprintf("  - QRR (Q-matrix Recovery Rate): %.2f%%\n", qrr_hull * 100))
  cat(sprintf("  - USR (Underspecification Rate): %.2f%%\n", usr_hull * 100))
  cat(sprintf("  - OSR (Overspecification Rate): %.2f%%\n", osr_hull * 100))
  cat("\n")
}

if (!is.null(Q1_MLR$Q.sug)) {
  qrr_mlr <- Qval::zQRR(Q1, Q1_MLR$Q.sug)
  usr_mlr <- Qval::zUSR(Q1, Q1_MLR$Q.sug)
  osr_mlr <- Qval::zOSR(Q1, Q1_MLR$Q.sug)

  cat("MLR-B Method:\n")
  cat(sprintf("  - QRR (Q-matrix Recovery Rate): %.2f%%\n", qrr_mlr * 100))
  cat(sprintf("  - USR (Underspecification Rate): %.2f%%\n", usr_mlr * 100))
  cat(sprintf("  - OSR (Overspecification Rate): %.2f%%\n", osr_mlr * 100))
  cat("\n")
}

# Eğer validated Q-matrix varsa, yeniden modelleme yap
if (!is.null(Q1_Hull$Q.sug) && sum(Q1 != Q1_Hull$Q.sug) > 0) {
  cat("  Hull validated Q-matrix ile model yeniden tahminleniyor...\n")
  fit1_GDINA_val <- GDINA::GDINA(
    dat = data1,
    Q = Q1_Hull$Q.sug,
    model = "GDINA",
    control = list(maxitr = 2000)
  )

  cat("\n  Orijinal vs Validated Q-matrix Model Karşılaştırması:\n")
  fit_orig <- modelfit(fit1_GDINA)
  fit_val <- modelfit(fit1_GDINA_val)

  comparison <- data.frame(
    Q_Matrix = c("Original", "Validated"),
    BIC = c(fit_orig$BIC, fit_val$BIC),
    AIC = c(fit_orig$AIC, fit_val$AIC)
  )
  print(comparison)
  cat("\n")
}

# 1.6 Item Fit Analysis --------------------------------------------------------
cat("1.6 Item Fit Analysis\n\n")

item_fit1 <- GDINA::itemfit(fit1_GDINA, method = "transformed")
cat("Item Fit İstatistikleri (ilk 10 madde):\n")
print(head(item_fit1, 10))
cat("\n")

# Problematic items (p < 0.05)
problem_items1 <- which(item_fit1$pval < 0.05)
if (length(problem_items1) > 0) {
  cat(sprintf("Uyum sorunu olan madde sayısı: %d\n", length(problem_items1)))
  cat("Problematic items:", paste(problem_items1, collapse = ", "), "\n\n")
} else {
  cat("Uyum sorunu olan madde bulunmamaktadır.\n\n")
}

# 1.7 Person Fit Analysis ------------------------------------------------------
cat("1.7 Person Fit Analysis\n\n")

person_fit1 <- GDINA::personfit(fit1_GDINA, method = "lz")
cat("Person Fit İstatistikleri:\n")
cat(sprintf("  - Ortalama lz: %.3f\n", mean(person_fit1$lz, na.rm = TRUE)))
cat(sprintf("  - Standart sapma: %.3f\n", sd(person_fit1$lz, na.rm = TRUE)))

# Aberrant respondents (|lz| > 2)
aberrant1 <- which(abs(person_fit1$lz) > 2)
cat(sprintf("  - Aberrant yanıt veren öğrenci sayısı: %d (%.1f%%)\n\n",
            length(aberrant1),
            length(aberrant1) / n_students * 100))

# 1.8 Attribute Classification -------------------------------------------------
cat("1.8 Bilişsel Özellik Sınıflandırması\n\n")

# Estimated attribute profiles
est_alpha1 <- personparm(fit1_GDINA, what = "EAP")

cat("Özellik Hakimiyet Oranları:\n")
for (k in 1:ncol(Q1)) {
  mastery_rate <- mean(est_alpha1[, k])
  cat(sprintf("  - %s: %.1f%%\n", colnames(Q1)[k], mastery_rate * 100))
}
cat("\n")

# Classification accuracy (gerçek vs tahmin)
if (exists("true_alpha1")) {
  cat("Sınıflandırma Doğruluğu (Gerçek vs Tahmin):\n")
  for (k in 1:ncol(Q1)) {
    accuracy <- mean(est_alpha1[, k] == true_alpha1[, k])
    cat(sprintf("  - %s: %.1f%%\n", colnames(Q1)[k], accuracy * 100))
  }
  overall_acc <- mean(est_alpha1 == true_alpha1)
  cat(sprintf("  - Genel Doğruluk: %.1f%%\n\n", overall_acc * 100))
}

# 1.9 Item Parameters ----------------------------------------------------------
cat("1.9 Item Parameters (GDINA)\n\n")

item_params1 <- coef(fit1_GDINA)
cat("İlk 3 madde için parametreler:\n")
print(item_params1[1:3])
cat("\n")

# 1.10 Görselleştirmeler -------------------------------------------------------
cat("1.10 Görselleştirmeler oluşturuluyor...\n\n")

# 1.10.1 Q-matrix heatmap
pdf("gdina_outputs/dataset1_qmatrix_heatmap.pdf", width = 10, height = 8)
heatmap(Q1,
        Rowv = NA,
        Colv = NA,
        scale = "none",
        col = c("white", "darkblue"),
        main = "Q-Matrix: Okuma Anlama",
        xlab = "Bilişsel Özellikler",
        ylab = "Maddeler")
dev.off()

# 1.10.2 Model comparison plot
pdf("gdina_outputs/dataset1_model_comparison.pdf", width = 10, height = 6)
par(mfrow = c(1, 2))
barplot(fit_stats1$BIC,
        names.arg = fit_stats1$Model,
        main = "Model Karşılaştırma (BIC)",
        ylab = "BIC",
        col = "steelblue",
        las = 2)

barplot(fit_stats1$AIC,
        names.arg = fit_stats1$Model,
        main = "Model Karşılaştırma (AIC)",
        ylab = "AIC",
        col = "coral",
        las = 2)
dev.off()

# 1.10.3 Attribute mastery profile
pdf("gdina_outputs/dataset1_attribute_mastery.pdf", width = 10, height = 6)
mastery_rates <- colMeans(est_alpha1)
barplot(mastery_rates * 100,
        names.arg = colnames(Q1),
        main = "Bilişsel Özellik Hakimiyet Oranları",
        ylab = "Hakimiyet Oranı (%)",
        col = rainbow(ncol(Q1)),
        las = 2,
        ylim = c(0, 100))
abline(h = 50, lty = 2, col = "red")
dev.off()

cat("  Grafikler 'gdina_outputs' klasörüne kaydedildi.\n\n")

################################################################################
# DATASET 2: MATEMATİK (MATHEMATICS)
################################################################################

cat("\n################################################################################\n")
cat("DATASET 2: MATEMATİK ANALİZİ\n")
cat("################################################################################\n\n")

set.seed(2025)

# 2.1 Q-Matrix Tanımlama -------------------------------------------------------
cat("2.1 Q-Matrix Tanımlama...\n\n")

# Bilişsel Özellikler (Attributes):
# A1: Temel işlemler (Basic operations)
# A2: Kesir kavramı (Fraction concepts)
# A3: Problem çözme (Problem solving)
# A4: Cebirsel düşünme (Algebraic thinking)

Q2 <- matrix(c(
  # A1  A2  A3  A4
    1,  0,  0,  0,  # Item 1: Sadece temel işlem
    1,  0,  0,  0,  # Item 2: Temel işlem
    1,  0,  1,  0,  # Item 3: Temel işlem + Problem çözme
    0,  1,  0,  0,  # Item 4: Sadece kesir
    0,  1,  0,  0,  # Item 5: Kesir
    1,  1,  0,  0,  # Item 6: Temel işlem + Kesir
    0,  1,  1,  0,  # Item 7: Kesir + Problem çözme
    1,  1,  1,  0,  # Item 8: Temel + Kesir + Problem
    0,  0,  1,  0,  # Item 9: Sadece problem çözme
    0,  0,  1,  0,  # Item 10: Problem çözme
    0,  0,  0,  1,  # Item 11: Sadece cebir
    0,  0,  0,  1,  # Item 12: Cebir
    1,  0,  0,  1,  # Item 13: Temel + Cebir
    0,  1,  0,  1,  # Item 14: Kesir + Cebir
    0,  0,  1,  1,  # Item 15: Problem + Cebir
    1,  0,  1,  1,  # Item 16: Temel + Problem + Cebir
    0,  1,  1,  1,  # Item 17: Kesir + Problem + Cebir
    1,  1,  0,  1,  # Item 18: Temel + Kesir + Cebir
    1,  1,  1,  1   # Item 19: Tüm özellikler
), ncol = 4, byrow = TRUE)

colnames(Q2) <- c("BasicOp", "Fraction", "ProbSolv", "Algebra")
rownames(Q2) <- paste0("Item", 1:nrow(Q2))

cat("Q-Matrix (Matematik):\n")
print(Q2)
cat("\n")

cat("Q-Matrix İstatistikleri:\n")
cat(sprintf("  - Madde sayısı: %d\n", nrow(Q2)))
cat(sprintf("  - Özellik sayısı: %d\n", ncol(Q2)))
cat(sprintf("  - Ortalama özellik sayısı/madde: %.2f\n", mean(rowSums(Q2))))
cat("\nÖzellik Dağılımı:\n")
print(colSums(Q2))
cat("\n")

# 2.2 Simulated Data Oluşturma -------------------------------------------------
cat("2.2 Veri Simülasyonu...\n\n")

n_students2 <- 400

# Gerçek bilişsel özellik profilleri (korelasyonlu)
attr_prob2 <- c(0.75, 0.60, 0.50, 0.35)
true_alpha2 <- matrix(NA, n_students2, ncol(Q2))

# İlk özellik
true_alpha2[, 1] <- rbinom(n_students2, 1, attr_prob2[1])

# Diğer özellikler (önceki özelliklere bağımlı)
for (k in 2:ncol(Q2)) {
  # Önceki özelliklere sahip olanlar için daha yüksek olasılık
  prob_given_prev <- ifelse(rowSums(true_alpha2[, 1:(k-1), drop = FALSE]) > 0,
                            attr_prob2[k] + 0.2,
                            attr_prob2[k] - 0.1)
  prob_given_prev <- pmax(0.1, pmin(0.9, prob_given_prev))
  true_alpha2[, k] <- rbinom(n_students2, 1, prob_given_prev)
}
colnames(true_alpha2) <- colnames(Q2)

# DINA modeli ile veri simüle et (daha kısıtlayıcı model)
sim_model2 <- GDINA::simGDINA(
  N = n_students2,
  Q = Q2,
  model = "DINA",
  attribute = true_alpha2,
  gs.parm = list(
    guessing = runif(nrow(Q2), 0.1, 0.25),
    slip = runif(nrow(Q2), 0.05, 0.20)
  )
)

data2 <- sim_model2$dat
cat(sprintf("Simüle edilmiş veri boyutu: %d öğrenci x %d madde\n",
            nrow(data2), ncol(data2)))
cat(sprintf("Ortalama doğru cevap oranı: %.2f%%\n\n",
            mean(data2, na.rm = TRUE) * 100))

# 2.3 Model Tahminleme ---------------------------------------------------------
cat("2.3 Model Tahminlemesi...\n\n")

# Farklı modeller tahminle
cat("  2.3.1 GDINA modeli tahminleniyor...\n")
fit2_GDINA <- GDINA::GDINA(dat = data2, Q = Q2, model = "GDINA",
                           control = list(maxitr = 2000))

cat("  2.3.2 DINA modeli tahminleniyor...\n")
fit2_DINA <- GDINA::GDINA(dat = data2, Q = Q2, model = "DINA",
                          control = list(maxitr = 2000))

cat("  2.3.3 ACDM modeli tahminleniyor...\n")
fit2_ACDM <- GDINA::GDINA(dat = data2, Q = Q2, model = "ACDM",
                          control = list(maxitr = 2000))

cat("  2.3.4 LLM modeli tahminleniyor...\n")
fit2_LLM <- GDINA::GDINA(dat = data2, Q = Q2, model = "LLM",
                         control = list(maxitr = 2000))

cat("\n  Tüm modeller başarıyla tahminlendi!\n\n")

# 2.4 Model Karşılaştırma ------------------------------------------------------
cat("2.4 Model Karşılaştırma\n\n")

models_list2 <- list(
  GDINA = fit2_GDINA,
  DINA = fit2_DINA,
  ACDM = fit2_ACDM,
  LLM = fit2_LLM
)

fit_stats2 <- data.frame(
  Model = names(models_list2),
  Deviance = NA,
  AIC = NA,
  BIC = NA,
  n_par = NA
)

for (i in 1:length(models_list2)) {
  fit <- modelfit(models_list2[[i]])
  fit_stats2$Deviance[i] <- fit$deviance
  fit_stats2$AIC[i] <- fit$AIC
  fit_stats2$BIC[i] <- fit$BIC
  fit_stats2$n_par[i] <- fit$npar
}

print(fit_stats2)
cat("\n")

best_model_idx2 <- which.min(fit_stats2$BIC)
cat(sprintf("En iyi model (BIC'e göre): %s\n", fit_stats2$Model[best_model_idx2]))
cat(sprintf("BIC değeri: %.2f\n\n", fit_stats2$BIC[best_model_idx2]))

# LRT
cat("=== Likelihood Ratio Test ===\n\n")
lrt2 <- anova(fit2_DINA, fit2_GDINA)
print(lrt2)
cat("\n")

# 2.5 Item Fit -----------------------------------------------------------------
cat("2.5 Item Fit Analysis\n\n")

item_fit2 <- GDINA::itemfit(fit2_DINA, method = "transformed")
cat("Item Fit İstatistikleri:\n")
print(item_fit2)
cat("\n")

problem_items2 <- which(item_fit2$pval < 0.05)
if (length(problem_items2) > 0) {
  cat(sprintf("Uyum sorunu olan madde sayısı: %d\n", length(problem_items2)))
  cat("Problematic items:", paste(problem_items2, collapse = ", "), "\n\n")
} else {
  cat("Uyum sorunu olan madde bulunmamaktadır.\n\n")
}

# 2.6 Attribute Classification -------------------------------------------------
cat("2.6 Bilişsel Özellik Sınıflandırması\n\n")

est_alpha2 <- personparm(fit2_DINA, what = "EAP")

cat("Özellik Hakimiyet Oranları:\n")
for (k in 1:ncol(Q2)) {
  mastery_rate <- mean(est_alpha2[, k])
  cat(sprintf("  - %s: %.1f%%\n", colnames(Q2)[k], mastery_rate * 100))
}
cat("\n")

# Classification accuracy
if (exists("true_alpha2")) {
  cat("Sınıflandırma Doğruluğu (Gerçek vs Tahmin):\n")
  for (k in 1:ncol(Q2)) {
    accuracy <- mean(est_alpha2[, k] == true_alpha2[, k])
    sensitivity <- sum(est_alpha2[, k] == 1 & true_alpha2[, k] == 1) /
                   sum(true_alpha2[, k] == 1)
    specificity <- sum(est_alpha2[, k] == 0 & true_alpha2[, k] == 0) /
                   sum(true_alpha2[, k] == 0)

    cat(sprintf("  - %s:\n", colnames(Q2)[k]))
    cat(sprintf("      Doğruluk: %.1f%%\n", accuracy * 100))
    cat(sprintf("      Duyarlılık: %.1f%%\n", sensitivity * 100))
    cat(sprintf("      Özgüllük: %.1f%%\n", specificity * 100))
  }
  overall_acc <- mean(est_alpha2 == true_alpha2)
  cat(sprintf("\n  - Genel Doğruluk: %.1f%%\n\n", overall_acc * 100))
}

# 2.7 DINA Parameters ----------------------------------------------------------
cat("2.7 DINA Model Parameters\n\n")

# Guess ve slip parametreleri
guess_slip <- data.frame(
  Item = rownames(Q2),
  Guessing = NA,
  Slip = NA
)

for (i in 1:nrow(Q2)) {
  params <- coef(fit2_DINA, what = "catprob")[[i]]
  # DINA: P(X=1|eta=0) = guessing, P(X=0|eta=1) = slip
  guess_slip$Guessing[i] <- params[1, 2]  # P(X=1|non-master)
  guess_slip$Slip[i] <- 1 - params[2, 2]  # 1 - P(X=1|master)
}

cat("DINA Parametreleri (Guessing ve Slip):\n")
print(guess_slip)
cat("\n")

cat("Özet İstatistikler:\n")
cat(sprintf("  - Ortalama Guessing: %.3f (SD: %.3f)\n",
            mean(guess_slip$Guessing), sd(guess_slip$Guessing)))
cat(sprintf("  - Ortalama Slip: %.3f (SD: %.3f)\n\n",
            mean(guess_slip$Slip), sd(guess_slip$Slip)))

# 2.8 Görselleştirmeler -------------------------------------------------------
cat("2.8 Görselleştirmeler oluşturuluyor...\n\n")

# Q-matrix heatmap
pdf("gdina_outputs/dataset2_qmatrix_heatmap.pdf", width = 8, height = 10)
heatmap(Q2,
        Rowv = NA,
        Colv = NA,
        scale = "none",
        col = c("white", "darkgreen"),
        main = "Q-Matrix: Matematik",
        xlab = "Bilişsel Özellikler",
        ylab = "Maddeler")
dev.off()

# Model comparison
pdf("gdina_outputs/dataset2_model_comparison.pdf", width = 10, height = 6)
par(mfrow = c(1, 2))
barplot(fit_stats2$BIC,
        names.arg = fit_stats2$Model,
        main = "Model Karşılaştırma (BIC)",
        ylab = "BIC",
        col = "steelblue",
        las = 2)

barplot(fit_stats2$AIC,
        names.arg = fit_stats2$Model,
        main = "Model Karşılaştırma (AIC)",
        ylab = "AIC",
        col = "coral",
        las = 2)
dev.off()

# Attribute mastery
pdf("gdina_outputs/dataset2_attribute_mastery.pdf", width = 10, height = 6)
mastery_rates2 <- colMeans(est_alpha2)
barplot(mastery_rates2 * 100,
        names.arg = colnames(Q2),
        main = "Bilişsel Özellik Hakimiyet Oranları - Matematik",
        ylab = "Hakimiyet Oranı (%)",
        col = c("red", "blue", "green", "purple"),
        ylim = c(0, 100))
abline(h = 50, lty = 2, col = "red")
dev.off()

# Guess-Slip plot
pdf("gdina_outputs/dataset2_guess_slip.pdf", width = 10, height = 6)
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

cat("  Grafikler 'gdina_outputs' klasörüne kaydedildi.\n\n")

################################################################################
# Özet Rapor
################################################################################

cat("\n################################################################################\n")
cat("ANALİZ ÖZET RAPORU\n")
cat("################################################################################\n\n")

cat("=== DATASET 1: OKUMA ANLAMA ===\n\n")
cat(sprintf("Öğrenci Sayısı: %d\n", nrow(data1)))
cat(sprintf("Madde Sayısı: %d\n", ncol(data1)))
cat(sprintf("Bilişsel Özellik Sayısı: %d\n", ncol(Q1)))
cat(sprintf("En İyi Model: %s (BIC: %.2f)\n",
            fit_stats1$Model[best_model_idx],
            fit_stats1$BIC[best_model_idx]))
cat(sprintf("Ortalama Sınıflandırma Doğruluğu: %.1f%%\n",
            mean(est_alpha1 == true_alpha1) * 100))
cat("\n")

cat("=== DATASET 2: MATEMATİK ===\n\n")
cat(sprintf("Öğrenci Sayısı: %d\n", nrow(data2)))
cat(sprintf("Madde Sayısı: %d\n", ncol(data2)))
cat(sprintf("Bilişsel Özellik Sayısı: %d\n", ncol(Q2)))
cat(sprintf("En İyi Model: %s (BIC: %.2f)\n",
            fit_stats2$Model[best_model_idx2],
            fit_stats2$BIC[best_model_idx2]))
cat(sprintf("Ortalama Sınıflandırma Doğruluğu: %.1f%%\n",
            mean(est_alpha2 == true_alpha2) * 100))
cat("\n")

cat("=== ÇIKTI DOSYALARI ===\n\n")
cat("Tüm grafikler 'gdina_outputs/' klasörüne kaydedildi:\n")
cat("  - dataset1_qmatrix_heatmap.pdf\n")
cat("  - dataset1_model_comparison.pdf\n")
cat("  - dataset1_attribute_mastery.pdf\n")
cat("  - dataset2_qmatrix_heatmap.pdf\n")
cat("  - dataset2_model_comparison.pdf\n")
cat("  - dataset2_attribute_mastery.pdf\n")
cat("  - dataset2_guess_slip.pdf\n")
cat("\n")

cat("################################################################################\n")
cat("ANALİZ TAMAMLANDI!\n")
cat("################################################################################\n\n")

# Workspace'i kaydet
save.image(file = "gdina_outputs/gdina_analysis_workspace.RData")
cat("Workspace 'gdina_outputs/gdina_analysis_workspace.RData' olarak kaydedildi.\n")
cat("Tekrar yüklemek için: load('gdina_outputs/gdina_analysis_workspace.RData')\n\n")
