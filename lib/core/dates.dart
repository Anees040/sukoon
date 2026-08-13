/// Date helpers shared by pure logic and UI. PURE DART — no Flutter imports.
library;

/// yyyy-MM-dd key used by the tracker/qaza DB — NOT localized, never change.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Midnight-normalized copy (avoids DST edge cases when stepping days).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The previous calendar day, normalized.
DateTime previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);
