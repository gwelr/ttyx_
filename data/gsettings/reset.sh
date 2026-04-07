# Resets ttyx_ settings to default for testing purposes
gsettings list-schemas | grep ttyx | xargs -n 1 gsettings reset-recursively
dconf list /io/github/gwelr/ttyx/profiles/ | xargs -I {} dconf reset -f "/io/github/gwelr/ttyx/profiles/"{}
