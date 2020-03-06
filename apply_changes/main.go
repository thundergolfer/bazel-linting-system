package main

import (
	"fmt"
	"os"
	"path"
	"strings"
)


type target struct {
	bzlPackage string
	name string
}

func CleanTargetName(uncleanTarget string) string {
	return strings.Replace(uncleanTarget, "//", "", -1)
}

func OverwriteFilesWithLintedVersions(dir string) error {
	// TODO(Jonathon): Actually implement the copy over
	return nil
}

func ParseTargetName(t string) *target {
	parts := strings.Split(t, ":")
	if len(parts) == 1 {
		return &target{
			bzlPackage: "",
			name: parts[0],
		}
	} else if len(parts) == 2 {
		return &target{
			bzlPackage: parts[0],
			name: parts[1],
		}
	}
	fmt.Fprintf(os.Stderr,"Received invalid label: %s", t)
	os.Exit(1)
	return nil
}

func main() {
	args := os.Args

	if len(args) < 4 {
		fmt.Fprintf(os.Stderr,"usage: <bazel-repo-root> $(bazel info bazel-genfiles) [targets ...]")
		os.Exit(1)
	}

	repoRoot := args[1]
	genfilesRoot := args[2]
	targets := args[3:]

	fmt.Println("Hello World")
	fmt.Printf("repoRoot: %s\n", repoRoot)
	fmt.Printf("genfilesRoot: %s\n", genfilesRoot)
	fmt.Printf("targets: %s\n", targets)

	for _, target := range targets {
		cleanTarget := CleanTargetName(target)
		fmt.Printf("clean target: %s\n", cleanTarget)
		parsedTarget := ParseTargetName(cleanTarget)

		fmt.Printf("parsed: %s\n", parsedTarget)

		lintedFilesDir := path.Join(
			genfilesRoot,
			fmt.Sprintf("%s__linting_system", parsedTarget.bzlPackage),
			parsedTarget.name)

		fileInfo, err := os.Stat(lintedFilesDir)
		if err != nil{
			fmt.Fprintf(
				os.Stderr,
				"The directory '%s' does not exist but was expected to",
				lintedFilesDir)
			os.Exit(1)
		}

		if fileInfo.IsDir() {
			_ = OverwriteFilesWithLintedVersions(lintedFilesDir)
		} else {
			fmt.Fprintf(
				os.Stderr,
				"The path '%s' was expected to be a dir not a file",
				lintedFilesDir)
			os.Exit(1)
		}

	}
}

