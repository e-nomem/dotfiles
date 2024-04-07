{ ... }:
{
  programs.gpg = {
    enable = true;

    scdaemonSettings = {
      disable-ccid = true;
    };

    settings = {
      no-greeting = true;

      # Disable inclusion of the version string in ASCII armored output
      no-emit-version = true;

      # Disable comment string in clear text signatures and ASCII armored messages
      no-comments = true;

      # Display long key IDs
      keyid-format = "0xlong";

      # List all keys (or the specified ones) along with their fingerprints
      with-fingerprint = true;

      # Display the calculated validity of user IDs during key listings
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";

      # Try to use the GnuPG-Agent. With this option, GnuPG first tries to connect to
      # the agent before it asks for a passphrase.
      use-agent = true;

      # When using --refresh-keys, if the key in question has a preferred keyserver
      # URL, then disable use of that preferred keyserver to refresh the key from
      # When searching for a key with --search-keys, include keys that are marked on
      # the keyserver as revoked
      keyserver-options = [
        "no-honor-keyserver-url"
        "include-revoked"
      ];

      charset = "utf-8";
      utf8-strings = true;
      fixed-list-mode = true;

      # list of personal digest preferences. When multiple digests are supported by
      # all recipients, choose the strongest one
      personal-cipher-preferences = "AES256 AES192 AES CAST5";

      # list of personal digest preferences. When multiple ciphers are supported by
      # all recipients, choose the strongest one
      personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";

      # message digest algorithm used when signing a key
      cert-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      s2k-digest-algo = "SHA512";

      # This preference list is used for new keys and becomes the default for
      # "setpref" in the edit menu
      default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed";
    };
  };
}
