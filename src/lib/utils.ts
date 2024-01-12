import type { Question, Choice } from '$lib/types/trivia';

export const shuffleArray = (array: any) => {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
}

export const getRandomNumbersInRange = (min: number, max: number, count: number) => {
    const out = [];
    for (let i = 0; i < count; i++) {
      const random = Math.floor(Math.random() * (max - min + 1)) + min;
      out.push(random);
    }
    return out;
}

export const getProgress = (score: number, max: number) => {
    let percentage = 0;
    if (typeof score === "number" && typeof max === "number") {
      percentage = Math.round((score / max) * 100);
    }
    return percentage;
};

export const isCorrect = (question: Question, choice: string) => {
    return question.choices.find((c: Choice) => c.cid === choice)?.is_correct ? true : false;
}