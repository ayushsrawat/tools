package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/djherbis/times"
	"github.com/spf13/cobra"
)

// tool's command line options
type cmd struct {
	dir     string
	verbose bool
	commit  bool
}

type padding struct {
	fileName         int
	creationDate     int
	modificationDate int
}

var opt cmd

const dateFormat = "Jan 02, 2006"
const fileNameHeading = "File"
const creationDateHeading = "Creation Date"
const modificationDateHeading = "Modify Date"

var rootCmd = &cobra.Command{
	Use:   "go run file-oraganizer/* -f <dir>",
	Short: "File Organizer Utility based on creation date, modification date or file type",
	Run:   run,
}

func run(cmd *cobra.Command, args []string) {
	target := opt.dir
	err := validateDirectory(target)
	if err != nil {
		exit(err)
	}
	fmt.Printf("Reorganizing: [%v]\n", target)
	entries, err := os.ReadDir(target)
	if err != nil {
		exit(err)
	}
	if opt.verbose {
		fmt.Printf("Found [%v] entiries in dir [%v]\n", len(entries), target)
	}
	metadata := make(map[string]times.Timespec)
	padding := padding{
		fileName:         len(fileNameHeading),
		creationDate:     len(creationDateHeading),
		modificationDate: len(modificationDateHeading),
	}
	for _, entry := range entries {
		fullPath := filepath.Join(target, entry.Name())
		spec, err := times.Stat(fullPath)
		if err == nil && spec != nil {
			metadata[entry.Name()] = spec
			// set paddings
			padding.fileName = max(padding.fileName, len(entry.Name()))
			padding.modificationDate = max(padding.modificationDate, len(spec.ModTime().Format(dateFormat)))
			if spec.HasBirthTime() {
				padding.creationDate = max(padding.creationDate, len(spec.BirthTime().Format(dateFormat)))
			}
		} else {
			fmt.Printf("error stating entry %v [%v] \n", entry.Name(), err)
		}
	}
	if len(metadata) > 0 {
		totalWidth := padding.fileName + padding.creationDate + padding.modificationDate + 10
		fmt.Printf("%s\n", strings.Repeat("_", totalWidth))
		fmt.Printf("| %s%s | %s%s | %s%s |\n",
			fileNameHeading, strings.Repeat(" ", padding.fileName-len(fileNameHeading)),
			creationDateHeading, strings.Repeat(" ", padding.creationDate-len(creationDateHeading)),
			modificationDateHeading, strings.Repeat(" ", padding.modificationDate-len(modificationDateHeading)),
		)
		fmt.Printf("%s\n", strings.Repeat("_", totalWidth))
		for file, meta := range metadata {
			creationTime := ""
			if meta.HasBirthTime() {
				creationTime = meta.BirthTime().Format(dateFormat)
			}
			modificationTime := meta.ModTime().Format(dateFormat)
			fmt.Printf("| %s%s | %s%s | %s%s |\n",
				file, strings.Repeat(" ", padding.fileName-len(file)),
				creationTime, strings.Repeat(" ", padding.creationDate-len(creationTime)),
				modificationTime, strings.Repeat(" ", padding.modificationDate-len(modificationTime)),
			)
		}
		fmt.Printf("%s\n", strings.Repeat("_", totalWidth))
	}
}

func exit(err error) {
	fmt.Printf("%v\n", err)
	os.Exit(1)
}

func validateDirectory(dir string) error {
	info, err := os.Stat(dir)
	if err == nil {
		if info.IsDir() {
			return nil
		} else {
			return fmt.Errorf("path exists, but it is a file, not a directory [%v]", dir)
		}
	} else if errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("directory does not exist [%v]", dir)
	} else {
		return fmt.Errorf("error checking directory[%v]: %v", dir, err)
	}
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.Flags().StringVarP(&opt.dir, "file", "f", "", "directory to reorganize")
	rootCmd.Flags().BoolVarP(&opt.commit, "commit", "c", false, "commit reorganizing files after dry run verification")
	rootCmd.Flags().BoolVarP(&opt.verbose, "verbose", "v", false, "verbose logs")
}
