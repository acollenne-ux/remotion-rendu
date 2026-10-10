import React from 'react';
import { Composition } from 'remotion';
import { Demo, DEMO_DURATION_IN_FRAMES, DEMO_FPS, DEMO_HEIGHT, DEMO_WIDTH } from './Video/Demo';

/**
 * Racine des compositions Remotion.
 * Toutes les compositions disponibles pour le CLI / le Studio sont enregistrees ici.
 */
export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Demo"
        component={Demo}
        durationInFrames={DEMO_DURATION_IN_FRAMES}
        fps={DEMO_FPS}
        width={DEMO_WIDTH}
        height={DEMO_HEIGHT}
        defaultProps={{
          title: 'Remotion est operationnel',
          subtitle: 'Rendu local verifie sur cette machine',
        }}
      />
    </>
  );
};
