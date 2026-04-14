// class_type.dart — supertype enum for domain classes and data models
//
// A class type is a domain model, registry, or data structure
// (e.g. WorkRegistry, BranchItem, ReminderItem).
// Each ClassType value declares which features and components use it,
// so the matrix knows which model variants need testing per feature.
//
// Example (in zedup):
//   enum ZedClass implements ClassType {
//     workRegistry(description: 'Typed JSON registry — branches + reminders per profile'),
//     branchItem(description: 'Single branch work item — type, status, ticket, title'),
//     reminderItem(description: 'Single reminder item — text, status');
//
//     const ZedClass({required this.description});
//     @override final String description;
//   }

/// Marker interface for class/model enums.
/// Consumer apps implement this on their own class enum.
abstract interface class ClassType {
  String get name;
  String get description;
}
