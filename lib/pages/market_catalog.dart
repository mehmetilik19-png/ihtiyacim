class MarketCatalog {
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

  /// Ana -> Alt
  static const categoryMap = <String, List<String>>{
    'Mobilya': [
      'Koltuk','Kanepe','Köşe Koltuk','Yatak','Baza','Gardırop','Masa','Sandalye','Sehpa','TV Ünitesi','Çocuk Odası'
    ],
    'Beyaz Eşya': [
      'Buzdolabı','Çamaşır Makinesi','Bulaşık Makinesi','Fırın','Kurutma Makinesi','Kombi','Klima'
    ],
    'Elektronik': [
      'Telefon','Laptop','Tablet','TV','Oyun Konsolu','Hoparlör','Kulaklık','Akıllı Saat'
    ],

    // ✅ MUTFAK (Ana kategori)
    'Mutfak': [
      'Çatal','Kaşık','Bıçak','Çatal-Kaşık-Bıçak Takımı',
      'Tabak','Kase','Bardak','Kupa','Fincan Takımı','Sürahi','Termos',
      'Tencere','Düdüklü Tencere','Tava','Sahan','Granit Set','Çaydanlık','Cezve',
      'Kesme Tahtası','Rende','Süzgeç','Merdane','Kepçe-Servis','Saklama Kabı',
      'Baharatlık','Tepsi','Fırın Kabı','Borcam','Kalıp',
      'Mutfak Robotu','Blender','Mikser','Tost Makinesi','Airfryer','Kettle',
      'Diğer'
    ],

    'Ev & Dekor': [
      'Halı','Perde','Avize','Ayna','Dekoratif'
    ],
    'Hırdavat': [
      'Matkap','El Aleti','Vida/Çivi','Boyalar','Elektrik Malzemesi','Kesme/Delme','Bahçe'
    ],
    'Kıyafet': [
      'Kadın','Erkek','Çocuk','Ayakkabı','Aksesuar'
    ],
    'Oyuncak': [
      'Bebek','Araba','Eğitici','Kutu Oyunu','Puzzle','Peluş'
    ],
    'Oto Parça': [
      'Motor','Kaporta','Şanzıman','Fren','Süspansiyon','Aydınlatma','Elektrik','Lastik/Jant','Akü','Yağ/Sıvı','Aksesuar'
    ],
    'Hediyelik Eşya': [
      'Epoksi Sehpa',
      'Epoksi Saat',
      'Epoksi Çerçeve',
      'Epoksi Üçgen Çerçeve',
      'Kişiye Özel Fotoğraflı',
      'Diğer'
    ],
  };

  // ✅ KATEGORİYE GÖRE MARKA LİSTELERİ

  static const furnitureBrands = <String>[
    'İstikbal','Bellona','Yataş','IKEA','Koçtaş','Doğtaş','Kelebek','Enza Home','Diğer'
  ];

  static const whiteGoodsBrands = <String>[
    'Arçelik','Vestel','Beko','Siemens','Bosch','Profilo','Regal','Grundig','Samsung','LG','Diğer'
  ];

  static const electronicsBrands = <String>[
    'Samsung','Apple','Xiaomi','Huawei','Oppo','Vivo','Realme','OnePlus',
    'LG','Sony','Lenovo','HP','Dell','Asus','Acer','MSI','Casper','Philips','Diğer'
  ];

  static const hardwareBrands = <String>[
    'Bosch','Makita','DeWalt','Stanley','Einhell','Black+Decker','Ryobi','Diğer'
  ];

  static const toyBrands = <String>[
    'Lego','Barbie','Hot Wheels','Fisher-Price','Hasbro','Mattel','Diğer'
  ];

  // ✅ MUTFAK MARKALARI (sende "Diğer" çıkmasının çözümü)
  static const kitchenBrands = <String>[
    'Karaca','Korkmaz','Schafer','Emsan','Bernardo','Jumbo','Aryıldız',
    'Tefal','Taç','Zwilling','Fissler',
    'Paşabahçe','Lav','Kütahya Porselen','Porland','Güral Porselen',
    'Philips','Arzum','Fakir','Bosch','Siemens','Arçelik','Beko','Vestel',
    'Diğer'
  ];

  // ✅ OTO
  static const autoBrands = <String>[
    'TOGG','Fiat','Opel','Ford','Renault','Toyota','Volkswagen','Hyundai','Honda',
    'Peugeot','Citroen','Mercedes-Benz','BMW','Audi','Skoda','Seat','Kia','Nissan','Dacia','Diğer'
  ];

  static const Map<String, List<String>> autoModels = {
    'Fiat': ['124','125','131','Albea','Brava','Bravo','Coupe','Croma','Doblo','Egea','Fiorino','Idea','Linea','Marea','Palio','Panda','Punto','Grande Punto','Punto Evo','Regata','Ritmo','Siena','Stilo','Tempra','Tipo','Uno','500','500L','500X','500e'],
    'Opel': ['Adam','Agila','Antara','Ascona','Astra','Calibra','Cascada','Combo','Corsa','Crossland','Frontera','Grandland','Insignia','Kadett','Meriva','Mokka','Monterey','Omega','Rekord','Senator','Signum','Sintra','Tigra','Vectra','Zafira'],
    'Renault': ['4','5','6','9','11','12 (Toros)','18','19','20','21','25','30','Clio','Symbol','Thalia','Fluence','Megane','Megane Sedan','Megane Coupe','Megane Cabrio','Laguna','Latitude','Safrane','Scenic','Grand Scenic','Espace','Captur','Kadjar','Koleos','Arkana','Austral','Taliant','Modus','Kangoo','Express'],
    'Ford': ['Anglia','B-Max','C-Max','Courier','Cortina','Cougar','EcoSport','Escort','Fiesta','Focus','Fusion','Galaxy','Granada','Ka','Kuga','Maverick','Mondeo','Mustang','Orion','Puma','S-Max','Sierra','Taunus','Tourneo Courier','Tourneo Connect','Transit Connect (binek)'],
    'Volkswagen': ['Amarok','Arteon','Beetle','Bora','Caddy (binek)','Corrado','Derby','Eos','Fox','Golf','Golf Plus','Jetta','Karmann Ghia','Lupo','Passat','Passat Variant','Phaeton','Polo','Santana','Scirocco','Sharan','T-Cross','Taigo','Tiguan','Tiguan Allspace','Touareg','Touran','Up!','Vento'],
    'Toyota': ['4Runner','Auris','Auris Touring Sports','Avensis','Avensis Verso','Camry','Carina','Celica','Corolla','Corolla Verso','Corona','C-HR','Hilux','Land Cruiser','MR2','Picnic','Previa','Prius','RAV4','Starlet','Supra','Urban Cruiser','Verso','Yaris','Yaris Verso'],
    'Hyundai': ['Accent','Accent Blue','Accent Era','Atos','Bayon','Coupe','Elantra','Excel','Getz','i10','i20','i30','i40','Ioniq','Ioniq 5','Ioniq 6','Kona','Matrix','Santa Fe','Sonata','Terracan','Tucson','Veloster'],
    'Honda': ['Accord','City','Civic','Concerto','CR-V','CR-Z','FR-V','HR-V','Insight','Jazz','Legend','Prelude','S2000','Shuttle','Stream','ZR-V','e:Ny1'],
    'Kia': ['Pride','Sephia','Shuma','Cerato','Rio','Picanto','Ceed','Proceed','Stonic','XCeed','Sportage','Sorento','Carens','Carnival','Niro','EV6','EV9'],
    'Nissan': ['Micra','Sunny','Almera','Primera','Note','Tiida','Juke','Qashqai','X-Trail','Navara (binek)','Pathfinder','Murano','Ariya'],
    'Peugeot': ['104','106','205','206','207','208','301','305','306','307','308','309','405','406','407','408','508','605','607','2008','3008','5008','Partner (binek)','Rifter'],
    'Citroen': ['AX','BX','C-Elysee','C1','C2','C3','C3 Aircross','C4','C4 Cactus','C4 X','C5','C5 Aircross','CX','DS3','DS4','DS5','Saxo','Xantia','Xsara','Xsara Picasso'],
    'BMW': ['1 Serisi','2 Serisi','3 Serisi','4 Serisi','5 Serisi','6 Serisi','7 Serisi','8 Serisi','X1','X2','X3','X4','X5','X6','X7','Z3','Z4','i3','i4','i5','i7','iX'],
    'Mercedes-Benz': ['A Serisi','B Serisi','C Serisi','E Serisi','S Serisi','CLA','CLS','GLA','GLB','GLC','GLE','GLS','G Serisi','SL','SLC','EQB','EQC','EQE','EQS'],
    'Audi': ['80','90','100','A1','A3','A4','A5','A6','A7','A8','Q2','Q3','Q4 e-tron','Q5','Q7','Q8','TT','R8','e-tron','e-tron GT'],
    'Skoda': ['Favorit','Felicia','Fabia','Scala','Octavia','Superb','Rapid','Kamiq','Karoq','Kodiaq','Enyaq'],
    'Seat': ['Ibiza','Leon','Toledo','Cordoba','Altea','Arona','Ateca','Tarraco'],
    'Dacia': ['Logan','Sandero','Sandero Stepway','Duster','Jogger','Lodgy','Dokker'],
    'TOGG': ['T10X'],
    'Diğer': ['Diğer'],
  };

  // ✅ OTO: Marka -> Motor
  static const Map<String, List<String>> autoMotors = {
    'Fiat': ['0.9','1.0','1.2','1.3','1.4','1.6','1.9','2.0'],
    'Opel': ['1.2','1.4','1.6','1.8','2.0','2.2','2.5'],
    'Renault': ['0.9','1.0','1.2','1.3','1.4','1.5','1.6','1.7','1.8','2.0','2.1','2.2'],
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

  // ✅ OTO: Parça türüne göre alt parçalar
  static const Map<String, List<String>> autoParts = {
    'Motor': ['Silindir Kapak','Piston','Enjektör','Turbo','Yağ Pompası','Triger Seti','Diğer'],
    'Kaporta': ['Sağ Ön Kapı','Sol Ön Kapı','Kaput','Tampon','Çamurluk','Diğer'],
    'Aydınlatma': ['Far','Stop','Sinyal','Diğer'],
    'Elektrik': ['ECU','Sigorta Kutusu','Kablo Tesisatı','Diğer'],
    'Şanzıman': ['Manuel','Otomatik','Diğer'],
    'Fren': ['Balata','Disk','ABS','Diğer'],
    'Süspansiyon': ['Amortisör','Yay','Salıncak','Diğer'],
    'Lastik/Jant': ['Lastik','Jant','Diğer'],
    'Akü': ['Akü','Diğer'],
    'Yağ/Sıvı': ['Motor Yağı','Şanzıman Yağı','Antifriz','Diğer'],
    'Aksesuar': ['Paspas','Multimedya','Tavan Barı','Diğer'],
  };

  /// ✅ Seçilen ana kategoriye göre marka listesi ver
  static List<String> brandsForMain(String main) {
    switch (main) {
      case 'Mobilya':
        return furnitureBrands;
      case 'Beyaz Eşya':
        return whiteGoodsBrands;
      case 'Elektronik':
        return electronicsBrands;
      case 'Hırdavat':
        return hardwareBrands;
      case 'Oyuncak':
        return toyBrands;
      case 'Mutfak': // ✅ EKLENDİ
        return kitchenBrands;
      case 'Oto Parça':
        return autoBrands;
      default:
        return const ['Diğer'];
    }
  }
}