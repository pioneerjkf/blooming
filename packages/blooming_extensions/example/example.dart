import 'package:blooming/effect.dart';
import 'package:blooming_extensions/blooming_extensions.dart';

void main() async {
  // 1. Create a reactive controller holding a collection of numbers
  final numbersController = blooming<List<double>>([10.0, 20.0, 30.0]);

  // 2. Use blooming_extensions to calculate reactive sum and average
  final sumBloom = numbersController.bloom.elements.sum;
  final avgBloom = numbersController.bloom.elements.average;

  // 3. Actively observe collection aggregations using EffectRunner
  final sumRunner =
      sumBloom.effect(() => print('Sum: ${untracked(sumBloom)}')).start();
  final avgRunner =
      avgBloom.effect(() => print('Average: ${untracked(avgBloom)}')).start();

  // 4. Update collection reactively
  numbersController.set([5.0, 15.0, 25.0, 35.0]);

  // 5. Await microtask flush
  await Future<void>.delayed(Duration.zero);

  // 6. Cleanup
  sumRunner.stop();
  avgRunner.stop();
}
