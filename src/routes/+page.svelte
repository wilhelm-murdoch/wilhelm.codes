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
        console.log(selectedAnswer, question)
        if(isCorrect(question, selectedAnswer)){

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

<!-- {#if get(status) == QuizStatus.STARTED} -->
    <div class="w-full bg-gray-200 h-4">
        <div class:hidden={progress == 0} class="bg-blue-600 text-xs font-medium text-blue-100 text-right px-2 py-0.5 leading-none transition-[width]" style="width: {progress}%">{progress}%</div>
    </div>
<!-- {/if} -->

<div class="prose m-auto">
{#if question}
    <form
        on:submit|preventDefault={onSubmit}
        in:fly={{ x: 200, duration: 500, delay: 500 }}
        out:fly={{ x: -200, duration: 500 }}>
        <fieldset>
            <legend><h2>{question.text}</h2></legend>
            {#each question.choices as choice}
                <label for="{choice.cid}" class="block cursor-pointer text-xl align-middle mb-4">
                    <input
                        class="h-6 w-6 mr-2 rounded border-blue-300 text-blue-600 focus:ring-blue-500"
                        required
                        type="radio"
                        id="{choice.cid}"
                        value={choice.cid}
                        name="{question.qid}"
                        bind:group={selectedAnswer} />
                    {choice.text}
                </label>
            {/each}
            <button type="submit">Submit Answer</button>
        </fieldset>
    </form>
{/if}
</div>