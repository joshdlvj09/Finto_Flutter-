// Pruebas de la logica de periodos y del JSON de metadatos
import 'package:finto_flutter/core/utils/periods.dart';
import 'package:finto_flutter/data/models/entry_metadata.dart';
import 'package:finto_flutter/data/models/movement.dart';
import 'package:flutter_test/flutter_test.dart';

Movement _m(String type, double amount, String cat) => Movement(
      userId: 1,
      type: type,
      amount: amount,
      category: cat,
      date: DateTime.now(),
    );

void main() {
  test('totales y balance', () {
    final t = Periods.totals([_m('ingreso', 1000, 'nomina'), _m('gasto', 250, 'comida')]);
    expect(t.income, 1000);
    expect(t.expenses, 250);
    expect(t.balance, 750);
  });

  test('gastos por categoria ordenados con porcentaje', () {
    final r = Periods.byCategory(
        [_m('gasto', 300, 'comida'), _m('gasto', 100, 'ocio'), _m('ingreso', 50, 'otros')], 'gasto');
    expect(r.first.category.id, 'comida');
    expect(r.first.percent, 75);
    expect(r.length, 2);
  });

  test('la semana tiene 7 barras', () {
    final range = Periods.range(PeriodMode.semana, 0);
    expect(Periods.buckets([], PeriodMode.semana, range).length, 7);
  });

  test('metadatos se serializan y leen de JSON', () {
    const meta = EntryMetadata(imagePath: '/a/b.jpg', latitude: 20.97, longitude: -89.62);
    final back = EntryMetadata.decode(meta.encode());
    expect(back.imagePath, '/a/b.jpg');
    expect(back.latitude, 20.97);
    expect(back.hasLocation, true);
  });

  test('JSON roto no truena la app', () {
    final back = EntryMetadata.decode('{esto no es json');
    expect(back.hasImage, false);
    expect(back.hasLocation, false);
  });

  test('movimiento ida y vuelta por SQLite map', () {
    final m = _m('gasto', 99.5, 'comida').copyWith(
        id: 3, metadata: const EntryMetadata(latitude: 1, longitude: 2));
    final back = Movement.fromMap(m.toMap());
    expect(back.amount, 99.5);
    expect(back.metadata.longitude, 2);
  });
}
