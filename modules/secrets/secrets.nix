# Recipients per encrypted file. The `agenix` CLI reads this to know which
# public keys to encrypt to when you run `agenix -e agefiles/<name>.age` (from this directory).
#
# The value of `alex` below is the *public* age key printed by:
#   age-keygen -y ~/.config/age/keys.txt
# Paste it here (starts with "age1..."). It is safe to commit.
let
  alex = "age1l6qe0epghvkzlhgmukdewh8mn407f3ftfwmtg8sh5ls2ag50fscqeq553c";
in {
  "agefiles/npm-font-awesome-token.age".publicKeys = [ alex ];
  "agefiles/npm-github-packages-token.age".publicKeys = [ alex ];

  # # MailMate account config - encrypted because they contain personal email addresses
  "agefiles/mailmate-sources.age".publicKeys = [ alex ];
  "agefiles/mailmate-identities.age".publicKeys = [ alex ];
  "agefiles/mailmate-submission.age".publicKeys = [ alex ];

  # SketchyBar code-signing identity (cert + private key, .p12) - see modules/interface/sketchybar/signing.nix
  "agefiles/sketchybar-signing-identity.age".publicKeys = [ alex ];
}
