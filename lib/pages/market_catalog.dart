class MarketCatalog {
  static const String other = 'Diğer';

  static const conditions = <String>['1el', '2el'];

  static const cities = <String>[
    'Adana','Adıyaman','Afyonkarahisar','Ağrı','Aksaray','Amasya','Ankara','Antalya','Ardahan','Artvin',
    'Aydın','Balıkesir','Bartın','Batman','Bayburt','Bilecik','Bingöl','Bitlis','Bolu','Burdur',
    'Bursa','Çanakkale','Çankırı','Çorum','Denizli','Diyarbakır','Düzce','Edirne','Elazığ','Erzincan',
    'Erzurum','Eskişehir','Gaziantep','Giresun','Gümüşhane','Hakkari','Hatay','Iğdır','Isparta','İstanbul',
    'İzmir','Kahramanmaraş','Karabük','Karaman','Kars','Kastamonu','Kayseri','Kilis','Kırıkkale','Kırklareli',
    'Kırşehir','Kocaeli','Konya','Kütahya','Malatya','Manisa','Mardin','Mersin','Muğla','Muş',
    'Nevşehir','Niğde','Ordu','Osmaniye','Rize','Sakarya','Samsun','Şanlıurfa','Siirt','Sinop',
    'Şırnak','Sivas','Tekirdağ','Tokat','Trabzon','Tunceli','Uşak','Van','Yalova','Yozgat','Zonguldak'
  ];

  /// Her listede "Diğer" son seçenektir. Kullanıcı seçince kendi değerini yazabilir.
  static const categoryMap = <String, List<String>>{
    'Mobilya': [
      'Koltuk Takımı','Kanepe','Köşe Koltuk','Berjer','Puf','Yatak','Baza','Başlık',
      'Gardırop','Şifonyer','Komodin','Masa','Yemek Masası','Çalışma Masası',
      'Sandalye','Sehpa','Zigon Sehpa','TV Ünitesi','Kitaplık','Raf','Ayakkabılık',
      'Portmanto','Dresuar','Mutfak Dolabı','Banyo Dolabı','Çocuk Odası','Bebek Odası','Diğer'
    ],
    'Ev & Dekor': [
      'Halı','Kilim','Yolluk','Perde','Tül','Stor Perde','Avize','Lambader','Abajur',
      'Ayna','Duvar Saati','Tablo','Çerçeve','Vazo','Mumluk','Dekoratif Obje',
      'Duvar Rafı','Organizer','Sepet','Saksı','Yapay Çiçek','Nevresim','Yorgan',
      'Battaniye','Yastık','Kırlent','Masa Örtüsü','Banyo Aksesuarı','Diğer'
    ],
    'Beyaz Eşya': [
      'Buzdolabı','Derin Dondurucu','Çamaşır Makinesi','Kurutma Makinesi',
      'Bulaşık Makinesi','Fırın','Ankastre Set','Ocak','Davlumbaz','Mikrodalga',
      'Kombi','Klima','Şofben','Su Sebili','Elektrikli Süpürge','Diğer'
    ],
    'Elektronik': [
      'Cep Telefonu','Telefon Aksesuarı','Laptop','Masaüstü Bilgisayar','Monitör',
      'Tablet','Televizyon','Projeksiyon','Oyun Konsolu','Oyun Aksesuarı',
      'Yazıcı','Modem','Kamera','Fotoğraf Makinesi','Drone','Hoparlör','Kulaklık',
      'Akıllı Saat','Powerbank','Şarj Cihazı','Kablo','Bilgisayar Parçası','Diğer'
    ],
    'Mutfak': [
      'Çatal','Kaşık','Bıçak','Çatal-Kaşık-Bıçak Takımı','Tabak','Kase','Bardak',
      'Kupa','Fincan Takımı','Sürahi','Termos','Tencere','Düdüklü Tencere','Tava',
      'Sahan','Tencere Seti','Çaydanlık','Cezve','Kesme Tahtası','Rende','Süzgeç',
      'Merdane','Kepçe-Servis','Saklama Kabı','Baharatlık','Tepsi','Fırın Kabı',
      'Borcam','Kek Kalıbı','Mutfak Robotu','Blender','Mikser','Tost Makinesi',
      'Airfryer','Kettle','Kahve Makinesi','Ekmek Kızartma Makinesi','Diğer'
    ],
    'Hırdavat & Yapı Market': [
      'Matkap','Vidalama','Testere','Taşlama','Kaynak Makinesi','El Aleti',
      'Takım Çantası','Vida ve Çivi','Boya','Boya Malzemesi','Elektrik Malzemesi',
      'Tesisat Malzemesi','Kesme ve Delme','Merdiven','Bahçe Aleti','Çim Biçme',
      'Jeneratör','Kompresör','İş Güvenliği','Diğer'
    ],
    'Giyim': [
      'Kadın Üst Giyim','Kadın Alt Giyim','Kadın Dış Giyim','Kadın Elbise',
      'Erkek Üst Giyim','Erkek Alt Giyim','Erkek Dış Giyim','Çocuk Giyim',
      'Bebek Giyim','Spor Giyim','İç Giyim','Ayakkabı','Çanta','Saat',
      'Takı ve Aksesuar','Şapka','Kemer','Diğer'
    ],
    'Bebek & Çocuk': [
      'Bebek Arabası','Bebek Koltuğu','Mama Sandalyesi','Beşik','Park Yatak',
      'Bebek Taşıyıcı','Bebek Telsizi','Biberon','Mama Malzemesi','Bebek Tekstili',
      'Çocuk Bisikleti','Çocuk Mobilyası','Okul Gereçleri','Diğer'
    ],
    'Oyuncak & Hobi': [
      'Bebek','Oyuncak Araba','Eğitici Oyuncak','Kutu Oyunu','Puzzle','Peluş',
      'Lego ve Blok','Uzaktan Kumandalı','Bisiklet','Scooter','Müzik Aleti',
      'Resim Malzemesi','El İşi Malzemesi','Koleksiyon','Model Maket','Diğer'
    ],
    'Spor & Outdoor': [
      'Fitness Ekipmanı','Koşu Bandı','Kondisyon Bisikleti','Dambıl','Yoga',
      'Futbol','Basketbol','Voleybol','Tenis','Yüzme','Kamp Malzemesi',
      'Çadır','Uyku Tulumu','Balıkçılık','Avcılık','Outdoor Giyim','Diğer'
    ],
    'Kitap & Kırtasiye': [
      'Roman','Çocuk Kitabı','Ders Kitabı','Sınav Kitabı','Ansiklopedi',
      'Dergi','Defter','Kalem','Boya Malzemesi','Ofis Malzemesi','Ajanda',
      'Okul Çantası','Hesap Makinesi','Diğer'
    ],
    'Kişisel Bakım': [
      'Saç Bakımı','Cilt Bakımı','Makyaj','Parfüm','Tıraş Makinesi',
      'Saç Kurutma Makinesi','Saç Şekillendirici','Ağız Bakımı','Masaj Aleti',
      'Manikür ve Pedikür','Diğer'
    ],
    'Bahçe & Balkon': [
      'Bahçe Mobilyası','Balkon Mobilyası','Saksı','Toprak','Gübre','Tohum',
      'Sulama Malzemesi','Bahçe Aleti','Mangal','Barbekü','Gölgelik','Hamak','Diğer'
    ],
    'Evcil Hayvan': [
      'Kedi Malzemesi','Köpek Malzemesi','Kuş Malzemesi','Akvaryum',
      'Mama Kabı','Taşıma Çantası','Yatak','Tasma','Oyuncak','Bakım Ürünü','Diğer'
    ],
    'Ofis & İşyeri': [
      'Ofis Masası','Ofis Koltuğu','Dosya Dolabı','Toplantı Masası','Yazarkasa',
      'Barkod Okuyucu','Raf Sistemi','Mağaza Ekipmanı','Kafe Ekipmanı',
      'Sanayi Makinesi','El Terminali','Diğer'
    ],
    'Oto Parça': [
      'Motor','Kaporta','Şanzıman','Fren','Süspansiyon','Aydınlatma','Elektrik',
      'Lastik/Jant','Akü','Yağ/Sıvı','İç Aksesuar','Dış Aksesuar','Diğer'
    ],
    'Hediyelik Eşya': [
      'Epoksi Sehpa','Epoksi Saat','Epoksi Çerçeve','Epoksi Üçgen Çerçeve',
      'Kişiye Özel Fotoğraflı','Kupa','Anahtarlık','Takı','Dekoratif Hediye',
      'Hediye Kutusu','Diğer'
    ],
  };

  static const furnitureBrands = <String>[
    'İstikbal','Bellona','Yataş','IKEA','Koçtaş','Doğtaş','Kelebek','Enza Home',
    'Vivense','Modalife','Mondi','Çilek','Alfemo','Tepe Home','Adore','Formood',
    'Özel Üretim','Markasız','Diğer'
  ];

  static const decorBrands = <String>[
    'Madame Coco','English Home','Karaca Home','Taç','Özdilek','Linens','Pierre Cardin Home',
    'IKEA','Koçtaş','Bauhaus','Evidea','Vivense','Bella Maison','Mudo Concept',
    'Özel Üretim','Markasız','Diğer'
  ];

  static const whiteGoodsBrands = <String>[
    'Arçelik','Vestel','Beko','Siemens','Bosch','Profilo','Regal','Grundig',
    'Samsung','LG','Altus','Miele','Electrolux','Hoover','Candy','Daikin',
    'Mitsubishi Electric','Demirdöküm','Baymak','Vaillant','Diğer'
  ];

  static const electronicsBrands = <String>[
    'Samsung','Apple','Xiaomi','Huawei','Oppo','Vivo','Realme','OnePlus','Honor',
    'LG','Sony','Lenovo','HP','Dell','Asus','Acer','MSI','Casper','Monster',
    'Philips','JBL','Logitech','Canon','Nikon','Epson','Brother','TCL','Diğer'
  ];

  static const kitchenBrands = <String>[
    'Karaca','Korkmaz','Schafer','Emsan','Bernardo','Jumbo','Aryıldız','Tefal',
    'Taç','Zwilling','Fissler','Paşabahçe','Lav','Kütahya Porselen','Porland',
    'Güral Porselen','Philips','Arzum','Fakir','Bosch','Siemens','Arçelik',
    'Beko','Vestel','Sinbo','Goldmaster','Kiwi','Diğer'
  ];

  static const hardwareBrands = <String>[
    'Bosch','Makita','DeWalt','Stanley','Einhell','Black+Decker','Ryobi','Hilti',
    'Metabo','Würth','İzeltaş','Knipex','Dremel','Rtrmax','Catpower','Ingco','Diğer'
  ];

  static const clothingBrands = <String>[
    'LC Waikiki','Koton','Mavi','DeFacto','Zara','H&M','Mango','Bershka',
    'Pull&Bear','Nike','Adidas','Puma','New Balance','Lumberjack','Flo',
    'Boyner','Vakko','Pierre Cardin','US Polo Assn.','Markasız','Diğer'
  ];

  static const babyBrands = <String>[
    'Chicco','Kraft','Joie','Baby2Go','Sunny Baby','Prego','Pierre Cardin',
    'Maxi-Cosi','Britax Römer','Tommee Tippee','Philips Avent','Wee Baby',
    'Civil','Ebebek','Diğer'
  ];

  static const toyBrands = <String>[
    'Lego','Barbie','Hot Wheels','Fisher-Price','Hasbro','Mattel','Nerf',
    'Play-Doh','Pilsan','Dolu','Clementoni','Ravensburger','Playmobil','Diğer'
  ];

  static const sportBrands = <String>[
    'Nike','Adidas','Puma','Reebok','Under Armour','Decathlon','Domyos',
    'Kipsta','Quechua','Salomon','The North Face','Columbia','Wilson',
    'Voit','Altis','Diğer'
  ];

  static const stationeryBrands = <String>[
    'Faber-Castell','Rotring','Stabilo','Pilot','Bic','Adel','Fatih','Maped',
    'Moleskine','Leitz','Gıpta','Keskin Color','Diğer'
  ];

  static const personalCareBrands = <String>[
    'Philips','Braun','Dyson','Remington','Arzum','Fakir','Grundig','Rowenta',
    'L’Oréal','Nivea','Garnier','Maybelline','Flormar','Avon','Farmasi','Diğer'
  ];

  static const petBrands = <String>[
    'Royal Canin','Pro Plan','Hill’s','Felicia','Reflex','N&D','Whiskas',
    'Pedigree','Trixie','Catit','Ferplast','Diğer'
  ];

  static const officeBrands = <String>[
    'IKEA','Koçtaş','Adore','Bürotime','Nurus','Ofisel','HP','Canon','Epson',
    'Brother','Zebra','Casio','Diğer'
  ];

  static const giftBrands = <String>[
    'Özel Üretim','El Yapımı','Kişiye Özel','Markasız','Diğer'
  ];

  static const autoBrands = <String>[
    'TOGG','Fiat','Opel','Ford','Renault','Toyota','Volkswagen','Hyundai','Honda',
    'Peugeot','Citroen','Mercedes-Benz','BMW','Audi','Skoda','Seat','Kia','Nissan',
    'Dacia','Volvo','Mazda','Mitsubishi','Suzuki','Subaru','Chevrolet','Jeep',
    'Land Rover','Mini','Porsche','Tesla','Diğer'
  ];

  static const Map<String, List<String>> autoModels = {
    'Fiat': ['124','125','131','Albea','Brava','Bravo','Doblo','Egea','Fiorino','Linea','Palio','Panda','Punto','Tipo','Uno','500','500L','500X','500e','Diğer'],
    'Opel': ['Adam','Agila','Astra','Combo','Corsa','Crossland','Grandland','Insignia','Meriva','Mokka','Omega','Vectra','Zafira','Diğer'],
    'Renault': ['9','11','12 (Toros)','19','21','Clio','Symbol','Fluence','Megane','Laguna','Captur','Kadjar','Koleos','Arkana','Austral','Taliant','Kangoo','Diğer'],
    'Ford': ['B-Max','C-Max','Courier','EcoSport','Escort','Fiesta','Focus','Fusion','Galaxy','Kuga','Mondeo','Mustang','Puma','Tourneo Connect','Diğer'],
    'Volkswagen': ['Amarok','Arteon','Beetle','Bora','Caddy','Golf','Jetta','Passat','Polo','Scirocco','T-Cross','Taigo','Tiguan','Touareg','Touran','Diğer'],
    'Toyota': ['Auris','Avensis','Camry','Carina','Celica','Corolla','C-HR','Hilux','Land Cruiser','Prius','RAV4','Supra','Verso','Yaris','Diğer'],
    'Hyundai': ['Accent','Accent Blue','Accent Era','Atos','Bayon','Elantra','Getz','i10','i20','i30','Ioniq','Kona','Santa Fe','Tucson','Diğer'],
    'Honda': ['Accord','City','Civic','CR-V','CR-Z','HR-V','Jazz','Legend','Prelude','S2000','ZR-V','Diğer'],
    'Kia': ['Pride','Cerato','Rio','Picanto','Ceed','Stonic','XCeed','Sportage','Sorento','Niro','EV6','EV9','Diğer'],
    'Nissan': ['Micra','Sunny','Almera','Primera','Note','Juke','Qashqai','X-Trail','Navara','Pathfinder','Ariya','Diğer'],
    'Peugeot': ['106','205','206','207','208','301','306','307','308','408','508','2008','3008','5008','Partner','Rifter','Diğer'],
    'Citroen': ['C-Elysee','C1','C2','C3','C3 Aircross','C4','C4 X','C5','C5 Aircross','Saxo','Xsara','Berlingo','Diğer'],
    'BMW': ['1 Serisi','2 Serisi','3 Serisi','4 Serisi','5 Serisi','6 Serisi','7 Serisi','8 Serisi','X1','X2','X3','X4','X5','X6','X7','Z4','i3','i4','i5','i7','iX','Diğer'],
    'Mercedes-Benz': ['A Serisi','B Serisi','C Serisi','E Serisi','S Serisi','CLA','CLS','GLA','GLB','GLC','GLE','GLS','G Serisi','EQB','EQC','EQE','EQS','Diğer'],
    'Audi': ['80','A1','A3','A4','A5','A6','A7','A8','Q2','Q3','Q4 e-tron','Q5','Q7','Q8','TT','e-tron','Diğer'],
    'Skoda': ['Favorit','Felicia','Fabia','Scala','Octavia','Superb','Rapid','Kamiq','Karoq','Kodiaq','Enyaq','Diğer'],
    'Seat': ['Ibiza','Leon','Toledo','Cordoba','Altea','Arona','Ateca','Tarraco','Diğer'],
    'Dacia': ['Logan','Sandero','Sandero Stepway','Duster','Jogger','Lodgy','Dokker','Diğer'],
    'TOGG': ['T10X','T10F','Diğer'],
    'Diğer': ['Diğer'],
  };

  static const Map<String, List<String>> autoMotors = {
    'Fiat': ['0.9','1.0','1.2','1.3','1.4','1.6','1.9','2.0'],
    'Opel': ['1.2','1.4','1.6','1.8','2.0','2.2','2.5'],
    'Renault': ['0.9','1.0','1.2','1.3','1.4','1.5','1.6','1.8','2.0','2.2'],
    'Ford': ['1.0','1.1','1.3','1.4','1.5','1.6','1.8','2.0','2.3','2.5','5.0'],
    'Volkswagen': ['1.0','1.2','1.4','1.5','1.6','1.9','2.0','2.5','3.2'],
    'Toyota': ['1.0','1.3','1.4','1.5','1.6','1.8','2.0','2.2','2.5'],
    'Hyundai': ['1.0','1.2','1.4','1.5','1.6','2.0','2.2'],
    'Honda': ['1.3','1.4','1.5','1.6','1.8','2.0','2.4'],
    'Kia': ['1.0','1.2','1.4','1.5','1.6','1.7','2.0','2.2'],
    'Nissan': ['1.2','1.3','1.4','1.5','1.6','1.8','2.0','2.5'],
    'Peugeot': ['1.0','1.1','1.2','1.4','1.5','1.6','1.8','2.0','2.2'],
    'Citroen': ['1.0','1.2','1.4','1.5','1.6','1.8','2.0','2.2'],
    'BMW': ['1.5','1.6','1.8','2.0','2.5','3.0','4.0','4.4'],
    'Mercedes-Benz': ['1.3','1.5','1.6','1.8','2.0','2.1','2.2','3.0','4.0','5.0'],
    'Audi': ['1.0','1.2','1.4','1.5','1.6','1.8','2.0','2.5','3.0','4.2'],
    'Skoda': ['1.0','1.2','1.4','1.5','1.6','1.9','2.0'],
    'Seat': ['1.0','1.2','1.4','1.5','1.6','1.8','2.0'],
    'Dacia': ['0.9','1.0','1.2','1.3','1.5','1.6'],
    'TOGG': ['Elektrik'],
  };

  static const Map<String, List<String>> autoParts = {
    'Motor': ['Komple Motor','Silindir Kapak','Piston','Enjektör','Turbo','Yağ Pompası','Triger Seti','Karter','Krank','Eksantrik','Diğer'],
    'Kaporta': ['Sağ Ön Kapı','Sol Ön Kapı','Sağ Arka Kapı','Sol Arka Kapı','Kaput','Bagaj Kapağı','Tampon','Çamurluk','Tavan','Marşpiyel','Diğer'],
    'Aydınlatma': ['Far','Stop','Sinyal','Sis Farı','İç Aydınlatma','Diğer'],
    'Elektrik': ['ECU','Sigorta Kutusu','Kablo Tesisatı','Marş Motoru','Şarj Dinamosu','Sensör','Diğer'],
    'Şanzıman': ['Manuel Şanzıman','Otomatik Şanzıman','Debriyaj','Volan','Şanzıman Beyni','Diğer'],
    'Fren': ['Balata','Disk','Kaliper','ABS','Fren Merkezi','Diğer'],
    'Süspansiyon': ['Amortisör','Yay','Salıncak','Rot','Rotil','Aks','Diğer'],
    'Lastik/Jant': ['Yaz Lastiği','Kış Lastiği','Dört Mevsim Lastik','Çelik Jant','Alaşım Jant','Bijon','Diğer'],
    'Akü': ['Akü','Akü Kablosu','Akü Kutup Başı','Diğer'],
    'Yağ/Sıvı': ['Motor Yağı','Şanzıman Yağı','Antifriz','Fren Hidroliği','Cam Suyu','Diğer'],
    'İç Aksesuar': ['Paspas','Koltuk Kılıfı','Multimedya','Direksiyon Kılıfı','Telefon Tutucu','Diğer'],
    'Dış Aksesuar': ['Tavan Barı','Rüzgarlık','Çeki Demiri','Spoiler','Kapı Koruma','Diğer'],
    'Diğer': ['Diğer'],
  };

  static List<String> brandsForMain(String main) {
    switch (main) {
      case 'Mobilya':
        return furnitureBrands;
      case 'Ev & Dekor':
        return decorBrands;
      case 'Beyaz Eşya':
        return whiteGoodsBrands;
      case 'Elektronik':
        return electronicsBrands;
      case 'Mutfak':
        return kitchenBrands;
      case 'Hırdavat & Yapı Market':
        return hardwareBrands;
      case 'Giyim':
        return clothingBrands;
      case 'Bebek & Çocuk':
        return babyBrands;
      case 'Oyuncak & Hobi':
        return toyBrands;
      case 'Spor & Outdoor':
        return sportBrands;
      case 'Kitap & Kırtasiye':
        return stationeryBrands;
      case 'Kişisel Bakım':
        return personalCareBrands;
      case 'Evcil Hayvan':
        return petBrands;
      case 'Ofis & İşyeri':
        return officeBrands;
      case 'Hediyelik Eşya':
        return giftBrands;
      case 'Oto Parça':
        return autoBrands;
      case 'Bahçe & Balkon':
        return hardwareBrands;
      default:
        return const ['Markasız', 'Diğer'];
    }
  }
}
