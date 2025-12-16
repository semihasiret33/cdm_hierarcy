################################################################################
# METADATA EXCEL DOSYASI OLUŞTURMA
# Sample Metadata Excel File Generator
################################################################################

# Bu script metadata.xlsx dosyası oluşturur
# Excel'de düzenlenebilir örnek metadata tablosu

library(openxlsx)

# Örnek metadata tablosu
metadata <- data.frame(
  Program = c("TemelEgit", "TemelEgit", "Ortaokul"),
  alan = c("Turkce", "Matematik", "Matematik"),
  kitapcik = c("A", "B", "A"),
  beceri = c("Okuma", "Sayilar", "Cebir"),
  TemelEgit = c("Evet", "Evet", "Hayir"),
  Turkce = c("Evet", "Hayir", "Hayir"),
  Sorguulama = c(1, 1, 2),
  stringsAsFactors = FALSE
)

# Excel dosyası oluştur
wb <- createWorkbook()
addWorksheet(wb, "Sayfa1")
writeData(wb, "Sayfa1", metadata)

# Başlıkları kalın yap
addStyle(wb, "Sayfa1",
         style = createStyle(textDecoration = "bold"),
         rows = 1, cols = 1:ncol(metadata), gridExpand = TRUE)

# Sütun genişliklerini ayarla
setColWidths(wb, "Sayfa1", cols = 1:ncol(metadata), widths = "auto")

# Kaydet
saveWorkbook(wb, "metadata.xlsx", overwrite = TRUE)

cat("\n✓ metadata.xlsx dosyası oluşturuldu!\n\n")
cat("Bu dosyayı Excel'de açıp kendi verilerinize göre düzenleyebilirsiniz.\n\n")

cat("Sütun Açıklamaları:\n")
cat("  - Program: Eğitim programı (ör: TemelEgit, Ortaokul)\n")
cat("  - alan: Test alanı (ör: Turkce, Matematik)\n")
cat("  - kitapcik: Kitapçık formu (ör: A, B, C)\n")
cat("  - beceri: Ölçülen beceri (ör: Okuma, Sayilar)\n")
cat("  - TemelEgit: Temel eğitim durumu (Evet/Hayir)\n")
cat("  - Turkce: Türkçe testi mi? (Evet/Hayir)\n")
cat("  - Sorguulama: Sorgulama seviyesi (1, 2, 3, ...)\n\n")

cat("Not: Her satır bir test kitapçığını temsil eder.\n")
cat("     Dosya adları bu bilgilerden otomatik oluşturulacaktır.\n\n")

print(metadata)
