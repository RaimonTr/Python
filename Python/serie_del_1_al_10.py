#escribe un programa que imprima los números del 1 al 10 separados por comas y en una sola línea.
for i in range(1, 11):
    if i < 10:
        print(i, end=', ')
    else:
        print(i)