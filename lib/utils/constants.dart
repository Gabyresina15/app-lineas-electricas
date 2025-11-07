/// Mapa global de códigos de falla y sus descripciones.
const Map<int, String> availableCodes = {
  521: '(Cambio aislador apoyo)',
  523: '(Cambio atadura aislador)',
  525: '(Cambio de cadena retencion o susp)',
  527: '(Cambio de cruceta)',
  528: '(Cambio de descargadores)',
  529: '(Colocacion/Cambio poste de madera)',
  555: '(poda)',
};

/// Lista de tensiones permitidas
const List<double> kAvailableTensions = [
  13.2, // MT
  33.0, // MT
  66.0, // AT
];

/// Lista de municipios de Salta
const List<String> kAvailableMunicipios = [
  'Aguaray',
  'Aguas Blancas',
  'Angastaco',
  'Animaná',
  'Apolinario Saravia',
  'Cachi',
  'Cafayate',
  'Campo Quijano',
  'Campo Santo',
  'Capital (Salta)',
  'Cerrillos',
  'Chicoana',
  'Colonia Santa Rosa',
  'Coronel Moldes',
  'El Bordo',
  'El Carril',
  'El Galpón',
  'El Jardín',
  'El Potrero',
  'El Quebrachal',
  'El Tala',
  'Embarcación',
  'General Ballivián',
  'General Güemes',
  'General Mosconi',
  'General Pizarro',
  'Guachipas',
  'Hipólito Yrigoyen',
  'Iruya',
  'Isla de Cañas',
  'Joaquín V. González',
  'La Caldera',
  'La Candelaria',
  'La Merced',
  'La Poma',
  'La Viña',
  'Las Lajitas',
  'Los Toldos',
  'Molinos',
  'Nazareno',
  'Payogasta',
  'Pichanal',
  'Profesor Salvador Mazza',
  'Río Piedras',
  'Rivadavia Banda Norte',
  'Rivadavia Banda Sur',
  'Rosario de la Frontera',
  'Rosario de Lerma',
  'San Antonio de los Cobres',
  'San Carlos',
  'San José de Metán',
  'San Lorenzo (Villa San Lorenzo)',
  'San Ramón de la Nueva Orán',
  'Santa Victoria Este',
  'Santa Victoria Oeste',
  'Seclantás',
  'Tartagal',
  'Tolar Grande',
  'Urundel',
  'Vaqueros',
];

/// Lista de tipos de estructuras (piquetes)
const List<String> kAvailablePiqueteTypes = [
  'Poste de madera',
  'Columna de hormigón',
  'Doble retención (columna de hormigón)',
  'Retención simple (columna de hormigón)',
  'Doble retención (poste de madera)',
  'Retención simple (poste de madera)',
];