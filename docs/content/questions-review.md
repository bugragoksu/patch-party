# Soru Havuzu: Gözden Geçirme

- Model: `gemini-flash-latest` · Üretim: 2026-10-22T21:49:03.933Z · Toplam 269 soru
- İnsan incelemesi: 2026-10-24 · `"reviewed": true`
- Eksik (2'den az soru) ikililer: yok · `general`: 35 soru
- Uygunsuz ya da zayıf bir soruyu `app/assets/content/questions.json` içinden silin; her ikilide en az 2 soru kalmalı.

## İnceleme özeti

269 sorudan **92'si yeniden yazıldı**, 177'si olduğu gibi kaldı. Havuz anahtarları ve havuz boyutları değişmedi; hiçbir soru silinmedi, kurtarılamayanların yerine aynı havuz için yeni soru yazıldı. Bütün sorular 110 karakterin altında.

Bulunan hata türleri:

- **Bağlamı eksik, tek okumada anlaşılmıyor.** Kimin, neyin, neden olduğu cümleden çıkmıyor ("Güvenlik uyarısını kimse okumadığı için…", "istemci ile sunucu arasında yaşanan tartışma").
- **Anlamca yanlış ya da çelişkili.** "Yanıtların hızını hissettirmemek" (yavaşlığı olmalı), "sayfa yükleme hızını düşürerek dönüşümü artırmak", "animasyonun sunucuya getirdiği yük".
- **Çeviri kokan kalıplar.** "O ilk an", "o gizli hazine repo", "modele beslemek", "ürün değerine dönüştürmek", "büyümenin en kritik anahtarı", "en uykusuz gece nöbeti vermek", "çevrimdışı çalışma senaryosu".
- **Evet/hayır soruları.** "…oldu mu?", "…var mı?" ile biten sorular açık uçluya çevrildi.
- **Dil bilgisi ve sözcük seçimi.** Eksik özne/nesne ("pes etme noktasına getiren"), edilgen ve kişisiz yapılar ("karşılaşılan", "yaşanan"), uyumsuz eşdizimler ("yanlış bildiği algı", "issue başlığını çözmek", "teknik borcu feda etmek"), yazım ("dökümantasyon", "yapay zeka").
- **Herkesin yaşamadığı çok özel varsayımlar.** Gerektiğinde "siz olsanız…" ya da gözleme dayalı ("gördüğünüz en…") biçime çevrildi.

## Önce / sonra örnekleri

| Havuz | Önce | Sonra |
|---|---|---|
| design\|security | Güvenlik uyarısını kimse okumadığı için tasarımını tamamen değiştirdiğiniz bir ekran oldu mu? | Kullanıcılar güvenlik uyarılarını okumadan geçiyor; sizce onlara nasıl okutabiliriz? |
| ai\|web | Frontend uygulamasında yapay zekâ yanıtlarının hızını hissettirmemek için bulduğunuz en iyi numara neydi? | Yapay zekâ yanıtı yavaş gelirken kullanıcıya beklemeyi hissettirmemek için bulduğunuz en iyi numara ne? |
| design\|devops | Kullanıcı deneyimini uçuran bir animasyonun sunucuya getirdiği yük yüzünden yaşanan kriz neydi? | Tasarımın canlıda Figma'dakinden farklı göründüğü en tuhaf durum neydi? |
| backend\|web | REST veya GraphQL tercihi yaparken istemci ile sunucu arasında yaşanan en hararetli tartışma neydi? | REST mi GraphQL mi tartışmasında hangi taraftasınız, neden? |
| ai\|opensource | Hugging Face veya GitHub'da bulup projelerinizin seyrini değiştiren o gizli hazine repo neydi? | Hugging Face ya da GitHub'da keşfedip projelerinizi değiştiren, az bilinen bir repo hangisi? |
| ai\|data | Kirli veriyi temizlemeden modele beslediğinizde ortaya çıkan en komik veya öğretici sonuç neydi? | Temizlemediğiniz bir veriyi modele verdiğinizde çıkan en komik ya da öğretici sonuç neydi? |
| product\|web | Bir e-ticaret akışında sayfa yükleme hızını düşürerek dönüşümü doğrudan artıran bir optimizasyonunuz oldu mu? | Sayfayı hızlandırmanın satışları ya da dönüşümü artırdığını gördüğünüz bir örnek neydi? |
| community\|opensource | Bir depoya gelen en kaotik issue başlığını çözmek için toplulukla nasıl iletişim kurdunuz? | Bir projeye gelen en kaotik issue'yu toplulukla birlikte nasıl çözdünüz? |
| backend\|product | MVP çıkarırken sunucu mimarisinde feda etmek zorunda kaldığınız en kritik teknik borç neydi? | MVP'yi yetiştirmek için backend'de bilerek bıraktığınız en büyük teknik borç neydi? |
| opensource\|product | Geliştirici ekosisteminde hızla güven kazanıp büyümenin açık kaynaktaki en kritik anahtarı nedir? | Açık kaynak bir proje geliştiricilerin güvenini nasıl kazanır? |
| design\|design | İçinize çok sinen ama kullanıcı testinde tamamen çuvallayan bir tasarımınız oldu mu? | İçinize çok sinip kullanıcı testinde çuvallayan bir tasarımınızın hikâyesi ne? |
| general | Gece geç saatte çözülen inatçı bir sorunun ardından hissettiğiniz o duygu neye benziyordu? | Gece yarısına kadar uğraşıp sonunda çözdüğünüz en inatçı sorun neydi? |

## Başlangıç seviyesi turu

Kitle çoğunlukla üniversite öğrencileri ve sektöre yeni girenler (~100 kişi). İlk turdan sonra soruların çoğu iş deneyimi varsayıyordu: canlı ortam, PR, deploy, müşteri, MVP, teknik borç, on-call gibi. Bu turda **221 soru yeniden yazıldı**. Havuz anahtarları ve boyutları değişmedi.

İlkeler:

- Hiçbir soru iş deneyimi gerektirmiyor. "Hiç yapmadım" diyen biri de cevaplayabiliyor.
- Sorular alanla bağlantılı ama giriş seviyesinde: ilgi nasıl başladı, ilk denenen araç, nereden yardım alınıyor, şu an ne öğreniliyor, hayal edilen proje.
- Deneyim yerine kullanıcı gözlemi ("telefonunuzdaki", "gördüğünüz", "oynadığınız") ve "siz olsanız…" kurgusu kullanıldı.
- Teknik terimler en yaygın olanlarla sınırlı: uygulama, web sitesi, oyun, yapay zekâ, kod, tasarım.
- Zaten temel olan 48 soruya (çoğu `general` havuzunda) dokunulmadı.

| Havuz | Önce | Sonra |
|---|---|---|
| opensource\|opensource | Bir projeye ilk PR'ınızı gönderirken sizi en çok ne tedirgin etti? | Açık kaynak kavramıyla ilk nerede karşılaştınız? |
| backend\|backend | Canlı ortamda veritabanını kitleyen veya sunucuları yere seren en unutulmaz sorgunuz neydi? | Backend'e nasıl ilgi duydunuz, sizi bu alana çeken ne oldu? |
| backend\|product | MVP'yi yetiştirmek için backend'de bilerek bıraktığınız en büyük teknik borç neydi? | Sizce bir uygulamayı milyonlarca kişinin kullanabilmesi için ne gerekir? |
| devops\|flutter | Store'a sürüm gönderirken pipeline son anda patladığında ne yaptınız? | Yaptığınız bir uygulama Play Store'da olsa ilk kime gönderirdiniz? |
| design\|devops | Bozuk bir deploy yüzünden kullanıcıların gördüğü en garip ekran neydi? | Sevdiğiniz bir uygulamanın güncellemeden sonra tamamen değişmesi size ne hissettiriyor? |
| ai\|data | RAG ya da model eğitiminde veri kalitesinin her şeyi değiştirdiğini gördüğünüz an hangisiydi? | Bir yapay zekâ modelini kendiniz eğitebilseniz ona hangi verileri verirdiniz? |
| security\|security | Logları incelerken tesadüfen yakaladığınız en ciddi saldırı girişimi neydi? | Film ve dizilerdeki hacker sahneleri size ne kadar gerçekçi geliyor? |
| product\|product | Kullanıcıların çok sevdiği ama şirkete hiçbir fayda sağlamayan bir özelliği yayından nasıl kaldırırsınız? | Bir girişim kursanız hangi sorunu çözmek isterdiniz? |

## Havuzlar

## Yapay Zekâ & LLM × Yapay Zekâ & LLM

- Prompt yazarken modelin saçmalayıp sizi en çok şaşırttığı an neydi?
- Yapay zekâ araçlarını en çok ne için kullanıyorsunuz?
- Hangi yapay zekâ aracının abartıldığını, hangisinin hakkının yendiğini düşünüyorsunuz?

## Yapay Zekâ & LLM × Backend & Cloud

- Bir yapay zekâ uygulamasının arka planda nasıl çalıştığını ilk ne zaman merak ettiniz?
- Kendi kodunuzdan bir yapay zekâya soru sorabilseniz ona ilk ne yaptırırdınız?
- Yapay zekâ kod öğrenmenizi nasıl etkiledi, kolaylaştırdı mı tembelleştirdi mi?

## Yapay Zekâ & LLM × Topluluk & Etkinlik

- İzlediğiniz bir yapay zekâ demosunda sizi en çok etkileyen şey neydi?
- Yapay zekâyı okulda ya da günlük hayatta en yaratıcı nasıl kullandınız?
- İnsanların yapay zekâ hakkında en sık yanlış bildiği ve düzeltmek istediğiniz şey ne?

## Yapay Zekâ & LLM × Veri & Analitik

- Yapay zekânın size verdiği en komik yanlış bilgi neydi?
- Bir yapay zekâ modelini kendiniz eğitebilseniz ona hangi verileri verirdiniz?
- Veri ve yapay zekâ öğrenmeye nereden başladınız, ya da nereden başlardınız?

## Yapay Zekâ & LLM × UI/UX & Tasarım

- Yapay zekâya ürettirdiğiniz en güzel ya da en tuhaf görsel neydi?
- Kullandığınız yapay zekâ uygulamalarından hangisinin tasarımını en çok beğeniyorsunuz?
- Yapay zekâ tasarımcıların işini nasıl değiştirecek sizce?

## Yapay Zekâ & LLM × DevOps

- Bilgisayarınızda çalıştırmayı denediğiniz ya da denemek istediğiniz yapay zekâ modeli hangisi?
- Yapay zekâyla bir işi otomatik hale getirebilseniz ilk neyi seçerdiniz?
- Takıldığınız bir hatayı yapay zekâya sorduğunuzda aldığınız en iyi ya da en kötü cevap neydi?

## Yapay Zekâ & LLM × Flutter & Mobil

- Telefonunuzdaki hangi uygulamaya bir yapay zekâ özelliği eklemek isterdiniz?
- Telefonunuzda en sık kullandığınız yapay zekâ uygulaması hangisi, ne için?
- Yapay zekâ destekli bir mobil uygulama yapsanız ne işe yarardı?

## Yapay Zekâ & LLM × Oyun Geliştirme

- Yapay zekâ destekli NPC'lerin oyunları nasıl değiştireceğini düşünüyorsunuz?
- Bir oyunda karşılaştığınız en akıllı ya da en aptal düşman hangisiydi?
- Yapay zekâyla bir oyun tasarlasanız konusu ne olurdu?

## Yapay Zekâ & LLM × Açık Kaynak

- Ücretsiz ve açık kaynak yapay zekâ araçlarından hangilerini duydunuz ya da denediniz?
- Herkesin ücretsiz kullanabileceği bir yapay zekâ aracı yapsanız ne işe yarardı?
- GitHub'da gördüğünüz en ilginç ya da en eğlenceli proje hangisiydi?

## Yapay Zekâ & LLM × Ürün & Girişimcilik

- Yapay zekâyla bir girişim kursanız hangi sorunu çözerdiniz?
- Yapay zekâdan beklediğiniz ama henüz yapamadığı şey ne?
- Sizce yapay zekâyla yapılmış en işe yarar uygulama hangisi?

## Yapay Zekâ & LLM × Siber Güvenlik

- Yapay zekâya kurallarını aştırmak için gördüğünüz en yaratıcı numara neydi?
- Yapay zekâya hangi bilgilerinizi asla vermezsiniz?
- Yapay zekâyla yapılan sahte ses ve videolar sizi ne kadar endişelendiriyor?

## Yapay Zekâ & LLM × Web & Frontend

- Yapay zekâya bir web sitesi yaptırsanız nasıl bir site isterdiniz?
- Sitelerde gördüğünüz en işe yarar ya da en sinir bozucu sohbet botu hangisiydi?
- Yapay zekâ web geliştirmeyi öğrenmenizi nasıl etkiledi?

## Backend & Cloud × Backend & Cloud

- Backend'e nasıl ilgi duydunuz, sizi bu alana çeken ne oldu?
- Bir uygulamanın arka planında nelerin döndüğünü ilk ne zaman merak ettiniz?
- İlk öğrendiğiniz ya da öğrenmek istediğiniz backend dili hangisi, neden?

## Backend & Cloud × Topluluk & Etkinlik

- Bir etkinlikte dinleyip eve dönünce hemen denemek istediğiniz backend fikri neydi?
- Backend öğrenirken takıldığınızda en çok nereden yardım alıyorsunuz?
- Bu oyunun arka planında sizce neler oluyor, nasıl çalışıyor olabilir?

## Backend & Cloud × Veri & Analitik

- En sık kullandığınız uygulama sizce hakkınızda hangi verileri tutuyor?
- İlk kurduğunuz ya da kurmak istediğiniz veritabanında ne saklardınız?
- Elinizde bir şehrin tüm verileri olsa hangi soruya cevap arardınız?

## Backend & Cloud × UI/UX & Tasarım

- Bir uygulamanın görünen yüzü mü, arka planı mı sizi daha çok çekiyor, neden?
- Yavaş açılan bir uygulamayı ne kadar beklersiniz, ne zaman kapatırsınız?
- Gördüğünüz en komik ya da en anlaşılmaz hata mesajı neydi?

## Backend & Cloud × DevOps

- Yaptığınız bir projeyi internete koysanız ilk kime gösterirdiniz?
- Programlama ortamını kurarken yaşadığınız en sinir bozucu an neydi?
- Bir site ya da uygulama çöktüğünde aklınıza ilk ne geliyor?

## Backend & Cloud × Flutter & Mobil

- İnternet yokken de kullanabildiğiniz uygulamalar hangileri, sizce bunu nasıl yapıyorlar?
- Mobil uygulama mı, arkasındaki sunucu mu yapmak size daha cazip geliyor?
- Bir uygulamadan aldığınız en sinir bozucu ya da en işe yarar bildirim neydi?

## Backend & Cloud × Oyun Geliştirme

- Online oyunlarda lag yaşadığınızda sizce arka planda neler oluyor?
- Arkadaşlarınızla oynayacağınız çok oyunculu bir oyun yapsanız nasıl bir oyun olurdu?
- Bir oyunda liderlik tablosuna girmek için yaptığınız en çılgın şey neydi?

## Backend & Cloud × Açık Kaynak

- Kullandığınız ücretsiz ve açık kaynak araçlardan hangisini en çok seviyorsunuz?
- GitHub'da kodunu okuyup bir şey öğrendiğiniz ya da öğrenmek istediğiniz proje hangisi?
- Yeni bir şey öğrenirken dokümantasyon mu, video mu, deneme yanılma mı size daha çok uyuyor?

## Backend & Cloud × Ürün & Girişimcilik

- Bir uygulama fikriniz olsa işe nereden başlardınız, tasarımdan mı koddan mı?
- Sizce bir uygulamayı milyonlarca kişinin kullanabilmesi için ne gerekir?
- Yaptığınız bir uygulamayı bir anda çok kişi kullanmaya başlasa ilk ne yapardınız?

## Backend & Cloud × Siber Güvenlik

- Bir siteye kaydolurken şifrenizin güvende olduğuna nasıl karar veriyorsunuz?
- Duyduğunuz en büyük veri sızıntısı hangisiydi, sizi nasıl etkiledi?
- Giriş yaparken en sevdiğiniz ve en sinir olduğunuz yöntem hangisi?

## Backend & Cloud × Web & Frontend

- Bir web sitesine girdiğinizde arka planda neler olduğunu ilk ne zaman merak ettiniz?
- Frontend mi backend mi, sizi hangisi daha çok çekiyor, neden?
- Hızlı açılan bir sitenin sırrı sizce ne?

## Topluluk & Etkinlik × Topluluk & Etkinlik

- Bugün buraya gelmeye nasıl karar verdiniz?
- Bir etkinlikte yeni biriyle konuşmayı başlatmanın sizce en kolay yolu ne?
- Katıldığınız bir buluşmada ortamın enerjisini anında yükselten şey neydi?

## Topluluk & Etkinlik × Veri & Analitik

- Bir etkinliğin iyi geçtiğini sayılardan nasıl anlardınız?
- Bu salondaki herkes hakkında tek bir şey öğrenebilseniz neyi merak ederdiniz?
- Katılımcı verilerine bakarak bir sonraki etkinlikte neyi değiştirirdiniz?

## Topluluk & Etkinlik × UI/UX & Tasarım

- Bir etkinliğin afişi ya da rozeti, oraya gitme isteğinizi nasıl etkiliyor?
- Gittiğiniz bir etkinlikte tasarımıyla aklınızda kalan şey neydi?
- Tasarım için en çok nereden ilham alıyorsunuz?

## Topluluk & Etkinlik × DevOps

- İzlediğiniz bir sunumda yaşanan en komik teknik aksilik neydi?
- Bir işi otomatik yapmak için yazdığınız ya da yazmak istediğiniz ilk küçük kod neydi?
- Bir hackathon'a katılsanız ekipte hangi rolü üstlenmek isterdiniz?

## Topluluk & Etkinlik × Flutter & Mobil

- Bu oyun gibi bir etkinlik uygulamasına siz hangi özelliği eklerdiniz?
- Konuşma sırasında dinleyicilerin sahneyle etkileşime girmesi için nasıl bir mobil özellik yapardınız?
- Bir günde bir mobil uygulama yapmanız gerekse ne yapardınız?

## Topluluk & Etkinlik × Oyun Geliştirme

- Arkadaşlarınızla en çok oynadığınız oyun hangisi, neden o?
- Bir topluluğu saatlerce ekrana kitleyecek çok oyunculu mini bir oyun tasarlasanız mekaniği ne olurdu?
- Oyuncuların bir araya gelip ürettiği en şaşırtıcı topluluk içeriği ya da mod neydi?

## Topluluk & Etkinlik × Açık Kaynak

- Açık kaynak dendiğinde aklınıza ilk ne geliyor?
- Herkesin katkı verebileceği bir projeye ilk adımı atmak için sizi ne cesaretlendirirdi?
- Wikipedia gibi gönüllülerle yürüyen projeler sizce neden işe yarıyor?

## Topluluk & Etkinlik × Ürün & Girişimcilik

- Bir uygulamaya geri bildirim gönderdiğiniz ya da göndermek istediğiniz son şey neydi?
- Sıfır bütçeyle bir uygulama yapsanız ilk 100 kullanıcıyı nasıl bulurdunuz?
- En sevdiğiniz uygulamaya tek bir özellik ekleyebilseniz ne eklerdiniz?

## Topluluk & Etkinlik × Siber Güvenlik

- Etkinliklerdeki açık Wi-Fi ağlarında nelere dikkat ediyorsunuz?
- Sosyal medyada paylaşmadan önce iki kez düşündüğünüz şeyler neler?
- Arkadaşlarınızı internet dolandırıcılığına karşı uyarmak için ne söylerdiniz?

## Topluluk & Etkinlik × Web & Frontend

- Bir etkinlik için web sitesi yapsanız sayfada mutlaka ne olurdu?
- Gördüğünüz en yaratıcı ya da en eğlenceli web sitesi hangisiydi?
- Bilet ya da kayıt sırasında çöken bir siteyle karşılaştığınızda ne yaptınız?

## Veri & Analitik × Veri & Analitik

- Veriye ve analize ilginiz nasıl başladı?
- Kendi hayatınızla ilgili hangi verileri takip ediyorsunuz ya da etmek isterdiniz?
- Fikrinizi değiştiren bir grafik ya da istatistik hangisiydi?

## Veri & Analitik × UI/UX & Tasarım

- İlk bakışta anlaşılan, gördüğünüz en etkileyici veri görselleştirmesi hangisi?
- Sıkıcı bir tabloyu ilgi çekici hale getirmek için ne yapardınız?
- Spotify Wrapped gibi kişisel veri özetleri sizce neden bu kadar seviliyor?

## Veri & Analitik × DevOps

- Dosyalarınızı nasıl yedekliyorsunuz, kaybettiğiniz en değerli dosya neydi?
- Tekrarlayan bir işi otomatik hale getirmek için ilk hangi aracı öğrenmek isterdiniz?
- Bir uygulamayı kaç kişinin kullandığını sizce nasıl takip ediyorlar?

## Veri & Analitik × Flutter & Mobil

- Telefonunuzdaki ekran süresi verisine baktığınızda sizi en çok ne şaşırttı?
- Bir uygulamanın sizin hakkınızda en çok neyi bildiğini düşünüyorsunuz?
- Verilerle çalışan bir mobil uygulama yapsanız neyi takip ederdi?

## Veri & Analitik × Oyun Geliştirme

- Oyunlarda istatistik ekranına ne kadar bakarsınız, en çok hangi sayıyı takip edersiniz?
- Oynadığınız bir oyunun dengesinde ya da ekonomisinde sizce bozuk olan ne?
- Oyun şirketleri oyuncuların verileriyle sizce neler yapıyor?

## Veri & Analitik × Açık Kaynak

- Herkese açık bir veri setini inceleyebilseniz hangi konuyu seçerdiniz?
- Belediyeler ya da devlet hangi verileri herkese açık paylaşmalı sizce?
- Veriyle uğraşmak için ilk denediğiniz araç hangisiydi, Excel mi, Python mı, başka bir şey mi?

## Veri & Analitik × Ürün & Girişimcilik

- Bir uygulamanın sizi fazla iyi tanıdığını hissettiğiniz an neydi?
- Bir uygulamayı indirmeden önce puanlara mı, yorumlara mı, indirme sayısına mı bakarsınız?
- Karar verirken içgüdünüze mi güvenirsiniz, verilere mi?

## Veri & Analitik × Siber Güvenlik

- Bir uygulamanın sizden istediği en gereksiz izin hangisiydi?
- İnternette hakkınızda en çok bilgiyi sizce hangi şirket tutuyor?
- Kişisel verilerinizi korumak için yaptığınız en basit şey ne?

## Veri & Analitik × Web & Frontend

- Web sitelerindeki çerez uyarılarında genelde ne yapıyorsunuz, neden?
- Sık kullandığınız bir site size hangi istatistiği göstersin isterdiniz?
- Web sitelerindeki formları doldururken sizi en çok ne sinir ediyor?

## UI/UX & Tasarım × UI/UX & Tasarım

- Tasarıma ilginiz nasıl başladı?
- Kullanırken tasarım detaylarına hayran kalıp 'Bunu ben yapmalıydım' dediğiniz uygulama hangisi?
- Tasarım yaparken en sevdiğiniz araç hangisi, neden?

## UI/UX & Tasarım × DevOps

- Kafanızda hayal ettiğiniz bir tasarımı ekrana dökerken en çok ne zorluyor?
- Sevdiğiniz bir uygulamanın güncellemeden sonra tamamen değişmesi size ne hissettiriyor?
- Yavaş yüklenen bir sitede sabrınız kaç saniye dayanıyor?

## UI/UX & Tasarım × Flutter & Mobil

- Telefonunuzdaki en güzel tasarlanmış uygulama hangisi?
- Bir uygulama tasarlasanız ilk hangi ekranı çizerdiniz?
- Bir uygulamada sizi en çok sinir eden tasarım hatası ne?

## UI/UX & Tasarım × Oyun Geliştirme

- Görsel tarzıyla aklınızda kalan oyun hangisi?
- Bir oyunda menüleri ya da kontrolleri anlamakta en çok zorlandığınız an hangisiydi?
- Bir oyun karakteri tasarlasanız nasıl görünürdü?

## UI/UX & Tasarım × Açık Kaynak

- Herkesin ücretsiz kullanabileceği bir tasarım kaynağı hazırlasanız ne olurdu?
- Ücretsiz font, ikon ya da görsel bulmak için en sevdiğiniz site hangisi?
- Tasarımlarınızı başkalarıyla paylaşmak için hangi yeri tercih edersiniz?

## UI/UX & Tasarım × Ürün & Girişimcilik

- Sadece tasarımı yüzünden indirdiğiniz ya da sildiğiniz uygulama hangisi?
- Kullanıcıların önce nefret edip sonra vazgeçemediği bir tasarım kararı hangisi?
- Bir ürün fikriniz olsa adını ve logosunu nasıl seçerdiniz?

## UI/UX & Tasarım × Siber Güvenlik

- İki adımlı doğrulamayı daha az sinir bozucu yapmak için ne değiştirirdiniz?
- Kullanıcılar güvenlik uyarılarını okumadan geçiyor; sizce onlara nasıl okutabiliriz?
- Şifre oluştururken karşılaştığınız en saçma kural neydi?

## UI/UX & Tasarım × Web & Frontend

- İlk yaptığınız ya da yapmak istediğiniz web sitesi neye benziyordu?
- Gezdiğiniz sitelerden hangisinin tasarımına hayran kaldınız?
- Telefonda kullanması en zor olan site hangisi, neyi düzeltirdiniz?

## DevOps × DevOps

- DevOps ile ilk nerede karşılaştınız, sizi ne çekti?
- Bilgisayarınızda tekrar tekrar yaptığınız ve otomatik hale getirmek istediğiniz iş ne?
- Linux, Docker, bulut... Öğrenmeye ilk nereden başladınız ya da başlardınız?

## DevOps × Flutter & Mobil

- Kodunuzun derlenmesini beklerken genelde ne yaparsınız?
- Yaptığınız bir uygulama Play Store'da olsa ilk kime gönderirdiniz?
- Telefon uygulamalarının bu kadar sık güncellenmesi size ne düşündürüyor?

## DevOps × Oyun Geliştirme

- Oyun sunucuları çöktüğünde oyuncu olarak ne yaparsınız?
- Bir oyunun güncellemesini beklerken yaşadığınız en uzun indirme hangisiydi?
- Sevdiğiniz bir şeyi bozan oyun güncellemesi hangisiydi?

## DevOps × Açık Kaynak

- Linux ile ilk tanışmanız nasıl oldu, ya da sizi denemekten ne alıkoyuyor?
- Kurulumda takıldığınızda en çok hangi siteden ya da forumdan yardım alıyorsunuz?
- Ücretsiz açık kaynak yazılımlar sizce nasıl ayakta kalıyor?

## DevOps × Ürün & Girişimcilik

- Bir uygulamanın hiç çökmemesi mi, sürekli yeni özellik gelmesi mi daha önemli sizce?
- Bir uygulamanın çöktüğünü ilk nereden öğreniyorsunuz?
- Hayalinizdeki projeyi herkesin kullanımına açmak için sizce neler gerekir?

## DevOps × Siber Güvenlik

- Telefonunuzun ve bilgisayarınızın güncellemelerini hemen mi yaparsınız, erteler misiniz?
- Onlarca şifreyi aklınızda tutmak için nasıl bir yöntem kullanıyorsunuz?
- Kendi sunucunuzu kursanız güvenliği için ilk neyi öğrenmek isterdiniz?

## DevOps × Web & Frontend

- Kendi web siteniz olsa alan adı ne olurdu?
- Bir web sitesini internete koymakla ilgili en çok neyi merak ediyorsunuz?
- Web sitesi yaparken en çok neyi öğrenmek istiyorsunuz, tasarımı mı, yayına almayı mı?

## Flutter & Mobil × Flutter & Mobil

- Flutter'a ya da mobil geliştirmeye nasıl başladınız?
- Yaptığınız ya da yapmak istediğiniz ilk mobil uygulama neydi?
- Mobil geliştirme öğrenirken takıldığınızda nereden yardım alıyorsunuz?

## Flutter & Mobil × Oyun Geliştirme

- Telefonunuzda en uzun süre oynadığınız oyun hangisi?
- Sıkıcı bir uygulamayı oyunlaştırsanız nasıl eğlenceli hale getirirdiniz?
- Telefonda oynanacak basit bir oyun yapsanız ne olurdu?

## Flutter & Mobil × Açık Kaynak

- Ücretsiz bir uygulamanın kodunu inceleyebilseniz hangisini merak ederdiniz?
- Başkalarının ücretsiz paylaştığı hazır kodları kullanmayı nasıl buluyorsunuz?
- Bir uygulamayı herkesin kullanımına ücretsiz açsanız hangisi olurdu?

## Flutter & Mobil × Ürün & Girişimcilik

- Telefonunuzda olmasını istediğiniz ama henüz kimsenin yapmadığı uygulama ne?
- Bir uygulamayı indirmeye karar verirken sizi en çok ne ikna ediyor?
- En son sildiğiniz uygulama hangisiydi, neden?

## Flutter & Mobil × Siber Güvenlik

- Telefonunuza uygulama yüklerken istenen izinlere ne kadar dikkat ediyorsunuz?
- Telefonunuzu kaybetseniz en çok hangi uygulamadaki verileriniz için endişelenirdiniz?
- Bir uygulamaya güvenip güvenmeyeceğinize nasıl karar veriyorsunuz?

## Flutter & Mobil × Web & Frontend

- Hangi işleri telefondan, hangilerini bilgisayardan yapmayı tercih ediyorsunuz?
- Hem web hem mobilde kullandığınız bir uygulamanın hangi sürümünü daha çok seviyorsunuz?
- Tek bir kodla hem telefon hem web için uygulama yapmak size nasıl geliyor?

## Oyun Geliştirme × Oyun Geliştirme

- Oyun geliştirmeye ilginiz nasıl başladı?
- Oynadığınız oyunlarda karşılaştığınız en komik bug neydi?
- Bitirmekte en çok zorlandığınız oyun bölümü hangisiydi?

## Oyun Geliştirme × Açık Kaynak

- Oyun yapmak için hangi araçla başladınız ya da başlamak isterdiniz?
- En sevdiğiniz oyun modu hangisi, sizce neden bu kadar tuttu?
- Ücretsiz bir oyun yapıp herkesle paylaşsanız nasıl bir oyun olurdu?

## Oyun Geliştirme × Ürün & Girişimcilik

- Bir oyunda para harcamaya değer bulduğunuz ya da hiç harcamadığınız şey ne?
- Bir oyunu arkadaşlarınıza önermeniz için o oyunda ne olması gerekir?
- Kendi oyununuzu yapsanız ücretsiz mi verirdiniz, satar mıydınız, neden?

## Oyun Geliştirme × Siber Güvenlik

- Online bir oyunda gördüğünüz en yaratıcı hile neydi?
- Oyun hesabınızın çalınmaması için neler yapıyorsunuz?
- Bir oyunda hile yapanlarla sizce nasıl başa çıkılmalı?

## Oyun Geliştirme × Web & Frontend

- Tarayıcıda oynadığınız en sevdiğiniz oyun hangisiydi?
- Bir web sitesine gizli bir mini oyun ekleseniz ne olurdu?
- Tarayıcı oyunları mı, indirilen oyunlar mı, sizce hangisi daha eğlenceli?

## Açık Kaynak × Açık Kaynak

- Açık kaynak kavramıyla ilk nerede karşılaştınız?
- Her gün kullandığınız ama açık kaynak olduğunu sonradan öğrendiğiniz araç hangisi?
- İnsanlar sizce neden hiçbir karşılık beklemeden kod paylaşıyor?

## Açık Kaynak × Ürün & Girişimcilik

- Ücretsiz dağıtılan bir yazılım sizce nasıl para kazanabilir?
- Ücretli bir uygulama yerine kullandığınız ücretsiz alternatif hangisi?
- Bir ürüne güvenmeniz için neyi görmeniz gerekir?

## Açık Kaynak × Siber Güvenlik

- Kodu herkese açık bir yazılım sizce daha mı güvenli, daha mı riskli?
- İnternetten indirdiğiniz bir programın güvenli olduğuna nasıl karar verirsiniz?
- Bir yazılımda güvenlik açığı bulsanız ilk ne yapardınız?

## Açık Kaynak × Web & Frontend

- Web sitesi yaparken başkalarının ücretsiz paylaştığı hangi kaynakları kullanırsınız?
- Beğendiğiniz bir sitenin nasıl yapıldığını merak ettiğinizde ne yaparsınız?
- Web geliştirmeyi öğrenmek için en çok hangi ücretsiz kaynağı önerirsiniz?

## Ürün & Girişimcilik × Ürün & Girişimcilik

- Bir girişim kursanız hangi sorunu çözmek isterdiniz?
- Hangi uygulamayı görünce "bunu ben yapmak isterdim" dediniz?
- Sevdiğiniz bir ürünün başarılı olmasının sırrı sizce ne?

## Ürün & Girişimcilik × Siber Güvenlik

- Hangi uygulamanın güvenlik adımları size güven veriyor, hangisininki yoruyor?
- Gizlilik sözleşmelerini okumadan kabul etmek size nasıl geliyor?
- Bir uygulamaya kişisel bilgilerinizi verirken neye dikkat ediyorsunuz?

## Ürün & Girişimcilik × Web & Frontend

- İnternetten alışveriş yaparken bir siteyi terk etmenize ne sebep olur?
- Hayalinizdeki web sitesi ya da internet girişimi ne olurdu?
- En sık kullandığınız web sitesinde neyi değiştirirdiniz?

## Siber Güvenlik × Siber Güvenlik

- Siber güvenliğe ilginiz nasıl başladı?
- Film ve dizilerdeki hacker sahneleri size ne kadar gerçekçi geliyor?
- Güvenlik öğrenmeye ilk nereden başladınız ya da başlardınız?

## Siber Güvenlik × Web & Frontend

- Bir sitenin güvenli olup olmadığını nasıl anlıyorsunuz?
- Size gelen en inandırıcı sahte site ya da dolandırıcılık mesajı neydi?
- Şifrelerinizi tarayıcıya kaydetmek size güvenli geliyor mu, neden?

## Web & Frontend × Web & Frontend

- Web geliştirmeye nasıl başladınız, ilk yaptığınız sayfa neydi?
- HTML ya da CSS öğrenirken sizi en çok uğraştıran şey neydi?
- Bir web sitesi yapsanız ilk hangi özelliği eklerdiniz?

## Genel

- Çalışırken odaklanmak için hangi müziği ya da şarkıyı açarsınız?
- Teknolojiyle uğraşırken yaptığınız ve sonradan çok güldüğünüz en saçma hata neydi?
- İşlerinizi hızlandırmak için kurup vazgeçemediğiniz en pratik klavye kısayolu hangisi?
- Sizi teknolojiye ilk kez bağlayan cihaz, oyun ya da yazılım neydi?
- Günlerce arayıp saç baş yolduktan sonra aşırı basit çıkan o unutamadığınız hata neydi?
- Çalışma masanızda dikkatinizi toplayan ya da dağıtan en ilginç eşya nedir?
- Başkalarının gereksiz bulduğu ama elinizin sürekli gittiği favori dijital araç nedir?
- İlk projenizin çalıştığını gördüğünüzde ne hissettiniz?
- Bir teknoloji terimini teknik olmayan birine anlatırken verdiğiniz en komik benzetme neydi?
- Üzerinde çalışırken zaman algınızı tamamen kaybettiğiniz son proje ne hakkındaydı?
- Artık hiç kullanmadığınız halde atmaya kıyamadığınız o emektar teknolojik eşyanız nedir?
- Yeni bir araç ya da teknoloji öğrenirken başvurduğunuz en verimli yöntem nedir?
- Gece yarısına kadar uğraşıp sonunda çözdüğünüz en inatçı sorun neydi?
- Yapay zekâya yaptırıp sonucuna en çok şaşırdığınız görev neydi?
- Ekran başında tıkanıp kaldığınızda zihninizi açmak için genelde ne yaparsınız?
- Bir gün tamamen internetsiz kalsanız gününüzü nasıl geçirirdiniz?
- Bir teknolojiyi kendi başınıza öğrenmeye çalışırken en çok neye takıldınız?
- Henüz kimse konuşmazken keşfedip erkenden benimsediğiniz teknoloji hangisiydi?
- Eski bir projenize dönüp baktığınızda 'bunu gerçekten ben mi yapmışım' dediğiniz detay nedir?
- Çalışırken kahve veya çay dışında masanızdan asla eksik etmediğiniz o şey nedir?
- Herkesin kullanmasını istediğiniz, az bilinen bir tarayıcı eklentisi hangisi?
- Teknoloji dünyasında son dönemde en çok abartıldığını düşündüğünüz şey nedir?
- İşlerinizi toparlar diye alıp hiç kullanmadığınız alet ya da kurs hangisi?
- Sıkışık bir teslim anında dosyalara verdiğiniz en kaotik isimlendirme neydi?
- Bir projenin bittiğine ve paylaşıma hazır olduğuna nasıl karar verirsiniz?
- Canlı bir demo veya sunum sırasında başınıza gelen en beklenmedik aksilik neydi?
- Bir projede gördüğünüz ya da yazdığınız en yaratıcı geçici çözüm neydi?
- Sırf merakınızı gidermek için hafta sonunuzu feda ettiğiniz en tuhaf konu neydi?
- Karanlık mod mu aydınlık mod mu tercih edersiniz ve bunun arkasındaki asıl sebep nedir?
- Bir teknik sorunu çözmek için arama motoruna yazdığınız en absürt cümle neydi?
- Şu sıralar ne öğreniyorsunuz, nereden öğreniyorsunuz?
- Kendi günlük hayatınızı kolaylaştırmak için yazmak isteyip ertelediğiniz o ufak araç nedir?
- Resmi bir dokümantasyonu okurken kendinizi en çok çaresiz hissettiğiniz an neydi?
- Masaüstünüzde veya indirmeler klasörünüzde temizlemeye bir türlü elinizin gitmediği dosya nedir?
- Bugün sadece tek bir geliştirme veya tasarım aracını seçme hakkınız olsa hangisini seçerdiniz?
