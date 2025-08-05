import 'package:flutter_test/flutter_test.dart';
import 'package:snack_hack_app/data/models/group_model.dart';

void main() {
  group('Group Model Tests', () {
    test('should create a valid Group', () {
      final group = Group(
        id: 'test_group_id',
        name: 'Test Group',
        description: 'Test Description',
        createdBy: 'admin_id',
        members: ['member1', 'member2', 'admin_id'],
        admins: ['admin_id'],
        inviteCode: 'TEST123',
        createdAt: DateTime(2024, 1, 1),
        maxMembers: 10,
      );

      expect(group.id, equals('test_group_id'));
      expect(group.name, equals('Test Group'));
      expect(group.description, equals('Test Description'));
      expect(group.createdBy, equals('admin_id'));
      expect(group.members, containsAll(['member1', 'member2', 'admin_id']));
      expect(group.admins, contains('admin_id'));
      expect(group.inviteCode, equals('TEST123'));
      expect(group.maxMembers, equals(10));
    });

    test('should convert Group to map and back', () {
      final originalGroup = Group(
        id: 'test_group_id',
        name: 'Test Group',
        description: 'Test Description',
        createdBy: 'admin_id',
        members: ['member1', 'member2'],
        admins: ['admin_id'],
        inviteCode: 'TEST123',
        createdAt: DateTime(2024, 1, 1),
        maxMembers: 5,
      );

      final map = originalGroup.toMap();
      final restoredGroup = Group.fromMap(map);

      expect(restoredGroup.id, equals(originalGroup.id));
      expect(restoredGroup.name, equals(originalGroup.name));
      expect(restoredGroup.description, equals(originalGroup.description));
      expect(restoredGroup.createdBy, equals(originalGroup.createdBy));
      expect(restoredGroup.members, equals(originalGroup.members));
      expect(restoredGroup.admins, equals(originalGroup.admins));
      expect(restoredGroup.maxMembers, equals(originalGroup.maxMembers));
    });

    test('should check if user is admin', () {
      final group = Group(
        id: 'test_group_id',
        name: 'Test Group',
        description: 'Test Description',
        createdBy: 'admin_id',
        members: ['member1', 'admin_id'],
        admins: ['admin_id'],
        inviteCode: 'TEST123',
        createdAt: DateTime.now(),
        maxMembers: 10,
      );

      expect(group.isAdmin('admin_id'), isTrue);
      expect(group.isAdmin('member1'), isFalse);
      expect(group.isAdmin('non_member'), isFalse);
    });

    test('should check if user is member', () {
      final group = Group(
        id: 'test_group_id',
        name: 'Test Group',
        description: 'Test Description',
        createdBy: 'admin_id',
        members: ['member1', 'member2'],
        admins: ['admin_id'],
        inviteCode: 'TEST123',
        createdAt: DateTime.now(),
        maxMembers: 10,
      );

      expect(group.isMember('member1'), isTrue);
      expect(group.isMember('member2'), isTrue);
      expect(group.isMember('non_member'), isFalse);
    });

    test('should check if group is full', () {
      final fullGroup = Group(
        id: 'test_group_id',
        name: 'Test Group',
        description: 'Test Description',
        createdBy: 'admin_id',
        members: ['member1', 'member2'],
        admins: ['admin_id'],
        inviteCode: 'TEST123',
        createdAt: DateTime.now(),
        maxMembers: 2,
      );

      final notFullGroup = Group(
        id: 'test_group_id',
        name: 'Test Group',
        description: 'Test Description',
        createdBy: 'admin_id',
        members: ['member1'],
        admins: ['admin_id'],
        inviteCode: 'TEST123',
        createdAt: DateTime.now(),
        maxMembers: 5,
      );

      expect(fullGroup.isFull, isTrue);
      expect(notFullGroup.isFull, isFalse);
    });

    test('should handle default maxMembers value', () {
      final group = Group(
        id: 'test_group_id',
        name: 'Test Group',
        description: 'Test Description',
        createdBy: 'admin_id',
        members: ['member1'],
        admins: ['admin_id'],
        inviteCode: 'TEST123',
        createdAt: DateTime.now(),
      );

      expect(group.maxMembers, equals(20)); // Default value
    });
  });
}
