

## Design 1: Non-hermetic in-place editing of source code

The following release marks the realisation of this design: https://github.com/thundergolfer/bazel-linting-rules/releases/tag/v0.1

By breaking out of the sandbox the aspect can in-place modify the repo's
source code. This is convenient, but has a _crucial_ problem.

A source file is the input to the action, but that source file is
non-hermetically changed by the action; a side-effect. As this
side-effect is not visible to Bazel, if you 'throw away' the linter's
changes the source file is returned to its original state and re-running
the aspect will hit the cache and no linting will actually occur.

**By turning off caching this problem would be solved, but turning off
caching is not ideal and anyways turning off caching doesn't work in
Bazel right now (https://github.com/bazelbuild/bazel/issues/10205)**

## Design 2: Hermetic pure-function linter_X(source_code) -> Bazel output source code

By removing the side-effect we can fix the caching problem described
above but we then we wouldn't have fixed any lint in the source code.

So we'd still need a non-hermetic step to change source code. This just
shouldn't be part of the aspect. It could be like this:

```
STEP 1:
linter_aspect(source_code_X/file_Y) -> bazel-bin/source_code_X/file_y.linted

STEP 2:
diff source_code_X/file_y bazel-bin/source_code_X/file_y.linted

OR

cp source_code_X/file_y bazel-bin/source_code_X/file_y.linted


```


### limitations

- Relies on the linters supporting a particular cmd line interface:
  `{linter} [file file2 file3 file4 ...]`
