{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Eashwar Ranganathan";
    userEmail = "eashwar@eashwar.com";

    extraConfig = {
      credential.helper = "osxkeychain";
      color.ui = "auto";

      gpg.format = "ssh";
      commit.gpgsign = true;
      tag.gpgsign = true;

      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIqwN+iU7mRhVBtUZ4stE510fuhfWqMo1nAcUhKNR4NA";
    };
  };
}
