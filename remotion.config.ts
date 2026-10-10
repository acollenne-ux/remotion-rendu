import { Config } from '@remotion/cli/config';

// Le dossier de sortie par defaut des rendus.
Config.setVideoImageFormat('jpeg');
Config.setOverwriteOutput(true);

// Disponible en local : le Chrome Headless Shell est telecharge automatiquement
// par Remotion au premier rendu (dossier de cache ~/.cache/remotion).
Config.setChromiumOpenGlRenderer('swangle');
