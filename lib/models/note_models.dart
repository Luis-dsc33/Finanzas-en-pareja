import 'package:flutter/material.dart';

enum NoteType { personal, group }

class NoteItem {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final NoteType type;
  final DateTime? reminderTime;
  final Color color;
  final DateTime createdAt;

  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.type,
    this.reminderTime,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'type': type == NoteType.personal ? 'personal' : 'group',
      'reminderTime': reminderTime?.toIso8601String(),
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      type: map['type'] == 'group' ? NoteType.group : NoteType.personal,
      reminderTime: map['reminderTime'] != null ? DateTime.parse(map['reminderTime']) : null,
      color: Color(map['color'] ?? Colors.yellow.value),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
