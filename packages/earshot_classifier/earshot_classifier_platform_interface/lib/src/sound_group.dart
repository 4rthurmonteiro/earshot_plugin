/// A broad group of sounds that every backend maps its labels to.
///
/// earshot is informational and is not a certified detector. Never rely on
/// it for safety, including the [alarms] group.
enum SoundGroup {
  /// Speech, laughter, crying, coughing and other human sounds.
  people,

  /// Dogs, cats, birds and other animals.
  animals,

  /// Doors, appliances, water and other household sounds.
  home,

  /// Smoke alarms, CO alarms, sirens and other alarms.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  alarms,

  /// Cars, horns, trains, aircraft and other vehicles.
  vehicles,

  /// Drills, saws, hammers and other tools.
  tools,

  /// Music and musical instruments.
  music,

  /// Wind, rain, thunder and other natural sounds.
  nature,

  /// Sounds that fit no other group.
  other,
}
