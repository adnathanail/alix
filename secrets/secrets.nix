# Recipients per encrypted file. The `agenix` CLI reads this to know which
# public keys to encrypt to when you run `agenix -e <name>.age`.
#
# The value of `alex` below is the *public* age key printed by:
#   age-keygen -y ~/.config/age/keys.txt
# Paste it here (starts with "age1..."). It is safe to commit.
let
  alex = "age1l6qe0epghvkzlhgmukdewh8mn407f3ftfwmtg8sh5ls2ag50fscqeq553c";
in {
  "npm-font-awesome-token.age".publicKeys = [ alex ];
  "npm-github-packages-token.age".publicKeys = [ alex ];
}
