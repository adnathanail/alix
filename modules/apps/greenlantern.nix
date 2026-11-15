# SSH settings for Green Lantern, the Raspberry Pi home automation server
# (github.com/adnathanail/green-lantern-nix): `ssh greenlantern` logs in as
# alex with the "Green Lantern SSH key" from 1Password.
#
# `IdentitiesOnly` makes SSH offer only that key, instead of every key in the
# 1Password agent in turn (servers refuse a login after too many failed keys).
# The agent itself is set by `IdentityAgent` in ~/.ssh/config; SSH finds the
# matching private key there from the public key file named here.
{ ... }:
let
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFMq67XO2BpeUuRrsDE4/nkceRvD4DN2pSZIssKzp7IH Green Lantern SSH key";
in
{
  environment.etc."ssh/greenlantern.pub".text = publicKey + "\n";

  # `greenlantern` is a shortcut for the home network address. The Tailscale
  # name is matched by wildcard so the tailnet's name stays out of this repo.
  environment.etc."ssh/ssh_config.d/200-greenlantern.conf".text = ''
    Host greenlantern
      HostName greenlantern.local

    Host greenlantern greenlantern.local greenlantern.*.ts.net
      User alex
      IdentityFile /etc/ssh/greenlantern.pub
      IdentitiesOnly yes
  '';
}
