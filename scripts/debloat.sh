#!/usr/bin/env bash

set -euo pipefail

AGENTS=(
    com.apple.campo
    com.apple.Siri.agent
    com.apple.assistantd
    com.apple.assistant_service
    com.apple.assistant_cdmd
    com.apple.siriactionsd
    com.apple.siriappintentsd
    com.apple.siriinferenced
    com.apple.siriknowledged
    com.apple.sirittsd
    com.apple.SiriTTSTrainingAgent
    com.apple.corespeechd

    com.apple.generativeexperiencesd
    com.apple.GenerativeFunctions.agentstored
    com.apple.intelligencecontextd
    com.apple.intelligenceflowd
    com.apple.intelligenceplatformd
    com.apple.intelligencetasksd
    com.apple.visualintelligenced
    com.apple.callintelligenced
    com.apple.mlruntimed
    com.apple.mlhostd
    com.apple.privatecloudcomputed
    com.apple.ModelCatalogAgent
    com.apple.textunderstandingd
    com.apple.ContextStoreAgent

    com.apple.suggestd
    com.apple.knowledge-agent
    com.apple.knowledgeconstructiond
    com.apple.parsecd
    com.apple.parsec-fbf
    com.apple.proactived
    com.apple.proactiveeventtrackerd
    com.apple.duetexpertd
    com.apple.reversetemplated
    com.apple.contacts.donation-agent
    com.apple.photoanalysisd
    com.apple.mediaanalysisd

    com.apple.analyticsagent
    com.apple.geoanalyticsd
    com.apple.inputanalyticsd
    com.apple.dprivacyd
    com.apple.feedbackd
    com.apple.diagnostics_agent
    com.apple.diagnosticspushd
    com.apple.DiagnosticsReporter
    com.apple.diagnosticextensionsd
    com.apple.symptomsd-diag
    com.apple.symptomsd.distributed-agent
    com.apple.securityuploadd
    com.apple.metrickitd
    com.apple.loginwindow.LWWeeklyMessageTracer
    com.apple.appleseed.seedusaged
    com.apple.betaenrollmentagent
    com.apple.triald

    com.apple.ap.adprivacyd
    com.apple.ap.promotedcontentd
    com.apple.amsengagementd
    com.apple.ndoagent
    com.apple.tipsd
    com.apple.gamed
    com.apple.sociallayerd
    com.apple.newsd
    com.apple.sportsd
    com.apple.watchlistd
    com.apple.progressd
    com.apple.shazamd
    com.apple.helpd
)

DAEMONS=(
    com.apple.analyticsd
    com.apple.audioanalyticsd
    com.apple.ecosystemanalyticsd
    com.apple.wifianalyticsd
    com.apple.dprivacyd
    com.apple.osanalytics.osanalyticshelper
    com.apple.SubmitDiagInfo
    com.apple.triald.system
    com.apple.modelmanagerd
    com.apple.modelcatalogd
    com.apple.contextstored
    com.apple.rtcreportingd
    com.apple.usbctelemetryd
    com.apple.systemstats.analysis
    com.apple.systemstats.daily
    com.apple.systemstats.microstackshot_periodic
    com.apple.signpost.signpost_reporter
    com.apple.appleseed.fbahelperd
    com.apple.betaenrollmentd
    com.apple.diagnosticservicesd
    com.apple.symptomsd-diag
    com.apple.InstallerDiagnostics.installerdiagd
    com.apple.InstallerDiagnostics.installerdiagwatcher
)

if [ "$(uname -s)" != "Darwin" ]; then
    echo "  skip   debloat (macOS only)"
    exit 0
fi

GUI="gui/$(id -u)"

if [ "${1:-}" = "--undo" ]; then
    for label in "${AGENTS[@]}"; do
        launchctl enable "$GUI/$label"
    done
    for label in "${DAEMONS[@]}"; do
        sudo launchctl enable "system/$label"
    done
    echo "  enabled ${#AGENTS[@]} agents and ${#DAEMONS[@]} daemons, restart to bring them back"
    exit 0
fi

for label in "${AGENTS[@]}"; do
    launchctl disable "$GUI/$label"
    launchctl bootout "$GUI/$label" 2>/dev/null || true
done
echo "  disabled ${#AGENTS[@]} agents"

for label in "${DAEMONS[@]}"; do
    sudo launchctl disable "system/$label"
    sudo launchctl bootout "system/$label" 2>/dev/null || true
done
echo "  disabled ${#DAEMONS[@]} daemons"
