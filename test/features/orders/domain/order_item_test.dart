import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/orders/domain/order_item.dart';

void main() {
  group('OrderItem', () {
    test('builds from Supabase-style json', () {
      final item = OrderItem.fromJson({
        'id': 'oi-1',
        'product_id': 'prod-1',
        'product_name': 'Cloud Sofa',
        'unit_price': 849.50,
        'quantity': 2,
        'line_total': 1699.00,
      });

      expect(item.id, 'oi-1');
      expect(item.productId, 'prod-1');
      expect(item.productName, 'Cloud Sofa');
      expect(item.unitPrice, 849.50);
      expect(item.quantity, 2);
      expect(item.lineTotal, 1699.00);
    });

    test('accepts null product_id', () {
      final item = OrderItem.fromJson({
        'id': 'oi-2',
        'product_id': null,
        'product_name': 'Legacy Item',
        'unit_price': 99.00,
        'quantity': 1,
        'line_total': 99.00,
      });

      expect(item.productId, isNull);
      expect(item.productName, 'Legacy Item');
    });
  });
}
