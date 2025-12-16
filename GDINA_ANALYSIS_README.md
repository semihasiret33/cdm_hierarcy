# GDINA Bilişsel Tanı Modeli Analizi

Bu klasörde GDINA (Generalized Deterministic Input, Noisy "And" gate) modelini kullanarak bilişsel tanı modeli (Cognitive Diagnostic Model - CDM) analizleri için kapsamlı R scriptleri bulunmaktadır.

## 📋 İçerik

1. **gdina_cognitive_analysis.R** - Ana analiz scripti (iki örnek dataset ile)
2. **gdina_real_data_template.R** - Kendi verinizle analiz yapmak için şablon
3. **GDINA_ANALYSIS_README.md** - Bu dosya

## 🎯 Ana Analiz Scripti

### Özellikler

**Dataset 1: Okuma Anlama**
- 500 öğrenci, 20 madde
- 5 bilişsel özellik (Vocabulary, Main Idea, Inference, Structure, Critical Thinking)
- GDINA veri simülasyonu

**Dataset 2: Matematik**
- 400 öğrenci, 19 madde
- 4 bilişsel özellik (Basic Operations, Fractions, Problem Solving, Algebra)
- DINA veri simülasyonu

### Yapılan Analizler

1. **Model Tahminleme**
   - GDINA (Genel Model)
   - DINA (Deterministic Input, Noisy And)
   - DINO (Deterministic Input, Noisy Or)
   - ACDM (Additive CDM)
   - LLM (Linear Logistic Model)
   - RRUM (Reduced RUM)

2. **Model Karşılaştırma**
   - AIC, BIC, CAIC, SABIC kriterleri
   - Likelihood Ratio Test
   - Parametre sayısı karşılaştırması

3. **Q-Matrix Validation**
   - Hull Method
   - MLR-B Method
   - QRR, USR, OSR metrikleri

4. **Diagnostic Analizler**
   - Item fit analysis
   - Person fit analysis
   - Attribute classification accuracy
   - Sensitivity ve Specificity

5. **Görselleştirmeler**
   - Q-matrix heatmaps
   - Model comparison plots
   - Attribute mastery profiles
   - Guess-Slip parameter plots

## 🚀 Kullanım

### Gerekli Paketler

```r
install.packages(c("GDINA", "Qval", "CDM", "lattice", "ggplot2", "reshape2", "knitr"))
```

### Ana Scripti Çalıştırma

```r
source("gdina_cognitive_analysis.R")
```

Script otomatik olarak:
- Gerekli paketleri yükler
- İki dataset simüle eder
- Tüm analizleri yapar
- Grafikleri `gdina_outputs/` klasörüne kaydeder
- Workspace'i kaydeder

### Çıktılar

Tüm çıktılar `gdina_outputs/` klasöründe:

**Grafikler (PDF):**
- `dataset1_qmatrix_heatmap.pdf`
- `dataset1_model_comparison.pdf`
- `dataset1_attribute_mastery.pdf`
- `dataset2_qmatrix_heatmap.pdf`
- `dataset2_model_comparison.pdf`
- `dataset2_attribute_mastery.pdf`
- `dataset2_guess_slip.pdf`

**Workspace:**
- `gdina_analysis_workspace.RData` - Tüm analizler ve sonuçlar

## 📊 Kendi Verinizle Analiz

### Veri Formatı

**1. Yanıt Verisi (Response Data)**
- Binary format (1 = doğru, 0 = yanlış)
- Satırlar: Öğrenciler
- Sütunlar: Maddeler
- Format: matrix veya data.frame

Örnek:
```r
data <- matrix(c(
  1, 0, 1, 1, 0,  # Öğrenci 1
  1, 1, 1, 0, 1,  # Öğrenci 2
  0, 0, 1, 1, 0   # Öğrenci 3
), nrow = 3, byrow = TRUE)
```

**2. Q-Matrix**
- Binary format (1 = özellik gerekli, 0 = gerekli değil)
- Satırlar: Maddeler
- Sütunlar: Bilişsel özellikler

Örnek:
```r
Q <- matrix(c(
  1, 0, 0,  # Item 1: Sadece Özellik 1
  1, 1, 0,  # Item 2: Özellik 1 ve 2
  0, 1, 1,  # Item 3: Özellik 2 ve 3
  1, 1, 1,  # Item 4: Tüm özellikler
  0, 0, 1   # Item 5: Sadece Özellik 3
), ncol = 3, byrow = TRUE)

colnames(Q) <- c("Attr1", "Attr2", "Attr3")
```

### Şablon Script Kullanımı

```r
# 1. Şablon scripti düzenleyin
source("gdina_real_data_template.R")

# 2. Kendi verilerinizi yükleyin
# Script içinde data ve Q-matrix bölümlerini düzenleyin

# 3. Analizi çalıştırın
```

## 📈 Sonuçları Yorumlama

### Model Seçimi

**BIC (Bayesian Information Criterion):**
- Daha düşük = daha iyi
- Model karmaşıklığını cezalandırır
- Genellikle tercih edilen kriter

**AIC (Akaike Information Criterion):**
- Daha düşük = daha iyi
- BIC'den daha az cezalandırıcı

### Q-Matrix Validation Metrikleri

**QRR (Q-matrix Recovery Rate):**
- Orijinal Q-matrix'in doğru tespit edilme oranı
- Yüksek değer (>0.90) = iyi

**USR (Underspecification Rate):**
- Eksik belirtilmiş q-girdilerinin oranı
- Düşük değer = iyi

**OSR (Overspecification Rate):**
- Fazla belirtilmiş q-girdilerinin oranı
- Düşük değer = iyi

### Item Fit

- p < 0.05: Madde model ile uyumsuz
- Uyumsuz maddeler gözden geçirilmeli
- Q-matrix yanlış belirtilmiş olabilir

### Person Fit

- |lz| > 2: Aberrant response pattern
- Bu öğrenciler daha fazla incelenmeli
- Tesadüfi yanıtlama veya kopya olabilir

### Classification Accuracy

- **Accuracy:** Genel doğru sınıflandırma oranı
- **Sensitivity:** Gerçekten master olan öğrencileri doğru tespit etme
- **Specificity:** Gerçekten non-master olan öğrencileri doğru tespit etme

> 0.80+ = Mükemmel
> 0.70-0.80 = İyi
> 0.60-0.70 = Kabul edilebilir
> <0.60 = Zayıf

## 🔍 CDM Model Karşılaştırması

### GDINA (General)
- En esnek model
- Tüm etkileşimlere izin verir
- Çok parametre gerektirir

### DINA
- En kısıtlayıcı model
- Tüm özelliklere sahip olma gerektirir
- 2 parametre/madde (guess, slip)

### DINO
- DINA'nın tersi
- Herhangi bir özelliğe sahip olma yeterli
- 2 parametre/madde

### ACDM
- Özellikler toplamsal etki yapar
- Orta düzey esneklik
- k+1 parametre (k = özellik sayısı)

### LLM
- Logit ölçekte lineer model
- ACDM'ye benzer
- k+1 parametre

### RRUM
- Başarısızlık olasılıklarını çarpımsal modeller
- Orta düzey kısıtlayıcı
- k+1 parametre

## 📚 Kaynaklar

### Temel Makaleler

1. **de la Torre, J. (2011).** The generalized DINA model framework. *Psychometrika, 76*, 179-199.

2. **Haertel, E. H. (1989).** Using restricted latent class models to map the skill structure of achievement items. *Journal of Educational Measurement, 26*, 333-352.

3. **Ma, W., & de la Torre, J. (2020).** GDINA: An R Package for Cognitive Diagnosis Modeling. *Journal of Statistical Software, 93*(14), 1-26.

4. **Ravand, H., & Robitzsch, A. (2018).** Cognitive diagnostic model of best choice: A study of reading comprehension. *Educational Psychology, 38*, 1255-1277.

### Paket Dokümantasyonu

- [GDINA Package](https://CRAN.R-project.org/package=GDINA)
- [Qval Package](https://CRAN.R-project.org/package=Qval)
- [CDM Package](https://CRAN.R-project.org/package=CDM)

## ⚠️ Önemli Notlar

1. **Sample Size:**
   - Minimum 200-300 öğrenci önerilir
   - Daha fazla özellik = daha fazla öğrenci gerekli

2. **Q-Matrix:**
   - Q-matrix tasarımı kritik öneme sahiptir
   - Uzman görüşü alınmalı
   - Empirical validation yapılmalı

3. **Model Selection:**
   - Birden fazla kriteri birlikte değerlendirin
   - Teorik gerekçelendirme önemli
   - Parsimony ilkesini göz önünde bulundurun

4. **Convergence:**
   - Model yakınsama sorunlarında maxitr artırın
   - Farklı başlangıç değerleri deneyin
   - Daha basit modelle başlayın

## 💡 İpuçları

1. **İlk Analiz:**
   - Simulated data ile başlayın
   - Scriptlerin nasıl çalıştığını öğrenin
   - Çıktıları inceleyin

2. **Gerçek Veri:**
   - Veri formatınızı kontrol edin
   - Eksik verileri ele alın
   - Q-matrix'i dikkatlice tasarlayın

3. **Hata Ayıklama:**
   - Convergence hatası: maxitr artırın
   - Memory hatası: daha az model tahminleyin
   - Q-matrix hatası: rank kontrolü yapın

## 📧 Yardım

Sorularınız için:
- GDINA vignette: `vignette("GDINA")`
- R help: `?GDINA::GDINA`
- Online forum: [Stack Overflow](https://stackoverflow.com/questions/tagged/r)

---

**Son Güncelleme:** 2024
**Versiyon:** 1.0
