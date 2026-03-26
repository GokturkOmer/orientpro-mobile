import 'package:flutter_test/flutter_test.dart';
import 'package:orientpro_mobile/models/training.dart';

void main() {
  group('TrainingRoute Model', () {
    test('fromJson - tam veri', () {
      final json = {
        'id': 'route-uuid',
        'department_id': 'dept-uuid',
        'title': 'Genel Oryantasyon',
        'description': 'Yeni calisanlar icin temel egitim',
        'difficulty': 'beginner',
        'estimated_minutes': 120,
        'is_mandatory': true,
        'is_active': true,
      };

      final route = TrainingRoute.fromJson(json);

      expect(route.id, 'route-uuid');
      expect(route.title, 'Genel Oryantasyon');
      expect(route.difficulty, 'beginner');
      expect(route.estimatedMinutes, 120);
      expect(route.isMandatory, true);
    });

    test('fromJson - default degerler', () {
      final json = {
        'id': 'r1',
        'department_id': 'd1',
        'title': 'Test Route',
      };

      final route = TrainingRoute.fromJson(json);

      expect(route.id, 'r1');
      expect(route.title, 'Test Route');
      expect(route.difficulty, 'beginner');
      expect(route.estimatedMinutes, 60);
    });

    test('difficultyText - Turkce karsilik', () {
      final route = TrainingRoute.fromJson({
        'id': 'r1',
        'department_id': 'd1',
        'title': 'Test',
        'difficulty': 'beginner',
      });
      expect(route.difficultyText, isNotEmpty);
    });
  });

  group('TrainingModule Model', () {
    test('fromJson - tam veri', () {
      final json = {
        'id': 'module-uuid',
        'route_id': 'route-uuid',
        'title': 'Is Guvenligi',
        'description': 'Temel is guvenligi kurallari',
        'module_type': 'reading',
        'estimated_minutes': 30,
        'sort_order': 1,
        'is_active': true,
      };

      final module = TrainingModule.fromJson(json);

      expect(module.id, 'module-uuid');
      expect(module.title, 'Is Guvenligi');
      expect(module.moduleType, 'reading');
      expect(module.estimatedMinutes, 30);
    });
  });

  group('UserProgress Model', () {
    test('fromJson - tamamlanmis modul', () {
      final json = {
        'id': 'prog-uuid',
        'user_id': 'user-uuid',
        'module_id': 'module-uuid',
        'status': 'completed',
        'progress_percent': 100.0,
        'time_spent_minutes': 25,
      };

      final progress = UserProgress.fromJson(json);

      expect(progress.status, 'completed');
      expect(progress.progressPercent, 100.0);
      expect(progress.timeSpentMinutes, 25);
    });

    test('fromJson - devam eden modul', () {
      final json = {
        'id': 'p1',
        'user_id': 'u1',
        'module_id': 'm1',
        'status': 'in_progress',
        'progress_percent': 50.0,
      };

      final progress = UserProgress.fromJson(json);

      expect(progress.status, 'in_progress');
      expect(progress.progressPercent, 50.0);
    });
  });

  group('QuizResult Model', () {
    test('fromJson - basarili quiz', () {
      final json = {
        'id': 'qr-uuid',
        'quiz_id': 'quiz-uuid',
        'user_id': 'user-uuid',
        'score': 85,
        'max_score': 100,
        'passed': true,
        'attempt_number': 1,
      };

      final result = QuizResult.fromJson(json);

      expect(result.score, 85);
      expect(result.maxScore, 100);
      expect(result.passed, true);
    });

    test('fromJson - basarisiz quiz', () {
      final json = {
        'id': 'qr2',
        'quiz_id': 'q1',
        'user_id': 'u1',
        'score': 30,
        'max_score': 100,
        'passed': false,
        'attempt_number': 2,
      };

      final result = QuizResult.fromJson(json);

      expect(result.passed, false);
      expect(result.attemptNumber, 2);
    });
  });
}
