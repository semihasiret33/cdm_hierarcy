# Klasik Test Kuramı (CTT) Madde Analizi
## Classical Test Theory Item Analysis

[![R](https://img.shields.io/badge/R-Programming-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Profesyonel seviyede, kapsamlı Klasik Test Kuramı madde analizi R scripti. Eğitim ölçme ve değerlendirme uzmanları için hazırlanmıştır.

*Professional-grade comprehensive Classical Test Theory item analysis R script. Prepared for educational measurement and assessment specialists.*

---

## 📋 İçindekiler / Table of Contents

- [Özellikler / Features](#özellikler--features)
- [Kurulum / Installation](#kurulum--installation)
- [Kullanım / Usage](#kullanım--usage)
- [Veri Formatı / Data Format](#veri-formatı--data-format)
- [Çıktılar / Outputs](#çıktılar--outputs)
- [Analizler / Analyses](#analizler--analyses)
- [Yorumlama Kriterleri / Interpretation Criteria](#yorumlama-kriterleri--interpretation-criteria)

---

## 🎯 Özellikler / Features

### Madde İstatistikleri / Item Statistics
- ✅ **Madde Güçlüğü İndeksi** (p-değeri) - Item Difficulty Index
- ✅ **Point-Biserial Korelasyon** - Madde ayırt ediciliği
- ✅ **Düzeltilmiş Madde-Toplam Korelasyonu** - Corrected Item-Total Correlation
- ✅ **Üçte Birlik Yöntemi** ile Ayırt Edicilik - Upper-Lower 27% Discrimination
- ✅ **Alpha if Item Deleted** - Madde çıkarıldığında güvenirlik

### Güvenirlik Analizleri / Reliability Analyses
- ✅ **Cronbach's Alpha** - İç tutarlılık katsayısı
- ✅ **KR-20** (Kuder-Richardson Formula 20) - Dikotom puanlama için
- ✅ **Split-Half Güvenirliği** - Spearman-Brown düzeltmesi ile

### Detaylı Çeldirici Analizi / Detailed Distractor Analysis
- ✅ **Seçenek Frekansları ve Yüzdeleri** - Option frequencies and percentages
- ✅ **Point-Biserial Korelasyon** her seçenek için
- ✅ **Üst %27, Orta %46, Alt %27** grup analizleri
- ✅ **Çeldirici Etkinlik Değerlendirmesi** - Distractor effectiveness rating
- ✅ **İşlev Görmeyen Çeldirici Tespiti** (<5% seçilme)
- ✅ **Seçeneği Seçenlerin Ortalama Puanı** - Mean score of option selectors
- ✅ **Çeldirici Ayırt Edicilik İndeksi** - Distractor discrimination index

### Görselleştirme / Visualizations
- 📊 Puan dağılımı histogramı
- 📊 Madde güçlük indeksleri grafiği
- 📊 Madde ayırt edicilik grafiği
- 📊 Güçlük vs. Ayırt edicilik scatter plot
- 📊 Madde korelasyon matrisi
- 📊 Çeldirici kalite göstergesi
- 📊 Doğru cevap seçim oranları

### Raporlama / Reporting
- 📄 Kapsamlı metin raporu (Türkçe)
- 📄 Uzman önerileri ve yorumlar
- 📄 **Word formatında profesyonel raporlar** (officer paketi ile) ⭐
- 📊 CSV formatında tüm istatistikler
- 📈 Yüksek kaliteli PDF grafikler
- 🔄 **Çoklu kitapçık desteği** (metadata.xlsx ile)

---

## 🔧 Kurulum / Installation

### Gereksinimler / Requirements

R (versiyon ≥ 4.0.0) ve aşağıdaki R paketleri:

```r
# Gerekli paketler / Required packages
install.packages(c(
  "ItemAnalysis",  # Madde analizi / Item analysis
  "psych",         # Psikolojik ölçüm / Psychological measurement
  "ggplot2",       # Görselleştirme / Visualization
  "reshape2",      # Veri dönüşümü / Data transformation
  "gridExtra",     # Grafik düzenleme / Plot arrangement
  "corrplot",      # Korelasyon grafikleri / Correlation plots
  "knitr",         # Rapor oluşturma / Report generation
  "dplyr",         # Veri manipülasyonu / Data manipulation
  "tidyr",         # Veri temizleme / Data tidying
  "CTT",           # Klasik Test Kuramı / Classical Test Theory
  "officer",       # Word belgeleri / Word documents
  "flextable",     # Tablo formatları / Table formatting
  "readxl",        # Excel okuma / Excel reading
  "openxlsx"       # Excel yazma / Excel writing
))
```

**Not:** Script, eksik paketleri otomatik olarak yüklemeye çalışacaktır.

---

## 📖 Kullanım / Usage

### 1. Hızlı Başlangıç / Quick Start

#### Örnek Veri ile Test Etme / Testing with Sample Data

```r
# Örnek veri oluştur / Generate sample data
source("generate_sample_data.R")

# Analizi çalıştır / Run analysis
source("ctt_item_analysis.R")
```

#### Kendi Verinizle / With Your Own Data

```r
# Veri dosyalarınızın adını değiştirin veya script içinde düzenleyin
# Rename your data files or edit the script

# Analizi çalıştır / Run analysis
source("ctt_item_analysis.R")
```

### 2. RStudio'da Kullanım

1. Projeyi RStudio'da açın
2. `ctt_item_analysis.R` dosyasını açın
3. **Source** butonuna tıklayın veya `Ctrl+Shift+S` tuşlarına basın
4. Analiz otomatik olarak çalışacak ve sonuçlar `output/` klasöründe oluşacaktır

---

## 📁 Veri Formatı / Data Format

### Ham Veri Dosyası (mezitli_iho_mat_ham_data.csv)

- **Format:** CSV dosyası (noktalı virgülle ayrılmış)
- **Satırlar:** Her satır bir öğrenciyi temsil eder
- **Sütunlar:** Her sütun bir test maddesini temsil eder
- **Değerler:** Öğrencinin verdiği cevap (A, B, C, D, E vb.)
- **Başlık:** Başlık satırı OLMAMALI (header = FALSE)

**Örnek:**
```
A;B;C;D;A;B;C;D;A;B
C;D;A;B;C;D;A;B;C;D
A;A;A;A;B;B;B;B;C;C
...
```

### Anahtar Dosyası (mezitli_iho_mat_key.csv)

- **Format:** CSV dosyası (noktalı virgülle ayrılmış)
- **İçerik:** Tek satır, her maddenin doğru cevabı
- **Başlık:** Başlık satırı OLMAMALI (header = FALSE)

**Örnek:**
```
A;B;C;D;A;B;C;D;A;B
```

### Metadata Dosyası (metadata.xlsx) - OPSİYONEL

- **Format:** Excel dosyası (.xlsx)
- **Sayfa:** Sayfa1 (veya ilk sayfa)
- **Sütunlar:** Program, alan, kitapcik, beceri, TemelEgit, Turkce, Sorguulama
- **Her satır:** Bir test kitapçığını temsil eder

**Örnek:**

| Program | alan | kitapcik | beceri | TemelEgit | Turkce | Sorguulama |
|---------|------|----------|--------|-----------|--------|------------|
| TemelEgit | Turkce | A | Okuma | Evet | Evet | 1 |
| TemelEgit | Matematik | B | Sayilar | Evet | Hayir | 1 |
| Ortaokul | Matematik | A | Cebir | Hayir | Hayir | 2 |

**Dosya Adı Oluşturma:**
Word raporları için dosya adı şu formatta oluşturulur:
```
Program_alan_Kitapcik_X_beceri_TemelEgit_Turkce_Sorgulama_N.docx
```

**Örnek:**
```
TemelEgit_Turkce_Kitapcik_A_Okuma_Evet_Evet_Sorgulama_1.docx
```

---

## 📊 Çıktılar / Outputs

Tüm çıktılar `output/` klasöründe oluşturulur:

### Rapor Dosyaları / Report Files

| Dosya | Açıklama |
|-------|----------|
| `item_analysis_report.txt` | Kapsamlı madde analizi raporu (Türkçe) |
| `recommendations.txt` | Uzman önerileri ve test kalite değerlendirmesi |
| `*.docx` | Word formatında profesyonel raporlar (her kitapçık için) ⭐ |

### Veri Dosyaları / Data Files (CSV)

| Dosya | İçerik |
|-------|--------|
| `item_statistics.csv` | Madde istatistikleri özeti |
| `discrimination_27.csv` | Üçte birlik ayırt edicilik analizi |
| `distractor_effectiveness_summary.csv` | Çeldirici etkinlik özeti |
| `descriptive_statistics.csv` | Betimsel istatistikler |
| `scored_data.csv` | 0-1 olarak puanlanmış ham veri |
| `distractor_analysis_item_*.csv` | Her madde için detaylı çeldirici analizi |

### Grafik Dosyaları / Graphic Files (PDF)

| Dosya | Grafik |
|-------|--------|
| `score_distribution.pdf` | Toplam puan dağılımı histogramı |
| `item_difficulty.pdf` | Madde güçlük indeksleri |
| `item_discrimination.pdf` | Madde ayırt edicilik indeksleri |
| `difficulty_vs_discrimination.pdf` | Güçlük-Ayırt edicilik scatter plot |
| `discrimination_27.pdf` | Üçte birlik ayırt edicilik |
| `item_correlation_matrix.pdf` | Madde korelasyon matrisi |
| `distractor_quality.pdf` | Çeldirici kalite göstergesi |
| `key_selection_rate.pdf` | Doğru cevap seçim oranları |

---

## 🔍 Analizler / Analyses

### 1. Madde Güçlüğü (Item Difficulty)

**Formül:** p = (Doğru cevap veren sayısı) / (Toplam öğrenci sayısı)

- Değer aralığı: 0.00 - 1.00
- Yüksek değer = kolay madde
- Düşük değer = zor madde

### 2. Madde Ayırt Ediciliği (Item Discrimination)

**Point-Biserial Korelasyon:**
- Madde puanı ile toplam test puanı arasındaki korelasyon
- Değer aralığı: -1.00 - +1.00
- Yüksek pozitif değer = iyi ayırt edicilik

**Düzeltilmiş Point-Biserial:**
- Madde puanı toplam puandan çıkarılarak hesaplanır
- Daha konservatif bir tahmin

**Üçte Birlik Yöntemi:**
- Üst %27 - Alt %27 doğru cevap yüzdesi farkı
- Klasik yöntem, yorumlaması kolay

### 3. Güvenirlik (Reliability)

**Cronbach's Alpha:**
- İç tutarlılık katsayısı
- Maddelerin homojenliğini ölçer

**KR-20:**
- Dikotom puanlanan maddeler için özel formül
- Cronbach's Alpha'nın özel hali

**Split-Half:**
- Testi ikiye bölerek hesaplanan güvenirlik
- Spearman-Brown formülü ile düzeltilir

### 4. Çeldirici Analizi (Distractor Analysis)

Her seçenek için:
- **Seçilme Frekansı ve Yüzdesi**
- **Point-Biserial Korelasyon** (negatif olmalı)
- **Üst-Orta-Alt Grup Dağılımı**
- **Ayırt Edicilik İndeksi**
- **Seçeneği Seçenlerin Ortalama Puanı**
- **Etkinlik Değerlendirmesi**

**İyi Çeldirici:**
- En az %5 oranında seçilir
- Negatif point-biserial korelasyona sahiptir
- Alt grup üst gruptan daha fazla seçer

**Sorunlu Çeldirici:**
- %5'ten az seçilir (işlev görmüyor)
- Pozitif point-biserial korelasyon (yüksek başarılı öğrenciler seçiyor)

---

## 📐 Yorumlama Kriterleri / Interpretation Criteria

### Madde Güçlüğü / Item Difficulty

| p değeri | Yorum |
|----------|-------|
| p < 0.20 | Çok Zor |
| 0.20 ≤ p < 0.40 | Zor |
| 0.40 ≤ p < 0.60 | Orta (İdeal) |
| 0.60 ≤ p < 0.80 | Kolay |
| p ≥ 0.80 | Çok Kolay |

### Madde Ayırt Ediciliği / Item Discrimination

#### Point-Biserial Korelasyon

| r değeri | Yorum | Öneri |
|----------|-------|-------|
| r < 0.00 | Negatif | Çıkarılmalı veya düzeltilmeli |
| 0.00 ≤ r < 0.20 | Zayıf | Gözden geçirilmeli |
| 0.20 ≤ r < 0.30 | Kabul Edilebilir | Kullanılabilir |
| 0.30 ≤ r < 0.40 | İyi | Korunmalı |
| r ≥ 0.40 | Çok İyi | Mükemmel madde |

#### Üçte Birlik Yöntemi

| D değeri | Yorum |
|----------|-------|
| D < 0.00 | Negatif (Sorunlu) |
| 0.00 ≤ D < 0.20 | Zayıf |
| 0.20 ≤ D < 0.30 | Kabul Edilebilir |
| 0.30 ≤ D < 0.40 | İyi |
| D ≥ 0.40 | Mükemmel |

### Güvenirlik / Reliability

| α değeri | Yorum |
|----------|-------|
| α < 0.60 | Kabul Edilemez |
| 0.60 ≤ α < 0.70 | Sorgulanabilir |
| 0.70 ≤ α < 0.80 | Kabul Edilebilir |
| 0.80 ≤ α < 0.90 | İyi |
| α ≥ 0.90 | Mükemmel |

### Çeldirici Etkinliği / Distractor Effectiveness

**Doğru Cevap için:**
- Point-biserial ≥ 0.30 ve Seçilme ≥ 40% → Mükemmel
- Point-biserial ≥ 0.20 ve Seçilme ≥ 30% → İyi
- Point-biserial ≥ 0.10 ve Seçilme ≥ 20% → Kabul Edilebilir
- Diğer → Zayıf

**Çeldirici için:**
- Seçilme < 5% → İşlev Görmüyor
- Point-biserial < 0 ve Alt grup > Üst grup → Çok İyi
- Point-biserial < 0 → İyi
- Point-biserial < 0.10 → Kabul Edilebilir
- Point-biserial > 0.10 → Sorunlu

---

## 📚 Kaynaklar / References

1. **Crocker, L., & Algina, J.** (2008). *Introduction to classical and modern test theory*. Mason, OH: Cengage Learning.

2. **Haladyna, T. M., & Rodriguez, M. C.** (2013). *Developing and validating test items*. New York, NY: Routledge.

3. **Allen, M. J., & Yen, W. M.** (2001). *Introduction to measurement theory*. Long Grove, IL: Waveland Press.

4. **Ebel, R. L., & Frisbie, D. A.** (1991). *Essentials of educational measurement* (5th ed.). Englewood Cliffs, NJ: Prentice Hall.

5. **Guilford, J. P., & Fruchter, B.** (1978). *Fundamental statistics in psychology and education* (6th ed.). New York: McGraw-Hill.

---

## 🤝 Katkıda Bulunma / Contributing

Bu proje açık kaynak bir eğitim aracıdır. Katkılarınızı bekliyoruz!

- Hata bildirimleri için GitHub Issues kullanın
- Geliştirme önerileri için Pull Request gönderin
- Sorularınız için tartışma başlatın

---

## 📝 Lisans / License

Bu proje MIT lisansı altında sunulmaktadır.

---

## 👥 Yazar / Author

**Profesyonel Ölçme ve Değerlendirme Uzmanı**
Eğitim Bilimleri - Ölçme ve Değerlendirme

---

## 📞 İletişim / Contact

Sorularınız veya önerileriniz için:
- GitHub Issues bölümünü kullanabilirsiniz
- Projeyi fork'layıp geliştirmelerinizi paylaşabilirsiniz

---

## 🙏 Teşekkürler / Acknowledgments

Bu script, eğitim ölçme ve değerlendirme alanındaki araştırmacılar ve uygulamacılar için hazırlanmıştır. Klasik Test Kuramı'nın temel prensiplerini ve en iyi uygulamalarını yansıtmaktadır.

---

## ⚠️ Önemli Notlar / Important Notes

1. **Veri Gizliliği:** Öğrenci verilerini kullanırken etik kurallara ve gizlilik politikalarına uyunuz.

2. **Yeterli Örneklem:** Güvenilir sonuçlar için en az 100 öğrenci önerilir (madde sayısının 3-5 katı).

3. **Madde Sayısı:** En az 20 madde, ideal olarak 30+ madde önerilir.

4. **Yorumlama:** Sonuçları bağlam içinde yorumlayın. Sayısal kriterler kesin sınırlar değildir.

5. **Çoktan Seçmeli:** Bu script çoktan seçmeli testler için optimize edilmiştir.

---

## 📈 Versiyon Geçmişi / Version History

### v1.0.0 (2025-12-16)
- İlk sürüm yayınlandı
- Temel madde analizi özellikleri
- Detaylı çeldirici analizi
- Kapsamlı görselleştirmeler
- Türkçe ve İngilizce dokümantasyon

---

**Başarılar dileriz! / Good luck with your analyses!** 🎓📊
