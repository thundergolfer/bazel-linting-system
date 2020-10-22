// Changed 2020 by Zenseact AB

package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"
)

func copy(src, dst string) (int64, error) {
	sourceFileStat, err := os.Stat(src)
	if err != nil {
		return 0, err
	}

	if !sourceFileStat.Mode().IsRegular() {
		return 0, fmt.Errorf("%s is not a regular file", src)
	}

	source, err := os.Open(src)
	if err != nil {
		return 0, err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return 0, err
	}
	defer destination.Close()
	nBytes, err := io.Copy(destination, source)
	return nBytes, err
}

func overwriteFilesWithLintedVersions(repoRoot, dir string) error {
	var files []string

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if !(info.IsDir()) {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		return err
	}
	for _, file := range files {
		repoRelativeFilepath := strings.Replace(file, dir, "", 1)
		absoluteFilepath := path.Join(repoRoot, repoRelativeFilepath)
		_, err := copy(file, absoluteFilepath)
		if err != nil {
			return err
		}

	}
	return nil
}

// Each linted package target within a bazel-linting-system directory space will have its own subdirectory.
// Eg:
// bazel-bin/api_client/__linting_system/api_client (for //api_client:api_client)
// bazel-bin/api_client/__linting_system/repl (for //api_client:repl)
func processLintSystemPackageRoot(repoRoot, lintSystemPkgRoot string) error {
	children, err := ioutil.ReadDir(lintSystemPkgRoot)
	if err != nil {
		log.Fatal(err)
	}

	for _, f := range children {
		if f.IsDir() {
			err = overwriteFilesWithLintedVersions(repoRoot, path.Join(lintSystemPkgRoot, f.Name()))
		}
	}
	return nil
}

func findLintSystemDirs(repoRoot string) ([]string, error) {
	var dirs []string
	err := filepath.Walk(repoRoot, func(path string, info os.FileInfo, err error) error {
		if info.IsDir() {
			if info.Name() == "__linting_system" {
				dirs = append(dirs, path)
				return filepath.SkipDir
			} else {
				return nil
			}
		} else {
			return filepath.SkipDir
		}
	})
	return dirs, err
}

func main() {
	args := os.Args

	if len(args) < 3 {
		fmt.Println("usage: <bazel-repo-root> $(bazel info bazel-genfiles)")
		os.Exit(1)
	}

	repoRoot := args[1]
	genfilesRoot := args[2]

	// All folders of linted files can be found by searching Bazel's genfiles root for
	// the (what should be) unique directory name of the bazel-linting-system.
	matches, err := findLintSystemDirs(genfilesRoot)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	for _, lintSysPkgRoot := range matches {
		err := processLintSystemPackageRoot(repoRoot, lintSysPkgRoot)
		if err != nil {
			fmt.Printf("Error processing pkg '%s': %s", lintSysPkgRoot, err)
			os.Exit(1)
		}
	}
}

