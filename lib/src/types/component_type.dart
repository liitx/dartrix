// component_type.dart — supertype enum for UI components
//
// A component is a renderable unit of the app (widget, screen, row, header).
// Each ComponentType value declares which FeatureTypes use it,
// and which domain enum variants it renders.
//
// The matrix uses this to derive: for every component, which enum variant
// combinations need a render test?
//
// Example (in zedup):
//   enum ZedComponent implements ComponentType {
//     dashboardHeader(description: 'Profile tab strip + active/done counts'),
//     branchRow(description: 'Single branch item row — status + action'),
//     reminderRow(description: 'Single reminder item row'),
//     dashboardFooter(description: 'Context-sensitive key hints');
//
//     const ZedComponent({required this.description});
//     @override final String description;
//   }

/// Marker interface for component enums.
/// Consumer apps implement this on their own component enum.
abstract interface class ComponentType {
  String get name;
  String get description;
}
