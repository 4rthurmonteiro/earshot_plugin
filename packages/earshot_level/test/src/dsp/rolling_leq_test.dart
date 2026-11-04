import 'package:earshot_level/src/dsp/rolling_leq.dart';
import 'package:test/test.dart';

void main() {
  group(RollingLeq, () {
    test('exposes its window length', () {
      expect(RollingLeq(4).binCount, 4);
    });

    test('averages the bins seen so far before the window fills', () {
      final leq = RollingLeq(4)
        ..addBin(1)
        ..addBin(3);
      expect(leq.meanSquare(partialMeanSquare: 0, partialFraction: 0), 2);
      // Half a bin of 6 adds half a bin's weight.
      expect(
        leq.meanSquare(partialMeanSquare: 6, partialFraction: 0.5),
        (1 + 3 + 3) / 2.5,
      );
    });

    test('covers only the partial bin before any bin completes', () {
      final leq = RollingLeq(4);
      expect(leq.meanSquare(partialMeanSquare: 5, partialFraction: 0.2), 5);
    });

    test('spans exactly the window once full', () {
      final leq = RollingLeq(4)
        ..addBin(1)
        ..addBin(2)
        ..addBin(3)
        ..addBin(4);
      expect(leq.meanSquare(partialMeanSquare: 0, partialFraction: 0), 2.5);
      // A quarter of a new bin of 9 replaces a quarter of the oldest bin (1).
      expect(
        leq.meanSquare(partialMeanSquare: 9, partialFraction: 0.25),
        (1 + 2 + 3 + 4 + (9 - 1) * 0.25) / 4,
      );
    });

    test('drops the oldest bin as new ones arrive', () {
      final leq = RollingLeq(2)
        ..addBin(10)
        ..addBin(2)
        ..addBin(4);
      expect(leq.meanSquare(partialMeanSquare: 0, partialFraction: 0), 3);
      // The oldest bin is now 2.
      expect(
        leq.meanSquare(partialMeanSquare: 6, partialFraction: 0.5),
        (2 + 4 + (6 - 2) * 0.5) / 2,
      );
    });
  });
}
