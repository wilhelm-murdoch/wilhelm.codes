<script lang="ts">
    import { quiz, currentQuestionIndex, status, title, QuizStatus } from '$lib/utils/stores/trivia';
    import { get } from 'svelte/store';
    import { fly } from 'svelte/transition';
    import { isCorrect, getProgress } from '$lib/utils'; 
	import type { Question } from '$lib/types/trivia';
	import { onMount } from 'svelte';

    let selectedAnswer: string;
    let question: Question

    const onSubmit = () => {
        if(!isCorrect(question, selectedAnswer)){

        }

        selectedAnswer = ""
        currentQuestionIndex.update(n => n + 1);
        question = $quiz[$currentQuestionIndex];
    }

    onMount(() => {
        question = $quiz[$currentQuestionIndex];
    })

    $: progress = getProgress($currentQuestionIndex, $quiz.length)

</script>

<svelte:head>
   <title>{get(title)}</title>
</svelte:head>

<div class="w-full bg-gray-200 h-4">
    <div class="bg-yellow-400 text-blue-100 text-right h-4 leading-none transition-[width]" style="width: {progress}%"></div>
</div>

<div class="prose m-auto prose-2xl">
{#if question}
    <form
        on:submit|preventDefault={onSubmit}
        in:fly={{ x: 200, duration: 500, delay: 500 }}
        out:fly={{ x: -200, duration: 500 }}
        class="rounded-2xl shadow-lg m-5 border-4 border-slate-400 overflow-hidden">
        <fieldset class="relative">
            <legend class="bg-gray-50 border-b mb-5">
                <h2 class="block my-0 p-4">{question.text}</h2>
            </legend>
            {#each question.choices as choice}
                <label for="{choice.cid}" class="block cursor-pointer text-2xl px-4 mb-4 -indent-10 pl-14">
                    <input
                        class="h-6 w-6 mr-2 rounded align-middle border-green-300 text-green-600 focus:ring-green-500"
                        required
                        type="radio"
                        id="{choice.cid}"
                        value={choice.cid}
                        name="{question.qid}"
                        bind:group={selectedAnswer} />
                    <span class="align-middle">{choice.text}</span>
                </label>
            {/each}
            <div class="text-right p-4 border-t relative">
                <span class="text-emerald-600 float-left mt-2">{$currentQuestionIndex + 1} of {$quiz.length}</span>
                <button 
                    disabled={!selectedAnswer}
                    class:opacity-50={!selectedAnswer}
                    type="submit"
                    class="cursor-pointer bg-green-500 hover:bg-green-400 text-white font-bold py-2 px-4 border-b-4 border-green-700 hover:border-green-500 rounded">
                    {$currentQuestionIndex == $quiz.length - 1 ? 'Finish' : 'Answer'}
                </button>
            </div>
        </fieldset>
    </form>
{/if}
</div>