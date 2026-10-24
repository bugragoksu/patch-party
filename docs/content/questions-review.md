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

## Havuzlar

## Yapay Zekâ & LLM × Yapay Zekâ & LLM

- Prompt yazarken modelin saçmalayıp sizi en çok şaşırttığı an neydi?
- LLM'li bir özelliği canlıya aldıktan sonra sizi en çok hayal kırıklığına uğratan ne oldu?
- Hangi yapay zekâ aracının abartıldığını, hangisinin hakkının yendiğini düşünüyorsunuz?

## Yapay Zekâ & LLM × Backend & Cloud

- LLM API'sinden gelen yanıtları hızlandırmak için denediğiniz en yaratıcı yol neydi?
- Model yanıtlarını backend tarafında cache'lerken karşılaştığınız en zorlu problem neydi?
- Canlıda token limitine takıldığınızda ya da sunucu çöktüğünde ilk ne yaptınız?

## Yapay Zekâ & LLM × Topluluk & Etkinlik

- Bir yapay zekâ aracını topluluğa ilk kez anlatırken dinleyicileri en çok büyüleyen demo neydi?
- Etkinlik düzenlerken ya da içerik üretirken yapay zekâyı en yaratıcı biçimde nasıl kullandınız?
- İnsanların yapay zekâ hakkında en sık yanlış bildiği ve düzeltmek istediğiniz şey ne?

## Yapay Zekâ & LLM × Veri & Analitik

- Temizlemediğiniz bir veriyi modele verdiğinizde çıkan en komik ya da öğretici sonuç neydi?
- RAG ya da model eğitiminde veri kalitesinin her şeyi değiştirdiğini gördüğünüz an hangisiydi?
- Vektör veritabanı seçerken ya da veri hattı kurarken başınızı en çok ağrıtan detay neydi?

## Yapay Zekâ & LLM × UI/UX & Tasarım

- Yapay zekâ araçlarının ürettiği bir arayüz tasarımını koda dökerken yaşadığınız en ilginç an neydi?
- Model yanıt üretirken kullanıcıyı bekletmenin gördüğünüz en iyi yolu hangisi?
- Bir yapay zekâ özelliğini kullanıcıya karmaşık gelmeyecek şekilde tasarlamanın en zor yanı neydi?

## Yapay Zekâ & LLM × DevOps

- Büyük bir modeli production ortamında scale etmeye çalışırken patlayan ilk şey neydi?
- GPU kaynaklarını optimize ederken veya CI/CD hattına model eklerken aldığınız en tuhaf hata neydi?
- Bir model sunucusunu ayakta tutmak için uykusuz kaldığınız gece ne olmuştu?

## Yapay Zekâ & LLM × Flutter & Mobil

- Bir mobil uygulamaya yerel veya bulut tabanlı bir yapay zekâ özelliği eklerken en çok ne zorladı?
- Telefonda çalışan küçük bir yapay zekâ modeli denerken karşılaştığınız performans engeli neydi?
- Kullanıcının cihazında çevrimdışı model çalıştırmayı denerken batarya veya bellek tarafında ne oldu?

## Yapay Zekâ & LLM × Oyun Geliştirme

- Yapay zekâ destekli NPC'lerin oyunları nasıl değiştireceğini düşünüyorsunuz?
- Prosedürel içerik ya da yapay zekâlı bir oyun mekaniği denerken karşılaştığınız en eğlenceli hata neydi?
- Bir oyunda yapay zekânın oyunu kırmadan oyuncuyu şaşırtmasını sağlamanın en zor yanı neydi?

## Yapay Zekâ & LLM × Açık Kaynak

- Açık kaynak bir modeli lokalde çalıştırırken sizi pes etme noktasına getiren ne oldu?
- Açık kaynak bir AI kütüphanesinde bir bug çözmeye çalışırken öğrendiğiniz en değerli şey neydi?
- Hugging Face ya da GitHub'da keşfedip projelerinizi değiştiren, az bilinen bir repo hangisi?

## Yapay Zekâ & LLM × Ürün & Girişimcilik

- Yapay zekâlı bir fikri gerçek bir ürüne dönüştürürken karşılaştığınız en büyük engel neydi?
- Müşterinin ya da kullanıcının yapay zekâdan imkansız bir şey beklediği en unutulmaz anınız neydi?
- Kullanıcıların bir AI özelliğini hiç beklemediğiniz bir amaçla kullandığı en ilginç örnek neydi?

## Yapay Zekâ & LLM × Siber Güvenlik

- Bir modele prompt injection yaptığınızda veya sistemin açık verdiğini gördüğünüzde ilk hissiniz neydi?
- Hassas kurumsal verilerin bir LLM servisine sızmasını önlemek için aldığınız en katı önlem neydi?
- Yapay zekânın bir güvenlik açığı yakaladığı ya da yarattığı en çarpıcı örnek hangisi?

## Yapay Zekâ & LLM × Web & Frontend

- Web sayfasına streaming LLM yanıtı entegre ederken DOM veya state yönetiminde yaşadığınız zorluk neydi?
- Yapay zekâ yanıtı yavaş gelirken kullanıcıya beklemeyi hissettirmemek için bulduğunuz en iyi numara ne?
- Bir web projesinde AI destekli arama veya sohbet bileşeni yaparken tasarımı en çok bozan durum neydi?

## Backend & Cloud × Backend & Cloud

- Canlı ortamda veritabanını kitleyen veya sunucuları yere seren en unutulmaz sorgunuz neydi?
- Bir mikroservis krizinde loglarda kaybolup sorunu saatler sonra bulduğunuz o an nasıldı?
- Bulut faturasının beklenmedik biçimde uçuşa geçtiğini fark ettiğiniz ilk an ne hissettiniz?

## Backend & Cloud × Topluluk & Etkinlik

- Bir etkinlikte dinleyip eve dönünce hemen denemek istediğiniz backend fikri neydi?
- Topluluk için geliştirilen bir projede sunucu çöktüğünde yaşanan en komik kriz anı neydi?
- Bir geliştirici etkinliğinin backend altyapısını kuracak olsanız hangi servisi kesin kullanırdınız?

## Backend & Cloud × Veri & Analitik

- Beklediğinizden çok yavaş çalışan bir sorguyu hızlandırmak için yaptığınız en etkili şey neydi?
- Analitik verileri backend'de işlerken karşılaştığınız en büyük darboğaz neydi?
- Canlı bir veri akışı sistemi çökerttiğinde durumu nasıl kurtardınız?

## Backend & Cloud × UI/UX & Tasarım

- Tasarımdaki karmaşık bir özelliği backend'e uydururken tasarımcıyla en çok neyi tartıştınız?
- API yanıt sürelerinin uzaması kullanıcı deneyimini bozduğunda çözümü nerede buldunuz?
- Backend'den gelen hataları kullanıcıya anlaşılır mesajlara çevirmek için nasıl bir yol buldunuz?

## Backend & Cloud × DevOps

- Canlıya çıkış sırasında sunucu yapılandırması yüzünden yaşanan en unutulmaz kriz neydi?
- Mikroservisleri konteynerize ederken deployment sürecinde en çok zorlandığınız an neydi?
- Sunucudan gelen ilk ciddi alarmda ne yaptınız, sonradan ne öğrendiniz?

## Backend & Cloud × Flutter & Mobil

- Uygulama çevrimdışıyken biriken verileri API ile nasıl senkronize ettiniz?
- Backend yanıt formatı habersiz değişip uygulama patladığında ne yaptınız?
- Sunucudan mobile anlık bildirim gönderirken karşılaştığınız en ilginç sorun neydi?

## Backend & Cloud × Oyun Geliştirme

- Çok oyunculu bir oyunda sunucu gecikmesini düşürmek için denediğiniz en sıra dışı yöntem neydi?
- Oyun içi durumları senkronize ederken veritabanı performansını nasıl toparladınız?
- Liderlik tablosu ya da envanter sisteminin backend altyapısını kurarken neye takıldınız?

## Backend & Cloud × Açık Kaynak

- Kullandığınız açık kaynak bir sunucu kütüphanesinde hata keşfedip PR açtığınızda ne oldu?
- Backend tarafında kapalı kaynak bir servisi açık kaynak bir alternatifle değiştirme hikayeniz neydi?
- Açık kaynak bir projeye katkı verirken dokümantasyon eksikliğiyle nasıl başa çıktınız?

## Backend & Cloud × Ürün & Girişimcilik

- Ürün sahibinin istediği acil bir özelliğin backend maliyeti çok yüksek çıktığında ne yaptınız?
- MVP'yi yetiştirmek için backend'de bilerek bıraktığınız en büyük teknik borç neydi?
- Kullanıcı sayısı aniden fırladığında ürünün ayakta kalması için sunucuda aldığınız ilk aksiyon neydi?

## Backend & Cloud × Siber Güvenlik

- Sunucuda şüpheli bir trafik ya da yetki açığı fark ettiğinizde izini nasıl sürdünüz?
- Bir API ucunun beklenmedik şekilde kötüye kullanıldığını fark ettiğinizde aldığınız ilk önlem neydi?
- Kimlik doğrulama sistemini baştan kurgularken güvenlikle geliştirme hızını nasıl dengelediniz?

## Backend & Cloud × Web & Frontend

- Sayfa yükleme hızını düşüren bir backend isteğini frontend tarafında nasıl telafi ettiniz?
- REST mi GraphQL mi tartışmasında hangi taraftasınız, neden?
- SSR mimarisine geçerken sunucu yükünü ve tarayıcı performansını nasıl dengelediniz?

## Topluluk & Etkinlik × Topluluk & Etkinlik

- Bir etkinlikte tanıştığınız ve kariyerinizi etkileyen biriyle hikâyeniz ne?
- Bir topluluk etkinliği organize ederken son dakikada çıkan en büyük kriz nasıl çözüldü?
- Katıldığınız bir buluşmada ortamın enerjisini anında yükselten şey neydi?

## Topluluk & Etkinlik × Veri & Analitik

- Bir etkinliğin başarısını ölçmek için bilet sayısından farklı hangi metriğe bakardınız?
- Topluluk geri bildirimlerini analiz ederken ortaya çıkan en şaşırtıcı içgörü neydi?
- Katılımcı verilerine bakarak bir sonraki etkinlikte neyi değiştirirdiniz?

## Topluluk & Etkinlik × UI/UX & Tasarım

- Bir etkinliğin afişi ya da rozeti, oraya gitme isteğinizi nasıl etkiliyor?
- Fiziksel bir etkinlik alanında katılımcı deneyimini bozan bir tasarım hatasını nasıl fark ettiniz?
- Topluluk kimliğini ve görsel dilini sıfırdan oluştururken en çok ilham aldığınız kaynak neydi?

## Topluluk & Etkinlik × DevOps

- Canlı bir etkinlik anında çöken sunucuyu kurtarmak için aldığınız en yaratıcı önlem neydi?
- Yüzlerce katılımcının aynı anda yüklendiği bir sistemde ilk kontrol edeceğiniz şey ne olurdu?
- Bir topluluk projesinde deployment sürecini otomatize ederken yaşadığınız en garip aksilik neydi?

## Topluluk & Etkinlik × Flutter & Mobil

- Bu oyun gibi bir etkinlik uygulamasına siz hangi özelliği eklerdiniz?
- Konuşma sırasında dinleyicilerin sahneyle etkileşime girmesi için nasıl bir mobil özellik yapardınız?
- Sadece bir günde tamamlanan bir hackathon mobil uygulamasında feda ettiğiniz ilk özellik neydi?

## Topluluk & Etkinlik × Oyun Geliştirme

- Bir game jam etkinliğinde kısıtlı zamanda ekiple kriz çözerken aldığınız en radikal karar neydi?
- Bir topluluğu saatlerce ekrana kitleyecek çok oyunculu mini bir oyun tasarlasanız mekaniği ne olurdu?
- Oyuncuların bir araya gelip ürettiği en şaşırtıcı topluluk içeriği ya da mod neydi?

## Topluluk & Etkinlik × Açık Kaynak

- İlk açık kaynak katkınızı yaparken ya da ilk pull request'i kabul ederken ne hissetmiştiniz?
- Bir projeye gelen en kaotik issue'yu toplulukla birlikte nasıl çözdünüz?
- Açık kaynak bir projeyi canlı tutmak için uyguladığınız en etkili motivasyon yöntemi nedir?

## Topluluk & Etkinlik × Ürün & Girişimcilik

- Topluluk geri bildirimleriyle tamamen yön değiştiren en ilginç ürün kararı neydi?
- Sıfır bütçeli bir fikir için ilk yüz aktif kullanıcıyı çekerken kullandığınız strateji neydi?
- Kullanıcıların en çok talep ettiği ama ürüne eklemeyi reddettiğiniz özellik neydi?

## Topluluk & Etkinlik × Siber Güvenlik

- Etkinliklerdeki açık Wi-Fi ağlarında nelere dikkat ediyorsunuz?
- Bir topluluk platformunda kullanıcı verilerini korurken aldığınız en sıkı önlem neydi?
- Bir topluluğu sosyal mühendisliğe karşı bilinçlendirmek için ilk ne yapardınız?

## Topluluk & Etkinlik × Web & Frontend

- Bir etkinlik sitesinde son dakika çıkan bir hatayı nasıl çözdünüz?
- Topluluğun ilgisini anında çeken en yaratıcı web animasyonu ya da etkileşimi neydi?
- Kayıtların açıldığı ilk dakikada trafiği kaldıramayan bir açılış sayfasını nasıl toparlardınız?

## Veri & Analitik × Veri & Analitik

- Bir veri setini temizlerken karşınıza çıkan en tuhaf kayıt neydi?
- Bir modelin tahminleri gerçekle tamamen çeliştiğinde ne yaptınız?
- Büyük bir veri yığınında saatlerce aradıktan sonra bulduğunuz en değerli içgörü neydi?

## Veri & Analitik × UI/UX & Tasarım

- İlk bakışta anlaşılan, gördüğünüz en etkileyici veri görselleştirmesi hangisi?
- Karmaşık bir analiz tablosunu sadeleştirirken vazgeçmekte en çok zorlandığınız öge neydi?
- A/B testi sonucunda tasarım sezgilerinizi tamamen yıkan en sürpriz kullanıcı davranışı neydi?

## Veri & Analitik × DevOps

- Bir veri pipeline'ı patladığında ilk nereye bakarsınız?
- Sürekli büyüyen bir veri tabanını sıfır kesintiyle taşırken yaşadığınız en büyük stres neydi?
- Analitik modelleri canlıya alırken kaynak tüketimini optimize ettiğiniz en zekice hamle neydi?

## Veri & Analitik × Flutter & Mobil

- Mobilde binlerce satırlık bir listeyi arayüzü dondurmadan göstermek için ne yaptınız?
- Kullanıcı davranış verilerini analiz ederek mobil uygulamada değiştirdiğiniz ilk ekran neydi?
- Cihazda yerel saklanan verileri uzaktaki analiz sunucusuyla senkronize ederken ne zorladı?

## Veri & Analitik × Oyun Geliştirme

- Oyuncuların bir bölümü geçemediğini oyun analitiğinde fark edince seviyeyi nasıl güncellediniz?
- Oyun içi ekonomiyi dengelerken veri simülasyonlarının yetersiz kaldığı an neydi?
- Oyun motorunda harita optimizasyonu yaparken veri yükünü azaltmak için uyguladığınız yöntem neydi?

## Veri & Analitik × Açık Kaynak

- Analiz yaparken kullandığınız açık kaynak bir kütüphanede bulduğunuz en kritik hata neydi?
- Kamuya açık bir veri setini GitHub üzerinde paylaşırken yaşadığınız en büyük teknik sorun neydi?
- Açık kaynak veri araçları içinde işinizi kökten değiştiren ilk paket hangisiydi?

## Veri & Analitik × Ürün & Girişimcilik

- Kullanıcı verisine bakıp ürünün tüm yol haritasını değiştirdiğiniz o an nasıldı?
- Metrikler harika görünürken ürünün aslında tutmadığını nasıl fark ettiniz?
- Yeni bir özellik çıkarırken sezgilerinizle verilerin çeliştiği durumlarda nasıl uzlaşırsınız?

## Veri & Analitik × Siber Güvenlik

- Veriyle çalışırken karşılaştığınız en tedirgin edici gizlilik sorunu neydi?
- Büyük bir veri setini korurken veya anonimleştirirken yaşadığınız en ilginç zorluk neydi?
- Veri erişim izinleri ile analitik ekiplerin hız baskısı çatıştığında dengeyi nasıl kurarsınız?

## Veri & Analitik × Web & Frontend

- Arayüzde devasa bir veri setini kasmadan görselleştirmeye çalışırken başınıza gelen en zor an neydi?
- Dashboard yaparken kullanıcıların gerçekte hiç bakmadığını fark ettiğiniz metrik hangisiydi?
- Frontend'den gelen kirli kullanıcı verilerini ayıklarken karşılaştığınız en tuhaf durum neydi?

## UI/UX & Tasarım × UI/UX & Tasarım

- İçinize çok sinip kullanıcı testinde çuvallayan bir tasarımınızın hikâyesi ne?
- Kullanırken tasarım detaylarına hayran kalıp 'Bunu ben yapmalıydım' dediğiniz uygulama hangisi?
- Tasarım sisteminde bir bileşeni baştan kurgularken yaşadığınız en büyük fikir ayrılığı neydi?

## UI/UX & Tasarım × DevOps

- Tasarımın canlıda Figma'dakinden farklı göründüğü en tuhaf durum neydi?
- Bozuk bir deploy yüzünden kullanıcıların gördüğü en garip ekran neydi?
- Tasarım varlıklarının CDN veya sunucu tarafında optimize edilmesinde yaşadığınız en büyük dert neydi?

## UI/UX & Tasarım × Flutter & Mobil

- Figma'daki bir mikro etkileşimi Flutter'da birebir yaparken nerede zorlandınız?
- Farklı ekran boyutlarında patlayan ve baştan çizmek zorunda kaldığınız arayüz hangisiydi?
- Kod tarafındaki kısıtlar yüzünden tasarımdan en çok ödün verdiğiniz ekran hangisiydi?

## UI/UX & Tasarım × Oyun Geliştirme

- Bir oyunda atmosferi bozmadan arayüzü görünmez kılmak için bulduğunuz en yaratıcı çözüm neydi?
- Oyuncuların arayüzü yanlış anlayıp bambaşka bir şey yaptığı en komik örnek neydi?
- Oyun içi HUD tasarlarken estetik ve okunabilirlik arasında kaldığınız en zor an hangisiydi?

## UI/UX & Tasarım × Açık Kaynak

- Açık kaynak dünyasında dokümantasyonu veya tasarımı rezalet ama işlevi harika olan araç hangisi?
- Topluluktan gelen bir tasarım katkısını projeye entegre ederken yaşadığınız en ilginç durum neydi?
- Bir tasarım kütüphanesini açık kaynak yapsanız en çok neyden çekinirdiniz?

## UI/UX & Tasarım × Ürün & Girişimcilik

- Kullanıcı deneyimi ile gelir hedefleri çatıştığında hangi tarafı seçtiniz?
- Kullanıcıların önce nefret edip sonra vazgeçemediği bir tasarım kararı hangisi?
- Pazara hızlı çıkmak için tasarımdan verdiğiniz en acı taviz ne olmuştu?

## UI/UX & Tasarım × Siber Güvenlik

- Kullanıcıyı bezdirmeden iki adımlı doğrulamayı arayüze entegre etmek için ne yapardınız?
- Kullanıcılar güvenlik uyarılarını okumadan geçiyor; sizce onlara nasıl okutabiliriz?
- Kolaylık uğruna güvenliği zayıflatan en tanıdık tasarım kararı hangisi?

## UI/UX & Tasarım × Web & Frontend

- Tasarımdaki '1 piksel boşluk' yüzünden CSS tarafında verdiğiniz en uzun mesai neydi?
- Tarayıcı uyumsuzluğu yüzünden çöpe giden en havalı arayüz fikriniz hangisiydi?
- Responsive yaparken mobilde tamamen dağılıp sizi çıldırtan o karmaşık bileşen neydi?

## DevOps × DevOps

- Gece yarısı tetiklenen ve canlı ortamı yerle bir eden en unutulmaz CI/CD patlaması neydi?
- Tüm mimariyi kurtaran ama arkasında sıfır dokümantasyon bıraktığınız o geçici yama neydi?
- Sunucu maliyetlerini düşürmek için yaptığınız ama sistemi kitleyen en cesur hamleniz neydi?

## DevOps × Flutter & Mobil

- Mobil uygulamanın derleme süresini dakikalardan saniyelere indirmek için denediğiniz en çılgın yol neydi?
- Store'a sürüm gönderirken pipeline son anda patladığında ne yaptınız?
- Farklı ortamlar için mobil sürüm alırken konfigürasyon yüzünden saç baş yolduran hata neydi?

## DevOps × Oyun Geliştirme

- Canlı bir oyun sunucusunda ya da dağıtımında yaşanan en büyük kriz anı nasıldı?
- Büyük bir güncelleme gecesinde işlerin ters gittiği anı nasıl toparladınız?
- Oyuncuların beklemediği bir sunucu çöküşünü çözmek için ilk adımınız ne oldu?

## DevOps × Açık Kaynak

- Kullandığınız bir açık kaynak altyapı aracında bulduğunuz en garip hata neydi?
- Kendi yazdığınız bir CI/CD betiğini ya da aracı toplulukla paylaşma deneyiminiz nasıldı?
- Desteği kesilen kritik bir açık kaynak aracın yerine ne koydunuz?

## DevOps × Ürün & Girişimcilik

- Kullanıcıya değer katmak ile altyapı maliyetini düşürmek arasında kaldığınızda neyi seçtiniz?
- Ürün hızla büyüdüğünde altyapıda ilk neyi değiştirmek zorunda kaldınız?
- Müşteriye hissettirmeden yaptığınız en kritik mimari dönüşüm neydi?

## DevOps × Siber Güvenlik

- Canlı ortamda fark edilen bir güvenlik açığı için aldığınız en hızlı aksiyon neydi?
- Sızan bir API anahtarı ya da yetki hatasıyla ilgili yaşadığınız en öğretici olay neydi?
- Güvenlik kısıtlamaları ile geliştirme hızı arasındaki dengeyi nasıl kuruyorsunuz?

## DevOps × Web & Frontend

- Arayüzde görünen ama sebebi build sürecinde çıkan en ilginç hata neydi?
- Statik dosyaların önbelleğe alınmasıyla ilgili yaşadığınız en komik sürpriz neydi?
- Dağıtım sonrası çöken bir frontend uygulamasını ayağa kaldırırken ne hissettiniz?

## Flutter & Mobil × Flutter & Mobil

- App Store ya da Play Store incelemesinden aldığınız en şaşırtıcı ret gerekçesi neydi?
- Bir animasyonu veya widget ağacını optimize ederken harcadığınız en uzun gece nasıldı?
- Hangi üçüncü parti Flutter paketinin azizliğine uğrayıp kendi çözümünüzü yazdınız?

## Flutter & Mobil × Oyun Geliştirme

- Mobilde fizik motoru veya kare hızıyla mücadele ederken aldığınız en radikal karar neydi?
- Sıkıcı bir ekranı oyunlaştırıp eğlenceli hale getirmek için neler denediniz?
- Mobil cihazın aşırı ısınmasına yol açan o sinsi performans sorununu nasıl buldunuz?

## Flutter & Mobil × Açık Kaynak

- İşinizi kurtaran bir açık kaynak Flutter kütüphanesine ilk katkınız nasıl oldu?
- Projelerinizde açık kaynak bir aracın kaynak koduna inmek zorunda kaldığınız o an neydi?
- Açık kaynak bir paketin aniden bozulması projede nasıl bir yangın çıkardı?

## Flutter & Mobil × Ürün & Girişimcilik

- Kullanıcılardan gelen geri bildirimle tamamen çöpe attığınız en havalı mobil özellik neydi?
- Mağazadaki ilk 100 kullanıcıya ulaşırken denediğiniz en sıra dışı yöntem neydi?
- Tasarımcının çizdiğiyle kullanıcının beklediği mobil deneyim nerede çatıştı?

## Flutter & Mobil × Siber Güvenlik

- Mobil tarafta saklanan hassas bir verinin açıkta kaldığını fark ettiğinizde ne yaptınız?
- Tersine mühendislik veya sahte API çağrılarına karşı aldığınız ilk önlem neydi?
- Uygulamanız rootlu ya da jailbreak'li cihazlarda nasıl davranıyor, buna karşı ne yaptınız?

## Flutter & Mobil × Web & Frontend

- Aynı tasarımı hem mobilde hem tarayıcıda pikseli pikseline tutturma savaşınız nasıldı?
- Tarayıcı kısıtlamaları yüzünden mobildeki kadar akıcı çalışmayan o özellik neydi?
- Mobilden web'e taşırken baştan yazmak zorunda kaldığınız ekran hangisiydi?

## Oyun Geliştirme × Oyun Geliştirme

- Oyunun ana mekaniğini çalıştırırken karşınıza çıkan en saçma fizik hatası neydi?
- Oyunculardan gelen beklenmedik bir taktiğin oyunun tüm dengesini bozduğu an nasıldı?
- Kendi oynarken bile bitirmekte zorlandığınız en çetrefilli bölüm hangisiydi?

## Oyun Geliştirme × Açık Kaynak

- Açık kaynaklı bir oyun motorunu ya da aracını projeye uydururken nerede tıkandınız?
- Kendi oyun projelerinizden hangi parçayı açık kaynak yapmak isterdiniz?
- Topluluğun ücretsiz paylaştığı bir asset'in projenizi kurtardığı an neydi?

## Oyun Geliştirme × Ürün & Girişimcilik

- Gelir modeli yüzünden oyuncuları kaçıran bir oyunu siz olsanız nasıl kurtarırdınız?
- Kullanıcı testlerinde fark edip baştan değiştirmek zorunda kaldığınız en şaşırtıcı detay neydi?
- Bir oyunun çıkış günündeki en büyük pazarlama ya da dağıtım krizinde ilk müdahaleniz ne olurdu?

## Oyun Geliştirme × Siber Güvenlik

- Online bir oyunda karşılaştığınız en yaratıcı hile ya da güvenlik açığı nasıl kapatıldı?
- Kullanıcı deneyimini hiç bozmadan bir oyuna anti-cheat sistemi entegre etmenin en kritik adımı nedir?
- Oyuncuların istemci tarafındaki verileri değiştirip hile yapmasını nasıl engellersiniz?

## Oyun Geliştirme × Web & Frontend

- Tarayıcıda 60 FPS'i tutturmak için yaptığınız en zor optimizasyon neydi?
- WebGL ya da WebGPU ile tarayıcıda yapılmış, gördüğünüz en etkileyici iş hangisi?
- Tarayıcıda oyun akıcılığı ile arayüz animasyonlarını birlikte nasıl dengelersiniz?

## Açık Kaynak × Açık Kaynak

- Bir projeye ilk PR'ınızı gönderirken sizi en çok ne tedirgin etti?
- Topluluktan gelen tuhaf bir issue bildirimi sonucunda keşfettiğiniz en ilginç hata neydi?
- Bir açık kaynak projeyi yıllarca yaşatmanın sırrı sizce ne?

## Açık Kaynak × Ürün & Girişimcilik

- Tamamen ücretsiz bir açık kaynak aracı gelir üreten bir girişime dönüştürürken nereden başlarsınız?
- Topluluğun ısrarla istediği ama ürün vizyonuna uymayan bir özelliği geri çevirirken tavrınız ne olurdu?
- Açık kaynak bir proje geliştiricilerin güvenini nasıl kazanır?

## Açık Kaynak × Siber Güvenlik

- Bakımını yaptığınız popüler bir pakette zero-day çıksa ilk ne yapardınız?
- Üçüncü parti bağımlılıkları denetlerken karşınıza çıkan en beklenmedik güvenlik açığı neydi?
- Açık kaynak bir projeye kötü niyetli kod sızmasını önlemek için katkı sürecini nasıl sıkılaştırırsınız?

## Açık Kaynak × Web & Frontend

- Kullandığınız bir frontend kütüphanesinin kaynak kodunu okurken öğrendiğiniz en parlak fikir neydi?
- Kendi yazdığınız bir UI bileşenini paket haline getirip yayınlarken en çok nerede zorlandınız?
- Bir frontend aracının dokümantasyonunda sizi en çok sinir eden eksik neydi?

## Ürün & Girişimcilik × Ürün & Girişimcilik

- Kullanıcıların çok sevdiği ama şirkete hiçbir fayda sağlamayan bir özelliği yayından nasıl kaldırırsınız?
- MVP aşamasında kullanıcıdan gelen ilk sert geri bildirimi duyduğunuzda stratejinizi nasıl güncellediniz?
- Doğru olduğunu düşündüğünüz bir hipotezin kullanıcı analitiğiyle tamamen çöktüğü an ne hissettiniz?

## Ürün & Girişimcilik × Siber Güvenlik

- İki adımlı doğrulama gibi güvenliği artıran ama dönüşüm oranını düşüren adımlarda dengeyi nasıl kurarsınız?
- Kullanıcı onay adımlarını sıkıcı hale getirmeden KVKK veya güvenlik gereksinimlerini nasıl tasarlarsınız?
- Ürünün hızla pazara çıkması ile sızma testlerinin tamamlanması çatıştığında önceliğiniz ne olurdu?

## Ürün & Girişimcilik × Web & Frontend

- Sayfayı hızlandırmanın satışları ya da dönüşümü artırdığını gördüğünüz bir örnek neydi?
- Tasarımcının çizdiği bir arayüz teknik olarak imkânsız çıktığında ne yaptınız?
- Kullanıcıları kaybetmeden baştan sona yeniden yazılan bir frontend projesinde en büyük risk neydi?

## Siber Güvenlik × Siber Güvenlik

- Sosyal mühendislik testlerinde insanların kanmasına en çok şaşırdığınız basit senaryo neydi?
- Logları incelerken tesadüfen yakaladığınız en ciddi saldırı girişimi neydi?
- CTF çözerken günlerce uğraşıp sonunda çok basit bir mantık hatası olduğunu anladığınız an ne hissettiniz?

## Siber Güvenlik × Web & Frontend

- Karşılaştığınız ya da bulduğunuz en ilginç XSS veya CSRF açığı neydi?
- Content Security Policy ayarlarını yaparken kırılan frontend özelliklerini nasıl toparladınız?
- Kullanıcı oturum yönetimini güvenli tutarken sayfalar arası geçişi akıcı yapmanın püf noktası nedir?

## Web & Frontend × Web & Frontend

- CSS ile merkezleme yaparken veya z-index karmaşasında kaybolup saatlerinizi harcadığınız en absürt an neydi?
- Tüm tarayıcılarda sorunsuz çalışıp tek bir cihazda patlayan bir frontend hatasını nasıl avladınız?
- Performans ölçümünde Lighthouse skorunu tavan yaptırmak için feda ettiğiniz en radikal şey neydi?

## Genel

- Çalışırken odaklanmak için hangi müziği ya da şarkıyı açarsınız?
- Teknolojiyle uğraşırken yaptığınız ve sonradan çok güldüğünüz en saçma hata neydi?
- İşlerinizi hızlandırmak için kurup vazgeçemediğiniz en pratik klavye kısayolu hangisi?
- Sizi ilk kez büyüleyen ve bu sektöre adım atmanızı sağlayan cihaz ya da yazılım neydi?
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
- Bir günlüğüne tamamen internetsiz kalsanız projenizi geliştirmeye nasıl devam edersiniz?
- Hayatı kolaylaştırsın diye başlayıp kendisi devasa bir işe dönüşen otomasyon denemeniz neydi?
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
- Bu alana sıfırdan başlayan birine vereceğiniz en samimi tavsiye ne olurdu?
- Kendi günlük hayatınızı kolaylaştırmak için yazmak isteyip ertelediğiniz o ufak araç nedir?
- Resmi bir dokümantasyonu okurken kendinizi en çok çaresiz hissettiğiniz an neydi?
- Masaüstünüzde veya indirmeler klasörünüzde temizlemeye bir türlü elinizin gitmediği dosya nedir?
- Bugün sadece tek bir geliştirme veya tasarım aracını seçme hakkınız olsa hangisini seçerdiniz?
