/// User type enum matching the backend UserType.
enum UserType {
  deaf,
  hearing,
  parent,
  teacher;

  /// Parse from backend string representation.
  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'deaf':
        return UserType.deaf;
      case 'hearing':
        return UserType.hearing;
      case 'parent':
        return UserType.parent;
      case 'teacher':
        return UserType.teacher;
      default:
        return UserType.hearing;
    }
  }
}
