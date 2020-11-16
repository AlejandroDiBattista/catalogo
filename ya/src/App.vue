<template>
	<img alt="Vue logo" src="./assets/logo.png" />
	<Comprar :unidades="3" :precio="10"/>
	<Comprar :unidades="0" :precio="20"/>
	<Comprar :unidades="10" :precio="30" />
</template>

<script>
import Comprar from "./components/Comprar.vue";


export default {
	name: "App",
	components: { Comprar, },
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
