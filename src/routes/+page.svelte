<script lang="ts">
    export let data;
</script>

<div class="prose">
    <ul>
        {#each data.quiz.questions as q}
            <h3>{q.question}</h3>
            <ol>
                {#each q.choices as a}
                    <li class:text-emerald-600={a.correct}>{a.text}</li>
                {/each}
            </ol>
        {/each}
    </ul>
</div>