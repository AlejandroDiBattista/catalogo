<template>
	<img alt="Vue logo" src="./assets/logo.png" />
	<Comprar :unidades="3" />
	<Comprar :unidades="0" />
	<Comprar :unidades="10" />
	Holis {{datos}}
</template>

<script>
	import Comprar from "./components/Comprar.vue";
	import rubros from "./components/productos.json";


	export default {
		name: "App",
		components: { Comprar, },
		setup(){
			const datos = rubros.productos.productos
			return {datos};
		}
	};
</script>

<style>
#app {
	font-family: Avenir, Helvetica, Arial, sans-serif;
	text-align: center;
	color: #2c3e50;
	margin-top: 60px;
}
</style>
