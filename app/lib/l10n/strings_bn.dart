/// Bangla-first UI strings. Instructions, buttons, and framing are Bangla; the
/// English being practiced stays English (it lives in the content, not here).
///
/// Kept as a plain class of constants for v1 — no intl/gen_l10n machinery until
/// a second UI language actually exists. The app speaks in the language of
/// exams (marks), not of "learning".
class Bn {
  const Bn._();

  // App
  static const appName = 'EZPZ Study';

  // Home
  static const homeGreeting = 'চলো আজকের অনুশীলন শুরু করি';
  static const streakDays = 'দিন ধরে চলছে';
  static const startPractice = 'অনুশীলন শুরু করো';
  static const practiceByTopic = 'বিষয় অনুযায়ী অনুশীলন';
  static const vocabularyFlashcards = 'শব্দভাণ্ডার (Flashcard)';
  static const noStreakYet = 'আজই শুরু করো';

  // Topic list
  static const chooseTopic = 'একটি বিষয় বেছে নাও';
  static const questionsAvailable = 'টি প্রশ্ন আছে';
  static const scoreLabel = 'তোমার স্কোর';

  // Session
  static const questionOf = 'প্রশ্ন'; // "প্রশ্ন ৩ / ১০"
  static const checkAnswer = 'উত্তর মিলিয়ে দেখো';
  static const nextQuestion = 'পরের প্রশ্ন';
  static const finish = 'শেষ করো';
  static const correct = 'সঠিক হয়েছে!';
  static const incorrect = 'ভুল হয়েছে';
  static const correctAnswerIs = 'সঠিক উত্তর';
  static const yourAnswer = 'তোমার উত্তর লেখো';
  static const tapToReveal = 'উত্তর দেখতে ট্যাপ করো';
  static const showModelAnswer = 'নমুনা উত্তর দেখাও';
  static const selfCheckTitle = 'নিজে যাচাই করো';
  static const iGotItRight = 'আমি ঠিক লিখেছি';
  static const iNeedPractice = 'আরও অনুশীলন দরকার';
  static const selectAnswer = 'উত্তর বেছে নাও';
  static const arrangeInOrder = 'সঠিক ক্রমে সাজাও';
  static const matchPairs = 'সঠিকভাবে মেলাও';

  // Flashcards
  static const flashcardFront = 'এই শব্দটির অর্থ কী?';
  static const showMeaning = 'অর্থ দেখাও';
  static const recallAgain = 'পারিনি';
  static const recallGood = 'পেরেছি';
  static const recallEasy = 'সহজ ছিল';
  static const noCardsDue = 'এখন পর্যালোচনার জন্য কোনো কার্ড নেই। দারুণ!';

  // Summary
  static const sessionComplete = 'অনুশীলন শেষ!';
  static const youScored = 'তুমি পেয়েছ';
  static const outOf = 'এর মধ্যে';
  static const backToHome = 'হোমে ফিরে যাও';
  static const practiceAgain = 'আবার অনুশীলন করো';
  static const keepGoing = 'চালিয়ে যাও, তুমি পারবে!';

  // Diagnostic (HSC Readiness Check)
  static const readinessCheckTitle = 'HSC প্রস্তুতি যাচাই';
  static const readinessCheckIntro =
      'কয়েকটি প্রশ্নের উত্তর দাও। আমরা দেখব তুমি বোর্ড পরীক্ষায় এখন কেমন করবে '
      'এবং কোন বিষয়গুলোতে বেশি অনুশীলন দরকার।';
  static const startReadinessCheck = 'যাচাই শুরু করো';
  static const readinessCheckDone = 'যাচাই সম্পন্ন!';
  static const yourPredictedScore = 'তোমার সম্ভাব্য বোর্ড স্কোর';
  static const focusOnThese = 'এই বিষয়গুলোতে মন দাও';
  static const seeYourPlan = 'তোমার পরিকল্পনা দেখো';

  // Focus areas & predicted score (home)
  static const predictedBoardScore = 'সম্ভাব্য বোর্ড স্কোর';
  static const basedOnSoFar = 'এ পর্যন্ত অনুশীলনের ভিত্তিতে';
  static const focusAreasTitle = 'Focus Area — এখন এগুলো অনুশীলন করো';
  static const worthMarks = 'নম্বর';
  static const youdScore = 'আজ তুমি পাবে';
  static const takeReadinessCheck = 'HSC প্রস্তুতি যাচাই করো';
  static const takeReadinessCheckSub =
      'কোথা থেকে শুরু করবে জানতে ছোট একটি যাচাই দাও';
  static const practiceThisTopic = 'এই বিষয়টি অনুশীলন করো';

  // Weekly progress
  static const thisWeek = 'এই সপ্তাহ';
  static const questionsAnswered = 'টি প্রশ্নের উত্তর দিয়েছ';
  static const daysActive = 'দিন সক্রিয় ছিলে';

  // Challenge track (strong student)
  static const challengeUnlocked = 'চ্যালেঞ্জ আনলক হয়েছে!';
  static const challengeTitle = 'চ্যালেঞ্জ মোড';
  static const challengeSub = 'তোমার Focus Area শেষ! কঠিন প্রশ্নে নিজেকে যাচাই করো';
  static const startChallenge = 'চ্যালেঞ্জ শুরু করো';

  // Misc
  static const loading = 'লোড হচ্ছে...';
  static const nothingHere = 'এখানে এখনো কিছু নেই';

  /// Bangla digits for a friendlier feel on numbers shown to students.
  static String digits(int n) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return n
        .toString()
        .split('')
        .map((c) {
          final d = int.tryParse(c);
          return d == null ? c : bnDigits[d];
        })
        .join();
  }
}
