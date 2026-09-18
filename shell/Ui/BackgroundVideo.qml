import QtQuick
import QtMultimedia

// The lock screen is the only user. Playback is always silent, so this is a
// bare MediaPlayer and VideoOutput rather than the Video convenience type:
// Video always builds an AudioOutput, and a muted sink still decodes the audio
// stream and opens an audio client.
Item {
  id: root

  property url mediaSource: ""
  property bool playbackEnabled: true
  property int mediaGeneration: 0
  property bool priming: false
  property int primingGeneration: -1
  property bool frameReceived: false
  readonly property bool ready: player.hasVideo

  onMediaSourceChanged: {
    mediaGeneration += 1
    priming = false
    primingGeneration = -1
    frameReceived = false
    primePauseTimer.stop()
    framePauseTimer.stop()
    output.clearOutput()
  }

  onPlaybackEnabledChanged: {
    priming = false
    frameReceived = false
    primePauseTimer.stop()
    framePauseTimer.stop()
    if (playbackEnabled) player.play()
    else player.pause()
  }

  function pauseAfterPrimedFrame() {
    if (!priming
        || root.playbackEnabled
        || primingGeneration !== root.mediaGeneration) return

    priming = false
    primePauseTimer.stop()
    framePauseTimer.stop()
    player.pause()
  }

  // A paused MediaPlayer can load a source without presenting its first frame.
  // Prime it until VideoOutput receives a frame, with a timeout so a stalled
  // decoder cannot keep running indefinitely on battery.
  Timer {
    id: primePauseTimer
    interval: 1000
    repeat: false

    onTriggered: root.pauseAfterPrimedFrame()
  }

  // Receiving a frame means the decoder has produced it, but the scene graph
  // may not have committed it yet. Give VideoOutput a render cycle before
  // pausing so the first frame is not lost on a source switch.
  Timer {
    id: framePauseTimer
    interval: 50
    repeat: false

    onTriggered: root.pauseAfterPrimedFrame()
  }

  VideoOutput {
    id: output
    anchors.fill: parent
    fillMode: VideoOutput.PreserveAspectCrop
  }

  // No audio output is built, so the lock never decodes an audio stream or
  // opens an audio client.
  MediaPlayer {
    id: player
    source: root.mediaSource
    videoOutput: output
    loops: MediaPlayer.Infinite
    autoPlay: root.playbackEnabled
    onMediaStatusChanged: {
      if (mediaStatus !== MediaPlayer.LoadedMedia) return

      if (!root.playbackEnabled) {
        root.priming = true
        root.primingGeneration = root.mediaGeneration
        root.frameReceived = false
        primePauseTimer.restart()
      }
      player.play()
    }
  }

  Connections {
    target: output.videoSink
    function onVideoFrameChanged() {
      if (player.mediaStatus !== MediaPlayer.BufferedMedia) return
      if (!root.priming
          || root.playbackEnabled
          || root.primingGeneration !== root.mediaGeneration
          || root.frameReceived) return

      root.frameReceived = true
      framePauseTimer.restart()
    }
  }
}
