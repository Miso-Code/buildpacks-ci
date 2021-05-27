package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
	"gopkg.in/yaml.v2"
)

const lightsOnColumnID int64 = 14349149

type Manifest struct {
	DeprecationDates []DeprecationDate `yaml:"dependency_deprecation_dates"`
}

type DeprecationDate struct {
	VersionLine string `yaml:"version_line"`
	Name        string
	DateString  string `yaml:"date"`
	Link        string
}

func main() {
	fmt.Printf("Creating Github issues to deprecate dependencies for %s...\n", os.Getenv("BUILDPACK_NAME"))
	var manifest Manifest

	// relies on relative locations of buildpack and buildpack-ci directories in
	// task container
	file, err := os.Open(filepath.Join("../../..", "buildpack", "manifest.yml"))
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	err = yaml.NewDecoder(file).Decode(&manifest)
	if err != nil {
		log.Fatal(err)
	}

	if len(manifest.DeprecationDates) == 0 {
		fmt.Println("Manifest does not contain deprecation dates. No issues to create.")
		return
	}

	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: os.Getenv("GITHUB_TOKEN")},
	)
	ctx := context.Background()
	tc := oauth2.NewClient(ctx, ts)

	client := github.NewClient(tc)
	for _, deprecation := range manifest.DeprecationDates {
		date, err := time.Parse("2006-01-02", deprecation.DateString)
		if err != nil {
			log.Fatal(err)
		}
		if time.Now().After(date.Add(-45 * 24 * time.Hour)) {
			issue, err := createDeprecationIssue(ctx, client, "cloudfoundry", os.Getenv("BUILDPACK_NAME"), deprecation)
			if err != nil {
				log.Fatal(err)
			}
			if issue.GetHTMLURL() != "" {
				err = createProjectCardFromIssueURL(ctx, client, issue.GetHTMLURL())
				if err != nil {
					log.Fatal(err)
				}
			}
		}
	}
}

func createDeprecationIssue(ctx context.Context, client *github.Client, org string, repo string, deprecation DeprecationDate) (github.Issue, error) {
	titleString := fmt.Sprintf("Dependency Deprecation: %s %s", deprecation.Name, deprecation.VersionLine)
	bodyString := fmt.Sprintf("Deprecation date: %s\nLink: %s", deprecation.DateString, deprecation.Link)
	labels := []string{"deprecation-alert"}

	issueRequest := github.IssueRequest{
		Title:  &titleString,
		Body:   &bodyString,
		Labels: &labels,
	}

	issueExists, issueURL, err := exists(ctx, client, org, repo, issueRequest)
	if err != nil {
		return github.Issue{}, fmt.Errorf("failed to check for existing issue: %w", err)
	}

	if issueExists {
		fmt.Printf("Issue %s already exists: %s\n", issueRequest.GetTitle(), issueURL)
		return github.Issue{}, nil
	}

	issue, response, err := client.Issues.Create(ctx, org, repo, &issueRequest)
	if err != nil {
		return github.Issue{}, fmt.Errorf("failed to create issue: %w", err)
	}
	if response.StatusCode < 200 || response.StatusCode > 299 {
		return github.Issue{}, fmt.Errorf("failed to create issue: server returned %s", response.Status)
	}

	fmt.Printf("Created issue with URL %s\n", issue.GetHTMLURL())

	return *issue, nil
}

func exists(ctx context.Context, client *github.Client, org string, repo string, issueRequest github.IssueRequest) (bool, string, error) {
	opts := github.IssueListByRepoOptions{
		Labels: issueRequest.GetLabels(),
		State:  "all",
	}

	issues, resp, err := client.Issues.ListByRepo(ctx, org, repo, &opts)
	if err != nil {
		return false, "", fmt.Errorf("failed to get issues list: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return false, "", fmt.Errorf("failed to get issues list: server returned %s", resp.Status)
	}

	for _, issue := range issues {
		if issue.GetTitle() == issueRequest.GetTitle() {
			return true, issue.GetHTMLURL(), nil
		}
	}
	return false, "", nil
}

func createProjectCardFromIssueURL(ctx context.Context, client *github.Client, url string) error {
	cardOpts := github.ProjectCardOptions{
		Note: url,
	}

	projectCard, response, err := client.Projects.CreateProjectCard(ctx, lightsOnColumnID, &cardOpts)
	if err != nil {
		return fmt.Errorf("failed to create project card: %w", err)
	}
	if response.StatusCode < 200 || response.StatusCode > 299 {
		return fmt.Errorf("failed to create project card: server returned %s", response.Status)
	}

	fmt.Printf("Created project card with URL %s\n", projectCard.GetURL())
	return nil
}