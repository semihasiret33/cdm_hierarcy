################################################################################
# BİLİŞSEL ÖZELLİK HİYERAŞİSİ ANALİZİ
# GDINA Package - Attribute Hierarchy Methods
################################################################################
#
# Bu script, bilişsel özelliklerin hiyerarşik yapısını analiz eder:
#   1. Farklı hiyerarşi yapıları (Linear, Convergent, Divergent, Unstructured)
#   2. Higher-Order CDM modelleri
#   3. Hiyerarşi doğrulama ve karşılaştırma
#   4. Reachability matrix ve attribute structure
#   5. Tetrachoric korelasyonlar
#
################################################################################

# Gerekli kütüphaneler ---------------------------------------------------------
packages <- c("GDINA", "CDM", "psych", "igraph", "network", "ggplot2", "reshape2")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

cat("\n================================================================================\n")
cat("BİLİŞSEL ÖZELLİK HİYERAŞİSİ ANALİZİ\n")
cat("================================================================================\n\n")

# Çıktı klasörü
if (!dir.exists("hierarchy_outputs")) {
  dir.create("hierarchy_outputs")
}

################################################################################
# BÖLÜM 1: HİYERAŞİ YAPILARININ TANITIMI
################################################################################

cat("\n################################################################################\n")
cat("BÖLÜM 1: HİYERAŞİ YAPILARI\n")
cat("################################################################################\n\n")

cat("Bilişsel özellikler arasında 4 temel hiyerarşi yapısı vardır:\n\n")
cat("1. LINEAR (Doğrusal): A1 -> A2 -> A3 -> A4\n")
cat("   Özellikler sıralı bir düzen takip eder.\n")
cat("   Örnek: Temel işlem -> Kesir -> Problem çözme -> Cebir\n\n")

cat("2. CONVERGENT (Yakınsak): A1 -> A3, A2 -> A3\n")
cat("   Birden fazla özellik tek bir üst özelliğe yönelir.\n")
cat("   Örnek: Kelime bilgisi -> Okuma anlama <- Gramer bilgisi\n\n")

cat("3. DIVERGENT (Iraksak): A1 -> A2, A1 -> A3\n")
cat("   Tek bir özellik birden fazla üst özelliğe yol açar.\n")
cat("   Örnek: Sayı hissi -> Toplama/Çıkarma veya Çarpma/Bölme\n\n")

cat("4. UNSTRUCTURED (Yapısız): Özellikler arası hiyerarşi yok\n")
cat("   Her özellik bağımsızdır.\n\n")

################################################################################
# BÖLÜM 2: ÖRNEK 1 - LİNEAR HİYERAŞİ (MATEMATİK)
################################################################################

cat("\n################################################################################\n")
cat("BÖLÜM 2: LINEAR HİYERAŞİ ÖRNEĞİ - MATEMATİK BECERİLERİ\n")
cat("################################################################################\n\n")

set.seed(2024)

# 2.1 Q-Matrix Tanımlama -------------------------------------------------------
cat("2.1 Q-Matrix ve Hiyerarşi Yapısı\n\n")

# Linear hierarchy: Basic -> Fraction -> ProbSolv -> Algebra
# A1 (Basic) -> A2 (Fraction) -> A3 (ProbSolv) -> A4 (Algebra)

Q_linear <- matrix(c(
  # A1  A2  A3  A4
    1,  0,  0,  0,   # Item 1: Sadece temel
    1,  0,  0,  0,   # Item 2: Sadece temel
    1,  1,  0,  0,   # Item 3: Temel + Kesir
    1,  1,  0,  0,   # Item 4: Temel + Kesir
    0,  1,  0,  0,   # Item 5: Sadece kesir (teoride A1 de olmalı)
    1,  1,  0,  0,   # Item 6: Temel + Kesir
    1,  1,  1,  0,   # Item 7: Temel + Kesir + Problem
    0,  1,  1,  0,   # Item 8: Kesir + Problem
    0,  0,  1,  0,   # Item 9: Sadece problem
    1,  1,  1,  0,   # Item 10: Temel + Kesir + Problem
    0,  0,  1,  0,   # Item 11: Sadece problem
    1,  1,  1,  1,   # Item 12: Tüm özellikler
    0,  0,  0,  1,   # Item 13: Sadece cebir
    0,  0,  1,  1,   # Item 14: Problem + Cebir
    0,  1,  1,  1,   # Item 15: Kesir + Problem + Cebir
    1,  1,  1,  1,   # Item 16: Tüm özellikler
    0,  0,  1,  1,   # Item 17: Problem + Cebir
    1,  0,  1,  1,   # Item 18: Temel + Problem + Cebir
    1,  1,  1,  1    # Item 19: Tüm özellikler
), ncol = 4, byrow = TRUE)

colnames(Q_linear) <- c("Basic", "Fraction", "ProbSolv", "Algebra")
rownames(Q_linear) <- paste0("Item", 1:nrow(Q_linear))

cat("Q-Matrix:\n")
print(Q_linear)
cat("\n")

# 2.2 Hiyerarşi Matrisi --------------------------------------------------------
cat("2.2 Hiyerarşi Matrisi Tanımlama\n\n")

# Hierarchy matrix: (i,j) = 1 means attribute i is prerequisite for j
# Linear: A1 -> A2 -> A3 -> A4
hierarchy_linear <- matrix(c(
  # A1  A2  A3  A4
    0,  1,  0,  0,   # A1 -> A2
    0,  0,  1,  0,   # A2 -> A3
    0,  0,  0,  1,   # A3 -> A4
    0,  0,  0,  0    # A4 (en üst)
), nrow = 4, byrow = TRUE)

rownames(hierarchy_linear) <- colnames(Q_linear)
colnames(hierarchy_linear) <- colnames(Q_linear)

cat("Hiyerarşi Matrisi (satır -> sütun):\n")
print(hierarchy_linear)
cat("\nYapı: Basic -> Fraction -> ProbSolv -> Algebra\n\n")

# Reachability matrix (transitive closure)
cat("Reachability Matrix (İndirgenmiş hiyerarşi):\n")
reach_linear <- GDINA::attributepattern(4, hierarchy = hierarchy_linear)$hierarchy.lv
print(reach_linear)
cat("\n")

# 2.3 Veri Simülasyonu ---------------------------------------------------------
cat("2.3 Hiyerarşik Yapı ile Veri Simülasyonu\n\n")

n_students <- 500

# Hiyerarşik attribute patterns oluştur
# Linear hiyerarşide: A4=1 ise A3=1, A3=1 ise A2=1, A2=1 ise A1=1
valid_patterns <- GDINA::attributepattern(4, hierarchy = hierarchy_linear)

cat(sprintf("Geçerli attribute pattern sayısı: %d (hiyerarşisiz: 2^4 = 16)\n",
            nrow(valid_patterns)))
cat("\nGeçerli Attribute Patterns:\n")
print(valid_patterns)
cat("\n")

# Öğrencileri geçerli pattern'lara atama
# Her pattern için eşit olmayan olasılıklar (düşük beceri -> yüksek olasılık)
pattern_probs <- c(0.20, 0.18, 0.15, 0.12, 0.10, 0.08, 0.07, 0.05, 0.03, 0.02)
pattern_probs <- pattern_probs / sum(pattern_probs)

student_patterns <- sample(1:nrow(valid_patterns), n_students,
                           replace = TRUE, prob = pattern_probs)
true_alpha_linear <- as.matrix(valid_patterns[student_patterns, ])

cat("Öğrenci Attribute Pattern Dağılımı:\n")
pattern_counts <- table(student_patterns)
for (i in 1:length(pattern_counts)) {
  cat(sprintf("  Pattern %d: %d öğrenci (%.1f%%)\n",
              as.numeric(names(pattern_counts)[i]),
              pattern_counts[i],
              pattern_counts[i] / n_students * 100))
}
cat("\n")

# DINA modeli ile veri simüle et
sim_linear <- GDINA::simGDINA(
  N = n_students,
  Q = Q_linear,
  model = "DINA",
  attribute = true_alpha_linear,
  gs.parm = list(
    guessing = runif(nrow(Q_linear), 0.10, 0.20),
    slip = runif(nrow(Q_linear), 0.05, 0.15)
  )
)

data_linear <- sim_linear$dat
cat(sprintf("Simüle edilmiş veri: %d öğrenci x %d madde\n",
            nrow(data_linear), ncol(data_linear)))
cat(sprintf("Ortalama doğru yanıt: %.2f%%\n\n",
            mean(data_linear, na.rm = TRUE) * 100))

# 2.4 Model Tahminleme ---------------------------------------------------------
cat("2.4 Model Tahminleme\n\n")

# 2.4.1 Hiyerarşisiz DINA
cat("  2.4.1 DINA (Hiyerarşisiz)...\n")
fit_linear_unrestricted <- GDINA::GDINA(
  dat = data_linear,
  Q = Q_linear,
  model = "DINA",
  control = list(maxitr = 2000)
)

# 2.4.2 Hiyerarşili DINA
cat("  2.4.2 DINA (Linear Hiyerarşi)...\n")
fit_linear_hierarchical <- GDINA::GDINA(
  dat = data_linear,
  Q = Q_linear,
  model = "DINA",
  att.str = hierarchy_linear,  # Hiyerarşi kısıtlaması
  control = list(maxitr = 2000)
)

# 2.4.3 Higher-Order GDINA
cat("  2.4.3 Higher-Order GDINA...\n")
fit_linear_ho <- GDINA::GDINA(
  dat = data_linear,
  Q = Q_linear,
  model = "GDINA",
  higher.order = list(model = "2PL", nquad = 30),
  control = list(maxitr = 2000)
)

cat("\n  Modeller başarıyla tahminlendi!\n\n")

# 2.5 Model Karşılaştırma ------------------------------------------------------
cat("2.5 Model Karşılaştırma\n\n")

fit_stats_linear <- data.frame(
  Model = c("DINA-Unrestricted", "DINA-Hierarchical", "HO-GDINA"),
  Deviance = NA,
  AIC = NA,
  BIC = NA,
  n_par = NA
)

fits <- list(fit_linear_unrestricted, fit_linear_hierarchical, fit_linear_ho)

for (i in 1:3) {
  fit <- modelfit(fits[[i]])
  fit_stats_linear$Deviance[i] <- fit$deviance
  fit_stats_linear$AIC[i] <- fit$AIC
  fit_stats_linear$BIC[i] <- fit$BIC
  fit_stats_linear$n_par[i] <- fit$npar
}

print(fit_stats_linear)
cat("\n")

# En iyi model
best_idx <- which.min(fit_stats_linear$BIC)
cat(sprintf("En iyi model (BIC): %s (BIC = %.2f)\n\n",
            fit_stats_linear$Model[best_idx],
            fit_stats_linear$BIC[best_idx]))

# 2.6 Classification Accuracy --------------------------------------------------
cat("2.6 Sınıflandırma Performansı\n\n")

# Her model için tahminler
est_alpha_unrestr <- personparm(fit_linear_unrestricted, what = "EAP")
est_alpha_hier <- personparm(fit_linear_hierarchical, what = "EAP")
est_alpha_ho <- personparm(fit_linear_ho, what = "EAP")

# Accuracy hesaplama
acc_unrestr <- mean(est_alpha_unrestr == true_alpha_linear)
acc_hier <- mean(est_alpha_hier == true_alpha_linear)
acc_ho <- mean(est_alpha_ho == true_alpha_linear)

cat("Genel Sınıflandırma Doğruluğu:\n")
cat(sprintf("  - DINA (Unrestricted): %.2f%%\n", acc_unrestr * 100))
cat(sprintf("  - DINA (Hierarchical): %.2f%%\n", acc_hier * 100))
cat(sprintf("  - Higher-Order GDINA: %.2f%%\n\n", acc_ho * 100))

# Özellik bazında accuracy
cat("Özellik Bazında Doğruluk (Hierarchical):\n")
for (k in 1:ncol(Q_linear)) {
  acc <- mean(est_alpha_hier[, k] == true_alpha_linear[, k])
  cat(sprintf("  - %s: %.2f%%\n", colnames(Q_linear)[k], acc * 100))
}
cat("\n")

# 2.7 Hiyerarşi Validation -----------------------------------------------------
cat("2.7 Hiyerarşi Validation\n\n")

# Tetrachoric correlations (özellikler arası korelasyon)
cat("Özellikler Arası Tetrachoric Korelasyonlar:\n")
tetra_cor <- psych::tetrachoric(est_alpha_hier)$rho
print(round(tetra_cor, 3))
cat("\n")

# Linear hiyerarşide beklenen: yüksek korelasyon, özellikle ardışık özellikler
cat("Beklenen hiyerarşi yapısı:\n")
cat("  - Basic <-> Fraction: Yüksek korelasyon (direkt bağlantı)\n")
cat("  - Fraction <-> ProbSolv: Yüksek korelasyon (direkt bağlantı)\n")
cat("  - ProbSolv <-> Algebra: Yüksek korelasyon (direkt bağlantı)\n")
cat("  - Basic <-> Algebra: Orta-yüksek korelasyon (indirekt bağlantı)\n\n")

# 2.8 Görselleştirme -----------------------------------------------------------
cat("2.8 Görselleştirmeler\n\n")

# 2.8.1 Hiyerarşi ağ grafiği
pdf("hierarchy_outputs/linear_hierarchy_network.pdf", width = 10, height = 8)
par(mfrow = c(1, 1))

# igraph ile network plot
library(igraph)
g_linear <- graph_from_adjacency_matrix(hierarchy_linear, mode = "directed")
V(g_linear)$label <- colnames(Q_linear)
V(g_linear)$color <- c("lightblue", "lightgreen", "lightyellow", "lightcoral")
V(g_linear)$size <- 40

plot(g_linear,
     layout = layout_as_tree(g_linear, root = 1),
     main = "Linear Attribute Hierarchy: Mathematics",
     edge.arrow.size = 1,
     vertex.label.cex = 1.2,
     vertex.label.color = "black")

dev.off()

# 2.8.2 Model comparison
pdf("hierarchy_outputs/linear_model_comparison.pdf", width = 10, height = 6)
par(mfrow = c(1, 2))

barplot(fit_stats_linear$BIC,
        names.arg = c("Unrestr", "Hierarch", "HO-GDINA"),
        main = "Model Comparison (BIC)",
        ylab = "BIC",
        col = c("gray", "steelblue", "coral"),
        las = 2)

barplot(c(acc_unrestr, acc_hier, acc_ho) * 100,
        names.arg = c("Unrestr", "Hierarch", "HO-GDINA"),
        main = "Classification Accuracy",
        ylab = "Accuracy (%)",
        col = c("gray", "steelblue", "coral"),
        las = 2,
        ylim = c(0, 100))

dev.off()

# 2.8.3 Correlation heatmap
pdf("hierarchy_outputs/linear_correlation_heatmap.pdf", width = 8, height = 8)
tetra_melt <- melt(tetra_cor)
ggplot(tetra_melt, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(value, 2)), color = "black", size = 5) +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                      midpoint = 0, limit = c(-1, 1)) +
  theme_minimal() +
  labs(title = "Tetrachoric Correlations: Linear Hierarchy",
       x = "", y = "", fill = "Correlation") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
dev.off()

cat("  Grafikler kaydedildi.\n\n")

################################################################################
# BÖLÜM 3: ÖRNEK 2 - CONVERGENT HİYERAŞİ (OKUMA ANLAMA)
################################################################################

cat("\n################################################################################\n")
cat("BÖLÜM 3: CONVERGENT HİYERAŞİ ÖRNEĞİ - OKUMA ANLAMA\n")
cat("################################################################################\n\n")

set.seed(2025)

# 3.1 Q-Matrix -----------------------------------------------------------------
cat("3.1 Q-Matrix ve Hiyerarşi Yapısı\n\n")

# Convergent hierarchy: Vocabulary -> Comprehension <- Grammar
#                       (A1)     ->      (A3)      <-   (A2)

Q_conv <- matrix(c(
  # A1  A2  A3
    1,  0,  0,   # Item 1: Vocabulary only
    1,  0,  0,   # Item 2: Vocabulary
    0,  1,  0,   # Item 3: Grammar only
    0,  1,  0,   # Item 4: Grammar
    1,  0,  1,   # Item 5: Vocab -> Comprehension
    0,  1,  1,   # Item 6: Grammar -> Comprehension
    1,  1,  0,   # Item 7: Vocab + Grammar
    1,  0,  1,   # Item 8: Vocab -> Comprehension
    0,  1,  1,   # Item 9: Grammar -> Comprehension
    1,  1,  1,   # Item 10: All
    0,  0,  1,   # Item 11: Comprehension only
    1,  1,  1,   # Item 12: All
    1,  0,  1,   # Item 13: Vocab -> Comprehension
    0,  1,  1,   # Item 14: Grammar -> Comprehension
    1,  1,  1    # Item 15: All
), ncol = 3, byrow = TRUE)

colnames(Q_conv) <- c("Vocabulary", "Grammar", "Comprehension")
rownames(Q_conv) <- paste0("Item", 1:nrow(Q_conv))

cat("Q-Matrix:\n")
print(Q_conv)
cat("\n")

# 3.2 Hiyerarşi Matrisi --------------------------------------------------------
cat("3.2 Hiyerarşi Matrisi\n\n")

# Convergent: A1 -> A3, A2 -> A3
hierarchy_conv <- matrix(c(
  # A1  A2  A3
    0,  0,  1,   # A1 -> A3
    0,  0,  1,   # A2 -> A3
    0,  0,  0    # A3 (en üst)
), nrow = 3, byrow = TRUE)

rownames(hierarchy_conv) <- colnames(Q_conv)
colnames(hierarchy_conv) <- colnames(Q_conv)

cat("Hiyerarşi Matrisi:\n")
print(hierarchy_conv)
cat("\nYapı: Vocabulary -> Comprehension <- Grammar\n\n")

# Valid patterns
valid_patterns_conv <- GDINA::attributepattern(3, hierarchy = hierarchy_conv)
cat(sprintf("Geçerli pattern sayısı: %d\n", nrow(valid_patterns_conv)))
cat("\nGeçerli Patterns:\n")
print(valid_patterns_conv)
cat("\n")

# 3.3 Veri Simülasyonu ---------------------------------------------------------
cat("3.3 Veri Simülasyonu\n\n")

n_students_conv <- 400

# Pattern probabilities
pattern_probs_conv <- c(0.25, 0.20, 0.18, 0.15, 0.12, 0.10)
pattern_probs_conv <- pattern_probs_conv / sum(pattern_probs_conv)

student_patterns_conv <- sample(1:nrow(valid_patterns_conv), n_students_conv,
                                replace = TRUE, prob = pattern_probs_conv)
true_alpha_conv <- as.matrix(valid_patterns_conv[student_patterns_conv, ])

# GDINA simülasyon
sim_conv <- GDINA::simGDINA(
  N = n_students_conv,
  Q = Q_conv,
  model = "GDINA",
  attribute = true_alpha_conv
)

data_conv <- sim_conv$dat
cat(sprintf("Simüle veri: %d öğrenci x %d madde\n\n",
            nrow(data_conv), ncol(data_conv)))

# 3.4 Model Tahminleme ---------------------------------------------------------
cat("3.4 Model Tahminleme\n\n")

cat("  3.4.1 GDINA (Unrestricted)...\n")
fit_conv_unrestr <- GDINA::GDINA(
  dat = data_conv,
  Q = Q_conv,
  model = "GDINA",
  control = list(maxitr = 2000)
)

cat("  3.4.2 GDINA (Convergent Hierarchy)...\n")
fit_conv_hier <- GDINA::GDINA(
  dat = data_conv,
  Q = Q_conv,
  model = "GDINA",
  att.str = hierarchy_conv,
  control = list(maxitr = 2000)
)

cat("\n  Modeller tahminlendi!\n\n")

# 3.5 Model Karşılaştırma ------------------------------------------------------
cat("3.5 Model Karşılaştırma\n\n")

fit_stats_conv <- data.frame(
  Model = c("GDINA-Unrestricted", "GDINA-Hierarchical"),
  Deviance = NA,
  AIC = NA,
  BIC = NA,
  n_par = NA
)

fits_conv <- list(fit_conv_unrestr, fit_conv_hier)

for (i in 1:2) {
  fit <- modelfit(fits_conv[[i]])
  fit_stats_conv$Deviance[i] <- fit$deviance
  fit_stats_conv$AIC[i] <- fit$AIC
  fit_stats_conv$BIC[i] <- fit$BIC
  fit_stats_conv$n_par[i] <- fit$npar
}

print(fit_stats_conv)
cat("\n")

# 3.6 Classification Accuracy --------------------------------------------------
est_alpha_conv <- personparm(fit_conv_hier, what = "EAP")
acc_conv <- mean(est_alpha_conv == true_alpha_conv)

cat(sprintf("Sınıflandırma Doğruluğu (Hierarchical): %.2f%%\n\n", acc_conv * 100))

# 3.7 Görselleştirme -----------------------------------------------------------
cat("3.7 Görselleştirme\n\n")

pdf("hierarchy_outputs/convergent_hierarchy_network.pdf", width = 10, height = 8)

g_conv <- graph_from_adjacency_matrix(hierarchy_conv, mode = "directed")
V(g_conv)$label <- colnames(Q_conv)
V(g_conv)$color <- c("lightblue", "lightgreen", "lightyellow")
V(g_conv)$size <- 40

# Convergent yapı için özel layout
layout_conv <- matrix(c(
  -1, 0,   # Vocabulary (sol)
   1, 0,   # Grammar (sağ)
   0, 1    # Comprehension (üst-orta)
), ncol = 2, byrow = TRUE)

plot(g_conv,
     layout = layout_conv,
     main = "Convergent Attribute Hierarchy: Reading Comprehension",
     edge.arrow.size = 1,
     vertex.label.cex = 1.2,
     vertex.label.color = "black")

dev.off()

cat("  Grafik kaydedildi.\n\n")

################################################################################
# BÖLÜM 4: ÖRNEK 3 - DIVERGENT HİYERAŞİ
################################################################################

cat("\n################################################################################\n")
cat("BÖLÜM 4: DIVERGENT HİYERAŞİ ÖRNEĞİ\n")
cat("################################################################################\n\n")

set.seed(2026)

# 4.1 Q-Matrix -----------------------------------------------------------------
cat("4.1 Q-Matrix ve Hiyerarşi Yapısı\n\n")

# Divergent: Number Sense -> Addition/Subtraction
#                        -> Multiplication/Division

Q_div <- matrix(c(
  # A1  A2  A3
    1,  0,  0,   # Item 1: Number sense only
    1,  0,  0,   # Item 2: Number sense
    1,  1,  0,   # Item 3: Number sense -> Add/Sub
    0,  1,  0,   # Item 4: Add/Sub only
    1,  1,  0,   # Item 5: Number sense -> Add/Sub
    1,  0,  1,   # Item 6: Number sense -> Mult/Div
    0,  0,  1,   # Item 7: Mult/Div only
    1,  0,  1,   # Item 8: Number sense -> Mult/Div
    0,  1,  0,   # Item 9: Add/Sub
    0,  0,  1,   # Item 10: Mult/Div
    1,  1,  1,   # Item 11: All
    1,  1,  1    # Item 12: All
), ncol = 3, byrow = TRUE)

colnames(Q_div) <- c("NumberSense", "AddSub", "MultDiv")
rownames(Q_div) <- paste0("Item", 1:nrow(Q_div))

cat("Q-Matrix:\n")
print(Q_div)
cat("\n")

# 4.2 Hiyerarşi Matrisi --------------------------------------------------------
cat("4.2 Hiyerarşi Matrisi\n\n")

# Divergent: A1 -> A2, A1 -> A3
hierarchy_div <- matrix(c(
  # A1  A2  A3
    0,  1,  1,   # A1 -> A2, A1 -> A3
    0,  0,  0,   # A2
    0,  0,  0    # A3
), nrow = 3, byrow = TRUE)

rownames(hierarchy_div) <- colnames(Q_div)
colnames(hierarchy_div) <- colnames(Q_div)

cat("Hiyerarşi Matrisi:\n")
print(hierarchy_div)
cat("\nYapı: NumberSense -> AddSub\n")
cat("                  -> MultDiv\n\n")

# Valid patterns
valid_patterns_div <- GDINA::attributepattern(3, hierarchy = hierarchy_div)
cat(sprintf("Geçerli pattern sayısı: %d\n", nrow(valid_patterns_div)))
cat("\nGeçerli Patterns:\n")
print(valid_patterns_div)
cat("\n")

# 4.3 Veri ve Model ------------------------------------------------------------
cat("4.3 Veri Simülasyonu ve Model\n\n")

n_students_div <- 350
pattern_probs_div <- c(0.30, 0.25, 0.20, 0.15, 0.10)
pattern_probs_div <- pattern_probs_div / sum(pattern_probs_div)

student_patterns_div <- sample(1:nrow(valid_patterns_div), n_students_div,
                               replace = TRUE, prob = pattern_probs_div)
true_alpha_div <- as.matrix(valid_patterns_div[student_patterns_div, ])

sim_div <- GDINA::simGDINA(
  N = n_students_div,
  Q = Q_div,
  model = "ACDM",
  attribute = true_alpha_div
)

data_div <- sim_div$dat

cat("  Model tahminleniyor...\n")
fit_div_hier <- GDINA::GDINA(
  dat = data_div,
  Q = Q_div,
  model = "ACDM",
  att.str = hierarchy_div,
  control = list(maxitr = 2000)
)

est_alpha_div <- personparm(fit_div_hier, what = "EAP")
acc_div <- mean(est_alpha_div == true_alpha_div)

cat(sprintf("\nSınıflandırma Doğruluğu: %.2f%%\n\n", acc_div * 100))

# 4.4 Görselleştirme -----------------------------------------------------------
cat("4.4 Görselleştirme\n\n")

pdf("hierarchy_outputs/divergent_hierarchy_network.pdf", width = 10, height = 8)

g_div <- graph_from_adjacency_matrix(hierarchy_div, mode = "directed")
V(g_div)$label <- colnames(Q_div)
V(g_div)$color <- c("lightcoral", "lightblue", "lightgreen")
V(g_div)$size <- 40

# Divergent yapı için layout
layout_div <- matrix(c(
   0, 0,   # NumberSense (alt-orta)
  -1, 1,   # AddSub (üst-sol)
   1, 1    # MultDiv (üst-sağ)
), ncol = 2, byrow = TRUE)

plot(g_div,
     layout = layout_div,
     main = "Divergent Attribute Hierarchy: Number Operations",
     edge.arrow.size = 1,
     vertex.label.cex = 1.2,
     vertex.label.color = "black")

dev.off()

cat("  Grafik kaydedildi.\n\n")

################################################################################
# BÖLÜM 5: HİYERAŞİ KARŞILAŞTIRMA
################################################################################

cat("\n################################################################################\n")
cat("BÖLÜM 5: HİYERAŞİ YAPILARININ KARŞILAŞTIRILMASI\n")
cat("################################################################################\n\n")

# Özet tablo
summary_table <- data.frame(
  Hierarchy = c("Linear", "Convergent", "Divergent"),
  Attributes = c(4, 3, 3),
  Valid_Patterns = c(nrow(valid_patterns),
                    nrow(valid_patterns_conv),
                    nrow(valid_patterns_div)),
  Total_Possible = c(16, 8, 8),
  Reduction = c(
    sprintf("%.1f%%", (1 - nrow(valid_patterns)/16) * 100),
    sprintf("%.1f%%", (1 - nrow(valid_patterns_conv)/8) * 100),
    sprintf("%.1f%%", (1 - nrow(valid_patterns_div)/8) * 100)
  ),
  Classification_Acc = c(
    sprintf("%.1f%%", acc_hier * 100),
    sprintf("%.1f%%", acc_conv * 100),
    sprintf("%.1f%%", acc_div * 100)
  )
)

cat("Hiyerarşi Yapıları Karşılaştırması:\n")
print(summary_table)
cat("\n")

# Comparison plot
pdf("hierarchy_outputs/hierarchy_comparison.pdf", width = 12, height = 6)
par(mfrow = c(1, 2))

barplot(c(nrow(valid_patterns), nrow(valid_patterns_conv), nrow(valid_patterns_div)),
        names.arg = c("Linear", "Convergent", "Divergent"),
        main = "Valid Attribute Patterns",
        ylab = "Number of Valid Patterns",
        col = c("steelblue", "coral", "lightgreen"),
        ylim = c(0, 12))

barplot(c(acc_hier, acc_conv, acc_div) * 100,
        names.arg = c("Linear", "Convergent", "Divergent"),
        main = "Classification Accuracy",
        ylab = "Accuracy (%)",
        col = c("steelblue", "coral", "lightgreen"),
        ylim = c(0, 100))
abline(h = 80, lty = 2, col = "red")

dev.off()

cat("Karşılaştırma grafiği kaydedildi.\n\n")

################################################################################
# BÖLÜM 6: HIGHER-ORDER CDM ANALİZİ
################################################################################

cat("\n################################################################################\n")
cat("BÖLÜM 6: HIGHER-ORDER CDM (Üst Düzey Genel Yetenek)\n")
cat("################################################################################\n\n")

cat("Higher-Order CDM, bilişsel özellikleri üst düzey bir genel yetenek (θ)\n")
cat("ile ilişkilendirir. Her özellik, genel yetenekle lojistik ilişkilidir.\n\n")

# Linear data kullanarak HO-CDM
cat("6.1 Higher-Order Model Parametreleri\n\n")

# Extract HO parameters
ho_params <- extract(fit_linear_ho, "higher.order")

cat("Genel Yetenek Parametreleri:\n")
cat(sprintf("  - Model: %s\n", ho_params$model))
cat(sprintf("  - Attribute sayısı: %d\n", length(ho_params$lambda)))

cat("\nAttribute-Theta İlişkisi (Lambda parametreleri):\n")
for (k in 1:length(ho_params$lambda)) {
  cat(sprintf("  - %s: λ = %.3f, d = %.3f\n",
              colnames(Q_linear)[k],
              ho_params$lambda[k],
              ho_params$d[k]))
}
cat("\n")

cat("Lambda yorumu:\n")
cat("  - Yüksek λ: Özellik genel yetenek ile güçlü ilişkili\n")
cat("  - Düşük λ: Özellik genel yetenekten daha bağımsız\n\n")

# Theta dağılımı
theta_est <- ho_params$theta.est
cat("Genel Yetenek (θ) Dağılımı:\n")
cat(sprintf("  - Ortalama: %.3f\n", mean(theta_est)))
cat(sprintf("  - Standart sapma: %.3f\n", sd(theta_est)))
cat(sprintf("  - Min: %.3f\n", min(theta_est)))
cat(sprintf("  - Max: %.3f\n", max(theta_est)))
cat("\n")

# Theta histogram
pdf("hierarchy_outputs/higher_order_theta_distribution.pdf", width = 10, height = 6)
par(mfrow = c(1, 2))

hist(theta_est, breaks = 30, col = "steelblue",
     main = "Distribution of θ (General Ability)",
     xlab = "θ", ylab = "Frequency")
curve(dnorm(x, mean(theta_est), sd(theta_est)) * length(theta_est) *
      diff(range(theta_est))/30,
      add = TRUE, col = "red", lwd = 2)

# Lambda plot
barplot(ho_params$lambda,
        names.arg = colnames(Q_linear),
        main = "Attribute-Theta Discrimination (λ)",
        ylab = "Lambda",
        col = rainbow(ncol(Q_linear)),
        las = 2)

dev.off()

cat("Higher-order grafikler kaydedildi.\n\n")

################################################################################
# ÖZET RAPOR
################################################################################

cat("\n################################################################################\n")
cat("ANALİZ ÖZET RAPORU\n")
cat("################################################################################\n\n")

cat("=== BÖLÜM 1: LINEAR HİYERAŞİ ===\n")
cat(sprintf("  Yapı: %s\n", "Basic -> Fraction -> ProbSolv -> Algebra"))
cat(sprintf("  Özellik sayısı: %d\n", ncol(Q_linear)))
cat(sprintf("  Geçerli pattern: %d / 16\n", nrow(valid_patterns)))
cat(sprintf("  En iyi model: %s\n", fit_stats_linear$Model[best_idx]))
cat(sprintf("  Sınıflandırma doğruluğu: %.1f%%\n\n", acc_hier * 100))

cat("=== BÖLÜM 2: CONVERGENT HİYERAŞİ ===\n")
cat(sprintf("  Yapı: %s\n", "Vocabulary -> Comprehension <- Grammar"))
cat(sprintf("  Özellik sayısı: %d\n", ncol(Q_conv)))
cat(sprintf("  Geçerli pattern: %d / 8\n", nrow(valid_patterns_conv)))
cat(sprintf("  Sınıflandırma doğruluğu: %.1f%%\n\n", acc_conv * 100))

cat("=== BÖLÜM 3: DIVERGENT HİYERAŞİ ===\n")
cat(sprintf("  Yapı: %s\n", "NumberSense -> AddSub/MultDiv"))
cat(sprintf("  Özellik sayısı: %d\n", ncol(Q_div)))
cat(sprintf("  Geçerli pattern: %d / 8\n", nrow(valid_patterns_div)))
cat(sprintf("  Sınıflandırma doğruluğu: %.1f%%\n\n", acc_div * 100))

cat("=== HIGHER-ORDER CDM ===\n")
cat(sprintf("  Ortalama θ: %.3f (SD: %.3f)\n",
            mean(theta_est), sd(theta_est)))
cat(sprintf("  En yüksek λ: %s (%.3f)\n",
            colnames(Q_linear)[which.max(ho_params$lambda)],
            max(ho_params$lambda)))
cat("\n")

cat("=== ÇIKTI DOSYALARI ===\n\n")
cat("Tüm dosyalar 'hierarchy_outputs/' klasöründe:\n")
cat("  - linear_hierarchy_network.pdf\n")
cat("  - linear_model_comparison.pdf\n")
cat("  - linear_correlation_heatmap.pdf\n")
cat("  - convergent_hierarchy_network.pdf\n")
cat("  - divergent_hierarchy_network.pdf\n")
cat("  - hierarchy_comparison.pdf\n")
cat("  - higher_order_theta_distribution.pdf\n")
cat("\n")

cat("################################################################################\n")
cat("ANALİZ TAMAMLANDI!\n")
cat("################################################################################\n\n")

# Workspace kaydet
save.image(file = "hierarchy_outputs/hierarchy_analysis_workspace.RData")
cat("Workspace 'hierarchy_outputs/hierarchy_analysis_workspace.RData' olarak kaydedildi.\n\n")

# Özet CSV kaydet
write.csv(summary_table, "hierarchy_outputs/hierarchy_comparison_summary.csv",
          row.names = FALSE)
cat("Özet tablo CSV olarak kaydedildi.\n\n")
