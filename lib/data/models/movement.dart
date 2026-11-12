// Modelo de un movimiento (gasto o ingreso). Es la "entrada del diario" de Finto.
import 'entry_metadata.dart';

class Movement {
  final int? id;
  final int userId;
  final String type; // 'gasto' | 'ingreso'
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String invoice; // 'no' | 'pendiente' | 'realizada' (solo gastos)
  final EntryMetadata metadata;

  const Movement({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
    this.invoice = 'no',
    this.metadata = const EntryMetadata(),
  });

  bool get isIncome => type == 'ingreso';

  Movement copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? invoice,
    EntryMetadata? metadata,
  }) {
    return Movement(
      id: id ?? this.id,
      userId: userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      invoice: invoice ?? this.invoice,
      metadata: metadata ?? this.metadata,
    );
  }

  // Fila de SQLite
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'type': type,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'invoice': invoice,
        'metadata': metadata.encode(),
      };

  factory Movement.fromMap(Map<String, dynamic> map) => Movement(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        type: map['type'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        description: (map['description'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        invoice: (map['invoice'] as String?) ?? 'no',
        metadata: EntryMetadata.decode(map['metadata'] as String?),
      );

  // JSON completo (por ejemplo para exportar un respaldo)
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'invoice': invoice,
        'metadata': metadata.toJson(),
      };
}
