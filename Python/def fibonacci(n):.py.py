def fibonacci(n):
    serie = []
    a, b = 0, 1
    for _ in range(n):
        serie.append(a)
        a, b = b, a + b
    return serie

def main():
    cantidad = int(input("¿Cuántos elementos de la serie de Fibonacci quieres ver? "))
    if cantidad <= 0:
        print("Introduce un número entero positivo.")
        return

    resultado = fibonacci(cantidad)
    print("Serie de Fibonacci:")
    print(", ".join(str(num) for num in resultado))

if __name__ == "__main__":
    main()