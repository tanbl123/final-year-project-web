<?php
// Canonical list of supported payout banks (Malaysia) and the account-number
// length(s) each one uses. Length validation catches typos; it does NOT prove
// ownership — real account verification needs DuitNow/PayNet name resolution or
// a licensed payment gateway's KYC. Lengths are best-effort and easy to tune.

const SUPPORTED_BANKS = [
  ['name' => 'Maybank',                'accountLengths' => [12]],
  ['name' => 'CIMB Bank',              'accountLengths' => [14]],
  ['name' => 'Public Bank',            'accountLengths' => [10]],
  ['name' => 'RHB Bank',               'accountLengths' => [14]],
  ['name' => 'Hong Leong Bank',        'accountLengths' => [12]],
  ['name' => 'AmBank',                 'accountLengths' => [13, 14]],
  ['name' => 'Bank Islam',             'accountLengths' => [14]],
  ['name' => 'Bank Rakyat',            'accountLengths' => [12]],
  ['name' => 'Affin Bank',             'accountLengths' => [13, 14]],
  ['name' => 'Alliance Bank',          'accountLengths' => [14, 16]],
  ['name' => 'UOB Malaysia',           'accountLengths' => [10, 12]],
  ['name' => 'OCBC Bank',              'accountLengths' => [10, 12]],
  ['name' => 'HSBC Malaysia',          'accountLengths' => [12]],
  ['name' => 'Standard Chartered',     'accountLengths' => [10, 12]],
  ['name' => 'Bank Simpanan Nasional', 'accountLengths' => [16]],
  ['name' => 'Agrobank',               'accountLengths' => [16]],
];

// Look up a bank by exact name; returns its row or null.
function findBank(string $name): ?array {
  foreach (SUPPORTED_BANKS as $bank) {
    if ($bank['name'] === $name) {
      return $bank;
    }
  }
  return null;
}

// Validate an account number against a bank row. Returns an error message, or
// null when valid. Accepts spaces/dashes in input; checks the digit count.
function bankAccountError(array $bank, string $accountNo): ?string {
  $digits = preg_replace('/\D/', '', $accountNo);
  if ($digits === '') {
    return 'Bank account number is required.';
  }
  if (!in_array(strlen($digits), $bank['accountLengths'], true)) {
    $lengths = implode(' or ', $bank['accountLengths']);
    return "A {$bank['name']} account number must be {$lengths} digits.";
  }
  return null;
}
