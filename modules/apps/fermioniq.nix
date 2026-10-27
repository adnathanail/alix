{ pkgs, ... }: {
  # CLIs for Fermioniq's cloud infrastructure.
  home.packages = [
    pkgs.awscli2        # `aws`
    pkgs.ssm-session-manager-plugin  # `session-manager-plugin`, for `aws ssm start-session`
    pkgs.opentofu       # `tofu`, open-source Terraform fork
  ];

  # Per-project tool versions (mise.toml / .tool-versions), activated in zsh.
  programs.mise.enable = true;
}
