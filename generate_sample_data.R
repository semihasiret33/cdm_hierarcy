################################################################################
# ÖRNEK VERİ OLUŞTURMA SCRIPTI
# Sample Data Generator for CTT Item Analysis
################################################################################

set.seed(12345)  # Tekrar üretilebilirlik için

# Parametreler
n_students <- 100
n_items <- 30
options <- c("A", "B", "C", "D")

# Doğru cevap anahtarı
answer_key <- rep(options, length.out = n_items)

# Öğrenci yetenekleri (normal dağılım, ort=0, sd=1)
student_abilities <- rnorm(n_students, mean = 0, sd = 1)

# Madde güçlük parametreleri (farklı zorluklarda maddeler)
item_difficulties <- c(
  rep(-1.5, 5),   # Çok kolay maddeler
  rep(-0.5, 10),  # Kolay maddeler
  rep(0, 10),     # Orta güçlükte maddeler
  rep(0.5, 3),    # Zor maddeler
  rep(1.5, 2)     # Çok zor maddeler
)

# Madde ayırt edicilik parametreleri
item_discriminations <- c(
  rep(1.5, 20),   # İyi ayırt eden maddeler
  rep(0.8, 5),    # Orta ayırt eden maddeler
  rep(0.3, 3),    # Zayıf ayırt eden maddeler
  rep(-0.2, 2)    # Negatif ayırt eden (sorunlu) maddeler
)

# 2-Parametreli Lojistik Model (2PL) ile yanıt üretimi
generate_response <- function(ability, difficulty, discrimination) {
  prob <- 1 / (1 + exp(-discrimination * (ability - difficulty)))
  return(runif(1) < prob)
}

# Yanıt matrisi oluştur
response_matrix <- matrix("", nrow = n_students, ncol = n_items)

for (i in 1:n_students) {
  for (j in 1:n_items) {
    correct_answer <- answer_key[j]

    # Doğru cevap verme olasılığı
    correct_prob <- generate_response(student_abilities[i],
                                      item_difficulties[j],
                                      item_discriminations[j])

    if (correct_prob) {
      # Doğru cevap ver
      response_matrix[i, j] <- correct_answer
    } else {
      # Yanlış cevap ver (çeldiricilerden birini seç)
      wrong_options <- setdiff(options, correct_answer)
      # Düşük yetenekli öğrenciler belirli çeldiricileri daha çok seçsin
      if (student_abilities[i] < -0.5) {
        # Düşük başarılı öğrenciler için ağırlıklı seçim
        weights <- c(0.5, 0.3, 0.2)
      } else {
        # Diğerleri için eşit olasılık
        weights <- c(1/3, 1/3, 1/3)
      }
      response_matrix[i, j] <- sample(wrong_options, 1, prob = weights)
    }
  }
}

# Bazı maddelere boş yanıt ekle (gerçekçi olması için)
missing_count <- round(n_students * n_items * 0.02)  # %2 boş yanıt
missing_indices <- sample(1:(n_students * n_items), missing_count)
response_matrix[missing_indices] <- ""

# Dosyalara kaydet
write.table(response_matrix, "mezitli_iho_mat_ham_data.csv",
            row.names = FALSE, col.names = FALSE, sep = ";", quote = FALSE)

# Anahtar dosyası
write.table(t(answer_key), "mezitli_iho_mat_key.csv",
            row.names = FALSE, col.names = FALSE, sep = ";", quote = FALSE)

cat("Örnek veriler başarıyla oluşturuldu!\n")
cat(sprintf("  - mezitli_iho_mat_ham_data.csv (%d öğrenci, %d madde)\n",
            n_students, n_items))
cat(sprintf("  - mezitli_iho_mat_key.csv (%d madde)\n", n_items))
cat("\nŞimdi ana analiz scriptini çalıştırabilirsiniz:\n")
cat("  source('ctt_item_analysis.R')\n")
