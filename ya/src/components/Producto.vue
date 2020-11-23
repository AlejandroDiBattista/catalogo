<template>
    <div class="card">
        <div class="image">
            <img src="{{props.producto.url_img}}" />
        </div>
        <div class="content">
            <div class="header">{{props.producto.nombre}}</div>
            <div class="description">${{props.producto.precio.toFixed(2)}}</div>
        </div>
        <div class="buttons">
            <Comprar :unidades="0" :precio="props.producto.precio" />
            <button class="like">♡</button>
        </div>
    </div>
</template>

<script>
    import Comprar from "./Comprar.vue";

    export default {
        name: "Producto",
        props: ['producto'],
           
	    components: { Comprar, },
        setup(){
            return {};
        }
    };
</script>