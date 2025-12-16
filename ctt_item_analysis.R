################################################################################
# KLASIK TEST KURAMI (CTT) MADDE ANALİZİ
# Classical Test Theory Item Analysis
#
# Yazar: Profesyonel Ölçme ve Değerlendirme Uzmanı
# Tarih: 2025-12-16
################################################################################

# Gerekli kütüphaneleri yükle
required_packages <- c("ItemAnalysis", "psych", "ggplot2", "reshape2", "gridExtra",
                       "corrplot", "knitr", "dplyr", "tidyr", "CTT",
                       "officer", "flextable", "readxl")

# Eksik paketleri kontrol et ve yükle
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

################################################################################
# 1. VERİ YÜKLEME VE HAZIRLIK
################################################################################

cat("\n=== KLASİK TEST KURAMI MADDE ANALİZİ ===\n\n")

# Metadata dosyasını yükle (Excel'den)
cat("Metadata bilgileri yükleniyor...\n")
if (file.exists("metadata.xlsx")) {
  metadata <- readxl::read_excel("metadata.xlsx", sheet = 1)
  cat(sprintf("Toplam %d kitapçık bulundu.\n", nrow(metadata)))
  use_metadata <- TRUE
} else {
  cat("UYARI: metadata.xlsx dosyası bulunamadı. Tek analiz modu kullanılacak.\n")
  use_metadata <- FALSE
  metadata <- data.frame(
    Program = "Genel",
    alan = "Matematik",
    kitapcik = "A",
    beceri = "Genel",
    TemelEgit = "Temel",
    Turkce = "Evet",
    Sorguulama = 1,
    stringsAsFactors = FALSE
  )
}

# Veri dosyalarını yükle
cat("\nVeri yükleniyor...\n")
data <- read.table("mezitli_iho_mat_ham_data.csv", header = FALSE, sep = ";")
key <- read.csv("mezitli_iho_mat_key.csv", header = FALSE, sep = ";",
                colClasses = "character")

# Anahtar vektörünü oluştur
answer_key <- as.character(key[1, ])

# Veri boyutları
n_students <- nrow(data)
n_items <- ncol(data)

cat(sprintf("Öğrenci sayısı: %d\n", n_students))
cat(sprintf("Madde sayısı: %d\n\n", n_items))

################################################################################
# 2. PUANLAMA MATRİSİ OLUŞTURMA
################################################################################

cat("Puanlama matrisi oluşturuluyor...\n")

# Dikotom puanlama matrisi (0-1)
score_matrix <- matrix(0, nrow = n_students, ncol = n_items)

for (i in 1:n_items) {
  score_matrix[, i] <- as.numeric(data[, i] == answer_key[i])
}

# Toplam puanları hesapla
total_scores <- rowSums(score_matrix)

# Data frame oluştur
df_scores <- as.data.frame(score_matrix)
colnames(df_scores) <- paste0("Item_", 1:n_items)
df_scores$Total_Score <- total_scores

################################################################################
# 3. MADDE İSTATİSTİKLERİ
################################################################################

cat("Madde istatistikleri hesaplanıyor...\n")

item_statistics <- data.frame(
  Item_No = 1:n_items,
  Item_Difficulty = numeric(n_items),
  Item_Discrimination_PtBis = numeric(n_items),
  Item_Discrimination_PtBis_Corrected = numeric(n_items),
  Item_Total_Correlation = numeric(n_items),
  Mean_Score = numeric(n_items),
  SD = numeric(n_items),
  Alpha_if_Deleted = numeric(n_items),
  Interpretation_Difficulty = character(n_items),
  Interpretation_Discrimination = character(n_items),
  stringsAsFactors = FALSE
)

for (i in 1:n_items) {
  item_scores <- score_matrix[, i]

  # Madde güçlüğü (p-değeri)
  p_value <- mean(item_scores, na.rm = TRUE)
  item_statistics$Item_Difficulty[i] <- p_value
  item_statistics$Mean_Score[i] <- p_value
  item_statistics$SD[i] <- sd(item_scores, na.rm = TRUE)

  # Point-Biserial korelasyonu (ayırt edicilik)
  if (sd(item_scores) > 0 && sd(total_scores) > 0) {
    item_statistics$Item_Discrimination_PtBis[i] <- cor(item_scores, total_scores,
                                                         use = "complete.obs")

    # Düzeltilmiş madde-toplam korelasyonu (madde puanı çıkarılarak)
    total_without_item <- total_scores - item_scores
    item_statistics$Item_Discrimination_PtBis_Corrected[i] <- cor(item_scores,
                                                                   total_without_item,
                                                                   use = "complete.obs")
  } else {
    item_statistics$Item_Discrimination_PtBis[i] <- NA
    item_statistics$Item_Discrimination_PtBis_Corrected[i] <- NA
  }

  # Madde güçlüğü yorumu
  if (p_value < 0.20) {
    item_statistics$Interpretation_Difficulty[i] <- "Çok Zor"
  } else if (p_value < 0.40) {
    item_statistics$Interpretation_Difficulty[i] <- "Zor"
  } else if (p_value < 0.60) {
    item_statistics$Interpretation_Difficulty[i] <- "Orta"
  } else if (p_value < 0.80) {
    item_statistics$Interpretation_Difficulty[i] <- "Kolay"
  } else {
    item_statistics$Interpretation_Difficulty[i] <- "Çok Kolay"
  }

  # Ayırt edicilik yorumu (Point-Biserial)
  rpb <- item_statistics$Item_Discrimination_PtBis[i]
  if (is.na(rpb)) {
    item_statistics$Interpretation_Discrimination[i] <- "Hesaplanamadı"
  } else if (rpb < 0) {
    item_statistics$Interpretation_Discrimination[i] <- "Negatif (Sorunlu)"
  } else if (rpb < 0.20) {
    item_statistics$Interpretation_Discrimination[i] <- "Zayıf"
  } else if (rpb < 0.30) {
    item_statistics$Interpretation_Discrimination[i] <- "Kabul Edilebilir"
  } else if (rpb < 0.40) {
    item_statistics$Interpretation_Discrimination[i] <- "İyi"
  } else {
    item_statistics$Interpretation_Discrimination[i] <- "Çok İyi"
  }
}

################################################################################
# 4. GÜVENİRLİK ANALİZİ
################################################################################

cat("Güvenirlik analizi yapılıyor...\n")

# Cronbach's Alpha
alpha_result <- psych::alpha(score_matrix, check.keys = TRUE)
cronbach_alpha <- alpha_result$total$raw_alpha

# KR-20 (Kuder-Richardson Formula 20)
kr20 <- psych::KR20(score_matrix)

# Split-half güvenirliği
split_half <- psych::splitHalf(score_matrix)

cat(sprintf("\nGüvenirlik Katsayıları:\n"))
cat(sprintf("Cronbach's Alpha: %.3f\n", cronbach_alpha))
cat(sprintf("KR-20: %.3f\n", kr20$KR20))
cat(sprintf("Split-Half (Spearman-Brown): %.3f\n", split_half$sb))

# Alpha if item deleted
alpha_if_deleted <- alpha_result$alpha.drop$raw_alpha
item_statistics$Alpha_if_Deleted <- alpha_if_deleted

################################################################################
# 5. ÜÇTE BİRLİK YÖNTEMİ İLE AYIRT EDİCİLİK
################################################################################

cat("\nÜçte birlik yöntemi ile ayırt edicilik hesaplanıyor...\n")

# Toplam puanlara göre sırala
sorted_indices <- order(total_scores, decreasing = TRUE)
n_group <- floor(n_students / 3)

# Üst %27 ve alt %27 grupları
upper_group_indices <- sorted_indices[1:n_group]
lower_group_indices <- sorted_indices[(n_students - n_group + 1):n_students]

discrimination_27 <- data.frame(
  Item_No = 1:n_items,
  Upper_27_Correct = numeric(n_items),
  Lower_27_Correct = numeric(n_items),
  Discrimination_Index = numeric(n_items),
  Interpretation = character(n_items),
  stringsAsFactors = FALSE
)

for (i in 1:n_items) {
  upper_correct <- mean(score_matrix[upper_group_indices, i])
  lower_correct <- mean(score_matrix[lower_group_indices, i])
  disc_index <- upper_correct - lower_correct

  discrimination_27$Upper_27_Correct[i] <- upper_correct
  discrimination_27$Lower_27_Correct[i] <- lower_correct
  discrimination_27$Discrimination_Index[i] <- disc_index

  # Yorumlama
  if (disc_index < 0) {
    discrimination_27$Interpretation[i] <- "Negatif (Çıkarılmalı)"
  } else if (disc_index < 0.20) {
    discrimination_27$Interpretation[i] <- "Zayıf (Gözden Geçirilmeli)"
  } else if (disc_index < 0.30) {
    discrimination_27$Interpretation[i] <- "Kabul Edilebilir"
  } else if (disc_index < 0.40) {
    discrimination_27$Interpretation[i] <- "İyi"
  } else {
    discrimination_27$Interpretation[i] <- "Mükemmel"
  }
}

################################################################################
# 6. DETAYLI ÇELDİRİCİ ANALİZİ
################################################################################

cat("Detaylı çeldirici analizi yapılıyor...\n")

distractor_analysis <- list()
distractor_effectiveness <- data.frame(
  Item_No = 1:n_items,
  Correct_Answer = character(n_items),
  N_Options = integer(n_items),
  Key_Selected_Pct = numeric(n_items),
  Key_PtBis = numeric(n_items),
  Best_Distractor = character(n_items),
  Worst_Distractor = character(n_items),
  Non_Functioning_Distractors = character(n_items),
  Distractor_Quality = character(n_items),
  stringsAsFactors = FALSE
)

for (i in 1:n_items) {
  item_responses <- as.character(data[, i])
  unique_responses <- unique(item_responses)
  unique_responses <- unique_responses[!is.na(unique_responses) & unique_responses != ""]

  # Seçenekleri alfabetik sırala
  unique_responses <- sort(unique_responses)

  distractor_stats <- data.frame(
    Option = character(),
    Frequency = integer(),
    Percentage = numeric(),
    Point_Biserial = numeric(),
    Upper_27_N = integer(),
    Upper_27_Pct = numeric(),
    Middle_46_N = integer(),
    Middle_46_Pct = numeric(),
    Lower_27_N = integer(),
    Lower_27_Pct = numeric(),
    Discrimination_Index = numeric(),
    Mean_Total_Score = numeric(),
    Status = character(),
    Effectiveness = character(),
    stringsAsFactors = FALSE
  )

  # Orta grup indekslerini hesapla
  n_upper <- length(upper_group_indices)
  n_lower <- length(lower_group_indices)
  middle_group_indices <- sorted_indices[(n_upper + 1):(n_students - n_lower)]

  for (opt in unique_responses) {
    opt_selected <- (item_responses == opt)
    freq <- sum(opt_selected, na.rm = TRUE)
    pct <- (freq / n_students) * 100

    # Point-biserial korelasyonu
    if (sd(as.numeric(opt_selected), na.rm = TRUE) > 0 && sd(total_scores) > 0) {
      pb_cor <- cor(as.numeric(opt_selected), total_scores, use = "complete.obs")
    } else {
      pb_cor <- NA
    }

    # Üst, orta ve alt grup frekansları
    upper_n <- sum(item_responses[upper_group_indices] == opt, na.rm = TRUE)
    upper_pct <- (upper_n / length(upper_group_indices)) * 100

    middle_n <- sum(item_responses[middle_group_indices] == opt, na.rm = TRUE)
    middle_pct <- (middle_n / length(middle_group_indices)) * 100

    lower_n <- sum(item_responses[lower_group_indices] == opt, na.rm = TRUE)
    lower_pct <- (lower_n / length(lower_group_indices)) * 100

    # Ayırt edicilik indeksi (üst - alt)
    disc_index <- (upper_pct - lower_pct) / 100

    # Seçeneği seçenlerin ortalama puanı
    if (freq > 0) {
      mean_score <- mean(total_scores[opt_selected], na.rm = TRUE)
    } else {
      mean_score <- NA
    }

    # Durum
    if (opt == answer_key[i]) {
      status <- "Doğru Cevap (Key)"
      # Doğru cevap için etkinlik değerlendirmesi
      if (is.na(pb_cor)) {
        effectiveness <- "Hesaplanamadı"
      } else if (pb_cor >= 0.30 && pct >= 40) {
        effectiveness <- "Mükemmel"
      } else if (pb_cor >= 0.20 && pct >= 30) {
        effectiveness <- "İyi"
      } else if (pb_cor >= 0.10 && pct >= 20) {
        effectiveness <- "Kabul Edilebilir"
      } else {
        effectiveness <- "Zayıf"
      }
    } else {
      status <- "Çeldirici (Distractor)"
      # Çeldirici için etkinlik değerlendirmesi
      if (pct < 5) {
        effectiveness <- "İşlev Görmüyor (<5%)"
      } else if (is.na(pb_cor)) {
        effectiveness <- "Hesaplanamadı"
      } else if (pb_cor < 0 && lower_pct > upper_pct) {
        effectiveness <- "Çok İyi (Negatif korelasyon)"
      } else if (pb_cor < 0) {
        effectiveness <- "İyi (Negatif korelasyon)"
      } else if (pb_cor < 0.10) {
        effectiveness <- "Kabul Edilebilir"
      } else {
        effectiveness <- "Sorunlu (Pozitif korelasyon)"
      }
    }

    distractor_stats <- rbind(distractor_stats, data.frame(
      Option = opt,
      Frequency = freq,
      Percentage = pct,
      Point_Biserial = pb_cor,
      Upper_27_N = upper_n,
      Upper_27_Pct = upper_pct,
      Middle_46_N = middle_n,
      Middle_46_Pct = middle_pct,
      Lower_27_N = lower_n,
      Lower_27_Pct = lower_pct,
      Discrimination_Index = disc_index,
      Mean_Total_Score = mean_score,
      Status = status,
      Effectiveness = effectiveness,
      stringsAsFactors = FALSE
    ))
  }

  distractor_analysis[[i]] <- distractor_stats

  # Özet istatistikler
  distractor_effectiveness$Correct_Answer[i] <- answer_key[i]
  distractor_effectiveness$N_Options[i] <- nrow(distractor_stats)

  key_row <- distractor_stats[distractor_stats$Option == answer_key[i], ]
  if (nrow(key_row) > 0) {
    distractor_effectiveness$Key_Selected_Pct[i] <- key_row$Percentage
    distractor_effectiveness$Key_PtBis[i] <- key_row$Point_Biserial
  }

  # Çeldiriciler
  distractors <- distractor_stats[distractor_stats$Status == "Çeldirici (Distractor)", ]
  if (nrow(distractors) > 0) {
    # En etkili çeldirici (en yüksek seçilme oranı)
    best_dist_idx <- which.max(distractors$Percentage)
    distractor_effectiveness$Best_Distractor[i] <-
      sprintf("%s (%.1f%%)", distractors$Option[best_dist_idx],
              distractors$Percentage[best_dist_idx])

    # En zayıf çeldirici (en düşük seçilme oranı)
    worst_dist_idx <- which.min(distractors$Percentage)
    distractor_effectiveness$Worst_Distractor[i] <-
      sprintf("%s (%.1f%%)", distractors$Option[worst_dist_idx],
              distractors$Percentage[worst_dist_idx])

    # İşlev görmeyen çeldiriciler (<5% seçilme)
    non_func <- distractors$Option[distractors$Percentage < 5]
    if (length(non_func) > 0) {
      distractor_effectiveness$Non_Functioning_Distractors[i] <-
        paste(non_func, collapse = ", ")
    } else {
      distractor_effectiveness$Non_Functioning_Distractors[i] <- "Yok"
    }

    # Genel çeldirici kalitesi
    non_func_count <- sum(distractors$Percentage < 5)
    positive_pb_count <- sum(distractors$Point_Biserial > 0, na.rm = TRUE)

    if (non_func_count == 0 && positive_pb_count == 0) {
      distractor_effectiveness$Distractor_Quality[i] <- "Mükemmel"
    } else if (non_func_count <= 1 && positive_pb_count <= 1) {
      distractor_effectiveness$Distractor_Quality[i] <- "İyi"
    } else if (non_func_count <= 2 || positive_pb_count <= 2) {
      distractor_effectiveness$Distractor_Quality[i] <- "Kabul Edilebilir"
    } else {
      distractor_effectiveness$Distractor_Quality[i] <- "Zayıf"
    }
  } else {
    distractor_effectiveness$Best_Distractor[i] <- "N/A"
    distractor_effectiveness$Worst_Distractor[i] <- "N/A"
    distractor_effectiveness$Non_Functioning_Distractors[i] <- "N/A"
    distractor_effectiveness$Distractor_Quality[i] <- "N/A"
  }
}

################################################################################
# 7. BETIMSEL İSTATİSTİKLER
################################################################################

cat("Betimsel istatistikler hesaplanıyor...\n")

descriptive_stats <- data.frame(
  Statistic = c("Ortalama", "Standart Sapma", "Varyans", "Minimum",
                "Maksimum", "Medyan", "Çarpıklık", "Basıklık", "Ranj"),
  Value = c(
    mean(total_scores),
    sd(total_scores),
    var(total_scores),
    min(total_scores),
    max(total_scores),
    median(total_scores),
    psych::skew(total_scores),
    psych::kurtosi(total_scores),
    max(total_scores) - min(total_scores)
  )
)

################################################################################
# 8. GÖRSELLEŞTİRME
################################################################################

cat("Grafikler oluşturuluyor...\n")

# Klasör oluştur
if (!dir.exists("output")) {
  dir.create("output")
}

# 1. Toplam puan dağılımı
pdf("output/score_distribution.pdf", width = 10, height = 6)
hist(total_scores,
     breaks = 20,
     col = "steelblue",
     border = "white",
     main = "Toplam Puan Dağılımı",
     xlab = "Toplam Puan",
     ylab = "Frekans",
     las = 1)
abline(v = mean(total_scores), col = "red", lwd = 2, lty = 2)
legend("topright", legend = paste("Ortalama:", round(mean(total_scores), 2)),
       col = "red", lty = 2, lwd = 2)
dev.off()

# 2. Madde güçlüğü dağılımı
pdf("output/item_difficulty.pdf", width = 12, height = 6)
barplot(item_statistics$Item_Difficulty,
        names.arg = item_statistics$Item_No,
        col = ifelse(item_statistics$Item_Difficulty < 0.40, "red",
                    ifelse(item_statistics$Item_Difficulty < 0.60, "green", "orange")),
        main = "Madde Güçlük İndeksleri",
        xlab = "Madde Numarası",
        ylab = "Güçlük İndeksi (p)",
        las = 2,
        cex.names = 0.7)
abline(h = c(0.40, 0.60), col = "blue", lty = 2)
legend("topright",
       legend = c("Zor (<0.40)", "Orta (0.40-0.60)", "Kolay (>0.60)"),
       fill = c("red", "green", "orange"))
dev.off()

# 3. Madde ayırt edicilik dağılımı
pdf("output/item_discrimination.pdf", width = 12, height = 6)
barplot(item_statistics$Item_Discrimination_PtBis_Corrected,
        names.arg = item_statistics$Item_No,
        col = ifelse(item_statistics$Item_Discrimination_PtBis_Corrected < 0.20, "red",
                    ifelse(item_statistics$Item_Discrimination_PtBis_Corrected < 0.30, "orange",
                          ifelse(item_statistics$Item_Discrimination_PtBis_Corrected < 0.40, "yellow", "green"))),
        main = "Madde Ayırt Edicilik İndeksleri (Düzeltilmiş Point-Biserial)",
        xlab = "Madde Numarası",
        ylab = "Ayırt Edicilik İndeksi",
        las = 2,
        cex.names = 0.7)
abline(h = c(0.20, 0.30, 0.40), col = "blue", lty = 2)
legend("topright",
       legend = c("Zayıf (<0.20)", "Kabul Edilebilir (0.20-0.30)",
                  "İyi (0.30-0.40)", "Çok İyi (>0.40)"),
       fill = c("red", "orange", "yellow", "green"))
dev.off()

# 4. Madde güçlüğü vs ayırt edicilik scatter plot
pdf("output/difficulty_vs_discrimination.pdf", width = 10, height = 8)
plot(item_statistics$Item_Difficulty,
     item_statistics$Item_Discrimination_PtBis_Corrected,
     pch = 19,
     col = "steelblue",
     main = "Madde Güçlüğü vs Ayırt Edicilik",
     xlab = "Madde Güçlüğü (p-değeri)",
     ylab = "Ayırt Edicilik (rpbis)",
     xlim = c(0, 1),
     ylim = c(-0.5, 1))
text(item_statistics$Item_Difficulty,
     item_statistics$Item_Discrimination_PtBis_Corrected,
     labels = item_statistics$Item_No,
     pos = 3,
     cex = 0.7)
abline(h = 0.30, col = "red", lty = 2)
abline(v = c(0.40, 0.60), col = "red", lty = 2)
grid()
dev.off()

# 5. Üçte birlik ayırt edicilik
pdf("output/discrimination_27.pdf", width = 12, height = 6)
barplot(discrimination_27$Discrimination_Index,
        names.arg = discrimination_27$Item_No,
        col = ifelse(discrimination_27$Discrimination_Index < 0, "red",
                    ifelse(discrimination_27$Discrimination_Index < 0.30, "orange",
                          ifelse(discrimination_27$Discrimination_Index < 0.40, "yellow", "green"))),
        main = "Üçte Birlik Yöntemi ile Ayırt Edicilik",
        xlab = "Madde Numarası",
        ylab = "Ayırt Edicilik İndeksi (Üst %27 - Alt %27)",
        las = 2,
        cex.names = 0.7)
abline(h = c(0, 0.30, 0.40), col = "blue", lty = 2)
legend("topright",
       legend = c("Negatif", "Zayıf (0-0.30)", "İyi (0.30-0.40)", "Mükemmel (>0.40)"),
       fill = c("red", "orange", "yellow", "green"))
dev.off()

# 6. Korelasyon matrisi (ilk 20 madde için)
if (n_items > 1) {
  pdf("output/item_correlation_matrix.pdf", width = 12, height = 12)
  items_to_plot <- min(20, n_items)
  cor_matrix <- cor(score_matrix[, 1:items_to_plot], use = "complete.obs")
  corrplot::corrplot(cor_matrix,
                     method = "color",
                     type = "upper",
                     tl.col = "black",
                     tl.srt = 45,
                     title = "Maddeler Arası Korelasyon Matrisi (İlk 20 Madde)",
                     mar = c(0, 0, 2, 0))
  dev.off()
}

# 7. Çeldirici etkinliği grafiği
pdf("output/distractor_quality.pdf", width = 12, height = 6)
quality_colors <- c("Mükemmel" = "darkgreen", "İyi" = "green",
                    "Kabul Edilebilir" = "orange", "Zayıf" = "red", "N/A" = "gray")
barplot_colors <- quality_colors[distractor_effectiveness$Distractor_Quality]
barplot(rep(1, n_items),
        names.arg = distractor_effectiveness$Item_No,
        col = barplot_colors,
        main = "Madde Bazında Çeldirici Kalitesi",
        xlab = "Madde Numarası",
        ylab = "",
        las = 2,
        yaxt = "n",
        cex.names = 0.7)
legend("topright",
       legend = names(quality_colors),
       fill = quality_colors,
       title = "Çeldirici Kalitesi")
dev.off()

# 8. Doğru cevap seçim oranları
pdf("output/key_selection_rate.pdf", width = 12, height = 6)
barplot(distractor_effectiveness$Key_Selected_Pct,
        names.arg = distractor_effectiveness$Item_No,
        col = ifelse(distractor_effectiveness$Key_Selected_Pct < 40, "red",
                    ifelse(distractor_effectiveness$Key_Selected_Pct < 60, "orange", "green")),
        main = "Doğru Cevap Seçim Oranları",
        xlab = "Madde Numarası",
        ylab = "Seçim Oranı (%)",
        las = 2,
        cex.names = 0.7,
        ylim = c(0, 100))
abline(h = c(40, 60, 80), col = "blue", lty = 2)
legend("topright",
       legend = c("Düşük (<40%)", "Orta (40-60%)", "Yüksek (>60%)"),
       fill = c("red", "orange", "green"))
dev.off()

################################################################################
# 9. RAPOR OLUŞTURMA
################################################################################

cat("\nRapor oluşturuluyor...\n")

# Ana rapor dosyası
sink("output/item_analysis_report.txt")

cat("================================================================================\n")
cat("                    KLASİK TEST KURAMI MADDE ANALİZİ RAPORU\n")
cat("                 CLASSICAL TEST THEORY ITEM ANALYSIS REPORT\n")
cat("================================================================================\n\n")

cat(sprintf("Analiz Tarihi: %s\n", Sys.Date()))
cat(sprintf("Veri Dosyası: mezitli_iho_mat_ham_data.csv\n"))
cat(sprintf("Anahtar Dosyası: mezitli_iho_mat_key.csv\n\n"))

cat("--------------------------------------------------------------------------------\n")
cat("1. GENEL BİLGİLER\n")
cat("--------------------------------------------------------------------------------\n")
cat(sprintf("Toplam Öğrenci Sayısı: %d\n", n_students))
cat(sprintf("Toplam Madde Sayısı: %d\n", n_items))
cat(sprintf("Maksimum Puan: %d\n\n", n_items))

cat("--------------------------------------------------------------------------------\n")
cat("2. BETİMSEL İSTATİSTİKLER (Toplam Puanlar)\n")
cat("--------------------------------------------------------------------------------\n")
print(descriptive_stats, row.names = FALSE)
cat("\n")

cat("--------------------------------------------------------------------------------\n")
cat("3. GÜVENİRLİK ANALİZİ\n")
cat("--------------------------------------------------------------------------------\n")
cat(sprintf("Cronbach's Alpha: %.4f\n", cronbach_alpha))
cat(sprintf("KR-20 (Kuder-Richardson): %.4f\n", kr20$KR20))
cat(sprintf("Split-Half (Spearman-Brown): %.4f\n\n", split_half$sb))

cat("Güvenirlik Yorumu:\n")
if (cronbach_alpha >= 0.90) {
  cat("  - Mükemmel güvenirlik (α ≥ 0.90)\n")
} else if (cronbach_alpha >= 0.80) {
  cat("  - İyi güvenirlik (0.80 ≤ α < 0.90)\n")
} else if (cronbach_alpha >= 0.70) {
  cat("  - Kabul edilebilir güvenirlik (0.70 ≤ α < 0.80)\n")
} else if (cronbach_alpha >= 0.60) {
  cat("  - Sorgulanabilir güvenirlik (0.60 ≤ α < 0.70)\n")
} else {
  cat("  - Kabul edilemez güvenirlik (α < 0.60)\n")
}
cat("\n")

cat("--------------------------------------------------------------------------------\n")
cat("4. MADDE İSTATİSTİKLERİ ÖZETI\n")
cat("--------------------------------------------------------------------------------\n")
print(item_statistics, row.names = FALSE)
cat("\n")

cat("--------------------------------------------------------------------------------\n")
cat("5. ÜÇTE BİRLİK YÖNTEMİ İLE AYIRT EDİCİLİK\n")
cat("--------------------------------------------------------------------------------\n")
print(discrimination_27, row.names = FALSE)
cat("\n")

cat("--------------------------------------------------------------------------------\n")
cat("6. SORUNLU MADDELER\n")
cat("--------------------------------------------------------------------------------\n")

# Negatif ayırt ediciliğe sahip maddeler
negative_disc <- item_statistics[item_statistics$Item_Discrimination_PtBis_Corrected < 0, ]
if (nrow(negative_disc) > 0) {
  cat("\nNegatif Ayırt Ediciliğe Sahip Maddeler (Çıkarılmalı):\n")
  print(negative_disc[, c("Item_No", "Item_Difficulty", "Item_Discrimination_PtBis_Corrected")],
        row.names = FALSE)
} else {
  cat("\nNegatif ayırt ediciliğe sahip madde bulunmamaktadır.\n")
}

# Çok zor maddeler
very_hard <- item_statistics[item_statistics$Item_Difficulty < 0.20, ]
if (nrow(very_hard) > 0) {
  cat("\nÇok Zor Maddeler (p < 0.20):\n")
  print(very_hard[, c("Item_No", "Item_Difficulty", "Item_Discrimination_PtBis_Corrected")],
        row.names = FALSE)
}

# Çok kolay maddeler
very_easy <- item_statistics[item_statistics$Item_Difficulty > 0.80, ]
if (nrow(very_easy) > 0) {
  cat("\nÇok Kolay Maddeler (p > 0.80):\n")
  print(very_easy[, c("Item_No", "Item_Difficulty", "Item_Discrimination_PtBis_Corrected")],
        row.names = FALSE)
}

# Zayıf ayırt edicilik
weak_disc <- item_statistics[item_statistics$Item_Discrimination_PtBis_Corrected < 0.20 &
                              item_statistics$Item_Discrimination_PtBis_Corrected >= 0, ]
if (nrow(weak_disc) > 0) {
  cat("\nZayıf Ayırt Ediciliğe Sahip Maddeler (0 ≤ rpbis < 0.20):\n")
  print(weak_disc[, c("Item_No", "Item_Difficulty", "Item_Discrimination_PtBis_Corrected")],
        row.names = FALSE)
}
cat("\n")

cat("--------------------------------------------------------------------------------\n")
cat("7. ÇELDİRİCİ ETKİNLİĞİ ÖZETİ\n")
cat("--------------------------------------------------------------------------------\n")
print(distractor_effectiveness, row.names = FALSE)
cat("\n")

cat("--------------------------------------------------------------------------------\n")
cat("8. DETAYLI ÇELDİRİCİ ANALİZİ (Her Madde İçin)\n")
cat("--------------------------------------------------------------------------------\n\n")

for (i in 1:n_items) {
  cat(sprintf("MADDE %d (Doğru Cevap: %s):\n", i, answer_key[i]))
  cat(sprintf("Çeldirici Kalitesi: %s\n\n", distractor_effectiveness$Distractor_Quality[i]))
  print(distractor_analysis[[i]], row.names = FALSE)
  cat("\n")
  cat("Yorumlar:\n")

  # Doğru cevap yorumu
  key_row <- distractor_analysis[[i]][distractor_analysis[[i]]$Option == answer_key[i], ]
  if (nrow(key_row) > 0) {
    cat(sprintf("  - Doğru cevap (%s) seçim oranı: %.1f%%\n",
                answer_key[i], key_row$Percentage))
    cat(sprintf("  - Point-biserial korelasyon: %.3f\n", key_row$Point_Biserial))
    if (key_row$Upper_27_Pct > key_row$Lower_27_Pct) {
      cat(sprintf("  - ✓ Üst grup (%.1f%%) alt gruptan (%.1f%%) daha fazla seçmiş (İyi)\n",
                  key_row$Upper_27_Pct, key_row$Lower_27_Pct))
    } else {
      cat(sprintf("  - ✗ Alt grup (%.1f%%) üst gruptan (%.1f%%) daha fazla seçmiş (Sorunlu!)\n",
                  key_row$Lower_27_Pct, key_row$Upper_27_Pct))
    }
  }

  # Çeldirici yorumları
  distractors <- distractor_analysis[[i]][distractor_analysis[[i]]$Status == "Çeldirici (Distractor)", ]
  if (nrow(distractors) > 0) {
    cat("\n  Çeldirici Değerlendirme:\n")
    for (j in 1:nrow(distractors)) {
      cat(sprintf("  - Seçenek %s: %.1f%% (PB=%.3f, Etkinlik: %s)\n",
                  distractors$Option[j], distractors$Percentage[j],
                  distractors$Point_Biserial[j], distractors$Effectiveness[j]))
      if (distractors$Percentage[j] < 5) {
        cat("    → UYARI: İşlev görmüyor, değiştirilmeli!\n")
      }
      if (!is.na(distractors$Point_Biserial[j]) && distractors$Point_Biserial[j] > 0.10) {
        cat("    → UYARI: Pozitif korelasyon, yüksek başarılı öğrenciler seçiyor!\n")
      }
    }
  }
  cat("\n")
  cat(paste(rep("-", 80), collapse = ""))
  cat("\n\n")
}

cat("================================================================================\n")
cat("                              RAPOR SONU\n")
cat("================================================================================\n")

sink()

# Excel çıktısı için
write.csv(item_statistics, "output/item_statistics.csv", row.names = FALSE)
write.csv(discrimination_27, "output/discrimination_27.csv", row.names = FALSE)
write.csv(descriptive_stats, "output/descriptive_statistics.csv", row.names = FALSE)
write.csv(df_scores, "output/scored_data.csv", row.names = FALSE)
write.csv(distractor_effectiveness, "output/distractor_effectiveness_summary.csv", row.names = FALSE)

# Her madde için çeldirici analizi ayrı dosyalara
for (i in 1:n_items) {
  write.csv(distractor_analysis[[i]],
            sprintf("output/distractor_analysis_item_%d.csv", i),
            row.names = FALSE)
}

################################################################################
# 10. ÖNERİLER VE YORUMLAR
################################################################################

sink("output/recommendations.txt")

cat("================================================================================\n")
cat("                    MADDE ANALİZİ ÖNERİLERİ VE YORUMLAR\n")
cat("================================================================================\n\n")

cat("1. TEST GÜVENİRLİĞİ:\n")
cat(sprintf("   Cronbach's Alpha: %.4f\n", cronbach_alpha))
if (cronbach_alpha >= 0.80) {
  cat("   ✓ Test yüksek güvenilirliğe sahiptir.\n\n")
} else if (cronbach_alpha >= 0.70) {
  cat("   ⚠ Test kabul edilebilir güvenilirliğe sahiptir. Sorunlu maddelerin\n")
  cat("     gözden geçirilmesi güvenilirliği artırabilir.\n\n")
} else {
  cat("   ✗ Test düşük güvenilirliğe sahiptir. Ciddi revizyon gereklidir.\n\n")
}

cat("2. MADDE GÜÇLÜĞÜ:\n")
cat(sprintf("   Ortalama güçlük indeksi: %.3f\n", mean(item_statistics$Item_Difficulty)))
very_easy_count <- sum(item_statistics$Item_Difficulty > 0.80)
very_hard_count <- sum(item_statistics$Item_Difficulty < 0.20)
optimal_count <- sum(item_statistics$Item_Difficulty >= 0.40 &
                     item_statistics$Item_Difficulty <= 0.60)

cat(sprintf("   Çok kolay maddeler: %d\n", very_easy_count))
cat(sprintf("   Çok zor maddeler: %d\n", very_hard_count))
cat(sprintf("   Optimal güçlükte maddeler (0.40-0.60): %d\n\n", optimal_count))

cat("3. MADDE AYIRT EDİCİLİĞİ:\n")
excellent_disc <- sum(item_statistics$Item_Discrimination_PtBis_Corrected >= 0.40, na.rm = TRUE)
good_disc <- sum(item_statistics$Item_Discrimination_PtBis_Corrected >= 0.30 &
                 item_statistics$Item_Discrimination_PtBis_Corrected < 0.40, na.rm = TRUE)
acceptable_disc <- sum(item_statistics$Item_Discrimination_PtBis_Corrected >= 0.20 &
                       item_statistics$Item_Discrimination_PtBis_Corrected < 0.30, na.rm = TRUE)
weak_disc <- sum(item_statistics$Item_Discrimination_PtBis_Corrected >= 0 &
                 item_statistics$Item_Discrimination_PtBis_Corrected < 0.20, na.rm = TRUE)
negative_disc <- sum(item_statistics$Item_Discrimination_PtBis_Corrected < 0, na.rm = TRUE)

cat(sprintf("   Mükemmel (≥0.40): %d madde\n", excellent_disc))
cat(sprintf("   İyi (0.30-0.40): %d madde\n", good_disc))
cat(sprintf("   Kabul edilebilir (0.20-0.30): %d madde\n", acceptable_disc))
cat(sprintf("   Zayıf (0.00-0.20): %d madde\n", weak_disc))
cat(sprintf("   Negatif (<0.00): %d madde\n\n", negative_disc))

cat("4. ÖNERİLER:\n\n")

if (negative_disc > 0) {
  cat(sprintf("   ⚠ %d madde negatif ayırt ediciliğe sahiptir:\n", negative_disc))
  neg_items <- item_statistics[item_statistics$Item_Discrimination_PtBis_Corrected < 0, "Item_No"]
  cat(sprintf("     Maddeler: %s\n", paste(neg_items, collapse = ", ")))
  cat("     → Bu maddeler testten çıkarılmalı veya yeniden yazılmalıdır.\n\n")
}

if (weak_disc > 0) {
  cat(sprintf("   ⚠ %d madde zayıf ayırt ediciliğe sahiptir:\n", weak_disc))
  weak_items <- item_statistics[item_statistics$Item_Discrimination_PtBis_Corrected >= 0 &
                                item_statistics$Item_Discrimination_PtBis_Corrected < 0.20, "Item_No"]
  cat(sprintf("     Maddeler: %s\n", paste(weak_items, collapse = ", ")))
  cat("     → Bu maddelerin çeldiricileri gözden geçirilmelidir.\n\n")
}

if (very_easy_count > 0) {
  cat(sprintf("   ⚠ %d madde çok kolaydır (p > 0.80):\n", very_easy_count))
  easy_items <- item_statistics[item_statistics$Item_Difficulty > 0.80, "Item_No"]
  cat(sprintf("     Maddeler: %s\n", paste(easy_items, collapse = ", ")))
  cat("     → Bu maddeler zorlaştırılabilir veya çıkarılabilir.\n\n")
}

if (very_hard_count > 0) {
  cat(sprintf("   ⚠ %d madde çok zordur (p < 0.20):\n", very_hard_count))
  hard_items <- item_statistics[item_statistics$Item_Difficulty < 0.20, "Item_No"]
  cat(sprintf("     Maddeler: %s\n", paste(hard_items, collapse = ", ")))
  cat("     → Bu maddeler kolaylaştırılabilir veya çıkarılabilir.\n\n")
}

cat("5. GENEL DEĞERLENDİRME:\n\n")

quality_score <- 0
if (cronbach_alpha >= 0.80) quality_score <- quality_score + 25
else if (cronbach_alpha >= 0.70) quality_score <- quality_score + 15

if (excellent_disc + good_disc >= n_items * 0.5) quality_score <- quality_score + 25
else if (excellent_disc + good_disc >= n_items * 0.3) quality_score <- quality_score + 15

if (negative_disc == 0) quality_score <- quality_score + 25
else if (negative_disc <= 2) quality_score <- quality_score + 10

if (optimal_count >= n_items * 0.4) quality_score <- quality_score + 25
else if (optimal_count >= n_items * 0.2) quality_score <- quality_score + 15

cat(sprintf("   Test Kalite Skoru: %d/100\n\n", quality_score))

if (quality_score >= 80) {
  cat("   ✓ Test yüksek kalitededir ve kullanıma hazırdır.\n")
} else if (quality_score >= 60) {
  cat("   ⚠ Test kabul edilebilir kalitededir. Bazı iyileştirmeler yapılabilir.\n")
} else if (quality_score >= 40) {
  cat("   ⚠ Test orta kalitededir. Önemli revizyonlar gereklidir.\n")
} else {
  cat("   ✗ Test düşük kalitededir. Kapsamlı revizyon gereklidir.\n")
}

cat("\n")
cat("================================================================================\n")

sink()

################################################################################
# 11. WORD RAPORU OLUŞTURMA (OFFICER PAKETI)
################################################################################

cat("\nWord raporu oluşturuluyor...\n")

# Her satır (kitapçık) için Word raporu oluştur
for (row_idx in 1:nrow(metadata)) {
  meta_row <- metadata[row_idx, ]

  # Dosya adı oluştur (Excel sütunlarından)
  filename_parts <- c(
    as.character(meta_row$Program),
    as.character(meta_row$alan),
    paste0("Kitapcik_", as.character(meta_row$kitapcik)),
    as.character(meta_row$beceri),
    as.character(meta_row$TemelEgit),
    as.character(meta_row$Turkce),
    paste0("Sorgulama_", as.character(meta_row$Sorguulama))
  )

  # Boşlukları ve özel karakterleri temizle
  filename_parts <- gsub(" ", "_", filename_parts)
  filename_parts <- gsub("[^[:alnum:]_-]", "", filename_parts)

  doc_filename <- paste0("output/", paste(filename_parts, collapse = "_"), ".docx")

  cat(sprintf("  - %s oluşturuluyor...\n", basename(doc_filename)))

  # Yeni Word belgesi oluştur
  doc <- officer::read_docx()

  # Başlık ekle
  doc <- doc %>%
    officer::body_add_par("KLASİK TEST KURAMI MADDE ANALİZİ RAPORU",
                         style = "heading 1") %>%
    officer::body_add_par("Classical Test Theory Item Analysis Report",
                         style = "heading 2") %>%
    officer::body_add_par("", style = "Normal")

  # Metadata bilgilerini ekle
  doc <- doc %>%
    officer::body_add_par("Test Bilgileri", style = "heading 2") %>%
    officer::body_add_par("", style = "Normal")

  # Metadata tablosu oluştur
  meta_df <- data.frame(
    Özellik = c("Program", "Alan", "Kitapçık", "Beceri", "Temel Eğitim",
                "Türkçe", "Sorgulama", "Analiz Tarihi"),
    Değer = c(
      as.character(meta_row$Program),
      as.character(meta_row$alan),
      as.character(meta_row$kitapcik),
      as.character(meta_row$beceri),
      as.character(meta_row$TemelEgit),
      as.character(meta_row$Turkce),
      as.character(meta_row$Sorguulama),
      as.character(Sys.Date())
    ),
    stringsAsFactors = FALSE
  )

  ft_meta <- flextable::flextable(meta_df)
  ft_meta <- flextable::theme_vanilla(ft_meta)
  ft_meta <- flextable::autofit(ft_meta)

  doc <- doc %>%
    flextable::body_add_flextable(ft_meta) %>%
    officer::body_add_par("", style = "Normal")

  # Genel bilgiler
  doc <- doc %>%
    officer::body_add_par("Genel Bilgiler", style = "heading 2") %>%
    officer::body_add_par(sprintf("Toplam Öğrenci Sayısı: %d", n_students),
                         style = "Normal") %>%
    officer::body_add_par(sprintf("Toplam Madde Sayısı: %d", n_items),
                         style = "Normal") %>%
    officer::body_add_par(sprintf("Maksimum Puan: %d", n_items),
                         style = "Normal") %>%
    officer::body_add_par("", style = "Normal")

  # Güvenirlik katsayıları
  doc <- doc %>%
    officer::body_add_par("Güvenirlik Katsayıları", style = "heading 2") %>%
    officer::body_add_par(sprintf("Cronbach's Alpha: %.4f", cronbach_alpha),
                         style = "Normal") %>%
    officer::body_add_par(sprintf("KR-20: %.4f", kr20$KR20),
                         style = "Normal") %>%
    officer::body_add_par(sprintf("Split-Half (Spearman-Brown): %.4f", split_half$sb),
                         style = "Normal") %>%
    officer::body_add_par("", style = "Normal")

  # Güvenirlik yorumu
  reliability_comment <- if (cronbach_alpha >= 0.90) {
    "Mükemmel güvenirlik (α ≥ 0.90)"
  } else if (cronbach_alpha >= 0.80) {
    "İyi güvenirlik (0.80 ≤ α < 0.90)"
  } else if (cronbach_alpha >= 0.70) {
    "Kabul edilebilir güvenirlik (0.70 ≤ α < 0.80)"
  } else if (cronbach_alpha >= 0.60) {
    "Sorgulanabilir güvenirlik (0.60 ≤ α < 0.70)"
  } else {
    "Kabul edilemez güvenirlik (α < 0.60)"
  }

  doc <- doc %>%
    officer::body_add_par(paste("Yorum:", reliability_comment), style = "Normal") %>%
    officer::body_add_par("", style = "Normal")

  # Betimsel istatistikler
  doc <- doc %>%
    officer::body_add_par("Betimsel İstatistikler", style = "heading 2") %>%
    officer::body_add_par("", style = "Normal")

  ft_desc <- flextable::flextable(descriptive_stats)
  ft_desc <- flextable::theme_vanilla(ft_desc)
  ft_desc <- flextable::autofit(ft_desc)
  ft_desc <- flextable::colformat_double(ft_desc, j = "Value", digits = 3)

  doc <- doc %>%
    flextable::body_add_flextable(ft_desc) %>%
    officer::body_add_par("", style = "Normal")

  # Madde istatistikleri özeti
  doc <- doc %>%
    officer::body_add_par("Madde İstatistikleri Özeti", style = "heading 2") %>%
    officer::body_add_par("", style = "Normal")

  # İlk 20 maddeyi göster (sayfa sınırı nedeniyle)
  items_to_show <- min(20, n_items)
  item_stats_subset <- item_statistics[1:items_to_show, ]

  ft_items <- flextable::flextable(item_stats_subset)
  ft_items <- flextable::theme_vanilla(ft_items)
  ft_items <- flextable::fontsize(ft_items, size = 8, part = "all")
  ft_items <- flextable::autofit(ft_items)
  ft_items <- flextable::colformat_double(ft_items,
                                          j = c("Item_Difficulty", "Item_Discrimination_PtBis",
                                               "Item_Discrimination_PtBis_Corrected",
                                               "Mean_Score", "SD", "Alpha_if_Deleted"),
                                          digits = 3)

  doc <- doc %>%
    flextable::body_add_flextable(ft_items) %>%
    officer::body_add_par("", style = "Normal")

  if (n_items > 20) {
    doc <- doc %>%
      officer::body_add_par(sprintf("Not: Sadece ilk %d madde gösterilmektedir. Tüm maddeler için CSV dosyasını inceleyiniz.",
                                   items_to_show),
                           style = "Normal") %>%
      officer::body_add_par("", style = "Normal")
  }

  # Çeldirici etkinlik özeti
  doc <- doc %>%
    officer::body_add_par("Çeldirici Etkinlik Özeti", style = "heading 2") %>%
    officer::body_add_par("", style = "Normal")

  dist_eff_subset <- distractor_effectiveness[1:items_to_show, ]

  ft_dist <- flextable::flextable(dist_eff_subset)
  ft_dist <- flextable::theme_vanilla(ft_dist)
  ft_dist <- flextable::fontsize(ft_dist, size = 8, part = "all")
  ft_dist <- flextable::autofit(ft_dist)
  ft_dist <- flextable::colformat_double(ft_dist,
                                         j = c("Key_Selected_Pct", "Key_PtBis"),
                                         digits = 2)

  doc <- doc %>%
    flextable::body_add_flextable(ft_dist) %>%
    officer::body_add_par("", style = "Normal")

  # Sorunlu maddeler
  doc <- doc %>%
    officer::body_add_par("Sorunlu Maddeler", style = "heading 2") %>%
    officer::body_add_par("", style = "Normal")

  # Negatif ayırt edicilik
  negative_disc_items <- item_statistics[item_statistics$Item_Discrimination_PtBis_Corrected < 0, ]
  if (nrow(negative_disc_items) > 0) {
    doc <- doc %>%
      officer::body_add_par("Negatif Ayırt Ediciliğe Sahip Maddeler:",
                           style = "heading 3")

    ft_neg <- flextable::flextable(negative_disc_items[, c("Item_No", "Item_Difficulty",
                                                            "Item_Discrimination_PtBis_Corrected")])
    ft_neg <- flextable::theme_vanilla(ft_neg)
    ft_neg <- flextable::autofit(ft_neg)

    doc <- doc %>%
      flextable::body_add_flextable(ft_neg) %>%
      officer::body_add_par("Bu maddeler testten çıkarılmalı veya yeniden yazılmalıdır.",
                           style = "Normal") %>%
      officer::body_add_par("", style = "Normal")
  } else {
    doc <- doc %>%
      officer::body_add_par("Negatif ayırt ediciliğe sahip madde bulunmamaktadır. ✓",
                           style = "Normal") %>%
      officer::body_add_par("", style = "Normal")
  }

  # Çok zor maddeler
  very_hard_items <- item_statistics[item_statistics$Item_Difficulty < 0.20, ]
  if (nrow(very_hard_items) > 0) {
    doc <- doc %>%
      officer::body_add_par(sprintf("Çok Zor Maddeler (p < 0.20): %d madde",
                                   nrow(very_hard_items)),
                           style = "heading 3")

    ft_hard <- flextable::flextable(very_hard_items[, c("Item_No", "Item_Difficulty",
                                                         "Item_Discrimination_PtBis_Corrected")])
    ft_hard <- flextable::theme_vanilla(ft_hard)
    ft_hard <- flextable::autofit(ft_hard)

    doc <- doc %>%
      flextable::body_add_flextable(ft_hard) %>%
      officer::body_add_par("", style = "Normal")
  }

  # Çok kolay maddeler
  very_easy_items <- item_statistics[item_statistics$Item_Difficulty > 0.80, ]
  if (nrow(very_easy_items) > 0) {
    doc <- doc %>%
      officer::body_add_par(sprintf("Çok Kolay Maddeler (p > 0.80): %d madde",
                                   nrow(very_easy_items)),
                           style = "heading 3")

    ft_easy <- flextable::flextable(very_easy_items[, c("Item_No", "Item_Difficulty",
                                                         "Item_Discrimination_PtBis_Corrected")])
    ft_easy <- flextable::theme_vanilla(ft_easy)
    ft_easy <- flextable::autofit(ft_easy)

    doc <- doc %>%
      flextable::body_add_flextable(ft_easy) %>%
      officer::body_add_par("", style = "Normal")
  }

  # Test kalite skoru
  doc <- doc %>%
    officer::body_add_par("Test Kalite Değerlendirmesi", style = "heading 2") %>%
    officer::body_add_par(sprintf("Test Kalite Skoru: %d/100", quality_score),
                         style = "Normal") %>%
    officer::body_add_par("", style = "Normal")

  quality_comment <- if (quality_score >= 80) {
    "✓ Test yüksek kalitededir ve kullanıma hazırdır."
  } else if (quality_score >= 60) {
    "⚠ Test kabul edilebilir kalitededir. Bazı iyileştirmeler yapılabilir."
  } else if (quality_score >= 40) {
    "⚠ Test orta kalitededir. Önemli revizyonlar gereklidir."
  } else {
    "✗ Test düşük kalitededir. Kapsamlı revizyon gereklidir."
  }

  doc <- doc %>%
    officer::body_add_par(quality_comment, style = "Normal") %>%
    officer::body_add_par("", style = "Normal")

  # Detaylı çeldirici analizi (ilk 5 madde)
  doc <- doc %>%
    officer::body_add_par("Detaylı Çeldirici Analizi (İlk 5 Madde)", style = "heading 2") %>%
    officer::body_add_par("", style = "Normal")

  items_dist_show <- min(5, n_items)
  for (i in 1:items_dist_show) {
    doc <- doc %>%
      officer::body_add_par(sprintf("Madde %d (Doğru Cevap: %s)", i, answer_key[i]),
                           style = "heading 3") %>%
      officer::body_add_par(sprintf("Çeldirici Kalitesi: %s",
                                   distractor_effectiveness$Distractor_Quality[i]),
                           style = "Normal")

    ft_dist_item <- flextable::flextable(distractor_analysis[[i]])
    ft_dist_item <- flextable::theme_vanilla(ft_dist_item)
    ft_dist_item <- flextable::fontsize(ft_dist_item, size = 7, part = "all")
    ft_dist_item <- flextable::autofit(ft_dist_item)
    ft_dist_item <- flextable::colformat_double(ft_dist_item,
                                                j = c("Percentage", "Point_Biserial",
                                                     "Upper_27_Pct", "Middle_46_Pct",
                                                     "Lower_27_Pct", "Discrimination_Index",
                                                     "Mean_Total_Score"),
                                                digits = 2)

    doc <- doc %>%
      flextable::body_add_flextable(ft_dist_item) %>%
      officer::body_add_par("", style = "Normal")
  }

  # Footer
  doc <- doc %>%
    officer::body_add_par("", style = "Normal") %>%
    officer::body_add_par(paste("Rapor Oluşturma Tarihi:", Sys.time()),
                         style = "Normal") %>%
    officer::body_add_par("Bu rapor Klasik Test Kuramı (CTT) prensiplerine göre otomatik olarak oluşturulmuştur.",
                         style = "Normal")

  # Word dosyasını kaydet
  print(doc, target = doc_filename)

  cat(sprintf("    ✓ %s kaydedildi.\n", basename(doc_filename)))
}

cat(sprintf("\nToplam %d Word raporu oluşturuldu.\n", nrow(metadata)))

################################################################################
# SONUÇ MESAJI
################################################################################

cat("\n")
cat("================================================================================\n")
cat("                    ✓ ANALİZ BAŞARIYLA TAMAMLANDI!\n")
cat("================================================================================\n\n")

cat("OLUŞTURULAN RAPORLAR:\n")
cat("  📄 output/item_analysis_report.txt          - Ana madde analizi raporu\n")
cat("  📄 output/recommendations.txt               - Uzman önerileri ve yorumlar\n")
cat(sprintf("  📄 output/*.docx (%d dosya)                  - Word format raporlar\n\n", nrow(metadata)))

cat("OLUŞTURULAN VERİ DOSYALARI (CSV):\n")
cat("  📊 output/item_statistics.csv               - Madde istatistikleri özeti\n")
cat("  📊 output/discrimination_27.csv             - Üçte birlik ayırt edicilik\n")
cat("  📊 output/distractor_effectiveness_summary.csv - Çeldirici etkinlik özeti\n")
cat("  📊 output/descriptive_statistics.csv        - Betimsel istatistikler\n")
cat("  📊 output/scored_data.csv                   - Puanlanmış ham veri\n")
cat("  📊 output/distractor_analysis_item_*.csv    - Madde bazlı çeldirici analizi\n\n")

cat("OLUŞTURULAN GRAFİKLER (PDF):\n")
cat("  📈 output/score_distribution.pdf            - Puan dağılımı histogramı\n")
cat("  📈 output/item_difficulty.pdf               - Madde güçlük indeksleri\n")
cat("  📈 output/item_discrimination.pdf           - Madde ayırt edicilik indeksleri\n")
cat("  📈 output/difficulty_vs_discrimination.pdf  - Güçlük-Ayırt edicilik scatter plot\n")
cat("  📈 output/discrimination_27.pdf             - Üçte birlik ayırt edicilik\n")
cat("  📈 output/item_correlation_matrix.pdf       - Madde korelasyon matrisi\n")
cat("  📈 output/distractor_quality.pdf            - Çeldirici kalite göstergesi\n")
cat("  📈 output/key_selection_rate.pdf            - Doğru cevap seçim oranları\n\n")

cat("GÜVENİRLİK KATSAYILARI:\n")
cat(sprintf("  • Cronbach's Alpha: %.4f", cronbach_alpha))
if (cronbach_alpha >= 0.80) {
  cat(" (Yüksek güvenilirlik ✓)\n")
} else if (cronbach_alpha >= 0.70) {
  cat(" (Kabul edilebilir güvenilirlik)\n")
} else {
  cat(" (Düşük güvenilirlik - revizyon gerekli ⚠)\n")
}
cat(sprintf("  • KR-20: %.4f\n", kr20$KR20))
cat(sprintf("  • Split-Half: %.4f\n\n", split_half$sb))

cat("TEST ÖZETİ:\n")
cat(sprintf("  • Toplam Madde: %d\n", n_items))
cat(sprintf("  • Toplam Öğrenci: %d\n", n_students))
cat(sprintf("  • Ortalama Puan: %.2f / %d\n", mean(total_scores), n_items))
cat(sprintf("  • Standart Sapma: %.2f\n", sd(total_scores)))
cat(sprintf("  • Ortalama Madde Güçlüğü: %.3f\n", mean(item_statistics$Item_Difficulty)))
cat(sprintf("  • Ortalama Ayırt Edicilik: %.3f\n\n",
            mean(item_statistics$Item_Discrimination_PtBis_Corrected, na.rm = TRUE)))

cat("ÇELDİRİCİ ANALİZİ ÖZETİ:\n")
non_func_total <- sum(grepl(",", distractor_effectiveness$Non_Functioning_Distractors) |
                      (!grepl("Yok|N/A", distractor_effectiveness$Non_Functioning_Distractors)))
cat(sprintf("  • İşlev Görmeyen Çeldirici İçeren Madde: %d\n", non_func_total))
quality_summary <- table(distractor_effectiveness$Distractor_Quality)
for (q in names(quality_summary)) {
  cat(sprintf("  • %s Kalitede Çeldirici: %d madde\n", q, quality_summary[q]))
}

cat("\n")
cat("================================================================================\n")
cat("Detaylı sonuçlar için 'output' klasörünü inceleyiniz.\n")
cat("Analiz tarihi: ")
cat(as.character(Sys.time()))
cat("\n")
cat("================================================================================\n")
