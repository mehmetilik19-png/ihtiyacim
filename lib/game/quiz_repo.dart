import 'dart:math';
import 'question_bank.dart';
import 'quiz_question.dart';

class QuizRepo {
  List<QuizQuestion> _ordered = const [];

  Future<void> init({required int seed}) async {
    final list = List<QuizQuestion>.from(QuestionBank.all());
    list.shuffle(Random(seed));
    _ordered = list;
  }

  QuizQuestion at(int pos) {
    if (_ordered.isEmpty) {
      // init unutulursa patlamasın diye
      return QuestionBank.all().first;
    }
    return _ordered[pos % _ordered.length];
  }

  int get length => _ordered.length;
}