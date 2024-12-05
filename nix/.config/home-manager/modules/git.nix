{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Eashwar Ranganathan";
    userEmail = "eashwar@eashwar.com";

    extraConfig.credential.helper = "osxkeychain";

    signing.signByDefault = true;
    # Yubikey 5
    signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIqwN+iU7mRhVBtUZ4stE510fuhfWqMo1nAcUhKNR4NA";
    # Primary key
    # signing.key = "ABE7DE99109E0751!";
    # Secondary Key
    # signing.key = 16D3DAA87DD14FD1!
    # Tertiary Key
    # signing.key = 9CC032321B7646AB!
    # Quaternary Key
    # signing.key = 41110033AEA8A6AF!

    extraConfig = {
      gpg.format = "ssh";
    };
  };
}
