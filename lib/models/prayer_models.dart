class Prayer {
  final String type;
  final String title;
  final String text;
  final int? count;

  Prayer({
    required this.type,
    required this.title,
    required this.text,
    this.count,
  });
}

class PrayerData {
  static const Map<String, String> mysteries = {
    'Lunes': 'Gozosos',
    'Martes': 'Dolorosos',
    'Miércoles': 'Gloriosos',
    'Jueves': 'Luminosos',
    'Viernes': 'Dolorosos',
    'Sábado': 'Gozosos',
    'Domingo': 'Gloriosos'
  };

  static const Map<String, List<String>> mysteryData = {
    'Gozosos': [
      'La Encarnación del Hijo de Dios',
      'La Visitación de Nuestra Señora a su prima santa Isabel',
      'El Nacimiento del Hijo de Dios',
      'La Presentación de Jesús en el templo',
      'El Niño Jesús perdido y hallado en el templo'
    ],
    'Dolorosos': [
      'La Oración de Jesús en el huerto',
      'La Flagelación del Señor',
      'La Coronación de espinas',
      'Jesús con la Cruz a cuestas, camino del Calvario',
      'La Crucifixión y Muerte de nuestro Señor'
    ],
    'Gloriosos': [
      'La Resurrección del Hijo de Dios',
      'La Ascensión del Señor a los Cielos',
      'La Venida del Espíritu Santo sobre los Apóstoles',
      'La Asunción de nuestra Señora a los Cielos',
      'La Coronación de la Santísima Virgen como Reina de Cielos y Tierra'
    ],
    'Luminosos': [
      'El Bautismo de Jesús en el Jordán',
      'La autorrevelación de Jesús en las bodas de Caná',
      'El anuncio del Reino de Dios invitando a la conversión',
      'La Transfiguración',
      'La Institución de la Eucaristía'
    ]
  };

  static final List<Prayer> initialPrayers = [
    Prayer(
      type: 'inicio',
      title: 'Señal de la Cruz',
      text: 'Por la señal de la Santa Cruz, de nuestros enemigos líbranos Señor Dios Nuestro. En el nombre del Padre, del Hijo y del Espíritu Santo. Amén.',
    ),
    Prayer(
      type: 'contricion',
      title: 'Acto de contrición',
      text: 'Señor mío Jesucristo, Dios y hombre verdadero, Creador, Padre y Redentor mío. Por ser Tú quién eres, Bondad infinita, y porque te amo sobre todas las cosas, me pesa de todo corazón haberte ofendido. También me pesa que puedes castigarme con las penas del infierno. Ayudado de tu divina gracia propongo firmemente nunca más pecar, confesarme y cumplir la penitencia que me fuere impuesta. Amén.',
    ),
    Prayer(
      type: 'invocacion',
      title: 'Invocaciones',
      text: 'Señor, ábreme los labios.\nY mi boca proclamará tu alabanza.\n\nDios mío, ven en mi auxilio.\nSeñor, date prisa en socorrerme.\n\nGloria al Padre y al Hijo y al Espíritu Santo.\nComo era en el principio, ahora y siempre, por los siglos de los siglos. Amén.',
    ),
  ];

  static final List<Prayer> mysteryPrayers = [
    Prayer(type: 'misterio', title: 'Misterio', text: ''),
    Prayer(
      type: 'padrenuestro',
      title: 'Padre Nuestro',
      text: 'Padre nuestro, que estás en el cielo, santificado sea tu Nombre; venga a nosotros tu reino; hágase tu voluntad en la tierra como en el cielo.\nDanos hoy nuestro pan de cada día; perdona nuestras ofensas como también nosotros perdonamos a los que nos ofenden; no nos dejes caer en la tentación y líbranos del mal. Amén.',
    ),
    Prayer(
      type: 'avemaria',
      title: 'Ave María',
      text: 'Dios te salve, María, llena eres de gracia; el Señor es contigo, bendita Tú eres entre todas las mujeres y bendito es el fruto de tu vientre, Jesús.\nSanta María, Madre de Dios, ruega por nosotros, pecadores, ahora y en la hora de nuestra muerte. Amén.',
      count: 10,
    ),
    Prayer(
      type: 'gloria',
      title: 'Gloria',
      text: 'Gloria al Padre y al Hijo y al Espíritu Santo.\nComo era en el principio, ahora y siempre, por los siglos de los siglos. Amén.',
    ),
    Prayer(
      type: 'maria_madre',
      title: 'María, Madre de gracia',
      text: 'María, Madre de gracia, Madre de misericordia.\nDefiéndenos de nuestros enemigos y ampáranos ahora y en la hora de nuestra muerte. Amén.',
    ),
    Prayer(
      type: 'oh_jesus',
      title: 'Oh, Jesús Mío',
      text: 'Oh Jesús mío, perdónanos. Líbranos del fuego del infierno, lleva a todas las almas al cielo, especialmente a las más necesitadas.',
    ),
  ];

  static final List<Prayer> finalPrayers = [
    Prayer(
      type: 'letanias',
      title: 'Letanías de la Santísima Virgen',
      text: 'Señor, ten piedad\nCristo, ten piedad\nSeñor, ten piedad\nCristo, óyenos\nCristo, escúchanos\n\nDios Padre celestial. Ten misericordia de nosotros.\nDios Hijo, Redentor del mundo. Ten misericordia de nosotros.\nDios Espíritu Santo. Ten misericordia de nosotros.\nTrinidad Santa, un solo Dios.\n\nSanta María, Ruega por nosotros\nSanta Madre de Dios, Ruega por nosotros\nSanta Virgen de las Vírgenes, Ruega por nosotros...',
    ),
    Prayer(
      type: 'cordero',
      title: 'Cordero de Dios',
      text: 'Cordero de Dios, que quitas el pecado del mundo.\nPerdónanos, Señor.\nCordero de Dios, que quitas el pecado del mundo.\nEscúchanos, Señor.\nCordero de Dios, que quitas el pecado del mundo.\nTen piedad de nosotros.\n\nRuega por nosotros, Santa Madre de Dios.\nPara que seamos dignos de alcanzar las promesas de Nuestro Señor Jesucristo. Amén.',
    ),
    Prayer(
      type: 'oracion_final',
      title: 'Oración',
      text: 'Te pedimos, Señor, nos concedas a nosotros tus siervos, gozar de perpetua salud de alma y cuerpo, y por la gloriosa intercesión de la bienaventurada siempre Virgen María, seamos librados de las tristezas presentes y gocemos de la eterna alegría. Por Jesucristo, nuestro Señor. Amén.',
    ),
    Prayer(
      type: 'intenciones_papa',
      title: 'Por las intenciones del Santo Padre',
      text: 'Padre nuestro, que estás en el cielo, santificado sea tu Nombre; venga a nosotros tu reino; hágase tu voluntad en la tierra como en el cielo.\nDanos hoy nuestro pan de cada día; perdona nuestras ofensas como también nosotros perdonamos a los que nos ofenden; no nos dejes caer en la tentación y líbranos del mal. Amén.',
    ),
    Prayer(
      type: 'avemaria_final',
      title: 'Ave María',
      text: 'Dios te salve, María, llena eres de gracia; el Señor es contigo, bendita Tú eres entre todas las mujeres y bendito es el fruto de tu vientre, Jesús.\nSanta María, Madre de Dios, ruega por nosotros, pecadores, ahora y en la hora de nuestra muerte. Amén.',
    ),
    Prayer(
      type: 'gloria_final',
      title: 'Gloria',
      text: 'Gloria al Padre y al Hijo y al Espíritu Santo.\nComo era en el principio, ahora y siempre, por los siglos de los siglos. Amén.',
    ),
    Prayer(
      type: 'salve',
      title: 'Una Salve a la Virgen',
      text: 'Dios te salve, Reina y Madre de misericordia, vida, dulzura y esperanza nuestra; Dios te salve. A Ti llamamos los desterrados hijos de Eva; a Ti suspiramos, gimiendo y llorando, en este valle de lágrimas. Ea, pues, Señora, abogada nuestra, vuelve a nosotros esos tus ojos misericordiosos; y después de este destierro muéstranos a Jesús, fruto bendito de tu vientre. ¡Oh clementísima, oh piadosa, oh dulce Virgen María!\n\nRuega por nosotros, Santa Madre de Dios.\nPara que seamos dignos de alcanzar las promesas de Nuestro Señor Jesucristo. Amén.',
    ),
    Prayer(
      type: 'jaculatoria',
      title: 'Jaculatoria final',
      text: 'Ave María Purísima.\nSin pecado concebida.',
    ),
  ];
}