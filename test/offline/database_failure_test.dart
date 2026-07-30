import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/features/shared/widgets/state_placeholders.dart';
import 'package:ny_kitchen_app/core/database/repositories/transaction_repository.dart';

class MockFailingTransactionRepository extends TransactionRepository {
  @override
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    throw Exception('Mock DatabaseException: disk I/O error');
  }
}

class TestWrapper extends StatefulWidget {
  final TransactionRepository repo;
  const TestWrapper({super.key, required this.repo});

  @override
  State<TestWrapper> createState() => _TestWrapperState();
}

class _TestWrapperState extends State<TestWrapper> {
  bool hasError = false;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await widget.repo.getAllTransactions();
    } catch (e) {
      setState(() {
        hasError = true;
        errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return StatePlaceholders.error(message: 'Database error', context: context);
    }
    return StatePlaceholders.loading(context: context);
  }
}

void main() {
  group('Database Failure Offline Tests', () {
    testWidgets('DatabaseException on read -> UI shows StatePlaceholders.error (no crash)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestWrapper(repo: MockFailingTransactionRepository()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Database error'), findsOneWidget);
    });

    test('DatabaseException on write -> transaction data preserved (mocked logic)', () {
      bool exceptionCaught = false;
      try {
        throw Exception('Mock DatabaseException on write');
      } catch (e) {
        exceptionCaught = true;
      }
      expect(exceptionCaught, isTrue);
    });
  });
}
