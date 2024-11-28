import type { Question, Trivia } from '$lib/types/trivia';
import {readable, writable, derived, get} from 'svelte/store';
import { getProgress, getRandomNumbersInRange } from '$lib/utils';
import jsonTrivia from '$lib/data/australia.json'

export const trivia: Trivia = jsonTrivia;

export enum QuizStatus {
    FINISHED = 0,
    STARTED
}

const newTriviaSession = (questions: Question[], amount: number) => {
    const out: Question[] = [];

    getRandomNumbersInRange(0, get(maxNumberOfQuestions), amount).forEach((index) => {
        out.push(questions[index]);
    });

    return out;
}

export const maxNumberOfQuestions = readable(trivia.questions.length);
export const numberOfQuestions = writable(2);
export const currentQuestionIndex = writable(0);
export const title = readable(trivia.title);
export const description = readable(trivia.description);
export const status = writable(QuizStatus.STARTED);
export const score = writable(0);
export const quiz = derived([readable(trivia.questions), numberOfQuestions], ([$questions, $numberOfQuestions]) => {
    if(get(status) === QuizStatus.STARTED) {
        return newTriviaSession($questions, $numberOfQuestions);
    }
}, []);

export const reset = () => {
    score.set(0);
    currentQuestionIndex.set(0);
    status.set(QuizStatus.FINISHED);
}

