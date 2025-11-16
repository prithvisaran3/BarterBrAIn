import 'dart:io';

/// Run this from Flutter app context to seed universities
///
/// Usage: flutter run tools/seed_via_app.dart
void main() async {
  // Sample universities for testing
  final universities = [
    {
      'id': 'stanford',
      'name': 'Stanford University',
      'domains': ['stanford.edu'],
      'state': 'CA',
      'country': 'US',
    },
    {
      'id': 'mit',
      'name': 'Massachusetts Institute of Technology',
      'domains': ['mit.edu'],
      'state': 'MA',
      'country': 'US',
    },
    {
      'id': 'harvard',
      'name': 'Harvard University',
      'domains': ['harvard.edu'],
      'state': 'MA',
      'country': 'US',
    },
    {
      'id': 'berkeley',
      'name': 'University of California, Berkeley',
      'domains': ['berkeley.edu'],
      'state': 'CA',
      'country': 'US',
    },
    {
      'id': 'yale',
      'name': 'Yale University',
      'domains': ['yale.edu'],
      'state': 'CT',
      'country': 'US',
    },
  ];

  print('Copy and paste this into Firebase Console → Firestore:');
  print('');
  print('Collection: universities');
  print('');

  for (var uni in universities) {
    print('---');
    print('Document ID: ${uni['id']}');
    print('Fields:');
    print('  name (string): ${uni['name']}');
    final domains = uni['domains'] as List<String>;
    print('  domains (array): [${domains.join(', ')}]');
    print('  state (string): ${uni['state']}');
    print('  country (string): ${uni['country']}');
    print('');
  }

  exit(0);
}
