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
  static const noStreakYetSub = 'প্রতিদিন একটু অনুশীলন করলেই streak গড়ে উঠবে।';

  // Topic list
  static const chooseTopic = 'একটি বিষয় বেছে নাও';
  static const questionsAvailable = 'টি প্রশ্ন আছে';
  static const scoreLabel = 'তোমার স্কোর';
  static const basicsSectionTitle = 'মূল ভিত্তি (Basics)';
  static const basicsSectionSub =
      'ইংরেজির ভিত্তি — দুর্বল হলে এখান থেকে শুরু করো';
  static const hscSectionTitle = 'HSC অনুশীলন';
  static const hscSectionSub = '1st ও 2nd Paper সিলেবাস অনুযায়ী';
  // Difficulty level chooser
  static const chooseLevel = 'কোন লেভেলে অনুশীলন করবে?';
  static const levelEasy = 'সহজ';
  static const levelMedium = 'মাঝারি';
  static const levelHard = 'কঠিন';
  static const levelAll = 'সব লেভেল একসাথে';
  static const levelEasyHint = 'শুরু করার জন্য ভালো';
  static const noQuestionsAtLevel = 'এই লেভেলে এখনো প্রশ্ন নেই';

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
  // Stricter self-check flow
  static const wordsWritten = 'লিখেছ';
  static const wordsUnit = 'শব্দ';
  static const minWordsHint = 'নমুনা দেখতে অন্তত ১৫ শব্দ নিজে লেখো';
  static const compareAndTick = 'নমুনার সাথে মিলিয়ে সৎভাবে টিক দাও — যেগুলো তুমি সত্যিই পেরেছ';
  static const youMet = 'তুমি পেরেছ';
  static const doneSelfCheck = 'হয়ে গেছে';
  static const writeFirst = 'আগে নিজে উত্তরটি লেখো, তারপর নমুনা দেখো';
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

  // Sync / account
  static const syncTitle = 'অগ্রগতি সংরক্ষণ';
  static const syncSubtitle = 'তোমার অগ্রগতি নিরাপদে রাখতে ফোন নম্বর দিয়ে যুক্ত হও';
  static const phoneLabel = 'ফোন নম্বর';
  static const nameLabel = 'তোমার নাম (ঐচ্ছিক)';
  static const schoolCodeLabel = 'স্কুল কোড (ঐচ্ছিক)';
  static const enrollCodeLabel = 'ক্লাস কোড (থাকলে দাও)';
  static const loginAndSync = 'যুক্ত হও ও সংরক্ষণ করো';

  // Teacher mode
  static const teacherLoginLink = 'আমি একজন শিক্ষক';
  static const teacherLoginTitle = 'শিক্ষক লগইন';
  static const passwordLabel = 'পাসওয়ার্ড';
  static const teacherLoginButton = 'লগইন করো';
  static const teacherLoginError = 'ফোন বা পাসওয়ার্ড ভুল';
  static const teacherDashTitle = 'আমার ক্লাসসমূহ';
  static const teacherLogout = 'শিক্ষক লগআউট';
  static const couldNotLoad = 'লোড করা যায়নি';
  static const retry = 'আবার চেষ্টা করো';
  static const studentsUnit = 'জন শিক্ষার্থী';
  static const shareCodeHint = 'শিক্ষার্থীদের এই কোডটি দাও';
  static const noStudentsYet = 'এখনো কেউ যোগ দেয়নি। উপরের কোডটি শিক্ষার্থীদের দাও।';
  static const attemptsShort = 'উত্তর';
  static const accuracyShort = 'সঠিক';
  static const pointsShort = 'পয়েন্ট';
  static const neverPracticed = 'এখনো অনুশীলন করেনি';
  static const lastActiveLabel = 'সর্বশেষ';
  static const topicBreakdown = 'বিষয়ভিত্তিক ফলাফল';
  static const noPracticeData = 'এখনো কোনো অনুশীলনের তথ্য নেই।';
  static const syncNow = 'এখনই সংরক্ষণ করো';
  static const logout = 'বের হও';
  static const lastSynced = 'সর্বশেষ সংরক্ষণ';
  static const neverSynced = 'এখনো সংরক্ষণ হয়নি';
  static const syncSuccess = 'অগ্রগতি সংরক্ষিত হয়েছে!';
  static const syncOffline = 'এখন ইন্টারনেট নেই — পরে চেষ্টা করা হবে';
  static const syncError = 'সংরক্ষণে সমস্যা হয়েছে';
  static const loginError = 'যুক্ত হওয়া যায়নি — ইন্টারনেট দেখে আবার চেষ্টা করো';
  static const notSyncedYet = 'অগ্রগতি সংরক্ষণ';
  static const enterPhone = 'ফোন নম্বর লেখো';

  // Leaderboard
  static const leaderboardTitle = 'তোমার ক্লাসের লিডারবোর্ড';
  static const leaderboardWeekly = 'প্রতি সপ্তাহে নতুন করে শুরু হয়';
  static const points = 'পয়েন্ট';
  static const you = 'তুমি';
  static const rank = 'অবস্থান';
  static const anonymousStudent = 'একজন শিক্ষার্থী';
  static const leaderboardNeedsLogin =
      'ক্লাসের লিডারবোর্ড দেখতে ফোন নম্বর দিয়ে যুক্ত হও';
  static const leaderboardNeedsSchool =
      'লিডারবোর্ডে যোগ দিতে স্কুল কোড যোগ করো';
  static const leaderboardEmpty =
      'এই সপ্তাহে এখনো কেউ অনুশীলন করেনি — প্রথম হও!';
  static const leaderboardOffline = 'লিডারবোর্ড আনা যায়নি — ইন্টারনেট দেখো';
  static const classLeaderboard = 'ক্লাস লিডারবোর্ড';

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
