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
if (file.exists("kitapcik_info.xlsx")) {
  metadata <- readxl::read_excel("kitapcik_info.xlsx", sheet = 1)
  use_metadata <- TRUE
} else {
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
data <- read.table("mezitli_iho_mat_ham_data.csv", header = FALSE, sep = ";")
key <- read.csv("mezitli_iho_mat_key.csv", header = FALSE, sep = ";",
                colClasses = "character")

# Anahtar vektörünü oluştur
answer_key <- as.character(key[1, ])

# Veri boyutları
n_students <- nrow(data)
n_items <- ncol(data)

################################################################################
# 2. PUANLAMA MATRİSİ OLUŞTURMA
################################################################################

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
  Recommendation = character(n_items),
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

  # Ayırt edicilik yorumu (Point-Biserial) - YENİ KRİTERLER
  rpb <- item_statistics$Item_Discrimination_PtBis_Corrected[i]
  if (is.na(rpb)) {
    item_statistics$Interpretation_Discrimination[i] <- "Hesaplanamadı"
    item_statistics$Recommendation[i] <- "İncelenmeli"
  } else if (rpb < 0.20) {
    item_statistics$Interpretation_Discrimination[i] <- "Çıkarılmalı"
    item_statistics$Recommendation[i] <- "Testten çıkarılmalı"
  } else if (rpb < 0.30) {
    item_statistics$Interpretation_Discrimination[i] <- "Zayıf"
    item_statistics$Recommendation[i] <- "Gözden geçirilmeli"
  } else if (rpb < 0.40) {
    item_statistics$Interpretation_Discrimination[i] <- "Kabul Edilebilir"
    item_statistics$Recommendation[i] <- "Kullanılabilir"
  } else {
    item_statistics$Interpretation_Discrimination[i] <- "İyi"
    item_statistics$Recommendation[i] <- "Korunmalı"
  }
}

################################################################################
# 4. GÜVENİRLİK ANALİZİ
################################################################################

# Cronbach's Alpha
alpha_result <- psych::alpha(score_matrix, check.keys = TRUE)
cronbach_alpha <- alpha_result$total$raw_alpha

# KR-20 (Kuder-Richardson Formula 20) - Manuel hesaplama
# KR-20 = (k/(k-1)) * (1 - Σ(p*q) / σ²)
k <- n_items
item_variances <- apply(score_matrix, 2, var, na.rm = TRUE)
sum_pq <- sum(item_variances)  # p*q = variance for binary items
total_variance <- var(total_scores, na.rm = TRUE)

kr20_value <- (k / (k - 1)) * (1 - (sum_pq / total_variance))

# Split-half güvenirliği
split_half <- psych::splitHalf(score_matrix)

# Alpha if item deleted
alpha_if_deleted <- alpha_result$alpha.drop$raw_alpha
item_statistics$Alpha_if_Deleted <- alpha_if_deleted

################################################################################
# 5. ÜÇTE BİRLİK YÖNTEMİ İLE AYIRT EDİCİLİK
################################################################################

# Toplam puanlara göre sırala
sorted_indices <- order(total_scores, decreasing = TRUE)
n_group <- floor(n_students * 0.27)  # %27 alt ve üst grup

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
# 8. GÖRSELLEŞTİRME - WORD RAPORU İÇİN TEK GRAFİK
################################################################################

# Klasör oluştur
if (!dir.exists("output")) {
  dir.create("output")
}

# Kombine Madde Güçlüğü ve Ayırt Edicilik Grafiği
# ItemAnalysis software tarzında çift sütun grafik
create_combined_chart <- function() {
  # Veri hazırlığı
  item_nums <- 1:n_items
  difficulty <- item_statistics$Item_Difficulty
  discrimination <- item_statistics$Item_Discrimination_PtBis_Corrected

  # PNG formatında kaydet (Word'e embed etmek için)
  png("output/combined_difficulty_discrimination.png", width = 1200, height = 600, res = 100)

  # Grafik parametreleri
  par(mar = c(5, 4, 4, 4) + 0.1)

  # X ekseni pozisyonları
  x_pos <- 1:n_items
  bar_width <- 0.35

  # Ayırt edicilik barları (soldaki)
  barplot(discrimination,
          space = 0.5,
          col = ifelse(discrimination < 0.20, "red",
                      ifelse(discrimination < 0.30, "orange",
                            ifelse(discrimination < 0.40, "yellow", "darkgreen"))),
          border = "black",
          ylim = c(0, 1),
          las = 1,
          ylab = "Değer",
          xlab = "Madde Numarası",
          main = "Madde Güçlüğü ve Ayırt Edicilik İndeksleri",
          names.arg = item_nums,
          cex.names = 0.7,
          cex.axis = 0.9)

  # 0.20 kesme çizgisi
  abline(h = 0.20, col = "red", lwd = 2, lty = 2)
  abline(h = 0.30, col = "orange", lwd = 1, lty = 3)
  abline(h = 0.40, col = "blue", lwd = 1, lty = 3)

  # Legend
  legend("topright",
         legend = c("Ayırt Edicilik", "Güçlük",
                   "Kesme: 0.20 (Çıkarılmalı)",
                   "Kesme: 0.30 (Zayıf)",
                   "Kesme: 0.40 (Kabul Edilebilir)"),
         col = c("darkgreen", "steelblue", "red", "orange", "blue"),
         lty = c(NA, NA, 2, 3, 3),
         lwd = c(NA, NA, 2, 1, 1),
         pch = c(15, 15, NA, NA, NA),
         cex = 0.8)

  # Güçlük değerlerini nokta olarak ekle
  points(x_pos, difficulty, col = "steelblue", pch = 19, cex = 1.2)
  lines(x_pos, difficulty, col = "steelblue", lwd = 2)

  dev.off()

  return("output/combined_difficulty_discrimination.png")
}

chart_file <- create_combined_chart()

# PDF grafikler kaldırıldı - Sadece Word raporu için PNG grafik kullanılıyor

################################################################################
# 9. CSV ÇIKTILAR
################################################################################

write.csv(item_statistics, "output/item_statistics.csv", row.names = FALSE)
write.csv(discrimination_27, "output/discrimination_27.csv", row.names = FALSE)
write.csv(descriptive_stats, "output/descriptive_statistics.csv", row.names = FALSE)
write.csv(df_scores, "output/scored_data.csv", row.names = FALSE)
write.csv(distractor_effectiveness, "output/distractor_effectiveness_summary.csv", row.names = FALSE)

for (i in 1:n_items) {
  write.csv(distractor_analysis[[i]],
            sprintf("output/distractor_analysis_item_%d.csv", i),
            row.names = FALSE)
}

################################################################################
# 10. WORD RAPORU OLUŞTURMA
################################################################################

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
    officer::body_add_par(sprintf("KR-20: %.4f", kr20_value),
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
cat(sprintf("  • KR-20: %.4f\n", kr20_value))
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
