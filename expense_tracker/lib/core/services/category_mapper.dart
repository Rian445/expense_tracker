/// Maps merchant names to app expense categories automatically.
class CategoryMapper {
  CategoryMapper._();

  /// Maps (lowercase keyword → category name)
  static const _map = <String, String>{
    // Groceries
    'agora':        'Groceries',
    'swapno':       'Groceries',
    'meena bazar':  'Groceries',
    'shajgoj':      'Groceries',
    'chaldal':      'Groceries',
    // Food & Dining
    'kfc':          'Food',
    'pizza hut':    'Food',
    'pizza':        'Food',
    'burger':       'Food',
    'restaurant':   'Food',
    'café':         'Food',
    'cafe':         'Food',
    'food':         'Food',
    'domino':       'Food',
    'hunger':       'Food',
    'pathao food':  'Food',
    'shohoz food':  'Food',
    'foodpanda':    'Food',
    // Transport
    'uber':         'Transport',
    'pathao':       'Transport',
    'shohoz':       'Transport',
    'obhai':        'Transport',
    'fuel':         'Transport',
    'petrol':       'Transport',
    'cng':          'Transport',
    'fare':         'Transport',
    // Shopping
    'daraz':        'Shopping',
    'pickaboo':     'Shopping',
    'shein':        'Shopping',
    'amazon':       'Shopping',
    'evaly':        'Shopping',
    'aarong':       'Shopping',
    // Utilities
    'desco':        'Utilities',
    'dpdc':         'Utilities',
    'titas':        'Utilities',
    'wasa':         'Utilities',
    'internet':     'Utilities',
    'gp':           'Utilities',
    'robi':         'Utilities',
    'banglalink':   'Utilities',
    'grameenphone': 'Utilities',
    'teletalk':     'Utilities',
    'airtel':       'Utilities',
    'electricity':  'Utilities',
    'water':        'Utilities',
    'bill':         'Utilities',
    'recharge':     'Utilities',
    'topup':        'Utilities',
    'flexiload':    'Utilities',
    'bundle':       'Utilities',
    'pack':         'Utilities',
    // Healthcare
    'pharmacy':     'Healthcare',
    'pharma':       'Healthcare',
    'hospital':     'Healthcare',
    'clinic':       'Healthcare',
    'square':       'Healthcare',
    'ibn sina':     'Healthcare',
    'labaid':       'Healthcare',
    'diagnostic':   'Healthcare',
    // Education
    'university':   'Education',
    'school':       'Education',
    'college':      'Education',
    'tuition':      'Education',
    // Entertainment
    'netflix':      'Entertainment',
    'youtube':      'Entertainment',
    'spotify':      'Entertainment',
    'cinema':       'Entertainment',
    'star cineplex':'Entertainment',
    // Finance
    'service charge':'Finance',
    'fee':          'Finance',
    'bank':         'Finance',
  };

  static String map(String? merchant, [String? smsBody]) {
    final m = merchant?.toLowerCase() ?? '';
    final context = smsBody?.toLowerCase() ?? '';

    // Priority 1: Check phone number
    if (RegExp(r'^01[3-9]\d{8}$').hasMatch(m.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Utilities';
    }

    // Priority 2: Direct merchant match
    if (m.isNotEmpty) {
      for (final entry in _map.entries) {
        if (m.contains(entry.key)) return entry.value;
      }
    }

    // Priority 3: Smart context match (scanning the SMS body)
    if (context.isNotEmpty) {
      for (final entry in _map.entries) {
        // Skip generic words like 'bill' for context matching 
        // to avoid over-categorizing generic bank alerts.
        if (entry.key == 'bill') continue;
        
        if (context.contains(entry.key)) return entry.value;
      }
    }

    return 'Other';
  }

  /// Returns a clean title-cased merchant name.
  static String clean(String raw) {
    return raw
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
