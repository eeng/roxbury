with import <nixpkgs> {};
mkShell {
  nativeBuildInputs = [
    ruby
  ];
  shellHook = ''
    gem list -i '^bundler$' -v 2.0.2 >/dev/null || gem install bundler --version=2.0.2 --no-document
  '';
}