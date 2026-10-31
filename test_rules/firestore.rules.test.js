const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { after, before, beforeEach, describe, test } = require('node:test');

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
} = require('firebase/firestore');

const PROJECT_ID = 'demo-studylens';
const HOST = '127.0.0.1';
const PORT = 8080;

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: HOST,
      port: PORT,
      rules: readFileSync(resolve(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function alice() {
  return testEnv
    .authenticatedContext('alice', { email: 'alice@example.com' })
    .firestore();
}

function bob() {
  return testEnv
    .authenticatedContext('bob', { email: 'bob@example.com' })
    .firestore();
}

function anonymous() {
  return testEnv.unauthenticatedContext().firestore();
}

function profileData(overrides = {}) {
  return {
    uid: 'alice',
    name: 'Alice',
    email: 'alice@example.com',
    createdAt: serverTimestamp(),
    xp: 0,
    level: 1,
    totalQuestions: 0,
    correctAnswers: 0,
    ...overrides,
  };
}

function sessionData(userId = 'alice', sessionId = 'session-1', overrides = {}) {
  return {
    id: sessionId,
    userId,
    title: 'Cell biology',
    materialType: 'text',
    status: 'active',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function messageData(
  userId = 'alice',
  sessionId = 'session-1',
  messageId = 'message-1',
  overrides = {},
) {
  return {
    id: messageId,
    userId,
    sessionId,
    role: 'student',
    content: 'What is a mitochondrion?',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

function quizData(userId = 'alice', quizId = 'quiz-1', overrides = {}) {
  return {
    id: quizId,
    userId,
    sessionId: null,
    title: 'Cell Biology Review',
    questionCount: 1,
    questions: [
      {
        id: 'question-1',
        question: 'Which organelle produces ATP?',
        options: ['Nucleus', 'Ribosome', 'Mitochondrion', 'Golgi'],
        correctOptionIndex: 2,
        explanation: 'Mitochondria generate most cellular ATP.',
      },
    ],
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

function quizResultData(overrides = {}) {
  return {
    id: 'result-1',
    userId: 'alice',
    quizId: 'quiz-1',
    sessionId: null,
    selectedOptionIndexes: [2],
    correctAnswers: 1,
    totalQuestions: 1,
    completedAt: serverTimestamp(),
    xpEarned: 10,
    ...overrides,
  };
}

async function seedSession(userId = 'alice', sessionId = 'session-1') {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'users', userId, 'sessions', sessionId),
      sessionData(userId, sessionId),
    );
  });
}

async function seedQuiz(userId = 'alice', quizId = 'quiz-1') {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'users', userId, 'quizzes', quizId),
      quizData(userId, quizId),
    );
  });
}

describe('unauthenticated access', () => {
  test('cannot read or write user data', async () => {
    const db = anonymous();
    await assertFails(getDoc(doc(db, 'users', 'alice')));
    await assertFails(setDoc(doc(db, 'users', 'alice'), profileData()));
  });

  test('cannot write to an arbitrary collection', async () => {
    const db = anonymous();
    await assertFails(setDoc(doc(db, 'public', 'anything'), { value: true }));
  });
});

describe('student profiles', () => {
  test('owner can create a valid profile and read it back', async () => {
    const db = alice();
    await assertSucceeds(setDoc(doc(db, 'users', 'alice'), profileData()));
    await assertSucceeds(getDoc(doc(db, 'users', 'alice')));
  });

  test('another user cannot create or read the profile', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users', 'alice'), profileData()),
    );

    const other = bob();
    await assertFails(getDoc(doc(other, 'users', 'alice')));
    await assertFails(
      setDoc(doc(other, 'users', 'alice'), {
        ...profileData(),
        uid: 'alice',
      }),
    );
  });

  test('rejects non-zero starting progress', async () => {
    const db = alice();
    await assertFails(
      setDoc(doc(db, 'users', 'alice'), profileData({ xp: 10 })),
    );
    await assertFails(
      setDoc(doc(db, 'users', 'alice'), profileData({ level: 2 })),
    );
  });

  test('rejects an email that does not match the auth token', async () => {
    const db = alice();
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice'),
        profileData({ email: 'someone-else@example.com' }),
      ),
    );
  });

  test('rejects extra or missing fields', async () => {
    const db = alice();
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice'),
        profileData({ isAdmin: true }),
      ),
    );

    const { xp, ...missingXp } = profileData();
    await assertFails(setDoc(doc(db, 'users', 'alice'), missingXp));
  });

  test('owner can delete the profile but another user cannot', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users', 'alice'), profileData()),
    );
    await assertFails(deleteDoc(doc(bob(), 'users', 'alice')));
    await assertSucceeds(deleteDoc(doc(alice(), 'users', 'alice')));
  });

  test('profile fields are immutable after creation', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users', 'alice'), profileData()),
    );

    const db = alice();
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice'),
        { ...profileData(), xp: 25 },
        { merge: true },
      ),
    );
  });
});

describe('study sessions', () => {
  test('owner can create and read a session', async () => {
    const db = alice();
    await assertSucceeds(
      setDoc(
        doc(db, 'users', 'alice', 'sessions', 'session-1'),
        sessionData(),
      ),
    );
    await assertSucceeds(
      getDoc(doc(db, 'users', 'alice', 'sessions', 'session-1')),
    );
  });

  test('rejects ownership and material-type mismatches', async () => {
    const db = alice();
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice', 'sessions', 'session-1'),
        sessionData('alice', 'session-1', { userId: 'bob' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice', 'sessions', 'session-1'),
        sessionData('alice', 'session-1', { materialType: 'video' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice', 'sessions', 'session-1'),
        sessionData('alice', 'session-1', { status: 'completed' }),
      ),
    );
  });

  test('another user cannot create or read an owned session', async () => {
    await assertSucceeds(
      setDoc(
        doc(alice(), 'users', 'alice', 'sessions', 'session-1'),
        sessionData(),
      ),
    );

    const other = bob();
    await assertFails(
      getDoc(doc(other, 'users', 'alice', 'sessions', 'session-1')),
    );
    await assertFails(
      setDoc(
        doc(other, 'users', 'alice', 'sessions', 'session-1'),
        sessionData(),
      ),
    );
  });

  test('allows only the active-to-completed transition', async () => {
    await assertSucceeds(
      setDoc(
        doc(alice(), 'users', 'alice', 'sessions', 'session-1'),
        sessionData(),
      ),
    );

    const db = alice();
    await assertSucceeds(
      setDoc(
        doc(db, 'users', 'alice', 'sessions', 'session-1'),
        { status: 'completed', updatedAt: serverTimestamp() },
        { merge: true },
      ),
    );
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice', 'sessions', 'session-1'),
        { title: 'Renamed session', updatedAt: serverTimestamp() },
        { merge: true },
      ),
    );
  });

  test('owner can delete a session but another user cannot', async () => {
    await assertSucceeds(
      setDoc(
        doc(alice(), 'users', 'alice', 'sessions', 'session-1'),
        sessionData(),
      ),
    );

    await assertFails(
      deleteDoc(doc(bob(), 'users', 'alice', 'sessions', 'session-1')),
    );
    await assertSucceeds(
      deleteDoc(doc(alice(), 'users', 'alice', 'sessions', 'session-1')),
    );
  });
});

describe('study messages', () => {
  test('owner can create a message under an existing session', async () => {
    await seedSession();
    const db = alice();
    await assertSucceeds(
      setDoc(
        doc(db, 'users', 'alice', 'sessions', 'session-1', 'messages', 'message-1'),
        messageData(),
      ),
    );
    await assertSucceeds(
      getDoc(
        doc(db, 'users', 'alice', 'sessions', 'session-1', 'messages', 'message-1'),
      ),
    );
  });

  test('rejects a message whose session does not exist', async () => {
    const db = alice();
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice', 'sessions', 'missing', 'messages', 'message-1'),
        messageData('alice', 'missing'),
      ),
    );
  });

  test('rejects invalid roles, empty content, and oversized content', async () => {
    await seedSession();
    const db = alice();
    const path = doc(
      db,
      'users',
      'alice',
      'sessions',
      'session-1',
      'messages',
      'message-1',
    );

    await assertFails(setDoc(path, messageData('alice', 'session-1', 'message-1', { role: 'system' })));
    await assertFails(setDoc(path, messageData('alice', 'session-1', 'message-1', { content: '' })));
    await assertFails(
      setDoc(
        path,
        messageData('alice', 'session-1', 'message-1', {
          content: 'x'.repeat(12001),
        }),
      ),
    );
  });

  test('owner can delete a message but another user cannot', async () => {
    await seedSession();
    await assertSucceeds(
      setDoc(
        doc(
          alice(),
          'users',
          'alice',
          'sessions',
          'session-1',
          'messages',
          'message-1',
        ),
        messageData(),
      ),
    );

    await assertFails(
      deleteDoc(
        doc(
          bob(),
          'users',
          'alice',
          'sessions',
          'session-1',
          'messages',
          'message-1',
        ),
      ),
    );
    await assertSucceeds(
      deleteDoc(
        doc(
          alice(),
          'users',
          'alice',
          'sessions',
          'session-1',
          'messages',
          'message-1',
        ),
      ),
    );
  });

  test('another user cannot read or write messages', async () => {
    await seedSession();
    await assertSucceeds(
      setDoc(
        doc(alice(), 'users', 'alice', 'sessions', 'session-1', 'messages', 'message-1'),
        messageData(),
      ),
    );

    const other = bob();
    await assertFails(
      getDoc(
        doc(other, 'users', 'alice', 'sessions', 'session-1', 'messages', 'message-1'),
      ),
    );
    await assertFails(
      setDoc(
        doc(other, 'users', 'alice', 'sessions', 'session-1', 'messages', 'message-2'),
        messageData('alice', 'session-1', 'message-2'),
      ),
    );
  });
});

describe('quizzes and results', () => {
  test('owner can create a quiz and read it back', async () => {
    const db = alice();
    await assertSucceeds(
      setDoc(doc(db, 'users', 'alice', 'quizzes', 'quiz-1'), quizData()),
    );
    await assertSucceeds(
      getDoc(doc(db, 'users', 'alice', 'quizzes', 'quiz-1')),
    );
  });

  test('rejects an inconsistent question count and foreign ownership', async () => {
    const db = alice();
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice', 'quizzes', 'quiz-1'),
        quizData('alice', 'quiz-1', { questionCount: 3 }),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice', 'quizzes', 'quiz-1'),
        quizData('bob', 'quiz-1'),
      ),
    );
  });

  test('owner can delete a quiz but another user cannot', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users', 'alice', 'quizzes', 'quiz-1'), quizData()),
    );
    await assertFails(
      deleteDoc(doc(bob(), 'users', 'alice', 'quizzes', 'quiz-1')),
    );
    await assertSucceeds(
      deleteDoc(doc(alice(), 'users', 'alice', 'quizzes', 'quiz-1')),
    );
  });

  test('another user cannot read a quiz', async () => {
    await seedQuiz();
    await assertFails(getDoc(doc(bob(), 'users', 'alice', 'quizzes', 'quiz-1')));
  });

  test('owner can record a result for an existing quiz', async () => {
    await seedQuiz();
    const db = alice();
    await assertSucceeds(
      setDoc(
        doc(db, 'users', 'alice', 'quizResults', 'result-1'),
        quizResultData(),
      ),
    );
  });

  test('owner can delete a result but another user cannot', async () => {
    await seedQuiz();
    await assertSucceeds(
      setDoc(
        doc(alice(), 'users', 'alice', 'quizResults', 'result-1'),
        quizResultData(),
      ),
    );
    await assertFails(
      deleteDoc(doc(bob(), 'users', 'alice', 'quizResults', 'result-1')),
    );
    await assertSucceeds(
      deleteDoc(doc(alice(), 'users', 'alice', 'quizResults', 'result-1')),
    );
  });

  test('rejects a result without a matching quiz', async () => {
    const db = alice();
    await assertFails(
      setDoc(
        doc(db, 'users', 'alice', 'quizResults', 'result-1'),
        quizResultData({ quizId: 'missing-quiz' }),
      ),
    );
  });

  test('rejects impossible scores and excessive XP', async () => {
    await seedQuiz();
    const db = alice();
    const path = doc(db, 'users', 'alice', 'quizResults', 'result-1');

    await assertFails(setDoc(path, quizResultData({ correctAnswers: 2 })));
    await assertFails(setDoc(path, quizResultData({ xpEarned: 1001 })));
    await assertFails(
      setDoc(path, quizResultData({ selectedOptionIndexes: [2, 2] })),
    );
  });
});

describe('catch-all rule', () => {
  test('denies arbitrary collections even for authenticated users', async () => {
    const db = alice();
    await assertFails(
      setDoc(doc(db, 'public', 'anything'), { value: true }),
    );
    await assertFails(getDoc(doc(db, 'public', 'anything')));
  });
});
