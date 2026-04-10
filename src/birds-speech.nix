# Human-speech-like bird combinators with conversational documentation
# Each bird has a personality and 'speaks' when called
# Dogfoods birds.nix — .call attributes reference canonical combinator definitions

{ }:

let
  # Import canonical combinator definitions
  birds = import ./birds.nix {};
  inherit (birds) I M K KI B C L W S V Y;

  self = {
    # Identity Bird - Echoes back exactly what it hears
    identityBird = {
      speech = "I hear you — and echo you back exactly.";
      call = I;
    };

    # Mockingbird - Makes you respond to yourself
    mockingbird = {
      speech = "If you tell me how to respond, I'll make you respond to yourself.";
      call = M;
    };

    # Kestrel - Only hears the first caller
    kestrel = {
      speech = "I only hear the first caller — the second one? Nevermind.";
      call = K;
    };

    # Kite - Only hears the second caller
    kite = {
      speech = "Sorry, I didn't catch the first — but I heard the second clearly!";
      call = KI;
    };

    # Bluebird - Composes two birds in sequence
    bluebird = {
      speech = "Tell me two birds and I'll give you the sequence.";
      call = B;
    };

    # Lark - Observer must react to me first
    lark = {
      speech = "Tell me how to react — but first, you must react to me!";
      call = L;
    };

    # Warbler - Sing once, sing twice
    warbler = {
      speech = "You want me to sing once? I'll sing twice!";
      call = W;
    };

    # Starling - Split the plan and have both act
    starling = {
      speech = "I'll take your plan, split it, and have both act on the same input.";
      call = S;
    };

    # Cardinal - Flips arguments
    cardinal = {
      speech = "You gave me two things? Let me swap them around!";
      call = C;
    };

    # Vireo - Pairs two things and lets a third decide
    vireo = {
      speech = "Give me two things, and I'll let the next bird decide what to do with them.";
      call = V;
    };

    # Sage Bird - Y combinator for recursion
    sageBird = {
      speech = "I make it possible to repeat yourself, over and over again.";
      call = Y;
    };

    # Example 'sentences' - Conversational test cases
    sentences = {
      # Identity: calling identityBird with a function and input
      identityEcho = {
        description = "Identity echo: calling identityBird with increment function and 5";
        result = let
          inc = x: x + 1;
        in self.identityBird.call inc 5;
      };

      # Mocking: mockingbird hearing identityBird
      mockingIdentity = {
        description = "Mocking identity: mockingbird hears identityBird";
        result = self.mockingbird.call self.identityBird.call;
      };

      # Kestrel: choosing between two callers
      kestrelChoice = {
        description = "Kestrel choice: kestrel picks first caller";
        result = self.kestrel.call "first-choice" "second-choice";
      };

      # Kite: choosing between two callers
      kiteChoice = {
        description = "Kite choice: kite picks second caller";
        result = self.kite.call "first-choice" "second-choice";
      };

      # Bluebird: composing increment and double
      bluebirdDemo = {
        description = "Bluebird demo: compose increment and double, then apply to 3";
        result = let
          inc = x: x + 1;
          double = x: x * 2;
        in self.bluebird.call inc double 3;  # inc(double(3)) = inc(6) = 7
      };

      # Warbler: warbler with kestrel
      warblerDemo = {
        description = "Warbler demo: warbler applies kestrel to same input twice";
        result = (self.warbler.call self.kestrel.call) "A";  # kestrel "A" "A" = "A"
      };

      # Starling: S K K = I proof (starling kestrel kestrel = identity)
      starlingDemo = {
        description = "Starling demo: S K K = I proof (applied to 42)";
        result = self.starling.call self.kestrel.call self.kestrel.call 42;  # Should equal 42
      };

      # Cardinal: flips kestrel's arguments
      cardinalDemo = {
        description = "Cardinal demo: C K reverses kestrel's arguments";
        result = self.cardinal.call self.kestrel.call "first" "second";  # K applied with flipped args = "second"
      };

      # Vireo: pair constructor applied to kestrel
      vireoDemo = {
        description = "Vireo demo: V creates a pair, kestrel selects first";
        result = self.vireo.call "a" "b" self.kestrel.call;  # K "a" "b" = "a"
      };
    };
  };
in self
