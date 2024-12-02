{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.ruby
    pkgs.bundler
  ];

  shellHook = ''
    echo "Installing gems..."
    bundle install
    echo "Usage: ruby naqelp.rb path/to/PDF/directory"
  '';
}
