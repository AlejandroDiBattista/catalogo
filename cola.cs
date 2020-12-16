Console.WriteLine("Hola Mundo");

const TiempoMinimoAtencion    = 2;
const TiempoMinimoObservacion = 5;

// Array.prototype.last = function() {
//     return this[this.length - 1];
// }

// Array.prototype.first = function() {
//     return this[0];
// }

// Array.prototype.promedio = function(){
//     return this.reduce((valor, suma) => suma + valor) / this.length;
// }

float promedio(int a, int b) {
    if( b.cantidad == a.cantidad) { 
        return 0;
    }
    return Math.abs((b.hora - a.hora) / (b.cantidad - a.cantidad));
}

float rand(int maximo){
    return Math.floor(Math.random() * maximo); 
}


class Cola {
    
    constructor (nombre){
        this.nombre = nombre;
        this.reloj  = 0 ;
        this.registros = [];
    }

    void entrar(){
        this.registrar(+1); 
    }

    void salir(){
        this.registrar(-1);
    }

    boolean configurando() {
        var primero = this.entradas().first();
        return !primero || (this.hora() - primero.hora >= TiempoMinimoObservacion);
    }

    boolean editando(){
        var ultimo = this.entradas().last();
        return !ultimo || (this.hora() - ultimo.hora >= TiempoMinimoAtencion);
    }

    int hora() {
        return this.reloj;
    }

    Array<Int> entradas() {
        let permanentes = [];
        this.reducir(this.registros, (anterior, actual) => {
            if( actual != undefined ){
                if( actual.hora - anterior.hora >= TiempoMinimoAtencion) {
                    permanentes.push(anterior);
                }
            } else {
                if (this.hora() - anterior.hora >= TiempoMinimoAtencion){
                    permanentes.push(anterior);
                }
            }
        });

        let salida = [];
        this.reducir(permanentes, (anterior, actual) => {
            if(actual != undefined){ 
                if(salida.length == 0){
                    if ( actual.hora - anterior.hora >= TiempoMinimoObservacion ){
                        salida.push(anterior);
                    }
                } 
                if( actual.cantidad < anterior.cantidad ) {
                        salida.push(actual);
                }
            }
        });
        return salida;
    }

    void muestra(int cantidad=100){
        let lista = this.entradas();
        let promedios = [];
        let a, b;
        for(var i = 0; i < cantidad; i++){
            do {
                a = rand(lista.length);
                b = rand(lista.length);
            } while(a == b);
            promedios.push( promedio(lista[a], lista[b]) );
        }
        return promedios;
    }

    void registrar(int cantidad){
        cantidad += this.registros.last() ? this.registros.last().cantidad : 0;
        if(cantidad >= 0){
            this.registros.push({ cantidad: cantidad, hora: this.hora() });
        }
    }

    void avanzar(int tiempo=1){
        this.reloj = this.reloj || 0;
        if(tiempo > 0){
            this.reloj += tiempo;
        }
    }

    void mostrar(Array<plista, string texto=''){
        console.log(` ${nombre} (${this.hora()}s, ${lista.length}) [${texto}] ${this.configurando ? 'configurando' : ''} ${this.editando ? 'editando' : ''} `)
        lista.forEach( e => console.log(`   • ${e.hora} > ${e.cantidad}`) );
        console.log("");
    }
  
    reducir(lista, acciones){
        for(var i = 0; i < lista.length; i++){
            var anterior = lista[i];
            var actual   = lista[i+1];
            acciones( anterior, actual);
        }
    }

}

var cola = new Cola("Polo Norte");
cola.entrar();
cola.entrar();
cola.entrar();
cola.entrar();
cola.entrar();
cola.avanzar(10);   // 5 
cola.salir();
cola.salir();       // 3
cola.avanzar(30);
cola.salir();       // 2
cola.avanzar(10);
console.log(cola.muestra(100).promedio());

console.log("Todo Ok")


// def Cola(nombre, cantidad=0, &bloque)
//     tmp = Cola.new( nombre )
//     tmp.avanzar(0)
//     cantidad.times{ tmp.entrar }
//     tmp.instance_eval( &bloque )
//     tmp 
// end
