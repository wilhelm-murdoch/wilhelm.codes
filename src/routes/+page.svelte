<script lang="ts">
    import { quiz, currentQuestionIndex } from '$lib/utils/stores/trivia';
    import { fly } from 'svelte/transition';
    import { isCorrect } from '$lib/utils'; 

    let selectedAnswer: string;

    const onSubmit = () => {
        currentQuestionIndex.update(n => n + 1);
    }

    $: question = $quiz[$currentQuestionIndex];
</script>

<div class="prose m-auto">
    <form
        on:submit|preventDefault={onSubmit}
        in:fly={{ x: 200, duration: 500, delay: 500 }}
        out:fly={{ x: -200, duration: 500 }}>
        <fieldset>
            <legend><h2>{question.text}</h2></legend>
            {#each question.choices as choice, choiceIndex}
                <label for="answer{choiceIndex}" class="block ml-2 cursor-pointer">
                    <input
                        class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600 mr-2"
                        required
                        type="radio"
                        id="answer{choiceIndex}"
                        value={choice.cid}
                        name="question{currentQuestionIndex}"
                        bind:group={selectedAnswer} />
                    {choice.text}
                </label>
            {/each}
            <button type="submit">Submit Answer</button>
        </fieldset>
    </form>
</div>