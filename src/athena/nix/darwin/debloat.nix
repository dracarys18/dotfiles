{ pkgs, lib, ... }:

let
  uid = "501"; # `id -u`

  # launchd agents in your session
  agents = [
    # Siri
    "com.apple.campo"
    "com.apple.Siri.agent"
    "com.apple.assistantd"
    "com.apple.assistant_service"
    "com.apple.assistant_cdmd"
    "com.apple.siriactionsd"
    "com.apple.siriappintentsd"
    "com.apple.siriinferenced"
    "com.apple.siriknowledged"
    "com.apple.sirittsd"
    "com.apple.SiriTTSTrainingAgent"
    "com.apple.corespeechd"

    # Apple Intelligence
    "com.apple.generativeexperiencesd"
    "com.apple.GenerativeFunctions.agentstored"
    "com.apple.intelligencecontextd"
    "com.apple.intelligenceflowd"
    "com.apple.intelligenceplatformd"
    "com.apple.intelligencetasksd"
    "com.apple.visualintelligenced"
    "com.apple.callintelligenced"
    "com.apple.mlruntimed"
    "com.apple.mlhostd"
    "com.apple.privatecloudcomputed"
    "com.apple.ModelCatalogAgent"
    "com.apple.textunderstandingd"
    "com.apple.ContextStoreAgent"

    # suggestions and on-device analysis
    "com.apple.suggestd"
    "com.apple.knowledge-agent"
    "com.apple.knowledgeconstructiond"
    "com.apple.parsecd"
    "com.apple.parsec-fbf"
    "com.apple.proactived"
    "com.apple.proactiveeventtrackerd"
    "com.apple.duetexpertd"
    "com.apple.reversetemplated"
    "com.apple.contacts.donation-agent"
    "com.apple.photoanalysisd"
    "com.apple.mediaanalysisd"

    # analytics and diagnostics
    "com.apple.analyticsagent"
    "com.apple.geoanalyticsd"
    "com.apple.inputanalyticsd"
    "com.apple.dprivacyd"
    "com.apple.feedbackd"
    "com.apple.diagnostics_agent"
    "com.apple.diagnosticspushd"
    "com.apple.DiagnosticsReporter"
    "com.apple.diagnosticextensionsd"
    "com.apple.symptomsd-diag.agent"
    "com.apple.symptomsd.distributed-agent"
    "com.apple.securityuploadd"
    "com.apple.metrickitd"
    "com.apple.loginwindow.LWWeeklyMessageTracer"
    "com.apple.appleseed.seedusaged"
    "com.apple.betaenrollmentagent"
    "com.apple.triald"

    # ads, promotions and Apple apps' helpers
    "com.apple.ap.adprivacyd"
    "com.apple.ap.promotedcontentd"
    "com.apple.amsengagementd"
    "com.apple.ndoagent"
    "com.apple.tipsd"
    "com.apple.gamed"
    "com.apple.sociallayerd"
    "com.apple.newsd"
    "com.apple.sportsd"
    "com.apple.watchlistd"
    "com.apple.progressd"
    "com.apple.shazamd"
    "com.apple.helpd"
    "com.apple.rcd" # the play key opening Music

    # Mail
    "com.apple.email.maild"
    "com.apple.icloudmailagent"
    "com.apple.mdworker.mail"
  ];

  # system-wide launchd daemons
  daemons = [
    "com.apple.analyticsd"
    "com.apple.audioanalyticsd"
    "com.apple.ecosystemanalyticsd"
    "com.apple.wifianalyticsd"
    "com.apple.dprivacyd"
    "com.apple.osanalytics.osanalyticshelper"
    "com.apple.SubmitDiagInfo"
    "com.apple.triald.system"
    "com.apple.corespeechd_system"
    "com.apple.modelmanagerd"
    "com.apple.modelcatalogd"
    "com.apple.contextstored"
    "com.apple.rtcreportingd"
    "com.apple.usbctelemetryd"
    "com.apple.systemstats.analysis"
    "com.apple.systemstats.daily"
    "com.apple.systemstats.microstackshot_periodic"
    "com.apple.signpost.signpost_reporter"
    "com.apple.appleseed.fbahelperd"
    "com.apple.betaenrollmentd"
    "com.apple.diagnosticservicesd"
    "com.apple.symptomsd-diag"
    "com.apple.InstallerDiagnostics.installerdiagd"
    "com.apple.InstallerDiagnostics.installerdiagwatcher"
  ];

  # launchctl has no declarative form, so the lists above are applied by this
  #
  #   debloat [UID]          disable everything now (UID defaults to you)
  #   debloat --boot UID     what the boot daemon runs
  #   debloat --undo [UID]   re-enable everything; also remove this module
  #                          from darwin/default.nix or the next switch disables them again
  debloat = pkgs.writeShellApplication {
    name = "debloat";
    text = ''
      AGENTS=(${lib.escapeShellArgs agents})
      DAEMONS=(${lib.escapeShellArgs daemons})

      as_root() {
          if [ "$(id -u)" -eq 0 ]; then
              "$@"
          else
              sudo "$@"
          fi
      }

      disable_all() {
          local gui="$1"
          if launchctl print "$gui" >/dev/null 2>&1; then
              for label in "''${AGENTS[@]}"; do
                  as_root launchctl disable "$gui/$label"
                  as_root launchctl bootout "$gui/$label" 2>/dev/null || true
              done
          fi
          for label in "''${DAEMONS[@]}"; do
              as_root launchctl disable "system/$label"
              as_root launchctl bootout "system/$label" 2>/dev/null || true
          done
      }

      case "''${1:-}" in
          --boot)
              # launchd brings some of these back at boot and at login, so apply
              # now and once more after the user's session is up
              disable_all "gui/$2"
              until launchctl print "gui/$2" >/dev/null 2>&1; do
                  sleep 5
              done
              sleep 60
              disable_all "gui/$2"
              ;;
          --undo)
              uid="''${2:-$(id -u)}"
              for label in "''${AGENTS[@]}"; do
                  as_root launchctl enable "gui/$uid/$label"
              done
              for label in "''${DAEMONS[@]}"; do
                  as_root launchctl enable "system/$label"
              done
              echo "  enabled ''${#AGENTS[@]} agents and ''${#DAEMONS[@]} daemons, restart to bring them back"
              ;;
          *)
              disable_all "gui/''${1:-$(id -u)}"
              echo "  disabled ''${#AGENTS[@]} agents and ''${#DAEMONS[@]} daemons"
              ;;
      esac
    '';
  };
in
{
  # `debloat --undo` on the command line turns everything back on
  environment.systemPackages = [ debloat ];

  # Siri, Apple Intelligence, analytics and telemetry stay off. Applied on every
  # switch (below) and again at boot and login, since launchd re-enables some.
  launchd.daemons.debloat.serviceConfig = {
    ProgramArguments = [
      "${debloat}/bin/debloat"
      "--boot"
      uid
    ];
    RunAtLoad = true;
  };

  system.activationScripts.postActivation.text = ''
    echo "debloating..."
    PATH=/usr/bin:/bin:/usr/sbin:/sbin ${lib.getExe debloat} ${uid}
  '';
}
