class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'isCompleted': isCompleted};
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id:
          (map['id'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      text: (map['text'] as String?) ?? '',
      isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
    );
  }

  ChecklistItem copyWith({String? id, String? text, bool? isCompleted}) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
