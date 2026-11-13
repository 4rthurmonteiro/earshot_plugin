import 'package:earshot_classifier_platform_interface/src/classifier_backend.dart';
import 'package:earshot_classifier_platform_interface/src/sound_group.dart';

/// A sound that earshot recognizes, with the same identifier on every
/// backend.
///
/// Each value lists its [group], an English [displayName], and the raw labels
/// of each backend that map to it: [appleLabels] for
/// [ClassifierBackend.apple] (SoundAnalysis) and [yamnetLabels] for
/// [ClassifierBackend.yamnet]. A sound is part of the vocabulary when at least
/// one backend can recognize it, so one of the two lists can be empty. Use
/// [isSupportedBy] to check a backend.
///
/// Backend labels that map to no [EarshotSound] are still reported, with
/// their group and raw label only. See `SoundDetection.sound`.
///
/// This file is the vocabulary's data file. Every label is validated against
/// the official label lists in `tools/vocab/` by
/// `test/src/vocabulary/vocabulary_validation_test.dart`.
///
/// earshot is informational and is not a certified detector. Never rely on
/// it for safety, including the sounds in [SoundGroup.alarms].
///
/// New values may be added in a minor version. When you switch on this
/// enum, add a wildcard (`_`) case so that your code keeps compiling.
enum EarshotSound {
  /// Someone speaking, including children and conversations.
  speech(
    SoundGroup.people,
    'Speech',
    appleLabels: ['speech'],
    yamnetLabels: [
      'Speech',
      'Child speech, kid speaking',
      'Conversation',
      'Narration, monologue',
    ],
  ),

  /// Someone whispering.
  whispering(
    SoundGroup.people,
    'Whispering',
    appleLabels: ['whispering'],
    yamnetLabels: ['Whispering'],
  ),

  /// Someone shouting or yelling.
  shouting(
    SoundGroup.people,
    'Shouting',
    appleLabels: ['shout', 'yell', 'children_shouting', 'battle_cry'],
    yamnetLabels: ['Shout', 'Bellow', 'Whoop', 'Yell', 'Children shouting'],
  ),

  /// Someone screaming.
  screaming(
    SoundGroup.people,
    'Screaming',
    appleLabels: ['screaming'],
    yamnetLabels: ['Screaming'],
  ),

  /// Someone laughing, giggling or chuckling.
  laughter(
    SoundGroup.people,
    'Laughter',
    appleLabels: [
      'laughter',
      'belly_laugh',
      'chuckle_chortle',
      'giggling',
      'snicker',
    ],
    yamnetLabels: [
      'Laughter',
      'Giggle',
      'Snicker',
      'Belly laugh',
      'Chuckle, chortle',
    ],
  ),

  /// A baby laughing.
  babyLaughter(
    SoundGroup.people,
    'Baby laughter',
    appleLabels: ['baby_laughter'],
    yamnetLabels: ['Baby laughter'],
  ),

  /// Someone crying, sobbing or whimpering.
  crying(
    SoundGroup.people,
    'Crying',
    appleLabels: ['crying_sobbing'],
    yamnetLabels: ['Crying, sobbing', 'Whimper', 'Wail, moan'],
  ),

  /// A baby or infant crying.
  babyCrying(
    SoundGroup.people,
    'Baby crying',
    appleLabels: ['baby_crying'],
    yamnetLabels: ['Baby cry, infant cry'],
  ),

  /// Someone humming.
  humming(
    SoundGroup.people,
    'Humming',
    appleLabels: ['humming'],
    yamnetLabels: ['Humming'],
  ),

  /// Someone whistling.
  whistling(
    SoundGroup.people,
    'Whistling',
    appleLabels: ['whistling'],
    yamnetLabels: ['Whistling'],
  ),

  /// Breathing, gasping, panting or sighing.
  breathing(
    SoundGroup.people,
    'Breathing',
    appleLabels: ['breathing', 'gasp', 'sigh'],
    yamnetLabels: ['Breathing', 'Wheeze', 'Gasp', 'Pant', 'Snort', 'Sigh'],
  ),

  /// Someone snoring.
  snoring(
    SoundGroup.people,
    'Snoring',
    appleLabels: ['snoring'],
    yamnetLabels: ['Snoring'],
  ),

  /// A cough or throat clearing.
  cough(
    SoundGroup.people,
    'Cough',
    appleLabels: ['cough'],
    yamnetLabels: ['Cough', 'Throat clearing'],
  ),

  /// A sneeze.
  sneeze(
    SoundGroup.people,
    'Sneeze',
    appleLabels: ['sneeze'],
    yamnetLabels: ['Sneeze'],
  ),

  /// Someone blowing their nose.
  noseBlowing(SoundGroup.people, 'Nose blowing', appleLabels: ['nose_blowing']),

  /// A hiccup.
  hiccup(
    SoundGroup.people,
    'Hiccup',
    appleLabels: ['hiccup'],
    yamnetLabels: ['Hiccup'],
  ),

  /// A burp.
  burp(
    SoundGroup.people,
    'Burp',
    appleLabels: ['burp'],
    yamnetLabels: ['Burping, eructation'],
  ),

  /// Chewing, biting or slurping.
  chewing(
    SoundGroup.people,
    'Chewing',
    appleLabels: ['chewing', 'biting', 'slurp'],
    yamnetLabels: ['Chewing, mastication', 'Biting'],
  ),

  /// Someone gargling.
  gargling(
    SoundGroup.people,
    'Gargling',
    appleLabels: ['gargling'],
    yamnetLabels: ['Gargling'],
  ),

  /// Someone walking, running or shuffling.
  footsteps(
    SoundGroup.people,
    'Footsteps',
    appleLabels: ['person_walking', 'person_running', 'person_shuffling'],
    yamnetLabels: ['Run', 'Shuffle', 'Walk, footsteps'],
  ),

  /// Fingers snapping.
  fingerSnapping(
    SoundGroup.people,
    'Finger snapping',
    appleLabels: ['finger_snapping'],
    yamnetLabels: ['Finger snapping'],
  ),

  /// Hands clapping.
  clapping(
    SoundGroup.people,
    'Clapping',
    appleLabels: ['clapping'],
    yamnetLabels: ['Clapping'],
  ),

  /// An audience applauding.
  applause(
    SoundGroup.people,
    'Applause',
    appleLabels: ['applause'],
    yamnetLabels: ['Applause'],
  ),

  /// People cheering.
  cheering(
    SoundGroup.people,
    'Cheering',
    appleLabels: ['cheering'],
    yamnetLabels: ['Cheering'],
  ),

  /// People booing.
  booing(SoundGroup.people, 'Booing', appleLabels: ['booing']),

  /// A crowd, chatter or babble of voices.
  crowd(
    SoundGroup.people,
    'Crowd',
    appleLabels: ['crowd', 'chatter', 'babble'],
    yamnetLabels: ['Chatter', 'Crowd', 'Hubbub, speech noise, speech babble'],
  ),

  /// Children playing.
  childrenPlaying(
    SoundGroup.people,
    'Children playing',
    yamnetLabels: ['Children playing'],
  ),

  /// A dog, when no more specific dog sound is recognized.
  dog(
    SoundGroup.animals,
    'Dog',
    appleLabels: ['dog'],
    yamnetLabels: ['Dog', 'Canidae, dogs, wolves'],
  ),

  /// A dog barking.
  dogBark(
    SoundGroup.animals,
    'Dog bark',
    appleLabels: ['dog_bark', 'dog_bow_wow'],
    yamnetLabels: ['Bark', 'Yip', 'Bow-wow'],
  ),

  /// A dog howling.
  dogHowl(
    SoundGroup.animals,
    'Dog howl',
    appleLabels: ['dog_howl'],
    yamnetLabels: ['Howl'],
  ),

  /// A dog growling.
  dogGrowl(
    SoundGroup.animals,
    'Dog growl',
    appleLabels: ['dog_growl'],
    yamnetLabels: ['Growling'],
  ),

  /// A dog whimpering.
  dogWhimper(
    SoundGroup.animals,
    'Dog whimper',
    appleLabels: ['dog_whimper'],
    yamnetLabels: ['Whimper (dog)'],
  ),

  /// A cat, when no more specific cat sound is recognized.
  cat(SoundGroup.animals, 'Cat', appleLabels: ['cat'], yamnetLabels: ['Cat']),

  /// A cat meowing.
  catMeow(
    SoundGroup.animals,
    'Cat meow',
    appleLabels: ['cat_meow'],
    yamnetLabels: ['Meow', 'Caterwaul'],
  ),

  /// A cat purring.
  catPurr(
    SoundGroup.animals,
    'Cat purr',
    appleLabels: ['cat_purr'],
    yamnetLabels: ['Purr'],
  ),

  /// A horse neighing or its hooves.
  horse(
    SoundGroup.animals,
    'Horse',
    appleLabels: ['horse_clip_clop', 'horse_neigh'],
    yamnetLabels: ['Horse', 'Clip-clop', 'Neigh, whinny'],
  ),

  /// Cattle mooing.
  cow(
    SoundGroup.animals,
    'Cow',
    appleLabels: ['cow_moo'],
    yamnetLabels: ['Cattle, bovinae', 'Moo'],
  ),

  /// A pig oinking.
  pig(
    SoundGroup.animals,
    'Pig',
    appleLabels: ['pig_oink'],
    yamnetLabels: ['Pig', 'Oink'],
  ),

  /// A sheep or goat bleating.
  sheep(
    SoundGroup.animals,
    'Sheep',
    appleLabels: ['sheep_bleat'],
    yamnetLabels: ['Goat', 'Bleat', 'Sheep'],
  ),

  /// A chicken clucking.
  chicken(
    SoundGroup.animals,
    'Chicken',
    appleLabels: ['chicken', 'chicken_cluck'],
    yamnetLabels: ['Chicken, rooster', 'Cluck'],
  ),

  /// A rooster crowing.
  rooster(
    SoundGroup.animals,
    'Rooster',
    appleLabels: ['rooster_crow'],
    yamnetLabels: ['Crowing, cock-a-doodle-doo'],
  ),

  /// A turkey gobbling.
  turkey(
    SoundGroup.animals,
    'Turkey',
    appleLabels: ['turkey_gobble'],
    yamnetLabels: ['Turkey', 'Gobble'],
  ),

  /// A duck quacking.
  duck(
    SoundGroup.animals,
    'Duck',
    appleLabels: ['duck_quack'],
    yamnetLabels: ['Duck', 'Quack'],
  ),

  /// A goose honking.
  goose(
    SoundGroup.animals,
    'Goose',
    appleLabels: ['goose_honk'],
    yamnetLabels: ['Goose', 'Honk'],
  ),

  /// A bird singing, chirping or squawking.
  bird(
    SoundGroup.animals,
    'Bird',
    appleLabels: [
      'bird',
      'bird_vocalization',
      'bird_chirp_tweet',
      'bird_squawk',
    ],
    yamnetLabels: [
      'Bird',
      'Bird vocalization, bird call, bird song',
      'Chirp, tweet',
      'Squawk',
    ],
  ),

  /// A pigeon or dove cooing.
  pigeon(
    SoundGroup.animals,
    'Pigeon',
    appleLabels: ['pigeon_dove_coo'],
    yamnetLabels: ['Pigeon, dove', 'Coo'],
  ),

  /// A crow cawing.
  crow(
    SoundGroup.animals,
    'Crow',
    appleLabels: ['crow_caw'],
    yamnetLabels: ['Crow', 'Caw'],
  ),

  /// An owl hooting.
  owl(
    SoundGroup.animals,
    'Owl',
    appleLabels: ['owl_hoot'],
    yamnetLabels: ['Owl', 'Hoot'],
  ),

  /// Rats or mice.
  rodent(
    SoundGroup.animals,
    'Rodent',
    yamnetLabels: ['Rodents, rats, mice', 'Mouse'],
  ),

  /// An insect, when no more specific insect sound is recognized.
  insect(
    SoundGroup.animals,
    'Insect',
    appleLabels: ['insect'],
    yamnetLabels: ['Insect'],
  ),

  /// Crickets chirping.
  cricket(
    SoundGroup.animals,
    'Cricket',
    appleLabels: ['cricket_chirp'],
    yamnetLabels: ['Cricket'],
  ),

  /// A mosquito buzzing.
  mosquito(
    SoundGroup.animals,
    'Mosquito',
    appleLabels: ['mosquito_buzz'],
    yamnetLabels: ['Mosquito'],
  ),

  /// A fly buzzing.
  fly(
    SoundGroup.animals,
    'Fly',
    appleLabels: ['fly_buzz'],
    yamnetLabels: ['Fly, housefly'],
  ),

  /// A bee or wasp buzzing.
  bee(
    SoundGroup.animals,
    'Bee',
    appleLabels: ['bee_buzz'],
    yamnetLabels: ['Bee, wasp, etc.'],
  ),

  /// A frog croaking.
  frog(
    SoundGroup.animals,
    'Frog',
    appleLabels: ['frog', 'frog_croak'],
    yamnetLabels: ['Frog', 'Croak'],
  ),

  /// A snake hissing or rattling.
  snake(
    SoundGroup.animals,
    'Snake',
    appleLabels: ['snake_hiss', 'snake_rattle'],
    yamnetLabels: ['Snake', 'Rattle'],
  ),

  /// A door opening or closing.
  door(SoundGroup.home, 'Door', appleLabels: ['door'], yamnetLabels: ['Door']),

  /// A doorbell ringing.
  doorbell(
    SoundGroup.home,
    'Doorbell',
    appleLabels: ['door_bell'],
    yamnetLabels: ['Doorbell', 'Ding-dong'],
  ),

  /// A door slamming.
  doorSlam(
    SoundGroup.home,
    'Door slam',
    appleLabels: ['door_slam'],
    yamnetLabels: ['Slam'],
  ),

  /// A sliding door.
  slidingDoor(
    SoundGroup.home,
    'Sliding door',
    appleLabels: ['door_sliding'],
    yamnetLabels: ['Sliding door'],
  ),

  /// Knocking, for example on a door.
  knock(
    SoundGroup.home,
    'Knock',
    appleLabels: ['knock'],
    yamnetLabels: ['Knock'],
  ),

  /// A drawer or cupboard opening or closing.
  drawer(
    SoundGroup.home,
    'Drawer or cupboard',
    appleLabels: ['drawer_open_close'],
    yamnetLabels: ['Cupboard open or close', 'Drawer open or close'],
  ),

  /// Dishes, pots and pans.
  dishes(
    SoundGroup.home,
    'Dishes',
    appleLabels: ['dishes_pots_pans'],
    yamnetLabels: ['Dishes, pots, and pans'],
  ),

  /// Cutlery clinking.
  cutlery(
    SoundGroup.home,
    'Cutlery',
    appleLabels: ['cutlery_silverware'],
    yamnetLabels: ['Cutlery, silverware'],
  ),

  /// Glasses clinking.
  glassClink(
    SoundGroup.home,
    'Glass clink',
    appleLabels: ['glass_clink'],
    yamnetLabels: ['Chink, clink'],
  ),

  /// Glass breaking or shattering.
  glassBreaking(
    SoundGroup.home,
    'Glass breaking',
    appleLabels: ['glass_breaking'],
    yamnetLabels: ['Shatter'],
  ),

  /// Food being chopped.
  choppingFood(
    SoundGroup.home,
    'Chopping food',
    appleLabels: ['chopping_food'],
    yamnetLabels: ['Chopping (food)'],
  ),

  /// Food frying or sizzling.
  frying(
    SoundGroup.home,
    'Frying',
    appleLabels: ['frying_food'],
    yamnetLabels: ['Frying (food)', 'Sizzle'],
  ),

  /// Water boiling.
  boiling(
    SoundGroup.home,
    'Boiling',
    appleLabels: ['boiling'],
    yamnetLabels: ['Boiling'],
  ),

  /// A microwave oven running.
  microwaveOven(
    SoundGroup.home,
    'Microwave oven',
    appleLabels: ['microwave_oven'],
    yamnetLabels: ['Microwave oven'],
  ),

  /// A blender running.
  blender(
    SoundGroup.home,
    'Blender',
    appleLabels: ['blender'],
    yamnetLabels: ['Blender'],
  ),

  /// Water running from a tap.
  waterTap(
    SoundGroup.home,
    'Water tap',
    appleLabels: ['water_tap_faucet'],
    yamnetLabels: ['Water tap, faucet'],
  ),

  /// A sink filling or being used for washing.
  sink(
    SoundGroup.home,
    'Sink',
    appleLabels: ['sink_filling_washing'],
    yamnetLabels: ['Sink (filling or washing)'],
  ),

  /// A bathtub filling or being used for washing.
  bathtub(
    SoundGroup.home,
    'Bathtub',
    appleLabels: ['bathtub_filling_washing'],
    yamnetLabels: ['Bathtub (filling or washing)'],
  ),

  /// A toilet flushing.
  toiletFlush(
    SoundGroup.home,
    'Toilet flush',
    appleLabels: ['toilet_flush'],
    yamnetLabels: ['Toilet flush'],
  ),

  /// A manual or electric toothbrush.
  toothbrush(
    SoundGroup.home,
    'Toothbrush',
    appleLabels: ['toothbrush'],
    yamnetLabels: ['Toothbrush', 'Electric toothbrush'],
  ),

  /// A hair dryer running.
  hairDryer(
    SoundGroup.home,
    'Hair dryer',
    appleLabels: ['hair_dryer'],
    yamnetLabels: ['Hair dryer'],
  ),

  /// An electric shaver running.
  electricShaver(
    SoundGroup.home,
    'Electric shaver',
    appleLabels: ['electric_shaver'],
    yamnetLabels: ['Electric shaver, electric razor'],
  ),

  /// A vacuum cleaner running.
  vacuumCleaner(
    SoundGroup.home,
    'Vacuum cleaner',
    appleLabels: ['vacuum_cleaner'],
    yamnetLabels: ['Vacuum cleaner'],
  ),

  /// An air conditioner running.
  airConditioner(
    SoundGroup.home,
    'Air conditioner',
    appleLabels: ['air_conditioner'],
    yamnetLabels: ['Air conditioning'],
  ),

  /// A mechanical fan running.
  fan(
    SoundGroup.home,
    'Fan',
    appleLabels: ['mechanical_fan'],
    yamnetLabels: ['Mechanical fan'],
  ),

  /// A sewing machine running.
  sewingMachine(
    SoundGroup.home,
    'Sewing machine',
    appleLabels: ['sewing_machine'],
    yamnetLabels: ['Sewing machine'],
  ),

  /// A zipper.
  zipper(
    SoundGroup.home,
    'Zipper',
    appleLabels: ['zipper'],
    yamnetLabels: ['Zipper (clothing)'],
  ),

  /// Keys jangling.
  keys(
    SoundGroup.home,
    'Keys',
    appleLabels: ['keys_jangling'],
    yamnetLabels: ['Keys jangling'],
  ),

  /// A coin dropping.
  coin(
    SoundGroup.home,
    'Coin',
    appleLabels: ['coin_dropping'],
    yamnetLabels: ['Coin (dropping)'],
  ),

  /// Typing on a keyboard or typewriter.
  typing(
    SoundGroup.home,
    'Typing',
    appleLabels: ['typing', 'typing_computer_keyboard', 'typewriter'],
    yamnetLabels: ['Typing', 'Typewriter', 'Computer keyboard'],
  ),

  /// Writing with a pen or pencil.
  writing(
    SoundGroup.home,
    'Writing',
    appleLabels: ['writing'],
    yamnetLabels: ['Writing'],
  ),

  /// A printer running.
  printer(
    SoundGroup.home,
    'Printer',
    appleLabels: ['printer'],
    yamnetLabels: ['Printer'],
  ),

  /// A telephone ringing.
  telephone(
    SoundGroup.home,
    'Telephone',
    appleLabels: ['telephone', 'telephone_bell_ringing'],
    yamnetLabels: ['Telephone', 'Telephone bell ringing'],
  ),

  /// A phone ringtone.
  ringtone(
    SoundGroup.home,
    'Ringtone',
    appleLabels: ['ringtone'],
    yamnetLabels: ['Ringtone'],
  ),

  /// A clock ticking.
  clock(
    SoundGroup.home,
    'Clock',
    appleLabels: ['clock', 'tick', 'tick_tock'],
    yamnetLabels: ['Clock', 'Tick', 'Tick-tock'],
  ),

  /// A television playing.
  television(SoundGroup.home, 'Television', yamnetLabels: ['Television']),

  /// A radio playing.
  radio(SoundGroup.home, 'Radio', yamnetLabels: ['Radio']),

  /// A smoke or fire alarm sounding.
  ///
  /// Neither backend has a separate carbon monoxide label: a CO alarm is
  /// reported as [smokeAlarm], [beep] or [alarm], depending on its pattern.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  smokeAlarm(
    SoundGroup.alarms,
    'Smoke alarm',
    appleLabels: ['smoke_detector'],
    yamnetLabels: ['Smoke detector, smoke alarm', 'Fire alarm'],
  ),

  /// An alarm, when no more specific alarm is recognized.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  alarm(SoundGroup.alarms, 'Alarm', yamnetLabels: ['Alarm']),

  /// An alarm clock ringing.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  alarmClock(
    SoundGroup.alarms,
    'Alarm clock',
    appleLabels: ['alarm_clock'],
    yamnetLabels: ['Alarm clock'],
  ),

  /// A car alarm sounding.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  carAlarm(SoundGroup.alarms, 'Car alarm', yamnetLabels: ['Car alarm']),

  /// A siren or emergency vehicle, when no more specific siren is recognized.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  siren(
    SoundGroup.alarms,
    'Siren',
    appleLabels: ['siren', 'emergency_vehicle'],
    yamnetLabels: ['Emergency vehicle', 'Siren'],
  ),

  /// A police car siren.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  policeSiren(
    SoundGroup.alarms,
    'Police siren',
    appleLabels: ['police_siren'],
    yamnetLabels: ['Police car (siren)'],
  ),

  /// An ambulance siren.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  ambulanceSiren(
    SoundGroup.alarms,
    'Ambulance siren',
    appleLabels: ['ambulance_siren'],
    yamnetLabels: ['Ambulance (siren)'],
  ),

  /// A fire engine siren.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  fireEngineSiren(
    SoundGroup.alarms,
    'Fire engine siren',
    appleLabels: ['fire_engine_siren'],
    yamnetLabels: ['Fire engine, fire truck (siren)'],
  ),

  /// A civil defense or air raid siren.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  civilDefenseSiren(
    SoundGroup.alarms,
    'Civil defense siren',
    appleLabels: ['civil_defense_siren'],
    yamnetLabels: ['Civil defense siren'],
  ),

  /// A buzzer sounding.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  buzzer(SoundGroup.alarms, 'Buzzer', yamnetLabels: ['Buzzer']),

  /// A beep or bleep, for example from an appliance or an alarm.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  beep(
    SoundGroup.alarms,
    'Beep',
    appleLabels: ['beep'],
    yamnetLabels: ['Beep, bleep'],
  ),

  /// A vehicle reversing alarm.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  reversingBeeps(
    SoundGroup.alarms,
    'Reversing beeps',
    appleLabels: ['reverse_beeps'],
    yamnetLabels: ['Reversing beeps'],
  ),

  /// A foghorn sounding.
  ///
  /// earshot is informational and is not a certified detector. It must not
  /// replace a certified smoke or carbon monoxide alarm.
  foghorn(
    SoundGroup.alarms,
    'Foghorn',
    appleLabels: ['foghorn'],
    yamnetLabels: ['Foghorn'],
  ),

  /// A car driving or passing by.
  car(
    SoundGroup.vehicles,
    'Car',
    appleLabels: ['car_passing_by'],
    yamnetLabels: ['Car', 'Car passing by'],
  ),

  /// A car horn honking.
  carHorn(
    SoundGroup.vehicles,
    'Car horn',
    appleLabels: ['car_horn'],
    yamnetLabels: ['Vehicle horn, car horn, honking', 'Toot'],
  ),

  /// A truck air horn.
  airHorn(
    SoundGroup.vehicles,
    'Air horn',
    appleLabels: ['air_horn'],
    yamnetLabels: ['Air horn, truck horn'],
  ),

  /// A truck.
  truck(
    SoundGroup.vehicles,
    'Truck',
    appleLabels: ['truck'],
    yamnetLabels: ['Truck'],
  ),

  /// A bus.
  bus(SoundGroup.vehicles, 'Bus', appleLabels: ['bus'], yamnetLabels: ['Bus']),

  /// A motorcycle.
  motorcycle(
    SoundGroup.vehicles,
    'Motorcycle',
    appleLabels: ['motorcycle'],
    yamnetLabels: ['Motorcycle'],
  ),

  /// An engine starting, idling, revving or knocking.
  engine(
    SoundGroup.vehicles,
    'Engine',
    appleLabels: [
      'engine',
      'engine_idling',
      'engine_starting',
      'engine_accelerating_revving',
      'engine_knocking',
    ],
    yamnetLabels: [
      'Engine',
      'Light engine (high frequency)',
      'Medium engine (mid frequency)',
      'Heavy engine (low frequency)',
      'Engine knocking',
      'Engine starting',
      'Idling',
      'Accelerating, revving, vroom',
    ],
  ),

  /// Tires skidding or squealing.
  skidding(
    SoundGroup.vehicles,
    'Skidding',
    appleLabels: ['vehicle_skidding'],
    yamnetLabels: ['Skidding', 'Tire squeal'],
  ),

  /// Road traffic noise.
  trafficNoise(
    SoundGroup.vehicles,
    'Traffic noise',
    appleLabels: ['traffic_noise'],
    yamnetLabels: ['Traffic noise, roadway noise'],
  ),

  /// A train or railway car.
  train(
    SoundGroup.vehicles,
    'Train',
    appleLabels: [
      'train',
      'rail_transport',
      'railroad_car',
      'train_wheels_squealing',
    ],
    yamnetLabels: [
      'Rail transport',
      'Train',
      'Railroad car, train wagon',
      'Train wheels squealing',
    ],
  ),

  /// A train horn or whistle.
  trainHorn(
    SoundGroup.vehicles,
    'Train horn',
    appleLabels: ['train_horn', 'train_whistle'],
    yamnetLabels: ['Train whistle', 'Train horn'],
  ),

  /// A subway or metro train.
  subway(
    SoundGroup.vehicles,
    'Subway',
    appleLabels: ['subway_metro'],
    yamnetLabels: ['Subway, metro, underground'],
  ),

  /// An airplane or its engine.
  aircraft(
    SoundGroup.vehicles,
    'Aircraft',
    appleLabels: ['aircraft', 'airplane'],
    yamnetLabels: [
      'Aircraft',
      'Aircraft engine',
      'Jet engine',
      'Propeller, airscrew',
      'Fixed-wing aircraft, airplane',
    ],
  ),

  /// A helicopter.
  helicopter(
    SoundGroup.vehicles,
    'Helicopter',
    appleLabels: ['helicopter'],
    yamnetLabels: ['Helicopter'],
  ),

  /// A boat or ship.
  boat(
    SoundGroup.vehicles,
    'Boat',
    appleLabels: [
      'boat_water_vehicle',
      'motorboat_speedboat',
      'rowboat_canoe_kayak',
      'sailing',
    ],
    yamnetLabels: [
      'Boat, Water vehicle',
      'Sailboat, sailing ship',
      'Rowboat, canoe, kayak',
      'Motorboat, speedboat',
      'Ship',
    ],
  ),

  /// A bicycle.
  bicycle(
    SoundGroup.vehicles,
    'Bicycle',
    appleLabels: ['bicycle'],
    yamnetLabels: ['Bicycle'],
  ),

  /// A bicycle bell ringing.
  bicycleBell(
    SoundGroup.vehicles,
    'Bicycle bell',
    appleLabels: ['bicycle_bell'],
    yamnetLabels: ['Bicycle bell'],
  ),

  /// A skateboard rolling.
  skateboard(
    SoundGroup.vehicles,
    'Skateboard',
    appleLabels: ['skateboard'],
    yamnetLabels: ['Skateboard'],
  ),

  /// A drill running.
  drill(
    SoundGroup.tools,
    'Drill',
    appleLabels: ['drill'],
    yamnetLabels: ['Drill'],
  ),

  /// A hammer striking.
  hammer(
    SoundGroup.tools,
    'Hammer',
    appleLabels: ['hammer'],
    yamnetLabels: ['Hammer'],
  ),

  /// Sawing.
  saw(SoundGroup.tools, 'Saw', appleLabels: ['saw'], yamnetLabels: ['Sawing']),

  /// A chainsaw running.
  chainsaw(
    SoundGroup.tools,
    'Chainsaw',
    appleLabels: ['chainsaw'],
    yamnetLabels: ['Chainsaw'],
  ),

  /// A power tool, when no more specific tool is recognized.
  powerTool(
    SoundGroup.tools,
    'Power tool',
    appleLabels: ['power_tool'],
    yamnetLabels: ['Power tool'],
  ),

  /// A jackhammer.
  jackhammer(SoundGroup.tools, 'Jackhammer', yamnetLabels: ['Jackhammer']),

  /// Sanding.
  sanding(SoundGroup.tools, 'Sanding', yamnetLabels: ['Sanding']),

  /// A lawn mower running.
  lawnMower(
    SoundGroup.tools,
    'Lawn mower',
    appleLabels: ['lawn_mower'],
    yamnetLabels: ['Lawn mower'],
  ),

  /// A hedge trimmer running.
  hedgeTrimmer(
    SoundGroup.tools,
    'Hedge trimmer',
    appleLabels: ['hedge_trimmer'],
  ),

  /// Scissors cutting.
  scissors(
    SoundGroup.tools,
    'Scissors',
    appleLabels: ['scissors'],
    yamnetLabels: ['Scissors'],
  ),

  /// Wood being chopped.
  choppingWood(
    SoundGroup.tools,
    'Chopping wood',
    appleLabels: ['chopping_wood'],
    yamnetLabels: ['Chop'],
  ),

  /// Music, when no more specific instrument is recognized.
  music(
    SoundGroup.music,
    'Music',
    appleLabels: ['music'],
    yamnetLabels: ['Music'],
  ),

  /// Someone singing, rapping or chanting, or a choir.
  singing(
    SoundGroup.music,
    'Singing',
    appleLabels: ['singing', 'choir_singing', 'yodeling', 'rapping'],
    yamnetLabels: [
      'Singing',
      'Choir',
      'Yodeling',
      'Chant',
      'Mantra',
      'Child singing',
      'Synthetic singing',
      'Rapping',
    ],
  ),

  /// A guitar, including electric and bass guitars.
  guitar(
    SoundGroup.music,
    'Guitar',
    appleLabels: [
      'guitar',
      'acoustic_guitar',
      'electric_guitar',
      'bass_guitar',
      'steel_guitar_slide_guitar',
      'guitar_strum',
      'guitar_tapping',
    ],
    yamnetLabels: [
      'Guitar',
      'Electric guitar',
      'Bass guitar',
      'Acoustic guitar',
      'Steel guitar, slide guitar',
      'Tapping (guitar technique)',
      'Strum',
    ],
  ),

  /// A banjo.
  banjo(
    SoundGroup.music,
    'Banjo',
    appleLabels: ['banjo'],
    yamnetLabels: ['Banjo'],
  ),

  /// A ukulele.
  ukulele(
    SoundGroup.music,
    'Ukulele',
    appleLabels: ['ukulele'],
    yamnetLabels: ['Ukulele'],
  ),

  /// A piano or electric piano.
  piano(
    SoundGroup.music,
    'Piano',
    appleLabels: ['piano', 'electric_piano', 'keyboard_musical'],
    yamnetLabels: ['Keyboard (musical)', 'Piano', 'Electric piano'],
  ),

  /// An organ.
  organ(
    SoundGroup.music,
    'Organ',
    appleLabels: ['organ', 'electronic_organ', 'hammond_organ'],
    yamnetLabels: ['Organ', 'Electronic organ', 'Hammond organ'],
  ),

  /// A synthesizer.
  synthesizer(
    SoundGroup.music,
    'Synthesizer',
    appleLabels: ['synthesizer'],
    yamnetLabels: ['Synthesizer'],
  ),

  /// Drums or a drum kit.
  drums(
    SoundGroup.music,
    'Drums',
    appleLabels: [
      'drum',
      'drum_kit',
      'snare_drum',
      'bass_drum',
      'timpani',
      'tabla',
    ],
    yamnetLabels: [
      'Drum kit',
      'Drum machine',
      'Drum',
      'Snare drum',
      'Rimshot',
      'Drum roll',
      'Bass drum',
      'Timpani',
      'Tabla',
    ],
  ),

  /// A cymbal or hi-hat.
  cymbal(
    SoundGroup.music,
    'Cymbal',
    appleLabels: ['cymbal', 'hi_hat'],
    yamnetLabels: ['Cymbal', 'Hi-hat'],
  ),

  /// A tambourine.
  tambourine(
    SoundGroup.music,
    'Tambourine',
    appleLabels: ['tambourine'],
    yamnetLabels: ['Tambourine'],
  ),

  /// A xylophone, marimba, glockenspiel, vibraphone or steelpan.
  malletPercussion(
    SoundGroup.music,
    'Mallet percussion',
    appleLabels: [
      'mallet_percussion',
      'marimba_xylophone',
      'glockenspiel',
      'vibraphone',
      'steelpan',
    ],
    yamnetLabels: [
      'Mallet percussion',
      'Marimba, xylophone',
      'Glockenspiel',
      'Vibraphone',
      'Steelpan',
    ],
  ),

  /// A violin or fiddle.
  violin(
    SoundGroup.music,
    'Violin',
    appleLabels: ['violin_fiddle'],
    yamnetLabels: ['Violin, fiddle', 'Pizzicato'],
  ),

  /// A cello.
  cello(
    SoundGroup.music,
    'Cello',
    appleLabels: ['cello'],
    yamnetLabels: ['Cello'],
  ),

  /// A double bass.
  doubleBass(
    SoundGroup.music,
    'Double bass',
    appleLabels: ['double_bass'],
    yamnetLabels: ['Double bass'],
  ),

  /// A harp.
  harp(SoundGroup.music, 'Harp', appleLabels: ['harp'], yamnetLabels: ['Harp']),

  /// A flute.
  flute(
    SoundGroup.music,
    'Flute',
    appleLabels: ['flute'],
    yamnetLabels: ['Flute'],
  ),

  /// A clarinet.
  clarinet(
    SoundGroup.music,
    'Clarinet',
    appleLabels: ['clarinet'],
    yamnetLabels: ['Clarinet'],
  ),

  /// A saxophone.
  saxophone(
    SoundGroup.music,
    'Saxophone',
    appleLabels: ['saxophone'],
    yamnetLabels: ['Saxophone'],
  ),

  /// A trumpet.
  trumpet(
    SoundGroup.music,
    'Trumpet',
    appleLabels: ['trumpet'],
    yamnetLabels: ['Trumpet'],
  ),

  /// A trombone.
  trombone(
    SoundGroup.music,
    'Trombone',
    appleLabels: ['trombone'],
    yamnetLabels: ['Trombone'],
  ),

  /// A French horn.
  frenchHorn(
    SoundGroup.music,
    'French horn',
    appleLabels: ['french_horn'],
    yamnetLabels: ['French horn'],
  ),

  /// An accordion.
  accordion(
    SoundGroup.music,
    'Accordion',
    appleLabels: ['accordion'],
    yamnetLabels: ['Accordion'],
  ),

  /// A harmonica.
  harmonica(
    SoundGroup.music,
    'Harmonica',
    appleLabels: ['harmonica'],
    yamnetLabels: ['Harmonica'],
  ),

  /// Bagpipes.
  bagpipes(
    SoundGroup.music,
    'Bagpipes',
    appleLabels: ['bagpipes'],
    yamnetLabels: ['Bagpipes'],
  ),

  /// An orchestra.
  orchestra(
    SoundGroup.music,
    'Orchestra',
    appleLabels: ['orchestra'],
    yamnetLabels: ['Orchestra'],
  ),

  /// A bell, when no more specific bell is recognized.
  bell(SoundGroup.music, 'Bell', appleLabels: ['bell'], yamnetLabels: ['Bell']),

  /// Church bells ringing.
  churchBell(
    SoundGroup.music,
    'Church bell',
    appleLabels: ['church_bell'],
    yamnetLabels: ['Church bell', 'Change ringing (campanology)'],
  ),

  /// A wind chime.
  windChime(
    SoundGroup.music,
    'Wind chime',
    appleLabels: ['wind_chime'],
    yamnetLabels: ['Wind chime'],
  ),

  /// A gong.
  gong(SoundGroup.music, 'Gong', appleLabels: ['gong'], yamnetLabels: ['Gong']),

  /// Wind blowing.
  wind(
    SoundGroup.nature,
    'Wind',
    appleLabels: ['wind'],
    yamnetLabels: ['Wind'],
  ),

  /// Leaves rustling in the wind.
  rustlingLeaves(
    SoundGroup.nature,
    'Rustling leaves',
    appleLabels: ['wind_rustling_leaves'],
    yamnetLabels: ['Rustling leaves'],
  ),

  /// Rain falling.
  rain(
    SoundGroup.nature,
    'Rain',
    appleLabels: ['rain', 'raindrop'],
    yamnetLabels: ['Rain', 'Raindrop', 'Rain on surface'],
  ),

  /// Thunder or a thunderstorm.
  thunder(
    SoundGroup.nature,
    'Thunder',
    appleLabels: ['thunder', 'thunderstorm'],
    yamnetLabels: ['Thunderstorm', 'Thunder'],
  ),

  /// A stream or brook.
  stream(
    SoundGroup.nature,
    'Stream',
    appleLabels: ['stream_burbling'],
    yamnetLabels: ['Stream'],
  ),

  /// A waterfall.
  waterfall(
    SoundGroup.nature,
    'Waterfall',
    appleLabels: ['waterfall'],
    yamnetLabels: ['Waterfall'],
  ),

  /// Ocean waves or surf.
  ocean(
    SoundGroup.nature,
    'Ocean',
    appleLabels: ['ocean', 'sea_waves'],
    yamnetLabels: ['Ocean', 'Waves, surf'],
  ),

  /// A fire burning or crackling.
  fire(
    SoundGroup.nature,
    'Fire',
    appleLabels: ['fire', 'fire_crackle'],
    yamnetLabels: ['Fire', 'Crackle'],
  ),

  /// A gunshot or gunfire.
  gunshot(
    SoundGroup.other,
    'Gunshot',
    appleLabels: ['gunshot_gunfire', 'artillery_fire'],
    yamnetLabels: [
      'Gunshot, gunfire',
      'Machine gun',
      'Fusillade',
      'Artillery fire',
      'Cap gun',
    ],
  ),

  /// An explosion or boom.
  explosion(
    SoundGroup.other,
    'Explosion',
    appleLabels: ['boom'],
    yamnetLabels: ['Explosion', 'Boom'],
  ),

  /// Fireworks or firecrackers.
  fireworks(
    SoundGroup.other,
    'Fireworks',
    appleLabels: ['fireworks', 'firecracker'],
    yamnetLabels: ['Fireworks', 'Firecracker'],
  );

  new(
    this.group,
    this.displayName, {
    this.appleLabels = const [],
    this.yamnetLabels = const [],
  });

  /// The group this sound belongs to.
  final SoundGroup group;

  /// A short English name for this sound, such as `Dog bark`. Not localized.
  final String displayName;

  /// The [ClassifierBackend.apple] labels that map to this sound. Empty if
  /// SoundAnalysis cannot recognize it.
  final List<String> appleLabels;

  /// The [ClassifierBackend.yamnet] labels that map to this sound. Empty if
  /// YAMNet cannot recognize it.
  final List<String> yamnetLabels;

  /// The labels of [backend] that map to this sound.
  List<String> labelsOf(ClassifierBackend backend) => switch (backend) {
    ClassifierBackend.apple => appleLabels,
    ClassifierBackend.yamnet => yamnetLabels,
  };

  /// Whether [backend] can recognize this sound.
  bool isSupportedBy(ClassifierBackend backend) => labelsOf(backend).isNotEmpty;
}
