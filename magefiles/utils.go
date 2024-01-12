package main

import (
	"encoding/json"
	"os"
)

type Tag struct {
	Label     string   `json:"label"`
	Slug      string   `json:"slug"`
	Questions []string `json:"questions"`
}

type Choice struct {
	Cid          string `json:"cid"`
	IsCorrect    bool   `json:"is_correct,omitempty"`
	Text         string `json:"text"`
	ContainsHTML bool   `json:"contains_html,omitempty"`
}

type Question struct {
	Qid          string   `json:"qid"`
	Text         string   `json:"text"`
	ContainsHTML bool     `json:"contains_html,omitempty"`
	Choices      []Choice `json:"choices"`
	Tags         []string `json:"tags"`
}

type UnmarshalledTrivia struct {
	Tid         string     `json:"tid"`
	Title       string     `json:"title"`
	Description string     `json:"description"`
	Questions   []Question `json:"questions"`
}

func unmarshalTriviaFromSource(sourcePath string) (*UnmarshalledTrivia, error) {
	if _, err := os.Stat(sourcePath); err != nil {
		return &UnmarshalledTrivia{}, err
	}

	triviaJson, err := os.ReadFile(sourcePath)
	if err != nil {
		return &UnmarshalledTrivia{}, err
	}

	var trivia UnmarshalledTrivia
	json.Unmarshal(triviaJson, &trivia)

	return &trivia, nil
}
