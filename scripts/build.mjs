// tvsignals is a single-file web app — "build" just stages it into www/ for Capacitor.
import { rmSync, mkdirSync, copyFileSync, existsSync } from 'node:fs';
rmSync('www', { recursive: true, force: true });
mkdirSync('www', { recursive: true });
copyFileSync('index.html', 'www/index.html');
if (existsSync('manifest.webmanifest')) copyFileSync('manifest.webmanifest', 'www/manifest.webmanifest');
console.log('✓ staged www/ for Capacitor');
