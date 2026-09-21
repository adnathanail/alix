# Battery percentage + charge state. No native menu-bar icon to alias here
# (unlike wifi/apple-menu) since SketchyBar's own battery provider is
# unreliable across sleep/wake, so this polls `pmset` directly on a timer
# instead.
{ sketchybarBin }: {
  rc = ''
    ${sketchybarBin} --add item battery right \
        --set battery \
            update_freq=30 \
            script="$PLUGIN_DIR/battery.sh"
  '';

  plugins = {
    "battery.sh" = ''
      #!/bin/bash
      BATT=$(pmset -g batt)
      PERCENT=$(grep -Eo "\d+%" <<< "$BATT" | cut -d% -f1)

      if grep -q "AC Power" <<< "$BATT"; then
        ${sketchybarBin} --set "$NAME" icon="" icon.color=0xff5dfe67 label="''${PERCENT}%"
        exit 0
      fi

      case $PERCENT in
        9[0-9]|100) ICON="" ;;
        [67][0-9]) ICON="" ;;
        [45][0-9]) ICON="" ;;
        [23][0-9]) ICON="" ;;
        *) ICON="" ;;
      esac

      [[ $PERCENT -gt 10 ]] && COLOR=0xffffffff || COLOR=0xffff0000

      ${sketchybarBin} --set "$NAME" icon="$ICON" icon.color=$COLOR label="''${PERCENT}%"
    '';
  };
}
