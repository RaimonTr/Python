#Escribe un código que genere la sucesión de Fibonacci hasta el número 100.
n = input("Introduce un número límite para la sucesión de Fibonacci: ")
n=int(n)
print("Sucesión de Fibonacci hasta " + str(n) + ":")
a, b = 0, 1
for _ in range (0, n):
    print(a, end=' ')
    a, b = b, a + b

