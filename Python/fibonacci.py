from typing import List

def fibonacci(n: int) -> List[int]:
    if n < 0:
        raise ValueError("n must be a non-negative integer")

    sequence: List[int] = []
    a, b = 0, 1
    for _ in range(n):
        sequence.append(a)
        a, b = b, a + b
    return sequence


if __name__ == "__main__":
    n = int(input("¿Cuántos números de la sucesión de Fibonacci quieres generar?: "))
    numbers = fibonacci(n)
    print(" ".join(str(num) for num in numbers))
