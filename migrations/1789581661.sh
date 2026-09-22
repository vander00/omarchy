echo "Install Elsewhen, the world clock plugin"

omarchy-pkg-add elsewhen

# Dev checkouts do not contain plugins installed by system packages.
packaged_plugin="/usr/share/omarchy/shell/plugins/omacom.elsewhen"
user_plugin="$HOME/.config/omarchy/plugins/omacom.elsewhen"
if [[ ! $OMARCHY_PATH -ef /usr/share/omarchy && -d $packaged_plugin && ! -e $user_plugin && ! -L $user_plugin ]]; then
  mkdir -p "${user_plugin%/*}"
  ln -s "$packaged_plugin" "$user_plugin"
fi

# Best-effort, like the put below: an update whose shell cannot be asked still
# finishes, and restarts the shell once the migrations are through.
omarchy-shell -q shell rescanPlugins
omarchy-bar put omacom.elsewhen --before omarchy.clock
