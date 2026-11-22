{ pkgs, lib, ... }:

let
  uid = "501"; # `id -u`

  agents = [
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
    "com.apple.siri.context.service"
    "com.apple.notificationcenterui.siri"
    "com.apple.intelligentroutingd"

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
    "com.apple.rcd"

    "com.apple.email.maild"
    "com.apple.icloudmailagent"
    "com.apple.mdworker.mail"
  ];

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
              [ "$(id -u)" -eq 0 ] || ignore_plugins
              echo "  disabled ''${#AGENTS[@]} agents and ''${#DAEMONS[@]} daemons"
              ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ debloat ];

  launchd.daemons.debloat.serviceConfig = {
    ProgramArguments = [
      "${debloat}/bin/debloat"
      "--boot"
      uid
    ];
    RunAtLoad = true;
  };

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
