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

	for i1 := range trivia.Questions {
		trivia.Questions[i1].Qid = fmt.Sprintf("Q%05d", i1)
		if len(trivia.Questions[i1].Tags) == 0 {
			trivia.Questions[i1].Tags = []string{}
		}

		for i2 := range trivia.Questions[i1].Choices {
			trivia.Questions[i1].Choices[i2].Cid = fmt.Sprintf("A%05d", i2)
		}
	}

	if err := json.NewEncoder(os.Stdout).Encode(trivia); err != nil {
		panic(err)
	}

	return nil
}
