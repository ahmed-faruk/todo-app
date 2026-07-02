class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final int sortOrder;

  Todo copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isCompleted == other.isCompleted &&
          createdAt == other.createdAt &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      isCompleted.hashCode ^
      createdAt.hashCode ^
      sortOrder.hashCode;
}
