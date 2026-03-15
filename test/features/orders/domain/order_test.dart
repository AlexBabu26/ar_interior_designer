import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/orders/domain/order.dart';

void main() {
  group('Order', () {
    test('builds from Supabase-style json with order_items', () {
      final order = Order.fromJson({
        'id': 'ord-1',
        'order_number': 'ORD-20260315120000000',
        'status': 'placed',
        'subtotal': 1998.50,
        'total': 1998.50,
        'created_at': '2026-03-15T12:00:00.000Z',
        'order_items': [
          {
            'id': 'oi-1',
            'product_id': 'prod-1',
            'product_name': 'Cloud Sofa',
            'unit_price': 849.50,
            'quantity': 2,
            'line_total': 1699.00,
          },
          {
            'id': 'oi-2',
            'product_id': 'prod-2',
            'product_name': 'Glass Table',
            'unit_price': 299.50,
            'quantity': 1,
            'line_total': 299.50,
          },
        ],
      });

      expect(order.id, 'ord-1');
      expect(order.orderNumber, 'ORD-20260315120000000');
      expect(order.status, 'placed');
      expect(order.subtotal, 1998.50);
      expect(order.total, 1998.50);
      expect(order.createdAt, DateTime.parse('2026-03-15T12:00:00.000Z'));
      expect(order.items.length, 2);
      expect(order.items[0].productName, 'Cloud Sofa');
      expect(order.items[0].quantity, 2);
      expect(order.items[1].productName, 'Glass Table');
    });

    test('builds with empty order_items', () {
      final order = Order.fromJson({
        'id': 'ord-2',
        'order_number': 'ORD-20260315130000000',
        'status': 'placed',
        'subtotal': 0,
        'total': 0,
        'created_at': '2026-03-15T13:00:00.000Z',
        'order_items': [],
      });

      expect(order.items, isEmpty);
    });
  });
}
