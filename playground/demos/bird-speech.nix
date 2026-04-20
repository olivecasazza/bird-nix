let speech = import ./birds-speech.nix {};
in {
  K_says = speech.kestrel.speech;
  I_says = speech.identityBird.speech;
  S_says = speech.starling.speech;
}
