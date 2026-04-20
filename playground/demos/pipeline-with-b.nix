# Build a pipeline by composing with B
let
  step1 = x: x * 2;        # double
  step2 = x: x + 10;       # add 10
  step3 = x: x * x;        # square
  pipeline = B step3 (B step2 step1);
  # pipeline 3 = step3 (step2 (step1 3))
  #            = step3 (step2 6)
  #            = step3 16
  #            = 256
in {
  result = pipeline 3;
  steps = {
    after_step1 = step1 3;
    after_step2 = step2 (step1 3);
    after_step3 = step3 (step2 (step1 3));
  };
}
