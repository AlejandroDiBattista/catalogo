const Comprar = {

    template: `
        <button class="add">
            Comprar
        </button>
    `,
  
    data() {
      return {
        email: "",
        validationErrors: [],
      };
    },

    computed: {   },
    
    mounted() {
      consola.log("Mounted COMPRA");
    },
    
    methods: {
        
    },
  };