class DrugInteractionsDB {
  // Drug categories and their common medications
  static const Map<String, List<String>> categories = {
    'NSAIDs': [
      'Aspirin',
      'Ibuprofen',
      'Naproxen',
      'Celecoxib',
      'Diclofenac',
    ],
    'Blood Thinners': [
      'Warfarin',
      'Heparin',
      'Apixaban',
      'Rivaroxaban',
      'Dabigatran',
    ],
    'Blood Pressure': [
      'Lisinopril',
      'Amlodipine',
      'Losartan',
      'Metoprolol',
      'Hydrochlorothiazide',
    ],
    'Diabetes': [
      'Metformin',
      'Insulin',
      'Glipizide',
      'Sitagliptin',
      'Empagliflozin',
    ],
    'Statins': [
      'Simvastatin',
      'Atorvastatin',
      'Rosuvastatin',
      'Pravastatin',
      'Lovastatin',
    ],
    'Antidepressants': [
      'Sertraline',
      'Fluoxetine',
      'Escitalopram',
      'Bupropion',
      'Venlafaxine',
    ],
    'Antibiotics': [
      'Amoxicillin',
      'Azithromycin',
      'Ciprofloxacin',
      'Doxycycline',
      'Cephalexin',
    ],
    'Acid Reducers': [
      'Omeprazole',
      'Pantoprazole',
      'Ranitidine',
      'Famotidine',
      'Esomeprazole',
    ],
  };

  // General interaction rules between drug categories
  static const List<Map<String, dynamic>> categoryInteractions = [
    {
      'categories': ['NSAIDs', 'Blood Thinners'],
      'severity': 'high',
      'description': 'Increased risk of bleeding. Avoid combination if possible.',
    },
    {
      'categories': ['NSAIDs', 'Blood Pressure'],
      'severity': 'medium',
      'description': 'May reduce effectiveness of blood pressure medications.',
    },
    {
      'categories': ['Statins', 'Acid Reducers'],
      'severity': 'medium',
      'description': 'May affect absorption of statins. Space doses apart.',
    },
    {
      'categories': ['Antidepressants', 'NSAIDs'],
      'severity': 'medium',
      'description': 'Increased risk of bleeding. Monitor for signs.',
    },
    {
      'categories': ['Blood Pressure', 'Diabetes'],
      'severity': 'low',
      'description': 'May require more frequent blood sugar monitoring.',
    },
    {
      'categories': ['Antibiotics', 'Acid Reducers'],
      'severity': 'low',
      'description': 'May reduce antibiotic absorption. Space doses apart.',
    },
  ];

  // Specific drug-to-drug interactions
  static const List<Map<String, dynamic>> specificInteractions = [
    {
      'drugs': ['Warfarin', 'Aspirin'],
      'severity': 'high',
      'description': 'Significantly increased risk of bleeding.',
    },
    {
      'drugs': ['Simvastatin', 'Amlodipine'],
      'severity': 'medium',
      'description': 'Increased risk of muscle problems.',
    },
    {
      'drugs': ['Metformin', 'Ciprofloxacin'],
      'severity': 'medium',
      'description': 'May affect blood sugar levels.',
    },
  ];

  // Get category for a drug
  static String? getCategoryForDrug(String drug) {
    for (var entry in categories.entries) {
      if (entry.value.contains(drug)) {
        return entry.key;
      }
    }
    return null;
  }

  // Get all drugs in a category
  static List<String> getDrugsInCategory(String category) {
    return categories[category] ?? [];
  }

  // Get all drugs
  static List<String> getAllDrugs() {
    final Set<String> drugs = {};
    for (var drugList in categories.values) {
      drugs.addAll(drugList);
    }
    return drugs.toList()..sort();
  }

  // Get common side effects for a drug category
  static String getSideEffects(String category) {
    switch (category) {
      case 'NSAIDs':
        return 'Stomach upset, heartburn, increased risk of bleeding';
      case 'Blood Thinners':
        return 'Increased risk of bleeding, bruising';
      case 'Blood Pressure':
        return 'Dizziness, fatigue, dry cough';
      case 'Diabetes':
        return 'Low blood sugar, nausea, weight changes';
      case 'Statins':
        return 'Muscle pain, liver problems, memory issues';
      case 'Antidepressants':
        return 'Nausea, sleep problems, weight changes';
      case 'Antibiotics':
        return 'Diarrhea, nausea, allergic reactions';
      case 'Acid Reducers':
        return 'Headache, nausea, vitamin B12 deficiency';
      default:
        return 'Side effects not listed';
    }
  }
}
