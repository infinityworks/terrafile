package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"sync"
	"time"

	"github.com/jessevdk/go-flags"
	"github.com/nritholtz/stdemuxerhook"
	log "github.com/sirupsen/logrus"
	"gopkg.in/yaml.v2"
)

type module struct {
	Source  string `yaml:"source"`
	Version string `yaml:"version"`
}

var opts struct {
	ModulePath string `short:"p" long:"module_path" default:"./vendor/modules" description:"File path to install generated terraform modules"`

	TerrafilePath string `short:"f" long:"terrafile_file" default:"./Terrafile" description:"File path to the Terrafile file"`

	WaitTime string `short:"w" long:"wait_time" default:"2" description:"Number of seconds to wait between each git clone"`

	MaxAttempts string `short:"m" long:"max_attempts" default:"5" description:"Maximum number of attempts to git clone"`
}

// To be set by goreleaser on build
var (
	version = "InfinityWorksConsulting-v1.0.1"
	commit  = "Adding default 5 retry attempts with -m flag to override"
	date    = "Tuesday 1st December 2020"
)

func init() {
	// Needed to redirect logrus to proper stream STDOUT vs STDERR
	log.AddHook(stdemuxerhook.New(log.StandardLogger()))
}

func gitClone(repository string, version string, moduleName string, maxAttempts int) {
	log.Printf("[*] Checking out %s of %s \n", version, repository)
	for i := 1; i <= maxAttempts; i++ {
		cmd := exec.Command("git", "clone", "--single-branch", "--depth=1", "-b", version, repository, moduleName)
		cmd.Dir = opts.ModulePath
		err := cmd.Run()
		if err != nil {
			log.Printf("WARN: attempt %d to fetch %s at version %s \n", i, repository, version)
			if i == maxAttempts {
				log.Fatalln(err)
			}
		} else {
			break;
		}
	}
}

func main() {
	fmt.Printf("Terrafile: version %v, commit %v, built at %v \n", version, commit, date)
	_, err := flags.Parse(&opts)

	// Invalid choice
	if err != nil {
		os.Exit(1)
	}

	// Read File
	yamlFile, err := ioutil.ReadFile(opts.TerrafilePath)
	if err != nil {
		log.Fatalln(err)
	}

	// Parse File
	var config map[string]module
	if err := yaml.Unmarshal(yamlFile, &config); err != nil {
		log.Fatalln(err)
	}

	// Parse Wait Time
	waitTime, err := strconv.ParseInt(opts.WaitTime, 10, 32)
	if err != nil {
		log.Fatalln(err)
	}

	// Parse Max Attempts
	maxAttempts, err := strconv.Atoi(opts.MaxAttempts)
	if err != nil {
		log.Fatalln(err)
	}

	// Clone modules
	var wg sync.WaitGroup
	_ = os.RemoveAll(opts.ModulePath)
	_ = os.MkdirAll(opts.ModulePath, os.ModePerm)
	for key, mod := range config {
		wg.Add(1)
		time.Sleep(time.Duration(waitTime) * time.Second)
		go func(m module, key string) {
			defer wg.Done()
			gitClone(m.Source, m.Version, key, maxAttempts)
			_ = os.RemoveAll(filepath.Join(opts.ModulePath, key, ".git"))
		}(mod, key)
	}

	wg.Wait()
}
