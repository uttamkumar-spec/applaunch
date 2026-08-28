class FormFlaw {
  FormFlaw({
    required this.label,
    required this.explanation,
    required this.severity,
    this.x,
    this.y,
  });

  final String label;
  final String explanation;
  final String severity; // 'low' | 'medium' | 'high'
  final num? x;
  final num? y;

  factory FormFlaw.fromJson(Map<String, dynamic> j) => FormFlaw(
        label: j['label'] as String? ?? 'Issue',
        explanation: j['explanation'] as String? ?? '',
        severity: j['severity'] as String? ?? 'medium',
        x: j['x'] as num?,
        y: j['y'] as num?,
      );
}

class VideoFrameAnalysis {
  VideoFrameAnalysis({
    required this.frameNumber,
    required this.timestampSeconds,
    required this.annotatedImageBase64,
    required this.flaws,
  });

  final int frameNumber;
  final num timestampSeconds;
  final String annotatedImageBase64;
  final List<FormFlaw> flaws;

  factory VideoFrameAnalysis.fromJson(Map<String, dynamic> j) => VideoFrameAnalysis(
        frameNumber: j['frame_number'] as int? ?? 0,
        timestampSeconds: j['timestamp_seconds'] as num? ?? 0,
        annotatedImageBase64: j['annotated_image_base64'] as String? ?? '',
        flaws: (j['flaws'] as List? ?? []).map((f) => FormFlaw.fromJson(f as Map<String, dynamic>)).toList(),
      );
}

/// Result of a photo or video form check — the annotated-image path (a
/// single image with flaws burned on) or the video path (a filmstrip of
/// annotated key frames), plus a shared coaching summary.
class FormAnalysisResult {
  FormAnalysisResult({
    required this.summary,
    required this.musclesNeedingStrength,
    required this.recommendedExercises,
    this.flaws = const [],
    this.annotatedImageBase64,
    this.frames = const [],
    this.durationSeconds,
  });

  final String summary;
  final List<String> musclesNeedingStrength;
  final List<String> recommendedExercises;

  // Image path
  final List<FormFlaw> flaws;
  final String? annotatedImageBase64;

  // Video path
  final List<VideoFrameAnalysis> frames;
  final num? durationSeconds;

  bool get isVideo => durationSeconds != null;

  factory FormAnalysisResult.fromJson(Map<String, dynamic> j) => FormAnalysisResult(
        summary: j['summary'] as String? ?? '',
        musclesNeedingStrength: (j['muscles_needing_strength'] as List? ?? []).cast<String>(),
        recommendedExercises: (j['recommended_exercises'] as List? ?? []).cast<String>(),
        flaws: (j['flaws'] as List? ?? []).map((f) => FormFlaw.fromJson(f as Map<String, dynamic>)).toList(),
        annotatedImageBase64: j['annotated_image_base64'] as String?,
        frames: (j['frames'] as List? ?? [])
            .map((f) => VideoFrameAnalysis.fromJson(f as Map<String, dynamic>))
            .toList(),
        durationSeconds: j['duration_seconds'] as num?,
      );
}
