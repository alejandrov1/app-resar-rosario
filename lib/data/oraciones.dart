import '../models/prayer_models.dart';

// Textos que se rezan en varias partes del rosario: se escriben una sola vez.
const String _senalDeLaCruz =
    'Por la señal de la Santa Cruz, de nuestros enemigos líbranos Señor Dios Nuestro. '
    'En el nombre del Padre, del Hijo y del Espíritu Santo. Amén.';

const String _padreNuestro =
    'Padre nuestro, que estás en el cielo, santificado sea tu Nombre; venga a nosotros tu reino; '
    'hágase tu voluntad en la tierra como en el cielo.\n'
    'Danos hoy nuestro pan de cada día; perdona nuestras ofensas como también nosotros perdonamos '
    'a los que nos ofenden; no nos dejes caer en la tentación y líbranos del mal. Amén.';

const String _aveMaria =
    'Dios te salve, María, llena eres de gracia; el Señor es contigo, bendita Tú eres entre todas '
    'las mujeres y bendito es el fruto de tu vientre, Jesús.\n'
    'Santa María, Madre de Dios, ruega por nosotros, pecadores, ahora y en la hora de nuestra muerte. Amén.';

const String _gloria =
    'Gloria al Padre y al Hijo y al Espíritu Santo.\n'
    'Como era en el principio, ahora y siempre, por los siglos de los siglos. Amén.';

const String _ruegaPorNosotros =
    'Ruega por nosotros, Santa Madre de Dios.\n'
    'Para que seamos dignos de alcanzar las promesas de Nuestro Señor Jesucristo. Amén.';

const String _letanias = 'Señor, ten piedad\n'
    'Cristo, ten piedad\n'
    'Señor, ten piedad\n'
    '\n'
    'Cristo, óyenos\n'
    'Cristo, escúchanos\n'
    '\n'
    'Dios, Padre celestial, ten misericordia de nosotros.\n'
    'Dios, Hijo, Redentor del mundo, ten misericordia de nosotros.\n'
    'Dios, Espíritu Santo, ten misericordia de nosotros.\n'
    'Santísima Trinidad, un solo Dios, ten misericordia de nosotros.\n'
    '\n'
    'Santa María, ruega por nosotros.\n'
    'Santa Madre de Dios, ruega por nosotros.\n'
    'Santa Virgen de las vírgenes, ruega por nosotros.\n'
    'Madre de Cristo, ruega por nosotros.\n'
    'Madre de la Iglesia, ruega por nosotros.\n'
    'Madre de la misericordia, ruega por nosotros.\n'
    'Madre de la divina gracia, ruega por nosotros.\n'
    'Madre de la esperanza, ruega por nosotros.\n'
    'Madre purísima, ruega por nosotros.\n'
    'Madre castísima, ruega por nosotros.\n'
    'Madre siempre virgen, ruega por nosotros.\n'
    'Madre inmaculada, ruega por nosotros.\n'
    'Madre amable, ruega por nosotros.\n'
    'Madre admirable, ruega por nosotros.\n'
    'Madre del buen consejo, ruega por nosotros.\n'
    'Madre del Creador, ruega por nosotros.\n'
    'Madre del Salvador, ruega por nosotros.\n'
    'Virgen prudentísima, ruega por nosotros.\n'
    'Virgen digna de veneración, ruega por nosotros.\n'
    'Virgen digna de alabanza, ruega por nosotros.\n'
    'Virgen poderosa, ruega por nosotros.\n'
    'Virgen clemente, ruega por nosotros.\n'
    'Virgen fiel, ruega por nosotros.\n'
    'Espejo de justicia, ruega por nosotros.\n'
    'Trono de la sabiduría, ruega por nosotros.\n'
    'Causa de nuestra alegría, ruega por nosotros.\n'
    'Vaso espiritual, ruega por nosotros.\n'
    'Vaso digno de honor, ruega por nosotros.\n'
    'Vaso de insigne devoción, ruega por nosotros.\n'
    'Rosa mística, ruega por nosotros.\n'
    'Torre de David, ruega por nosotros.\n'
    'Torre de marfil, ruega por nosotros.\n'
    'Casa de oro, ruega por nosotros.\n'
    'Arca de la Alianza, ruega por nosotros.\n'
    'Puerta del cielo, ruega por nosotros.\n'
    'Estrella de la mañana, ruega por nosotros.\n'
    'Salud de los enfermos, ruega por nosotros.\n'
    'Refugio de los pecadores, ruega por nosotros.\n'
    'Consuelo de los migrantes, ruega por nosotros.\n'
    'Consoladora de los afligidos, ruega por nosotros.\n'
    'Auxilio de los cristianos, ruega por nosotros.\n'
    'Reina de los Ángeles, ruega por nosotros.\n'
    'Reina de los Patriarcas, ruega por nosotros.\n'
    'Reina de los Profetas, ruega por nosotros.\n'
    'Reina de los Apóstoles, ruega por nosotros.\n'
    'Reina de los Mártires, ruega por nosotros.\n'
    'Reina de los Confesores, ruega por nosotros.\n'
    'Reina de las Vírgenes, ruega por nosotros.\n'
    'Reina de todos los Santos, ruega por nosotros.\n'
    'Reina concebida sin pecado original, ruega por nosotros.\n'
    'Reina asunta a los Cielos, ruega por nosotros.\n'
    'Reina del Santísimo Rosario, ruega por nosotros.\n'
    'Reina de la familia, ruega por nosotros.\n'
    'Reina de la paz, ruega por nosotros.';

/// Los cinco misterios de cada tipo, en orden.
const Map<TipoMisterio, List<String>> misteriosPorTipo = {
  TipoMisterio.gozosos: [
    'La Encarnación del Hijo de Dios',
    'La Visitación de Nuestra Señora a su prima santa Isabel',
    'El Nacimiento del Hijo de Dios',
    'La Presentación de Jesús en el templo',
    'El Niño Jesús perdido y hallado en el templo',
  ],
  TipoMisterio.dolorosos: [
    'La Oración de Jesús en el huerto',
    'La Flagelación del Señor',
    'La Coronación de espinas',
    'Jesús con la Cruz a cuestas, camino del Calvario',
    'La Crucifixión y Muerte de nuestro Señor',
  ],
  TipoMisterio.gloriosos: [
    'La Resurrección del Hijo de Dios',
    'La Ascensión del Señor a los Cielos',
    'La Venida del Espíritu Santo sobre los Apóstoles',
    'La Asunción de nuestra Señora a los Cielos',
    'La Coronación de la Santísima Virgen como Reina de Cielos y Tierra',
  ],
  TipoMisterio.luminosos: [
    'El Bautismo de Jesús en el Jordán',
    'La autorrevelación de Jesús en las bodas de Caná',
    'El anuncio del Reino de Dios invitando a la conversión',
    'La Transfiguración',
    'La Institución de la Eucaristía',
  ],
};

/// Misterio que se reza cada día. La clave es `DateTime.weekday` (1 = lunes … 7 = domingo).
const Map<int, TipoMisterio> misterioPorDia = {
  DateTime.monday: TipoMisterio.gozosos,
  DateTime.tuesday: TipoMisterio.dolorosos,
  DateTime.wednesday: TipoMisterio.gloriosos,
  DateTime.thursday: TipoMisterio.luminosos,
  DateTime.friday: TipoMisterio.dolorosos,
  DateTime.saturday: TipoMisterio.gozosos,
  DateTime.sunday: TipoMisterio.gloriosos,
};

/// Nombre de cada día. El índice es `DateTime.weekday - 1`.
const List<String> nombresDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

const List<Prayer> oracionesIniciales = [
  Prayer(type: 'inicio', title: 'Señal de la Cruz', text: _senalDeLaCruz),
  Prayer(
    type: 'contricion',
    title: 'Acto de contrición',
    text: 'Señor mío Jesucristo, Dios y hombre verdadero, Creador, Padre y Redentor mío. Por ser Tú quien '
        'eres, Bondad infinita, y porque te amo sobre todas las cosas, me pesa de todo corazón haberte '
        'ofendido. También me pesa que puedes castigarme con las penas del infierno. Ayudado de tu divina '
        'gracia propongo firmemente nunca más pecar, confesarme y cumplir la penitencia que me fuere '
        'impuesta. Amén.',
  ),
  Prayer(
    type: 'invocacion',
    title: 'Invocaciones',
    text: 'Señor, ábreme los labios.\nY mi boca proclamará tu alabanza.\n\n'
        'Dios mío, ven en mi auxilio.\nSeñor, date prisa en socorrerme.\n\n$_gloria',
  ),
];

/// Oraciones de cada misterio. La primera es el anuncio; el Ave María se reza 10 veces.
const List<Prayer> oracionesPorMisterio = [
  Prayer(type: 'misterio', title: 'Misterio', text: ''),
  Prayer(type: 'padrenuestro', title: 'Padre Nuestro', text: _padreNuestro),
  Prayer(type: 'avemaria', title: 'Ave María', text: _aveMaria, count: 10),
  Prayer(type: 'gloria', title: 'Gloria', text: _gloria),
  Prayer(
    type: 'maria_madre',
    title: 'María, Madre de gracia',
    text: 'María, Madre de gracia, Madre de misericordia.\nEn la vida y en la muerte ampáranos, gran Señora.',
  ),
  Prayer(type: 'sagrado_corazon', title: 'Sagrado Corazón', text: 'Sagrado Corazón de Jesús,\nen vos confío.'),
  Prayer(
    type: 'oh_jesus',
    title: 'Oh, Jesús mío',
    text: 'Oh Jesús mío, perdónanos. Líbranos del fuego del infierno, lleva a todas las almas al cielo, '
        'especialmente a las más necesitadas.',
  ),
];

const List<Prayer> oracionesFinales = [
  Prayer(type: 'letanias', title: 'Letanías de la Santísima Virgen', text: _letanias),
  Prayer(
    type: 'cordero',
    title: 'Cordero de Dios',
    text: 'Cordero de Dios, que quitas el pecado del mundo.\nPerdónanos, Señor.\n'
        'Cordero de Dios, que quitas el pecado del mundo.\nEscúchanos, Señor.\n'
        'Cordero de Dios, que quitas el pecado del mundo.\nTen piedad de nosotros.\n\n$_ruegaPorNosotros',
  ),
  Prayer(
    type: 'oracion_final',
    title: 'Oración',
    text: 'Te pedimos, Señor, nos concedas a nosotros tus siervos, gozar de perpetua salud de alma y '
        'cuerpo, y por la gloriosa intercesión de la bienaventurada siempre Virgen María, seamos librados '
        'de las tristezas presentes y gocemos de la eterna alegría. Por Jesucristo, nuestro Señor. Amén.',
  ),
  Prayer(type: 'intenciones_papa', title: 'Por las intenciones del Santo Padre', text: _padreNuestro),
  Prayer(type: 'avemaria_final', title: 'Ave María', text: _aveMaria),
  Prayer(type: 'gloria_final', title: 'Gloria', text: _gloria),
  Prayer(
    type: 'salve',
    title: 'Una Salve a la Virgen',
    text: 'Dios te salve, Reina y Madre de misericordia, vida, dulzura y esperanza nuestra; Dios te salve. '
        'A Ti llamamos los desterrados hijos de Eva; a Ti suspiramos, gimiendo y llorando, en este valle de '
        'lágrimas. Ea, pues, Señora, abogada nuestra, vuelve a nosotros esos tus ojos misericordiosos; y '
        'después de este destierro muéstranos a Jesús, fruto bendito de tu vientre. ¡Oh clementísima, oh '
        'piadosa, oh dulce Virgen María!\n\n$_ruegaPorNosotros',
  ),
  Prayer(type: 'jaculatoria', title: 'Jaculatoria final', text: 'Ave María Purísima.\nSin pecado concebida.'),
  Prayer(type: 'senal_final', title: 'Señal de la Cruz', text: _senalDeLaCruz),
  Prayer(
    type: 'dulce_madre',
    title: 'Dulce Madre',
    text: 'Dulce Madre, no te alejes, tu vista de mí no apartes, ven conmigo a todas partes y solo/a nunca '
        'me dejes. Ya que proteges tanto como verdadera madre, haz que me bendiga.\n'
        'El Padre, el Hijo y el Espíritu Santo. Amén.',
  ),
];
