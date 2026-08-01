// Customer-service notes come back from the API as a list of objects
// (e.g. `{ "remark": "...", "createdAt": "...", ... }`), not plain strings.
// These helpers pull out just the `remark` text for display.
String csNoteRemark(dynamic note) {
  if (note is Map) {
    return (note['remark'] ?? '').toString();
  }
  return note?.toString() ?? '';
}

List<String> csNotesToRemarks(List? csNotes) {
  if (csNotes == null) return [];
  return csNotes
      .map(csNoteRemark)
      .where((remark) => remark.isNotEmpty)
      .toList();
}
