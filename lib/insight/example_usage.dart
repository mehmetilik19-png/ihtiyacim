import 'human_response_composer.dart';
import 'context_mapper.dart';

void main() {
  // Örnek: iş yeri düzeni
  final text1 = HumanResponseComposer.compose(
    workResult: 'Düzenlemeyi tamamladım, alan daha akıcı hale geldi.',
    context: mapCategoryToContext('dukkan'),
    workDone: true,
    confidence: 0.82,
  );
  print(text1);

  // Örnek: bazen sadece iş (insight eklemez)
  final text2 = HumanResponseComposer.compose(
    workResult: 'Düzenleme tamamlandı.',
    context: mapCategoryToContext('ev'),
    workDone: true,
    confidence: 0.50,
  );
  print(text2);
}