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
    com.apple.corespeechd.system
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

BOOT_SCRIPT=/usr/local/libexec/debloat.sh

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
        for label in "${AGENTS[@]}"; do
            launchctl disable "$gui/$label"
            launchctl bootout "$gui/$label" 2>/dev/null || true
        done
    fi
    for label in "${DAEMONS[@]}"; do
        as_root launchctl disable "system/$label"
        as_root launchctl bootout "system/$label" 2>/dev/null || true
    done
}

if [ "${1:-}" = "--boot" ]; then
    disable_all "gui/$2"
    until launchctl print "gui/$2" >/dev/null 2>&1; do
        sleep 5
    done
    sleep 60
    disable_all "gui/$2"
    exit 0
fi

LABEL="com.$(id -un).debloat"
PLIST="/Library/LaunchDaemons/$LABEL.plist"

unload() {
    as_root launchctl bootout "system/$LABEL" 2>/dev/null || true
    for _ in $(seq 1 25); do
        as_root launchctl print "system/$LABEL" >/dev/null 2>&1 || return 0
        sleep 0.2
    done
}

if [ "${1:-}" = "--undo" ]; then
    unload
    as_root rm -f "$PLIST" "$BOOT_SCRIPT"
    for label in "${AGENTS[@]}"; do
        launchctl enable "gui/$(id -u)/$label"
    done
    for label in "${DAEMONS[@]}"; do
        as_root launchctl enable "system/$label"
    done
    echo "  enabled ${#AGENTS[@]} agents and ${#DAEMONS[@]} daemons, restart to bring them back"
    exit 0
fi

disable_all "gui/$(id -u)"
echo "  disabled ${#AGENTS[@]} agents and ${#DAEMONS[@]} daemons"

as_root mkdir -p "$(dirname "$BOOT_SCRIPT")"
as_root install -m 755 -o root -g wheel "${BASH_SOURCE[0]}" "$BOOT_SCRIPT"
as_root tee "$PLIST" >/dev/null <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$BOOT_SCRIPT</string>
        <string>--boot</string>
        <string>$(id -u)</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST
unload
as_root launchctl bootstrap system "$PLIST"
echo "  loaded $LABEL, reapplies at boot and after login"
