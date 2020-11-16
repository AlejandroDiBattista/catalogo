<template>
  <div class="root">
    <div v-if="state.vacio">
      <button @click="incrementar" class="ui button icon basic">
        <i class="icon cart arrow down"></i>
        Comprar
      </button>
    </div>
    <div v-else>
      <div class="ui icon buttons">
        <button @click="incrementar" class="ui button icon basic">
          <i class="ui icon plus"></i>
        </button>
        <button class="ui button basic" @click="vaciar">
          {{ state.unidades }}
        </button>
        <button @click="decrementar" class="ui button basic">
          <i class="iu icon minus"></i>
        </button>
      </div>
      <span class="ui">${{ state.importe }}</span>
    </div>
  </div>
</template>

<script>
import { reactive, computed } from "vue";

export default {
  name: "Comprar",

  props: {
    unidades: Number,
    precio: Number,
  },

  setup(prop) {
    const state = reactive({
      unidades: prop.unidades,
      vacio: computed(() => state.unidades == 0),
      importe: computed(
        () => state.unidades * (state.unidades > 3 ? 0.8 : 1) * prop.precio
      ),
    });

    function incrementar() {
      state.unidades++;
    }

    function decrementar() {
      state.unidades--;
    }

    function vaciar() {
      state.unidades = 0;
    }

    return { state, incrementar, decrementar, vaciar };
  },
};
</script>

<style>
.comprar {
  width: 220px;
}

.cambiar {
  width: 40px;
}

.unidades {
  width: 60px;
  text-align: center;
  vertical-align: middle;
  background-color: yellow;
  padding: 0 20px;
}

button {
  padding: 10px;
  border: 1px solid red;
}
</style>
