contador = 0
for i in range(990000, 1000001):
    modulo = i%7
    if modulo == 0:
        print (str(i) + " % 7 = " + str(modulo))
        contador += 1
        
print("Cantidad de números divisibles por 7 entre 1 y 999999:", contador)

