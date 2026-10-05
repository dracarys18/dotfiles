let
  user = "karthihegde";
  uid = "501"; # `id -u`
in
{
  # Siri, Apple Intelligence, analytics and telemetry stay off. Applied on every
  # switch (below) and again at boot and login, since launchd re-enables some.
  launchd.daemons.debloat.serviceConfig = {
    ProgramArguments = [
      "/bin/bash"
      "${../../scripts/debloat.sh}"
      "--boot"
      uid
    ];
    RunAtLoad = true;
  };

  system.activationScripts.postActivation.text = ''
    # The debloat boot service used to install itself; launchd.daemons.debloat
    # replaces it, so remove the old copy if it's still around
    if [ -e /Library/LaunchDaemons/com.${user}.debloat.plist ]; then
      launchctl bootout system/com.${user}.debloat 2>/dev/null || true
      rm -f /Library/LaunchDaemons/com.${user}.debloat.plist /usr/local/libexec/debloat.sh
    fi

    echo "debloating..."
    PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash ${../../scripts/debloat.sh} ${uid}
  '';
}
