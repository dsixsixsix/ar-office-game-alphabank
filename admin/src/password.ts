// Easy to dictate: no look-alike characters (0/O, 1/l/I).
const ALPHABET = "abcdefghjkmnpqrstuvwxyz23456789";

export function generatePassword(length = 10): string {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  return Array.from(bytes, (byte) => ALPHABET[byte % ALPHABET.length]).join("");
}
