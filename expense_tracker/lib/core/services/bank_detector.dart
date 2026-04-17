/// Detects which bank sent the SMS and returns a stable bank key.
class BankDetector {
  BankDetector._();

  static const String unknown = 'Generic';

  static const _patterns = <String, List<String>>{
    'UCB':         ['UCB', 'United Commercial'],
    'DBBL':        ['DBBL', 'Dutch-Bangla', 'Dutch Bangla', 'Rocket'],
    'BRAC':        ['BRAC', 'bKash'],
    'CityBank':    ['City Bank', 'CityBank', 'City Alo'],
    'EBL':         ['EBL', 'Eastern Bank'],
    'HSBC':        ['HSBC'],
    'Islami':      ['IBBL', 'Islami Bank'],
    'AB':          ['AB Bank'],
    'Mutual':      ['Mutual Trust', 'MTB'],
    'Prime':       ['Prime Bank'],
    'Southeast':   ['Southeast Bank', 'SEBL'],
    'NexusPay':    ['NexusPay'],
    'Nagad':       ['Nagad', 'nogod'],
    'SCB':         ['SCB', 'Standard Chartered'],
    'Sonali':      ['Sonali Bank'],
    'Janata':      ['Janata Bank'],
    'Agrani':      ['Agrani Bank'],
  };

  static String detect(String sms) {
    for (final entry in _patterns.entries) {
      for (final keyword in entry.value) {
        if (sms.toLowerCase().contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return unknown;
  }

  static bool isBangladeshiBank(String sms) => detect(sms) != unknown;
}
