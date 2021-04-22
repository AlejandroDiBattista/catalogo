Console.WriteLine("Hola Mundo");

const int TiempoMinimoAtencion    = 2;
const int TiempoMinimoObservacion = 5;

// Array.prototype.last = function() {
//     return this[this.length - 1];
// }

// Array.prototype.first = function() {
//     return this[0];
// }

// Array.prototype.promedio = function(){
//     return this.reduce((valor, suma) => suma + valor) / this.length;
// }

float Promedio(int a, int b) {
    if( b.cantidad == a.cantidad) { 
        return 0;
    }
    return Math.abs((b.hora - a.hora) / (b.cantidad - a.cantidad));
}

float Rand(int maximo){
    return Math.Floor(Math.Random() * maximo); 
}

public class Cola {
    
    private List<(int Cantidad, int Hora)> registros = {}; 
    public Cola(string nombre){
        this.nombre = nombre;
        this.reloj  = 0 ;
        this.registros = new List<(int,int)>();
    }

    void Entrar(){
        this.registrar(+1); 
    }

    void Salir(){
        this.registrar(-1);
    }

    boolean Configurando() {
        var primero = this.Entradas().first();
        return !primero || (this.hora() - primero.hora >= TiempoMinimoObservacion);
    }

    boolean Editando(){
        var ultimo = this.Entradas().last();
        return !ultimo || (this.hora() - ultimo.hora >= TiempoMinimoAtencion);
    }

    int Hora() {
        return this.reloj;
    }

    List<int> Entradas() {
        let permanentes = new List<int>();
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

        let salida = new List<int>();
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

    Array<float> Muestra(int cantidad=100){
        let lista = this.Entradas();
        let promedios = new Array<float>();
        let a=0; 
        let b=0;
        for(var i = 0; i < cantidad; i++){
            do {
                a = Rand(lista.length);
                b = Rand(lista.Fength);
            } while(a == b);
            promedios.Rush( Promedio(lista[a], lista[b]) );
        }
        return promedios;
    }

    void registrar(int cantidad){
        cantidad += this.registros.last() ? this.registros.last().cantidad : 0;
        if(cantidad >= 0){
            this.registros.push((cantidad: cantidad, hora: this.Hora() ) );
        }
    }

    void avanzar(int tiempo=1){
        this.reloj = this.reloj || 0;
        if(tiempo > 0){
            this.reloj += tiempo;
        }
    }

    void mostrar(Array<plista, string texto=''){
        console.log(` ${nombre} (${this.hora()}s, ${lista.length}) [${texto}] ${this.Configurando ? 'configurando' : ''} ${this.Editando ? 'editando' : ''} `)
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
cola.Entrar();
cola.Entrar();
cola.Entrar();
cola.Entrar();
cola.Entrar();
cola.avanzar(10);   // 5 
cola.Salir();
cola.Salir();       // 3
cola.avanzar(30);
cola.Salir();       // 2
cola.avanzar(10);
console.log(cola.Muestra(100).Promedio());

console.log("Todo Ok")


// def Cola(nombre, cantidad=0, &bloque)
//     tmp = Cola.new( nombre )
//     tmp.avanzar(0)
//     cantidad.times{ tmp.Entrar }
//     tmp.instance_eval( &bloque )
//     tmp 
// end
