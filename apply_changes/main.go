package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"
)

type SimpleLog struct {
	DebugEnabled bool
}

func (m *SimpleLog) Debug(args ...interface{}) {
	if m.DebugEnabled {
		log.Println(args...)
	}
}

func (m *SimpleLog) Info(args ...interface{}) {
	log.Println(args...)
}


type target struct {
	bzlPackage string
	name string
}

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

func CleanTargetName(uncleanTarget string) string {
	return strings.Replace(uncleanTarget, "//", "", -1)
}

func OverwriteFilesWithLintedVersions(repoRoot, dir string) error {
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

func ParseTargetName(t string) (*target, error) {
	cleanTarget := CleanTargetName(t)
	parts := strings.Split(cleanTarget, ":")
	if len(parts) == 1 {
		return &target{
			bzlPackage: "",
			name: parts[0],
		}, nil
	} else if len(parts) == 2 {
		return &target{
			bzlPackage: parts[0],
			name: parts[1],
		}, nil
	}
	err := fmt.Errorf("received invalid label: %s", t)
	return nil, err
}

func ApplyLintedChanges(logger SimpleLog, repoRoot, genfilesRoot, target string) error {
	parsedTarget, err := ParseTargetName(target)
	if err != nil {
		return err
	}

	lintedFilesDir := path.Join(
		genfilesRoot,
		parsedTarget.bzlPackage,
		"__linting_system",
		parsedTarget.name)

	fileInfo, err := os.Stat(lintedFilesDir)
	if err != nil {
		if os.IsNotExist(err) {
			logger.Debug(fmt.Sprintf(
				"The directory '%s' does not exist so no linted file for target '%s/%s'\n",
				lintedFilesDir,
				parsedTarget.bzlPackage,
				parsedTarget.name,
			))
			return nil
		} else {
			return err
		}
	} else if fileInfo.IsDir() {
		err = OverwriteFilesWithLintedVersions(repoRoot, lintedFilesDir)
		if err != nil {
			return err
		}
	}
	return nil
}

func main() {
	args := os.Args

	logger := SimpleLog{DebugEnabled: false}

	if len(args) < 4 {
		fmt.Println("usage: <bazel-repo-root> $(bazel info bazel-genfiles) [targets ...]")
		os.Exit(1)
	}

	repoRoot := args[1]
	genfilesRoot := args[2]
	targetsGroup := args[3]
	targets := strings.Split(targetsGroup, " ")

	for _, target := range targets {
		err := ApplyLintedChanges(logger, repoRoot, genfilesRoot, target)
		if err != nil {
			fmt.Printf("Error on target '%s': %s", target, err)
			os.Exit(1)
		}
	}
}

