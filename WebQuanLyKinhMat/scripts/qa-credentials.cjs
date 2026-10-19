// Existing employee credentials are supplied by the caller, never stored in QA source.
function getQaCredentials(environment = process.env) {
  const userName = environment.KINHMAT_TEST_USER?.trim() || '1';
  const password = environment.KINHMAT_TEST_PASSWORD;
  if (typeof password !== 'string' || !password.trim()) {
    throw new Error('Set KINHMAT_TEST_PASSWORD to the existing manager password before running authenticated QA. KINHMAT_TEST_USER defaults to employee code 1.');
  }
  return { userName, password };
}

module.exports = { getQaCredentials };
