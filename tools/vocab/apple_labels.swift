// Prints the labels of Apple's built-in sound classifier, one per line.
//
// Regenerate tools/vocab/apple_labels.txt on a Mac (macOS 12 or later):
//
//   swift tools/vocab/apple_labels.swift > tools/vocab/apple_labels.txt
//
// The list depends on the classifier version, not on the OS, so it only
// changes when earshot moves to a newer SNClassifierIdentifier.

import SoundAnalysis

let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
for label in request.knownClassifications.sorted() {
  print(label)
}
