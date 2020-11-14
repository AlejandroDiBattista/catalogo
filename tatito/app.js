export default {
    name: 'App',

    setup() {
        const { watchEffect, onMounted, ref } = Vue;
        const contador = ref(null);

        onMounted(() => {
            console.log("onMounted");
        })

        watchEffect(() => {
            console.log("watchEffect");
        })

        function incrementar() {
            contador.value++;
        }

        return { contador, incrementar }
    },

    template: `
        <div id="sidebar">
            <nav>
                <button v-on:click="incrementar">Comprado {{contador}}</button>
            </nav><hr>
        </div>
        <div id="content">
        </div>
    `,
};