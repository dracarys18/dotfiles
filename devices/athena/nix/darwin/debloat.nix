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
    # macOS 27 additions: the context service the assistant reads the screen
    # with, the Control Center item, and Apple Intelligence's request router
    "com.apple.siri.context.service"
    "com.apple.notificationcenterui.siri"
    "com.apple.intelligentroutingd"

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

  # Siri's extensions, which are neither launchd jobs nor covered by anything
  # else: they are elected per user, and while an extension is running it lives
  # in the same process list as the assistant and outlives the settings pane
  # that spawned it. Includes the metrics, analytics and upload workers, voice
  # assets and the app-intent extensions, so nothing Siri-shaped can be hosted.
  plugins = [
    "com.apple.aiml.siri.SiriLogProcessor"
    "com.apple.lighthouse.SiriCoreMetricsWorker"
    "com.apple.siri.analytics.SAMaintenance"
    "com.apple.siri.car.PnRCarPlayOnDeviceWorker"
    "com.apple.siri.GMSSELFIngestor"
    "com.apple.siri.inference.SiriInference.SiriInferenceRuntimeDiagnostics"
    "com.apple.siri.messages.SiriMessagesAppIntentsExtension"
    "com.apple.siri.metrics.AssetMetrics"
    "com.apple.siri.metrics.DevicePropertiesExtension"
    "com.apple.siri.ODDFeatureDigestsExtension"
    "com.apple.siri.ODDIExperimentationExtension"
    "com.apple.siri.ODDIMetricsExtension"
    "com.apple.siri.OnDeviceAnalytics.SiriAttentionAndInvocationExtension"
    "com.apple.siri.OnDeviceAnalytics.SpeakerIdSamplingExtension"
    "com.apple.siri.parsec.HashtagImagesApp.HashtagImagesExtension"
    "com.apple.siri.SiriAppLaunchIntents.AppLaunchIntentExtension"
    "com.apple.siri.SiriExtensionsDigestExtension"
    "com.apple.siri.SiriGeo.SiriGeoAppIntentExtension"
    "com.apple.siri.SiriPhoneAppIntentsExtension"
    "com.apple.siri.SiriPrivateLearningAnalytics.SiriUserSegmentation"
    "com.apple.siri.SiriPrivateLearningAnalytics.SiriUserSegments.Plugin"
    "com.apple.siri.SiriSuggestionsLightHousePlugin"
    "com.apple.siri.SiriTimeInternal.AlarmIntentsExtension"
    "com.apple.siri.SiriTimeInternal.TimerIntentsExtension"
    "com.apple.siri.SiriTTSService.STSDiagnostic"
    "com.apple.SiriMetrics.SiriTurnRestatementExtension"
    "com.apple.siriplugin.FileSearch"
    "com.apple.SiriSetup.SiriSetupSettingsIntents"
    "com.apple.texttospeech.SiriAUSP"
    "com.apple.unilog.SiriUploadWorker"
  ];

  # launchctl has no declarative form, so the lists above are applied by this
  #
  #   debloat [UID]          disable everything now (UID defaults to you)
  #   debloat --boot UID     what the boot daemon runs
  #   debloat --plugins      only the plug-in elections (runs as you)
  #   debloat --undo [UID]   re-enable everything; also remove this module
  #                          from darwin/default.nix or the next switch disables them again
  debloat = pkgs.writeShellApplication {
    name = "debloat";
    text = ''
      AGENTS=(${lib.escapeShellArgs agents})
      DAEMONS=(${lib.escapeShellArgs daemons})
      PLUGINS=(${lib.escapeShellArgs plugins})

      ignore_plugins() {
          local n=0
          for id in "''${PLUGINS[@]}"; do
              pluginkit -e ignore -i "$id" 2>/dev/null && n=$((n+1))
          done
          echo "  ignored $n of ''${#PLUGINS[@]} plug-ins"
      }

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
              # now and once more after the user's session is up. The wait is
              # skipped when the session already exists (the hourly re-run).
              disable_all "gui/$2"
              if ! launchctl print "gui/$2" >/dev/null 2>&1; then
                  until launchctl print "gui/$2" >/dev/null 2>&1; do
                      sleep 5
                  done
                  sleep 60
              fi
              disable_all "gui/$2"
              ;;
          --plugins)
              ignore_plugins
              ;;
          --undo)
              uid="''${2:-$(id -u)}"
              for label in "''${AGENTS[@]}"; do
                  as_root launchctl enable "gui/$uid/$label"
              done
              for label in "''${DAEMONS[@]}"; do
                  as_root launchctl enable "system/$label"
              done
              for id in "''${PLUGINS[@]}"; do
                  pluginkit -e use -i "$id" 2>/dev/null || true
              done
              echo "  enabled ''${#AGENTS[@]} agents, ''${#DAEMONS[@]} daemons and ''${#PLUGINS[@]} plug-ins, restart to bring them back"
              ;;
          *)
              disable_all "gui/''${1:-$(id -u)}"
              # elections are per user; as root this would write root's own
              [ "$(id -u)" -eq 0 ] || ignore_plugins
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

  # The plug-in elections have to be written by the user whose extensions they
  # are, which the root daemon above is not, so they get their own user agent.
  # Like the launchd overrides these are stored, not re-derived: one pass at
  # login holds until the next macOS update clears them.
  launchd.user.agents.siri-plugins = {
    serviceConfig = {
      ProgramArguments = [ "${debloat}/bin/debloat" "--plugins" ];
      RunAtLoad = true;
    };
  };

  system.activationScripts.postActivation.text = ''
    echo "debloating..."
    PATH=/usr/bin:/bin:/usr/sbin:/sbin ${lib.getExe debloat} ${uid}
  '';
}
