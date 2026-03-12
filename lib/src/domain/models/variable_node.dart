class VariableNode {
  final String name;
  final String typeName;
  final String displayValue;
  final String? objectId;
  final bool isExpandable;
  final String? libraryName;

  const VariableNode({
    required this.name,
    required this.typeName,
    required this.displayValue,
    this.objectId,
    this.isExpandable = false,
    this.libraryName,
  });
}
