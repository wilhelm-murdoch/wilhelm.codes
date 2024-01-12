export type Tag = {
    label: string;
    slug: string;
    questions: string[];
}

export type Question = {
    qid: string;
    text: string;
    contains_html?: boolean;
    choices: Choice[];
    tags: string[];
}

export type Choice = {
    cid: string;
    is_correct?: boolean;
    text: string;
    contains_html?: boolean;
}

export type Trivia = {
    tid: string;
    title: string;
    description: string;
    questions: Question[];
};