<template>
  <div class="root">
    <template v-if="compras == 0">
      <button @click="incrementar" class="ui button icon primary basic fluid">
        <i class="icon cart arrow down"></i>
        Comprar
      </button>
    </template>

    <template v-else>
      <div class="ui icon buttons primary fluid">
        <button @click="decrementar" class="ui button icon basic primary">
          <i class="ui icon minus"></i>
        </button>
        <button @click="vaciar" class="ui button basic">
          {{ compras }}
        </button>
        <button @click="incrementar" class="ui button basic primary">
          <i class="iu icon plus"></i>
        </button>
      </div>
    </template>
  </div>
</template>

<script>
import { ref } from "vue";

export default {
  name: "Comprar",

  props: { unidades: Number },

  setup(prop) {
    const compras = ref(prop.unidades || 0);

const incrementar = () => compras.value++;
    const decrementar = () => compras.value--;
    const vaciar = () => (compras.value = 0);

    return { compras, incrementar, decrementar, vaciar };
  },
};
</script>

<style>
.root {
  width: 140px;
  margin: 20px;
}
</style>
