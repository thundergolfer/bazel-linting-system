package main

import (
	"fmt"
	"os"
	"strings"
)

func CleanTargetName(uncleanTarget string) string {
	return strings.Replace(uncleanTarget, "//", "", -1)
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
		fmt.Printf("clean target: %s\n", CleanTargetName(target))
	}
}

