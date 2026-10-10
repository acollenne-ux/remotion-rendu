import React from 'react';
import {
  AbsoluteFill,
  Easing,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';

export const DEMO_WIDTH = 1920;
export const DEMO_HEIGHT = 1080;
export const DEMO_FPS = 30;
export const DEMO_DURATION_IN_FRAMES = 150;

export type DemoProps = {
  title: string;
  subtitle: string;
};

/**
 * Composition de test "motion design" : texte principal qui arrive en spring,
 * sous-titre qui se revele par decalage, et barre de progression sur toute
 * la duree de la video. Sert de preuve de rendu pour l'installation locale.
 */
export const Demo: React.FC<DemoProps> = ({ title, subtitle }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames, width, height } = useVideoConfig();

  const titleSpring = spring({
    frame,
    fps,
    config: { damping: 200, stiffness: 100 },
    durationInFrames: 30,
  });
  const titleY = interpolate(titleSpring, [0, 1], [120, 0]);
  const titleOpacity = interpolate(titleSpring, [0, 1], [0, 1]);

  const subtitleStart = 25;
  const subtitleOpacity = interpolate(frame, [subtitleStart, subtitleStart + 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.ease),
  });
  const subtitleY = interpolate(frame, [subtitleStart, subtitleStart + 20], [40, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const progress = interpolate(frame, [0, durationInFrames - 1], [0, 100], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const pulse = interpolate(frame % 45, [0, 22, 45], [0.6, 1, 0.6], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: '#0b1020',
        backgroundImage:
          'radial-gradient(circle at 25% 20%, rgba(64,93,230,0.35), transparent 55%), radial-gradient(circle at 80% 75%, rgba(230,72,145,0.30), transparent 55%)',
        justifyContent: 'center',
        alignItems: 'center',
        fontFamily: 'Arial, Helvetica, sans-serif',
      }}
    >
      <div
        style={{
          transform: `translateY(${titleY}px)`,
          opacity: titleOpacity,
          fontSize: 120,
          fontWeight: 800,
          color: '#ffffff',
          textAlign: 'center',
          letterSpacing: -2,
          maxWidth: width * 0.85,
          textShadow: '0 10px 40px rgba(0,0,0,0.45)',
        }}
      >
        {title}
      </div>

      <div
        style={{
          transform: `translateY(${subtitleY}px)`,
          opacity: subtitleOpacity,
          marginTop: 32,
          fontSize: 46,
          fontWeight: 500,
          color: 'rgba(255,255,255,0.82)',
          textAlign: 'center',
          maxWidth: width * 0.8,
        }}
      >
        {subtitle}
      </div>

      <div
        style={{
          marginTop: 64,
          width: 14,
          height: 14,
          borderRadius: '50%',
          backgroundColor: '#7cc4ff',
          opacity: pulse,
          boxShadow: '0 0 24px rgba(124,196,255,0.9)',
        }}
      />

      <div
        style={{
          position: 'absolute',
          bottom: 0,
          left: 0,
          height: 10,
          width: `${progress}%`,
          background: 'linear-gradient(90deg, #405de6, #e64891)',
        }}
      />

      <div
        style={{
          position: 'absolute',
          bottom: 40,
          left: 0,
          width,
          textAlign: 'center',
          fontSize: 26,
          color: 'rgba(255,255,255,0.55)',
          fontFamily: 'monospace',
        }}
      >
        frame {frame} / {durationInFrames - 1} &middot; {width}x{height} @ {fps}fps
      </div>
    </AbsoluteFill>
  );
};
