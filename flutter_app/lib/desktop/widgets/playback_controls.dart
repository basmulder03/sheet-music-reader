import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/midi_playback_service.dart';

/// Widget for controlling music playback
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MidiPlaybackService>(
      builder: (context, playback, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              if (playback.currentScore != null) ...[
                Row(
                  children: [
                    Text(
                      _formatDuration(playback.currentPosition),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Slider(
                        value: playback.currentPosition,
                        max: playback.duration,
                        onChanged: (value) {
                          playback.seek(value);
                        },
                      ),
                    ),
                    Text(
                      _formatDuration(playback.duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tempo control
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: playback.currentScore != null
                        ? () => playback.setTempo(playback.tempo - 5)
                        : null,
                    tooltip: 'Decrease Tempo',
                  ),
                  SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Text(
                          '${playback.tempo}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'BPM',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: playback.currentScore != null
                        ? () => playback.setTempo(playback.tempo + 5)
                        : null,
                    tooltip: 'Increase Tempo',
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Play/pause button
                  IconButton(
                    icon: Icon(
                      playback.state == PlaybackState.playing
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      size: 48,
                    ),
                    onPressed: playback.currentScore != null
                        ? () {
                            if (playback.state == PlaybackState.playing) {
                              playback.pause();
                            } else {
                              playback.play();
                            }
                          }
                        : null,
                    tooltip: playback.state == PlaybackState.playing ? 'Pause' : 'Play',
                  ),
                  
                  // Stop button
                  IconButton(
                    icon: const Icon(Icons.stop_circle, size: 48),
                    onPressed: playback.currentScore != null &&
                            playback.state != PlaybackState.stopped
                        ? () => playback.stop()
                        : null,
                    tooltip: 'Stop',
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Volume control
                  const Icon(Icons.volume_up),
                  SizedBox(
                    width: 120,
                    child: Slider(
                      value: playback.volume,
                      onChanged: (value) {
                        playback.setVolume(value);
                      },
                    ),
                  ),
                ],
              ),
              
              // Current measure indicator
              if (playback.currentScore != null &&
                  playback.state != PlaybackState.stopped)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Measure ${playback.currentMeasureIndex + 1}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(double seconds) {
    final minutes = seconds ~/ 60;
    final secs = (seconds % 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
