<script lang="ts">
    export let data;
</script>

<div class="prose">
    <ul>
        {#each data.quiz.questions as q}
            <h3><span class="mr-1 text-slate-500">{q.qid}.</span>{q.text}</h3>
            <ol>
                {#each q.choices as a}
                    <li class:text-emerald-600={a.is_correct}>{a.text}</li>
                {/each}
            </ol>
        {/each}
    </ul>
</div>