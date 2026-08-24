# Recomp and native-port research

DesktopGoldenEye v0.1 deliberately ships the proven 1964GEPD quality stack. It
is not a static recompilation.

Earlier work evaluated GoldenRecomp/N64Recomp directions and imported MGB64
revision `0d1d40b4cde18302ec9789853a50f5545e679062` as an editable experiment.
That build accepted the ordinary ROM and exposed promising native/mod seams, but
human testing rejected its mouse feel and rendering quality for the product
baseline. The large snapshot was removed from the v0.1 release tree; its commit
remains recoverable in Git history (`88b5bb9`) and upstream at
<https://github.com/akratch/mgb64>.

A future replacement must beat the Windows baseline in real play, not only in
architecture:

- ordinary-ROM first run;
- accurate rendering across representative missions;
- low-latency mouse, keyboard, and controller input;
- stable audio, timing, saves, and campaign progression;
- Windows, Linux, and macOS maintainability;
- clear provenance and ROM-free distribution;
- safe semantic hooks suitable for mods.

Until a candidate passes that gate, the launcher/runtime boundary stays small:
verify ROM, apply settings, launch, manage saves, and report diagnostics.
