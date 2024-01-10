package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/gosimple/slug"
	"github.com/magefile/mage/mg"
)

type Json mg.Namespace

func (Json) Trivia(ctx context.Context, triviaPath string) error {
	trivia, err := unmarshalTriviaFromSource(triviaPath)
	if err != nil {
		return err
	}

	trivia.Tid = slug.Make(trivia.Title)

	for i := range trivia.Questions {
		trivia.Questions[i].Qid = fmt.Sprintf("Q%05d", i)
		if len(trivia.Questions[i].Tags) == 0 {
			trivia.Questions[i].Tags = []string{}
		}
	}

	if err := json.NewEncoder(os.Stdout).Encode(trivia); err != nil {
		panic(err)
	}

	return nil
}
