contador = 0
for i in range(1, 1000000):
    modulo = i%7
    if modulo == 0:
        contador += 1
    print (str(i) + " % 7 = " + str(modulo))
print("Cantidad de números divisibles por 7 entre 1 y 999999:", contador)

